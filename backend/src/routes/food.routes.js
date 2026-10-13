const express = require('express');
const { getPool, sql } = require('../config/database');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.get('/', asyncHandler(async (request, response) => {
	const search = typeof request.query.search === 'string' ? request.query.search.trim().slice(0, 140) : null;
	const category = typeof request.query.category === 'string' ? request.query.category.trim().slice(0, 80) : null;
	const restaurantId = request.query.restaurantId === undefined ? null : Number(request.query.restaurantId);
	const minPrice = request.query.minPrice === undefined ? null : Number(request.query.minPrice);
	const maxPrice = request.query.maxPrice === undefined ? null : Number(request.query.maxPrice);
	if (restaurantId !== null && (!Number.isSafeInteger(restaurantId) || restaurantId < 1)) return response.status(400).json({ error: 'Invalid restaurant ID.' });
	if ([minPrice, maxPrice].some((price) => price !== null && (!Number.isFinite(price) || price < 0))) return response.status(400).json({ error: 'Price filters must be non-negative numbers.' });
	if (minPrice !== null && maxPrice !== null && minPrice > maxPrice) return response.status(400).json({ error: 'Minimum price cannot exceed maximum price.' });
	const pool = await getPool();
	const result = await pool.request()
		.input('Search', sql.NVarChar(140), search || null)
		.input('Category', sql.NVarChar(80), category || null)
		.input('RestaurantID', sql.Int, restaurantId)
		.input('MinPrice', sql.Decimal(10, 2), minPrice)
		.input('MaxPrice', sql.Decimal(10, 2), maxPrice)
		.execute('dbo.usp_SearchFood');
	response.json({ items: result.recordset });
}));

module.exports = router;
