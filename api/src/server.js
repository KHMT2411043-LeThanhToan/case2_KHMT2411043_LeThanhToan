
require('dotenv').config({
    path: require('path').resolve(__dirname, '../.env')
});

const app = require('./app');
const connectDatabase = require('./config/database');
const { startReminderJob } = require('./services/reminderService');

const PORT = process.env.PORT || 5000;

async function startServer() {
    try {
        await connectDatabase();

        // Khoi dong lich gui email nhac viec
        startReminderJob();

        app.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`);
        });
    } catch (error) {
        console.error(
            'Khong the khoi dong server:',
            error.message
        );
        process.exit(1);
    }
}

startServer();
