
const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/User');
const authenticateToken = require('../middleware/auth_middleware');

const router = express.Router();

// GET /api/users/search?q=
router.get('/search', authenticateToken, async (req, res) => {
    try {
        const q = req.query.q;

        if (typeof q !== 'string' || !q.trim()) {
            return res.status(400).json({
                message: 'Vui long nhap ten hoac email can tim'
            });
        }

        const keyword = q.trim();

        const users = await User.find({
            $or: [
                { fullName: { $regex: keyword, $options: 'i' } },
                { email: { $regex: keyword, $options: 'i' } }
            ]
        })
        .select('_id fullName email')
        .limit(20);

        return res.json(users);
    } catch (error) {
        console.error('Loi tim kiem nguoi dung:', error);

        return res.status(500).json({
            message: 'Khong the tim kiem nguoi dung'
        });
    }
});

module.exports = router;
