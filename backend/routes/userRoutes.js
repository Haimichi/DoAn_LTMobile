const express = require('express');
const { getUserProfile, updateUserProfile, deleteUser } = require('../controllers/userController');
const { verifyToken } = require('../middleware/authMiddleware');

const router = express.Router();

// Lấy thông tin người dùng
router.get('/profile', verifyToken, getUserProfile);

// Cập nhật thông tin người dùng
router.put('/profile', verifyToken, updateUserProfile);

// Xóa người dùng (Chỉ Admin)
router.delete('/:userId', verifyToken, deleteUser);

module.exports = router;
