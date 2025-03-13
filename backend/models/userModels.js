// const mongoose = require('mongoose');

// const userSchema = new mongoose.Schema({
//     fullName: { type: String, required: true },
//     email: { type: String, required: true, unique: true },
//     passwordHash: { type: String, required: true },
//     phoneNumber: { type: String },
//     birthDate: { type: Date },
//     role: { type: String, default: 'customer' }, // customer, admin, guest
//     avatarUrl: { type: String },
//     createdAt: { type: Date, default: Date.now },
//     updatedAt: { type: Date, default: Date.now }
// });

// const User = mongoose.model('User', userSchema);

// module.exports = User;


const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    fullName: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    passwordHash: { type: String, required: true },
    phoneNumber: { type: String },
    birthDate: { type: Date },
    role_id: { type: Number, ref: 'Role', required: true },
    avatarUrl: { type: String },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
    ban_id: { type: Number, ref: 'Banned', required: true }
});

const User = mongoose.model('User', userSchema);

module.exports = User;
