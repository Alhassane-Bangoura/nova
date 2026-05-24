const express = require('express');
const router = express.Router();
const stockOutputController = require('./stockOutput.controller');

// Route pour enregistrer une sortie
router.post('/', stockOutputController.createOutput);

// Route pour l'historique des sorties (Dashboard)
router.get('/', stockOutputController.getAllOutputs);
router.get('/:id', stockOutputController.getOutputById);
router.delete('/:id', stockOutputController.deleteOutput);

module.exports = router;
