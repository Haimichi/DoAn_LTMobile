const db = require('../config/db');

exports.createOrder = async (req, res) => {
  const { userId } = req;
  const { totalAmount, paymentMethod, shippingAddress } = req.body;
  try {
    const newOrder = await db.query(
      'INSERT INTO orders (user_id, total_amount, payment_method, shipping_address) VALUES ($1, $2, $3, $4) RETURNING *',
      [userId, totalAmount, paymentMethod, shippingAddress]
    );
    res.status(201).json({ message: 'Tạo đơn hàng thành công', order: newOrder.rows[0] });
  } catch (error) {
    res.status(500).json({ message: 'Không thể tạo đơn hàng', error });
  }
};
