const sql = require('mssql');
const db = require('../config/db');

exports.getVouchers = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    const result = await pool.request()
      .query('SELECT * FROM Vouchers ORDER BY voucher_id DESC');
    
    res.json({
      status: 'success',
      data: result.recordset
    });
  } catch (err) {
    console.log('Error:', err);
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.getVoucherById = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    const result = await pool.request()
      .input('voucher_id', sql.Int, req.params.id)
      .query('SELECT * FROM Vouchers WHERE voucher_id = @voucher_id');

    if (result.recordset.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy voucher'
      });
    }

    res.json({
      status: 'success',
      data: result.recordset[0]
    });
  } catch (err) {
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.createVoucher = async (req, res) => {
  try {
    console.log('Creating voucher with data:', req.body);
    let pool = await sql.connect(db);
    
    // Lấy thông tin từ request body
    const { code, discount, voucher_quantity } = req.body;

    // Kiểm tra mã voucher đã tồn tại chưa
    const checkExisting = await pool.request()
      .input('code', sql.VarChar(255), code)
      .query('SELECT COUNT(*) as count FROM Vouchers WHERE code = @code');
      
    if (checkExisting.recordset[0].count > 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Mã voucher đã tồn tại'
      });
    }

    // Thêm voucher mới
    const result = await pool.request()
      .input('code', sql.VarChar(255), code)
      .input('discount', sql.Int, discount)
      .input('voucher_quantity', sql.Int, voucher_quantity)
      .query(`
        INSERT INTO Vouchers (code, discount, voucher_quantity)
        VALUES (@code, @discount, @voucher_quantity);
        SELECT SCOPE_IDENTITY() AS id;
      `);

    console.log('Voucher created with ID:', result.recordset[0].id);

    res.status(201).json({
      status: 'success',
      data: {
        voucher_id: result.recordset[0].id,
        code: code,
        discount: discount,
        voucher_quantity: voucher_quantity
      }
    });
  } catch (err) {
    console.error('Error creating voucher:', err);
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.updateVoucher = async (req, res) => {
  try {
    console.log('Updating voucher with ID:', req.params.id, 'and data:', req.body);
    const { code, discount, voucher_quantity } = req.body;
    const voucherId = parseInt(req.params.id);

    let pool = await sql.connect(db);

    // Kiểm tra voucher có tồn tại không
    const checkExisting = await pool.request()
      .input('voucher_id', sql.Int, voucherId)
      .query('SELECT COUNT(*) as count FROM Vouchers WHERE voucher_id = @voucher_id');

    if (checkExisting.recordset[0].count === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy voucher'
      });
    }

    // Kiểm tra mã code mới có trùng với voucher khác không
    const checkCode = await pool.request()
      .input('code', sql.VarChar(255), code)
      .input('voucher_id', sql.Int, voucherId)
      .query('SELECT COUNT(*) as count FROM Vouchers WHERE code = @code AND voucher_id != @voucher_id');

    if (checkCode.recordset[0].count > 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Mã voucher đã tồn tại'
      });
    }

    const result = await pool.request()
      .input('voucher_id', sql.Int, voucherId)
      .input('code', sql.VarChar(255), code)
      .input('discount', sql.Int, discount)
      .input('voucher_quantity', sql.Int, voucher_quantity)
      .query(`
        UPDATE Vouchers
        SET code = @code,
            discount = @discount,
            voucher_quantity = @voucher_quantity
        WHERE voucher_id = @voucher_id;
        SELECT * FROM Vouchers WHERE voucher_id = @voucher_id;
      `);

    console.log('Voucher updated with ID:', voucherId);

    res.json({
      status: 'success',
      data: result.recordset[0]
    });
  } catch (err) {
    console.error('Error updating voucher:', err);
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.deleteVoucher = async (req, res) => {
  try {
    const voucherId = parseInt(req.params.id);
    let pool = await sql.connect(db);

    // Kiểm tra voucher có tồn tại không
    const checkExisting = await pool.request()
      .input('voucher_id', sql.Int, voucherId)
      .query('SELECT COUNT(*) as count FROM Vouchers WHERE voucher_id = @voucher_id');

    if (checkExisting.recordset[0].count === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy voucher'
      });
    }

    await pool.request()
      .input('voucher_id', sql.Int, voucherId)
      .query('DELETE FROM Vouchers WHERE voucher_id = @voucher_id');

    res.json({
      status: 'success',
      message: 'Xóa voucher thành công'
    });
  } catch (err) {
    console.error('Error deleting voucher:', err);
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  }
};