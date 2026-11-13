
const mongoose = require('mongoose');
const Task = require('../models/Task');
const TaskActivity = require('../models/TaskActivity');

// GET /api/tasks/:id/activities
const getTaskActivities = async (req, res) => {
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

        const currentUserId = String(req.userId);

        const isCreator =
            String(task.createdBy) === currentUserId;

        const isAssignee = task.assignedTo.some(
            user => String(user) === currentUserId
        );

        const isAccepted = task.acceptedBy.some(
            user => String(user) === currentUserId
        );

        const isShared = task.sharedWith.some(
            user => String(user) === currentUserId
        );

        if (!isCreator && !isAssignee && !isAccepted && !isShared) {
            return res.status(403).json({
                message: 'Ban khong co quyen xem lich su cong viec'
            });
        }

        const activities = await TaskActivity.find({
            taskId: id
        })
            .populate('userId', 'fullName email')
            .sort({ createdAt: -1 });

        return res.json({
            taskId: id,
            total: activities.length,
            activities
        });
    } catch (error) {
        console.error('Loi lay lich su hoat dong:', error);

        return res.status(500).json({
            message: 'Khong the lay lich su hoat dong'
        });
    }
};

module.exports = {
    getTaskActivities
};
