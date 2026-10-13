const path = require('node:path');
const express = require('express');
const cookieParser = require('cookie-parser');
const cors = require('cors');
const helmet = require('helmet');
const { rateLimit } = require('express-rate-limit');
const authRoutes = require('./routes/auth.routes');
const restaurantRoutes = require('./routes/restaurants.routes');
const foodRoutes = require('./routes/food.routes');
const orderRoutes = require('./routes/orders.routes');
const deliveryRoutes = require('./routes/deliveries.routes');
const chatRoutes = require('./routes/chat.routes');
const adminRoutes = require('./routes/admin.routes');
const { notFound, errorHandler } = require('./middleware/errorHandler');

const app = express();
const allowedOrigins = new Set((process.env.FRONTEND_ORIGIN || 'http://localhost:3000,http://127.0.0.1:3000,http://localhost:5500,http://127.0.0.1:5500')
	.split(',').map((origin) => origin.trim()).filter(Boolean));

app.disable('x-powered-by');
app.use(helmet({ crossOriginResourcePolicy: { policy: 'same-site' } }));
app.use(cors({ origin(origin, callback) {
	if (!origin || allowedOrigins.has(origin)) return callback(null, true);
	return callback(Object.assign(new Error('Origin is not allowed.'), { status: 403 }));
}, credentials: true }));
app.use((request, response, next) => {
	if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(request.method) && request.get('Origin') && !allowedOrigins.has(request.get('Origin'))) {
		return response.status(403).json({ error: 'Origin is not allowed.' });
	}
	next();
});
app.use(express.json({ limit: '32kb' }));
app.use(cookieParser());

const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 20, standardHeaders: 'draft-7', legacyHeaders: false });
const chatLimiter = rateLimit({ windowMs: 60 * 1000, limit: 20, standardHeaders: 'draft-7', legacyHeaders: false });
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/restaurants', restaurantRoutes);
app.use('/api/food', foodRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/deliveries', deliveryRoutes);
app.use('/api/chat', chatLimiter, chatRoutes);
app.use('/api/admin', adminRoutes);
app.get('/api/health', (request, response) => response.json({ status: 'ok' }));
app.use(express.static(path.resolve(__dirname, '../../frontend')));
app.use(notFound);
app.use(errorHandler);

module.exports = app;
