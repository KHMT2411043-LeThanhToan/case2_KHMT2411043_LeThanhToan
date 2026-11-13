
const express = require('express');

const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const taskRoutes = require('./routes/tasks');
const userRoutes = require('./routes/users');
const assignmentRoutes = require('./routes/assignmentRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const statisticsRoutes = require('./routes/statisticsRoutes');
const app = express();
const deadlineRoutes = require('./routes/deadlineRoutes');
const activityRoutes = require('./routes/activityRoutes');
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/tasks', activityRoutes);
app.use('/api/users', userRoutes);
app.use('/api/assignments', assignmentRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/statistics', statisticsRoutes);
app.use('/api/deadlines', deadlineRoutes);
app.get('/', (req, res) => {
    res.send('Task Manager API is running!');
});

module.exports = app;
