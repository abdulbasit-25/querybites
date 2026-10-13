const express = require('express');
const { randomUUID } = require('node:crypto');
const { getPool, sql } = require('../config/database');
const { authenticate } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const { validateOrder } = require('../utils/validation');

const router = express.Router();
router.use(authenticate);

router.get('/', asyncHandler(async (request, response) => {
	const pool = await getPool();
	const result = await pool.request()
		.input('CustomerID', sql.Int, request.user.customerId)
		.execute('dbo.usp_GetCustomerOrders');
	response.json({ orders: result.recordset });
}));

router.post('/', asyncHandler(async (request, response) => {
	const order = validateOrder(request.body);
	const idempotencyKey = request.get('Idempotency-Key') || randomUUID();
	if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(idempotencyKey)) return response.status(400).json({ error: 'Invalid idempotency key.' });
	const table = new sql.Table('dbo.OrderItemInput');
	table.columns.add('FoodItemID', sql.Int, { nullable: false });
	table.columns.add('Quantity', sql.Int, { nullable: false });
	for (const item of order.items) table.rows.add(item.foodItemId, item.quantity);
	const pool = await getPool();
	const result = await pool.request()
		.input('CustomerID', sql.Int, request.user.customerId)
		.input('RestaurantID', sql.Int, order.restaurantId)
		.input('Items', table)
		.input('DeliveryAddress', sql.NVarChar(300), order.deliveryAddress)
		.input('IdempotencyKey', sql.UniqueIdentifier, idempotencyKey)
		.input('PaymentSucceeds', sql.Bit, request.body?.simulatePaymentFailure !== true)
		.execute('dbo.usp_PlaceOrder');
	const orderResult = result.recordset[0];
	response.status(orderResult.WasDuplicate ? 200 : 201).json({ order: orderResult });
}));

router.get('/:orderId', asyncHandler(async (request, response) => {
	const orderId = Number(request.params.orderId);
	if (!Number.isSafeInteger(orderId) || orderId < 1) return response.status(400).json({ error: 'Invalid order ID.' });
	const pool = await getPool();
	const result = await pool.request()
		.input('CustomerID', sql.Int, request.user.customerId)
		.input('OrderID', sql.Int, orderId)
		.execute('dbo.usp_GetOrderStatus');
	if (!result.recordset.length) return response.status(404).json({ error: 'Order not found.' });
	response.json({ order: result.recordset[0] });
}));

router.post('/:orderId/cancel', asyncHandler(async (request, response) => {
	const orderId = Number(request.params.orderId);
	if (!Number.isSafeInteger(orderId) || orderId < 1) return response.status(400).json({ error: 'Invalid order ID.' });
	const pool = await getPool();
	const result = await pool.request()
		.input('CustomerID', sql.Int, request.user.customerId)
		.input('OrderID', sql.Int, orderId)
		.execute('dbo.usp_CancelOrder');
	response.json({ order: result.recordset[0] });
}));

module.exports = router;
