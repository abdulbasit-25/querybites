USE FoodBotDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE dbo.Customers (
	CustomerID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Customers PRIMARY KEY,
	FullName nvarchar(120) NOT NULL,
	Email nvarchar(254) NOT NULL,
	Phone nvarchar(30) NULL,
	PasswordHash nvarchar(255) NOT NULL,
	Role varchar(20) NOT NULL CONSTRAINT DF_Customers_Role DEFAULT ('customer'),
	IsActive bit NOT NULL CONSTRAINT DF_Customers_IsActive DEFAULT (1),
	CreatedAtUtc datetime2(0) NOT NULL CONSTRAINT DF_Customers_CreatedAtUtc DEFAULT (SYSUTCDATETIME()),
	CONSTRAINT UQ_Customers_Email UNIQUE (Email),
	CONSTRAINT CK_Customers_Role CHECK (Role IN ('customer', 'admin'))
);
GO

CREATE TABLE dbo.Restaurants (
	RestaurantID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Restaurants PRIMARY KEY,
	Name nvarchar(120) NOT NULL,
	Description nvarchar(500) NULL,
	Address nvarchar(300) NOT NULL,
	Phone nvarchar(30) NULL,
	IsActive bit NOT NULL CONSTRAINT DF_Restaurants_IsActive DEFAULT (1),
	CreatedAtUtc datetime2(0) NOT NULL CONSTRAINT DF_Restaurants_CreatedAtUtc DEFAULT (SYSUTCDATETIME())
);
GO

CREATE TABLE dbo.FoodCategories (
	CategoryID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_FoodCategories PRIMARY KEY,
	Name nvarchar(80) NOT NULL CONSTRAINT UQ_FoodCategories_Name UNIQUE,
	IsActive bit NOT NULL CONSTRAINT DF_FoodCategories_IsActive DEFAULT (1)
);
GO

CREATE TABLE dbo.FoodItems (
	FoodItemID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_FoodItems PRIMARY KEY,
	RestaurantID int NOT NULL,
	CategoryID int NOT NULL,
	Name nvarchar(140) NOT NULL,
	Description nvarchar(500) NULL,
	Price decimal(10,2) NOT NULL,
	StockQuantity int NOT NULL CONSTRAINT DF_FoodItems_Stock DEFAULT (0),
	IsAvailable bit NOT NULL CONSTRAINT DF_FoodItems_Available DEFAULT (1),
	CreatedAtUtc datetime2(0) NOT NULL CONSTRAINT DF_FoodItems_CreatedAtUtc DEFAULT (SYSUTCDATETIME()),
	CONSTRAINT FK_FoodItems_Restaurants FOREIGN KEY (RestaurantID) REFERENCES dbo.Restaurants(RestaurantID),
	CONSTRAINT FK_FoodItems_Categories FOREIGN KEY (CategoryID) REFERENCES dbo.FoodCategories(CategoryID),
	CONSTRAINT CK_FoodItems_Price CHECK (Price >= 0),
	CONSTRAINT CK_FoodItems_Stock CHECK (StockQuantity >= 0)
);
GO

CREATE TABLE dbo.Orders (
	OrderID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
	CustomerID int NOT NULL,
	RestaurantID int NOT NULL,
	Status varchar(20) NOT NULL CONSTRAINT DF_Orders_Status DEFAULT ('pending'),
	Subtotal decimal(10,2) NOT NULL,
	DiscountAmount decimal(10,2) NOT NULL CONSTRAINT DF_Orders_Discount DEFAULT (0),
	TaxAmount decimal(10,2) NOT NULL CONSTRAINT DF_Orders_Tax DEFAULT (0),
	DeliveryFee decimal(10,2) NOT NULL CONSTRAINT DF_Orders_DeliveryFee DEFAULT (0),
	TotalAmount AS CONVERT(decimal(10,2), Subtotal - DiscountAmount + TaxAmount + DeliveryFee) PERSISTED,
	IdempotencyKey uniqueidentifier NULL,
	CreatedAtUtc datetime2(0) NOT NULL CONSTRAINT DF_Orders_CreatedAtUtc DEFAULT (SYSUTCDATETIME()),
	UpdatedAtUtc datetime2(0) NOT NULL CONSTRAINT DF_Orders_UpdatedAtUtc DEFAULT (SYSUTCDATETIME()),
	CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) REFERENCES dbo.Customers(CustomerID),
	CONSTRAINT FK_Orders_Restaurants FOREIGN KEY (RestaurantID) REFERENCES dbo.Restaurants(RestaurantID),
	CONSTRAINT CK_Orders_Status CHECK (Status IN ('pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled', 'payment_failed')),
	CONSTRAINT CK_Orders_Amounts CHECK (Subtotal >= 0 AND DiscountAmount >= 0 AND DiscountAmount <= Subtotal AND TaxAmount >= 0 AND DeliveryFee >= 0)
);
GO

CREATE UNIQUE INDEX UX_Orders_IdempotencyKey ON dbo.Orders(CustomerID, IdempotencyKey) WHERE IdempotencyKey IS NOT NULL;
GO

CREATE TABLE dbo.OrderDetails (
	OrderDetailID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_OrderDetails PRIMARY KEY,
	OrderID int NOT NULL,
	FoodItemID int NOT NULL,
	Quantity int NOT NULL,
	UnitPrice decimal(10,2) NOT NULL,
	LineTotal AS CONVERT(decimal(10,2), Quantity * UnitPrice) PERSISTED,
	CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID),
	CONSTRAINT FK_OrderDetails_FoodItems FOREIGN KEY (FoodItemID) REFERENCES dbo.FoodItems(FoodItemID),
	CONSTRAINT UQ_OrderDetails_Order_Food UNIQUE (OrderID, FoodItemID),
	CONSTRAINT CK_OrderDetails_Quantity CHECK (Quantity > 0),
	CONSTRAINT CK_OrderDetails_UnitPrice CHECK (UnitPrice >= 0)
);
GO

CREATE TABLE dbo.Payments (
	PaymentID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Payments PRIMARY KEY,
	OrderID int NOT NULL,
	Amount decimal(10,2) NOT NULL,
	Method varchar(20) NOT NULL CONSTRAINT DF_Payments_Method DEFAULT ('simulated'),
	Status varchar(20) NOT NULL CONSTRAINT DF_Payments_Status DEFAULT ('pending'),
	TransactionReference uniqueidentifier NOT NULL CONSTRAINT DF_Payments_Reference DEFAULT (NEWID()),
	CreatedAtUtc datetime2(0) NOT NULL CONSTRAINT DF_Payments_CreatedAtUtc DEFAULT (SYSUTCDATETIME()),
	CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID),
	CONSTRAINT UQ_Payments_Order UNIQUE (OrderID),
	CONSTRAINT CK_Payments_Amount CHECK (Amount >= 0),
	CONSTRAINT CK_Payments_Status CHECK (Status IN ('pending', 'succeeded', 'failed', 'refunded')),
	CONSTRAINT CK_Payments_Method CHECK (Method IN ('simulated', 'cash'))
);
GO

CREATE TABLE dbo.Riders (
	RiderID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Riders PRIMARY KEY,
	FullName nvarchar(120) NOT NULL,
	Phone nvarchar(30) NOT NULL,
	IsAvailable bit NOT NULL CONSTRAINT DF_Riders_Available DEFAULT (1),
	IsActive bit NOT NULL CONSTRAINT DF_Riders_Active DEFAULT (1)
);
GO

CREATE TABLE dbo.Deliveries (
	DeliveryID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Deliveries PRIMARY KEY,
	OrderID int NOT NULL,
	RiderID int NULL,
	DeliveryAddress nvarchar(300) NOT NULL,
	Status varchar(20) NOT NULL CONSTRAINT DF_Deliveries_Status DEFAULT ('queued'),
	AssignedAtUtc datetime2(0) NULL,
	DeliveredAtUtc datetime2(0) NULL,
	CONSTRAINT FK_Deliveries_Orders FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID),
	CONSTRAINT FK_Deliveries_Riders FOREIGN KEY (RiderID) REFERENCES dbo.Riders(RiderID),
	CONSTRAINT UQ_Deliveries_Order UNIQUE (OrderID),
	CONSTRAINT CK_Deliveries_Status CHECK (Status IN ('queued', 'assigned', 'picked_up', 'delivered', 'cancelled'))
);
GO

CREATE TABLE dbo.ChatIntents (
	IntentID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ChatIntents PRIMARY KEY,
	IntentName varchar(60) NOT NULL CONSTRAINT UQ_ChatIntents_Name UNIQUE,
	ResponseTemplate nvarchar(500) NOT NULL,
	IsActive bit NOT NULL CONSTRAINT DF_ChatIntents_Active DEFAULT (1)
);
GO

CREATE TABLE dbo.ChatKeywords (
	KeywordID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ChatKeywords PRIMARY KEY,
	IntentID int NOT NULL,
	Keyword nvarchar(80) NOT NULL,
	CONSTRAINT FK_ChatKeywords_Intents FOREIGN KEY (IntentID) REFERENCES dbo.ChatIntents(IntentID),
	CONSTRAINT UQ_ChatKeywords_Intent_Keyword UNIQUE (IntentID, Keyword)
);
GO

CREATE TABLE dbo.ChatHistory (
	ChatHistoryID bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_ChatHistory PRIMARY KEY,
	CustomerID int NULL,
	UserMessage nvarchar(1000) NOT NULL,
	MatchedIntent varchar(60) NULL,
	BotResponse nvarchar(2000) NOT NULL,
	CreatedAtUtc datetime2(0) NOT NULL CONSTRAINT DF_ChatHistory_CreatedAtUtc DEFAULT (SYSUTCDATETIME()),
	CONSTRAINT FK_ChatHistory_Customers FOREIGN KEY (CustomerID) REFERENCES dbo.Customers(CustomerID)
);
GO
