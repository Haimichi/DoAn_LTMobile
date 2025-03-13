const express = require('express');
const router = express.Router();
const voucherController = require('../controllers/voucherController');

// Lấy tất cả vouchers
router.get('/', async (req, res) => {
  try {
    await voucherController.getVouchers(req, res);
  } catch (err) {
    console.error('Error in GET /api/vouchers:', err);
    res.status(500).json({ status: 'error', message: 'Có lỗi xảy ra' });
  }
});

// Lấy voucher theo ID
router.get('/:id', async (req, res) => {
  try {
    await voucherController.getVoucherById(req, res);
  } catch (err) {
    console.error('Error in GET /api/vouchers/:id:', err);
    res.status(500).json({ status: 'error', message: 'Có lỗi xảy ra' });
  }
});

// Thêm voucher mới
router.post('/', async (req, res) => {
  try {
    await voucherController.createVoucher(req, res);
  } catch (err) {
    console.error('Error in POST /api/vouchers:', err);
    res.status(500).json({ status: 'error', message: 'Có lỗi xảy ra' });
  }
});

// Cập nhật voucher
router.put('/:id', async (req, res) => {
  try {
    await voucherController.updateVoucher(req, res);
  } catch (err) {
    console.error('Error in PUT /api/vouchers/:id:', err);
    res.status(500).json({ status: 'error', message: 'Có lỗi xảy ra' });
  }
});

// Xoá voucher
router.delete('/:id', async (req, res) => {
  try {
    await voucherController.deleteVoucher(req, res);
  } catch (err) {
    console.error('Error in DELETE /api/vouchers/:id:', err);
    res.status(500).json({ status: 'error', message: 'Có lỗi xảy ra' });
  }
});

module.exports = router;