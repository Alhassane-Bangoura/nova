const { allQuery } = require('../../utils/databaseHelper');

class AuditRepository {
    /**
     * Récupère tous les logs avec filtres dynamiques
     */
    static async getLogs({ startDate, endDate, actionType, search } = {}) {
        const params = [];
        const conditions = [];

        if (startDate) {
            conditions.push(`date(a.created_at) >= date(?)`);
            params.push(startDate);
        }
        if (endDate) {
            conditions.push(`date(a.created_at) <= date(?)`);
            params.push(endDate);
        }
        if (actionType && actionType !== 'ALL') {
            conditions.push(`a.action_type = ?`);
            params.push(actionType);
        }
        if (search) {
            conditions.push(`(a.description LIKE ? OR a.employee_name LIKE ? OR a.entity_name LIKE ?)`);
            params.push(`%${search}%`, `%${search}%`, `%${search}%`);
        }

        const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

        return await allQuery(`
            SELECT
                a.id,
                a.action_type,
                a.entity_name,
                a.entity_id,
                a.description,
                a.employee_name,
                a.created_at
            FROM audit_logs a
            ${where}
            ORDER BY a.created_at DESC
            LIMIT 200
        `, params);
    }

    /**
     * Récupère les stats pour le résumé en haut de page
     */
    static async getStats({ startDate, endDate } = {}) {
        const params = [];
        const conditions = [];
        if (startDate) { conditions.push(`date(created_at) >= date(?)`); params.push(startDate); }
        if (endDate)   { conditions.push(`date(created_at) <= date(?)`); params.push(endDate); }
        const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

        const rows = await allQuery(`
            SELECT action_type, COUNT(*) as count
            FROM audit_logs
            ${where}
            GROUP BY action_type
        `, params);

        const stats = { total: 0, VENTE: 0, DEPENSE: 0, STOCK: 0, SANCTION: 0 };
        for (const row of rows) {
            stats[row.action_type] = row.count;
            stats.total += row.count;
        }
        return stats;
    }
}

module.exports = AuditRepository;
