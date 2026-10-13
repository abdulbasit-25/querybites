function notFound(request, response) {
	response.status(404).json({ error: 'The requested resource was not found.' });
}

function errorHandler(error, request, response, next) {
	if (response.headersSent) return next(error);
	const status = Number.isInteger(error.status) ? error.status : 500;
	if (status >= 500) console.error('Request failed:', error.message);
	response.status(status).json({ error: status >= 500 ? 'The request could not be completed.' : error.message });
}

module.exports = { notFound, errorHandler };
