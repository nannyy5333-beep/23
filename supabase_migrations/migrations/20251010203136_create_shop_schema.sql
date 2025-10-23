/*
  # Create Telegram Shop Bot Database Schema

  1. New Tables
    - `users` - User profiles with Telegram IDs
      - `id` (uuid, primary key)
      - `telegram_id` (bigint, unique, indexed)
      - `name` (text)
      - `phone` (text)
      - `email` (text)
      - `language` (text, default 'ru')
      - `is_admin` (boolean, default false)
      - `role` (text)
      - `acquisition_channel` (text)
      - `created_at` (timestamptz)
    
    - `categories` - Product categories
      - `id` (uuid, primary key)
      - `name` (text, not null)
      - `description` (text)
      - `emoji` (text)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz)
    
    - `subcategories` - Product subcategories/brands
      - `id` (uuid, primary key)
      - `name` (text, not null)
      - `category_id` (uuid, foreign key)
      - `emoji` (text)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz)
    
    - `products` - Products catalog
      - `id` (uuid, primary key)
      - `name` (text, not null)
      - `description` (text)
      - `price` (numeric, not null)
      - `category_id` (uuid, foreign key)
      - `subcategory_id` (uuid, foreign key)
      - `brand` (text)
      - `image_url` (text)
      - `stock` (integer, default 0)
      - `views` (integer, default 0)
      - `sales_count` (integer, default 0)
      - `is_active` (boolean, default true)
      - `cost_price` (numeric, default 0)
      - `original_price` (numeric)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `product_images` - Product image gallery
    - `cart` - Shopping cart items
    - `orders` - Customer orders with location tracking
    - `order_items` - Items in orders
    - `reviews` - Product reviews
    - `favorites` - User favorite products
    - `notifications` - User notifications
    - `loyalty_points` - Customer loyalty program
    - `promo_codes` - Promotional discount codes
    - `promo_uses` - Promo code usage tracking
    - `shipments` - Order delivery tracking
    - `business_expenses` - Business expense tracking
    - `suppliers` - Supplier management
    - `inventory_rules` - Automatic reorder rules
    - `inventory_movements` - Stock movement logs
    - `purchase_orders` - Purchase orders to suppliers
    - `automation_rules` - Marketing automation rules
    - `automation_executions` - Automation execution logs
    - `security_logs` - Security event logs
    - `security_blocks` - User security blocks
    - `api_keys` - API key management
    - `webhook_logs` - Webhook event logs
    - `marketing_campaigns` - Marketing campaign tracking
    - `stock_reservations` - Temporary stock reservations
    - `stocktaking_sessions` - Physical inventory sessions
    - `stocktaking_items` - Counted items during stocktaking
    - `user_activity_logs` - User activity tracking
    - `flash_sale_products` - Flash sale product links
    - `scheduled_posts` - Scheduled channel posts
    - `post_statistics` - Post delivery statistics

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users and admins
    - Admin role checks for sensitive operations
    - User ownership checks for personal data

  3. Indexes
    - Optimized for common queries
    - Foreign key indexes
    - User and product lookups
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    telegram_id bigint UNIQUE NOT NULL,
    name text NOT NULL,
    phone text,
    email text,
    language text DEFAULT 'ru',
    is_admin boolean DEFAULT false,
    role text,
    acquisition_channel text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON users FOR SELECT
  TO authenticated
  USING (telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint);

CREATE POLICY "Admins can read all users"
  ON users FOR SELECT
  TO authenticated
  USING (is_admin = true AND telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint)
  WITH CHECK (telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    description text,
    emoji text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active categories"
  ON categories FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage categories"
  ON categories FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Subcategories table
CREATE TABLE IF NOT EXISTS subcategories (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    category_id uuid REFERENCES categories(id) ON DELETE CASCADE,
    emoji text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE subcategories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active subcategories"
  ON subcategories FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage subcategories"
  ON subcategories FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    description text,
    price numeric NOT NULL CHECK (price >= 0),
    category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
    subcategory_id uuid REFERENCES subcategories(id) ON DELETE SET NULL,
    brand text,
    image_url text,
    stock integer DEFAULT 0 CHECK (stock >= 0),
    views integer DEFAULT 0,
    sales_count integer DEFAULT 0,
    is_active boolean DEFAULT true,
    cost_price numeric DEFAULT 0 CHECK (cost_price >= 0),
    original_price numeric,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active products"
  ON products FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage products"
  ON products FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Product images table
CREATE TABLE IF NOT EXISTS product_images (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    image_url text NOT NULL,
    sort_order integer DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view product images"
  ON product_images FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage product images"
  ON product_images FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Cart table
CREATE TABLE IF NOT EXISTS cart (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES users(id) ON DELETE CASCADE,
    product_id uuid REFERENCES products(id) ON DELETE CASCADE,
    quantity integer DEFAULT 1 CHECK (quantity > 0),
    created_at timestamptz DEFAULT now()
);

ALTER TABLE cart ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own cart"
  ON cart FOR ALL
  TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint))
  WITH CHECK (user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint));

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    total_amount numeric NOT NULL CHECK (total_amount >= 0),
    status text DEFAULT 'pending',
    delivery_address text,
    payment_method text,
    payment_status text DEFAULT 'pending',
    promo_discount numeric DEFAULT 0 CHECK (promo_discount >= 0),
    delivery_cost numeric DEFAULT 0 CHECK (delivery_cost >= 0),
    latitude numeric,
    longitude numeric,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint));

CREATE POLICY "Admins can view all orders"
  ON orders FOR SELECT
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

CREATE POLICY "Users can create own orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint));

CREATE POLICY "Admins can update orders"
  ON orders FOR UPDATE
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
    product_id uuid REFERENCES products(id) ON DELETE SET NULL,
    quantity integer NOT NULL CHECK (quantity > 0),
    price numeric NOT NULL CHECK (price >= 0),
    created_at timestamptz DEFAULT now()
);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (order_id IN (SELECT id FROM orders WHERE user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint)));

CREATE POLICY "Admins can view all order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES users(id) ON DELETE CASCADE,
    product_id uuid REFERENCES products(id) ON DELETE CASCADE,
    rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view reviews"
  ON reviews FOR SELECT
  USING (true);

CREATE POLICY "Users can create own reviews"
  ON reviews FOR INSERT
  TO authenticated
  WITH CHECK (user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint));

-- Favorites table
CREATE TABLE IF NOT EXISTS favorites (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES users(id) ON DELETE CASCADE,
    product_id uuid REFERENCES products(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    UNIQUE(user_id, product_id)
);

ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own favorites"
  ON favorites FOR ALL
  TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint))
  WITH CHECK (user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint));

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES users(id) ON DELETE CASCADE,
    title text NOT NULL,
    message text NOT NULL,
    type text DEFAULT 'info',
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notifications"
  ON notifications FOR ALL
  TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint))
  WITH CHECK (user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint));

-- Loyalty points table
CREATE TABLE IF NOT EXISTS loyalty_points (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    current_points integer DEFAULT 0 CHECK (current_points >= 0),
    total_earned integer DEFAULT 0 CHECK (total_earned >= 0),
    current_tier text DEFAULT 'Bronze',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE loyalty_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own loyalty points"
  ON loyalty_points FOR SELECT
  TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint));

-- Promo codes table
CREATE TABLE IF NOT EXISTS promo_codes (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    code text UNIQUE NOT NULL,
    discount_type text NOT NULL,
    discount_value numeric NOT NULL CHECK (discount_value >= 0),
    min_order_amount numeric DEFAULT 0 CHECK (min_order_amount >= 0),
    max_uses integer,
    expires_at timestamptz,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active promo codes"
  ON promo_codes FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage promo codes"
  ON promo_codes FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Promo uses table
CREATE TABLE IF NOT EXISTS promo_uses (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    promo_code_id uuid REFERENCES promo_codes(id) ON DELETE CASCADE,
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    order_id uuid REFERENCES orders(id) ON DELETE SET NULL,
    discount_amount numeric CHECK (discount_amount >= 0),
    created_at timestamptz DEFAULT now()
);

ALTER TABLE promo_uses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view promo uses"
  ON promo_uses FOR SELECT
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Shipments table
CREATE TABLE IF NOT EXISTS shipments (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
    tracking_number text UNIQUE,
    delivery_provider text,
    delivery_option text,
    time_slot text,
    status text DEFAULT 'created',
    estimated_delivery timestamptz,
    scheduled_date date,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE shipments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own shipments"
  ON shipments FOR SELECT
  TO authenticated
  USING (order_id IN (SELECT id FROM orders WHERE user_id IN (SELECT id FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint)));

CREATE POLICY "Admins can manage shipments"
  ON shipments FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Business expenses table
CREATE TABLE IF NOT EXISTS business_expenses (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    expense_type text NOT NULL,
    amount numeric NOT NULL CHECK (amount >= 0),
    description text,
    expense_date date NOT NULL,
    is_tax_deductible boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE business_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage expenses"
  ON business_expenses FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Suppliers table
CREATE TABLE IF NOT EXISTS suppliers (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    contact_email text,
    phone text,
    address text,
    payment_terms text,
    cost_per_unit numeric DEFAULT 0 CHECK (cost_per_unit >= 0),
    created_at timestamptz DEFAULT now()
);

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage suppliers"
  ON suppliers FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Inventory rules table
CREATE TABLE IF NOT EXISTS inventory_rules (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id uuid REFERENCES products(id) ON DELETE CASCADE,
    reorder_point integer NOT NULL CHECK (reorder_point >= 0),
    reorder_quantity integer NOT NULL CHECK (reorder_quantity > 0),
    supplier_id uuid REFERENCES suppliers(id) ON DELETE SET NULL,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE inventory_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage inventory rules"
  ON inventory_rules FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Inventory movements table
CREATE TABLE IF NOT EXISTS inventory_movements (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id uuid REFERENCES products(id) ON DELETE CASCADE,
    movement_type text NOT NULL,
    quantity_change integer NOT NULL,
    old_quantity integer,
    new_quantity integer,
    supplier_id uuid REFERENCES suppliers(id) ON DELETE SET NULL,
    cost_per_unit numeric,
    reason text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage inventory movements"
  ON inventory_movements FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Purchase orders table
CREATE TABLE IF NOT EXISTS purchase_orders (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id uuid REFERENCES products(id) ON DELETE SET NULL,
    supplier_id uuid REFERENCES suppliers(id) ON DELETE SET NULL,
    quantity integer NOT NULL CHECK (quantity > 0),
    cost_per_unit numeric NOT NULL CHECK (cost_per_unit >= 0),
    total_amount numeric NOT NULL CHECK (total_amount >= 0),
    status text DEFAULT 'pending',
    received_quantity integer DEFAULT 0 CHECK (received_quantity >= 0),
    delivered_at timestamptz,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage purchase orders"
  ON purchase_orders FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Automation rules table
CREATE TABLE IF NOT EXISTS automation_rules (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    trigger_type text NOT NULL,
    conditions text,
    actions text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE automation_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage automation rules"
  ON automation_rules FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Automation executions table
CREATE TABLE IF NOT EXISTS automation_executions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id uuid REFERENCES automation_rules(id) ON DELETE CASCADE,
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    rule_type text,
    executed_at timestamptz DEFAULT now()
);

ALTER TABLE automation_executions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view automation executions"
  ON automation_executions FOR SELECT
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Security logs table
CREATE TABLE IF NOT EXISTS security_logs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    activity_type text NOT NULL,
    details text,
    severity text DEFAULT 'low',
    created_at timestamptz DEFAULT now()
);

ALTER TABLE security_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view security logs"
  ON security_logs FOR SELECT
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Security blocks table
CREATE TABLE IF NOT EXISTS security_blocks (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES users(id) ON DELETE CASCADE,
    reason text NOT NULL,
    blocked_until timestamptz,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE security_blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage security blocks"
  ON security_blocks FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- API keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_name text NOT NULL,
    api_key text UNIQUE NOT NULL,
    permissions text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage API keys"
  ON api_keys FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Webhook logs table
CREATE TABLE IF NOT EXISTS webhook_logs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider text NOT NULL,
    order_id uuid REFERENCES orders(id) ON DELETE SET NULL,
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    status text NOT NULL,
    error_message text,
    payload_preview text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE webhook_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view webhook logs"
  ON webhook_logs FOR SELECT
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Marketing campaigns table
CREATE TABLE IF NOT EXISTS marketing_campaigns (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    segment text,
    campaign_type text,
    target_count integer,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE marketing_campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage marketing campaigns"
  ON marketing_campaigns FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Stock reservations table
CREATE TABLE IF NOT EXISTS stock_reservations (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id uuid REFERENCES products(id) ON DELETE CASCADE,
    order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
    quantity integer NOT NULL CHECK (quantity > 0),
    expires_at timestamptz,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE stock_reservations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage stock reservations"
  ON stock_reservations FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Stocktaking sessions table
CREATE TABLE IF NOT EXISTS stocktaking_sessions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    location text DEFAULT 'Основной склад',
    status text DEFAULT 'active',
    started_at timestamptz,
    completed_at timestamptz,
    created_by uuid REFERENCES users(id) ON DELETE SET NULL
);

ALTER TABLE stocktaking_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage stocktaking sessions"
  ON stocktaking_sessions FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Stocktaking items table
CREATE TABLE IF NOT EXISTS stocktaking_items (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id uuid REFERENCES stocktaking_sessions(id) ON DELETE CASCADE,
    product_id uuid REFERENCES products(id) ON DELETE CASCADE,
    system_quantity integer,
    counted_quantity integer,
    counted_at timestamptz
);

ALTER TABLE stocktaking_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage stocktaking items"
  ON stocktaking_items FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- User activity logs table
CREATE TABLE IF NOT EXISTS user_activity_logs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES users(id) ON DELETE CASCADE,
    action text NOT NULL,
    search_query text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE user_activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view activity logs"
  ON user_activity_logs FOR SELECT
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Flash sale products table
CREATE TABLE IF NOT EXISTS flash_sale_products (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    promo_code_id uuid REFERENCES promo_codes(id) ON DELETE CASCADE,
    product_id uuid REFERENCES products(id) ON DELETE CASCADE
);

ALTER TABLE flash_sale_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view flash sale products"
  ON flash_sale_products FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage flash sale products"
  ON flash_sale_products FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Scheduled posts table
CREATE TABLE IF NOT EXISTS scheduled_posts (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    title text NOT NULL,
    content text NOT NULL,
    image_url text,
    time_morning text,
    time_afternoon text,
    time_evening text,
    target_audience text DEFAULT 'all',
    bot_username text DEFAULT 'Safar_call_bot',
    website_url text DEFAULT 'https://your-website.com',
    include_reviews boolean DEFAULT true,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE scheduled_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage scheduled posts"
  ON scheduled_posts FOR ALL
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Post statistics table
CREATE TABLE IF NOT EXISTS post_statistics (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id uuid REFERENCES scheduled_posts(id) ON DELETE CASCADE,
    time_period text,
    sent_count integer DEFAULT 0,
    error_count integer DEFAULT 0,
    sent_at timestamptz DEFAULT now()
);

ALTER TABLE post_statistics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view post statistics"
  ON post_statistics FOR SELECT
  TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE telegram_id = (current_setting('request.jwt.claims', true)::json->>'telegram_id')::bigint AND is_admin = true));

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_telegram_id ON users(telegram_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_subcategory_id ON products(subcategory_id);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_cart_user_id ON cart(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_product_id ON cart(product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_product_id ON inventory_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_user_id ON security_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_automation_executions_user_id ON automation_executions(user_id);