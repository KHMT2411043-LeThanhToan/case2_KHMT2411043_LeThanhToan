
const express = require('express');
const router = express.Router();

const {
    register,
    login
} = require('../controllers/authController');

// API dang ky tai khoan
router.post('/register', register);

// API dang nhap
router.post('/login', login);

module.exports = router;
