const db = require('../config/db');

// Lấy thông tin người dùng
exports.getUserProfile = async (req, res) => {
  const { userId } = req;
  try {
    const user = await db.query('SELECT user_id, full_name, email, phone_number, avatar_url FROM users WHERE user_id = $1', [userId]);
    if (user.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }
    res.status(200).json(user.rows[0]);
  } catch (error) {
    res.status(500).json({ message: 'Không thể lấy thông tin người dùng', error });
  }
};

// Cập nhật thông tin người dùng
exports.updateUserProfile = async (req, res) => {
  const { userId } = req;
  const { fullName, phoneNumber, avatarUrl } = req.body;
  try {
    await db.query(
      'UPDATE users SET full_name = $1, phone_number = $2, avatar_url = $3, updated_at = NOW() WHERE user_id = $4',
      [fullName, phoneNumber, avatarUrl, userId]
    );
    res.status(200).json({ message: 'Cập nhật thông tin thành công' });
  } catch (error) {
    res.status(500).json({ message: 'Không thể cập nhật thông tin', error });
  }
};

// Xóa tài khoản người dùng (Chỉ Admin)
exports.deleteUser = async (req, res) => {
  const { userId } = req.params;
  try {
    await db.query('DELETE FROM users WHERE user_id = $1', [userId]);
    res.status(200).json({ message: 'Xóa người dùng thành công' });
  } catch (error) {
    res.status(500).json({ message: 'Không thể xóa người dùng', error });
  }
};
