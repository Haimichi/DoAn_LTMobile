// const jwt = require('jsonwebtoken');

// exports.verifyToken = (req, res, next) => {
//   try {
//     const bearerToken = req.headers['authorization'];
//     console.log('Received authorization header:', bearerToken);

//     if (!bearerToken) {
//       return res.status(403).json({ message: 'Token không được cung cấp' });
//     }

//     const token = bearerToken.split(' ')[1];
//     console.log('Extracted token:', token);

//     const decoded = jwt.verify(token, process.env.JWT_SECRET);
//     console.log('Decoded token:', decoded);

//     // Kiểm tra thời gian hết hạn
//     if (decoded.exp < Date.now() / 1000) {
//       return res.status(401).json({ message: 'Token đã hết hạn' });
//     }

//     req.userId = decoded.userId;
//     next();
//   } catch (error) {
//     console.error('Auth middleware error:', error);
//     if (error.name === 'TokenExpiredError') {
//       return res.status(401).json({ message: 'Token đã hết hạn, vui lòng đăng nhập lại' });
//     }
//     if (error.name === 'JsonWebTokenError') {
//       return res.status(401).json({ message: 'Token không hợp lệ' });
//     }
//     return res.status(401).json({ message: 'Lỗi xác thực: ' + error.message });
//   }
// };


const jwt = require('jsonwebtoken');

exports.verifyToken = (req, res, next) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers['authorization'];
    console.log('Auth header:', authHeader); // Debug log
    
    if (!authHeader) {
      return res.status(401).json({ message: 'Authorization header không tồn tại' });
    }

    const token = authHeader.split(' ')[1];
    console.log('Extracted token:', token); // Debug log
    
    if (!token) {
      return res.status(401).json({ message: 'Token không được cung cấp' });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log('Decoded token:', decoded); // Debug log
    
    req.userId = decoded.userId;
    next();
  } catch (err) {
    console.error('Token verification error:', err);
    return res.status(401).json({ 
      message: 'Token không hợp lệ',
      error: err.message,
      jwt_secret: process.env.JWT_SECRET
    });
  }
};