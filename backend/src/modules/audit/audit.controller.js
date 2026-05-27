const AuditRepository = require('./audit.repository');

const getAuditLogs = async (req, res, next) => {
    try {
        const { startDate, endDate, actionType, search } = req.query;
        const [logs, stats] = await Promise.all([
            AuditRepository.getLogs({ startDate, endDate, actionType, search }),
            AuditRepository.getStats({ startDate, endDate, search }),
        ]);
        res.json({ status: 'success', data: { logs, stats } });
    } catch (err) {
        next(err);
    }
};

module.exports = { getAuditLogs };
