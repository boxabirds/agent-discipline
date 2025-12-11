-- setup.sql - SQLite fixture schema
-- Sentinel tables: must survive safe operations

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL
);

INSERT INTO users (name, email) VALUES
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com'),
    ('Charlie', 'charlie@example.com');

CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total DECIMAL(10,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders (user_id, total) VALUES
    (1, 99.99),
    (1, 149.99),
    (2, 49.99);

-- Expendable table: can be truncated in tests
CREATE TABLE audit_log (
    id INTEGER PRIMARY KEY,
    action TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO audit_log (action) VALUES
    ('user_created'),
    ('order_placed'),
    ('user_updated');
