const express = require('express');
const bcrypt = require('bcryptjs');
const { getPool, sql } = require('../config/database');
const { authenticate, issueAuthCookie, clearAuthCookie } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const { validateRegistration } = require('../utils/validation');

const router = express.Router();

router.post('/register', asyncHandler(async (request, response) => {
	const userInput = validateRegistration(request.body);
	const passwordHash = await bcrypt.hash(userInput.password, 12);
	try {
		const pool = await getPool();
		const result = await pool.request()
			.input('FullName', sql.NVarChar(120), userInput.fullName)
			.input('Email', sql.NVarChar(254), userInput.email)
			.input('Phone', sql.NVarChar(30), userInput.phone)
			.input('PasswordHash', sql.NVarChar(255), passwordHash)
			.execute('dbo.usp_RegisterCustomer');
		const user = result.recordset[0];
		issueAuthCookie(response, user);
		response.status(201).json({ user });
	} catch (error) {
		if (error.number === 2627 || error.number === 2601) return response.status(409).json({ error: 'An account with that email already exists.' });
		throw error;
	}
}));

router.post('/login', asyncHandler(async (request, response) => {
	const email = typeof request.body?.email === 'string' ? request.body.email.trim().toLowerCase() : '';
	const password = typeof request.body?.password === 'string' ? request.body.password : '';
	if (!email || !password || email.length > 254 || password.length > 72) return response.status(400).json({ error: 'Enter your email and password.' });
	const pool = await getPool();
	const result = await pool.request()
		.input('Email', sql.NVarChar(254), email)
		.query('SELECT CustomerID, FullName, Email, Role, PasswordHash FROM dbo.Customers WHERE Email = @Email AND IsActive = 1');
	const user = result.recordset[0];
	if (!user || !(await bcrypt.compare(password, user.PasswordHash))) return response.status(401).json({ error: 'Email or password is incorrect.' });
	issueAuthCookie(response, user);
	response.json({ user: { CustomerID: user.CustomerID, FullName: user.FullName, Email: user.Email, Role: user.Role } });
}));

router.get('/me', authenticate, (request, response) => response.json({
	user: { CustomerID: request.user.customerId, FullName: request.user.name, Email: request.user.email, Role: request.user.role }
}));

router.post('/logout', (request, response) => {
	clearAuthCookie(response);
	response.status(204).end();
});

module.exports = router;
