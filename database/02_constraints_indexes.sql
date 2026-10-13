USE FoodBotDB;
GO

CREATE INDEX IX_FoodItems_Restaurant_Availability ON dbo.FoodItems(RestaurantID, IsAvailable, Name) INCLUDE (CategoryID, Price, StockQuantity);
CREATE INDEX IX_FoodItems_Category_Price ON dbo.FoodItems(CategoryID, Price) INCLUDE (RestaurantID, Name, IsAvailable);
CREATE INDEX IX_Orders_Customer_Created ON dbo.Orders(CustomerID, CreatedAtUtc DESC) INCLUDE (Status, TotalAmount);
CREATE INDEX IX_Orders_Restaurant_Created ON dbo.Orders(RestaurantID, CreatedAtUtc DESC) INCLUDE (Status, TotalAmount);
CREATE INDEX IX_OrderDetails_Order ON dbo.OrderDetails(OrderID) INCLUDE (FoodItemID, Quantity, UnitPrice);
CREATE INDEX IX_Deliveries_Status ON dbo.Deliveries(Status, RiderID);
CREATE INDEX IX_ChatKeywords_Keyword ON dbo.ChatKeywords(Keyword) INCLUDE (IntentID);
GO

IF TYPE_ID(N'dbo.OrderItemInput') IS NULL
	EXEC(N'CREATE TYPE dbo.OrderItemInput AS TABLE (FoodItemID int NOT NULL PRIMARY KEY, Quantity int NOT NULL CHECK (Quantity > 0));');
GO
