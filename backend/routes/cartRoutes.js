const express = require('express');
const { getCart, addToCart } = require('../controllers/cartController');
const { verifyToken } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', verifyToken, getCart); // Lấy giỏ hàng của người dùng
router.post('/add', verifyToken, addToCart); // Thêm sách vào giỏ hàng

module.exports = router;
