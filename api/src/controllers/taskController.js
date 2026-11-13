
const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/User');
const EmailLog = require('../models/EmailLog');
const { sendEmail } = require('../services/emailService');
const { createNotifications } = require('../services/notificationService');
const { logTaskActivity } = require('../services/activityService');
// GET /api/tasks?type=created|assigned|accepted|shared
const getTasks = async (req, res) => {
    try {
        const userId = req.userId;
        const type = req.query.type;

        const filters = {
            created: { createdBy: userId },
            assigned: { assignedTo: userId },
            accepted: { acceptedBy: userId },
            shared: { sharedWith: userId }
        };

        let filter;

        if (!type) {
            filter = {
                $or: [
                    { createdBy: userId },
                    { assignedTo: userId },
                    { acceptedBy: userId },
                    { sharedWith: userId }
                ]
            };
        } else if (filters[type]) {
            filter = filters[type];
        } else {
            return res.status(400).json({
                message: 'Loai cong viec khong hop le'
            });
        }

        const tasks = await Task.find(filter)
            .populate('assignedTo', 'fullName email')
            .populate('primaryAssigneeId', 'fullName email')
            .populate('sharedWith', 'fullName email')
            .populate('sharedPermissions.user', 'fullName email')
            .populate('assigneeProgress.user', 'fullName email')
            .sort({ createdAt: -1 });

        return res.json(tasks);
    } catch (error) {
        console.error('Loi lay danh sach cong viec:', error);
        return res.status(500).json({
            message: 'Khong the lay danh sach cong viec'
        });
    }
};

// POST /api/tasks
const createTask = async (req, res) => {
    try {
        const {
            title,
            description,
            assignedTo,
            primaryAssigneeId,
            sharedWith,
            sharedPermissions,
            priority,
            startDate,
            dueDate
        } = req.body;

        const isValidId = id =>
            mongoose.Types.ObjectId.isValid(id);

        const validPriorities = ['low', 'medium', 'high'];

        if (typeof title !== 'string' || !title.trim()) {
            return res.status(400).json({
                message: 'Tieu de cong viec khong duoc de trong'
            });
        }

        if (
            description !== undefined &&
            typeof description !== 'string'
        ) {
            return res.status(400).json({
                message: 'Mo ta cong viec khong hop le'
            });
        }

        if (
            priority !== undefined &&
            !validPriorities.includes(priority)
        ) {
            return res.status(400).json({
                message: 'Muc do uu tien khong hop le'
            });
        }

        const parsedStartDate =
            startDate === undefined || startDate === null || startDate === ''
                ? null
                : new Date(startDate);

        const parsedDueDate =
            dueDate === undefined || dueDate === null || dueDate === ''
                ? null
                : new Date(dueDate);

        if (
            (parsedStartDate !== null &&
                Number.isNaN(parsedStartDate.getTime())) ||
            (parsedDueDate !== null &&
                Number.isNaN(parsedDueDate.getTime()))
        ) {
            return res.status(400).json({
                message: 'Ngay bat dau hoac han hoan thanh khong hop le'
            });
        }

        if (
            parsedStartDate !== null &&
            parsedDueDate !== null &&
            parsedDueDate < parsedStartDate
        ) {
            return res.status(400).json({
                message: 'Han hoan thanh khong duoc som hon ngay bat dau'
            });
        }

        const assigned = assignedTo === undefined ? [] : assignedTo;
        const shared = sharedWith === undefined ? [] : sharedWith;
        const permissions =
            sharedPermissions === undefined ? [] : sharedPermissions;

        if (
            !Array.isArray(assigned) ||
            !Array.isArray(shared) ||
            !assigned.every(isValidId) ||
            !shared.every(isValidId)
        ) {
            return res.status(400).json({
                message: 'Danh sach nguoi dung khong hop le'
            });
        }

        if (!Array.isArray(permissions)) {
            return res.status(400).json({
                message: 'Danh sach quyen chia se khong hop le'
            });
        }

        for (const item of permissions) {
            if (
                !item ||
                !isValidId(item.user) ||
                !['viewer', 'editor'].includes(item.permission) ||
                !shared.some(id => String(id) === String(item.user))
            ) {
                return res.status(400).json({
                    message: 'Thong tin quyen chia se khong hop le'
                });
            }
        }

        if (
            primaryAssigneeId !== undefined &&
            primaryAssigneeId !== null &&
            (
                !isValidId(primaryAssigneeId) ||
                !assigned.some(id => String(id) === String(primaryAssigneeId))
            )
        ) {
            return res.status(400).json({
                message: 'Nguoi phu trach chinh phai nam trong danh sach nguoi duoc giao'
            });
        }

        const task = await Task.create({
            title: title.trim(),
            description: description || '',
            priority: priority || 'medium',
            startDate: parsedStartDate,
            dueDate: parsedDueDate,
            createdBy: req.userId,
            assignedTo: assigned,
            primaryAssigneeId: primaryAssigneeId || null,
            acceptedBy: [],
            assigneeProgress: assigned.map(userId => ({
                user: userId,
                status: 'not_started',
                updatedAt: new Date()
            })),
            sharedWith: shared,
            sharedPermissions: permissions
        });

        // Ghi lich su tao cong viec
        await logTaskActivity({
            taskId: task._id,
            userId: req.userId,
            action: 'created',
            description: `Da tao cong viec: ${task.title}`
        });

        // Ghi lich su giao viec khi tao cong viec
        if (assigned.length > 0) {
            await logTaskActivity({
                taskId: task._id,
                userId: req.userId,
                action: 'assigned',
                description: `Da giao cong viec cho ${assigned.length} nguoi`,
                changes: {
                    assignedTo: assigned
                }
            });
        }

        // Ghi lich su chia se khi tao cong viec
        if (shared.length > 0) {
            await logTaskActivity({
                taskId: task._id,
                userId: req.userId,
                action: 'shared',
                description: `Da chia se cong viec voi ${shared.length} nguoi`,
                changes: {
                    sharedWith: shared,
                    permissions
                }
            });
        }


        // Tao thong bao trong ung dung khi giao viec
        try {
            await createNotifications({
                recipients: assigned,
                sender: req.userId,
                task: task._id,
                type: 'task_assigned',
                message: `Ban duoc giao cong viec: ${task.title}`
            });
        } catch (notificationError) {
            console.error(
                'Loi tao thong bao giao viec:',
                notificationError.message
            );
        }

        // Gui email cho nguoi duoc giao
        try {
            const assignees = await User.find({
                _id: { $in: assigned }
            }).select('fullName email');

            const creator = await User.findById(req.userId)
                .select('fullName');

            for (const assignee of assignees) {
                if (!assignee.email) continue;

                try {
                    const subject =
                        `[TaskManager] Ban duoc giao cong viec: ${task.title}`;

                    const text = `
Xin chao ${assignee.fullName},

Ban vua duoc giao mot cong viec moi.

Ten cong viec: ${task.title}
Mo ta: ${task.description || 'Khong co mo ta'}
Nguoi giao: ${creator ? creator.fullName : 'TaskManager'}

Vui long dang nhap TaskManager de xem chi tiet.

Tran trong,
TaskManager
                    `;

                    const emailLog = await EmailLog.create({
                        taskId: task._id,
                        recipientEmail: assignee.email,
                        eventType: 'task_assigned',
                        subject,
                        status: 'pending'
                    });

                    const result = await sendEmail({
                        to: assignee.email,
                        subject,
                        text
                    });

                    emailLog.attempts += 1;

                    if (result.success) {
                        emailLog.status = 'sent';
                        emailLog.sentAt = new Date();
                        emailLog.errorMessage = null;
                    } else {
                        emailLog.status = 'failed';
                        emailLog.errorMessage = result.error;
                    }

                    await emailLog.save();
                } catch (recipientError) {
                    console.error(
                        'Loi gui email giao viec:',
                        recipientError.message
                    );
                }
            }
        } catch (emailError) {
            console.error(
                'Loi xu ly email thong bao:',
                emailError.message
            );
        }

        // Gui email cho nguoi duoc chia se khi tao cong viec
        try {
            const assignedIds = new Set(
                assigned.map(id => String(id))
            );

            const creator = await User.findById(req.userId)
                .select('fullName');

            const sharedUsers = await User.find({
                _id: { $in: shared }
            }).select('fullName email');

            for (const sharedUser of sharedUsers) {
                if (
                    String(sharedUser._id) === String(req.userId) ||
                    assignedIds.has(String(sharedUser._id)) ||
                    !sharedUser.email
                ) {
                    continue;
                }

                try {
                    const sharePermission = permissions.find(
                        item =>
                            String(item.user) === String(sharedUser._id)
                    );

                    const permission =
                        sharePermission?.permission || 'viewer';

                    const permissionText =
                        permission === 'editor'
                            ? 'Co quyen chinh sua cong viec'
                            : 'Chi co quyen xem cong viec';

                    const subject =
                        `[TaskManager] Ban duoc moi chia se cong viec: ${task.title}`;

                    const text = `
Xin chao ${sharedUser.fullName},

Ban vua duoc moi tham gia chia se mot cong viec.

Ten cong viec: ${task.title}
Mo ta: ${task.description || 'Khong co mo ta'}
Nguoi moi: ${creator ? creator.fullName : 'TaskManager'}
Quyen cua ban: ${permissionText}

Vui long dang nhap TaskManager de xem chi tiet.

Tran trong,
TaskManager
                    `;

                    const emailLog = await EmailLog.create({
                        taskId: task._id,
                        recipientEmail: sharedUser.email,
                        eventType: 'task_shared',
                        subject,
                        status: 'pending'
                    });

                    const result = await sendEmail({
                        to: sharedUser.email,
                        subject,
                        text
                    });

                    emailLog.attempts += 1;

                    if (result.success) {
                        emailLog.status = 'sent';
                        emailLog.sentAt = new Date();
                        emailLog.errorMessage = null;
                    } else {
                        emailLog.status = 'failed';
                        emailLog.errorMessage = result.error;
                    }

                    await emailLog.save();
                } catch (recipientError) {
                    console.error(
                        'Loi gui email chia se:',
                        recipientError.message
                    );
                }
            }
        } catch (emailError) {
            console.error(
                'Loi xu ly email chia se cong viec:',
                emailError.message
            );
        }

        return res.status(201).json({
            message: 'Tao cong viec thanh cong',
            task
        });
    } catch (error) {
        console.error('Loi tao cong viec:', error);
        return res.status(500).json({
            message: 'Khong the tao cong viec'
        });
    }
};

// PUT /api/tasks/:id
const updateTask = async (req, res) => {
    try {
        const { id } = req.params;
        const {
            title,
            description,
            status,
            priority,
            startDate,
            dueDate
        } = req.body;

        const isValidId = value =>
            mongoose.Types.ObjectId.isValid(value);

        const validPriorities = ['low', 'medium', 'high'];

        if (!isValidId(id)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        const isCreator =
            String(task.createdBy) === String(req.userId);

        const isEditor = task.sharedPermissions.some(item =>
            String(item.user) === String(req.userId) &&
            item.permission === 'editor'
        );

        if (!isCreator && !isEditor) {
            return res.status(403).json({
                message: 'Ban khong co quyen chinh sua cong viec nay'
            });
        }

        if (
            title !== undefined &&
            (typeof title !== 'string' || !title.trim())
        ) {
            return res.status(400).json({
                message: 'Tieu de cong viec khong duoc de trong'
            });
        }

        if (
            description !== undefined &&
            typeof description !== 'string'
        ) {
            return res.status(400).json({
                message: 'Mo ta cong viec khong hop le'
            });
        }

        const validStatuses = [
            'not_started',
            'in_progress',
            'completed'
        ];

        if (
            status !== undefined &&
            !validStatuses.includes(status)
        ) {
            return res.status(400).json({
                message: 'Trang thai cong viec khong hop le'
            });
        }

        if (
            priority !== undefined &&
            !validPriorities.includes(priority)
        ) {
            return res.status(400).json({
                message: 'Muc do uu tien khong hop le'
            });
        }

        const oldStatus = task.status;

        const oldValues = {
            title: task.title,
            description: task.description || '',
            priority: task.priority,
            startDate: task.startDate
                ? new Date(task.startDate).getTime()
                : null,
            dueDate: task.dueDate
                ? new Date(task.dueDate).getTime()
                : null
        };

        const parsedStartDate =
            startDate === undefined
                ? task.startDate
                : startDate === null || startDate === ''
                    ? null
                    : new Date(startDate);

        const parsedDueDate =
            dueDate === undefined
                ? task.dueDate
                : dueDate === null || dueDate === ''
                    ? null
                    : new Date(dueDate);

        if (
            (parsedStartDate != null &&
                Number.isNaN(new Date(parsedStartDate).getTime())) ||
            (parsedDueDate != null &&
                Number.isNaN(new Date(parsedDueDate).getTime()))
        ) {
            return res.status(400).json({
                message: 'Ngay bat dau hoac han hoan thanh khong hop le'
            });
        }

        if (
            parsedStartDate != null &&
            parsedDueDate != null &&
            new Date(parsedDueDate) < new Date(parsedStartDate)
        ) {
            return res.status(400).json({
                message: 'Han hoan thanh khong duoc som hon ngay bat dau'
            });
        }

        const newValues = {
            title: title !== undefined ? title.trim() : task.title,
            description: description !== undefined
                ? description
                : task.description || '',
            priority: priority !== undefined ? priority : task.priority,
            startDate: parsedStartDate != null
                ? new Date(parsedStartDate).getTime()
                : null,
            dueDate: parsedDueDate != null
                ? new Date(parsedDueDate).getTime()
                : null
        };

        const changes = [];

        if (oldValues.title !== newValues.title) {
            changes.push(
                `Ten cong viec: "${oldValues.title}" -> "${newValues.title}"`
            );
        }

        if (oldValues.description !== newValues.description) {
            changes.push(
                `Mo ta: "${oldValues.description || 'Khong co'}" -> "${newValues.description || 'Khong co'}"`
            );
        }

        if (oldValues.priority !== newValues.priority) {
            changes.push(
                `Muc do uu tien: ${oldValues.priority} -> ${newValues.priority}`
            );
        }

        const formatDate = value => {
            if (value === null) return 'Chua thiet lap';
            return new Date(value).toLocaleString('vi-VN');
        };

        if (oldValues.startDate !== newValues.startDate) {
            changes.push(
                `Ngay bat dau: ${formatDate(oldValues.startDate)} -> ${formatDate(newValues.startDate)}`
            );
        }

        if (oldValues.dueDate !== newValues.dueDate) {
            changes.push(
                `Han hoan thanh: ${formatDate(oldValues.dueDate)} -> ${formatDate(newValues.dueDate)}`
            );
        }

        task.title = newValues.title;
        task.description = newValues.description;
        task.priority = newValues.priority;

        if (status !== undefined) {
            task.status = status;
        }

                task.startDate = parsedStartDate;
                task.dueDate = parsedDueDate;

                await task.save();

                // Ghi lich su chinh sua thong tin cong viec
                if (changes.length > 0) {
                    await logTaskActivity({
                        taskId: task._id,
                        userId: req.userId,
                        action: 'updated',
                        description: `Da cap nhat thong tin cong viec: ${task.title}`,
                        changes: {
                            details: changes
                        }
                    });
                }

                // Ghi lich su thay doi trang thai
                if (oldStatus !== task.status) {
                    await logTaskActivity({
                        taskId: task._id,
                        userId: req.userId,
                        action: 'status_changed',
                        description: `Da thay doi trang thai: ${oldStatus} -> ${task.status}`,
                        changes: {
                            oldStatus,
                            newStatus: task.status
                        }
                    });
                }

        // Gui email khi cong viec hoan thanh
        if (
            oldStatus !== 'completed' &&
            task.status === 'completed'
        ) {
            try {
                const recipientIds = new Set([
                    ...task.assignedTo.map(user => String(user)),
                    ...task.sharedWith.map(user => String(user))
                ]);

                recipientIds.delete(String(req.userId));

                const recipients = await User.find({
                    _id: { $in: [...recipientIds] }
                }).select('fullName email');

                const completer = await User.findById(req.userId)
                    .select('fullName');

                const subject =
                    `[TaskManager] Cong viec da hoan thanh: ${task.title}`;

                for (const recipient of recipients) {
                    if (!recipient.email) continue;

                    try {
                        const text = `
Xin chao ${recipient.fullName},

Mot cong viec ban dang tham gia da duoc hoan thanh.

Ten cong viec: ${task.title}
Nguoi hoan thanh: ${completer ? completer.fullName : 'TaskManager'}

Vui long dang nhap TaskManager de xem chi tiet.

Tran trong,
TaskManager
                        `;

                        const emailLog = await EmailLog.create({
                            taskId: task._id,
                            recipientEmail: recipient.email,
                            eventType: 'task_completed',
                            subject,
                            status: 'pending'
                        });

                        const result = await sendEmail({
                            to: recipient.email,
                            subject,
                            text
                        });

                        emailLog.attempts += 1;

                        if (result.success) {
                            emailLog.status = 'sent';
                            emailLog.sentAt = new Date();
                            emailLog.errorMessage = null;
                        } else {
                            emailLog.status = 'failed';
                            emailLog.errorMessage = result.error;
                        }

                        await emailLog.save();
                    } catch (recipientError) {
                        console.error(
                            `Loi gui email hoan thanh cho ${recipient.email}:`,
                            recipientError.message
                        );
                    }
                }
            } catch (emailError) {
                console.error(
                    'Loi xu ly email hoan thanh cong viec:',
                    emailError.message
                );
            }
        }

        // Gui email khi thong tin cong viec thay doi
        if (changes.length > 0) {
            try {
                const recipientIds = new Set([
                    ...task.assignedTo.map(user => String(user)),
                    ...task.sharedWith.map(user => String(user))
                ]);

                recipientIds.delete(String(req.userId));

                const recipients = await User.find({
                    _id: { $in: [...recipientIds] }
                }).select('fullName email');

                const updater = await User.findById(req.userId)
                    .select('fullName');

                const subject =
                    `[TaskManager] Cong viec da duoc cap nhat: ${task.title}`;

                const changeText = changes
                    .map((change, index) => `${index + 1}. ${change}`)
                    .join('\n');

                for (const recipient of recipients) {
                    if (!recipient.email) continue;

                    try {
                        const text = `
Xin chao ${recipient.fullName},

Mot cong viec ban dang tham gia vua duoc cap nhat.

Ten cong viec: ${task.title}
Nguoi cap nhat: ${updater ? updater.fullName : 'TaskManager'}

Thong tin thay doi:
${changeText}

Vui long dang nhap TaskManager de xem chi tiet cong viec.

Tran trong,
TaskManager
                        `;

                        const emailLog = await EmailLog.create({
                            taskId: task._id,
                            recipientEmail: recipient.email,
                            eventType: 'task_updated',
                            subject,
                            status: 'pending'
                        });

                        const result = await sendEmail({
                            to: recipient.email,
                            subject,
                            text
                        });

                        emailLog.attempts += 1;

                        if (result.success) {
                            emailLog.status = 'sent';
                            emailLog.sentAt = new Date();
                            emailLog.errorMessage = null;
                        } else {
                            emailLog.status = 'failed';
                            emailLog.errorMessage = result.error;
                        }

                        await emailLog.save();
                    } catch (recipientError) {
                        console.error(
                            `Loi gui email cap nhat cho ${recipient.email}:`,
                            recipientError.message
                        );
                    }
                }
            } catch (emailError) {
                console.error(
                    'Loi xu ly email cap nhat cong viec:',
                    emailError.message
                );
            }
        }

        return res.json({
            message: 'Cap nhat cong viec thanh cong',
            task
        });
    } catch (error) {
        console.error('Loi cap nhat cong viec:', error);
        return res.status(500).json({
            message: 'Khong the cap nhat cong viec'
        });
    }
};

// DELETE /api/tasks/:id
const deleteTask = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        if (String(task.createdBy) !== String(req.userId)) {
            return res.status(403).json({
                message: 'Ban khong co quyen xoa cong viec nay'
            });
        }

        await Task.findByIdAndDelete(id);

        return res.json({
            message: 'Xoa cong viec thanh cong'
        });
    } catch (error) {
        console.error('Loi xoa cong viec:', error);
        return res.status(500).json({
            message: 'Khong the xoa cong viec'
        });
    }
};

// GET /api/tasks/:id/email-logs
const getEmailLogs = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        const isCreator =
            String(task.createdBy) === String(req.userId);

        const isAssignee = task.assignedTo.some(
            user => String(user) === String(req.userId)
        );

        const isSharedUser = task.sharedWith.some(
            user => String(user) === String(req.userId)
        );

        if (!isCreator && !isAssignee && !isSharedUser) {
            return res.status(403).json({
                message: 'Ban khong co quyen xem lich su email'
            });
        }

        const emailLogs = await EmailLog.find({
            taskId: task._id
        })
            .sort({ createdAt: -1 })
            .select(
                'recipientEmail eventType subject status attempts errorMessage sentAt createdAt'
            );

        return res.json({
            message: 'Lay lich su email thanh cong',
            total: emailLogs.length,
            emailLogs
        });
    } catch (error) {
        console.error('Loi lay lich su email:', error);
        return res.status(500).json({
            message: 'Khong the lay lich su email'
        });
    }
};

module.exports = {
    getTasks,
    createTask,
    updateTask,
    deleteTask,
    getEmailLogs
};
