
const express = require('express');
const router = express.Router();

const {
    getTaskActivities
} = require('../controllers/activityController');

const authenticateToken = require('../middleware/auth_middleware');

// GET /api/tasks/:id/activities
router.get(
    '/:id/activities',
    authenticateToken,
    getTaskActivities
);

module.exports = router;
