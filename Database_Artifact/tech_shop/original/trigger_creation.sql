-- Set schema path
SET search_path TO tech;


-- Creating Trigger Function for Timestamps
CREATE OR REPLACE FUNCTION set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Implementing Trigger for each Table

--Customer Table
CREATE TRIGGER trigger_update_customer
BEFORE UPDATE ON customer
FOR EACH ROW
EXECUTE FUNCTION set_timestamp();


--Device Table
CREATE TRIGGER trigger_update_device
BEFORE UPDATE ON device
FOR EACH ROW
EXECUTE FUNCTION set_timestamp();

--Repair_Order Table
CREATE TRIGGER trigger_update_repair_orders
BEFORE UPDATE ON repair_order
FOR EACH ROW
EXECUTE FUNCTION set_timestamp();

--Part_Used Table
CREATE TRIGGER trigger_update_parts_used
BEFORE UPDATE ON part_used
FOR EACH ROW
EXECUTE FUNCTION set_timestamp();

--Technician Table
CREATE TRIGGER trigger_update_technician
BEFORE UPDATE ON technician
FOR EACH ROW
EXECUTE FUNCTION set_timestamp();

-- User_Role Table
CREATE TRIGGER trigger_update_user_role
BEFORE UPDATE ON user_role
FOR EACH ROW
EXECUTE FUNCTION set_timestamp();

-- Creating Trigger for closed_at
CREATE OR REPLACE FUNCTION set_closed_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   IF NEW.status = 'Closed' AND OLD.status IS DISTINCT FROM 'Closed' THEN
      NEW.closed_at = NOW();
   END IF;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Implementing closed_at Trigger for repair_orders
CREATE TRIGGER trigger_closed_at_repair
BEFORE UPDATE ON repair_order
FOR EACH ROW
EXECUTE FUNCTION set_closed_timestamp();