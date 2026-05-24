const express = require('express');
const chinaPurchasesController = require('./china_purchases.controller');

const router = express.Router();

router.get('/', chinaPurchasesController.getAll);
router.post('/', chinaPurchasesController.create);
router.put('/:id/receive', chinaPurchasesController.receive);
router.get('/:id/report', chinaPurchasesController.getReport);

module.exports = router;
