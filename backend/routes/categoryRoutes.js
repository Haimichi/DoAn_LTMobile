const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Tạo đường dẫn tuyệt đối cho thư mục uploads
const uploadDir = path.join(__dirname, '..', 'uploads', 'categories');

// Đảm bảo thư mục tồn tại
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `category-${uniqueSuffix}${ext}`);
  }
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }
}).single('category_image');

// Middleware xử lý upload
router.post('/upload-image', (req, res) => {
  upload(req, res, function(err) {
    if (err) {
      return res.status(400).json({
        status: 'error',
        message: err.message
      });
    }
    
    if (!req.file) {
      return res.status(400).json({
        status: 'error',
        message: 'No file uploaded'
      });
    }

    // Trả về đường dẫn tương đối
    const imageUrl = `/uploads/categories/${req.file.filename}`;
    res.json({
      status: 'success',
      imageUrl: imageUrl
    });
  });
});

// Routes
router.get('/', categoryController.getCategories);
router.get('/:id', categoryController.getCategoryById);
router.post('/', categoryController.createCategory);
router.put('/:id', categoryController.updateCategory);
router.delete('/:id', categoryController.deleteCategory);

module.exports = router;