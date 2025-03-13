const sql = require('mssql');
const config = require('../config/db');

exports.checkOrderExistence = async (req, res, next) => {
  const { orderId } = req.params;
  const userId = req.userId;

  try {
    const pool = await sql.connect(config);
    const result = await pool.request()
      .input('orderId', sql.Int, orderId)
      .input('userId', sql.Int, userId)
      .query`
        SELECT * FROM Orders 
        WHERE order_id = @orderId AND user_id = @userId
      `;
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'Đơn hàng không tồn tại' });
    }

    next();
  } catch (error) {
    console.error('Check order existence error:', error);
    return res.status(500).json({ 
      message: 'Lỗi khi kiểm tra đơn hàng', 
      error: error.message 
    });
  }
};
