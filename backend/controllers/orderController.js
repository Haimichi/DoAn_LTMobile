const sql = require('mssql');
const config = require('../config/db');
const { updateBookQuantity } = require('./bookController');

exports.getMyOrders = async (req, res) => {
  try {
    const pool = await sql.connect(config);
    const userId = req.userId;

    const result = await pool.request()
      .input('userId', sql.Int, userId)
      .query(`
        SELECT 
          o.order_id,
          o.order_date,
          o.total_amount,
          o.status,
          o.payment_method,
          o.payment_status,
          o.shipping_address,
          b.book_id,
          b.title as book_name,
          b.image_url,
          oi.quantity,
          oi.price
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN books b ON oi.book_id = b.book_id
        WHERE o.user_id = @userId
        ORDER BY o.order_date DESC
      `);

    const orders = [];
    const orderMap = new Map();

    result.recordset.forEach(row => {
      if (!orderMap.has(row.order_id)) {
        orderMap.set(row.order_id, {
          order_id: row.order_id,
          order_date: row.order_date,
          total_amount: row.total_amount,
          status: row.status,
          payment_method: row.payment_method,
          payment_status: row.payment_status,
          shipping_address: row.shipping_address,
          items: []
        });
        orders.push(orderMap.get(row.order_id));
      }

      orderMap.get(row.order_id).items.push({
        book_id: row.book_id,
        book_name: row.book_name,
        image_url: row.image_url,
        quantity: row.quantity,
        price: row.price
      });
    });

    res.json({ orders });
  } catch (error) {
    console.error('Get my orders error:', error);
    res.status(500).json({ 
      message: 'Không thể lấy danh sách đơn hàng',
      error: error.message 
    });
  }
};

exports.getOrderById = async (req, res) => {
  try {
    const { orderId } = req.params;
    const userId = req.userId;

    const pool = await sql.connect(config);
    const result = await pool.request()
      .input('orderId', sql.Int, orderId)
      .input('userId', sql.Int, userId)
      .query(`
        SELECT 
          o.*,
          b.book_id,
          b.title as book_name,
          b.image_url,
          oi.quantity,
          oi.price
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN books b ON oi.book_id = b.book_id
        WHERE o.order_id = @orderId AND o.user_id = @userId
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'Đơn hàng không tồn tại' });
    }

    const orderData = {
      order_id: result.recordset[0].order_id,
      order_date: result.recordset[0].order_date,
      total_amount: result.recordset[0].total_amount,
      status: result.recordset[0].status,
      payment_method: result.recordset[0].payment_method,
      payment_status: result.recordset[0].payment_status,
      shipping_address: result.recordset[0].shipping_address,
      items: result.recordset.map(item => ({
        book_id: item.book_id,
        book_name: item.book_name,
        image_url: item.image_url,
        quantity: item.quantity,
        price: item.price
      }))
    };

    res.json(orderData);
  } catch (error) {
    console.error('Get order by id error:', error);
    res.status(500).json({ 
      message: 'Không thể lấy thông tin đơn hàng',
      error: error.message 
    });
  }
};

exports.createOrder = async (req, res) => {
  const { userId } = req;
  const { totalAmount, paymentMethod, shippingAddress } = req.body;
  try {
    const newOrder = await sql.connect(config);
    const result = await newOrder.request()
      .input('userId', sql.Int, userId)
      .input('totalAmount', sql.Float, totalAmount)
      .input('paymentMethod', sql.VarChar, paymentMethod)
      .input('shippingAddress', sql.VarChar, shippingAddress)
      .query(`
        INSERT INTO orders (user_id, total_amount, payment_method, shipping_address)
        VALUES (@userId, @totalAmount, @paymentMethod, @shippingAddress)
        RETURNING *
      `);

    // Sau khi đặt hàng thành công, cập nhật số lượng sách
    for (const item of req.body.items) {
      await updateBookQuantity(item.book_id, item.quantity);
    }

    res.status(201).json({ message: 'Tạo đơn hàng thành công', order: result.recordset[0] });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
};
