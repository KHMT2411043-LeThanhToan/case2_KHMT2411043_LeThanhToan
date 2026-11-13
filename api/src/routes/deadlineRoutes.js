
const express = require('express');
const authenticateToken = require('../middleware/auth_middleware');

const {
    getDeadlineTasks
} = require('../controllers/deadlineController');

const router = express.Router();

// E3: Lay cong viec sap den han va qua han
router.get('/', authenticateToken, getDeadlineTasks);

module.exports = router;
