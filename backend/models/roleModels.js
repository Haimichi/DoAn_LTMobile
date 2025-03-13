const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema({
    role_id: { type: Number, required: true },
    role_name: { type: String, maxlength: 20, default: null }
});

const Admin = mongoose.model('Role', adminSchema);

module.exports = { Role };