USE FoodBotDB;
GO

-- Savepoints are useful for optional work; they do not replace validating the full order.
SET XACT_ABORT OFF;
BEGIN TRY
	BEGIN TRANSACTION;
	DECLARE @ProbeCustomerID int;
	SELECT TOP (1) @ProbeCustomerID = CustomerID FROM dbo.Customers ORDER BY CustomerID;
	SAVE TRANSACTION BeforeOptionalUpdate;
	UPDATE dbo.Customers SET Phone = Phone WHERE CustomerID = @ProbeCustomerID;
	ROLLBACK TRANSACTION BeforeOptionalUpdate;
	COMMIT TRANSACTION;
	PRINT N'Outer transaction committed; work after the savepoint was rolled back.';
END TRY
BEGIN CATCH
	IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
	THROW;
END CATCH;
GO

-- Safe transaction-state inspection pattern for procedure authors.
BEGIN TRY
	BEGIN TRANSACTION;
	DECLARE @ExampleValue int = 1;
	IF @ExampleValue <> 1 THROW 50030, 'Example validation failed.', 1;
	COMMIT TRANSACTION;
END TRY
BEGIN CATCH
	IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
	SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO
