const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { verifyToken } = require('../middleware/authMiddleware');

// POST /api/reviews - Tạo review mới (yêu cầu đăng nhập)
router.post('/', verifyToken, reviewController.createReview);

// GET /api/reviews/book/:bookId - Lấy reviews theo bookId
router.get('/book/:bookId', reviewController.getReviewsByBookId);

module.exports = router;
