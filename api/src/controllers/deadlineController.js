
const mongoose = require('mongoose');
const Task = require('../models/Task');

// GET /api/deadlines
// Lay danh sach cong viec sap den han va qua han
const getDeadlineTasks = async (req, res) => {
    try {
        const userId = new mongoose.Types.ObjectId(req.userId);

        const now = new Date();

        // Moc thoi gian 7 ngay tiep theo
        const sevenDaysLater = new Date(now);
        sevenDaysLater.setDate(sevenDaysLater.getDate() + 7);

        // Dieu kien cong viec nguoi dung co quyen xem
        const userTaskFilter = {
            $or: [
                { createdBy: userId },
                { assignedTo: userId },
                { acceptedBy: userId },
                { sharedWith: userId }
            ]
        };

        // Lay cong viec sap den han
        const upcomingTasks = await Task.find({
            $and: [
                userTaskFilter,
                {
                    dueDate: {
                        $gte: now,
                        $lte: sevenDaysLater
                    }
                },
                {
                    status: { $ne: 'completed' }
                }
            ]
        })
            .sort({ dueDate: 1 })
            .select('title description status priority startDate dueDate');

        // Lay cong viec qua han
        const overdueTasks = await Task.find({
            $and: [
                userTaskFilter,
                {
                    dueDate: { $lt: now }
                },
                {
                    status: { $ne: 'completed' }
                }
            ]
        })
            .sort({ dueDate: 1 })
            .select('title description status priority startDate dueDate');

        return res.json({
            message: 'Lay danh sach cong viec sap den han va qua han thanh cong',
            statistics: {
                upcoming: upcomingTasks.length,
                overdue: overdueTasks.length
            },
            upcomingTasks,
            overdueTasks
        });
    } catch (error) {
        console.error(
            'Loi lay danh sach cong viec sap den han va qua han:',
            error
        );

        return res.status(500).json({
            message: 'Khong the lay danh sach cong viec sap den han va qua han'
        });
    }
};

module.exports = {
    getDeadlineTasks
};
