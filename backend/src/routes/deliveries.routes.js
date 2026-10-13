const express = require('express');
const { getPool, sql } = require('../config/database');
const { authenticate } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();
router.use(authenticate);

router.get('/:orderId', asyncHandler(async (request, response) => {
	const orderId = Number(request.params.orderId);
	if (!Number.isSafeInteger(orderId) || orderId < 1) return response.status(400).json({ error: 'Invalid order ID.' });
	const pool = await getPool();
	const result = await pool.request()
		.input('CustomerID', sql.Int, request.user.customerId)
		.input('OrderID', sql.Int, orderId)
		.execute('dbo.usp_GetOrderStatus');
	if (!result.recordset.length) return response.status(404).json({ error: 'Delivery not found.' });
	response.json({ delivery: result.recordset[0] });
}));

module.exports = router;
