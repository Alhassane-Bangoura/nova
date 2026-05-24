const ExpensesService = require('./expenses.service');

exports.createExpense = async (req, res, next) => {
    try {
        const result = await ExpensesService.createExpense(req.body);
        res.status(201).json({ success: true, data: result });
    } catch (error) {
        if (error.message === 'INSUFFICIENT_CASH') {
            return res.status(400).json({
                success: false,
                code: 'INSUFFICIENT_CASH',
                currentCash: error.currentCash,
                requested: error.requested,
                message: 'Solde insuffisant',
            });
        }
        next(error);
    }
};

exports.getExpenses = async (req, res, next) => {
    try {
        const result = await ExpensesService.getExpenses();
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};
