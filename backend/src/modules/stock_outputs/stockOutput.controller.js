const StockOutputService = require('./stockOutput.service');

exports.createOutput = async (req, res, next) => {
    try {
        const { productId, quantity, sellingPrice, location, clientName } = req.body;

        if (!productId || !quantity || !sellingPrice || !location || !clientName) {
            return res.status(400).json({ 
                success: false, 
                message: "Tous les champs (productId, quantity, sellingPrice, location, clientName) sont requis." 
            });
        }

        const result = await StockOutputService.createOutput({
            productId,
            quantity,
            sellingPrice,
            location,
            clientName
        });

        res.status(201).json(result);
    } catch (error) {
        // En cas d'erreur métier (ex: stock insuffisant)
        if (error.message.includes('Stock insuffisant')) {
            return res.status(400).json({ success: false, message: error.message });
        }
        next(error); // Renvoie au middleware errorHandler global
    }
};

exports.getOutputById = async (req, res, next) => {
    try {
        const { id } = req.params;
        const output = await StockOutputService.getOutputById(id);
        if (!output) {
            return res.status(404).json({ success: false, message: 'Sortie non trouvée' });
        }
        res.status(200).json({ success: true, data: output });
    } catch (error) {
        next(error);
    }
};

exports.deleteOutput = async (req, res, next) => {
    try {
        const { id } = req.params;
        const result = await StockOutputService.deleteOutput(id);
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};
exports.getAllOutputs = async (req, res, next) => {
    try {
        const outputs = await StockOutputService.getOutputs();
        res.status(200).json({ success: true, data: outputs });
    } catch (error) {
        next(error);
    }
};
