
const User = require('../models/User');
const bcrypt = require('bcryptjs');

// Chuan hoa du lieu nguoi dung tra ve client
const formatUser = (user) => ({
    id: user._id,
    fullName: user.fullName,
    email: user.email
});

// Bao ve ky tu dac biet trong Regex
const escapeRegex = (value) => {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
};

// Tim kiem nguoi dung theo ten hoac email
const searchUsers = async (req, res) => {
    try {
        const q = req.query.q;

        if (typeof q !== 'string' || !q.trim()) {
            return res.status(400).json({
                message: 'Vui long nhap ten hoac email can tim'
            });
        }

        const keyword = escapeRegex(q.trim());

        const users = await User.find({
            $or: [
                { fullName: { $regex: keyword, $options: 'i' } },
                { email: { $regex: keyword, $options: 'i' } }
            ]
        })
            .select('_id fullName email')
            .limit(20)
            .lean();

        return res.json(users);
    } catch (error) {
        console.error('Loi tim kiem nguoi dung:', error.message);

        return res.status(500).json({
            message: 'Khong the tim kiem nguoi dung'
        });
    }
};

// Xem thong tin ca nhan
const getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.userId);

        if (!user) {
            return res.status(404).json({
                message: 'Khong tim thay tai khoan'
            });
        }

        return res.json({
            user: formatUser(user)
        });
    } catch (error) {
        console.error('Loi lay ho so:', error.message);

        return res.status(500).json({
            message: 'Khong the lay thong tin ca nhan'
        });
    }
};

// Cap nhat ho ten
const updateProfile = async (req, res) => {
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
            {
                new: true,
                runValidators: true
            }
        );

        if (!user) {
            return res.status(404).json({
                message: 'Khong tim thay tai khoan'
            });
        }

        return res.json({
            message: 'Cap nhat thong tin thanh cong',
            user: formatUser(user)
        });
    } catch (error) {
        console.error('Loi cap nhat ho so:', error.message);

        if (error.name === 'ValidationError') {
            return res.status(400).json({
                message: 'Thong tin cap nhat khong hop le'
            });
        }

        return res.status(500).json({
            message: 'Khong the cap nhat thong tin ca nhan'
        });
    }
};

// Doi mat khau
const changePassword = async (req, res) => {
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

        if (currentPassword === newPassword) {
            return res.status(400).json({
                message: 'Mat khau moi phai khac mat khau hien tai'
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

        user.password = await bcrypt.hash(newPassword, 12);
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
};

module.exports = {
    searchUsers,
    getProfile,
    updateProfile,
    changePassword
};
