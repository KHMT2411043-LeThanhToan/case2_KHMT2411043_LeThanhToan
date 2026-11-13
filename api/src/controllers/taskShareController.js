
const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/User');
const EmailLog = require('../models/EmailLog');
const { sendEmail } = require('../services/emailService');
const { createNotifications } = require('../services/notificationService');
const { logTaskActivity } = require('../services/activityService');

// POST /api/tasks/:id/shares
const shareTask = async (req, res) => {
    try {
        const { id } = req.params;
        const { userId, permission = 'viewer' } = req.body;

        if (
            !mongoose.Types.ObjectId.isValid(id) ||
            !mongoose.Types.ObjectId.isValid(userId)
        ) {
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

        // Ghi lich su chia se cong viec
        await logTaskActivity({
            taskId: task._id,
            userId: req.userId,
            action: 'shared',
            description: `Da chia se cong viec voi ${invitedUser.fullName}`,
            changes: {
                sharedWith: userId,
                permission
            }
        });


        // Tao thong bao trong ung dung
        try {
            await createNotifications({
                recipients: [userId],
                sender: req.userId,
                task: task._id,
                type: 'task_shared',
                message: `Ban duoc chia se cong viec: ${task.title}`
            });
        } catch (notificationError) {
            console.error(
                'Loi tao thong bao chia se:',
                notificationError.message
            );
        }

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
};

// PUT /api/tasks/:id/shares/:userId
const updateSharePermission = async (req, res) => {
    try {
        const { id, userId } = req.params;
        const { permission } = req.body;

        if (
            !mongoose.Types.ObjectId.isValid(id) ||
            !mongoose.Types.ObjectId.isValid(userId)
        ) {
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

        const oldPermission = share
            ? share.permission
            : 'viewer';


        if (share) {
            share.permission = permission;
        } else {
            task.sharedPermissions.push({
                user: userId,
                permission
            });
        }

                await task.save();

                // Ghi lich su thay doi quyen chia se
                if (oldPermission !== permission) {
                    await logTaskActivity({
                        taskId: task._id,
                        userId: req.userId,
                        action: 'permission_changed',
                        description: `Da thay doi quyen chia se: ${oldPermission} -> ${permission}`,
                        changes: {
                            sharedUserId: userId,
                            oldPermission,
                            newPermission: permission
                        }
                    });
                }

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
};

// DELETE /api/tasks/:id/shares/:userId
const revokeShare = async (req, res) => {
    try {
        const { id, userId } = req.params;

        if (
            !mongoose.Types.ObjectId.isValid(id) ||
            !mongoose.Types.ObjectId.isValid(userId)
        ) {
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

        // Lay thong tin nguoi duoc thu hoi quyen
        const revokedPermission = task.sharedPermissions.find(
            item => String(item.user) === String(userId)
        );

        const oldPermission = revokedPermission
            ? revokedPermission.permission
            : 'viewer';


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

                // Ghi lich su thu hoi quyen chia se
                await logTaskActivity({
                    taskId: task._id,
                    userId: req.userId,
                    action: 'share_revoked',
                    description: 'Da thu hoi quyen chia se cong viec',
                    changes: {
                        sharedUserId: userId,
                        oldPermission
                    }
                });

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
};

module.exports = {
    shareTask,
    updateSharePermission,
    revokeShare
};
