const sql = require('mssql');
const config = require('../config/db');

exports.getCart = async (req, res) => {
  const { userId } = req;
  try {
    const pool = await sql.connect(config);
    const result = await pool.request()
      .input('userId', sql.Int, userId)
      .query('SELECT * FROM cart WHERE user_id = @userId');
    
    res.status(200).json(result.recordset);
  } catch (error) {
    res.status(500).json({ message: 'Không thể lấy giỏ hàng', error: error.message });
  }
};

exports.addToCart = async (req, res) => {
  const { userId } = req;
  const { bookId, quantity } = req.body;
  try {
    const pool = await sql.connect(config);
    
    // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
    const checkResult = await pool.request()
      .input('userId', sql.Int, userId)
      .input('bookId', sql.Int, bookId)
      .query('SELECT * FROM cart WHERE user_id = @userId AND book_id = @bookId');

    if (checkResult.recordset.length > 0) {
      // Nếu có rồi thì cập nhật số lượng
      await pool.request()
        .input('userId', sql.Int, userId)
        .input('bookId', sql.Int, bookId)
        .input('quantity', sql.Int, quantity)
        .query('UPDATE cart SET quantity = quantity + @quantity WHERE user_id = @userId AND book_id = @bookId');
    } else {
      // Nếu chưa có thì thêm mới
      await pool.request()
        .input('userId', sql.Int, userId)
        .input('bookId', sql.Int, bookId)
        .input('quantity', sql.Int, quantity)
        .query('INSERT INTO cart (user_id, book_id, quantity) VALUES (@userId, @bookId, @quantity)');
    }
    
    res.status(201).json({ message: 'Thêm vào giỏ hàng thành công' });
  } catch (error) {
    res.status(500).json({ message: 'Không thể thêm vào giỏ hàng', error: error.message });
  }
};

exports.placeOrder = async (req, res) => {
  try {
    const { items, shipping_address } = req.body;
    
    if (!items || items.length === 0) {
      return res.status(400).json({ message: 'Đơn hàng không có sản phẩm' });
    }

    const userId = req.userId;
    const total_amount = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);

    const pool = await sql.connect(config);
    const transaction = new sql.Transaction(pool);

    await transaction.begin();
    try {
      // Tạo order mới
      const orderResult = await transaction.request()
        .input('user_id', sql.Int, userId)
        .input('order_date', sql.DateTime, new Date())
        .input('total_amount', sql.Decimal(10,2), total_amount)
        .input('status', sql.VarChar(50), 'Pending')
        .input('payment_method', sql.VarChar(50), 'COD')
        .input('payment_status', sql.VarChar(50), 'Pending')
        .input('shipping_address', sql.NVarChar(sql.MAX), JSON.stringify(shipping_address))
        .query(`
          INSERT INTO orders (user_id, order_date, total_amount, status, payment_method, payment_status, shipping_address)
          OUTPUT INSERTED.order_id
          VALUES (@user_id, @order_date, @total_amount, @status, @payment_method, @payment_status, @shipping_address);
        `);

      const newOrderId = orderResult.recordset[0].order_id;

      // Thêm order items
      for (const item of items) {
        await transaction.request()
          .input('order_id', sql.Int, newOrderId)
          .input('book_id', sql.Int, item.book_id)
          .input('quantity', sql.Int, item.quantity)
          .input('price', sql.Decimal(10,2), item.price)
          .query(`
            INSERT INTO order_items (order_id, book_id, quantity, price)
            VALUES (@order_id, @book_id, @quantity, @price);
          `);
      }

      await transaction.commit();
      res.json({ 
        message: 'Đặt hàng thành công!',
        orderId: newOrderId 
      });
    } catch (err) {
      await transaction.rollback();
      throw err;
    }
  } catch (error) {
    console.error('Place order error:', error);
    res.status(500).json({ 
      message: 'Không thể đặt hàng', 
      error: error.message 
    });
  }
};
