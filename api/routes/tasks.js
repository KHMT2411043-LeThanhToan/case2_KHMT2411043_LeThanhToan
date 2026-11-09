
const express = require('express');
const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/User');
const EmailLog = require('../models/EmailLog');
const { sendEmail } = require('../services/emailService');
const authenticateToken = require('../middleware/auth_middleware');

const router = express.Router();

const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);

const validPriorities = ['low', 'medium', 'high'];

// GET /api/tasks?type=created|assigned|accepted|shared
router.get('/', authenticateToken, async (req, res) => {
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
});

// POST /api/tasks - tao cong viec
router.post('/', authenticateToken, async (req, res) => {
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

        // Kiem tra ngay bat dau va han hoan thanh
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

        // Kiem tra quyen chia se
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

        // D1: Gui email thong bao cho nguoi duoc giao cong viec
        try {
            const assignees = await User.find({
                _id: { $in: assigned }
            }).select('fullName email');

            const creator = await User.findById(req.userId)
                .select('fullName');

            for (const assignee of assignees) {
                if (!assignee.email) {
                    continue;
                }

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

        // D2.1: Gui email cho nguoi duoc chia se khi tao cong viec
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
});

// PUT /api/tasks/:id - chinh sua cong viec va gui email D3
router.put('/:id', authenticateToken, async (req, res) => {
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

        // Nguoi tao hoac editor duoc phep chinh sua
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

        // Luu gia tri cu de so sanh
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

        // Xu ly ngay bat dau va han hoan thanh
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

        // Xac dinh gia tri moi
        const newValues = {
            title: title !== undefined
                ? title.trim()
                : task.title,

            description: description !== undefined
                ? description
                : task.description || '',

            priority: priority !== undefined
                ? priority
                : task.priority,

            startDate: parsedStartDate != null
                ? new Date(parsedStartDate).getTime()
                : null,

            dueDate: parsedDueDate != null
                ? new Date(parsedDueDate).getTime()
                : null
        };

        // D3: Xac dinh cac thong tin thuc su thay doi
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

        const formatDate = (value) => {
            if (value === null) {
                return 'Chua thiet lap';
            }

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

        // Cap nhat cong viec
        task.title = newValues.title;
        task.description = newValues.description;
        task.priority = newValues.priority;

        if (status !== undefined) {
            task.status = status;
        }

        task.startDate = parsedStartDate;
        task.dueDate = parsedDueDate;

        await task.save();

        // D3: Gui email cho nguoi duoc giao va nguoi duoc chia se
        // Khong gui email cho nguoi dang cap nhat
        // Khong gui email khi chi thay doi trang thai
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
                    if (!recipient.email) {
                        continue;
                    }

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
});

// DELETE /api/tasks/:id - xoa cong viec
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;

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
});

// POST /api/tasks/:id/accept - nhan cong viec
router.post('/:id/accept', authenticateToken, async (req, res) => {
    try {
        if (!isValidId(req.params.id)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        const task = await Task.findById(req.params.id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        const userId = String(req.userId);

        const canAccept =
            task.assignedTo.some(id => String(id) === userId) ||
            task.sharedWith.some(id => String(id) === userId);

        if (!canAccept) {
            return res.status(403).json({
                message: 'Ban khong co quyen nhan cong viec nay'
            });
        }

        const alreadyAccepted = task.acceptedBy.some(
            id => String(id) === userId
        );

        if (!alreadyAccepted) {
            task.acceptedBy.push(req.userId);
            await task.save();
        }

        return res.json({
            message: 'Nhan cong viec thanh cong',
            task
        });
    } catch (error) {
        console.error('Loi nhan cong viec:', error);

        return res.status(500).json({
            message: 'Khong the nhan cong viec'
        });
    }
});

// PUT /api/tasks/:id/progress - cap nhat tien do ca nhan
router.put('/:id/progress', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const userId = String(req.userId);

        if (!isValidId(id)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        const validStatuses = [
            'not_started',
            'in_progress',
            'completed'
        ];

        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                message: 'Trang thai tien do khong hop le'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        const isAssignee = task.assignedTo.some(
            user => String(user) === userId
        );

        if (!isAssignee) {
            return res.status(403).json({
                message: 'Ban khong phai nguoi duoc giao cong viec nay'
            });
        }

        const progress = task.assigneeProgress.find(
            item => String(item.user) === userId
        );

        if (progress) {
            progress.status = status;
            progress.updatedAt = new Date();
        } else {
            task.assigneeProgress.push({
                user: req.userId,
                status: status,
                updatedAt: new Date()
            });
        }

        await task.save();

        return res.json({
            message: 'Cap nhat tien do thanh cong',
            assigneeProgress: task.assigneeProgress
        });
    } catch (error) {
        console.error('Loi cap nhat tien do:', error);

        return res.status(500).json({
            message: 'Khong the cap nhat tien do'
        });
    }
});

// POST /api/tasks/:id/shares - moi nguoi moi chia se cong viec
router.post('/:id/shares', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { userId, permission = 'viewer' } = req.body;

        if (!isValidId(id) || !isValidId(userId)) {
            return res.status(400).json({
                message: 'ID cong viec hoac nguoi dung khong hop le'
            });
        }

        if (!['viewer', 'editor'].includes(permission)) {
            return res.status(400).json({
                message: 'Quyen chia se khong hop le'
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
                message: 'Chi nguoi tao cong viec duoc moi nguoi chia se'
            });
        }

        if (String(userId) === String(req.userId)) {
            return res.status(400).json({
                message: 'Khong the chia se cong viec voi chinh minh'
            });
        }

        const isAssignee = task.assignedTo.some(
            user => String(user) === String(userId)
        );

        if (isAssignee) {
            return res.status(400).json({
                message: 'Nguoi dung nay da duoc giao cong viec'
            });
        }

        const isShared = task.sharedWith.some(
            user => String(user) === String(userId)
        );

        if (isShared) {
            return res.status(409).json({
                message: 'Nguoi dung da duoc chia se cong viec nay'
            });
        }

        const invitedUser = await User.findById(userId)
            .select('fullName email');

        if (!invitedUser || !invitedUser.email) {
            return res.status(404).json({
                message: 'Khong tim thay nguoi dung hoac email'
            });
        }

        task.sharedWith.push(userId);

        task.sharedPermissions.push({
            user: userId,
            permission
        });

        await task.save();

        // Gui email moi chia se
        try {
            const permissionText = permission === 'editor'
                ? 'Co quyen chinh sua cong viec'
                : 'Chi co quyen xem cong viec';

            const creator = await User.findById(req.userId)
                .select('fullName');

            const subject =
                `[TaskManager] Ban duoc moi chia se cong viec: ${task.title}`;

            const text = `
Xin chao ${invitedUser.fullName},

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
                recipientEmail: invitedUser.email,
                eventType: 'task_shared',
                subject,
                status: 'pending'
            });

            const result = await sendEmail({
                to: invitedUser.email,
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

            return res.status(201).json({
                message: result.success
                    ? 'Moi chia se cong viec thanh cong'
                    : 'Da chia se cong viec nhung gui email that bai',
                emailStatus: emailLog.status,
                task
            });

        } catch (emailError) {
            console.error(
                'Loi gui email moi chia se:',
                emailError.message
            );

            return res.status(201).json({
                message: 'Da chia se cong viec nhung xu ly email that bai',
                task
            });
        }

    } catch (error) {
        console.error('Loi moi chia se cong viec:', error);

        return res.status(500).json({
            message: 'Khong the moi chia se cong viec'
        });
    }
});

// PUT /api/tasks/:id/shares/:userId - thay doi quyen chia se
router.put('/:id/shares/:userId', authenticateToken, async (req, res) => {
    try {
        const { id, userId } = req.params;
        const { permission } = req.body;

        if (!isValidId(id) || !isValidId(userId)) {
            return res.status(400).json({
                message: 'ID cong viec hoac nguoi dung khong hop le'
            });
        }

        if (!['viewer', 'editor'].includes(permission)) {
            return res.status(400).json({
                message: 'Quyen chia se khong hop le'
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
                message: 'Chi nguoi tao cong viec duoc thay doi quyen chia se'
            });
        }

        const isShared = task.sharedWith.some(
            user => String(user) === String(userId)
        );

        if (!isShared) {
            return res.status(404).json({
                message: 'Nguoi dung khong duoc chia se cong viec nay'
            });
        }

        const share = task.sharedPermissions.find(
            item => String(item.user) === String(userId)
        );

        if (share) {
            share.permission = permission;
        } else {
            task.sharedPermissions.push({
                user: userId,
                permission
            });
        }

        await task.save();

        return res.json({
            message: 'Thay doi quyen chia se thanh cong',
            task
        });
    } catch (error) {
        console.error('Loi thay doi quyen chia se:', error);

        return res.status(500).json({
            message: 'Khong the thay doi quyen chia se'
        });
    }
});

// DELETE /api/tasks/:id/shares/:userId - thu hoi quyen chia se
router.delete('/:id/shares/:userId', authenticateToken, async (req, res) => {
    try {
        const { id, userId } = req.params;

        if (!isValidId(id) || !isValidId(userId)) {
            return res.status(400).json({
                message: 'ID cong viec hoac nguoi dung khong hop le'
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
                message: 'Chi nguoi tao cong viec duoc thu hoi quyen chia se'
            });
        }

        const isShared = task.sharedWith.some(
            user => String(user) === String(userId)
        );

        if (!isShared) {
            return res.status(404).json({
                message: 'Nguoi dung khong duoc chia se cong viec nay'
            });
        }

        task.sharedWith = task.sharedWith.filter(
            user => String(user) !== String(userId)
        );

        task.sharedPermissions = task.sharedPermissions.filter(
            item => String(item.user) !== String(userId)
        );

        task.acceptedBy = task.acceptedBy.filter(
            user => String(user) !== String(userId)
        );

        await task.save();

        return res.json({
            message: 'Thu hoi quyen chia se thanh cong',
            task
        });
    } catch (error) {
        console.error('Loi thu hoi quyen chia se:', error);

        return res.status(500).json({
            message: 'Khong the thu hoi quyen chia se'
        });
    }
});

module.exports = router;
