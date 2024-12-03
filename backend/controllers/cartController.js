const db = require('../config/db');

exports.getCart = async (req, res) => {
  const { userId } = req;
  try {
    const cartItems = await db.query('SELECT * FROM cart WHERE user_id = $1', [userId]);
    res.status(200).json(cartItems.rows);
  } catch (error) {
    res.status(500).json({ message: 'Không thể lấy giỏ hàng', error });
  }
};

exports.addToCart = async (req, res) => {
  const { userId } = req;
  const { bookId, quantity } = req.body;
  try {
    await db.query(
      'INSERT INTO cart (user_id, book_id, quantity) VALUES ($1, $2, $3) ON CONFLICT (user_id, book_id) DO UPDATE SET quantity = cart.quantity + $3',
      [userId, bookId, quantity]
    );
    res.status(201).json({ message: 'Thêm vào giỏ hàng thành công' });
  } catch (error) {
    res.status(500).json({ message: 'Không thể thêm vào giỏ hàng', error });
  }
};
