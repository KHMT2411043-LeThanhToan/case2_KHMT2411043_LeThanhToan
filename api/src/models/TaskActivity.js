
const mongoose = require('mongoose');

const taskActivitySchema = new mongoose.Schema(
    {
        taskId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Task',
            required: true,
            index: true
        },

        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },

        action: {
            type: String,
            required: true,
            enum: [
                'created',
                'updated',
                'status_changed',
                'assigned',
                'assignment_removed',
                'accepted',
                'progress_updated',
                'shared',
                'permission_changed',
                'share_revoked'
            ]
        },

        description: {
            type: String,
            required: true,
            trim: true
        },

        changes: {
            type: mongoose.Schema.Types.Mixed,
            default: null
        }
    },
    {
        timestamps: true
    }
);

taskActivitySchema.index({
    taskId: 1,
    createdAt: -1
});

module.exports = mongoose.model(
    'TaskActivity',
    taskActivitySchema
);
