
const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const taskRoutes = require('./routes/tasks');
const userRoutes = require('./routes/users');
const { startReminderJob } = require('./services/reminderService');
const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/users', userRoutes);
app.get('/', (req, res) => {
    res.send('Task Manager API is running!');
});

async function startServer() {
    try {
        if (!process.env.MONGODB_URI) {
            throw new Error(
                'Chua cau hinh MONGODB_URI trong file .env'
            );
        }

        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Da ket noi MongoDB thanh cong!');
// Chuyen doi du lieu trang thai cong viec cu
const taskCollection = mongoose.connection.collection('tasks');

// Cong viec da hoan thanh
await taskCollection.updateMany(
    {
        status: { $exists: false },
        completed: true
    },
    {
        $set: { status: 'completed' },
        $unset: { completed: '' }
    }
);

// Cong viec chua hoan thanh hoac chua co trang thai
await taskCollection.updateMany(
    {
        status: { $exists: false }
    },
    {
        $set: { status: 'not_started' },
        $unset: { completed: '' }
    }
);

// Xoa truong completed cu neu con ton tai
await taskCollection.updateMany(
    {
        completed: { $exists: true }
    },
    {
        $unset: { completed: '' }
    }
);

console.log('Da chuyen doi trang thai cong viec cu thanh cong!');

// D5: Khoi dong lich gui email nhac viec
startReminderJob();

app.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`);
        });
    } catch (error) {
        console.error(
            'Khong the ket noi MongoDB:',
            error.message
        );
        process.exit(1);
    }
}

startServer();
