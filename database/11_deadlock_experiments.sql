USE FoodBotDB;
GO

IF OBJECT_ID(N'dbo.DeadlockProbe', N'U') IS NULL
	CREATE TABLE dbo.DeadlockProbe (ProbeID int NOT NULL PRIMARY KEY, ProbeValue int NOT NULL);
IF NOT EXISTS (SELECT 1 FROM dbo.DeadlockProbe WHERE ProbeID IN (1, 2) GROUP BY ProbeID HAVING COUNT(*) = 2)
BEGIN
	MERGE dbo.DeadlockProbe AS target
	USING (VALUES (1, 10), (2, 20)) AS source(ProbeID, ProbeValue)
	ON target.ProbeID = source.ProbeID
	WHEN NOT MATCHED THEN INSERT (ProbeID, ProbeValue) VALUES (source.ProbeID, source.ProbeValue);
END;
GO

/* In two SSMS windows, execute the first block in each, then the second block in each. */
-- Session A, first: BEGIN TRANSACTION; UPDATE dbo.DeadlockProbe SET ProbeValue = ProbeValue + 1 WHERE ProbeID = 1;
-- Session B, first: BEGIN TRANSACTION; UPDATE dbo.DeadlockProbe SET ProbeValue = ProbeValue + 1 WHERE ProbeID = 2;
-- Session A, second: UPDATE dbo.DeadlockProbe SET ProbeValue = ProbeValue + 1 WHERE ProbeID = 2; COMMIT;
-- Session B, second: UPDATE dbo.DeadlockProbe SET ProbeValue = ProbeValue + 1 WHERE ProbeID = 1; COMMIT;
-- SQL Server detects the wait-for cycle and rolls one transaction back with error 1205.
-- Victim choice considers deadlock priority and rollback cost; it is not fixed by session name.
-- Observe the graph in the deadlock XML / Extended Events system_health session.
-- Retry only idempotent work, with a small bounded retry count and jitter in application code.
-- Prevent by accessing keys in the same order in every transaction; keep transactions short.
-- Cleanup after all sessions finish: UPDATE dbo.DeadlockProbe SET ProbeValue = CASE ProbeID WHEN 1 THEN 10 ELSE 20 END;
