const sql = require('mssql');
const db = require('../config/db');

// Get all books
exports.getBooks = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    console.log('Executing getBooks query...');
    
    const result = await pool.request()
      .query(`
        SELECT b.*, c.name as category_name 
        FROM Books b
        LEFT JOIN Categories c ON b.category_id = c.category_id
      `);
    
    console.log(`Found ${result.recordset.length} books`);
    
    res.json({
      status: 'success',
      data: result.recordset
    });
  } catch (err) {
    console.error('Error in getBooks:', err);
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  } finally {
    sql.close();
  }
};

// Get book by ID
exports.getBookById = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    const result = await pool.request()
      .input('book_id', sql.Int, req.params.id)
      .query(`
        SELECT b.*, c.name as category_name,
        CASE 
          WHEN b.quantity <= 5 THEN b.quantity
          ELSE 999999 
        END as max_purchasable_quantity,
        b.preview_images
        FROM Books b
        LEFT JOIN Categories c ON b.category_id = c.category_id
        WHERE b.book_id = @book_id
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Book not found'
      });
    }

    // Xử lý preview_images trước khi trả về
    const book = result.recordset[0];
    if (book.preview_images) {
      try {
        book.preview_images = JSON.parse(book.preview_images);
      } catch (e) {
        book.preview_images = book.preview_images.split(',').map(url => url.trim());
      }
    } else {
      book.preview_images = [];
    }

    res.json({
      status: 200,
      data: book
    });
  } catch (err) {
    console.log('Error:', err);
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  }
};

// Create new book
exports.createBook = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    const currentDate = new Date().toISOString();
    
    const result = await pool.request()
      .input('title', sql.NVarChar, req.body.title)
      .input('author', sql.NVarChar, req.body.author)
      .input('description', sql.NVarChar, req.body.description)
      .input('price', sql.Decimal(10,2), req.body.price)
      .input('published_year', sql.Int, req.body.published_year)
      .input('category_id', sql.Int, req.body.category_id)
      .input('image_url', sql.NVarChar, req.body.image_url)
      .input('preview_images', sql.NVarChar, JSON.stringify(req.body.preview_images))
      .input('quantity', sql.Int, req.body.quantity)
      .input('created_at', sql.DateTime, currentDate)
      .input('updated_at', sql.DateTime, currentDate)
      .query(`
        INSERT INTO Books (
          title, author, description, price, category_id,
          image_url, preview_images, quantity, created_at, updated_at
        )
        OUTPUT INSERTED.*
        VALUES (
          @title, @author, @description, @price, @category_id,
          @image_url, @preview_images, @quantity, @created_at, @updated_at
        );
      `);

    res.status(201).json({
      status: 'success',
      data: result.recordset[0]
    });
  } catch (err) {
    console.log('Error:', err);
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  } finally {
    sql.close();
  }
};

// Update book
exports.updateBook = async (req, res) => {
  try {
    const { book_id, title, author, price, description, image_url, preview_images, quantity } = req.body;

    if (quantity < 1) {
      return res.status(400).json({
        status: 'error',
        message: 'Số lượng không được nhỏ hơn 1'
      });
    }

    const pool = await sql.connect(db);
    const result = await pool.request()
      .input('book_id', sql.Int, book_id)
      .input('title', sql.NVarChar, title)
      .input('author', sql.NVarChar, author)
      .input('price', sql.Decimal(10, 2), price)
      .input('description', sql.NVarChar, description)
      .input('image_url', sql.NVarChar, image_url)
      .input('preview_images', sql.NVarChar, JSON.stringify(preview_images))
      .input('quantity', sql.Int, quantity)
      .query(`
        UPDATE Books 
        SET title = @title, author = @author, price = @price, description = @description, 
            image_url = @image_url, preview_images = @preview_images, quantity = @quantity 
        WHERE book_id = @book_id
      `);

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Book not found'
      });
    }

    res.status(200).json({ message: 'Cập nhật sách thành công' });
  } catch (error) {
    console.error('Error updating book:', error);
    res.status(500).json({ message: 'Cập nhật sách thất bại', error: error.message });
  }
};

// Delete book
exports.deleteBook = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    const result = await pool.request()
      .input('book_id', sql.Int, req.params.id)
      .query('DELETE FROM Books WHERE book_id = @book_id');

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Book not found'
      });
    }

    res.json({
      status: 'success',
      message: 'Book deleted successfully'
    });
  } catch (err) {
    console.log('Error:', err);
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  } finally {
    sql.close();
  }
};

// Search books
exports.searchBooks = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    const searchQuery = req.query.q;
    
    const result = await pool.request()
      .input('searchQuery', sql.NVarChar, `%${searchQuery}%`)
      .query(`
        SELECT b.*, c.name as category_name 
        FROM Books b
        LEFT JOIN Categories c ON b.category_id = c.category_id
        WHERE b.title LIKE @searchQuery 
        OR b.author LIKE @searchQuery
      `);
    
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
  } finally {
    sql.close();
  }
};

// Thêm hàm mới để lấy categories
exports.getCategories = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    const result = await pool.request()
      .query('SELECT category_id, name FROM Categories');
    
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
  } finally {
    sql.close();
  }
};

exports.uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        status: 'error',
        message: 'No file uploaded'
      });
    }

    // Trả về URL của ảnh đã upload
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    
    res.json({
      status: 'success',
      imageUrl: imageUrl
    });
  } catch (err) {
    console.log('Error:', err);
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.getBooksByCategory = async (req, res) => {
  try {
    const categoryId = req.params.categoryId;
    let pool = await sql.connect(db);
    const result = await pool.request()
      .input('categoryId', sql.Int, categoryId)
      .query('SELECT * FROM Books WHERE category_id = @categoryId');
    
    res.json({
      status: 'success',
      data: result.recordset
    });
  } catch (err) {
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  }
};

// Thêm hàm mới để cập nhật số lượng sách
exports.updateBookQuantity = async (bookId, quantityToReduce) => {
  try {
    let pool = await sql.connect(db);
    
    // Kiểm tra số lượng hiện tại
    const checkResult = await pool.request()
      .input('book_id', sql.Int, bookId)
      .query('SELECT quantity FROM Books WHERE book_id = @book_id');
    
    const currentQuantity = checkResult.recordset[0].quantity;
    const newQuantity = currentQuantity - quantityToReduce;
    
    if (newQuantity < 0) {
      throw new Error('Số lượng sách không đủ');
    }

    // Cập nhật số lượng mới
    await pool.request()
      .input('book_id', sql.Int, bookId)
      .input('quantity', sql.Int, newQuantity)
      .query(`
        UPDATE Books 
        SET quantity = @quantity 
        WHERE book_id = @book_id
      `);

    return newQuantity;
  } catch (err) {
    console.error('Error updating book quantity:', err);
    throw err;
  }
};