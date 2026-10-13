USE FoodBotDB;
GO

/* Simulated failure: usp_PlaceOrder @PaymentSucceeds = 0 records a failed payment and does
	not decrement stock or create a delivery. The stored procedure uses a transaction and
	structured TRY/CATCH rollback for actual SQL errors. */

/* Explicit rollback using a disposable probe row. */
BEGIN TRANSACTION;
UPDATE dbo.ConcurrencyProbe SET ProbeValue = -1 WHERE ProbeID = 1;
SELECT ProbeValue AS UncommittedValue FROM dbo.ConcurrencyProbe WHERE ProbeID = 1;
ROLLBACK TRANSACTION;
SELECT ProbeValue AS RestoredValue FROM dbo.ConcurrencyProbe WHERE ProbeID = 1;
GO

/* Backup / restore are real SQL Server operations, not simulated by this script.
	In SSMS, obtain the configured SQL Server backup directory from the instance administrator
	or SERVERPROPERTY('InstanceDefaultBackupPath') where supported. SQL Server service identity
	must have write permission to that server-side directory. Do not assume a client PC path. */
-- BACKUP DATABASE FoodBotDB TO DISK = N'<server-accessible-folder>\FoodBotDB.bak' WITH INIT, CHECKSUM;
-- RESTORE VERIFYONLY FROM DISK = N'<server-accessible-folder>\FoodBotDB.bak' WITH CHECKSUM;
-- Restore only to a disposable database and inspect logical file names first with RESTORE FILELISTONLY.
-- A restore over an existing database is intentionally not included here.
