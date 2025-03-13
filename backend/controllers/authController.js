const sql = require('mssql');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

exports.register = async (req, res) => {
  try {
    const { email, password, fullName } = req.body;

    // Sử dụng global pool
    const pool = global.sqlPool;
    if (!pool) {
      throw new Error('Database connection not initialized');
    }

    // Kiểm tra email đã tồn tại chưa
    const checkEmail = await pool.request()
      .input('email', sql.NVarChar, email)
      .query('SELECT email FROM Users WHERE email = @email');

    if (checkEmail.recordset.length > 0) {
      return res.status(400).json({ message: 'Email đã tồn tại' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Thêm user mới
    const result = await pool.request()
      .input('email', sql.NVarChar, email)
      .input('password_hash', sql.NVarChar, hashedPassword)
      .input('full_name', sql.NVarChar, fullName)
      .input('role_id', sql.Int, 2) // 2 = customer
      .input('ban_id', sql.Int, 2) // 0 = không bị ban
      .query(`
        INSERT INTO Users (email, password_hash, full_name, role_id, ban_id)
        OUTPUT INSERTED.user_id, INSERTED.email, INSERTED.full_name
        VALUES (@email, @password_hash, @full_name, @role_id, @ban_id)
      `);

    const newUser = result.recordset[0];

    // // Tạo token
    // const token = jwt.sign(
    //   { userId: newUser.user_id },
    //   process.env.JWT_SECRET,
    //   { expiresIn: '24h' }
    // );
    const token = jwt.sign(
      { userId: user.user_id },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({
      message: 'Đăng ký thành công!',
      token,
      user: {
        user_id: newUser.user_id,
        email: newUser.email,
        full_name: newUser.full_name
      }
    });

  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      message: 'Đăng ký thất bại',
      error: error.message
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    console.log('Login attempt for email:', email);

    const pool = global.sqlPool;
    if (!pool) {
      throw new Error('Database connection not initialized');
    }

    const result = await pool.request()
      .input('email', sql.NVarChar, email)
      .query(`
        SELECT user_id, email, password_hash, full_name, avatar_url, ban_id
        FROM [dbo].[Users]
        WHERE [email] = @email
      `);

    if (result.recordset.length === 0) {
      return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' });
    }

    const user = result.recordset[0];

    if (user.ban_id === 1) {
      return res.status(403).json({ 
        status: 'error',
        message: 'Tài khoản của bạn đã bị khóa' 
      });
    }

    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' });
    }

    // Tạo token ở đây
    const token = jwt.sign(
      { userId: user.user_id },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log('Login successful for user:', email);

    res.status(200).json({
      message: 'Đăng nhập thành công!',
      token: token,
      user: {
        user_id: user.user_id,
        full_name: user.full_name,
        email: user.email,
        avatar_url: user.avatar_url || null
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      message: 'Đăng nhập thất bại', 
      error: error.message 
    });
  }
};