-- Enable UUID extension if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  phone VARCHAR(15) UNIQUE NOT NULL,
  email VARCHAR(100),
  role VARCHAR(20) DEFAULT 'customer', -- 'customer', 'admin', 'agent'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Addresses Table
CREATE TABLE IF NOT EXISTS addresses (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  address_line_1 VARCHAR(255) NOT NULL,
  address_line_2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100) NOT NULL,
  pincode VARCHAR(10) NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_default BOOLEAN DEFAULT false,
  tag VARCHAR(20) DEFAULT 'Home', -- 'Home', 'Work', 'Other'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Services Table
CREATE TABLE IF NOT EXISTS services (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  image TEXT,
  status VARCHAR(20) DEFAULT 'active' -- 'active', 'inactive'
);

-- Items Table (Clothes types)
CREATE TABLE IF NOT EXISTS items (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  category VARCHAR(50) NOT NULL, -- 'Men', 'Women', 'Kids', 'Household'
  image TEXT
);

-- Service Pricing Table
CREATE TABLE IF NOT EXISTS service_pricing (
  id SERIAL PRIMARY KEY,
  service_id INTEGER REFERENCES services(id) ON DELETE CASCADE,
  item_id INTEGER REFERENCES items(id) ON DELETE CASCADE,
  price DECIMAL(10, 2) NOT NULL,
  CONSTRAINT unique_service_item UNIQUE (service_id, item_id)
);

-- Coupons Table
CREATE TABLE IF NOT EXISTS coupons (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  discount_type VARCHAR(20) NOT NULL, -- 'flat', 'percentage'
  discount_value DECIMAL(10, 2) NOT NULL,
  min_order_value DECIMAL(10, 2) DEFAULT 0.00,
  expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'inactive'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  pickup_address_id INTEGER REFERENCES addresses(id) ON DELETE SET NULL,
  pickup_date DATE NOT NULL,
  pickup_time_slot VARCHAR(50) NOT NULL,
  delivery_preference VARCHAR(30) DEFAULT 'standard', -- 'standard', 'express', 'same_day'
  delivery_date DATE,
  status VARCHAR(30) DEFAULT 'created',
  -- 'created', 'pickup_scheduled', 'pickup_completed', 'processing', 'washing', 'drying', 'ironing', 'quality_check', 'ready_for_delivery', 'out_for_delivery', 'delivered'
  total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(10, 2) DEFAULT 0.00,
  delivery_charges DECIMAL(10, 2) DEFAULT 0.00,
  tax_amount DECIMAL(10, 2) DEFAULT 0.00,
  grand_total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  coupon_code VARCHAR(50),
  payment_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'paid', 'failed', 'refunded'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
  id SERIAL PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
  item_id INTEGER REFERENCES items(id) ON DELETE RESTRICT,
  service_id INTEGER REFERENCES services(id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL
);

-- Payments Table
CREATE TABLE IF NOT EXISTS payments (
  id SERIAL PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
  payment_gateway VARCHAR(50) DEFAULT 'razorpay', -- 'razorpay', 'cod'
  transaction_id VARCHAR(100),
  payment_id VARCHAR(100),
  signature VARCHAR(255),
  amount DECIMAL(10, 2) NOT NULL,
  status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'captured', 'failed', 'refunded'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'unread', -- 'unread', 'read'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------
-- Seed Data Initialization
-- ----------------------------------------------------

-- Seed User (Admin default)
INSERT INTO users (name, phone, email, role)
VALUES ('Admin India', '+919999999999', 'admin@laundryapp.in', 'admin')
ON CONFLICT (phone) DO UPDATE SET role = 'admin', name = 'Admin India';

-- Seed Services
INSERT INTO services (id, name, description, image, status) VALUES
(1, 'Washing & Fold', 'Get your everyday clothes thoroughly washed, clean, and neatly folded.', 'https://images.unsplash.com/photo-1545173168-9f19472ef7f4?w=500&auto=format&fit=crop&q=60', 'active'),
(2, 'Dry Cleaning', 'Premium care for suits, sarees, blazers, jackets, and delicate fabrics.', 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=500&auto=format&fit=crop&q=60', 'active'),
(3, 'Steam Pressing', 'Crisp steam ironing and pressing to keep your outfits wrinkle-free.', 'https://images.unsplash.com/photo-1525971977907-22d555db64c0?w=500&auto=format&fit=crop&q=60', 'active')
ON CONFLICT (id) DO NOTHING;

-- Seed Items
INSERT INTO items (id, name, category, image) VALUES
(1, 'Shirt', 'Men', 'https://images.unsplash.com/photo-1620012253295-c05518e993be?w=100&q=80'),
(2, 'Saree', 'Women', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=100&q=80'),
(3, 'Suit', 'Men', 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=100&q=80'),
(4, 'Jeans', 'Men', 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=100&q=80'),
(5, 'Blanket / Quilt', 'Household', 'https://images.unsplash.com/photo-1580301762395-21ce84d00bc6?w=100&q=80'),
(6, 'Curtains (per pane)', 'Household', 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=100&q=80'),
(7, 'T-Shirt', 'Men', 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=100&q=80'),
(8, 'Jacket', 'Men', 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=100&q=80'),
(9, 'Blazer', 'Men', 'https://images.unsplash.com/photo-1592878904946-b3cd8ae243d0?w=100&q=80'),
(10, 'Dress (One piece)', 'Women', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=100&q=80'),
(11, 'Kurtis / Salwar', 'Women', 'https://images.unsplash.com/photo-1608748010899-18f300247112?w=100&q=80')
ON CONFLICT (id) DO NOTHING;

-- Seed Service Pricing (Washing, id = 1)
INSERT INTO service_pricing (service_id, item_id, price) VALUES
(1, 1, 20.00),  -- Shirt Washing
(1, 2, 50.00),  -- Saree Washing
(1, 3, 120.00), -- Suit Washing
(1, 4, 30.00),  -- Jeans Washing
(1, 5, 120.00), -- Blanket Washing
(1, 6, 80.00),  -- Curtains Washing
(1, 7, 20.00),  -- T-Shirt Washing
(1, 8, 80.00),  -- Jacket Washing
(1, 9, 90.00),  -- Blazer Washing
(1, 10, 45.00), -- Dress Washing
(1, 11, 35.00)  -- Kurtis Washing
ON CONFLICT (service_id, item_id) DO UPDATE SET price = EXCLUDED.price;

-- Seed Service Pricing (Dry Cleaning, id = 2)
INSERT INTO service_pricing (service_id, item_id, price) VALUES
(2, 1, 60.00),  -- Shirt Dry Cleaning
(2, 2, 150.00), -- Saree Dry Cleaning
(2, 3, 280.00), -- Suit Dry Cleaning
(2, 4, 80.00),  -- Jeans Dry Cleaning
(2, 5, 250.00), -- Blanket Dry Cleaning
(2, 6, 180.00), -- Curtains Dry Cleaning
(2, 7, 50.00),  -- T-Shirt Dry Cleaning
(2, 8, 160.00), -- Jacket Dry Cleaning
(2, 9, 180.00), -- Blazer Dry Cleaning
(2, 10, 150.00),-- Dress Dry Cleaning
(2, 11, 110.00) -- Kurtis Dry Cleaning
ON CONFLICT (service_id, item_id) DO UPDATE SET price = EXCLUDED.price;

-- Seed Service Pricing (Steam Pressing, id = 3)
INSERT INTO service_pricing (service_id, item_id, price) VALUES
(3, 1, 10.00),  -- Shirt Steam Pressing
(3, 2, 30.00),  -- Saree Steam Pressing
(3, 3, 80.00),  -- Suit Steam Pressing
(3, 4, 15.00),  -- Jeans Steam Pressing
(3, 5, 50.00),  -- Blanket Steam Pressing
(3, 6, 40.00),  -- Curtains Steam Pressing
(3, 7, 10.00),  -- T-Shirt Steam Pressing
(3, 8, 40.00),  -- Jacket Steam Pressing
(3, 9, 45.00),  -- Blazer Steam Pressing
(3, 10, 30.00), -- Dress Steam Pressing
(3, 11, 20.00)  -- Kurtis Steam Pressing
ON CONFLICT (service_id, item_id) DO UPDATE SET price = EXCLUDED.price;

-- Seed Coupons
INSERT INTO coupons (code, discount_type, discount_value, min_order_value, expiry_date, status) VALUES
('WELCOME50', 'flat', 50.00, 200.00, '2027-12-31 23:59:59+05:30', 'active'),
('FIRSTORDER', 'percentage', 20.00, 300.00, '2027-12-31 23:59:59+05:30', 'active'),
('FESTIVE30', 'percentage', 30.00, 500.00, '2027-12-31 23:59:59+05:30', 'active')
ON CONFLICT (code) DO UPDATE SET discount_value = EXCLUDED.discount_value, min_order_value = EXCLUDED.min_order_value, expiry_date = EXCLUDED.expiry_date, status = EXCLUDED.status;
