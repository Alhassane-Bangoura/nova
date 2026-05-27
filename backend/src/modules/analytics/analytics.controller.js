const AnalyticsRepository = require('./analytics.repository');
const AppError = require('../../errors/AppError');

const getDashboard = async (req, res, next) => {
    try {
        const { startDate, endDate, productId } = req.query;
        
        if (!startDate || !endDate) {
            throw new AppError('Les dates startDate et endDate sont requises', 400);
        }

        const data = await AnalyticsRepository.getDashboardData(startDate, endDate, productId);
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getDashboard
};
