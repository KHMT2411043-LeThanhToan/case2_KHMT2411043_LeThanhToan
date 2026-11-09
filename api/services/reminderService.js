
const cron = require('node-cron');
const Task = require('../models/Task');
const User = require('../models/User');
const EmailLog = require('../models/EmailLog');
const { sendEmail } = require('./emailService');

// D5: Kiem tra va gui email nhac viec truoc han 24 gio
const checkDueReminders = async () => {
    console.log('[Reminder] Bat dau kiem tra cong viec sap den han...');

    try {
        const now = new Date();
        const reminderLimit = new Date(
            now.getTime() + 24 * 60 * 60 * 1000
        );

        // Tim cong viec chua hoan thanh, co han trong 24 gio toi
        const tasks = await Task.find({
            status: { $ne: 'completed' },
            dueDate: {
                $gt: now,
                $lte: reminderLimit
            }
        });

        for (const task of tasks) {
            const recipientIds = new Set([
                ...task.assignedTo.map(id => String(id)),
                ...task.sharedWith.map(id => String(id))
            ]);

            // Khong gui cho nguoi tao neu ho khong duoc giao/chia se
            // Lay thong tin email cua nguoi nhan
            const recipients = await User.find({
                _id: { $in: [...recipientIds] }
            }).select('fullName email');

            for (const recipient of recipients) {
                if (!recipient.email) {
                    continue;
                }

                try {
                    // Kiem tra da gui email nhac han cho nguoi nay chua
                    const existingLog = await EmailLog.findOne({
                        taskId: task._id,
                        recipientEmail: recipient.email,
                        eventType: 'task_due_reminder',
                        status: 'sent'
                    });

                    if (existingLog) {
                        continue;
                    }

                    const subject =
                        `[TaskManager] Nhac nho: Cong viec "${task.title}" sap den han`;

                    const dueDateText = new Date(
                        task.dueDate
                    ).toLocaleString('vi-VN', {
                        timeZone: 'Asia/Ho_Chi_Minh'
                    });

                    const text = `
Xin chao ${recipient.fullName || 'ban'},

Day la email nhac nho ve cong viec sap den han.

Ten cong viec: ${task.title}
Mo ta: ${task.description || 'Khong co'}
Han hoan thanh: ${dueDateText}

Vui long dang nhap TaskManager de hoan thanh cong viec dung han.

Tran trong,
TaskManager
                    `;

                    // Tao log email
                    const emailLog = await EmailLog.create({
                        taskId: task._id,
                        recipientEmail: recipient.email,
                        eventType: 'task_due_reminder',
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

                        console.log(
                            `[Reminder] Da gui email den ${recipient.email}`
                        );
                    } else {
                        emailLog.status = 'failed';
                        emailLog.errorMessage = result.error;

                        console.error(
                            `[Reminder] Gui email that bai den ${recipient.email}`
                        );
                    }

                    await emailLog.save();

                } catch (recipientError) {
                    console.error(
                        `[Reminder] Loi xu ly ${recipient.email}:`,
                        recipientError.message
                    );
                }
            }
        }

        console.log('[Reminder] Hoan tat kiem tra cong viec.');

    } catch (error) {
        console.error('[Reminder] Loi kiem tra cong viec:', error.message);
    }
};

// Chay kiem tra moi gio mot lan
const startReminderJob = () => {
    cron.schedule('0 * * * *', () => {
        checkDueReminders();
    }, {
        timezone: 'Asia/Ho_Chi_Minh'
    });

    console.log('[Reminder] Da khoi dong lich nhac viec moi gio.');
};

module.exports = {
    startReminderJob,
    checkDueReminders
};
