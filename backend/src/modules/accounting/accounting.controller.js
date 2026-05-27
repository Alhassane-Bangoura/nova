const AccountingService = require('./accounting.service');

exports.getFinancialDashboard = async (req, res, next) => {
    try {
        const { productId } = req.query;
        const result = await AccountingService.getFinancialControlCenterData(productId);
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};

exports.fundCaisse = async (req, res, next) => {
    try {
        const { amount, note } = req.body;
        if (!amount || amount <= 0) {
            return res.status(400).json({ success: false, message: 'Montant invalide.' });
        }
        const result = await AccountingService.fundCaisse(amount, note);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};
