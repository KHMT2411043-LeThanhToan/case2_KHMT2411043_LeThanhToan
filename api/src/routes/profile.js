
const express = require('express');
const authenticateToken = require('../middleware/auth_middleware');

const {
    getProfile,
    updateProfile,
    changePassword
} = require('../controllers/userController');

const router = express.Router();

// Xem thong tin ca nhan
router.get('/', authenticateToken, getProfile);

// Cap nhat ho ten
router.put('/', authenticateToken, updateProfile);

// Doi mat khau
router.put('/change-password', authenticateToken, changePassword);

module.exports = router;
