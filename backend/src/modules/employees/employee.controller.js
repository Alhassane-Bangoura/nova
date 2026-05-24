const employeeService = require('./employee.service');

// Le Controller est le chef d'orchestre. 
// Il ne contient AUCUNE logique métier et AUCUN SQL.
const createEmployee = async (req, res, next) => {
    try {
        const employeeData = req.body;
        
        // On demande au "Cerveau" (le Service) de faire le travail
        const newEmployee = await employeeService.create(employeeData);
        
        // On répond proprement au Frontend Flutter
        res.status(201).json({
            status: 'success',
            data: newEmployee
        });
    } catch (error) {
        // Envoie l'erreur au Middleware central
        next(error); 
    }
};

const getAllEmployees = async (req, res, next) => {
    try {
        const employees = await employeeService.findAll();
        
        res.status(200).json({
            status: 'success',
            results: employees.length,
            data: employees
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    createEmployee,
    getAllEmployees
};
