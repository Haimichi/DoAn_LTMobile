const mongoose = require('mongoose');

const bookSchema = new mongoose.Schema({
    book_id: { type: Number, required: true },
    title: { type: String, required: true },
    quantity: { type: Number, required: true, default: 1 },
    author: { type: String },
    description: { type: String },
    price: { type: Number, required: true },
    publishedYear: { type: Number },
    category_id: { type: Number, ref: 'Category', required: true },
    imageUrl: { type: String },
    preview_images: { type: String },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
});

const Book = mongoose.model('Book', bookSchema);

module.exports = Book;
