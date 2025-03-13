// const mongoose = require('mongoose');

// const categorySchema = new mongoose.Schema({
//     category_id: { type: Number, required: true },
//     name: { type: String, maxlength: 100, default: null },
//     category_image: { type: String },
// });

// const Category = mongoose.model('Category', categorySchema);

// module.exports = Category;

const sql = require('mssql');

// SQL Server table structure
const categoryTableStructure = `
CREATE TABLE Categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    category_image NVARCHAR(MAX)
)`;

// Helper functions
const categoryQueries = {
  getAllCategories: 'SELECT * FROM Categories',
  getCategoryById: 'SELECT * FROM Categories WHERE category_id = @categoryId',
  createCategory: 'INSERT INTO Categories (name, category_image) VALUES (@name, @categoryImage)',
  updateCategory: 'UPDATE Categories SET name = @name, category_image = @categoryImage WHERE category_id = @categoryId',
  deleteCategory: 'DELETE FROM Categories WHERE category_id = @categoryId'
};

module.exports = {
  categoryTableStructure,
  categoryQueries
};