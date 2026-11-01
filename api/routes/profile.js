const express = require('express');
const User = require('../models/User');
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

module.exports = router;