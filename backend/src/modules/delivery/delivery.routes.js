const express = require('express');
const deliveryController = require('./delivery.controller');

const router = express.Router();

router.post('/assign', deliveryController.assignMotard);
router.post('/complete', deliveryController.completeDelivery);

module.exports = router;
