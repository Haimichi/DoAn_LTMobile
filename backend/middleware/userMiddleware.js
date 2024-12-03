const { sql } = require('../config/db');

exports.checkUserExistence = async (req, res, next) => {
  const { userId } = req.params;

  try {
    const result = await sql.query`SELECT * FROM Users WHERE user_id = ${userId}`;
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'Người dùng không tồn tại' });
    }

    next(); // Nếu người dùng tồn tại, tiếp tục
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Lỗi khi kiểm tra người dùng', error: error.message });
  }
};