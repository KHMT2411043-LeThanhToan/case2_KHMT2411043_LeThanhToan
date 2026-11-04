
const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: true,
            trim: true
        },
        description: {
            type: String,
            default: ''
        },

        // Trang thai cong viec
        status: {
            type: String,
            enum: [
                'not_started',
                'in_progress',
                'completed'
            ],
            default: 'not_started'
        },

        // Nguoi tao cong viec
        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },

        // Nguoi duoc giao cong viec
        assignedTo: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }],

        // Nguoi da nhan cong viec
        acceptedBy: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }],

        // Nguoi duoc chia se cong viec
        sharedWith: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }]
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model('Task', taskSchema);
