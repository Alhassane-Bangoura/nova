const DashboardService = require('./dashboard.service');

exports.getStats = async (req, res, next) => {
    try {
        const result = await DashboardService.getDashboardStats();
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};
