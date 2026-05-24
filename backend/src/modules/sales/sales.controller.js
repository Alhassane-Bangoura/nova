const salesService = require('./sales.service');

const createSale = async (req, res, next) => {
    try {
        const sale = await salesService.createSale(req.body);
        
        res.status(201).json({
            status: 'success',
            message: 'TRANSACTION RÉUSSIE : Vente enregistrée, stock mis à jour, et caisse créditée !',
            data: sale
        });
    } catch (error) {
        next(error);
    }
};

module.exports = { createSale };
