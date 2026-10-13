USE FoodBotDB;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RegisterCustomer
	@FullName nvarchar(120), @Email nvarchar(254), @Phone nvarchar(30) = NULL,
	@PasswordHash nvarchar(255)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT dbo.Customers (FullName, Email, Phone, PasswordHash)
	VALUES (TRIM(@FullName), LOWER(TRIM(@Email)), @Phone, @PasswordHash);
	SELECT CustomerID, FullName, Email, Role FROM dbo.Customers WHERE CustomerID = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_SearchRestaurants @Search nvarchar(120) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SELECT RestaurantID, Name, Description, Address, Phone
	FROM dbo.Restaurants
	WHERE IsActive = 1 AND (@Search IS NULL OR Name LIKE N'%' + TRIM(@Search) + N'%')
	ORDER BY Name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_SearchFood
	@Search nvarchar(140) = NULL, @Category nvarchar(80) = NULL,
	@RestaurantID int = NULL, @MinPrice decimal(10,2) = NULL, @MaxPrice decimal(10,2) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SELECT food.FoodItemID, food.RestaurantID, restaurant.Name AS RestaurantName,
		   food.Name, food.Description, category.Name AS CategoryName,
		   food.Price, food.StockQuantity, food.IsAvailable
	FROM dbo.FoodItems food
	JOIN dbo.Restaurants restaurant ON restaurant.RestaurantID = food.RestaurantID
	JOIN dbo.FoodCategories category ON category.CategoryID = food.CategoryID
	WHERE restaurant.IsActive = 1
	  AND (@Search IS NULL OR food.Name LIKE N'%' + TRIM(@Search) + N'%')
	  AND (@Category IS NULL OR category.Name = @Category)
	  AND (@RestaurantID IS NULL OR food.RestaurantID = @RestaurantID)
	  AND (@MinPrice IS NULL OR food.Price >= @MinPrice)
	  AND (@MaxPrice IS NULL OR food.Price <= @MaxPrice)
	  AND food.IsAvailable = 1
	ORDER BY restaurant.Name, food.Name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetRestaurantMenu @RestaurantID int
AS
BEGIN
	SET NOCOUNT ON;
	SELECT * FROM dbo.fn_MenuItems(@RestaurantID) ORDER BY CategoryName, Name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetCustomerOrders @CustomerID int
AS
BEGIN
	SET NOCOUNT ON;
	SELECT history.*, payment.Status AS PaymentStatus, delivery.Status AS DeliveryStatus
	FROM dbo.fn_CustomerOrderHistory(@CustomerID) history
	LEFT JOIN dbo.Payments payment ON payment.OrderID = history.OrderID
	LEFT JOIN dbo.Deliveries delivery ON delivery.OrderID = history.OrderID
	ORDER BY history.CreatedAtUtc DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetOrderStatus @CustomerID int, @OrderID int
AS
BEGIN
	SET NOCOUNT ON;
	SELECT OrderID, Status, PaymentStatus, DeliveryStatus, RiderName, RiderPhone, CreatedAtUtc
	FROM dbo.vw_OrderSummary
	WHERE OrderID = @OrderID AND CustomerID = @CustomerID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_PlaceOrder
	@CustomerID int, @RestaurantID int, @Items dbo.OrderItemInput READONLY,
	@DeliveryAddress nvarchar(300), @IdempotencyKey uniqueidentifier = NULL,
	@PaymentSucceeds bit = 1
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	IF NOT EXISTS (SELECT 1 FROM @Items) THROW 50001, 'The cart must contain at least one item.', 1;
	IF EXISTS (SELECT 1 FROM @Items WHERE Quantity <= 0) THROW 50002, 'Quantities must be positive.', 1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerID = @CustomerID AND IsActive = 1)
		THROW 50003, 'Customer account is unavailable.', 1;

	DECLARE @OrderID int, @Subtotal decimal(10,2), @Total decimal(10,2);
	DECLARE @PricedItems TABLE (FoodItemID int PRIMARY KEY, Quantity int NOT NULL, UnitPrice decimal(10,2) NOT NULL);

	BEGIN TRY
		BEGIN TRANSACTION;

		IF @IdempotencyKey IS NOT NULL
		BEGIN
			SELECT @OrderID = OrderID
			FROM dbo.Orders WITH (UPDLOCK, HOLDLOCK)
			WHERE CustomerID = @CustomerID AND IdempotencyKey = @IdempotencyKey;
			IF @OrderID IS NOT NULL
			BEGIN
				COMMIT TRANSACTION;
				SELECT @OrderID AS OrderID, CONVERT(bit, 1) AS WasDuplicate;
				RETURN;
			END;
		END;

		INSERT @PricedItems (FoodItemID, Quantity, UnitPrice)
		SELECT food.FoodItemID, requested.Quantity, food.Price
		FROM dbo.FoodItems food WITH (UPDLOCK, HOLDLOCK)
		JOIN @Items requested ON requested.FoodItemID = food.FoodItemID
		WHERE food.RestaurantID = @RestaurantID
		  AND food.IsAvailable = 1
		  AND food.StockQuantity >= requested.Quantity;

		IF (SELECT COUNT(*) FROM @PricedItems) <> (SELECT COUNT(*) FROM @Items)
			THROW 50004, 'One or more items are unavailable, out of stock, or from another restaurant.', 1;

		SELECT @Subtotal = SUM(Quantity * UnitPrice) FROM @PricedItems;

		INSERT dbo.Orders (CustomerID, RestaurantID, Status, Subtotal, TaxAmount, DeliveryFee, IdempotencyKey)
		VALUES (@CustomerID, @RestaurantID, CASE WHEN @PaymentSucceeds = 1 THEN 'confirmed' ELSE 'payment_failed' END,
				@Subtotal, ROUND(@Subtotal * 0.05, 2), 100.00, @IdempotencyKey);
		SET @OrderID = CONVERT(int, SCOPE_IDENTITY());

		INSERT dbo.OrderDetails (OrderID, FoodItemID, Quantity, UnitPrice)
		SELECT @OrderID, FoodItemID, Quantity, UnitPrice FROM @PricedItems;

		SELECT @Total = TotalAmount FROM dbo.Orders WHERE OrderID = @OrderID;
		INSERT dbo.Payments (OrderID, Amount, Status)
		VALUES (@OrderID, @Total, CASE WHEN @PaymentSucceeds = 1 THEN 'succeeded' ELSE 'failed' END);

		IF @PaymentSucceeds = 1
		BEGIN
			UPDATE food
			SET StockQuantity = food.StockQuantity - item.Quantity
			FROM dbo.FoodItems food
			JOIN @PricedItems item ON item.FoodItemID = food.FoodItemID;

			INSERT dbo.Deliveries (OrderID, DeliveryAddress)
			VALUES (@OrderID, TRIM(@DeliveryAddress));
		END;

		COMMIT TRANSACTION;
		SELECT @OrderID AS OrderID, CONVERT(bit, 0) AS WasDuplicate;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CancelOrder @CustomerID int, @OrderID int
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
		IF NOT EXISTS (
			SELECT 1 FROM dbo.Orders WITH (UPDLOCK, HOLDLOCK)
			WHERE OrderID = @OrderID AND CustomerID = @CustomerID AND Status IN ('pending', 'confirmed')
		) THROW 50005, 'Order was not found or can no longer be cancelled.', 1;

		UPDATE food
		SET StockQuantity = food.StockQuantity + detail.Quantity
		FROM dbo.FoodItems food
		JOIN dbo.OrderDetails detail ON detail.FoodItemID = food.FoodItemID
		WHERE detail.OrderID = @OrderID
		  AND EXISTS (SELECT 1 FROM dbo.Payments WHERE OrderID = @OrderID AND Status = 'succeeded');

		UPDATE dbo.Orders SET Status = 'cancelled', UpdatedAtUtc = SYSUTCDATETIME() WHERE OrderID = @OrderID;
		UPDATE dbo.Payments SET Status = 'refunded' WHERE OrderID = @OrderID AND Status = 'succeeded';
		UPDATE dbo.Deliveries SET Status = 'cancelled' WHERE OrderID = @OrderID;
		COMMIT TRANSACTION;
		SELECT @OrderID AS OrderID, 'cancelled' AS Status;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AssignAvailableRider @OrderID int
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	DECLARE @RiderID int;
	BEGIN TRY
		BEGIN TRANSACTION;
		SELECT TOP (1) @RiderID = RiderID
		FROM dbo.Riders WITH (UPDLOCK, READPAST, ROWLOCK)
		WHERE IsAvailable = 1 AND IsActive = 1
		ORDER BY RiderID;
		IF @RiderID IS NULL THROW 50006, 'No available rider was found.', 1;
		UPDATE dbo.Riders SET IsAvailable = 0 WHERE RiderID = @RiderID;
		UPDATE dbo.Deliveries
		SET RiderID = @RiderID, Status = 'assigned', AssignedAtUtc = SYSUTCDATETIME()
		WHERE OrderID = @OrderID AND Status = 'queued';
		IF @@ROWCOUNT = 0 THROW 50007, 'Delivery was not found or already assigned.', 1;
		COMMIT TRANSACTION;
		SELECT @OrderID AS OrderID, @RiderID AS RiderID;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_UpdateOrderStatus @OrderID int, @Status varchar(20)
AS
BEGIN
	SET NOCOUNT ON;
	IF NOT EXISTS (
		SELECT 1 FROM dbo.Orders
		WHERE OrderID = @OrderID AND
		  ((Status = 'confirmed' AND @Status = 'preparing') OR
		   (Status = 'preparing' AND @Status = 'ready') OR
		   (Status = 'ready' AND @Status = 'out_for_delivery') OR
		   (Status = 'out_for_delivery' AND @Status = 'delivered'))
	) THROW 50008, 'Invalid order status transition.', 1;
	UPDATE dbo.Orders SET Status = @Status, UpdatedAtUtc = SYSUTCDATETIME() WHERE OrderID = @OrderID;
	IF @Status = 'out_for_delivery' UPDATE dbo.Deliveries SET Status = 'picked_up' WHERE OrderID = @OrderID;
	IF @Status = 'delivered'
	BEGIN
		UPDATE dbo.Deliveries SET Status = 'delivered', DeliveredAtUtc = SYSUTCDATETIME() WHERE OrderID = @OrderID;
		UPDATE dbo.Riders SET IsAvailable = 1 WHERE RiderID = (SELECT RiderID FROM dbo.Deliveries WHERE OrderID = @OrderID);
	END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_HandleChatMessage @Message nvarchar(1000), @CustomerID int = NULL
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Normalized nvarchar(1000) = LOWER(TRIM(COALESCE(@Message, N'')));
	DECLARE @IntentName varchar(60), @Response nvarchar(2000);
	IF LEN(@Normalized) = 0 THROW 50009, 'Message cannot be empty.', 1;

	SELECT TOP (1) @IntentName = intent.IntentName, @Response = intent.ResponseTemplate
	FROM dbo.ChatKeywords keyword
	JOIN dbo.ChatIntents intent ON intent.IntentID = keyword.IntentID
	WHERE intent.IsActive = 1 AND CHARINDEX(LOWER(keyword.Keyword), @Normalized) > 0
	ORDER BY LEN(keyword.Keyword) DESC;

	IF @IntentName = 'restaurants'
	BEGIN
		SELECT @Response = CONCAT(@Response, N' ', COALESCE(STRING_AGG(Name, N', '), N'No restaurants are currently available.'))
		FROM (SELECT TOP (8) Name FROM dbo.Restaurants WHERE IsActive = 1 ORDER BY Name) available;
	END;
	ELSE IF @IntentName = 'food_search'
	BEGIN
		DECLARE @Term nvarchar(140) = NULL, @MaxPrice decimal(10,2) = NULL;
		SELECT TOP (1) @Term = Name FROM dbo.FoodItems
		WHERE IsAvailable = 1 AND CHARINDEX(LOWER(Name), @Normalized) > 0 ORDER BY LEN(Name) DESC;
		IF @Normalized LIKE N'%under%'
			SET @MaxPrice = TRY_CONVERT(decimal(10,2), NULLIF(SUBSTRING(@Normalized, CHARINDEX(N'under', @Normalized) + 5, 30), N''));
		IF @Term IS NOT NULL OR @MaxPrice IS NOT NULL
		BEGIN
			DECLARE @Matches nvarchar(1200);
			SELECT @Matches = STRING_AGG(CONVERT(nvarchar(max), CONCAT(Name, N' (Rs. ', Price, N')')), N'; ')
			FROM (SELECT TOP (5) Name, Price FROM dbo.FoodItems
				  WHERE IsAvailable = 1 AND StockQuantity > 0
					AND (@Term IS NULL OR Name LIKE N'%' + @Term + N'%')
					AND (@MaxPrice IS NULL OR Price <= @MaxPrice)
				  ORDER BY Name) matches;
			SET @Response = CONCAT(@Response, N' ', COALESCE(@Matches, N'No available dishes matched that search.'));
		END;
	END;

	IF @IntentName IS NULL
	BEGIN
		SET @IntentName = 'help';
		SELECT @Response = ResponseTemplate FROM dbo.ChatIntents WHERE IntentName = 'help';
	END;

	INSERT dbo.ChatHistory (CustomerID, UserMessage, MatchedIntent, BotResponse)
	VALUES (@CustomerID, LEFT(@Message, 1000), @IntentName, @Response);
	SELECT @IntentName AS Intent, @Response AS Response;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AdminUpsertFoodItem
	@FoodItemID int = NULL, @RestaurantID int, @CategoryID int, @Name nvarchar(140),
	@Description nvarchar(500) = NULL, @Price decimal(10,2), @StockQuantity int, @IsAvailable bit
AS
BEGIN
	SET NOCOUNT ON;
	IF @Price < 0 OR @StockQuantity < 0 THROW 50010, 'Price and stock must be non-negative.', 1;
	IF @FoodItemID IS NULL
		INSERT dbo.FoodItems (RestaurantID, CategoryID, Name, Description, Price, StockQuantity, IsAvailable)
		VALUES (@RestaurantID, @CategoryID, @Name, @Description, @Price, @StockQuantity, @IsAvailable);
	ELSE
		UPDATE dbo.FoodItems SET RestaurantID = @RestaurantID, CategoryID = @CategoryID,
			Name = @Name, Description = @Description, Price = @Price,
			StockQuantity = @StockQuantity, IsAvailable = @IsAvailable
		WHERE FoodItemID = @FoodItemID;
	SELECT * FROM dbo.FoodItems WHERE FoodItemID = COALESCE(@FoodItemID, SCOPE_IDENTITY());
END;
GO
