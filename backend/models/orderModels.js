const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    orderDate: { type: Date, default: Date.now },
    totalAmount: { type: Number },
    status: { type: String, default: 'pending' }, // pending, completed, canceled
    paymentMethod: { type: String }, // VNPay, MoMo, ZaloPay, COD
    paymentStatus: { type: String, default: 'pending' }, // pending, completed, failed
    transactionId: { type: String },
    shippingAddress: { type: String },
    items: [{
        bookId: { type: mongoose.Schema.Types.ObjectId, ref: 'Book', required: true },
        quantity: { type: Number, required: true },
        price: { type: Number, required: true }
    }],
    createdAt: { type: Date, default: Date.now }
});

const Order = mongoose.model('Order', orderSchema);

module.exports = Order;
