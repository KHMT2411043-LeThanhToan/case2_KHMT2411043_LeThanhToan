
const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/User');
const EmailLog = require('../models/EmailLog');
const { sendEmail } = require('../services/emailService');
const { createNotifications } = require('../services/notificationService');
const { logTaskActivity } = require('../services/activityService');

// GET /api/assignments/:taskId
// Lay danh sach nguoi duoc giao va nguoi phu trach chinh
const getAssignment = async (req, res) => {
    try {
        const { taskId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(taskId)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        const task = await Task.findById(taskId)
            .populate('assignedTo', 'fullName email')
            .populate('primaryAssigneeId', 'fullName email')
            .populate('assigneeProgress.user', 'fullName email');

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        const userId = String(req.userId);

        const isCreator = String(task.createdBy) === userId;
        const isAssignee = task.assignedTo.some(
            user => String(user._id) === userId
        );
        const isSharedUser = task.sharedWith.some(
            user => String(user) === userId
        );

        if (!isCreator && !isAssignee && !isSharedUser) {
            return res.status(403).json({
                message: 'Ban khong co quyen xem thong tin giao viec'
            });
        }

        return res.json({
            message: 'Lay thong tin giao viec thanh cong',
            assignedTo: task.assignedTo,
            primaryAssignee: task.primaryAssigneeId,
            assigneeProgress: task.assigneeProgress
        });
    } catch (error) {
        console.error('Loi lay thong tin giao viec:', error);

        return res.status(500).json({
            message: 'Khong the lay thong tin giao viec'
        });
    }
};

// PUT /api/assignments/:taskId
// Cap nhat danh sach nguoi duoc giao
const updateAssignment = async (req, res) => {
    try {
        const { taskId } = req.params;
        const { assignedTo, primaryAssigneeId } = req.body;

        if (!mongoose.Types.ObjectId.isValid(taskId)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        if (
            !Array.isArray(assignedTo) ||
            !assignedTo.every(id =>
                mongoose.Types.ObjectId.isValid(id)
            )
        ) {
            return res.status(400).json({
                message: 'Danh sach nguoi duoc giao khong hop le'
            });
        }

        const uniqueAssigned = [
            ...new Set(assignedTo.map(id => String(id)))
        ];

        if (
            primaryAssigneeId !== undefined &&
            primaryAssigneeId !== null &&
            (
                !mongoose.Types.ObjectId.isValid(primaryAssigneeId) ||
                !uniqueAssigned.includes(String(primaryAssigneeId))
            )
        ) {
            return res.status(400).json({
                message: 'Nguoi phu trach chinh phai nam trong danh sach nguoi duoc giao'
            });
        }

        const task = await Task.findById(taskId);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        // Chi nguoi tao moi duoc thay doi nguoi duoc giao
        if (String(task.createdBy) !== String(req.userId)) {
            return res.status(403).json({
                message: 'Chi nguoi tao moi co quyen giao cong viec'
            });
        }

        // Kiem tra tat ca tai khoan nguoi duoc giao ton tai
        const users = await User.find({
            _id: { $in: uniqueAssigned }
        }).select('_id fullName email');

        if (users.length !== uniqueAssigned.length) {
            return res.status(400).json({
                message: 'Co nguoi dung khong ton tai'
            });
        }

        const oldAssigned = task.assignedTo.map(
            user => String(user)
        );

        const oldAssignedSet = new Set(oldAssigned);
        const newAssignedSet = new Set(uniqueAssigned);

        const addedUsers = uniqueAssigned.filter(
            id => !oldAssignedSet.has(id)
        );

        const removedUsers = oldAssigned.filter(
            id => !newAssignedSet.has(id)
        );

        // Cap nhat danh sach nguoi duoc giao
        task.assignedTo = uniqueAssigned;

        // Cap nhat nguoi phu trach chinh
        task.primaryAssigneeId =
            primaryAssigneeId === undefined
                ? (
                    task.primaryAssigneeId &&
                    newAssignedSet.has(String(task.primaryAssigneeId))
                        ? task.primaryAssigneeId
                        : null
                )
                : primaryAssigneeId || null;

        // Them tien do cho nguoi moi
        for (const userId of addedUsers) {
            task.assigneeProgress.push({
                user: userId,
                status: 'not_started',
                updatedAt: new Date()
            });
        }

        // Xoa tien do cua nguoi khong con duoc giao
        task.assigneeProgress = task.assigneeProgress.filter(
            item => newAssignedSet.has(String(item.user))
        );

        // Xoa trang thai chap nhan cua nguoi khong con duoc giao
        task.acceptedBy = task.acceptedBy.filter(
            user => newAssignedSet.has(String(user))
        );

        await task.save();
        // Ghi lich su giao cong viec cho nguoi moi
        if (addedUsers.length > 0) {
            await logTaskActivity({
                taskId: task._id,
                userId: req.userId,
                action: 'assigned',
                description: `Da giao cong viec cho ${addedUsers.length} nguoi`,
                changes: {
                    addedUsers
                }
            });
        }

        // Ghi lich su thu hoi cong viec
        if (removedUsers.length > 0) {
            await logTaskActivity({
                taskId: task._id,
                userId: req.userId,
                action: 'assignment_removed',
                description: `Da thu hoi cong viec tu ${removedUsers.length} nguoi`,
                changes: {
                    removedUsers
                }
            });
        }
        // Gui thong bao cho nguoi moi duoc giao
        if (addedUsers.length > 0) {
            try {
                await createNotifications({
                    recipients: addedUsers,
                    sender: req.userId,
                    task: task._id,
                    type: 'task_assigned',
                    message: `Ban duoc giao cong viec: ${task.title}`
                });
            } catch (error) {
                console.error(
                    'Loi tao thong bao giao viec:',
                    error.message
                );
            }

            // Gui email cho nguoi moi
            const creator = await User.findById(req.userId)
                .select('fullName');

            for (const user of users) {
                if (
                    !addedUsers.includes(String(user._id)) ||
                    !user.email
                ) {
                    continue;
                }

                try {
                    const subject =
                        `[TaskManager] Ban duoc giao cong viec: ${task.title}`;

                    const text = `
Xin chao ${user.fullName},

Ban vua duoc giao mot cong viec.

Ten cong viec: ${task.title}
Mo ta: ${task.description || 'Khong co mo ta'}
Nguoi giao: ${creator ? creator.fullName : 'TaskManager'}

Vui long dang nhap TaskManager de xem chi tiet.

Tran trong,
TaskManager
                    `;

                    const emailLog = await EmailLog.create({
                        taskId: task._id,
                        recipientEmail: user.email,
                        eventType: 'task_assigned',
                        subject,
                        status: 'pending'
                    });

                    const result = await sendEmail({
                        to: user.email,
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
                } catch (error) {
                    console.error(
                        'Loi gui email giao viec:',
                        error.message
                    );
                }
            }
        }

        const updatedTask = await Task.findById(taskId)
            .populate('assignedTo', 'fullName email')
            .populate('primaryAssigneeId', 'fullName email')
            .populate('assigneeProgress.user', 'fullName email');

        return res.json({
            message: 'Cap nhat nguoi duoc giao thanh cong',
            task: updatedTask
        });
    } catch (error) {
        console.error('Loi cap nhat nguoi duoc giao:', error);

        return res.status(500).json({
            message: 'Khong the cap nhat nguoi duoc giao'
        });
    }
};

// POST /api/tasks/:id/accept
const acceptTask = async (req, res) => {
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

                    // Ghi lich su nhan cong viec
                    await logTaskActivity({
                        taskId: task._id,
                        userId: req.userId,
                        action: 'accepted',
                        description: 'Da chap nhan cong viec'
                    });
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
};

// PUT /api/tasks/:id/progress
const updateProgress = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const userId = String(req.userId);

        if (!mongoose.Types.ObjectId.isValid(id)) {
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
        // Lay tien do cu de ghi lich su thay doi
        const oldProgress = task.assigneeProgress.find(
            item => String(item.user) === userId
        );

        const oldProgressStatus = oldProgress
            ? oldProgress.status
            : 'not_started';

        const progress = task.assigneeProgress.find(
            item => String(item.user) === userId
        );

        if (progress) {
            progress.status = status;
            progress.updatedAt = new Date();
        } else {
            task.assigneeProgress.push({
                user: req.userId,
                status,
                updatedAt: new Date()
            });
        }

                await task.save();

                // Ghi lich su cap nhat tien do ca nhan
                if (oldProgressStatus !== status) {
                    await logTaskActivity({
                        taskId: task._id,
                        userId: req.userId,
                        action: 'progress_updated',
                        description: `Da cap nhat tien do: ${oldProgressStatus} -> ${status}`,
                        changes: {
                            oldStatus: oldProgressStatus,
                            newStatus: status
                        }
                    });
                }

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
};

module.exports = {
    getAssignment,
    updateAssignment,
    acceptTask,
    updateProgress
};
