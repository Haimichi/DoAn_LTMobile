const mongoose = require('mongoose');

const bannedSchema = new mongoose.Schema({
    ban_id: { 
        type: Number,
        required: true,
        unique: true
    },
    status: { 
        type: String,
        required: true
    }
});

const Banned = mongoose.model('Banned', bannedSchema);

module.exports = Banned;