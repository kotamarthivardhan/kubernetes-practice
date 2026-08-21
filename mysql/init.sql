CREATE DATABASE IF NOT EXISTS devopsdb;

USE devopsdb;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

INSERT INTO users (name, email)
VALUES
('Aditya', 'aditya@example.com'),
('Rahul', 'rahul@example.com'),
('Kiran', 'kiran@example.com');
