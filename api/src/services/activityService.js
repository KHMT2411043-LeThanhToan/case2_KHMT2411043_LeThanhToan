
const TaskActivity = require('../models/TaskActivity');

const logTaskActivity = async ({
    taskId,
    userId,
    action,
    description,
    changes = null
}) => {
    try {
        return await TaskActivity.create({
            taskId,
            userId,
            action,
            description,
            changes
        });
    } catch (error) {
        console.error(
            'Loi ghi lich su hoat dong:',
            error.message
        );

        return null;
    }
};

module.exports = {
    logTaskActivity
};
