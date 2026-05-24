const EmployeesRepository = require('./employees.repository');
const AppError = require('../../errors/AppError');

const create = async (req, res, next) => {
    try {
        const data = req.body;
        if (!data.name) {
            throw new AppError('Le nom de l\'employé est requis', 400);
        }
        const employee = await EmployeesRepository.create(data);
        res.status(201).json({ success: true, data: employee });
    } catch (error) {
        next(error);
    }
};

const getAll = async (req, res, next) => {
    try {
        const employees = await EmployeesRepository.getAll();
        res.status(200).json({ success: true, data: employees });
    } catch (error) {
        next(error);
    }
};

const update = async (req, res, next) => {
    try {
        const employee = await EmployeesRepository.update(req.params.id, req.body);
        res.status(200).json({ success: true, data: employee });
    } catch (error) {
        next(error);
    }
};

const remove = async (req, res, next) => {
    try {
        await EmployeesRepository.delete(req.params.id);
        res.status(200).json({ success: true, message: 'Employé supprimé' });
    } catch (error) {
        next(error);
    }
};

module.exports = { create, getAll, update, remove };
