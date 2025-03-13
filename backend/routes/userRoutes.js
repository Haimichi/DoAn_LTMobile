// const express = require('express');
// const router = express.Router();
// const userController = require('../controllers/userController');

// // Test route
// router.get('/test', (req, res) => {
//   res.json({ message: 'User routes working' });
// });

// // Routes
// // Lấy danh sách users
// router.get('/', userController.getUsers);
// // Xóa user
// router.delete('/:id', userController.deleteUser);
// router.get('/info/:email', userController.getUserInfo);
// router.get('/get-user-info/:email', userController.getUserInfo);
// router.post('/avatar', userController.updateAvatar);
// router.put('/update-profile', userController.updateProfile);

// module.exports = router;

const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken } = require('../middleware/authMiddleware');

// Test route
router.get('/test', (req, res) => {
  console.log('Test route hit');
  res.json({ message: 'User routes working' });
});

// Get all users - Đặt route này lên đầu
router.get('/', verifyToken, async (req, res) => {
  console.log('Get all users route hit');
  await userController.getUsers(req, res);
});

// Các routes khác
router.delete('/:id', verifyToken, userController.deleteUser);
router.get('/info/:email', verifyToken, userController.getUserInfo);
router.get('/get-user-info/:email', verifyToken, userController.getUserInfo);
router.post('/avatar', verifyToken, userController.updateAvatar);
router.put('/update-profile', verifyToken, userController.updateProfile);
router.put('/ban/:id', verifyToken, userController.banUser);

module.exports = router;