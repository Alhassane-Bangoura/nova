const StockOutputRepository = require('./stockOutput.repository');

class StockOutputService {
    /**
     * Crée une sortie de stock de manière sécurisée avec transaction
     * Calcule automatiquement le bénéfice par rapport au prix d'achat réel du lot
     */
    static async createOutput(data) {
        const { productId, quantity, sellingPrice, location, clientName, employeeName = 'Moussa' } = data;
        let requestedQuantity = parseInt(quantity, 10);
        const price = parseFloat(sellingPrice);

        try {
            await StockOutputRepository.beginTransaction();

            // 1. Récupérer les lots disponibles pour ce produit (FIFO : les plus anciens en premier)
            const batches = await StockOutputRepository.getAvailableBatchesFIFO(productId);

            let remainingToSatisfy = requestedQuantity;
            let totalProfit = 0;
            let totalRevenue = requestedQuantity * price;
            let outputsCreated = [];

            // 2. Parcourir les lots pour satisfaire la quantité demandée
            for (const batch of batches) {
                if (remainingToSatisfy <= 0) break;

                let qtyToTakeFromBatch = Math.min(batch.quantity_remaining, remainingToSatisfy);
                
                // Calcul des bénéfices pour cette fraction de stock
                let chunkRevenue = qtyToTakeFromBatch * price;
                let chunkCost = qtyToTakeFromBatch * batch.unit_cost_real;
                let chunkProfit = chunkRevenue - chunkCost;

                // Mettre à jour la quantité du lot
                await StockOutputRepository.deductBatchQuantity(batch.id, qtyToTakeFromBatch);

                // Enregistrer la trace de la sortie liée à ce lot
                const insertId = await StockOutputRepository.insertStockOutput({
                    productId,
                    batchId: batch.id,
                    quantity: qtyToTakeFromBatch,
                    sellingPrice: price,
                    totalRevenue: chunkRevenue,
                    totalProfit: chunkProfit,
                    location,
                    clientName
                });

                outputsCreated.push(insertId);
                totalProfit += chunkProfit;
                remainingToSatisfy -= qtyToTakeFromBatch;
            }

            // 3. Vérifier qu'on avait assez de stock
            if (remainingToSatisfy > 0) {
                throw new Error(`Stock insuffisant. Il manque ${remainingToSatisfy} unités en stock pour effectuer la sortie.`);
            }

            // 4. Mettre à jour le grand livre (Caisse)
            // On lie arbitrairement l'entrée en caisse au premier ID de sortie créé pour ce groupe
            await StockOutputRepository.insertCashTransaction(totalRevenue, outputsCreated[0]);

            // 5. Enregistrer l'audit log
            const auditDescription = `Sortie de ${requestedQuantity} unité(s) du produit ID ${productId} vers ${location}. Revenu: ${totalRevenue}, Bénéfice: ${totalProfit}`;
            await StockOutputRepository.insertAuditLog('VENTE', 'stock_outputs', outputsCreated[0], auditDescription, employeeName);

            await StockOutputRepository.commitTransaction();

            return {
                success: true,
                message: "Sortie de stock enregistrée avec succès.",
                data: {
                    totalRevenue,
                    totalProfit,
                    outputsGenerated: outputsCreated.length
                }
            };
        } catch (error) {
            await StockOutputRepository.rollbackTransaction();
            throw error;
        }
    }

    /**
     * Récupère l'historique complet des sorties (pour le dashboard)
     */
    static async getOutputs() {
        return await StockOutputRepository.findAllOutputs();
    }

    /**
    * Récupère une sortie par son ID
    */
    static async getOutputById(id) {
        return await StockOutputRepository.getOutputById(id);
    }

    /**
    * Supprime une sortie de stock (et met à jour la caisse si besoin)
    */
    static async deleteOutput(id) {
        try {
            await StockOutputRepository.beginTransaction();
            // Récupérer l'entrée pour ajuster la caisse (revenu à retirer)
            const [output] = await StockOutputRepository.getOutputById(id);
            if (!output) {
                throw new Error('Sortie introuvable');
            }
            // Supprimer la sortie
            await StockOutputRepository.deleteStockOutput(id);
            // Ajuster la caisse en créant une transaction NEGATIVE
            await StockOutputRepository.insertCashTransaction(-output.total_revenue, id);
            await StockOutputRepository.commitTransaction();
            return { success: true, message: 'Sortie supprimée.' };
        } catch (error) {
            await StockOutputRepository.rollbackTransaction();
            throw error;
        }
    }
}

module.exports = StockOutputService;
