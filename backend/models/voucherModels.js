const mongoose = require('mongoose');

const voucherSchema = new mongoose.Schema({
    voucher_id: { type: Number, required: true },
    code: { type: String, required: true, maxlength: 255 },
    discount: { type: Number, required: true },
    voucher_quantity: { type: Number, required: true }
});

const Voucher = mongoose.model('Voucher', voucherSchema);

module.exports = { Voucher };