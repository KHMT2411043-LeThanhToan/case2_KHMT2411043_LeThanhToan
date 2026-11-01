const express = require('express');
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const authenticateToken = require('../middleware/auth_middleware');

const router = express.Router();

// API xem thong tin ca nhan
router.get('/', authenticateToken, async (req, res) => {
    try {
        const user = await User.findById(req.userId);

        if (!user) {
            return res.status(404).json({
                message: 'Khong tim thay tai khoan'
            });
        }

        return res.json({
            user: {
                id: user._id,
                fullName: user.fullName,
                email: user.email
            }
        });
    } catch (error) {
        console.error('Loi lay ho so:', error.message);
        return res.status(500).json({
            message: 'Khong the lay thong tin ca nhan'
        });
    }
});

// API cap nhat ho ten
router.put('/', authenticateToken, async (req, res) => {
    try {
        const { fullName } = req.body;

        if (typeof fullName !== 'string' || !fullName.trim()) {
            return res.status(400).json({
                message: 'Ho ten khong duoc de trong'
            });
        }

        const user = await User.findByIdAndUpdate(
            req.userId,
            { fullName: fullName.trim() },
            { new: true, runValidators: true }
        );

        if (!user) {
            return res.status(404).json({
                message: 'Khong tim thay tai khoan'
            });
        }

        return res.json({
            message: 'Cap nhat thong tin thanh cong',
            user: {
                id: user._id,
                fullName: user.fullName,
                email: user.email
            }
        });
    } catch (error) {
        console.error('Loi cap nhat ho so:', error.message);
        return res.status(500).json({
            message: 'Khong the cap nhat thong tin ca nhan'
        });
    }
});
// API doi mat khau
router.put('/change-password', authenticateToken, async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (
            typeof currentPassword !== 'string' ||
            typeof newPassword !== 'string' ||
            !currentPassword ||
            !newPassword
        ) {
            return res.status(400).json({
                message: 'Vui long nhap day du mat khau'
            });
        }

        if (newPassword.length < 8) {
            return res.status(400).json({
                message: 'Mat khau moi phai co it nhat 8 ky tu'
            });
        }

        const user = await User.findById(req.userId).select('+password');

        if (!user) {
            return res.status(404).json({
                message: 'Khong tim thay tai khoan'
            });
        }

        const isMatch = await bcrypt.compare(
            currentPassword,
            user.password
        );

        if (!isMatch) {
            return res.status(400).json({
                message: 'Mat khau hien tai khong chinh xac'
            });
        }

        user.password = await bcrypt.hash(newPassword, 10);
        await user.save();

        return res.json({
            message: 'Doi mat khau thanh cong'
        });
    } catch (error) {
        console.error('Loi doi mat khau:', error.message);
        return res.status(500).json({
            message: 'Khong the doi mat khau'
        });
    }
});
module.exports = router;