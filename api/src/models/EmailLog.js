
const mongoose = require('mongoose');

const emailLogSchema = new mongoose.Schema({
    taskId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Task',
        default: null,
    },
    recipientEmail: {
        type: String,
        required: true,
        trim: true,
    },
    eventType: {
        type: String,
        required: true,
    },
    subject: {
        type: String,
        required: true,
    },
    status: {
        type: String,
        enum: ['pending', 'sent', 'failed'],
        default: 'pending',
    },
    attempts: {
        type: Number,
        default: 0,
    },
    errorMessage: {
        type: String,
        default: null,
    },
    sentAt: {
        type: Date,
        default: null,
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model('EmailLog', emailLogSchema);
