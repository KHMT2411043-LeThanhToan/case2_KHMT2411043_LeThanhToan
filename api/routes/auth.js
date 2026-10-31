
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// Tao JWT token
function createToken(user) {
    if (!process.env.JWT_SECRET) {
        throw new Error('Chua cau hinh JWT_SECRET trong file .env');
    }

    return jwt.sign(
        { userId: user._id.toString() },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
    );
}

// API dang ky tai khoan
router.post('/register', async (req, res) => {
    try {
        const { fullName, email, password } = req.body;

        if (
            typeof fullName !== 'string' ||
            typeof email !== 'string' ||
            typeof password !== 'string' ||
            !fullName.trim() ||
            !email.trim() ||
            !password
        ) {
            return res.status(400).json({
                message: 'Vui long nhap ho ten, email va mat khau'
            });
        }

        if (password.length < 8) {
            return res.status(400).json({
                message: 'Mat khau phai co it nhat 8 ky tu'
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        const existingUser = await User.findOne({
            email: normalizedEmail
        });

        if (existingUser) {
            return res.status(409).json({
                message: 'Email da duoc dang ky'
            });
        }

        const hashedPassword = await bcrypt.hash(password, 12);

        const user = await User.create({
            fullName: fullName.trim(),
            email: normalizedEmail,
            password: hashedPassword
        });

        const token = createToken(user);

        return res.status(201).json({
            message: 'Dang ky tai khoan thanh cong',
            token,
            user: {
                id: user._id,
                fullName: user.fullName,
                email: user.email
            }
        });
    } catch (error) {
        if (error.code === 11000) {
            return res.status(409).json({
                message: 'Email da duoc dang ky'
            });
        }

        console.error('Loi dang ky:', error.message);
        return res.status(500).json({
            message: 'Khong the dang ky tai khoan'
        });
    }
});

// API dang nhap
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (
            typeof email !== 'string' ||
            typeof password !== 'string' ||
            !email.trim() ||
            !password
        ) {
            return res.status(400).json({
                message: 'Vui long nhap email va mat khau'
            });
        }

        const user = await User.findOne({
            email: email.trim().toLowerCase()
        }).select('+password');

        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(401).json({
                message: 'Email hoac mat khau khong dung'
            });
        }

        const token = createToken(user);

        return res.json({
            message: 'Dang nhap thanh cong',
            token,
            user: {
                id: user._id,
                fullName: user.fullName,
                email: user.email
            }
        });
    } catch (error) {
        console.error('Loi dang nhap:', error.message);
        return res.status(500).json({
            message: 'Khong the dang nhap'
        });
    }
});

module.exports = router;
