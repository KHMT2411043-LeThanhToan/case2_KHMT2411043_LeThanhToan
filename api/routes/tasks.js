
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
            .populate('assignedTo', 'fullName email')
            .populate('primaryAssigneeId', 'fullName email')
            .populate('sharedWith', 'fullName email')
            .populate('sharedPermissions.user', 'fullName email')
            .populate('assigneeProgress.user', 'fullName email')
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
            primaryAssigneeId,
            sharedWith,
            sharedPermissions,
            priority,
            startDate,
            dueDate
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
// Kiem tra ngay bat dau va han hoan thanh
const parsedStartDate =
    startDate === undefined || startDate === null || startDate === ''
        ? null
        : new Date(startDate);

const parsedDueDate =
    dueDate === undefined || dueDate === null || dueDate === ''
        ? null
        : new Date(dueDate);

if (
    (parsedStartDate !== null &&
        Number.isNaN(parsedStartDate.getTime())) ||
    (parsedDueDate !== null &&
        Number.isNaN(parsedDueDate.getTime()))
) {
    return res.status(400).json({
        message: 'Ngay bat dau hoac han hoan thanh khong hop le'
    });
}

if (
    parsedStartDate !== null &&
    parsedDueDate !== null &&
    parsedDueDate < parsedStartDate
) {
    return res.status(400).json({
        message: 'Han hoan thanh khong duoc som hon ngay bat dau'
    });
}
        const assigned = assignedTo === undefined ? [] : assignedTo;
        const shared = sharedWith === undefined ? [] : sharedWith;

        const permissions =
            sharedPermissions === undefined ? [] : sharedPermissions;

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

        // Kiem tra quyen chia se
        if (!Array.isArray(permissions)) {
            return res.status(400).json({
                message: 'Danh sach quyen chia se khong hop le'
            });
        }

        for (const item of permissions) {
            if (
                !item ||
                !isValidId(item.user) ||
                !['viewer', 'editor'].includes(item.permission) ||
                !shared.some(id => String(id) === String(item.user))
            ) {
                return res.status(400).json({
                    message: 'Thong tin quyen chia se khong hop le'
                });
            }
        }

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

        if (
            primaryAssigneeId !== undefined &&
            primaryAssigneeId !== null &&
            (
                !isValidId(primaryAssigneeId) ||
                !assigned.some(id => String(id) === String(primaryAssigneeId))
            )
        ) {
            return res.status(400).json({
                message: 'Nguoi phu trach chinh phai nam trong danh sach nguoi duoc giao'
            });
        }

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
            startDate: parsedStartDate,
            dueDate: parsedDueDate,
            createdBy: req.userId,
            assignedTo: assigned,
            primaryAssigneeId: primaryAssigneeId || null,
            acceptedBy: [],

            // Khoi tao tien do cho tung nguoi duoc giao
            assigneeProgress: assigned.map(userId => ({
                user: userId,
                status: 'not_started',
                updatedAt: new Date()
            })),
            sharedWith: shared,
            sharedPermissions: permissions
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
        const {
            title,
            description,
            status,
            priority,
            startDate,
            dueDate
        } = req.body;

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

        // Nguoi tao cong viec co toan quyen chinh sua
        const isCreator =
            String(task.createdBy) === String(req.userId);

        // Nguoi duoc chia se co quyen editor duoc phep chinh sua
        const isEditor = task.sharedPermissions.some(item =>
            String(item.user) === String(req.userId) &&
            item.permission === 'editor'
        );

        // Chi creator hoac editor duoc chinh sua
        if (!isCreator && !isEditor) {
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
// Kiem tra ngay bat dau va han hoan thanh
const parsedStartDate =
    startDate === undefined
        ? task.startDate
        : startDate === null || startDate === ''
            ? null
            : new Date(startDate);

const parsedDueDate =
    dueDate === undefined
        ? task.dueDate
        : dueDate === null || dueDate === ''
            ? null
            : new Date(dueDate);

if (
    (parsedStartDate != null &&
        Number.isNaN(new Date(parsedStartDate).getTime())) ||
    (parsedDueDate != null &&
        Number.isNaN(new Date(parsedDueDate).getTime()))
) {
    return res.status(400).json({
        message: 'Ngay bat dau hoac han hoan thanh khong hop le'
    });
}

if (
    parsedStartDate != null &&
    parsedDueDate != null &&
    new Date(parsedDueDate) < new Date(parsedStartDate)
) {
    return res.status(400).json({
        message: 'Han hoan thanh khong duoc som hon ngay bat dau'
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
task.startDate = parsedStartDate;
task.dueDate = parsedDueDate;
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


// PUT /api/tasks/:id/progress - cap nhat tien do ca nhan
router.put('/:id/progress', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const userId = String(req.userId);

        if (!isValidId(id)) {
            return res.status(400).json({
                message: 'ID cong viec khong hop le'
            });
        }

        const validStatuses = [
            'not_started',
            'in_progress',
            'completed'
        ];

        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                message: 'Trang thai tien do khong hop le'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        // Chi nguoi duoc giao moi duoc cap nhat tien do cua minh
        const isAssignee = task.assignedTo.some(
            user => String(user) === userId
        );

        if (!isAssignee) {
            return res.status(403).json({
                message: 'Ban khong phai nguoi duoc giao cong viec nay'
            });
        }

        // Tim tien do hien tai cua nguoi dung
        const progress = task.assigneeProgress.find(
            item => String(item.user) === userId
        );

        if (progress) {
            progress.status = status;
            progress.updatedAt = new Date();
        } else {
            // Tao tien do neu cong viec cu chua co du lieu
            task.assigneeProgress.push({
                user: req.userId,
                status: status,
                updatedAt: new Date()
            });
        }

        await task.save();

        return res.json({
            message: 'Cap nhat tien do thanh cong',
            assigneeProgress: task.assigneeProgress
        });
    } catch (error) {
        console.error('Loi cap nhat tien do:', error);

        return res.status(500).json({
            message: 'Khong the cap nhat tien do'
        });
    }
});


// PUT /api/tasks/:id/shares/:userId - thay doi quyen chia se
router.put('/:id/shares/:userId', authenticateToken, async (req, res) => {
    try {
        const { id, userId } = req.params;
        const { permission } = req.body;

        if (!isValidId(id) || !isValidId(userId)) {
            return res.status(400).json({
                message: 'ID cong viec hoac nguoi dung khong hop le'
            });
        }

        if (!['viewer', 'editor'].includes(permission)) {
            return res.status(400).json({
                message: 'Quyen chia se khong hop le'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        // Chi nguoi tao cong viec duoc thay doi quyen
        if (String(task.createdBy) !== String(req.userId)) {
            return res.status(403).json({
                message: 'Chi nguoi tao cong viec duoc thay doi quyen chia se'
            });
        }

        const isShared = task.sharedWith.some(
            user => String(user) === String(userId)
        );

        if (!isShared) {
            return res.status(404).json({
                message: 'Nguoi dung khong duoc chia se cong viec nay'
            });
        }

        const share = task.sharedPermissions.find(
            item => String(item.user) === String(userId)
        );

        if (share) {
            share.permission = permission;
        } else {
            task.sharedPermissions.push({
                user: userId,
                permission
            });
        }

        await task.save();

        return res.json({
            message: 'Thay doi quyen chia se thanh cong',
            task
        });
    } catch (error) {
        console.error('Loi thay doi quyen chia se:', error);

        return res.status(500).json({
            message: 'Khong the thay doi quyen chia se'
        });
    }
});

// DELETE /api/tasks/:id/shares/:userId - thu hoi quyen chia se
router.delete('/:id/shares/:userId', authenticateToken, async (req, res) => {
    try {
        const { id, userId } = req.params;

        if (!isValidId(id) || !isValidId(userId)) {
            return res.status(400).json({
                message: 'ID cong viec hoac nguoi dung khong hop le'
            });
        }

        const task = await Task.findById(id);

        if (!task) {
            return res.status(404).json({
                message: 'Khong tim thay cong viec'
            });
        }

        // Chi nguoi tao cong viec duoc thu hoi quyen
        if (String(task.createdBy) !== String(req.userId)) {
            return res.status(403).json({
                message: 'Chi nguoi tao cong viec duoc thu hoi quyen chia se'
            });
        }

        const isShared = task.sharedWith.some(
            user => String(user) === String(userId)
        );

        if (!isShared) {
            return res.status(404).json({
                message: 'Nguoi dung khong duoc chia se cong viec nay'
            });
        }

        // Xoa khoi danh sach chia se
        task.sharedWith = task.sharedWith.filter(
            user => String(user) !== String(userId)
        );

        // Xoa quyen Viewer/Editor
        task.sharedPermissions = task.sharedPermissions.filter(
            item => String(item.user) !== String(userId)
        );

        // Xoa trang thai chap nhan cua nguoi bi thu hoi quyen
        task.acceptedBy = task.acceptedBy.filter(
            user => String(user) !== String(userId)
        );

        await task.save();

        return res.json({
            message: 'Thu hoi quyen chia se thanh cong',
            task
        });
    } catch (error) {
        console.error('Loi thu hoi quyen chia se:', error);

        return res.status(500).json({
            message: 'Khong the thu hoi quyen chia se'
        });
    }
});
module.exports = router;