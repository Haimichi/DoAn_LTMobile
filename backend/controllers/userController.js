const sql = require('mssql');
const config = require('../config/db');

exports.getUserInfo = async (req, res) => {
  let connection;
  try {
    const email = req.params.email;
    connection = await new sql.ConnectionPool(config).connect();
    const result = await connection.request()
      .input('email', sql.NVarChar, email)
      .query(`
        SELECT 
          user_id,
          email,
          full_name as fullName,
          phone_number as phoneNumber, 
          birth_date as birth_date,
          avatar_url as avatarUrl,
          role_id
        FROM Users 
        WHERE email = @email
      `);

    if (result.recordset.length > 0) {
      const userData = {
        status: 'success',
        user_id: result.recordset[0].user_id,
        email: result.recordset[0].email,
        fullName: result.recordset[0].fullName,
        phoneNumber: result.recordset[0].phoneNumber,
        birthDate: result.recordset[0].birth_date,
        avatarUrl: result.recordset[0].avatarUrl,
        role_id: result.recordset[0].role_id
      };
      res.status(200).json(userData);
    } else {
      res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }
  } catch (error) {
    console.error('Error getting user info:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  } finally {
    if (connection) await connection.close();
  }
};

exports.updateAvatar = async (req, res) => {
  let connection;
  try {
    const { email, avatar } = req.body;
    
    if (!email || !avatar) {
      return res.status(400).json({
        status: 'error',
        message: 'Email and avatar are required'
      });
    }

    connection = await new sql.ConnectionPool(config).connect();
    const result = await connection.request()
      .input('email', sql.NVarChar, email)
      .input('avatar', sql.NVarChar(sql.MAX), avatar)
      .query(`
        UPDATE Users 
        SET avatar_url = @avatar,
            updatedAt = GETDATE()
        OUTPUT 
          INSERTED.user_id,
          INSERTED.avatar_url as avatarUrl
        WHERE email = @email;
      `);

    if (result.recordset.length > 0) {
      res.status(200).json({
        status: 'success',
        user_id: result.recordset[0].user_id,
        avatarUrl: result.recordset[0].avatarUrl
      });
    } else {
      res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

  } catch (error) {
    console.error('Error updating avatar:', error);
    res.status(500).json({
      status: 'error', 
      message: error.message
    });
  } finally {
    if (connection) await connection.close();
  }
};

exports.updateProfile = async (req, res) => {
  let connection;
  try {
    console.log('Received update profile request:', req.body);
    const { email, fullName, phoneNumber, birthDate } = req.body;
    
    if (!email || !fullName) {
      return res.status(400).json({ message: 'Email and fullName are required' });
    }

    connection = await new sql.ConnectionPool(config).connect();
    console.log('Connected to database');

    const result = await connection.request()
      .input('email', sql.NVarChar, email)
      .input('fullName', sql.NVarChar, fullName)
      .input('phoneNumber', sql.NVarChar, phoneNumber)
      .input('birthDate', sql.DateTime, birthDate ? new Date(birthDate) : null)
      .query(`
        UPDATE [dbo].[Users]
        SET [full_name] = @fullName,
            [phone_number] = @phoneNumber,
            [birth_date] = @birthDate,
            [updatedAt] = GETDATE()
        OUTPUT INSERTED.*
        WHERE [email] = @email;
      `);

    console.log('Query executed, result:', result);

    if (result.recordset && result.recordset.length > 0) {
      const updatedUser = result.recordset[0];
      res.status(200).json({
        status: 'success',
        message: 'Profile updated successfully',
        user: {
          fullName: updatedUser.full_name,
          phoneNumber: updatedUser.phone_number,
          birthDate: updatedUser.birth_date
        }
      });
    } else {
      res.status(404).json({ message: 'User not found' });
    }

  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ 
      message: 'Internal server error',
      error: error.message 
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
};

exports.getUsers = async (req, res) => {
  let connection;
  try {
    connection = await new sql.ConnectionPool(config).connect();
    const result = await connection.request()
      .query(`
        SELECT 
          user_id,
          full_name as fullName,
          email,
          phone_number as phoneNumber,
          birth_date as birthDate,
          avatar_url as avatarUrl,
          role_id,
          CAST(ban_id as INT) as ban_id
        FROM Users
      `);

    console.log('Query executed, found users:', result.recordset);
    result.recordset.forEach(user => {
      console.log(`User ${user.email} - ban_id:`, user.ban_id, typeof user.ban_id);
    });

    if (result.recordset.length > 0) {
      res.status(200).json({
        status: 'success',
        data: result.recordset
      });
    } else {
      res.status(404).json({ 
        status: 'error', 
        message: 'No users found' 
      });
    }
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ 
      status: 'error', 
      message: error.message 
    });
  } finally {
    if (connection) await connection.close();
  }
};

exports.deleteUser = async (req, res) => {
  let connection;
  try {
    const userId = req.params.id;
    connection = await new sql.ConnectionPool(config).connect();
    const result = await connection.request()
      .input('user_id', sql.Int, userId)
      .query('DELETE FROM Users WHERE user_id = @user_id');

    if (result.rowsAffected[0] > 0) {
      res.status(200).json({
        status: 'success',
        message: 'User deleted successfully'
      });
    } else {
      res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  } finally {
    if (connection) await connection.close();
  }
};

exports.banUser = async (req, res) => {
  let connection;
  try {
    const userId = req.params.id;
    const { ban_id } = req.body;
    
    connection = await new sql.ConnectionPool(config).connect();
    
    const result = await connection.request()
      .input('user_id', sql.Int, userId)
      .input('ban_id', sql.Int, ban_id)
      .query(`
        UPDATE Users 
        SET ban_id = @ban_id,
            updatedAt = GETDATE()
        OUTPUT INSERTED.*
        WHERE user_id = @user_id
      `);

    if (result.rowsAffected[0] > 0) {
      const message = ban_id === 1 
        ? 'Đã khóa tài khoản thành công'
        : 'Đã mở khóa tài khoản thành công';
        
      res.status(200).json({
        status: 'success',
        message: message,
        banStatus: ban_id
      });
    } else {
      res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }
  } catch (error) {
    console.error('Error banning/unbanning user:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  } finally {
    if (connection) await connection.close();
  }
};