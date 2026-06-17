-- Database Enhancement: Rich Sample Data
-- Author: Frank Lawrence
-- Date: 2026-06-07
-- Purpose: Realistic shop volume for API demos, analytics, and role-based views

SET search_path TO tech;

-- ============================================================
-- 1. Technician profiles
-- ============================================================
UPDATE tech.technician SET
    specialty = 'Laptops & MacBooks',
    hourly_rate = 65.00,
    is_active = true
WHERE id = 1 AND specialty IS NULL;

UPDATE tech.technician SET
    specialty = 'Phones & Tablets',
    hourly_rate = 58.00,
    is_active = true
WHERE id = 2 AND specialty IS NULL;

UPDATE tech.technician SET
    specialty = 'Desktops & Gaming',
    hourly_rate = 62.00,
    is_active = true
WHERE id = 3 AND specialty IS NULL;

-- ============================================================
-- 2. Enrich existing customers
-- ============================================================
UPDATE tech.customer SET
    address = '42 Elm Street, Manchester, NH 03101',
    loyalty_points = 120
WHERE id = 1 AND loyalty_points = 0;

UPDATE tech.customer SET
    address = '18 Oak Avenue, Nashua, NH 03060',
    loyalty_points = 85
WHERE id = 2 AND loyalty_points = 0;

UPDATE tech.customer SET
    address = '7 Pine Road, Concord, NH 03301',
    loyalty_points = 200
WHERE id = 3 AND loyalty_points = 0;

UPDATE tech.customer SET
    address = '301 South Willow St, Manchester, NH 03103',
    loyalty_points = 45
WHERE id = 4 AND loyalty_points = 0;

UPDATE tech.customer SET
    address = '55 Lake Ave, Salem, NH 03079',
    loyalty_points = 310
WHERE id = 5 AND loyalty_points = 0;

UPDATE tech.customer SET loyalty_points = 60 + (id * 7) WHERE loyalty_points = 0;

UPDATE tech.customer
SET address_encrypted = tech.encrypt_text(address)
WHERE address IS NOT NULL
  AND address_encrypted IS NULL;

-- ============================================================
-- 3. New customers (skip if already loaded)
-- ============================================================
INSERT INTO tech.customer (first_name, last_name, email, phone, address, loyalty_points)
SELECT * FROM (VALUES
    ('Uma',   'Patel',    'uma.patel@example.com',    '603-555-1021', '9 Canal Street, Manchester, NH 03101', 140),
    ('Victor','Nguyen',   'victor.n@example.com',   '603-555-1022', '220 Main St, Nashua, NH 03060',        95),
    ('Wendy', 'Brooks',   'wendy.brooks@example.com', '603-555-1023', '14 West St, Keene, NH 03431',          175),
    ('Xavier','Coleman',  'xavier.c@example.com',   '603-555-1024', '88 Hanover St, Lebanon, NH 03766',     55),
    ('Yara',  'Fischer',  'yara.fischer@example.com', '603-555-1025', '3 Market St, Portsmouth, NH 03801',    220),
    ('Zane',  'Murphy',   'zane.murphy@example.com',  '603-555-1026', '61 Elm St, Dover, NH 03820',           30),
    ('Aiden', 'Reed',     'aiden.reed@example.com',   '603-555-1027', '102 Broadway, Derry, NH 03038',        110),
    ('Bella', 'Santos',   'bella.santos@example.com', '603-555-1028', '44 Central Ave, Rochester, NH 03867',  260),
    ('Caleb', 'Turner',   'caleb.turner@example.com', '603-555-1029', '12 Union St, Laconia, NH 03246',       75),
    ('Diana', 'Price',    'diana.price@example.com',  '603-555-1030', '77 Pleasant St, Claremont, NH 03743',  190),
    ('Ethan', 'Hayes',    'ethan.hayes@example.com',  '603-555-1031', '5 Court St, Exeter, NH 03833',         40),
    ('Fiona', 'Grant',    'fiona.grant@example.com',  '603-555-1032', '29 High St, Hampton, NH 03842',        155),
    ('Gavin', 'Porter',   'gavin.porter@example.com', '603-555-1033', '201 Main St, Littleton, NH 03561',     65),
    ('Holly', 'Barnes',   'holly.barnes@example.com', '603-555-1034', '8 Park Ave, Berlin, NH 03570',         300),
    ('Ian',   'Foster',   'ian.foster@example.com',   '603-555-1035', '16 Water St, Milford, NH 03055',       125)
) AS v(first_name, last_name, email, phone, address, loyalty_points)
WHERE NOT EXISTS (
    SELECT 1 FROM tech.customer WHERE email = 'uma.patel@example.com'
);

UPDATE tech.customer
SET address_encrypted = tech.encrypt_text(address)
WHERE email LIKE '%@example.com'
  AND address IS NOT NULL
  AND address_encrypted IS NULL;

-- ============================================================
-- 4. Additional devices (second devices + new customer devices)
-- ============================================================
INSERT INTO tech.device (customer_id, device_type, brand, model, serial_no)
SELECT * FROM (VALUES
    (1,  'Phone',   'Apple',     'iPhone 12',       'APLIPH12-1001B'),
    (2,  'Laptop',  'Lenovo',    'IdeaPad 5',       'LENID5-2002B'),
    (4,  'Phone',   'Samsung',   'Galaxy A54',      'SAMA54-4004B'),
    (6,  'Laptop',  'Dell',      'Latitude 5420',   'DLLAT5420-6006B'),
    (8,  'Tablet',  'Apple',     'iPad Air',        'APIPAIR-8008B'),
    (10, 'Phone',   'Google',    'Pixel 7a',        'GPIX7A-1010B'),
    (12, 'Desktop', 'CyberPower','Gamer Xtreme',    'CPGXT-1212B'),
    (14, 'Phone',   'Apple',     'iPhone 15 Pro',   'APLIPH15-1414B'),
    (16, 'Laptop',  'HP',        'Envy x360',       'HPENVY-1601'),
    (17, 'Phone',   'Samsung',   'Galaxy Z Flip',   'SAMZFLIP-1702'),
    (18, 'Desktop', 'Apple',     'iMac 24',         'APIMAC24-1803'),
    (19, 'Laptop',  'Asus',      'ROG Zephyrus',    'ASROGZ-1904'),
    (20, 'Phone',   'Motorola',  'Edge 40',         'MOTED40-2005'),
    (21, 'Laptop',  'Apple',     'MacBook Air M2',  'MBAIRM2-2106'),
    (22, 'Phone',   'Apple',     'iPhone 14',       'APLIPH14-2207'),
    (23, 'Tablet',  'Samsung',   'Galaxy Tab S9',   'SAMTABS9-2308'),
    (24, 'Laptop',  'MSI',       'Stealth 16',      'MSIST16-2409'),
    (25, 'Desktop', 'Dell',      'XPS Desktop',     'DLXPSDT-2510'),
    (26, 'Phone',   'OnePlus',   '12',              'OP12-2611'),
    (27, 'Laptop',  'Framework', 'Laptop 13',       'FWL13-2712'),
    (28, 'Phone',   'Samsung',   'Galaxy S24',      'SAMS24-2813'),
    (29, 'Desktop', 'HP',        'Omen 40L',        'HPOMEN-2914'),
    (30, 'Laptop',  'Lenovo',    'ThinkPad X1',     'LENX1-3015'),
    (31, 'Phone',   'Google',    'Pixel 8 Pro',     'GPIX8P-3116'),
    (32, 'Tablet',  'Microsoft', 'Surface Pro 9',   'MSSPRO9-3217'),
    (33, 'Laptop',  'Acer',      'Swift X',         'ACSWX-3318'),
    (34, 'Phone',   'Apple',     'iPhone SE',       'APLSE-3419'),
    (35, 'Desktop', 'Lenovo',    'Legion Tower',    'LENLEG-3520')
) AS v(customer_id, device_type, brand, model, serial_no)
WHERE NOT EXISTS (
    SELECT 1 FROM tech.device WHERE serial_no = 'APLIPH12-1001B'
);

-- ============================================================
-- 5. Repair orders — historical closed work (revenue history)
-- ============================================================
INSERT INTO tech.repair_order (
    device_id, technician_id, issue_description, resolution, serial_no,
    status, priority, total_cost, estimated_hours, created_at, closed_at
)
SELECT
    d.id, v.technician_id, v.issue_description, v.resolution, v.serial_no,
    'Closed', v.priority, v.total_cost, v.estimated_hours, v.created_at::timestamp, v.closed_at::timestamp
FROM (VALUES
    ('MBAIRM2-2106', 1, 'Liquid damage — keyboard not responding', 'Replaced top case assembly', 'RO-2026-011', 'HIGH',   489.00, 3.5, '2026-01-12', '2026-01-14'),
    ('APLIPH14-2207', 2, 'Shattered back glass', 'Replaced rear housing', 'RO-2026-012', 'MEDIUM', 229.00, 1.5, '2026-01-18', '2026-01-19'),
    ('SAMTABS9-2308',  2, 'Charging port loose', 'Soldered USB-C port', 'RO-2026-013', 'MEDIUM', 175.00, 2.0, '2026-01-22', '2026-01-23'),
    ('MSIST16-2409',   3, 'GPU artifacting under load', 'Reapplied thermal paste, cleaned fans', 'RO-2026-014', 'HIGH',   145.00, 2.5, '2026-02-03', '2026-02-04'),
    ('DLXPSDT-2510',   3, 'No POST after power surge', 'Replaced PSU and tested RAM', 'RO-2026-015', 'HIGH',   310.00, 4.0, '2026-02-08', '2026-02-10'),
    ('OP12-2611',      2, 'Face ID not working', 'Replaced front sensor module', 'RO-2026-016', 'MEDIUM', 265.00, 2.0, '2026-02-14', '2026-02-15'),
    ('FWL13-2712',     1, 'Battery swelling', 'Replaced battery and inspected board', 'RO-2026-017', 'HIGH',   195.00, 1.5, '2026-02-20', '2026-02-21'),
    ('SAMS24-2813',    2, 'Green line on display', 'Replaced OLED panel', 'RO-2026-018', 'HIGH',   349.00, 2.5, '2026-03-01', '2026-03-03'),
    ('HPOMEN-2914',    3, 'Random shutdowns while gaming', 'Updated BIOS, replaced VRM thermal pads', 'RO-2026-019', 'MEDIUM', 185.00, 3.0, '2026-03-07', '2026-03-08'),
    ('LENX1-3015',     1, 'Trackpad clicks not registering', 'Replaced trackpad module', 'RO-2026-020', 'LOW',    155.00, 1.5, '2026-03-12', '2026-03-13'),
    ('GPIX8P-3116',    2, 'Boot loop after update', 'Flashed firmware, cleared cache', 'RO-2026-021', 'MEDIUM', 95.00,  1.0, '2026-03-18', '2026-03-18'),
    ('MSSPRO9-3217',   1, 'Type cover keys repeating', 'Replaced type cover', 'RO-2026-022', 'LOW',    129.00, 0.5, '2026-03-22', '2026-03-22'),
    ('ACSWX-3318',     1, 'Blue screen — driver conflict', 'Reinstalled GPU drivers, ran diagnostics', 'RO-2026-023', 'MEDIUM', 110.00, 1.5, '2026-04-02', '2026-04-03'),
    ('APLSE-3419',     2, 'Home button intermittent', 'Replaced home button flex', 'RO-2026-024', 'LOW',    89.00,  1.0, '2026-04-08', '2026-04-09'),
    ('LENLEG-3520',    3, 'RGB fans not spinning', 'Replaced fan controller hub', 'RO-2026-025', 'MEDIUM', 140.00, 2.0, '2026-04-14', '2026-04-15'),
    ('APLIPH12-1001B', 2, 'Speaker crackling on calls', 'Replaced earpiece speaker', 'RO-2026-026', 'LOW',    75.00,  1.0, '2026-04-20', '2026-04-20'),
    ('LENID5-2002B',   1, 'Hinge stiff — risk of screen damage', 'Lubricated and adjusted hinges', 'RO-2026-027', 'MEDIUM', 85.00,  1.0, '2026-04-25', '2026-04-26'),
    ('APIPAIR-8008B',  2, 'Touchscreen ghost touches', 'Replaced digitizer', 'RO-2026-028', 'HIGH',   245.00, 2.0, '2026-05-02', '2026-05-04'),
    ('CPGXT-1212B',    3, 'No display output on GPU', 'Reseated GPU, replaced DisplayPort cable', 'RO-2026-029', 'HIGH',   120.00, 2.0, '2026-05-08', '2026-05-09'),
    ('HPENVY-1601',    1, 'Fingerprint reader failed', 'Replaced power button/fingerprint assembly', 'RO-2026-030', 'MEDIUM', 165.00, 1.5, '2026-05-14', '2026-05-15')
) AS v(device_serial, technician_id, issue_description, resolution, serial_no, priority, total_cost, estimated_hours, created_at, closed_at)
JOIN tech.device d ON d.serial_no = v.device_serial
WHERE NOT EXISTS (
    SELECT 1 FROM tech.repair_order WHERE serial_no = 'RO-2026-011'
);

-- ============================================================
-- 6. Active shop floor — open & in-progress repairs
-- ============================================================
INSERT INTO tech.repair_order (
    device_id, technician_id, issue_description, resolution, serial_no,
    status, priority, total_cost, estimated_hours, created_at
)
SELECT
    d.id, v.technician_id, v.issue_description, NULL, v.serial_no,
    v.status, v.priority, v.total_cost, v.estimated_hours, v.created_at::timestamp
FROM (VALUES
    ('SAMA54-4004B',   2, 'Open',        'Phone not charging past 12%',           'RO-2026-031', 'HIGH',   115.00, 1.5, '2026-05-20'),
    ('DLLAT5420-6006B',1, 'In Progress', 'Intermittent black screen on wake',     'RO-2026-032', 'HIGH',   220.00, 3.0, '2026-05-22'),
    ('GPIX7A-1010B',   2, 'Open',        'Rear camera blurry',                    'RO-2026-033', 'MEDIUM',  95.00, 1.0, '2026-05-24'),
    ('APIMAC24-1803',  1, 'In Progress', 'iMac fan running loud at idle',         'RO-2026-034', 'MEDIUM', 135.00, 2.0, '2026-05-26'),
    ('ASROGZ-1904',    3, 'Open',        'Liquid metal needed — overheating',     'RO-2026-035', 'HIGH',   275.00, 4.0, '2026-05-27'),
    ('MOTED40-2005',   2, 'In Progress', 'SIM tray stuck, no cellular',           'RO-2026-036', 'MEDIUM',  80.00, 1.0, '2026-05-28'),
    ('SAMZFLIP-1702',  2, 'Open',        'Fold crease showing dead pixels',       'RO-2026-037', 'HIGH',   410.00, 3.5, '2026-05-29'),
    ('APLIPH15-1414B', 2, 'In Progress', 'Back glass cracked, wireless charging dead', 'RO-2026-045', 'HIGH', 285.00, 2.0, '2026-06-06'),
    ('MBPRO-1414',     1, 'Open',        'Data recovery — won''t boot to macOS',  'RO-2026-047', 'HIGH',   395.00, 5.0, '2026-06-07'),
    ('MSIGF63-1111',   3, 'Open',        'Keyboard backlight dead',               'RO-2026-048', 'LOW',     70.00, 1.0, '2026-06-07'),
    ('MSGO-1212',      1, 'In Progress', 'Battery drains in under 2 hours',       'RO-2026-049', 'MEDIUM', 125.00, 1.5, '2026-06-07'),
    ('SAMS22-1313',    2, 'Open',        'Water damage — power button sticky',    'RO-2026-050', 'HIGH',   340.00, 3.0, '2026-06-07')
) AS v(device_serial, technician_id, status, issue_description, serial_no, priority, total_cost, estimated_hours, created_at)
JOIN tech.device d ON d.serial_no = v.device_serial
WHERE NOT EXISTS (
    SELECT 1 FROM tech.repair_order WHERE serial_no = 'RO-2026-031'
);

-- Enrich original seed repairs with realistic active-shop details
UPDATE tech.repair_order SET
    status = 'In Progress',
    issue_description = 'Keyboard keys sticking after coffee spill',
    total_cost = 149.99,
    priority = 'MEDIUM',
    created_at = '2026-05-30 09:15:00'
WHERE serial_no = 'DLXPS13-1001';

UPDATE tech.repair_order SET
    status = 'In Progress',
    issue_description = 'Tablet won''t power on — possible board issue',
    total_cost = 320.00,
    priority = 'HIGH',
    created_at = '2026-06-06 08:00:00'
WHERE serial_no = 'SAMTAB-3003';

UPDATE tech.repair_order SET
    status = 'Open',
    issue_description = 'Laptop overheating under light use',
    total_cost = 45.00,
    priority = 'MEDIUM',
    created_at = '2026-05-31 10:00:00'
WHERE serial_no = 'HPSPEC-4004';

UPDATE tech.repair_order SET
    status = 'In Progress',
    issue_description = 'Rear camera blurry after drop',
    total_cost = 210.00,
    priority = 'HIGH',
    created_at = '2026-06-01 11:00:00'
WHERE serial_no = 'GPIX6-5005';

UPDATE tech.repair_order SET
    status = 'Open',
    issue_description = 'Slow performance — possible malware',
    total_cost = 175.00,
    priority = 'MEDIUM',
    created_at = '2026-06-02 08:30:00'
WHERE serial_no = 'LENM720-6006';

UPDATE tech.repair_order SET
    status = 'Open',
    total_cost = 65.00,
    priority = 'LOW',
    created_at = '2026-06-03 09:00:00'
WHERE serial_no = 'ASZEN14-8008';

UPDATE tech.repair_order SET
    status = 'In Progress',
    total_cost = 55.00,
    created_at = '2026-06-04 14:00:00'
WHERE serial_no = 'OP9PRO-9009';

UPDATE tech.repair_order SET
    status = 'Open',
    total_cost = 95.00,
    created_at = '2026-06-05 08:45:00'
WHERE serial_no = 'ACETC-1010';

-- ============================================================
-- 7. Parts used on new repairs
-- ============================================================
INSERT INTO tech.part_used (order_id, part_name, quantity, unit_cost)
SELECT ro.id, v.part_name, v.quantity, v.unit_cost
FROM (VALUES
    ('RO-2026-011', 'Top Case Assembly', 1, 320.00),
    ('RO-2026-011', 'Labor — liquid damage', 1, 169.00),
    ('RO-2026-012', 'Rear Glass Kit', 1, 189.00),
    ('RO-2026-013', 'USB-C Port', 1, 45.00),
    ('RO-2026-014', 'Thermal Paste', 1, 12.00),
    ('RO-2026-015', '750W PSU', 1, 110.00),
    ('RO-2026-018', 'OLED Display', 1, 280.00),
    ('RO-2026-031', 'Charging Flex Cable', 1, 35.00),
    ('RO-2026-032', 'LVDS Display Cable', 1, 48.00),
    ('RO-2026-035', 'Liquid Metal Kit', 1, 25.00),
    ('RO-2026-037', 'Fold Display Assembly', 1, 340.00),
    ('GPIX6-5005', 'Rear Camera Module', 1, 65.00),
    ('RO-2026-045', 'Back Glass + MagSafe Coil', 1, 210.00),
    ('RO-2026-047', 'Data Recovery Service', 1, 395.00),
    ('RO-2026-050', 'Charging Port + Cleaning', 1, 85.00)
) AS v(repair_serial, part_name, quantity, unit_cost)
JOIN tech.repair_order ro ON ro.serial_no = v.repair_serial
WHERE NOT EXISTS (
    SELECT 1 FROM tech.part_used pu
    JOIN tech.repair_order ro2 ON ro2.id = pu.order_id
    WHERE ro2.serial_no = 'RO-2026-011'
);

-- ============================================================
-- 8. Repair notes — realistic conversation threads
-- ============================================================
INSERT INTO tech.repair_notes (repair_order_id, technician_id, note_text, note_type, created_by, created_at)
SELECT ro.id, v.technician_id, v.note_text, v.note_type, v.created_by, v.created_at::timestamp
FROM (VALUES
    ('DLXPS13-1001', 1, 'Customer reports issue started after spill on left side.', 'CUSTOMER', 'cs_jordan', '2026-05-30 10:00:00'),
    ('DLXPS13-1001', 1, 'Removed keyboard deck, found minor corrosion.', 'PROGRESS', 'tech_tom', '2026-05-30 14:20:00'),
    ('DLXPS13-1001', 1, 'Need to replace keyboard assembly — ETA 2 days.', 'PARTS', 'tech_tom', '2026-05-31 09:00:00'),
    ('GPIX6-5005', 1, 'Caller says camera failed after beach trip.', 'CUSTOMER', 'cs_jordan', '2026-06-01 11:30:00'),
    ('GPIX6-5005', 1, 'Ordered replacement camera module.', 'PARTS', 'tech_tom', '2026-06-01 15:00:00'),
    ('GPIX6-5005', 1, 'Part arrived — scheduling install tomorrow.', 'PROGRESS', 'tech_tom', '2026-06-06 10:15:00'),
    ('LENM720-6006', 1, 'Customer approved malware scan and cleanup.', 'CUSTOMER', 'cs_jordan', '2026-06-02 09:00:00'),
    ('LENM720-6006', 1, 'Found PUPs and browser hijacker — removing.', 'PROGRESS', 'tech_tom', '2026-06-02 13:45:00'),
    ('RO-2026-047', 1, 'Customer needs photos recovered before erase.', 'CUSTOMER', 'cs_jordan', '2026-06-07 08:00:00'),
    ('RO-2026-047', 1, 'Target drive mounted externally — cloning in progress.', 'PROGRESS', 'tech_tom', '2026-06-07 11:30:00'),
    ('RO-2026-032', 1, 'Reproduced black screen — testing lid sensor next.', 'PROGRESS', 'tech_tom', '2026-05-23 16:00:00'),
    ('RO-2026-034', 1, 'Dust buildup in fan assembly confirmed.', 'PROGRESS', 'tech_tom', '2026-05-27 10:00:00'),
    ('RO-2026-049', 1, 'Battery health at 68% — recommending replacement.', 'RESOLUTION', 'tech_tom', '2026-06-07 09:45:00'),
    ('RO-2026-031', 2, 'Customer dropped phone — charging intermittent.', 'CUSTOMER', 'cs_jordan', '2026-05-20 13:00:00'),
    ('RO-2026-031', 2, 'Flex cable shows micro-fractures.', 'PROGRESS', 'tech_sara', '2026-05-21 10:30:00'),
    ('RO-2026-037', 2, 'Fold display line expanding — quoted $410.', 'CUSTOMER', 'cs_jordan', '2026-05-29 14:00:00'),
    ('RO-2026-037', 2, 'Customer approved repair — ordering panel.', 'PARTS', 'tech_sara', '2026-05-30 09:00:00'),
    ('SAMTAB-3003', 2, 'No power — board-level short suspected.', 'PROGRESS', 'tech_sara', '2026-06-06 15:00:00'),
    ('RO-2026-050', 2, 'Corrosion around charging port cleaned.', 'PROGRESS', 'tech_sara', '2026-06-07 12:00:00'),
    ('RO-2026-045', 2, 'Wireless charging coil damaged with glass.', 'PROGRESS', 'tech_sara', '2026-06-06 17:00:00'),
    ('RO-2026-035', 3, 'CPU hitting 98C in Cinebench — repaste scheduled.', 'PROGRESS', 'tech_jake', '2026-05-28 11:00:00'),
    ('HPSPEC-4004', 3, 'Fan vents clogged — cleaned and tested.', 'PROGRESS', 'tech_jake', '2026-06-01 09:30:00'),
    ('ASZEN14-8008', 3, 'WiFi card not detected — ordered replacement.', 'PARTS', 'tech_jake', '2026-06-03 14:00:00'),
    ('OP9PRO-9009', 3, 'Antenna cable disconnected internally.', 'PROGRESS', 'tech_jake', '2026-06-04 16:30:00'),
    ('ACETC-1010', 2, 'Customer complains fan loud every morning.', 'CUSTOMER', 'cs_jordan', '2026-06-05 08:50:00'),
    ('ACETC-1010', 2, 'Fan bearing worn — replacement ordered.', 'PARTS', 'tech_sara', '2026-06-05 15:00:00'),
    ('RO-2026-048', 3, 'LED ribbon cable loose — reseated.', 'RESOLUTION', 'tech_jake', '2026-06-07 13:15:00'),
    ('RO-2026-011', 1, 'Repair completed — customer picked up.', 'RESOLUTION', 'tech_tom', '2026-01-14 16:00:00'),
    ('RO-2026-018', 2, 'Display replaced and calibrated.', 'RESOLUTION', 'tech_sara', '2026-03-03 11:00:00'),
    ('RO-2026-025', 3, 'Fan hub replaced — RGB restored.', 'RESOLUTION', 'tech_jake', '2026-04-15 15:30:00')
) AS v(repair_serial, technician_id, note_text, note_type, created_by, created_at)
JOIN tech.repair_order ro ON ro.serial_no = v.repair_serial
WHERE NOT EXISTS (
    SELECT 1 FROM tech.repair_notes n
    JOIN tech.repair_order ro2 ON ro2.id = n.repair_order_id
    WHERE ro2.serial_no = 'DLXPS13-1001'
      AND n.note_type = 'CUSTOMER'
      AND n.created_by = 'cs_jordan'
);

-- Extra notes on original low-note repairs
INSERT INTO tech.repair_notes (repair_order_id, technician_id, note_text, note_type, created_by, created_at)
SELECT ro.id, 1, 'Need to replace keyboard', 'PARTS', 'tech_tom', '2026-06-07 06:15:08'
FROM tech.repair_order ro
WHERE ro.id = 1
  AND NOT EXISTS (SELECT 1 FROM tech.repair_notes WHERE repair_order_id = 1 AND note_type = 'PARTS');

-- ============================================================
-- 9. Refresh analytics views
-- ============================================================
REFRESH MATERIALIZED VIEW tech.technician_performance;
REFRESH MATERIALIZED VIEW tech.repair_aging;

\echo 'Rich sample data applied successfully.'