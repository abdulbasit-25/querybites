const jwt = require('jsonwebtoken');

const cookieOptions = {
	httpOnly: true,
	sameSite: 'lax',
	secure: process.env.COOKIE_SECURE === 'true',
	path: '/'
};

function issueAuthCookie(response, user) {
	const token = jwt.sign(
		{ sub: String(user.CustomerID), role: user.Role, name: user.FullName, email: user.Email },
		process.env.JWT_SECRET,
		{ expiresIn: '8h', issuer: 'foodbot-api', audience: 'foodbot-web' }
	);
	response.cookie('foodbot_token', token, { ...cookieOptions, maxAge: 8 * 60 * 60 * 1000 });
}

function clearAuthCookie(response) {
	response.clearCookie('foodbot_token', cookieOptions);
}

function authenticate(request, response, next) {
	const token = request.cookies?.foodbot_token;
	if (!token) return response.status(401).json({ error: 'Sign in is required.' });
	try {
		const claims = jwt.verify(token, process.env.JWT_SECRET, { issuer: 'foodbot-api', audience: 'foodbot-web' });
		request.user = { customerId: Number(claims.sub), role: claims.role, name: claims.name, email: claims.email };
		return next();
	} catch {
		clearAuthCookie(response);
		return response.status(401).json({ error: 'Your session has expired. Please sign in again.' });
	}
}

function requireRole(role) {
	return (request, response, next) => {
		if (!request.user || request.user.role !== role) return response.status(403).json({ error: 'You are not allowed to perform this action.' });
		return next();
	};
}

module.exports = { authenticate, requireRole, issueAuthCookie, clearAuthCookie };
