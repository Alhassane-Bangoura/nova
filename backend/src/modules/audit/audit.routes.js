const express = require('express');
const router = express.Router();
const { getAuditLogs } = require('./audit.controller');

router.get('/', getAuditLogs);

module.exports = router;
