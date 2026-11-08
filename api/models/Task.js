
const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema(
    {
        title: { type: String, required: true, trim: true },
        description: { type: String, default: '' },

        status: {
            type: String,
            enum: ['not_started', 'in_progress', 'completed'],
            default: 'not_started'
        },

        priority: {
            type: String,
            enum: ['low', 'medium', 'high'],
            default: 'medium'
        },

        startDate: { type: Date, default: null },
        dueDate: { type: Date, default: null },

        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },

        assignedTo: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User'
            }
        ],

        primaryAssigneeId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            default: null
        },

        acceptedBy: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User'
            }
        ],
// Tien do cua tung nguoi duoc giao
assigneeProgress: [
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },

        status: {
            type: String,
            enum: ['not_started', 'in_progress', 'completed'],
            default: 'not_started'
        },

        updatedAt: {
            type: Date,
            default: Date.now
        }
    }
],
        // Danh sach nguoi duoc chia se cong viec
        sharedWith: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User'
            }
        ],

        // Quyen cua tung nguoi duoc chia se
        sharedPermissions: [
            {
                user: {
                    type: mongoose.Schema.Types.ObjectId,
                    ref: 'User',
                    required: true
                },

                permission: {
                    type: String,
                    enum: ['viewer', 'editor'],
                    default: 'viewer'
                }
            }
        ]
    },
    { timestamps: true }
);

module.exports = mongoose.model('Task', taskSchema);
