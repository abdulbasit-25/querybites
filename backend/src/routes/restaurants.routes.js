const express = require('express');
const { getPool, sql } = require('../config/database');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.get('/', asyncHandler(async (request, response) => {
	const search = typeof request.query.search === 'string' ? request.query.search.trim().slice(0, 120) : null;
	const pool = await getPool();
	const result = await pool.request()
		.input('Search', sql.NVarChar(120), search || null)
		.execute('dbo.usp_SearchRestaurants');
	response.json({ restaurants: result.recordset });
}));

router.get('/:restaurantId/menu', asyncHandler(async (request, response) => {
	const restaurantId = Number(request.params.restaurantId);
	if (!Number.isSafeInteger(restaurantId) || restaurantId < 1) return response.status(400).json({ error: 'Invalid restaurant ID.' });
	const pool = await getPool();
	const result = await pool.request()
		.input('RestaurantID', sql.Int, restaurantId)
		.execute('dbo.usp_GetRestaurantMenu');
	response.json({ items: result.recordset });
}));

module.exports = router;
