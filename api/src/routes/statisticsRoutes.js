
const express = require('express');
const authenticateToken = require('../middleware/auth_middleware');

const {
    getTaskStatisticsByStatus
} = require('../controllers/statisticsController');

const router = express.Router();

// Thong ke so luong cong viec theo trang thai
router.get('/tasks-by-status', authenticateToken, getTaskStatisticsByStatus);

module.exports = router;
