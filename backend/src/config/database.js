const sql = process.env.DB_TRUSTED_CONNECTION === 'true'
	? require('mssql/msnodesqlv8')
	: require('mssql');

let poolPromise;

function getPool() {
	if (!poolPromise) {
		const trusted = process.env.DB_TRUSTED_CONNECTION === 'true';
		const config = trusted
			? {
					driver: 'msnodesqlv8',
					connectionString: [
						'Driver={ODBC Driver 18 for SQL Server}',
						`Server=${process.env.DB_SERVER || 'localhost'}`,
						`Database=${process.env.DB_DATABASE || 'FoodBotDB'}`,
						'Trusted_Connection=yes',
						`Encrypt=${process.env.DB_ENCRYPT || 'yes'}`,
						`TrustServerCertificate=${process.env.DB_TRUST_SERVER_CERTIFICATE || 'yes'}`
					].join(';')
				}
			: {
					server: process.env.DB_SERVER || 'localhost',
					database: process.env.DB_DATABASE || 'FoodBotDB',
					user: process.env.DB_USER,
					password: process.env.DB_PASSWORD,
					port: process.env.DB_PORT ? Number(process.env.DB_PORT) : undefined,
					options: {
						encrypt: process.env.DB_ENCRYPT !== 'false',
						trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true'
					},
					pool: { max: 10, min: 0, idleTimeoutMillis: 30000 },
					requestTimeout: 15000,
					connectionTimeout: 10000
				};
		poolPromise = sql.connect(config).catch((error) => {
			poolPromise = undefined;
			throw error;
		});
	}
	return poolPromise;
}

async function closePool() {
	if (poolPromise) {
		const pool = await poolPromise.catch(() => null);
		poolPromise = undefined;
		if (pool) await pool.close();
	}
}

module.exports = { sql, getPool, closePool };
