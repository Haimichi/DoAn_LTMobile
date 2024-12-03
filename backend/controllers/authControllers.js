const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { sql, connectToDatabase } = require('../config/db');  // Ensure this import is correct

exports.register = async (req, res) => {
  const { fullName, email, phoneNumber, password } = req.body;

  try {
    // Kết nối với cơ sở dữ liệu nếu chưa kết nối
    await connectToDatabase();

    // Kiểm tra xem người dùng đã tồn tại chưa
    const result = await sql.query`SELECT * FROM Users WHERE email = ${email}`;

    if (result.recordset.length > 0) {
      return res.status(400).json({ message: 'Email đã tồn tại!' });
    }

    // Mã hóa mật khẩu
    const hashedPassword = await bcrypt.hash(password, 10);

    // Thực hiện chèn người dùng vào bảng Users
    const newUser = await sql.query`
      INSERT INTO Users (full_name, email, phone_number, password_hash) 
      VALUES (${fullName}, ${email}, ${phoneNumber}, ${hashedPassword});
      SELECT * FROM Users WHERE user_id = SCOPE_IDENTITY();
    `;

    return res.status(201).json({
      message: 'Đăng ký thành công!',
      user: newUser.recordset[0],  // Trả về thông tin người dùng vừa đăng ký
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Đăng ký thất bại', error: error.message });
  }
};


exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    // Kết nối với cơ sở dữ liệu nếu chưa kết nối
    await connectToDatabase();

    // Khai báo tham số cho câu truy vấn SQL
    const request = new sql.Request();
    request.input('email', sql.NVarChar, email);  // Khai báo tham số email

    // Truy vấn cơ sở dữ liệu
    const result = await request.query('SELECT * FROM Users WHERE email = @email');

    if (result.recordset.length === 0) {
      return res.status(400).json({ message: 'Sai email hoặc mật khẩu!' });
    }

    const user = result.recordset[0];

    // So sánh mật khẩu
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(400).json({ message: 'Sai email hoặc mật khẩu!' });
    }

    // Tạo JWT token
    const token = jwt.sign({ userId: user.user_id }, process.env.JWT_SECRET, { expiresIn: '1h' });

    return res.status(200).json({
      message: 'Đăng nhập thành công!',
      token: token,  // Trả về token cho người dùng
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Đăng nhập thất bại', error: error.message });
  }
};

