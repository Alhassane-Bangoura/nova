const SanctionsRepository = require('./sanctions.repository');
const AppError = require('../../errors/AppError');
const db = require('../../config/database');

const create = async (req, res, next) => {
    try {
        const { employee_id, reason } = req.body;
        if (!employee_id || !reason) {
            throw new AppError('L\'employé et le motif sont requis', 400);
        }
        const sanction = await SanctionsRepository.create({ employee_id, reason });
        // Récupérer le nom de l'employé pour l'audit
        const db2 = require('../../config/database');
        db2.get('SELECT first_name || \' \' || last_name as full_name FROM employees WHERE id = ?', [employee_id], (err, row) => {
            const empName = row ? row.full_name : `Employé ID ${employee_id}`;
            db.run(`INSERT INTO audit_logs (action_type, entity_name, entity_id, description, employee_name) VALUES (?, ?, ?, ?, ?)`,
                ['SANCTION', 'sanctions', sanction.id || employee_id,
                 `Sanction enregistrée pour ${empName}: ${reason}`,
                 'Système']);
        });
        res.status(201).json({ success: true, data: sanction });
    } catch (error) {
        next(error);
    }
};

const getAll = async (req, res, next) => {
    try {
        const sanctions = await SanctionsRepository.getAll();
        res.status(200).json({ success: true, data: sanctions });
    } catch (error) {
        next(error);
    }
};

const getStats = async (req, res, next) => {
    try {
        const stats = await SanctionsRepository.getStats();
        res.status(200).json({ success: true, data: stats });
    } catch (error) {
        next(error);
    }
};

const updateStatus = async (req, res, next) => {
    try {
        const { status } = req.body;
        const allowed = ['En attente', 'Payée', 'Annulée'];
        if (!status || !allowed.includes(status)) {
            throw new AppError('Statut invalide', 400);
        }
        const result = await SanctionsRepository.updateStatus(req.params.id, status);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};

module.exports = { create, getAll, getStats, updateStatus };
