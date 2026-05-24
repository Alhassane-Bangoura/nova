const express = require('express');
const salesController = require('./sales.controller');

const router = express.Router();

router.post('/', salesController.createSale);

module.exports = router;
