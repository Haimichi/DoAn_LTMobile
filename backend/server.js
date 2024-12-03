const express = require('express');
const app = express();
const cors = require('cors');
require('dotenv').config({ path: './config/.env' });

const { connectToDatabase } = require('./config/db');  // Import hàm connectToDatabase từ db.js

console.log('DB_HOST:', process.env.DB_HOST);  // Kiểm tra giá trị của biến DB_HOST
console.log('DB_USER:', process.env.DB_USER);  // Kiểm tra giá trị của biến DB_USER
console.log('DB_PASSWORD:', process.env.DB_PASSWORD);  // Kiểm tra giá trị của biến DB_PASSWORD
console.log('DB_NAME:', process.env.DB_NAME);  // Kiểm tra giá trị của biến DB_NAME

const authRoutes = require('./routes/authRoutes'); // Đảm bảo đường dẫn đúng
const bookRoutes = require('./routes/bookRoutes');  // Đảm bảo bạn đã import đúng file route

connectToDatabase();  // Gọi hàm kết nối tới cơ sở dữ liệu

app.use(express.json());
app.use(cors());

// Sử dụng các routes
app.use('/api/auth', authRoutes);
app.use('/api/books', bookRoutes); 

// Khởi động server
app.listen(5000, () => {
  console.log('Server đang chạy trên cổng 5000');
});
