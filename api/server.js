
const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const taskRoutes = require('./routes/tasks');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/tasks', taskRoutes);

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
