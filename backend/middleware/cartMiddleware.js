const { sql } = require('../config/db');

exports.checkCartItems = async (req, res, next) => {
  const { userId } = req.userId; // Lấy userId từ token
  const { cartItems } = req.body;

  try {
    if (!cartItems || cartItems.length === 0) {
      return res.status(400).json({ message: 'Giỏ hàng không có sản phẩm' });
    }

    // Kiểm tra tất cả các sản phẩm trong giỏ hàng
    for (let item of cartItems) {
      const result = await sql.query`SELECT * FROM Books WHERE book_id = ${item.bookId}`;
      if (result.recordset.length === 0) {
        return res.status(404).json({ message: `Sản phẩm với ID ${item.bookId} không tồn tại` });
      }
    }

    next(); // Nếu tất cả các sản phẩm đều hợp lệ
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Lỗi khi kiểm tra giỏ hàng', error: error.message });
  }
};
