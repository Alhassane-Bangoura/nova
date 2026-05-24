const express = require('express');
const purchaseController = require('./purchase.controller');

const router = express.Router();

router.post('/', purchaseController.receiveStock);

module.exports = router;
