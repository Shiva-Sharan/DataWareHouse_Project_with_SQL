/*

# Create Database and Schemas

Script Purpose:
This script recreates the 'datawarehouse' database and
creates the required schemas: bronze, silver, and gold.

WARNING:
Running this script will permanently delete the existing
'datawarehouse' database (if it exists) along with all
tables, views, functions, procedures, and data stored in it.

```
Make sure you have a backup before executing this script.
```

NOTE:
Execute the DROP DATABASE and CREATE DATABASE statements
while connected to the 'postgres' database.

```
After the database is created, reconnect to the newly
created 'datawarehouse' database and execute the schema
creation statements.
```

*/

-- ==========================================================
-- Step 1: Drop the existing database (if it exists)
-- This will forcefully disconnect active sessions and
-- permanently remove all existing data.
-- ==========================================================

DROP DATABASE IF EXISTS datawarehouse WITH (FORCE);

-- ==========================================================
-- Step 2: Create a fresh database
-- ==========================================================

CREATE DATABASE datawarehouse;

-- ==========================================================
-- IMPORTANT:
-- Connect to the 'datawarehouse' database before running
-- the statements below.
-- ==========================================================

-- ==========================================================
-- Step 3: Create Bronze Schema
-- Stores raw source data.
-- ==========================================================

CREATE SCHEMA IF NOT EXISTS bronze;

-- ==========================================================
-- Step 4: Create Silver Schema
-- Stores cleaned and transformed data.
-- ==========================================================

CREATE SCHEMA IF NOT EXISTS silver;

-- ==========================================================
-- Step 5: Create Gold Schema
-- Stores business-ready and reporting data.
-- ==========================================================

CREATE SCHEMA IF NOT EXISTS gold;
