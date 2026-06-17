-- Set the schema to use
SET search_path TO tech;

-- =====================================================
-- Tech Repair Database - Maintenance and Performance Setup
-- =====================================================

-- ===================
-- INDEXING STRATEGY
-- ===================

-- Indexes for customer lookup
CREATE INDEX idx_customer_email ON tech.customer(email);
CREATE INDEX idx_customer_phone ON tech.customer(phone);
COMMENT ON INDEX tech.idx_customer_email IS 'Improves performance when searching customers by email address';
COMMENT ON INDEX tech.idx_customer_phone IS 'Improves performance when searching customers by phone number';

-- Indexes for repair order filtering and foreign keys
CREATE INDEX idx_repair_order_status ON tech.repair_order(status);
CREATE INDEX idx_repair_order_device ON tech.repair_order(device_id);
COMMENT ON INDEX tech.idx_repair_order_status IS 'Improves performance when filtering repair orders by status';
COMMENT ON INDEX tech.idx_repair_order_device IS 'Supports foreign key relationship to device table and joins between repairs and devices';

-- Indexes for device lookup and foreign keys
CREATE INDEX idx_device_serial ON tech.device(serial_no);
CREATE INDEX idx_device_customer ON tech.device(customer_id);
COMMENT ON INDEX tech.idx_device_serial IS 'Enhances device lookup by serial number';
COMMENT ON INDEX tech.idx_device_customer IS 'Supports foreign key relationship to customer table and joins between devices and customers';

-- Composite index for technician + status filters
CREATE INDEX idx_repair_technician_status ON tech.repair_order(technician_id, status);
COMMENT ON INDEX tech.idx_repair_technician_status IS 'Optimizes queries that filter by both technician and repair status';

-- Full-text search indexes
CREATE INDEX idx_device_model_gin ON tech.device USING gin(to_tsvector('english', model));
CREATE INDEX idx_repair_issue_gin ON tech.repair_order USING gin(to_tsvector('english', issue_description));
COMMENT ON INDEX tech.idx_device_model_gin IS 'Enables efficient full-text search on device models';
COMMENT ON INDEX tech.idx_repair_issue_gin IS 'Enables efficient full-text search on repair issue descriptions';

-- Index for part_used's most common join path
CREATE INDEX idx_part_used_order ON tech.part_used(order_id);
COMMENT ON INDEX tech.idx_part_used_order IS 'Supports foreign key relationship to repair_order table for reporting on parts used per repair';

-- ====================
-- MAINTENANCE FUNCTION
-- ====================

-- Creates a reusable maintenance procedure
CREATE OR REPLACE FUNCTION tech.perform_database_maintenance()
RETURNS void AS $$
BEGIN
  -- Analyze tables
  VACUUM ANALYZE tech.customer;
  VACUUM ANALYZE tech.device;
  VACUUM ANALYZE tech.repair_order;
  VACUUM ANALYZE tech.technician;
  VACUUM ANALYZE tech.part_used;
  VACUUM ANALYZE tech.user_role;

  -- Reindex for index health
  REINDEX TABLE tech.customer;
  REINDEX TABLE tech.device;
  REINDEX TABLE tech.repair_order;
  REINDEX TABLE tech.technician;
  REINDEX TABLE tech.part_used;
  REINDEX TABLE tech.user_role;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION tech.perform_database_maintenance() IS 'Runs routine database vacuuming and reindexing on tech schema tables.';

-- ====================
-- DOCUMENTATION NOTES
-- ====================

COMMENT ON DATABASE tech_repair_db IS 'Tech repair shop database with basic maintenance support.';

-- Maintenance tip banner
DO $$
BEGIN
  RAISE NOTICE '
  MAINTENANCE NOTES:
  ==================
  1. Run full maintenance using: SELECT tech.perform_database_maintenance();
  2. Monitor indexes with: SELECT * FROM pg_stat_user_indexes WHERE schemaname = ''tech'';
  3. Consider adding a regular ANALYZE routine if table updates grow over time.
  ';
END $$;


