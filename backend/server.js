const express = require("express");
const mysql = require("mysql2/promise");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 5000;

const DB_HOST = process.env.DB_HOST || "mysql";
const DB_USER = process.env.DB_USER || "appuser";
const DB_PASSWORD = process.env.DB_PASSWORD || "password";
const DB_NAME = process.env.DB_NAME || "devopsdb";

let pool;

async function connectDatabase() {
    pool = mysql.createPool({
        host: DB_HOST,
        user: DB_USER,
        password: DB_PASSWORD,
        database: DB_NAME,
        waitForConnections: true,
        connectionLimit: 10
    });

    console.log("Database pool created");
}

app.get("/health", (req, res) => {
    res.status(200).json({
        status: "UP"
    });
});

app.get("/api/users", async (req, res) => {
    try {
        const [rows] = await pool.query(
            "SELECT * FROM users"
        );

        res.json(rows);

    } catch (error) {
        console.error(error);

        res.status(500).json({
            error: "Database query failed"
        });
    }
});

app.get("/api/info", (req, res) => {
    res.json({
        application: "DevOps Demo Application",
        version: "1.0",
        environment: process.env.APP_ENV || "development",
        hostname: require("os").hostname()
    });
});

async function start() {

    await connectDatabase();

    app.listen(PORT, "0.0.0.0", () => {
        console.log(`Backend running on port ${PORT}`);
    });
}

start();
