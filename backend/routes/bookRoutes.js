const express = require('express');
const router = express.Router();
const bookController = require('../controllers/bookController');
const multer = require('multer');
const path = require('path');

// Cấu hình multer
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

const upload = multer({ storage: storage });

// Đảm bảo route này được đặt TRƯỚC các route khác
router.post('/upload', upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({
      status: 'error',
      message: 'Không có file được upload'
    });
  }

  const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
  res.json({
    status: 'success',
    imageUrl: imageUrl
  });
});

// Thêm route để upload nhiều ảnh đọc thử
router.post('/upload-preview-images', upload.array('images', 10), (req, res) => { // Tối đa 10 ảnh
  if (req.files.length === 0) {
    return res.status(400).json({
      status: 'error',
      message: 'Không có file nào được upload'
    });
  }

  const imageUrls = req.files.map(file => `${req.protocol}://${req.get('host')}/uploads/${file.filename}`);
  res.json({
    status: 'success',
    imageUrls: imageUrls
  });
});

// Lấy tất cả sách
router.get('/', bookController.getBooks);

// Lấy sách theo ID
router.get('/:id', bookController.getBookById);

// Thêm sách mới
router.post('/', bookController.createBook);

// Cập nhật sách
router.put('/:id', bookController.updateBook);

// Xoá sách
router.delete('/:id', bookController.deleteBook);

// Tìm kiếm sách
router.get('/search', bookController.searchBooks);

// Lấy categories
router.get('/categories', bookController.getCategories);

// Lấy sách theo category_id
router.get('/category/:categoryId', bookController.getBooksByCategory);

module.exports = router;
