const express = require('express');
const employeeController = require('./employee.controller');

const router = express.Router();

// L'URL commence par /api/employees (défini dans app.js)

// 1. Créer un employé
router.post('/', employeeController.createEmployee);

// 2. Récupérer tous les employés
router.get('/', employeeController.getAllEmployees);

module.exports = router;
