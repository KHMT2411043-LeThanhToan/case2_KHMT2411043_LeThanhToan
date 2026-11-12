
const mongoose = require('mongoose');
const Notification = require('../models/Notification');

// GET /api/notifications
// Lay danh sach thong bao cua nguoi dung dang dang nhap
const getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({
            recipient: req.userId
        })
            .populate('sender', 'fullName email')
            .populate('task', 'title status priority dueDate')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            message: 'Lay danh sach thong bao thanh cong',
            notifications
        });
    } catch (error) {
        console.error('Loi lay danh sach thong bao:', error);

        return res.status(500).json({
            message: 'Khong the lay danh sach thong bao'
        });
    }
};

// GET /api/notifications/unread-count
// Dem so thong bao chua doc
const getUnreadCount = async (req, res) => {
    try {
        const unreadCount = await Notification.countDocuments({
            recipient: req.userId,
            isRead: false
        });

        return res.status(200).json({
            unreadCount
        });
    } catch (error) {
        console.error('Loi dem thong bao chua doc:', error);

        return res.status(500).json({
            message: 'Khong the dem thong bao chua doc'
        });
    }
};

// PATCH /api/notifications/:id/read
// Danh dau mot thong bao da doc
const markAsRead = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: 'ID thong bao khong hop le'
            });
        }

        const notification = await Notification.findOne({
            _id: id,
            recipient: req.userId
        });

        if (!notification) {
            return res.status(404).json({
                message: 'Khong tim thay thong bao'
            });
        }

        notification.isRead = true;
        await notification.save();

        return res.status(200).json({
            message: 'Danh dau thong bao da doc thanh cong',
            notification
        });
    } catch (error) {
        console.error('Loi danh dau thong bao da doc:', error);

        return res.status(500).json({
            message: 'Khong the danh dau thong bao da doc'
        });
    }
};

// PATCH /api/notifications/read-all
// Danh dau tat ca thong bao da doc
const markAllAsRead = async (req, res) => {
    try {
        await Notification.updateMany(
            {
                recipient: req.userId,
                isRead: false
            },
            {
                $set: { isRead: true }
            }
        );

        return res.status(200).json({
            message: 'Danh dau tat ca thong bao da doc thanh cong'
        });
    } catch (error) {
        console.error('Loi danh dau tat ca thong bao:', error);

        return res.status(500).json({
            message: 'Khong the danh dau tat ca thong bao da doc'
        });
    }
};

module.exports = {
    getNotifications,
    getUnreadCount,
    markAsRead,
    markAllAsRead
};
