
const express = require('express');

const authenticateToken = require('../middleware/auth_middleware');

const {
    getAssignment,
    updateAssignment
} = require('../controllers/assignmentController');

const router = express.Router();

// Lay thong tin nguoi duoc giao
router.get('/:taskId', authenticateToken, getAssignment);

// Them, thay doi hoac xoa nguoi duoc giao
router.put('/:taskId', authenticateToken, updateAssignment);

module.exports = router;
