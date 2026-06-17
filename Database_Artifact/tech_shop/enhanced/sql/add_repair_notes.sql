-- Database Enhancement: New Table and Relationship Improvements
-- Author: Frank Lawrence
-- Date: 2026-06-06
-- Purpose: Add repair_notes table for detailed history and strengthen relationships

SET search_path TO tech;

-- 1. Create new repair_notes table (1-to-many with repair_order)
CREATE TABLE IF NOT EXISTS repair_notes (
    note_id SERIAL PRIMARY KEY,
    repair_order_id INTEGER NOT NULL,
    technician_id INTEGER,
    note_text TEXT NOT NULL,
    note_type TEXT DEFAULT 'GENERAL' CHECK (note_type IN ('GENERAL', 'PROGRESS', 'CUSTOMER', 'PARTS', 'RESOLUTION')),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT DEFAULT current_user,
    FOREIGN KEY (repair_order_id) REFERENCES repair_order(id) ON DELETE CASCADE,
    FOREIGN KEY (technician_id) REFERENCES technician(id) ON DELETE SET NULL
);

-- 2. Add index for fast lookups
CREATE INDEX IF NOT EXISTS idx_repair_notes_order ON repair_notes(repair_order_id);
CREATE INDEX IF NOT EXISTS idx_repair_notes_created ON repair_notes(created_at);

-- 3. Add audit trigger to the new table
CREATE TRIGGER audit_repair_notes_changes
    AFTER INSERT OR UPDATE OR DELETE ON repair_notes
    FOR EACH ROW EXECUTE FUNCTION tech.log_audit_changes();

-- 4. Strengthen existing relationships (add FKs if missing)
ALTER TABLE repair_order 
    ADD CONSTRAINT fk_repair_order_device 
    FOREIGN KEY (device_id) REFERENCES device(id) ON DELETE SET NULL;

ALTER TABLE repair_order 
    ADD CONSTRAINT fk_repair_order_technician 
    FOREIGN KEY (technician_id) REFERENCES technician(id) ON DELETE SET NULL;

ALTER TABLE device 
    ADD CONSTRAINT fk_device_customer 
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE;

\echo "New repair_notes table and relationship improvements applied successfully."
