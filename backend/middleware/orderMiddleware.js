const { sql } = require('../config/db');

exports.checkOrderExistence = async (req, res, next) => {
  const { orderId } = req.params;

  try {
    const result = await sql.query`SELECT * FROM Orders WHERE order_id = ${orderId}`;
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'Đơn hàng không tồn tại' });
    }

    next(); // Nếu đơn hàng tồn tại, tiếp tục
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Lỗi khi kiểm tra đơn hàng', error: error.message });
  }
};
