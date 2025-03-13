// const sql = require('mssql');
// const db = require('../config/db');

// exports.getCategories = async (req, res) => {
//   try {
//     let pool = await sql.connect(db);
//     const result = await pool.request()
//       .query('SELECT category_id, name FROM Categories');
    
//     res.json({
//       status: 'success',
//       data: result.recordset
//     });
//   } catch (err) {
//     console.log('Error:', err);
//     res.status(500).json({
//       status: 'error',
//       message: err.message
//     });
//   }
// };

// exports.getCategoryById = async (req, res) => {
//   try {
//     let pool = await sql.connect(db);
//     const result = await pool.request()
//       .input('category_id', sql.Int, req.params.id)
//       .query('SELECT * FROM Categories WHERE category_id = @category_id');

//     if (result.recordset.length === 0) {
//       return res.status(404).json({
//         status: 'error',
//         message: 'Category not found'
//       });
//     }

//     res.json({
//       status: 'success',
//       data: result.recordset[0]
//     });
//   } catch (err) {
//     res.status(500).json({
//       status: 'error',
//       message: err.message
//     });
//   }
// };

// exports.createCategory = async (req, res) => {
//   try {
//     let pool = await sql.connect(db);
//     const result = await pool.request()
//       .input('name', sql.NVarChar, req.body.name)
//       .query(`
//         INSERT INTO Categories (name)
//         VALUES (@name);
//         SELECT SCOPE_IDENTITY() AS id;
//       `);

//     res.status(201).json({
//       status: 'success',
//       data: {
//         category_id: result.recordset[0].id,
//         name: req.body.name
//       }
//     });
//   } catch (err) {
//     res.status(400).json({
//       status: 'error',
//       message: err.message
//     });
//   }
// };

// exports.updateCategory = async (req, res) => {
//   try {
//     let pool = await sql.connect(db);
//     const result = await pool.request()
//       .input('category_id', sql.Int, req.params.id)
//       .input('name', sql.NVarChar, req.body.name)
//       .query(`
//         UPDATE Categories 
//         SET name = @name
//         WHERE category_id = @category_id
//       `);

//     if (result.rowsAffected[0] === 0) {
//       return res.status(404).json({
//         status: 'error',
//         message: 'Category not found'
//       });
//     }

//     res.json({
//       status: 'success',
//       data: {
//         category_id: parseInt(req.params.id),
//         name: req.body.name
//       }
//     });
//   } catch (err) {
//     res.status(400).json({
//       status: 'error',
//       message: err.message
//     });
//   }
// };

// exports.deleteCategory = async (req, res) => {
//   try {
//     let pool = await sql.connect(db);
    
//     // Kiểm tra xem có sách nào thuộc thể loại này không
//     const checkBooks = await pool.request()
//       .input('category_id', sql.Int, req.params.id)
//       .query('SELECT COUNT(*) as bookCount FROM Books WHERE category_id = @category_id');
    
//     if (checkBooks.recordset[0].bookCount > 0) {
//       return res.status(400).json({
//         status: 'error',
//         message: 'Có sách thuộc thể loại này! Không thể xóa!'
//       });
//     }

//     // Nếu không có sách nào, tiến hành xóa thể loại
//     const result = await pool.request()
//       .input('category_id', sql.Int, req.params.id)
//       .query('DELETE FROM Categories WHERE category_id = @category_id');

//     if (result.rowsAffected[0] === 0) {
//       return res.status(404).json({
//         status: 'error',
//         message: 'Category not found'
//       });
//     }

//     res.json({
//       status: 'success',
//       message: 'Category deleted successfully'
//     });
//   } catch (err) {
//     res.status(400).json({
//       status: 'error',
//       message: err.message
//     });
//   }
// };

/*
const sql = require('mssql');
const db = require('../config/db');
const multer = require('multer');
const path = require('path');

// Cấu hình multer
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

const upload = multer({ storage: storage }).single('image');

exports.getCategories = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    const result = await pool.request()
      .query('SELECT category_id, name, category_image FROM Categories');
    
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

exports.getCategoryById = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    const result = await pool.request()
      .input('category_id', sql.Int, req.params.id)
      .query('SELECT * FROM Categories WHERE category_id = @category_id');

    if (result.recordset.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Category not found'
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

exports.createCategory = async (req, res) => {
  try {
    console.log('Creating category with data:', req.body);
    let pool = await sql.connect(db);
    console.log('Category image before saving:', req.body.category_image);
    const result = await pool.request()
      .input('name', sql.NVarChar, req.body.name)
      .input('category_image', sql.NVarChar, req.body.category_image)
      .query(`
        INSERT INTO Categories (name, category_image)
        VALUES (@name, @category_image);
        SELECT SCOPE_IDENTITY() AS id;
      `);

    console.log('Category created with ID:', result.recordset[0].id);

    res.status(201).json({
      status: 'success',
      data: {
        category_id: result.recordset[0].id,
        name: req.body.name,
        category_image: req.body.category_image
      }
    });
  } catch (err) {
    console.error('Error creating category:', err);
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.updateCategory = async (req, res) => {
  try {
    console.log('Updating category with ID:', req.params.id, 'and data:', req.body);
    let pool = await sql.connect(db);
    const result = await pool.request()
      .input('category_id', sql.Int, req.params.id)
      .input('name', sql.NVarChar, req.body.name)
      .input('category_image', sql.NVarChar, req.body.category_image)
      .query(`
        UPDATE Categories 
        SET name = @name, category_image = @category_image
        WHERE category_id = @category_id
      `);

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Category not found'
      });
    }

    console.log('Category updated with ID:', req.params.id);

    res.json({
      status: 'success',
      data: {
        category_id: parseInt(req.params.id),
        name: req.body.name,
        category_image: req.body.category_image
      }
    });
  } catch (err) {
    console.error('Error updating category:', err);
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.deleteCategory = async (req, res) => {
  try {
    let pool = await sql.connect(db);
    
    // Kiểm tra xem có sách nào thuộc thể loại này không
    const checkBooks = await pool.request()
      .input('category_id', sql.Int, req.params.id)
      .query('SELECT COUNT(*) as bookCount FROM Books WHERE category_id = @category_id');
    
    if (checkBooks.recordset[0].bookCount > 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Có sách thuộc thể loại này! Không thể xóa!'
      });
    }

    // Nếu không có sách nào, tiến hành xóa thể loại
    const result = await pool.request()
      .input('category_id', sql.Int, req.params.id)
      .query('DELETE FROM Categories WHERE category_id = @category_id');

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Category not found'
      });
    }

    res.json({
      status: 'success',
      message: 'Category deleted successfully'
    });
  } catch (err) {
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.uploadImage = (req, res) => {
  upload(req, res, function (err) {
    if (err) {
      return res.status(400).json({
        status: 'error',
        message: 'Không thể upload hình ảnh'
      });
    }
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    res.json({
      status: 'success',
      imageUrl: imageUrl
    });
  });
};*/
const sql = require('mssql');
const config = require('../config/db');

exports.getCategories = async (req, res) => {
  try {
    let pool = await sql.connect(config);
    const result = await pool.request()
      .query('SELECT category_id, name, category_image FROM Categories');
    
    res.json({
      status: 'success',
      data: result.recordset
    });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.getCategoryById = async (req, res) => {
  try {
    let pool = await sql.connect(config);
    const result = await pool.request()
      .input('categoryId', sql.Int, req.params.id)
      .query('SELECT * FROM Categories WHERE category_id = @categoryId');

    if (result.recordset.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Category not found'
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

exports.createCategory = async (req, res) => {
  try {
    let pool = await sql.connect(config);
    const result = await pool.request()
      .input('name', sql.NVarChar, req.body.name)
      .input('categoryImage', sql.NVarChar, req.body.category_image)
      .query('INSERT INTO Categories (name, category_image) VALUES (@name, @categoryImage); SELECT SCOPE_IDENTITY() AS id;');

    res.status(201).json({
      status: 'success',
      data: {
        category_id: result.recordset[0].id,
        name: req.body.name,
        category_image: req.body.category_image
      }
    });
  } catch (err) {
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.updateCategory = async (req, res) => {
  try {
    let pool = await sql.connect(config);
    const result = await pool.request()
      .input('categoryId', sql.Int, req.params.id)
      .input('name', sql.NVarChar, req.body.name)
      .input('categoryImage', sql.NVarChar, req.body.category_image)
      .query('UPDATE Categories SET name = @name, category_image = @categoryImage WHERE category_id = @categoryId');

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Category not found'
      });
    }

    res.json({
      status: 'success',
      data: {
        category_id: parseInt(req.params.id),
        name: req.body.name,
        category_image: req.body.category_image
      }
    });
  } catch (err) {
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.deleteCategory = async (req, res) => {
  try {
    let pool = await sql.connect(config);
    const result = await pool.request()
      .input('categoryId', sql.Int, req.params.id)
      .query('DELETE FROM Categories WHERE category_id = @categoryId');

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Category not found'
      });
    }

    res.json({
      status: 'success',
      message: 'Category deleted successfully'
    });
  } catch (err) {
    res.status(400).json({
      status: 'error',
      message: err.message
    });
  }
};

exports.uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        message: 'Không có file được upload',
      });
    }

    // Trả về đường dẫn tương đối của file
    const imageUrl = `uploads/categories/${req.file.filename}`;
    
    res.status(200).json({
      status: 'success',
      imageUrl: imageUrl
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({
      message: 'Internal Server Error',
      error: error.message
    });
  }
};