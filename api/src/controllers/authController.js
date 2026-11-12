
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Tao JWT token
const createToken = (user) => {
    const secret = process.env.JWT_SECRET;

    if (!secret) {
        throw new Error('Chua cau hinh JWT_SECRET trong file .env');
    }

    return jwt.sign(
        { userId: user._id.toString() },
        secret,
        { expiresIn: '7d' }
    );
};

// Tao du lieu nguoi dung tra ve client
const formatUser = (user) => ({
    id: user._id,
    fullName: user.fullName,
    email: user.email
});

// Xu ly dang ky tai khoan
const register = async (req, res) => {
    try {
        const { fullName, email, password } = req.body;

        // Kiem tra du lieu dau vao
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

        // Kiem tra email da ton tai
        const existingUser = await User.findOne({
            email: normalizedEmail
        });

        if (existingUser) {
            return res.status(409).json({
                message: 'Email da duoc dang ky'
            });
        }

        // Ma hoa mat khau
        const hashedPassword = await bcrypt.hash(password, 12);

        // Tao tai khoan
        const user = await User.create({
            fullName: fullName.trim(),
            email: normalizedEmail,
            password: hashedPassword
        });

        const token = createToken(user);

        return res.status(201).json({
            message: 'Dang ky tai khoan thanh cong',
            token,
            user: formatUser(user)
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
};

// Xu ly dang nhap
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Kiem tra du lieu dau vao
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

        const normalizedEmail = email.trim().toLowerCase();

        // Tim tai khoan
        const user = await User.findOne({
            email: normalizedEmail
        }).select('+password');

        if (!user) {
            return res.status(401).json({
                message: 'Email hoac mat khau khong dung'
            });
        }

        // Kiem tra mat khau
        const isPasswordValid = await bcrypt.compare(
            password,
            user.password
        );

        if (!isPasswordValid) {
            return res.status(401).json({
                message: 'Email hoac mat khau khong dung'
            });
        }

        const token = createToken(user);

        return res.json({
            message: 'Dang nhap thanh cong',
            token,
            user: formatUser(user)
        });
    } catch (error) {
        console.error('Loi dang nhap:', error.message);

        return res.status(500).json({
            message: 'Khong the dang nhap'
        });
    }
};

module.exports = {
    register,
    login
};
