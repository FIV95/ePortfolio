-- Database Enhancement: Richer Demo Data for API usability
-- Author: Frank Lawrence
-- Date: 2026-06-07
-- Purpose: Give non-technical API demos meaningful open repairs, costs, and notes

SET search_path TO tech;

-- Costs and priorities on existing repairs
UPDATE tech.repair_order SET total_cost = 149.99, priority = 'MEDIUM' WHERE id = 1;
UPDATE tech.repair_order SET total_cost = 89.50, priority = 'LOW' WHERE id = 2;
UPDATE tech.repair_order SET total_cost = 320.00, priority = 'HIGH' WHERE id = 3;
UPDATE tech.repair_order SET total_cost = 45.00, priority = 'MEDIUM' WHERE id = 4;
UPDATE tech.repair_order SET total_cost = 210.00, priority = 'HIGH', status = 'In Progress' WHERE id = 5;
UPDATE tech.repair_order SET total_cost = 175.00, priority = 'MEDIUM', status = 'Open' WHERE id = 6;
UPDATE tech.repair_order SET total_cost = 199.99, priority = 'MEDIUM' WHERE id = 7;
UPDATE tech.repair_order SET total_cost = 65.00, priority = 'LOW' WHERE id = 8;
UPDATE tech.repair_order SET total_cost = 55.00, priority = 'MEDIUM' WHERE id = 9;
UPDATE tech.repair_order SET total_cost = 95.00, priority = 'LOW' WHERE id = 10;

-- Give tech_tom (technician 1) visible active work — was all Closed before
UPDATE tech.repair_order SET status = 'Open', issue_description = 'Keyboard keys sticking'
    WHERE id = 1 AND technician_id = 1;

-- Sample repair notes (skip if already present)
INSERT INTO tech.repair_notes (repair_order_id, technician_id, note_text, note_type, created_by)
SELECT 1, 1, 'Customer reports issue started after spill.', 'CUSTOMER', 'tech_tom'
WHERE NOT EXISTS (SELECT 1 FROM tech.repair_notes WHERE repair_order_id = 1);

INSERT INTO tech.repair_notes (repair_order_id, technician_id, note_text, note_type, created_by)
SELECT 5, 1, 'Ordered replacement camera module.', 'PARTS', 'tech_tom'
WHERE NOT EXISTS (SELECT 1 FROM tech.repair_notes WHERE repair_order_id = 5 AND note_type = 'PARTS');

INSERT INTO tech.repair_notes (repair_order_id, technician_id, note_text, note_type, created_by)
SELECT 6, 1, 'RAM upgrade in progress — ETA tomorrow.', 'PROGRESS', 'tech_tom'
WHERE NOT EXISTS (SELECT 1 FROM tech.repair_notes WHERE repair_order_id = 6 AND note_type = 'PROGRESS');

REFRESH MATERIALIZED VIEW tech.technician_performance;
REFRESH MATERIALIZED VIEW tech.repair_aging;

\echo 'Demo data boost applied successfully.'