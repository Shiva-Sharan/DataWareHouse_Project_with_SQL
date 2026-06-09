/*
===============================================================================
INITIALIZATION SCRIPT: Create Database and Schemas
===============================================================================

Purpose:
    Recreates the 'datawarehouse' database and creates the required
    schemas for the Medallion Architecture: bronze, silver, and gold.

WARNING:
    Running this script will PERMANENTLY DELETE the existing
    'datawarehouse' database (if it exists) along with ALL tables,
    views, functions, procedures, and data stored in it.

    >>> Make sure you have a backup before executing this script. <<<

Usage:
    Step 1: Connect to the 'postgres' database.
    Step 2: Execute the DROP DATABASE and CREATE DATABASE statements.
    Step 3: Reconnect to the 'datawarehouse' database.
    Step 4: Execute the CREATE SCHEMA statements.

===============================================================================
*/



-- =============================================================================
-- Step 1: Drop the existing database (if it exists)
-- Forces disconnection of active sessions before dropping.
-- =============================================================================

DROP DATABASE IF EXISTS datawarehouse WITH (FORCE);



-- =============================================================================
-- Step 2: Create a fresh database
-- =============================================================================

CREATE DATABASE datawarehouse;



-- =============================================================================
-- IMPORTANT:
-- Reconnect to the 'datawarehouse' database before running the
-- statements below.
-- =============================================================================



-- =============================================================================
-- Step 3: Create Bronze Schema
-- Stores raw, unprocessed source data (exact copy of source files).
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS bronze;



-- =============================================================================
-- Step 4: Create Silver Schema
-- Stores cleansed, standardized, and deduplicated data.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS silver;



-- =============================================================================
-- Step 5: Create Gold Schema
-- Stores business-ready dimensional model views for analytics.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS gold;
