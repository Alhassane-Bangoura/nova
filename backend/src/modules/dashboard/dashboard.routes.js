const express = require('express');
const router = express.Router();
const dashboardController = require('./dashboard.controller');

// Route pour récupérer toutes les données du dashboard
router.get('/', dashboardController.getStats);

module.exports = router;
