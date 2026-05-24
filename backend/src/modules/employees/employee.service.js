const crypto = require('crypto');
const employeeRepository = require('./employee.repository');

// Le Service contient 100% de la logique métier.
// S'il faut calculer des jours de congés, vérifier des rôles, c'est ici.

const create = async (employeeData) => {
    // 1. Validation métier (Un Validator séparé est mieux, mais on le met ici pour l'exemple)
    if (!employeeData.firstName || !employeeData.lastName || !employeeData.email) {
        throw new Error('Les champs prénom, nom et email sont obligatoires.');
    }

    // 2. Règle métier : Vérifier que l'email est unique
    const existingEmployee = await employeeRepository.findByEmail(employeeData.email);
    if (existingEmployee) {
        throw new Error('Un employé avec cet email existe déjà dans le système.');
    }

    // 3. Préparation pour le mode "Offline-First"
    // On génère TOUJOURS un UUID (jamais un ID auto-incrémenté 1, 2, 3) !
    const newEmployee = {
        id: crypto.randomUUID(), 
        first_name: employeeData.firstName,
        last_name: employeeData.lastName,
        email: employeeData.email,
        role: employeeData.role || 'employee',
        is_synced: 0, // 0 = Donnée créée en local, pas encore envoyée au Cloud
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
    };

    // 4. On délègue la sauvegarde physique au Repository
    await employeeRepository.insert(newEmployee);
    
    return newEmployee;
};

const findAll = async () => {
    return await employeeRepository.findAll();
};

module.exports = {
    create,
    findAll
};
