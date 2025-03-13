const express = require('express');
const orderController = require('../controllers/orderController');
const { verifyToken } = require('../middleware/authMiddleware');
const { checkOrderExistence } = require('../middleware/orderMiddleware');

const router = express.Router();

// Áp dụng middleware xác thực cho tất cả routes
router.use(verifyToken);

// Routes
router.get('/my-orders', orderController.getMyOrders); // Thêm route mới
router.post('/create', orderController.createOrder);
router.get('/:orderId', checkOrderExistence, orderController.getOrderById);

module.exports = router;
