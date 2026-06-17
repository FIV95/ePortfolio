-- Set the schema to use
SET search_path TO tech;

-- Create login roles with secure passwords
-- These roles will be assigned different levels of access based on job function
CREATE ROLE tech_login WITH LOGIN PASSWORD 'tech_pass';
CREATE ROLE admin_login WITH LOGIN PASSWORD 'admin_pass';
CREATE ROLE auditor_login WITH LOGIN PASSWORD 'auditor_pass';

-- Grant basic schema usage so users can reference objects in the schema
GRANT USAGE ON SCHEMA tech TO tech_login;
GRANT USAGE ON SCHEMA tech TO admin_login;
GRANT USAGE ON SCHEMA tech TO auditor_login;

-- Grant permissions to customer table based on role responsibilities
-- Technicians can read and modify customer records
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.customer TO tech_login;

-- Admins can perform all operations
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.customer TO admin_login;

-- Auditors can only view customer data
GRANT SELECT ON tech.customer TO auditor_login;

-- Repeat permission grants for other tables used in the schema
-- Devices
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.device TO tech_login;
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.device TO admin_login;
GRANT SELECT ON tech.device TO auditor_login;

-- Technicians
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.technician TO tech_login;
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.technician TO admin_login;
GRANT SELECT ON tech.technician TO auditor_login;

-- Repair Orders
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.repair_order TO tech_login;
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.repair_order TO admin_login;
GRANT SELECT ON tech.repair_order TO auditor_login;

-- Parts Used
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.part_used TO tech_login;
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.part_used TO admin_login;
GRANT SELECT ON tech.part_used TO auditor_login;

-- User Role table: Sensitive table with stricter access
-- Only admin can fully manage it
GRANT SELECT, INSERT, UPDATE, DELETE ON tech.user_role TO admin_login;
-- Technicians can read and update only their own rows (RLS enforces this)
GRANT SELECT, UPDATE ON tech.user_role TO tech_login;
-- Auditors can only read it
GRANT SELECT ON tech.user_role TO auditor_login;

-- Enable Row-Level Security on user_role table
ALTER TABLE tech.user_role ENABLE ROW LEVEL SECURITY;

-- Create policy to restrict technician access to their own record
CREATE POLICY tech_own_record ON tech.user_role
FOR ALL
TO tech_login
USING (username = current_user);

-- Set default privileges for new tables in the schema to maintain role access
ALTER DEFAULT PRIVILEGES IN SCHEMA tech
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO tech_login;
ALTER DEFAULT PRIVILEGES IN SCHEMA tech
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO admin_login;
ALTER DEFAULT PRIVILEGES IN SCHEMA tech
GRANT SELECT ON TABLES TO auditor_login;
