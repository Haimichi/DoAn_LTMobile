const { sql } = require('../config/db');

exports.checkBookExistence = async (req, res, next) => {
  const { bookId } = req.params;

  try {
    const result = await sql.query`SELECT * FROM Books WHERE book_id = ${bookId}`;
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'Sách không tồn tại' });
    }

    next(); // Nếu sách tồn tại, tiếp tục
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Lỗi khi kiểm tra sách', error: error.message });
  }
};
