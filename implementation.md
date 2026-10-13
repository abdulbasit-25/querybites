# BUILD FOODBOT — COMPLETE SQL SERVER FOOD DELIVERY CHATBOT

Act as a senior full-stack developer, SQL Server database architect, and database systems instructor. Build a complete, functional, well-documented university-level project named **FoodBot: A SQL Server-Based Food Delivery Chatbot**.

Do not stop at a UI prototype, a database schema, or a list of suggestions. Implement the actual application, database scripts, backend integration, test scenarios, documentation, and demonstration materials.

Work directly in the current VS Code workspace. First inspect the repository and existing files. Preserve useful existing work, avoid overwriting unrelated files, and adapt the implementation if a project already exists.

If the workspace is empty, initialize the project with the structure described below.

## 1. Project objectives

FoodBot is a rule-based food delivery chatbot backed by Microsoft SQL Server.

Users should be able to:

- Register and log in.
- Browse restaurants and their menus.
- Search food by name, category, restaurant, availability, or price range.
- Add food items to a cart.
- Place orders and calculate totals.
- View current and previous orders.
- Track order and delivery statuses.
- Cancel eligible orders.
- Ask predefined food delivery questions through the chatbot.

Administrators should be able to manage restaurants, food items, stock, orders, riders, and deliveries.

The project must demonstrate advanced database concepts through executable SQL scripts and reproducible experiments.

Do not use an external AI API, machine-learning model, or vector database. Chatbot intelligence must be rule-based and implemented primarily in SQL Server.

## 2. Required technology stack

Use:

- Database: Microsoft SQL Server Developer Edition.
- Database development: SQL Server Management Studio (SSMS).
- Database language: T-SQL.
- Frontend: HTML5, CSS3, and vanilla JavaScript.
- Backend: Node.js with Express.
- Database driver: `mssql`.
- Authentication: bcrypt password hashing and server-side sessions or another securely implemented authentication mechanism.
- Environment configuration: dotenv.
- Testing: Node.js built-in test runner where practical, plus SQL scripts for database experiments.
- Version control compatibility: Git.

Use JavaScript rather than TypeScript for the backend to keep the project accessible to an undergraduate database student.

Use compatible, stable package versions. Do not introduce unnecessary frameworks or dependencies.

## 3. Project architecture

Separate the frontend, backend, SQL scripts, and documentation.

Use a structure similar to:

FoodBot/
frontend/
index.html
login.html
register.html
menu.html
orders.html
admin.html
css/
styles.css
js/
api.js
auth.js
chat.js
menu.js
orders.js
admin.js
backend/
src/
app.js
server.js
config/
database.js
middleware/
auth.js
errorHandler.js
routes/
auth.routes.js
restaurants.routes.js
food.routes.js
orders.routes.js
deliveries.routes.js
chat.routes.js
admin.routes.js
services/
utils/
tests/
package.json
.env.example
database/
00_create_database.sql
01_schema.sql
02_constraints_indexes.sql
03_seed_data.sql
04_functions.sql
05_stored_procedures.sql
06_triggers.sql
07_views.sql
08_transactions.sql
09_concurrency_experiments.sql
10_isolation_levels.sql
11_deadlock_experiments.sql
12_recovery_experiments.sql
13_verification.sql
docs/
ER_DIAGRAM.md
DATABASE_DESIGN.md
EXPERIMENTS.md
TESTING.md
DEMO_GUIDE.md
VIVA_QUESTIONS.md
README.md
.gitignore

You may adjust the structure when there is a clear technical reason, but keep the project organized and easy to understand.

## 4. Database design

Create a database named `FoodBotDB`.

Design a normalized relational schema with suitable primary keys, foreign keys, data types, uniqueness rules, defaults, check constraints, and indexes.

Include at least these entities:

1. Customers
2. Restaurants
3. FoodCategories
4. FoodItems
5. Orders
6. OrderDetails
7. Payments
8. Riders
9. Deliveries
10. ChatIntents
11. ChatKeywords, if useful
12. ChatHistory
13. DiscountCodes, if implemented
14. Sessions or equivalent server-side session storage, if needed

Use identity primary keys where appropriate. Use decimal types for currency, UTC timestamps where practical, and explicit status values.

Important database rules:

- Prices and quantities must be valid.
- Stock must never become negative.
- Order items must reference existing food items.
- Foreign keys must protect referential integrity.
- Order totals must be calculated consistently from order details, applicable discounts, tax, and delivery charges.
- Historical order details must preserve the price charged at the time of ordering.
- A customer must not be able to read another customer's private orders.
- A payment amount must match the appropriate order total.
- Order and delivery statuses must follow defined transitions.
- Avoid redundant data and explain any intentional denormalization.

Provide a clear ER diagram in Mermaid format and document the cardinality of each relationship.

## 5. Sample dataset

Generate a deterministic SQL seed script. Do not require a downloaded external dataset.

Include:

- At least 10 sample customers.
- At least 5 restaurants.
- At least 30 food items.
- At least 20 historical orders.
- Corresponding order details, payments, riders, and deliveries.
- Multiple food categories and stock levels.
- Successful, pending, failed, and refunded payment examples where valid.
- Several order and delivery statuses.
- At least 15 useful chatbot intents with multiple keywords and predefined responses.
- Examples of unavailable items, low-stock items, discounted orders, and cancelled orders.

Use fictional names, addresses, and contact information. Never use real credentials or personal information.

Ensure seed scripts are safe to rerun or document a reliable reset procedure. Avoid duplicate records and broken foreign keys.

## 6. Stored procedures

Implement and document stored procedures for:

- Customer registration support and authentication-related database operations, as appropriate.
- Restaurant search.
- Food search and price filtering.
- Retrieving a restaurant menu.
- Retrieving customer order history.
- Placing an order.
- Cancelling an eligible order.
- Retrieving order and delivery status.
- Applying and validating discount codes.
- Assigning an available rider.
- Updating order and delivery status.
- Processing simulated payment outcomes.
- Handling chatbot messages.
- Administrative management of restaurants, menu items, and stock.

The chatbot handler must receive a message and, when needed, a customer ID or session context. It should normalize the input, match known keywords or patterns against database records, determine the intent, and execute the appropriate parameterized SQL operation.

For example:

- "Hello"
- "Show restaurants"
- "Show food under Rs. 500"
- "Show pizza"
- "Show menu for restaurant 1"
- "Where is my order?"
- "Cancel my order"
- "Help"

Do not parse user input by concatenating arbitrary text into SQL. Use parameters and fixed, allowlisted procedure mappings.

If the message is ambiguous, return a helpful clarification rather than executing an unsafe operation.

Never expose private customer information in public chatbot responses.

## 7. SQL functions, views, and triggers

Create scalar functions for appropriate calculations, such as discount amounts or delivery estimates.

Create inline table-valued functions for useful read operations, such as retrieving menu items or order history, where appropriate.

Use views for reporting, including:

- Detailed order summaries.
- Restaurant sales summaries.
- Popular food items.
- Customer order summaries.
- Delivery status reports.

Use triggers only when they serve a clear database integrity or auditing purpose. Do not duplicate business logic unnecessarily across triggers and stored procedures.

Document the difference between stored procedures, scalar functions, table-valued functions, views, and triggers.

Explain SQL Server restrictions on side effects in user-defined functions. Do not implement data-modifying operations inside functions where SQL Server does not permit them.

## 8. Reliable order processing and ACID

The order placement procedure must use explicit transactions and structured error handling.

A successful order should:

1. Validate the customer and cart.
2. Validate food availability and stock.
3. Create the order.
4. Create order-detail rows with historical prices.
5. Reduce inventory safely.
6. Calculate and store the correct order total.
7. Process a simulated payment result.
8. Update the payment and order status.
9. Create delivery information when appropriate.
10. Commit only when all required operations succeed.

If a required step fails, roll back the entire transaction.

Use `SET XACT_ABORT ON` where appropriate, `TRY...CATCH`, `XACT_STATE()`, and safe transaction cleanup.

Prevent duplicate submissions and overselling. Consider an idempotency key or another defensible duplicate-order protection strategy.

Explain how the implementation demonstrates:

- Atomicity.
- Consistency.
- Isolation.
- Durability.

Do not claim that an experiment proves durability after a server restart unless that test is actually performed.

Demonstrate savepoints separately. Explain that rolling back to a savepoint preserves earlier work within the same transaction and that savepoints do not replace proper business-level order validation.

## 9. Concurrency and isolation experiments

Provide executable SQL scripts designed to run in separate SSMS query windows.

Demonstrate:

- Lost update.
- Dirty read.
- Non-repeatable read.
- Phantom read.
- Shared and exclusive locks.
- Blocking.
- Two-Phase Locking.
- Conflict serializability.
- Precedence graphs.
- SQL Server isolation levels.
- Snapshot isolation and row-versioning behavior.

Include reproducible transaction schedules, expected outcomes, explanations, and cleanup instructions.

For every experiment:

- State which SSMS window runs which script.
- Explain when to execute each statement.
- Identify the expected blocking behavior or anomaly.
- Explain how to observe the outcome.
- Explain how to prevent or reduce the problem.

Use separate test tables or safely resettable test data where appropriate.

Never make an experiment dependent on unpredictable timing alone. Use explicit waits, controlled transaction ordering, or step-by-step manual execution where appropriate.

Explain the differences between `READ UNCOMMITTED`, `READ COMMITTED`, `REPEATABLE READ`, `SERIALIZABLE`, and `SNAPSHOT`.

Ensure that database settings required for snapshot isolation are documented and that tests do not silently change production settings.

For serializability, provide sample transaction schedules, conflict analysis, precedence graphs in Mermaid or another clear diagram format, and an explanation of cycles.

For Two-Phase Locking, explain the growing and shrinking phases using a practical schedule. Distinguish the theoretical protocol from the actual lock behavior observed in SQL Server.

## 10. Deadlock demonstration

Build a reproducible deadlock experiment using two sessions and two resources.

Session A:

- Begin a transaction.
- Lock resource 1.
- Wait for the next step.
- Attempt to lock resource 2.

Session B:

- Begin a transaction.
- Lock resource 2.
- Wait for the next step.
- Attempt to lock resource 1.

Explain how to coordinate the steps so both sessions hold their first locks before requesting the second resource.

Demonstrate:

- The deadlock cycle in a Wait-For Graph.
- SQL Server's deadlock victim selection.
- Error handling for error 1205.
- Retrying a transaction safely.
- Prevention by acquiring resources in a consistent order.
- Short transactions and appropriate lock timeouts.

Include cleanup and recovery steps if the experiment is interrupted.

Do not use application delays as the only mechanism for synchronizing the experiment.

## 11. Database recovery

Create practical recovery demonstrations covering:

- A simulated payment failure during order placement.
- A validation failure after an order transaction starts.
- Explicit rollback.
- SQL Server `TRY...CATCH` error handling.
- Transaction log and checkpoint concepts.
- Backup and restore using a clearly documented local development database.

Provide backup and restore instructions that use paths valid for the user's configured SQL Server instance, rather than assuming that SQL Server can access any folder on the computer.

Explain which demonstrations are simulations and which involve actual SQL Server backup and restore operations.

Never recommend deliberately terminating a production database or destroying real user data.

## 12. Backend implementation

Build a complete Express API with:

- Centralized SQL Server connection pooling.
- Environment-based configuration.
- Parameterized queries.
- Stored procedure calls.
- Request validation.
- Centralized error handling.
- Authentication and authorization middleware.
- Role-based access for customers and administrators.
- Rate limiting for login and chat endpoints.
- Secure session or token handling.
- Safe handling of database connection failures.
- Graceful server shutdown.
- Appropriate HTTP status codes.
- CORS configured for the actual local frontend origin.

Do not expose database credentials, SQL errors, stack traces, password hashes, session secrets, or internal implementation details to users.

Use bcrypt for password hashing. Do not store plaintext passwords or put passwords in browser local storage.

If using sessions, configure secure cookies appropriately, explain local HTTP development settings, and use a suitable server-side session store rather than relying on an unbounded in-memory production session store.

Provide an `.env.example` containing placeholders only.

Support local SQL Server connection settings for:

- A default local instance.
- A named instance where applicable.
- SQL Server authentication.
- Windows/integrated authentication if the chosen driver configuration supports it.

Document any native dependencies or driver configuration required for integrated authentication.

Do not automatically execute SQL scripts against a database during server startup. Database creation and migration steps must be explicit.

## 13. Frontend implementation

Create a polished, responsive interface with a professional food delivery visual identity.

Design direction:

- Clean, modern, and consistent.
- Warm food-inspired accents with neutral backgrounds.
- Strong typography and readable spacing.
- Responsive layouts for desktop, tablet, and mobile.
- Accessible buttons, labels, focus states, and contrast.
- Loading states, empty states, success messages, and error feedback.
- No fake functionality or decorative controls that do nothing.

Implement:

- Landing page.
- Login and registration pages.
- Restaurant browsing.
- Search and filtering.
- Restaurant menu display.
- Shopping cart and checkout.
- Order confirmation.
- Order history and tracking.
- Chatbot interface.
- Admin dashboard for restaurant, menu, inventory, order, and delivery management.

The chat interface should display user messages and server responses in a readable conversation layout.

Render database results safely. Do not insert user-supplied messages into HTML using unsafe `innerHTML` operations.

Keep frontend code separated into reusable JavaScript modules. The interface must use real backend endpoints and actual SQL data.

## 14. Testing

Create automated backend tests and documented SQL manual tests for:

- Database connectivity.
- Registration and login.
- Invalid credentials.
- Role-based access.
- Restaurant and menu searches.
- Price filtering.
- Successful order placement.
- Out-of-stock orders.
- Invalid quantities.
- Failed simulated payments.
- Duplicate submissions.
- Inventory consistency.
- Order cancellation.
- Unauthorized access to another customer's order.
- Chatbot intent matching.
- Invalid input and SQL injection attempts.
- Transaction rollback.
- Concurrent stock updates.
- Deadlock handling.
- Order totals and discounts.

Use a dedicated test database or controlled test fixtures. Do not run destructive tests against a user's unrelated database.

Do not fabricate test results. Run the available tests, fix failures, and report exactly what was and was not verified.

## 15. Documentation and university deliverables

Create:

- A comprehensive README with prerequisites, installation, SQL Server setup, database initialization, configuration, startup, testing, and troubleshooting.
- ER diagram and relational schema documentation.
- Normalization explanation.
- Database design decisions and constraints.
- Stored procedure versus function comparison.
- Isolation-level comparison table.
- Transaction and ACID explanations.
- Concurrency experiment instructions.
- Deadlock Wait-For Graph.
- Precedence graph examples.
- Recovery and backup/restore instructions.
- A test report template.
- A live demonstration script.
- University-level viva questions and answers.

Use simple, technically accurate explanations appropriate for an undergraduate Advanced Database Systems course.

Clearly distinguish implemented features, simulated features, and features requiring additional setup.

## 16. Implementation workflow

Work in these stages:

Stage 1: Inspect the workspace, identify existing code, check the available environment, and create an implementation plan.

Stage 2: Implement the database schema, constraints, indexes, seed data, and verification queries.

Stage 3: Implement stored procedures, functions, views, and necessary triggers.

Stage 4: Implement transactions, concurrency, isolation, 2PL, deadlock, serializability, and recovery experiments.

Stage 5: Implement the Node.js backend and secure SQL Server integration.

Stage 6: Implement the frontend and connect every user-facing feature to working API endpoints.

Stage 7: Add tests, execute available checks, fix errors, and document any tests requiring manual SQL Server sessions.

Stage 8: Finish the documentation and prepare the demonstration.

At the end of each stage:

- Summarize the files created or modified.
- Explain how to run and verify that stage.
- Run relevant available tests.
- Fix errors before proceeding where practical.

Do not stop after creating a plan. Continue implementing the project in manageable stages. If the task exceeds one context window, maintain a concise progress file such as `docs/BUILD_PROGRESS.md` and continue from it.

Do not replace real implementation with pseudocode, placeholder functions, hardcoded API responses, or mock database results.

If SQL Server is unavailable in the environment, still write the SQL scripts and backend integration, statically inspect the code, and clearly document which tests need a configured SQL Server instance.

Do not claim that code has been executed, tested, or verified unless it actually has.

## 17. Completion criteria

The project is complete when:

- All required files exist.
- The database can be initialized using the documented SQL scripts.
- Seed data loads without broken relationships.
- The backend connects to SQL Server using environment configuration.
- Registration, login, browsing, ordering, tracking, cancellation, and chatbot operations work end to end.
- Order transactions preserve inventory and payment consistency.
- Administrative features are protected by authorization.
- Advanced database experiments can be reproduced using the instructions.
- Tests run successfully where the required environment is available.
- The README allows another student to set up and run the application.
- Limitations and unverified behavior are clearly documented.

Start by inspecting the current workspace, then implement Stage 1 and continue through the project in manageable stages. Prioritize correctness, security, database integrity, and demonstrable learning outcomes over unnecessary complexity.
