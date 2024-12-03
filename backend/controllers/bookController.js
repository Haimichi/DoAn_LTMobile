const db = require('../config/db');  // Kết nối cơ sở dữ liệu

exports.getBooks = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM Books');
    res.status(200).json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Không thể lấy danh sách sách', error });
  }
};



exports.getBookById = async (req, res) => {
  const { id } = req.params;  // Lấy ID từ URL

  try {
    const result = await db.query('SELECT * FROM Books WHERE book_id = $1', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy sách với ID này' });
    }
    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Không thể lấy thông tin sách', error });
  }
};


exports.addBook = async (req, res) => {
  const { title, author, description, price, published_year, category_id, image_url } = req.body;

  try {
    const result = await db.query(`
      INSERT INTO Books (title, author, description, price, published_year, category_id, image_url)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `, [title, author, description, price, published_year, category_id, image_url]);

    res.status(201).json({
      message: 'Sách đã được thêm thành công!',
      book: result.rows[0],
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Không thể thêm sách', error });
  }
};

exports.updateBook = async (req, res) => {
  const { id } = req.params;  // Lấy ID từ URL
  const { title, author, description, price, published_year, category_id, image_url } = req.body;

  try {
    const result = await db.query(`
      UPDATE Books
      SET title = $1, author = $2, description = $3, price = $4, published_year = $5, category_id = $6, image_url = $7, updated_at = CURRENT_TIMESTAMP
      WHERE book_id = $8
      RETURNING *;
    `, [title, author, description, price, published_year, category_id, image_url, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy sách với ID này để cập nhật' });
    }

    res.status(200).json({
      message: 'Sách đã được cập nhật thành công!',
      book: result.rows[0],
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Không thể cập nhật sách', error });
  }
};


exports.deleteBook = async (req, res) => {
  const { id } = req.params;  // Lấy ID từ URL

  try {
    const result = await db.query('DELETE FROM Books WHERE book_id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy sách với ID này để xoá' });
    }

    res.status(200).json({
      message: 'Sách đã được xoá thành công!',
      book: result.rows[0],
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Không thể xoá sách', error });
  }
};