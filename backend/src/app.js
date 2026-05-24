const express = require("express");
const cors = require("cors");
require("./config/database"); // Init DB, PRAGMAs & Création base enterprise.db

const errorHandler = require("./middlewares/errorHandler");

// Import des Modules (Feature-Based)
const employeeRoutes = require("./modules/employees/employee.routes");
const productRoutes = require("./modules/products/product.routes");
const salesRoutes = require("./modules/sales/sales.routes");
const purchaseRoutes = require("./modules/purchases/purchase.routes");
const deliveryRoutes = require("./modules/delivery/delivery.routes"); // MOTARDS
const stockOutputRoutes = require("./modules/stock_outputs/stockOutput.routes");
const dashboardRoutes = require("./modules/dashboard/dashboard.routes");
const accountingRoutes = require("./modules/accounting/accounting.routes");
const expensesRoutes = require("./modules/expenses/expenses.routes");
const chinaPurchasesRoutes = require("./modules/china_purchases/china_purchases.routes");
const sanctionsRoutes = require("./modules/sanctions/sanctions.routes");
const teamEmployeesRoutes = require("./modules/employees/employees.routes");
const analyticsRoutes = require("./modules/analytics/analytics.routes");
const auditRoutes = require("./modules/audit/audit.routes");

const app = express();

app.use(cors());
app.use(express.json());

// --- ROUTES PRINCIPALES ERP ---
app.use("/api/dashboard", dashboardRoutes); // NOUVELLE ROUTE ANALYTICS
app.use("/api/employees", employeeRoutes);
app.use("/api/products", productRoutes);
app.use("/api/sales", salesRoutes); // Bientôt déprécié au profit de stock_outputs
app.use("/api/purchases", purchaseRoutes);
app.use("/api/delivery", deliveryRoutes); 
app.use("/api/stock_outputs", stockOutputRoutes); // NOUVEAU CŒUR MÉTIER
app.use("/api/accounting", accountingRoutes); // FINANCIAL CONTROL CENTER
app.use("/api/expenses", expensesRoutes); // GESTION DES DÉPENSES
app.use("/api/china-purchases", chinaPurchasesRoutes);
app.use("/api/sanctions", sanctionsRoutes);       // MODULE SANCTIONS ÉQUIPE
app.use("/api/team", teamEmployeesRoutes);         // MODULE GESTION ÉQUIPE
app.use("/api/analytics", analyticsRoutes);
app.use("/api/audit", auditRoutes);             // MODULE AUDIT & HISTORIQUE

// Route Fallback (Erreur 404)
app.use((req, res, next) => {
    res.status(404).json({
        status: 'fail',
        message: `La route ${req.originalUrl} n'existe pas sur le serveur ERP.`
    });
});

// --- GESTION CENTRALE DES ERREURS ---
// Le filet de sécurité final
app.use(errorHandler);

// Prevent the server from crashing due to unhandled promise rejections or exceptions
process.on('unhandledRejection', (reason, promise) => {
    console.error('💥 [FATAL] Unhandled Rejection at:', promise, 'reason:', reason);
    // On ne crash pas, mais on logge l'erreur.
});

process.on('uncaughtException', (err) => {
    console.error('💥 [FATAL] Uncaught Exception thrown:', err);
    // Optionnel: log the error and decide whether to restart or keep running
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`\n===========================================`);
    console.log(`🚀 Nova genix Digital Backend Engine Démarré (Port ${PORT})`);
    console.log(`🛡️  Architecture: Clean Architecture + Transactions`);
    console.log(`💾 Base de données locale: enterprise.db`);
    console.log(`===========================================\n`);
});
