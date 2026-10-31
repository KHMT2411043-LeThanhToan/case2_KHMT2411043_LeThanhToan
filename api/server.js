
const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Model cong viec
const Task = require('./models/Task');
const authRoutes = require('./routes/auth');

// Cho phep server doc du lieu JSON
app.use(express.json());
app.use('/api/auth', authRoutes);

// API kiem tra server
app.get('/', (req, res) => {
    res.send('Task Manager API is running!');
});

// API lay danh sach cong viec tu MongoDB
app.get('/api/tasks', async (req, res) => {
    try {
        const tasks = await Task.find().sort({ createdAt: -1 });
        res.json(tasks);
    } catch (error) {
        console.error('Loi lay danh sach cong viec:', error);
        res.status(500).json({
            message: 'Khong the lay danh sach cong viec'
        });
    }
});

// Ket noi MongoDB va khoi dong server
async function startServer() {
    try {
        if (!process.env.MONGODB_URI) {
            throw new Error('Chua cau hinh MONGODB_URI trong file .env');
        }

        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Da ket noi MongoDB thanh cong!');

        app.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`);
        });
    } catch (error) {
        console.error('Khong the ket noi MongoDB:', error.message);
        process.exit(1);
    }
}

startServer();
