const express = require('express');
const { getPool, sql } = require('../config/database');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.post('/', asyncHandler(async (request, response) => {
	const message = typeof request.body?.message === 'string' ? request.body.message.trim() : '';
	if (!message || message.length > 1000) return response.status(400).json({ error: 'Message must contain 1 to 1000 characters.' });
	const pool = await getPool();
	const result = await pool.request()
		.input('Message', sql.NVarChar(1000), message)
		.input('CustomerID', sql.Int, null)
		.execute('dbo.usp_HandleChatMessage');
	response.json({ reply: result.recordset[0].Response, intent: result.recordset[0].Intent });
}));

module.exports = router;
