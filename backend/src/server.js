require('dotenv').config({ path: require('node:path').resolve(__dirname, '../.env') });

if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
	throw new Error('JWT_SECRET must be configured with at least 32 characters.');
}

const app = require('./app');
const { closePool } = require('./config/database');

const port = Number(process.env.PORT || 3000);
const server = app.listen(port, () => console.log(`FoodBot is available at http://localhost:${port}`));

let shuttingDown = false;
async function shutdown(signal) {
	if (shuttingDown) return;
	shuttingDown = true;
	console.log(`${signal} received; closing FoodBot.`);
	server.close(async () => {
		await closePool();
		process.exit(0);
	});
	setTimeout(() => process.exit(1), 10000).unref();
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
