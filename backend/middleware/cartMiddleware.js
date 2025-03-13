const sql = require('mssql');
const config = require('../config/db');

exports.validateOrder = async (req, res, next) => {
  try {
    const { items } = req.body;
    
    if (!items || items.length === 0) {
      return res.status(400).json({ message: 'Đơn hàng không có sản phẩm' });
    }

    const pool = await sql.connect(config);
    
    // Kiểm tra tồn tại của sách
    for (const item of items) {
      const result = await pool.request()
        .input('bookId', sql.Int, item.book_id)
        .query('SELECT * FROM books WHERE book_id = @bookId');
        
      if (result.recordset.length === 0) {
        return res.status(404).json({ 
          message: `Sách với ID ${item.book_id} không tồn tại` 
        });
      }
    }
    
    next();
  } catch (error) {
    console.error('Validate order error:', error);
    res.status(500).json({ 
      message: 'Lỗi khi kiểm tra đơn hàng', 
      error: error.message 
    });
  }
};
