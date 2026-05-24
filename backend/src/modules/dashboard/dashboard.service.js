const DashboardRepository = require('./dashboard.repository');

class DashboardService {
    static async getDashboardStats() {
        try {
            // Exécution de toutes les requêtes en parallèle pour optimiser la performance
            const [
                currentCash,
                dailyProfit,
                dailyOutputs,
                dailyExpenses,
                totalStock,
                topProductsVolume,
                topProductsProfit,
                topLocations,
                financialEvolution,
                expenseEvolution,
                lowStockProducts,
                recentOutputs,
                recentExpenses,
                recentPurchases
            ] = await Promise.all([
                DashboardRepository.getCurrentCash(),
                DashboardRepository.getDailyProfit(),
                DashboardRepository.getDailyOutputs(),
                DashboardRepository.getDailyExpenses(),
                DashboardRepository.getTotalStock(),
                DashboardRepository.getTopProductsByVolume(),
                DashboardRepository.getTopProductsByProfit(),
                DashboardRepository.getTopLocations(),
                DashboardRepository.getFinancialEvolution(),
                DashboardRepository.getExpenseEvolution(),
                DashboardRepository.getLowStockProducts(),
                DashboardRepository.getRecentOutputs(),
                DashboardRepository.getRecentExpenses(),
                DashboardRepository.getRecentPurchases()
            ]);

            return {
                success: true,
                data: {
                    kpis: {
                        currentCash,
                        dailyProfit,
                        dailyOutputs,
                        dailyExpenses,
                        totalStock,
                        lowStockCount: lowStockProducts.length
                    },
                    productsPerformance: {
                        topByVolume: topProductsVolume,
                        topByProfit: topProductsProfit
                    },
                    locationsPerformance: {
                        topLocations
                    },
                    evolution: {
                        financial: financialEvolution,
                        expenses: expenseEvolution
                    },
                    alerts: {
                        lowStockProducts
                    },
                    tables: {
                        recentOutputs,
                        recentExpenses,
                        recentPurchases
                    }
                }
            };
        } catch (error) {
            console.error('Erreur lors de la récupération des analytics :', error);
            throw error;
        }
    }
}

module.exports = DashboardService;
