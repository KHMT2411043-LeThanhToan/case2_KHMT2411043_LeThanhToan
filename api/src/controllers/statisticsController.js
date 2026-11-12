
const mongoose = require('mongoose');
const Task = require('../models/Task');

// GET /api/statistics/tasks-by-status
const getTaskStatisticsByStatus = async (req, res) => {
    try {
        const userId = new mongoose.Types.ObjectId(req.userId);

        // Chi thong ke cac cong viec ma nguoi dung co the xem
        const userTaskFilter = {
            $or: [
                { createdBy: userId },
                { assignedTo: userId },
                { acceptedBy: userId },
                { sharedWith: userId }
            ]
        };

        // Dem so luong cong viec theo tung trang thai
        const statistics = await Task.aggregate([
            {
                $match: userTaskFilter
            },
            {
                $group: {
                    _id: '$status',
                    total: { $sum: 1 }
                }
            }
        ]);

        const result = {
            not_started: 0,
            in_progress: 0,
            completed: 0,
            total: 0
        };

        statistics.forEach(item => {
            result[item._id] = item.total;
            result.total += item.total;
        });

        return res.json({
            message: 'Lay thong ke cong viec thanh cong',
            statistics: result
        });
    } catch (error) {
        console.error('Loi lay thong ke cong viec:', error);

        return res.status(500).json({
            message: 'Khong the lay thong ke cong viec'
        });
    }
};

// GET /api/statistics/assignments
const getAssignmentStatistics = async (req, res) => {
    try {
        const userId = new mongoose.Types.ObjectId(req.userId);

        // Dem cong viec duoc giao cho nguoi dung hien tai
        const assigned = await Task.countDocuments({
            assignedTo: userId
        });

        // Dem cong viec nguoi dung hien tai phu trach chinh
        const responsible = await Task.countDocuments({
            primaryAssigneeId: userId
        });

        return res.json({
            message: 'Lay thong ke cong viec duoc giao va phu trach thanh cong',
            statistics: {
                assigned,
                responsible
            }
        });
    } catch (error) {
        console.error('Loi lay thong ke cong viec duoc giao va phu trach:', error);

        return res.status(500).json({
            message: 'Khong the lay thong ke cong viec duoc giao va phu trach'
        });
    }
};

module.exports = {
    getTaskStatisticsByStatus,
    getAssignmentStatistics
};
