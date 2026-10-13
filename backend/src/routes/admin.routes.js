const express = require('express');
const { getPool, sql } = require('../config/database');
const { authenticate, requireRole } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();
router.use(authenticate, requireRole('admin'));

router.get('/summary', asyncHandler(async (request, response) => {
	const pool = await getPool();
	const result = await pool.request().query(`
		SELECT (SELECT COUNT(*) FROM dbo.Orders WHERE Status NOT IN ('delivered', 'cancelled', 'payment_failed')) AS ActiveOrders,
					 (SELECT COUNT(*) FROM dbo.FoodItems WHERE StockQuantity <= 5 AND IsAvailable = 1) AS LowStockItems,
					 (SELECT COUNT(*) FROM dbo.Restaurants WHERE IsActive = 1) AS ActiveRestaurants;
		SELECT TOP (20) OrderID, CustomerID, RestaurantID, Status, TotalAmount, CreatedAtUtc
		FROM dbo.Orders ORDER BY CreatedAtUtc DESC;
	`);
	response.json({ metrics: result.recordsets[0][0], orders: result.recordsets[1] });
}));

router.post('/food', asyncHandler(async (request, response) => {
	const body = request.body || {};
	const foodItemId = body.foodItemId === undefined ? null : Number(body.foodItemId);
	const restaurantId = Number(body.restaurantId);
	const categoryId = Number(body.categoryId);
	const price = Number(body.price);
	const stockQuantity = Number(body.stockQuantity);
	const name = typeof body.name === 'string' ? body.name.trim() : '';
	if ((foodItemId !== null && (!Number.isSafeInteger(foodItemId) || foodItemId < 1)) || !Number.isSafeInteger(restaurantId) || restaurantId < 1 || !Number.isSafeInteger(categoryId) || categoryId < 1 || !name || name.length > 140 || !Number.isFinite(price) || price < 0 || !Number.isSafeInteger(stockQuantity) || stockQuantity < 0) {
		return response.status(400).json({ error: 'Food item fields are invalid.' });
	}
	const pool = await getPool();
	const result = await pool.request()
		.input('FoodItemID', sql.Int, foodItemId)
		.input('RestaurantID', sql.Int, restaurantId)
		.input('CategoryID', sql.Int, categoryId)
		.input('Name', sql.NVarChar(140), name)
		.input('Description', sql.NVarChar(500), typeof body.description === 'string' ? body.description.slice(0, 500) : null)
		.input('Price', sql.Decimal(10, 2), price)
		.input('StockQuantity', sql.Int, stockQuantity)
		.input('IsAvailable', sql.Bit, body.isAvailable !== false)
		.execute('dbo.usp_AdminUpsertFoodItem');
	response.status(foodItemId === null ? 201 : 200).json({ item: result.recordset[0] });
}));

router.patch('/orders/:orderId/status', asyncHandler(async (request, response) => {
	const orderId = Number(request.params.orderId);
	const status = typeof request.body?.status === 'string' ? request.body.status : '';
	if (!Number.isSafeInteger(orderId) || orderId < 1) return response.status(400).json({ error: 'Invalid order ID.' });
	const pool = await getPool();
	await pool.request()
		.input('OrderID', sql.Int, orderId)
		.input('Status', sql.VarChar(20), status)
		.execute('dbo.usp_UpdateOrderStatus');
	response.json({ orderId, status });
}));

router.post('/orders/:orderId/assign-rider', asyncHandler(async (request, response) => {
	const orderId = Number(request.params.orderId);
	if (!Number.isSafeInteger(orderId) || orderId < 1) return response.status(400).json({ error: 'Invalid order ID.' });
	const pool = await getPool();
	const result = await pool.request().input('OrderID', sql.Int, orderId).execute('dbo.usp_AssignAvailableRider');
	response.json({ assignment: result.recordset[0] });
}));

module.exports = router;
