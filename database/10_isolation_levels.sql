USE FoodBotDB;
GO

/* Run the A/B schedules in 09_concurrency_experiments.sql for dirty reads and blocking. */
/* Non-repeatable read: A uses READ COMMITTED, reads ProbeValue, pauses; B updates and commits;
	A reads again and gets a different value. Under REPEATABLE READ A's shared lock prevents B. */
/* Phantom: A runs the same range SELECT twice under REPEATABLE READ; B inserts a matching row.
	A may see a phantom. SERIALIZABLE uses range locks to prevent it. */

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT ProbeID, ProbeValue FROM dbo.ConcurrencyProbe WHERE ProbeID BETWEEN 1 AND 10;
GO

/* SNAPSHOT is an opt-in database setting. Inspect before changing anything. */
SELECT name, snapshot_isolation_state_desc, is_read_committed_snapshot_on
FROM sys.databases WHERE name = DB_NAME();
GO

/* In a disposable local FoodBotDB only, an administrator may enable this separately:
	ALTER DATABASE FoodBotDB SET ALLOW_SNAPSHOT_ISOLATION ON;
	Then in a test session: SET TRANSACTION ISOLATION LEVEL SNAPSHOT; BEGIN TRANSACTION;
	SELECT ProbeValue FROM dbo.ConcurrencyProbe WHERE ProbeID = 1; COMMIT;
	Do not run ALTER DATABASE against a shared/production database. */

/* Isolation summary:
	READ UNCOMMITTED: dirty, non-repeatable, and phantom reads possible.
	READ COMMITTED: no dirty reads; non-repeatable and phantom reads possible.
	REPEATABLE READ: rows read remain locked; phantoms may occur.
	SERIALIZABLE: range locks prevent phantoms; least concurrency.
	SNAPSHOT: transaction-level row-versioned consistent view; update conflicts can occur. */
