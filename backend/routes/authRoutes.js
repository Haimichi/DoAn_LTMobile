const express = require('express');
const router = express.Router();
const authControllers = require('../controllers/authControllers');  // Đảm bảo đường dẫn đúng

router.post('/register', authControllers.register);
router.post('/login', authControllers.login);

module.exports = router;
