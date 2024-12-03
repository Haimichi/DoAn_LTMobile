const express = require('express');
const { createOrder } = require('../controllers/orderController');
const { verifyToken } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/create', verifyToken, createOrder); // Tạo đơn hàng

module.exports = router;
