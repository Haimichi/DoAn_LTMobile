const sql = require('mssql');
const db = require('../config/db');

class Review {
  static async create(reviewData) {
    try {
      const pool = await sql.connect(db);
      const result = await pool.request()
        .input('user_id', sql.Int, reviewData.user_id)
        .input('book_id', sql.Int, reviewData.book_id)
        .input('comment', sql.NVarChar, reviewData.review)
        .input('rating', sql.Int, reviewData.rating)
        .input('created_at', sql.DateTime, new Date())
        .input('full_name', sql.NVarChar, reviewData.full_name)
        .query(`
          INSERT INTO Reviews (user_id, book_id, comment, rating, created_at, full_name)
          VALUES (@user_id, @book_id, @comment, @rating, @created_at, @full_name);
          SELECT SCOPE_IDENTITY() AS review_id;
        `);
      return result.recordset[0];
    } catch (error) {
      throw error;
    }
  }

  static async getByBookId(bookId) {
    try {
      const pool = await sql.connect(db);
      const result = await pool.request()
        .input('book_id', sql.Int, bookId)
        .query(`
          SELECT 
            review_id,
            user_id,
            book_id,
            comment,
            rating,
            created_at,
            full_name
          FROM Reviews
          WHERE book_id = @book_id
          ORDER BY created_at DESC
        `);
      return result.recordset;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Review;