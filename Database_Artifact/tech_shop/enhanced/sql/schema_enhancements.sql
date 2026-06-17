-- Database Enhancement: Schema Improvements
-- Author: Frank Lawrence
-- Date: 2026-06-04
-- Purpose: Add columns to support better tracking, costing, and reporting

SET search_path TO tech;

-- 1. Enhance repair_order table
ALTER TABLE repair_order 
ADD COLUMN IF NOT EXISTS total_cost NUMERIC(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH')),
ADD COLUMN IF NOT EXISTS estimated_hours NUMERIC(5,2) DEFAULT 0.00;

-- 2. Enhance technician table
ALTER TABLE technician 
ADD COLUMN IF NOT EXISTS specialty TEXT,
ADD COLUMN IF NOT EXISTS hourly_rate NUMERIC(8,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- 3. Enhance customer table
ALTER TABLE customer 
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS loyalty_points INTEGER DEFAULT 0;

-- Add comments for documentation
COMMENT ON COLUMN repair_order.total_cost IS 'Total cost of the repair including parts and labor';
COMMENT ON COLUMN repair_order.priority IS 'Priority level of the repair';
COMMENT ON COLUMN technician.hourly_rate IS 'Technician hourly billing rate';

-- Re-apply indexes if needed after changes (we can expand later)
CREATE INDEX IF NOT EXISTS idx_repair_order_priority ON repair_order(priority);
CREATE INDEX IF NOT EXISTS idx_repair_order_status ON repair_order(status);

\echo "Schema enhancements applied successfully."
