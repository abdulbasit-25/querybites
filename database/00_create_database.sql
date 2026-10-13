IF DB_ID(N'FoodBotDB') IS NULL
BEGIN
	CREATE DATABASE FoodBotDB;
END;
GO

USE FoodBotDB;
GO

PRINT N'FoodBotDB is ready. Run the remaining scripts in numeric order.';
GO
