const express = require('express');
const router = express.Router();
const sanctionsController = require('./sanctions.controller');

router.get('/', sanctionsController.getAll);
router.get('/stats', sanctionsController.getStats);
router.post('/', sanctionsController.create);
router.put('/:id/status', sanctionsController.updateStatus);

module.exports = router;
