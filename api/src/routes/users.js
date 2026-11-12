
const express = require('express');
const authenticateToken = require('../middleware/auth_middleware');
const { searchUsers } = require('../controllers/userController');

const router = express.Router();

// GET /api/users/search?q=
router.get('/search', authenticateToken, searchUsers);

module.exports = router;
