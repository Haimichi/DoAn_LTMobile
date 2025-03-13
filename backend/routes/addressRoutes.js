const express = require('express');
const router = express.Router();
const addressController = require('../controllers/addressController');

// Routes
router.get('/get-addresses', addressController.getAddresses);
router.get('/default', addressController.getDefaultAddress);
router.post('/', addressController.addAddress);
router.put('/:id', addressController.updateAddress);
router.delete('/:id', addressController.deleteAddress);

module.exports = router;