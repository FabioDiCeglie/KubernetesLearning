-- Database and user are already created by Docker Compose
-- Just create the table and insert test data

USE auth;

CREATE TABLE user (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL
);

INSERT INTO user (email, password) VALUES ('ftestf9@gmail.com', 'test');