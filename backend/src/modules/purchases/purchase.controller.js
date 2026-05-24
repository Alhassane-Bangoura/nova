const purchaseService = require('./purchase.service');

const receiveStock = async (req, res, next) => {
    try {
        const purchase = await purchaseService.receiveStockFromChina(req.body);
        
        // Les clés de réponse JSON peuvent rester standard (status, data), 
        // mais les valeurs et messages sont 100% en Français pour la plateforme.
        res.status(201).json({
            statut: 'succès',
            message: 'TRANSACTION RÉUSSIE : Marchandise reçue de Chine, inventaire mis à jour et dépense enregistrée en comptabilité !',
            donnees: purchase
        });
    } catch (error) {
        next(error);
    }
};

module.exports = { receiveStock };
