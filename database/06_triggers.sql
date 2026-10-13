USE FoodBotDB;
GO

CREATE OR ALTER TRIGGER dbo.trg_Orders_ValidateStatusTransition
ON dbo.Orders
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	IF UPDATE(Status) AND EXISTS (
		SELECT 1
		FROM inserted currentOrder
		JOIN deleted previousOrder ON previousOrder.OrderID = currentOrder.OrderID
		WHERE currentOrder.Status <> previousOrder.Status
		  AND NOT (
			  (previousOrder.Status = 'pending' AND currentOrder.Status IN ('confirmed', 'payment_failed', 'cancelled')) OR
			  (previousOrder.Status = 'confirmed' AND currentOrder.Status IN ('preparing', 'cancelled')) OR
			  (previousOrder.Status = 'preparing' AND currentOrder.Status = 'ready') OR
			  (previousOrder.Status = 'ready' AND currentOrder.Status = 'out_for_delivery') OR
			  (previousOrder.Status = 'out_for_delivery' AND currentOrder.Status = 'delivered')
		  )
	)
	BEGIN
		THROW 50020, 'Order status transition is not allowed.', 1;
	END;
END;
GO
