USE FoodBotDB;
GO

CREATE OR ALTER FUNCTION dbo.fn_MenuItems (@RestaurantID int)
RETURNS TABLE
AS
RETURN
(
	SELECT food.FoodItemID, food.Name, food.Description, food.Price, food.StockQuantity,
		   food.IsAvailable, category.Name AS CategoryName
	FROM dbo.FoodItems food
	JOIN dbo.FoodCategories category ON category.CategoryID = food.CategoryID
	WHERE food.RestaurantID = @RestaurantID AND food.IsAvailable = 1 AND food.StockQuantity > 0
);
GO

CREATE OR ALTER FUNCTION dbo.fn_CustomerOrderHistory (@CustomerID int)
RETURNS TABLE
AS
RETURN
(
	SELECT orders.OrderID, orders.RestaurantID, restaurant.Name AS RestaurantName,
		   orders.Status, orders.Subtotal, orders.DiscountAmount, orders.TaxAmount,
		   orders.DeliveryFee, orders.TotalAmount, orders.CreatedAtUtc
	FROM dbo.Orders orders
	JOIN dbo.Restaurants restaurant ON restaurant.RestaurantID = orders.RestaurantID
	WHERE orders.CustomerID = @CustomerID
);
GO

CREATE OR ALTER FUNCTION dbo.fn_DiscountAmount (@Subtotal decimal(10,2), @Percent decimal(5,2))
RETURNS decimal(10,2)
AS
BEGIN
	RETURN CONVERT(decimal(10,2), ROUND(@Subtotal * CASE WHEN @Percent BETWEEN 0 AND 100 THEN @Percent ELSE 0 END / 100, 2));
END;
GO
