const express = require('express');
const router = express.Router();
const { getBooks, getBookById, addBook, updateBook, deleteBook } = require('../controllers/bookController');

// Lấy tất cả sách
router.get('/', getBooks);

// Lấy sách theo ID
router.get('/:id', getBookById);

// Thêm sách mới
router.post('/', addBook);

// Cập nhật sách
router.put('/:id', updateBook);

// Xoá sách
router.delete('/:id', deleteBook);

module.exports = router;
