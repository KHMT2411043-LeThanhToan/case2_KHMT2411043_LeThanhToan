
const express = require('express');
const authenticateToken = require('../middleware/auth_middleware');

const {
    getTasks,
    createTask,
    updateTask,
    deleteTask,
    getEmailLogs
} = require('../controllers/taskController');

const {
    acceptTask,
    updateProgress
} = require('../controllers/assignmentController');

const {
    shareTask,
    updateSharePermission,
    revokeShare
} = require('../controllers/taskShareController');

const router = express.Router();

// Quan ly cong viec
router.get('/', authenticateToken, getTasks);
router.post('/', authenticateToken, createTask);
router.put('/:id', authenticateToken, updateTask);
router.delete('/:id', authenticateToken, deleteTask);

// Giao va cap nhat tien do
router.post('/:id/accept', authenticateToken, acceptTask);
router.put('/:id/progress', authenticateToken, updateProgress);

// Chia se va phan quyen
router.post('/:id/shares', authenticateToken, shareTask);
router.put('/:id/shares/:userId', authenticateToken, updateSharePermission);
router.delete('/:id/shares/:userId', authenticateToken, revokeShare);

// Lich su email
router.get('/:id/email-logs', authenticateToken, getEmailLogs);

module.exports = router;
