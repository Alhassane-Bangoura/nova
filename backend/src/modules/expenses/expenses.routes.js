const express = require('express');
const router = express.Router();
const expensesController = require('./expenses.controller');

router.get('/', expensesController.getExpenses);
router.post('/', expensesController.createExpense);

module.exports = router;
