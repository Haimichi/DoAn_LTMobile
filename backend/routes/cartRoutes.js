const express = require('express');
const cartController = require('../controllers/cartController');
const { verifyToken } = require('../middleware/authMiddleware');
const { validateOrder } = require('../middleware/cartMiddleware');

const router = express.Router();

// Áp dụng middleware verifyToken cho tất cả các routes
router.use(verifyToken);

router.get('/', cartController.getCart);
router.post('/add', cartController.addToCart);
router.post('/place_order', validateOrder, cartController.placeOrder);

module.exports = router;
