USE FoodBotDB;
GO

CREATE OR ALTER VIEW dbo.vw_OrderSummary
AS
SELECT orders.OrderID, orders.CustomerID, customer.FullName AS CustomerName,
	   orders.RestaurantID, restaurant.Name AS RestaurantName, orders.Status,
	   orders.Subtotal, orders.DiscountAmount, orders.TaxAmount, orders.DeliveryFee,
	   orders.TotalAmount, orders.CreatedAtUtc,
	   payment.Status AS PaymentStatus, delivery.Status AS DeliveryStatus,
	   delivery.RiderID
FROM dbo.Orders orders
JOIN dbo.Customers customer ON customer.CustomerID = orders.CustomerID
JOIN dbo.Restaurants restaurant ON restaurant.RestaurantID = orders.RestaurantID
LEFT JOIN dbo.Payments payment ON payment.OrderID = orders.OrderID
LEFT JOIN dbo.Deliveries delivery ON delivery.OrderID = orders.OrderID;
GO

CREATE OR ALTER VIEW dbo.vw_RestaurantSales
AS
SELECT restaurant.RestaurantID, restaurant.Name AS RestaurantName,
	   COUNT(orders.OrderID) AS SuccessfulOrderCount,
	   CONVERT(decimal(12,2), COALESCE(SUM(CASE WHEN payment.Status = 'succeeded' THEN orders.TotalAmount ELSE 0 END), 0)) AS GrossSales
FROM dbo.Restaurants restaurant
LEFT JOIN dbo.Orders orders ON orders.RestaurantID = restaurant.RestaurantID
LEFT JOIN dbo.Payments payment ON payment.OrderID = orders.OrderID
GROUP BY restaurant.RestaurantID, restaurant.Name;
GO

CREATE OR ALTER VIEW dbo.vw_PopularFoodItems
AS
SELECT food.FoodItemID, food.Name AS FoodName, restaurant.Name AS RestaurantName,
	   COALESCE(SUM(CASE WHEN payment.Status = 'succeeded' THEN detail.Quantity ELSE 0 END), 0) AS UnitsSold
FROM dbo.FoodItems food
JOIN dbo.Restaurants restaurant ON restaurant.RestaurantID = food.RestaurantID
LEFT JOIN dbo.OrderDetails detail ON detail.FoodItemID = food.FoodItemID
LEFT JOIN dbo.Orders orders ON orders.OrderID = detail.OrderID
LEFT JOIN dbo.Payments payment ON payment.OrderID = orders.OrderID
GROUP BY food.FoodItemID, food.Name, restaurant.Name;
GO

CREATE OR ALTER VIEW dbo.vw_DeliveryStatus
AS
SELECT delivery.DeliveryID, delivery.OrderID, orders.CustomerID,
	   delivery.Status, rider.FullName AS RiderName, rider.Phone AS RiderPhone,
	   delivery.AssignedAtUtc, delivery.DeliveredAtUtc
FROM dbo.Deliveries delivery
JOIN dbo.Orders orders ON orders.OrderID = delivery.OrderID
LEFT JOIN dbo.Riders rider ON rider.RiderID = delivery.RiderID;
GO
