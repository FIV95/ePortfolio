-- Set schema path
SET search_path TO tech;

-- =========================
-- BASIC QUERIES
-- =========================

-- 1. Get a list of all customers
SELECT * FROM customer;
-- Returns all customer records with contact info.

-- 2. Get devices owned by a specific customer (e.g., customer ID 1)
SELECT * FROM device WHERE customer_id = 1;
-- Shows all devices registered to customer #1.

-- 3. List all open repair orders
SELECT * FROM repair_order WHERE status = 'Open';
-- Displays repair orders that are currently active and not yet resolved.

-- =========================
-- INTERMEDIATE QUERIES (JOINS)
-- =========================

-- 4. List customer names with their devices
SELECT c.first_name, c.last_name, d.device_type, d.brand, d.model
FROM customer c
JOIN device d ON c.id = d.customer_id;
-- Joins customer and device tables to show who owns which devices.

-- 5. Get repair orders along with device and technician info
SELECT r.id AS order_id, d.serial_no, t.first_name AS tech_first, t.last_name AS tech_last, r.status
FROM repair_order r
JOIN device d ON r.device_id = d.id
JOIN technician t ON r.technician_id = t.id;
-- Shows repair order details including which tech handled which device.

-- 6. Show parts used in each repair order
SELECT r.id AS order_id, p.part_name, p.quantity, p.unit_cost
FROM repair_order r
JOIN part_used p ON r.id = p.order_id;
-- Lists each repair with parts consumed and their cost.

-- =========================
-- ADVANCED QUERIES
-- =========================

-- 7. Count how many devices each customer owns
SELECT c.id, c.first_name, c.last_name, COUNT(d.id) AS total_devices
FROM customer c
LEFT JOIN device d ON c.id = d.customer_id
GROUP BY c.id;
-- Uses aggregation to count how many devices each customer owns.

-- 8. Get total repair cost per order
SELECT r.id AS order_id, SUM(p.quantity * p.unit_cost) AS total_cost
FROM repair_order r
JOIN part_used p ON r.id = p.order_id
GROUP BY r.id;
-- Calculates total cost of parts used in each repair order.

-- 9. List all repairs completed by each technician
SELECT t.first_name, t.last_name, COUNT(r.id) AS closed_repairs
FROM technician t
JOIN repair_order r ON t.id = r.technician_id
WHERE r.status = 'Closed'
GROUP BY t.id;
-- Finds how many repairs each technician has successfully closed.

-- 10.Find the customer who spent the most on repairs
SELECT 
    c.id AS customer_id,
    c.first_name,
    c.last_name,
    SUM(p.quantity * p.unit_cost) AS total_spent
FROM customer c
JOIN device d ON c.id = d.customer_id
JOIN repair_order r ON d.id = r.device_id
JOIN part_used p ON r.id = p.order_id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 1;


-- 11. Average cost of repairs per technician (only Closed)
SELECT 
    t.first_name || ' ' || t.last_name AS technician,
    ROUND(AVG(p.quantity * p.unit_cost), 2) AS avg_cost_per_repair
FROM technician t
JOIN repair_order r ON t.id = r.technician_id
JOIN part_used p ON r.id = p.order_id
WHERE r.status = 'Closed'
GROUP BY technician;
-- Shows average part cost across repairs per tech (closed orders only).

-- 12. Show repair orders and customer info where status is not 'Closed'
SELECT r.id AS order_id, r.status, c.first_name, c.last_name
FROM repair_order r
JOIN device d ON r.device_id = d.id
JOIN customer c ON d.customer_id = c.id
WHERE r.status != 'Closed';
-- Combines repair, device, and customer data for open/in-progress jobs.
