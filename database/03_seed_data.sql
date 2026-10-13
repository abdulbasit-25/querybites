USE FoodBotDB;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @SeedPasswordHash nvarchar(255) = N'$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy';

INSERT dbo.Customers (FullName, Email, Phone, PasswordHash, Role)
SELECT source.FullName, source.Email, source.Phone, @SeedPasswordHash, source.Role
FROM (VALUES
	(N'Amina Shah', N'amina@example.test', N'+92-300-555-0101', 'customer'),
	(N'Bilal Khan', N'bilal@example.test', N'+92-300-555-0102', 'customer'),
	(N'Chen Malik', N'chen@example.test', N'+92-300-555-0103', 'customer'),
	(N'Dua Farooq', N'dua@example.test', N'+92-300-555-0104', 'customer'),
	(N'Ehsan Ali', N'ehsan@example.test', N'+92-300-555-0105', 'customer'),
	(N'Fatima Noor', N'fatima@example.test', N'+92-300-555-0106', 'customer'),
	(N'Hamza Raza', N'hamza@example.test', N'+92-300-555-0107', 'customer'),
	(N'Iqra Ahmed', N'iqra@example.test', N'+92-300-555-0108', 'customer'),
	(N'Junaid Tariq', N'junaid@example.test', N'+92-300-555-0109', 'customer'),
	(N'FoodBot Admin', N'admin@example.test', N'+92-300-555-0110', 'admin')
) source(FullName, Email, Phone, Role)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Customers existing WHERE existing.Email = source.Email);

INSERT dbo.Restaurants (Name, Description, Address, Phone)
SELECT source.Name, source.Description, source.Address, source.Phone
FROM (VALUES
	(N'Copper Kettle', N'Comfort food and grilled favorites.', N'12 Garden Street, Lahore', N'+92-42-555-1001'),
	(N'Olive & Oven', N'Wood-fired pizza and pasta.', N'8 Canal View, Lahore', N'+92-42-555-1002'),
	(N'Green Bowl', N'Fresh bowls, salads, and wraps.', N'24 Market Road, Lahore', N'+92-42-555-1003'),
	(N'Spice Route', N'Pakistani classics with a modern touch.', N'5 Old Town, Lahore', N'+92-42-555-1004'),
	(N'Sugar Studio', N'Small-batch desserts and drinks.', N'16 Lake Avenue, Lahore', N'+92-42-555-1005')
) source(Name, Description, Address, Phone)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Restaurants existing WHERE existing.Name = source.Name);

INSERT dbo.FoodCategories (Name)
SELECT source.Name
FROM (VALUES (N'Pizza'), (N'Burgers'), (N'Pakistani'), (N'Salads'), (N'Desserts'), (N'Drinks')) source(Name)
WHERE NOT EXISTS (SELECT 1 FROM dbo.FoodCategories existing WHERE existing.Name = source.Name);

INSERT dbo.Riders (FullName, Phone)
SELECT source.FullName, source.Phone
FROM (VALUES
	(N'Sameer Iqbal', N'+92-300-555-0201'),
	(N'Maria Yousaf', N'+92-300-555-0202'),
	(N'Usman Latif', N'+92-300-555-0203')
) source(FullName, Phone)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Riders existing WHERE existing.Phone = source.Phone);

INSERT dbo.FoodItems (RestaurantID, CategoryID, Name, Description, Price, StockQuantity, IsAvailable)
SELECT restaurant.RestaurantID, category.CategoryID, item.Name, item.Description, item.Price, item.StockQuantity, item.IsAvailable
FROM (VALUES
	(N'Copper Kettle', N'Burgers', N'Classic Smash Burger', N'Double patty, cheddar, house sauce.', 780.00, 30, 1),
	(N'Copper Kettle', N'Burgers', N'Firecracker Chicken Burger', N'Crispy chicken with chili mayo.', 690.00, 18, 1),
	(N'Copper Kettle', N'Drinks', N'Fresh Lime Soda', N'Sweet or salted lime soda.', 180.00, 40, 1),
	(N'Copper Kettle', N'Desserts', N'Chocolate Brownie', N'Warm cocoa brownie.', 320.00, 0, 0),
	(N'Copper Kettle', N'Burgers', N'Garden Veggie Burger', N'Grilled vegetable patty.', 540.00, 12, 1),
	(N'Copper Kettle', N'Drinks', N'Vanilla Shake', N'Vanilla bean milkshake.', 350.00, 15, 1),
	(N'Olive & Oven', N'Pizza', N'Margherita Pizza', N'Tomato, mozzarella, and basil.', 950.00, 25, 1),
	(N'Olive & Oven', N'Pizza', N'Pepperoni Pizza', N'Classic pepperoni and mozzarella.', 1250.00, 20, 1),
	(N'Olive & Oven', N'Pizza', N'Garden Supreme Pizza', N'Peppers, olives, mushrooms.', 1150.00, 16, 1),
	(N'Olive & Oven', N'Pizza', N'Four Cheese Pizza', N'Mozzarella, cheddar, parmesan, feta.', 1380.00, 10, 1),
	(N'Olive & Oven', N'Pizza', N'BBQ Chicken Pizza', N'Roasted chicken and smoky sauce.', 1320.00, 14, 1),
	(N'Olive & Oven', N'Desserts', N'Tiramisu Cup', N'Espresso-soaked layered dessert.', 420.00, 8, 1),
	(N'Green Bowl', N'Salads', N'Avocado Grain Bowl', N'Brown rice, avocado, herbs.', 820.00, 12, 1),
	(N'Green Bowl', N'Salads', N'Roasted Beet Salad', N'Beet, greens, and citrus dressing.', 620.00, 20, 1),
	(N'Green Bowl', N'Salads', N'Chicken Caesar Bowl', N'Grilled chicken, romaine, parmesan.', 890.00, 15, 1),
	(N'Green Bowl', N'Salads', N'Falafel Wrap', N'Falafel, pickles, tahini.', 560.00, 22, 1),
	(N'Green Bowl', N'Drinks', N'Cold Brew', N'House-steeped coffee.', 300.00, 18, 1),
	(N'Green Bowl', N'Drinks', N'Mango Smoothie', N'Mango, yogurt, and honey.', 390.00, 9, 1),
	(N'Spice Route', N'Pakistani', N'Chicken Karahi', N'Tomato, ginger, and green chili.', 1450.00, 18, 1),
	(N'Spice Route', N'Pakistani', N'Beef Seekh Kebab', N'Charcoal-grilled spiced beef.', 980.00, 22, 1),
	(N'Spice Route', N'Pakistani', N'Chicken Biryani', N'Fragrant rice with chicken.', 720.00, 28, 1),
	(N'Spice Route', N'Pakistani', N'Daal Makhani', N'Slow-cooked lentils.', 590.00, 17, 1),
	(N'Spice Route', N'Pakistani', N'Garlic Naan', N'Tandoor-baked garlic naan.', 120.00, 45, 1),
	(N'Spice Route', N'Drinks', N'Mint Lemonade', N'Fresh mint and lemon.', 220.00, 0, 0),
	(N'Sugar Studio', N'Desserts', N'Lotus Cheesecake', N'Biscoff-style cheesecake slice.', 480.00, 11, 1),
	(N'Sugar Studio', N'Desserts', N'Vanilla Cupcake', N'Vanilla sponge and buttercream.', 210.00, 24, 1),
	(N'Sugar Studio', N'Desserts', N'Fudge Cookie', N'Chewy double chocolate cookie.', 190.00, 30, 1),
	(N'Sugar Studio', N'Desserts', N'Pistachio Kunafa', N'Warm kunafa with pistachio.', 550.00, 7, 1),
	(N'Sugar Studio', N'Drinks', N'Iced Mocha', N'Espresso, cocoa, and milk.', 360.00, 16, 1),
	(N'Sugar Studio', N'Drinks', N'Rose Milk', N'Chilled milk with rose.', 240.00, 13, 1)
) item(RestaurantName, CategoryName, Name, Description, Price, StockQuantity, IsAvailable)
JOIN dbo.Restaurants restaurant ON restaurant.Name = item.RestaurantName
JOIN dbo.FoodCategories category ON category.Name = item.CategoryName
WHERE NOT EXISTS (
	SELECT 1 FROM dbo.FoodItems existing
	WHERE existing.RestaurantID = restaurant.RestaurantID AND existing.Name = item.Name
);

INSERT dbo.ChatIntents (IntentName, ResponseTemplate)
SELECT source.IntentName, source.ResponseTemplate
FROM (VALUES
	('greeting', N'Hello! I can help you find restaurants, browse food, check an order, or explain how FoodBot works.'),
	('help', N'Try: "show restaurants", "show pizza", "food under 500", or "where is my order?"'),
	('restaurants', N'Here are the restaurants currently accepting orders.'),
	('menu', N'Browse available dishes in the menu page.'),
	('food_search', N'I found matching dishes for you.'),
	('order_status', N'Please sign in and provide your order number to check its status.'),
	('cancel_order', N'Orders can be cancelled while they are pending or confirmed. Open Orders to select one.'),
	('thanks', N'You are welcome. Enjoy your meal!'),
	('hours', N'Restaurant availability is shown live in the restaurant list.'),
	('delivery', N'Delivery status and rider assignment appear in your order details.')
) source(IntentName, ResponseTemplate)
WHERE NOT EXISTS (SELECT 1 FROM dbo.ChatIntents existing WHERE existing.IntentName = source.IntentName);

INSERT dbo.ChatKeywords (IntentID, Keyword)
SELECT intent.IntentID, source.Keyword
FROM (VALUES
	('greeting', N'hello'), ('greeting', N'hi'), ('greeting', N'hey'),
	('help', N'help'), ('help', N'what can you do'),
	('restaurants', N'restaurant'), ('restaurants', N'restaurants'), ('restaurants', N'places'),
	('menu', N'menu'), ('menu', N'dishes'),
	('food_search', N'pizza'), ('food_search', N'burger'), ('food_search', N'under'), ('food_search', N'food'),
	('order_status', N'where is my order'), ('order_status', N'track'), ('order_status', N'status'),
	('cancel_order', N'cancel'), ('thanks', N'thank'), ('thanks', N'thanks'),
	('hours', N'open'), ('delivery', N'delivery'), ('delivery', N'rider')
) source(IntentName, Keyword)
JOIN dbo.ChatIntents intent ON intent.IntentName = source.IntentName
WHERE NOT EXISTS (
	SELECT 1 FROM dbo.ChatKeywords existing
	WHERE existing.IntentID = intent.IntentID AND existing.Keyword = source.Keyword
);

DECLARE @SeedOrderInput TABLE (
	IdempotencyKey uniqueidentifier PRIMARY KEY,
	CustomerEmail nvarchar(254) NOT NULL,
	RestaurantName nvarchar(120) NOT NULL,
	FoodName nvarchar(140) NOT NULL,
	Quantity int NOT NULL,
	OrderStatus varchar(20) NOT NULL,
	PaymentStatus varchar(20) NOT NULL,
	DeliveryStatus varchar(20) NULL,
	DiscountPercent decimal(5,2) NOT NULL,
	AgeDays int NOT NULL
);

INSERT @SeedOrderInput VALUES
('00000001-0000-0000-0000-000000000001', N'amina@example.test', N'Olive & Oven', N'Margherita Pizza', 1, 'delivered', 'succeeded', 'delivered', 0, 25),
('00000002-0000-0000-0000-000000000002', N'bilal@example.test', N'Spice Route', N'Chicken Biryani', 2, 'delivered', 'succeeded', 'delivered', 10, 23),
('00000003-0000-0000-0000-000000000003', N'chen@example.test', N'Copper Kettle', N'Classic Smash Burger', 1, 'delivered', 'succeeded', 'delivered', 0, 20),
('00000004-0000-0000-0000-000000000004', N'dua@example.test', N'Green Bowl', N'Falafel Wrap', 2, 'delivered', 'succeeded', 'delivered', 0, 19),
('00000005-0000-0000-0000-000000000005', N'ehsan@example.test', N'Sugar Studio', N'Lotus Cheesecake', 1, 'delivered', 'succeeded', 'delivered', 15, 18),
('00000006-0000-0000-0000-000000000006', N'fatima@example.test', N'Olive & Oven', N'Pepperoni Pizza', 1, 'delivered', 'succeeded', 'delivered', 0, 16),
('00000007-0000-0000-0000-000000000007', N'hamza@example.test', N'Spice Route', N'Beef Seekh Kebab', 2, 'delivered', 'succeeded', 'delivered', 0, 15),
('00000008-0000-0000-0000-000000000008', N'iqra@example.test', N'Green Bowl', N'Chicken Caesar Bowl', 1, 'delivered', 'succeeded', 'delivered', 10, 13),
('00000009-0000-0000-0000-000000000009', N'junaid@example.test', N'Copper Kettle', N'Garden Veggie Burger', 1, 'delivered', 'succeeded', 'delivered', 0, 12),
('00000010-0000-0000-0000-000000000010', N'amina@example.test', N'Sugar Studio', N'Fudge Cookie', 3, 'delivered', 'succeeded', 'delivered', 0, 11),
('00000011-0000-0000-0000-000000000011', N'bilal@example.test', N'Olive & Oven', N'Garden Supreme Pizza', 1, 'delivered', 'succeeded', 'delivered', 0, 9),
('00000012-0000-0000-0000-000000000012', N'chen@example.test', N'Spice Route', N'Daal Makhani', 2, 'delivered', 'succeeded', 'delivered', 5, 8),
('00000013-0000-0000-0000-000000000013', N'dua@example.test', N'Green Bowl', N'Avocado Grain Bowl', 1, 'confirmed', 'succeeded', 'queued', 0, 1),
('00000014-0000-0000-0000-000000000014', N'ehsan@example.test', N'Copper Kettle', N'Firecracker Chicken Burger', 1, 'preparing', 'succeeded', 'queued', 0, 2),
('00000015-0000-0000-0000-000000000015', N'fatima@example.test', N'Olive & Oven', N'BBQ Chicken Pizza', 1, 'ready', 'succeeded', 'assigned', 0, 1),
('00000016-0000-0000-0000-000000000016', N'hamza@example.test', N'Spice Route', N'Chicken Karahi', 1, 'out_for_delivery', 'succeeded', 'picked_up', 0, 0),
('00000017-0000-0000-0000-000000000017', N'iqra@example.test', N'Sugar Studio', N'Pistachio Kunafa', 1, 'cancelled', 'refunded', 'cancelled', 0, 7),
('00000018-0000-0000-0000-000000000018', N'junaid@example.test', N'Spice Route', N'Garlic Naan', 2, 'cancelled', 'refunded', 'cancelled', 0, 6),
('00000019-0000-0000-0000-000000000019', N'amina@example.test', N'Green Bowl', N'Mango Smoothie', 1, 'payment_failed', 'failed', NULL, 0, 4),
('00000020-0000-0000-0000-000000000020', N'bilal@example.test', N'Copper Kettle', N'Vanilla Shake', 1, 'pending', 'pending', 'queued', 0, 0);

DECLARE @SeededOrderIDs TABLE (OrderID int NOT NULL, IdempotencyKey uniqueidentifier NOT NULL);
INSERT dbo.Orders (CustomerID, RestaurantID, Status, Subtotal, DiscountAmount, TaxAmount, DeliveryFee, IdempotencyKey, CreatedAtUtc)
OUTPUT inserted.OrderID, inserted.IdempotencyKey INTO @SeededOrderIDs (OrderID, IdempotencyKey)
SELECT customer.CustomerID, restaurant.RestaurantID, input.OrderStatus,
	   CONVERT(decimal(10,2), food.Price * input.Quantity),
	ROUND(food.Price * input.Quantity * input.DiscountPercent / 100, 2),
	ROUND((food.Price * input.Quantity - ROUND(food.Price * input.Quantity * input.DiscountPercent / 100, 2)) * 0.05, 2),
	   100.00, input.IdempotencyKey, DATEADD(day, -input.AgeDays, SYSUTCDATETIME())
FROM @SeedOrderInput input
JOIN dbo.Customers customer ON customer.Email = input.CustomerEmail
JOIN dbo.Restaurants restaurant ON restaurant.Name = input.RestaurantName
JOIN dbo.FoodItems food ON food.RestaurantID = restaurant.RestaurantID AND food.Name = input.FoodName
WHERE NOT EXISTS (SELECT 1 FROM dbo.Orders existing WHERE existing.CustomerID = customer.CustomerID AND existing.IdempotencyKey = input.IdempotencyKey);

INSERT dbo.OrderDetails (OrderID, FoodItemID, Quantity, UnitPrice)
SELECT seeded.OrderID, food.FoodItemID, input.Quantity, food.Price
FROM @SeededOrderIDs seeded
JOIN @SeedOrderInput input ON input.IdempotencyKey = seeded.IdempotencyKey
JOIN dbo.Restaurants restaurant ON restaurant.Name = input.RestaurantName
JOIN dbo.FoodItems food ON food.RestaurantID = restaurant.RestaurantID AND food.Name = input.FoodName;

INSERT dbo.Payments (OrderID, Amount, Method, Status)
SELECT seeded.OrderID, orders.TotalAmount, 'simulated', input.PaymentStatus
FROM @SeededOrderIDs seeded
JOIN @SeedOrderInput input ON input.IdempotencyKey = seeded.IdempotencyKey
JOIN dbo.Orders orders ON orders.OrderID = seeded.OrderID;

INSERT dbo.Deliveries (OrderID, RiderID, DeliveryAddress, Status, AssignedAtUtc, DeliveredAtUtc)
SELECT seeded.OrderID,
	   CASE WHEN input.DeliveryStatus IN ('assigned', 'picked_up', 'delivered') THEN rider.RiderID ELSE NULL END,
	   N'Fictional sample address, Lahore', input.DeliveryStatus,
	   CASE WHEN input.DeliveryStatus IN ('assigned', 'picked_up', 'delivered') THEN SYSUTCDATETIME() END,
	   CASE WHEN input.DeliveryStatus = 'delivered' THEN DATEADD(hour, -1, SYSUTCDATETIME()) END
FROM @SeededOrderIDs seeded
JOIN @SeedOrderInput input ON input.IdempotencyKey = seeded.IdempotencyKey
LEFT JOIN dbo.Riders rider ON rider.RiderID = 1
WHERE input.DeliveryStatus IS NOT NULL;

UPDATE food
SET StockQuantity = food.StockQuantity - sold.Quantity
FROM dbo.FoodItems food
JOIN (
	SELECT detail.FoodItemID, SUM(detail.Quantity) AS Quantity
	FROM dbo.OrderDetails detail
	JOIN @SeededOrderIDs seeded ON seeded.OrderID = detail.OrderID
	JOIN dbo.Payments payment ON payment.OrderID = detail.OrderID AND payment.Status = 'succeeded'
	GROUP BY detail.FoodItemID
) sold ON sold.FoodItemID = food.FoodItemID;

COMMIT TRANSACTION;
GO
