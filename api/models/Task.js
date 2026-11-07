
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

                // Muc do uu tien cong viec
                priority: {
                    type: String,
                    enum: [
                        'low',
                        'medium',
                        'high'
                    ],
                    default: 'medium'
                },

                // Ngay bat dau cong viec
                startDate: {
                    type: Date,
                    default: null
                },

                // Han hoan thanh cong viec
                dueDate: {
                    type: Date,
                    default: null
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

        // Nguoi phu trach chinh
        primaryAssigneeId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            default: null
        },

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
