const mongoose = require('mongoose');

const bookSchema = new mongoose.Schema({
    title: { type: String, required: true },
    author: { type: String },
    description: { type: String },
    price: { type: Number, required: true },
    publishedYear: { type: Number },
    categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' },
    imageUrl: { type: String },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
});

const Book = mongoose.model('Book', bookSchema);

module.exports = Book;
