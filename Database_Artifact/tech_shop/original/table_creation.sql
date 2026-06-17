create schema tech;
set search_path to tech;

-- Customers table
CREATE TABLE customer (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    phone VARCHAR(200) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP DEFAULT CURRENT_DATE
);

-- Devices table
CREATE TABLE device (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customer(id),
    device_type VARCHAR(150) NOT NULL,
    brand VARCHAR(200),
    model VARCHAR(200),
    serial_no TEXT UNIQUE,
    status TEXT DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP DEFAULT CURRENT_DATE
);

-- Technicians table
CREATE TABLE technician (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    phone VARCHAR(200) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP DEFAULT CURRENT_DATE
);

-- Repair Orders table
CREATE TABLE repair_order (
    id SERIAL PRIMARY KEY,
    device_id INTEGER REFERENCES device(id),
    technician_id INTEGER REFERENCES technician(id),
    issue_description TEXT,
    resolution TEXT,
    serial_no TEXT UNIQUE,
    status TEXT NOT NULL DEFAULT 'OPEN',
    created_at TIMESTAMP DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP DEFAULT CURRENT_DATE,
    closed_at TIMESTAMP DEFAULT CURRENT_DATE
);

-- Parts Used table
CREATE TABLE part_used (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES repair_order(id) ON DELETE CASCADE,
    part_name VARCHAR(200) NOT NULL,
    quantity INT CHECK (quantity > 0),
    unit_cost NUMERIC(10,2) CHECK (unit_cost >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP DEFAULT CURRENT_DATE
);

-- User Role table
CREATE TABLE user_role (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(100) NOT NULL,
    technician_id VARCHAR(200) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'tech', 'auditor')),
    created_at DATE,
    updated_at DATE
);
