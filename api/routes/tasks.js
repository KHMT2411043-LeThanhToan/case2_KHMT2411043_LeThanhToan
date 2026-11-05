
const express = require('express');
const mongoose = require('mongoose');
const Task = require('../models/Task');
const authenticateToken = require('../middleware/auth_middleware');

const router = express.Router();

const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);

const validPriorities = ['low', 'medium', 'high'];

// GET /api/tasks?type=created|assigned|accepted|shared
router.get('/', authenticateToken, async (req, res) => {
    try {
        const userId = req.userId;
        const type = req.query.type;

        const filters = {
            created: { createdBy: userId },
            assigned: { assignedTo: userId },
            accepted: { acceptedBy: userId },
            shared: { sharedWith: userId }
        };

        let filter;

        if (!type) {
            filter = {
                $or: [
                    { createdBy: userId },
                    { assignedTo: userId },
                    { acceptedBy: userId },
                    { sharedWith: userId }
                ]
            };
        } else if (filters[type]) {
            filter = filters[type];
        } else {
            return res.status(400).json({
                message: 'Loai cong viec khong hop le'
            });
        }

        const tasks = await Task.find(filter)
            .sort({ createdAt: -1 });

        return res.json(tasks);
    } catch (error) {
        console.error('Loi lay danh sach cong viec:', error);

        return res.status(500).json({
            message: 'Khong the lay danh sach cong viec'
        });
    }
});

// POST /api/tasks - tao cong viec
router.post('/', authenticateToken, async (req, res) => {
    try {
        const {
            title,
            description,
            assignedTo,
            sharedWith,
            priority
        } = req.body;

        if (typeof title !== 'string' || !title.trim()) {
            return res.status(400).json({
                message: 'Tieu de cong viec khong duoc de trong'
            });
        }

        if (
            description !== undefined &&
            typeof description !== 'string'
        ) {
            return res.status(400).json({
                message: 'Mo ta cong viec khong hop le'
            });
        }

        if (
            priority !== undefined &&
            !validPriorities.includes(priority)
        ) {
            return res.status(400).json({
                message: 'Muc do uu tien khong hop le'
            });
        }

        const assigned = assignedTo === undefined ? [] : assignedTo;
        const shared = sharedWith === undefined ? [] : sharedWith;

        if (
            !Array.isArray(assigned) ||
            !Array.isArray(shared) ||
            !assigned.every(isValidId) ||
            !shared.every(isValidId)
        ) {
            return res.status(400).json({
                message: 'Danh sach nguoi dung khong hop le'
            });
        }

        const task = await Task.create({
            title: title.trim(),
            description: description || '',
            priority: priority || 'medium',
            createdBy: req.userId,
            assignedTo: assigned,
            acceptedBy: [],
            sharedWith: shared
        });

        return res.status(201).json({
            message: 'Tao cong viec thanh cong',
            task
        });
    } catch (error) {
        console.error('Loi tao cong viec:', error);

        return res.status(500).json({
            message: 'Khong the tao cong viec'
        });
    }
});

// PUT /api/tasks/:id - chinh sua cong viec, trang thai va uu tien
router.put('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { title, description, status, priority } = req.body;

        if (!isValidId(id)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        // Chi nguoi tao cong viec moi duoc chinh sua
        if (String(task.createdBy) !== String(req.userId)) {
            return res.status(403).json({
                message: 'Ban khong co quyen chinh sua cong viec nay'
            });
        }

        if (
            title !== undefined &&
            (typeof title !== 'string' || !title.trim())
        ) {
            return res.status(400).json({
                message: 'Tieu de cong viec khong duoc de trong'
            });
        }

        if (
            description !== undefined &&
            typeof description !== 'string'
        ) {
            return res.status(400).json({
                message: 'Mo ta cong viec khong hop le'
            });
        }

        const validStatuses = [
            'not_started',
            'in_progress',
            'completed'
        ];

        if (
            status !== undefined &&
            !validStatuses.includes(status)
        ) {
            return res.status(400).json({
                message: 'Trang thai cong viec khong hop le'
            });
        }

        if (
            priority !== undefined &&
            !validPriorities.includes(priority)
        ) {
            return res.status(400).json({
                message: 'Muc do uu tien khong hop le'
            });
        }

        if (title !== undefined) {
            task.title = title.trim();
        }

        if (description !== undefined) {
            task.description = description;
        }

        if (status !== undefined) {
            task.status = status;
        }

        if (priority !== undefined) {
            task.priority = priority;
        }

        await task.save();

        return res.json({
            message: 'Cap nhat cong viec thanh cong',
            task
        });
    } catch (error) {
        console.error('Loi cap nhat cong viec:', error);

        return res.status(500).json({
            message: 'Khong the cap nhat cong viec'
        });
    }
});

// DELETE /api/tasks/:id - xoa cong viec
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;

        if (!isValidId(id)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        if (String(task.createdBy) !== String(req.userId)) {
            return res.status(403).json({
                message: 'Ban khong co quyen xoa cong viec nay'
            });
        }

        await Task.findByIdAndDelete(id);

        return res.json({
            message: 'Xoa cong viec thanh cong'
        });
    } catch (error) {
        console.error('Loi xoa cong viec:', error);

        return res.status(500).json({
            message: 'Khong the xoa cong viec'
        });
    }
});

// POST /api/tasks/:id/accept - nhan cong viec
router.post('/:id/accept', authenticateToken, async (req, res) => {
    try {
        if (!isValidId(req.params.id)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        const task = await Task.findById(req.params.id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        const userId = String(req.userId);

        const canAccept =
            task.assignedTo.some(id => String(id) === userId) ||
            task.sharedWith.some(id => String(id) === userId);

        if (!canAccept) {
            return res.status(403).json({
                message: 'Ban khong co quyen nhan cong viec nay'
            });
        }

        const alreadyAccepted = task.acceptedBy.some(
            id => String(id) === userId
        );

        if (!alreadyAccepted) {
            task.acceptedBy.push(req.userId);
            await task.save();
        }

        return res.json({
            message: 'Nhan cong viec thanh cong',
            task
        });
    } catch (error) {
        console.error('Loi nhan cong viec:', error);

        return res.status(500).json({
            message: 'Khong the nhan cong viec'
        });
    }
});

module.exports = router;
