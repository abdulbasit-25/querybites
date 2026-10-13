USE FoodBotDB;
GO

IF OBJECT_ID(N'dbo.ConcurrencyProbe', N'U') IS NULL
	CREATE TABLE dbo.ConcurrencyProbe (ProbeID int NOT NULL PRIMARY KEY, ProbeValue int NOT NULL);
IF NOT EXISTS (SELECT 1 FROM dbo.ConcurrencyProbe WHERE ProbeID = 1)
	INSERT dbo.ConcurrencyProbe VALUES (1, 100);
GO

/* Lost update (two SSMS windows). Run setup once. A: */
-- BEGIN TRANSACTION; SELECT ProbeValue FROM dbo.ConcurrencyProbe WHERE ProbeID = 1;
-- B: BEGIN TRANSACTION; SELECT ProbeValue FROM dbo.ConcurrencyProbe WHERE ProbeID = 1;
-- A: UPDATE dbo.ConcurrencyProbe SET ProbeValue = 110 WHERE ProbeID = 1; COMMIT;
-- B: UPDATE dbo.ConcurrencyProbe SET ProbeValue = 120 WHERE ProbeID = 1; COMMIT;
-- The final value is 120, losing A's increment. Use atomic SET ProbeValue = ProbeValue + @delta.

/* Dirty read: A holds an uncommitted update; run B while A is paused. */
-- A: BEGIN TRANSACTION; UPDATE dbo.ConcurrencyProbe SET ProbeValue = 999 WHERE ProbeID = 1;
-- B: SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT ProbeValue FROM dbo.ConcurrencyProbe WHERE ProbeID = 1;
-- A: ROLLBACK; B can observe 999 even though it never commits.

/* Blocking / shared and exclusive locks. */
-- A: BEGIN TRANSACTION; SELECT ProbeValue FROM dbo.ConcurrencyProbe WITH (HOLDLOCK) WHERE ProbeID = 1;
-- B: UPDATE dbo.ConcurrencyProbe SET ProbeValue = ProbeValue + 1 WHERE ProbeID = 1; -- blocks until A commits.
-- A: COMMIT; observe B finish. Shared readers and exclusive writers are coordinated by SQL Server locks.

/* Restore the probe after manual schedules. */
-- UPDATE dbo.ConcurrencyProbe SET ProbeValue = 100 WHERE ProbeID = 1;
