-- Set schema to tech
SET search_path TO tech;

-- Insert 20 dummy customers
INSERT INTO customer (first_name, last_name, email, phone)
VALUES
('Alice', 'Johnson', 'alice.j@example.com', '555-1001'),
('Bob', 'Smith', 'bob.smith@example.com', '555-1002'),
('Carol', 'White', 'carol.w@example.com', '555-1003'),
('David', 'Brown', 'david.b@example.com', '555-1004'),
('Eve', 'Davis', 'eve.d@example.com', '555-1005'),
('Frank', 'Taylor', 'frank.t@example.com', '555-1006'),
('Grace', 'Evans', 'grace.e@example.com', '555-1007'),
('Hank', 'Wilson', 'hank.w@example.com', '555-1008'),
('Ivy', 'Martin', 'ivy.m@example.com', '555-1009'),
('Jack', 'Moore', 'jack.m@example.com', '555-1010'),
('Karen', 'Lewis', 'karen.l@example.com', '555-1011'),
('Leo', 'Clark', 'leo.c@example.com', '555-1012'),
('Mona', 'Walker', 'mona.w@example.com', '555-1013'),
('Nate', 'Hall', 'nate.h@example.com', '555-1014'),
('Olivia', 'Young', 'olivia.y@example.com', '555-1015'),
('Paul', 'Allen', 'paul.a@example.com', '555-1016'),
('Quinn', 'King', 'quinn.k@example.com', '555-1017'),
('Rachel', 'Scott', 'rachel.s@example.com', '555-1018'),
('Steve', 'Green', 'steve.g@example.com', '555-1019'),
('Tina', 'Baker', 'tina.b@example.com', '555-1020');

-- Insert dummy technicians
INSERT INTO technician (first_name, last_name, email, phone)
VALUES
('Tom', 'Miller', 'tom.m@example.com', '555-2001'),
('Sara', 'Lee', 'sara.l@example.com', '555-2002'),
('Jake', 'Wong', 'jake.w@example.com', '555-2003');

-- Insert dummy devices
INSERT INTO device (customer_id, device_type, brand, model, serial_no)
VALUES
(1, 'Laptop', 'Dell', 'XPS 13', 'DLXPS13-1001'),
(2, 'Phone', 'Apple', 'iPhone 13', 'APLIPH13-2002'),
(3, 'Tablet', 'Samsung', 'Galaxy Tab', 'SAMTAB-3003'),
(4, 'Laptop', 'HP', 'Spectre x360', 'HPSPEC-4004'),
(5, 'Phone', 'Google', 'Pixel 6', 'GPIX6-5005'),
(6, 'Desktop', 'Lenovo', 'ThinkCentre M720', 'LENM720-6006'),
(7, 'Tablet', 'Amazon', 'Fire HD 10', 'AMZHD10-7007'),
(8, 'Laptop', 'Asus', 'ZenBook 14', 'ASZEN14-8008'),
(9, 'Phone', 'OnePlus', '9 Pro', 'OP9PRO-9009'),
(10, 'Desktop', 'Acer', 'Aspire TC', 'ACETC-1010'),
(11, 'Laptop', 'MSI', 'GF63 Thin', 'MSIGF63-1111'),
(12, 'Tablet', 'Microsoft', 'Surface Go', 'MSGO-1212'),
(13, 'Phone', 'Samsung', 'Galaxy S22', 'SAMS22-1313'),
(14, 'Laptop', 'Apple', 'MacBook Pro', 'MBPRO-1414'),
(15, 'Desktop', 'HP', 'Pavilion', 'HPPAV-1515');

-- Insert dummy repair orders
INSERT INTO repair_order (device_id, technician_id, issue_description, resolution, serial_no, status)
VALUES
(1, 1, 'Screen flickering', 'Replaced screen cable', 'DLXPS13-1001', 'Closed'),
(2, 2, 'Battery draining quickly', 'Replaced battery', 'APLIPH13-2002', 'Closed'),
(3, 2, 'Not turning on', 'Replaced motherboard', 'SAMTAB-3003', 'In Progress'),
(4, 3, 'Overheating', 'Cleaned fan and reapplied thermal paste', 'HPSPEC-4004', 'Open'),
(5, 1, 'Camera not working', 'Replaced camera module', 'GPIX6-5005', 'Closed'),
(6, 1, 'Slow performance', 'Upgraded RAM', 'LENM720-6006', 'Closed'),
(7, 2, 'Cracked screen', 'Replaced screen', 'AMZHD10-7007', 'Closed'),
(8, 3, 'WiFi not working', 'Replaced wireless card', 'ASZEN14-8008', 'Open'),
(9, 3, 'No signal', 'Replaced antenna', 'OP9PRO-9009', 'In Progress'),
(10, 2, 'Loud fan noise', 'Replaced fan', 'ACETC-1010', 'Open');

-- Insert dummy parts used
INSERT INTO part_used (order_id, part_name, quantity, unit_cost)
VALUES
(1, 'Screen Cable', 1, 15.99),
(2, 'Battery', 1, 49.99),
(3, 'Motherboard', 1, 120.00),
(4, 'Thermal Paste', 1, 5.99),
(5, 'Camera Module', 1, 39.99),
(6, 'RAM 8GB', 1, 79.99),
(7, 'Screen Replacement', 1, 89.99),
(8, 'Wireless Card', 1, 29.99),
(9, 'Antenna', 1, 19.99),
(10, 'Cooling Fan', 1, 24.99);

-- Insert dummy user roles (linked to technician usernames)
INSERT INTO user_role (username, password, technician_id, role, created_at, updated_at)
VALUES
('tech_tom', 'pass123', 1, 'tech', CURRENT_DATE, CURRENT_DATE),
('tech_sara', 'pass123', 2, 'tech', CURRENT_DATE, CURRENT_DATE),
('tech_jake', 'pass123', 3, 'tech', CURRENT_DATE, CURRENT_DATE),
('admin_mary', 'admin123', 9999, 'admin', CURRENT_DATE, CURRENT_DATE),
('audit_alex', 'audit123', 9998, 'auditor', CURRENT_DATE, CURRENT_DATE);
