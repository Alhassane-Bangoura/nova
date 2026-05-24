const express = require('express');
const router = express.Router();
const accountingController = require('./accounting.controller');

router.get('/dashboard', accountingController.getFinancialDashboard);
router.post('/fund-cash', accountingController.fundCaisse);

module.exports = router;
