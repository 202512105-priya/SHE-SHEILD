CREATE TABLE users (id SERIAL PRIMARY KEY, username VARCHAR(50), password_hash VARCHAR(100), role_id INT);
CREATE TABLE complaints (id SERIAL PRIMARY KEY, user_id INT, status VARCHAR(20), description TEXT);
