const express = require('express');
const router = express.Router();
const analyticsController = require('./analytics.controller');

router.get('/dashboard', analyticsController.getDashboard);

module.exports = router;
