
const express = require('express');
const authenticateToken = require('../middleware/auth_middleware');

const {
    getTaskStatisticsByStatus,
    getAssignmentStatistics
} = require('../controllers/statisticsController');

const router = express.Router();

// E1: Thong ke so luong cong viec theo trang thai
router.get('/tasks-by-status', authenticateToken, getTaskStatisticsByStatus);

// E2: Thong ke cong viec duoc giao va cong viec phu trach
router.get('/assignments', authenticateToken, getAssignmentStatistics);

module.exports = router;
