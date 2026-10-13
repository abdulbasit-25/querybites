USE FoodBotDB;
GO

SELECT 'Customers' AS EntityName, COUNT(*) AS RowCount FROM dbo.Customers
UNION ALL SELECT 'Restaurants', COUNT(*) FROM dbo.Restaurants
UNION ALL SELECT 'FoodCategories', COUNT(*) FROM dbo.FoodCategories
UNION ALL SELECT 'FoodItems', COUNT(*) FROM dbo.FoodItems
UNION ALL SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL SELECT 'OrderDetails', COUNT(*) FROM dbo.OrderDetails
UNION ALL SELECT 'Payments', COUNT(*) FROM dbo.Payments
UNION ALL SELECT 'Riders', COUNT(*) FROM dbo.Riders
UNION ALL SELECT 'Deliveries', COUNT(*) FROM dbo.Deliveries
UNION ALL SELECT 'ChatIntents', COUNT(*) FROM dbo.ChatIntents;
GO

SELECT food.FoodItemID, food.Name, food.StockQuantity
FROM dbo.FoodItems food WHERE food.StockQuantity < 0;

SELECT orders.OrderID, orders.TotalAmount, payment.Amount AS PaymentAmount
FROM dbo.Orders orders
JOIN dbo.Payments payment ON payment.OrderID = orders.OrderID
WHERE orders.TotalAmount <> payment.Amount;

SELECT detail.OrderID, detail.FoodItemID
FROM dbo.OrderDetails detail
LEFT JOIN dbo.Orders orders ON orders.OrderID = detail.OrderID
LEFT JOIN dbo.FoodItems food ON food.FoodItemID = detail.FoodItemID
WHERE orders.OrderID IS NULL OR food.FoodItemID IS NULL;
GO
