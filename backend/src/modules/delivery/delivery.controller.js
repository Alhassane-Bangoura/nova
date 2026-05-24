const deliveryService = require('./delivery.service');

const assignMotard = async (req, res, next) => {
    try {
        const { saleId, motardName, deliveryFee } = req.body;
        const delivery = await deliveryService.assignMotard(saleId, motardName, deliveryFee);
        
        res.status(201).json({
            statut: 'succès',
            message: `Le motard ${motardName} a été assigné à la livraison. Le colis est en route.`,
            donnees: delivery
        });
    } catch (error) {
        next(error);
    }
};

const completeDelivery = async (req, res, next) => {
    try {
        const { deliveryId } = req.body;
        const result = await deliveryService.completeDelivery(deliveryId);
        
        res.status(200).json({
            statut: 'succès',
            message: 'TRANSACTION RÉUSSIE : Livraison terminée. L\'argent a été ajouté à la caisse de l\'entreprise.',
            donnees: result
        });
    } catch (error) {
        next(error);
    }
};

module.exports = { assignMotard, completeDelivery };
