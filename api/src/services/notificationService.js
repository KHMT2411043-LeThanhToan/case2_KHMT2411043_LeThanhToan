
const Notification = require('../models/Notification');

const createNotifications = async ({
    recipients,
    sender,
    task,
    type,
    message
}) => {
    if (!Array.isArray(recipients) || recipients.length === 0) {
        return;
    }

    const uniqueRecipients = [
        ...new Set(recipients.map(id => String(id)))
    ].filter(id => id !== String(sender));

    if (uniqueRecipients.length === 0) {
        return;
    }

    await Notification.insertMany(
        uniqueRecipients.map(recipient => ({
            recipient,
            sender,
            task,
            type,
            message
        }))
    );
};

module.exports = { createNotifications };
