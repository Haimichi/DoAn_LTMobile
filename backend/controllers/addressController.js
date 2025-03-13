const sql = require('mssql');
const config = require('../config/db');

const getAddresses = async (req, res) => {
  let connection;
  try {
    const { userId } = req.query;
    console.log('Getting addresses for userId:', userId);

    if (!userId) {
      return res.status(400).json({
        status: 'error',
        message: 'userId is required'
      });
    }

    connection = await new sql.ConnectionPool(config).connect();
    const result = await connection.request()
      .input('userId', sql.Int, userId)
      .query(`
        SELECT * FROM Addresses 
        WHERE user_id = @userId
        ORDER BY is_default DESC
      `);

    console.log('Found addresses:', result.recordset);

    res.status(200).json({
      status: 'success',
      addresses: result.recordset
    });

  } catch (error) {
    console.error('Error getting addresses:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
};

const getDefaultAddress = async (req, res) => {
  let connection;
  try {
    const { userId } = req.query;
    
    if (!userId) {
      return res.status(400).json({
        status: 'error',
        message: 'userId is required'
      });
    }

    connection = await new sql.ConnectionPool(config).connect();
    const result = await connection.request()
      .input('userId', sql.Int, userId)
      .query(`
        SELECT * FROM Addresses 
        WHERE user_id = @userId AND is_default = 1
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'No default address found'
      });
    }

    res.status(200).json({
      status: 'success',
      address: result.recordset[0]
    });

  } catch (error) {
    console.error('Error getting default address:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
};

const addAddress = async (req, res) => {
  let connection;
  try {
    const { userId, receiverName, phone, houseNumber, street, ward, district, province, addressType, isDefault } = req.body;

    if (!userId || !receiverName || !phone || !houseNumber || !street || !ward || !district || !province) {
      return res.status(400).json({
        status: 'error',
        message: 'Missing required fields'
      });
    }

    connection = await new sql.ConnectionPool(config).connect();

    // Nếu địa chỉ mới là mặc định, cập nhật các địa chỉ khác thành không mặc định
    if (isDefault) {
      await connection.request()
        .input('userId', sql.Int, userId)
        .query(`
          UPDATE Addresses
          SET is_default = 0
          WHERE user_id = @userId
        `);
    }

    const result = await connection.request()
      .input('userId', sql.Int, userId)
      .input('receiverName', sql.NVarChar, receiverName)
      .input('phone', sql.VarChar, phone)
      .input('houseNumber', sql.NVarChar, houseNumber)
      .input('street', sql.NVarChar, street)
      .input('ward', sql.NVarChar, ward)
      .input('district', sql.NVarChar, district)
      .input('province', sql.NVarChar, province)
      .input('addressType', sql.NVarChar, addressType)
      .input('isDefault', sql.Bit, isDefault || 0)
      .query(`
        INSERT INTO Addresses (
          user_id, receiver_name, phone, house_number, street, 
          ward, district, province, address_type, is_default
        )
        OUTPUT INSERTED.*
        VALUES (
          @userId, @receiverName, @phone, @houseNumber, @street,
          @ward, @district, @province, @addressType, @isDefault
        )
      `);

    res.status(201).json({
      status: 'success',
      message: 'Address added successfully',
      address: result.recordset[0]
    });

  } catch (error) {
    console.error('Error adding address:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
};

const updateAddress = async (req, res) => {
  let connection;
  try {
    const { id } = req.params;
    const { receiverName, phone, houseNumber, street, ward, district, province, addressType, isDefault } = req.body;

    connection = await new sql.ConnectionPool(config).connect();

    // Nếu cập nhật thành địa chỉ mặc định
    if (isDefault) {
      await connection.request()
        .input('userId', sql.Int, req.body.userId)
        .query(`
          UPDATE Addresses
          SET is_default = 0
          WHERE user_id = @userId
        `);
    }

    const result = await connection.request()
      .input('id', sql.Int, id)
      .input('receiverName', sql.NVarChar, receiverName)
      .input('phone', sql.VarChar, phone)
      .input('houseNumber', sql.NVarChar, houseNumber)
      .input('street', sql.NVarChar, street)
      .input('ward', sql.NVarChar, ward)
      .input('district', sql.NVarChar, district)
      .input('province', sql.NVarChar, province)
      .input('addressType', sql.NVarChar, addressType)
      .input('isDefault', sql.Bit, isDefault)
      .query(`
        UPDATE Addresses
        SET receiver_name = @receiverName,
            phone = @phone,
            house_number = @houseNumber,
            street = @street,
            ward = @ward,
            district = @district,
            province = @province,
            address_type = @addressType,
            is_default = @isDefault
        OUTPUT INSERTED.*
        WHERE id = @id
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Address not found'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Address updated successfully',
      address: result.recordset[0]
    });

  } catch (error) {
    console.error('Error updating address:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
};

const deleteAddress = async (req, res) => {
  let connection;
  try {
    const { id } = req.params;

    connection = await new sql.ConnectionPool(config).connect();
    const result = await connection.request()
      .input('id', sql.Int, id)
      .query(`
        DELETE FROM Addresses
        OUTPUT DELETED.*
        WHERE id = @id
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Address not found'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Address deleted successfully'
    });

  } catch (error) {
    console.error('Error deleting address:', error);
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
};

module.exports = {
  getAddresses,
  getDefaultAddress,
  addAddress,
  updateAddress,
  deleteAddress
};