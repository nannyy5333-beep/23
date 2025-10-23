-- Расширение для UUID
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- ========== USERS
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  telegram_id bigint UNIQUE,
  name text,
  is_admin boolean DEFAULT false,
  language text DEFAULT 'ru',
  created_at timestamptz DEFAULT now()
);

-- ========== PRODUCTS
CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  name text NOT NULL,
  title text,
  price numeric(12,2) NOT NULL DEFAULT 0,
  is_active boolean DEFAULT true,
  category_id uuid,
  subcategory_id uuid,
  created_at timestamptz DEFAULT now()
);

-- ========== CART
CREATE TABLE IF NOT EXISTS public.cart (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE CASCADE,
  quantity int NOT NULL DEFAULT 1,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_cart_user_id ON public.cart(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_product_id ON public.cart(product_id);

-- ========== ORDERS
CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  total_amount numeric(12,2) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at);

-- ========== AUTOMATION RULES
CREATE TABLE IF NOT EXISTS public.automation_rules (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  name text NOT NULL,
  trigger_type text NOT NULL,
  conditions jsonb NOT NULL DEFAULT '{}'::jsonb,
  actions jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ========== AUTOMATION EXECUTIONS (лог выполнений)
CREATE TABLE IF NOT EXISTS public.automation_executions (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  rule_id uuid REFERENCES public.automation_rules(id) ON DELETE CASCADE,
  rule_type text,
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ae_rule_id ON public.automation_executions(rule_id);
CREATE INDEX IF NOT EXISTS idx_ae_user_id ON public.automation_executions(user_id);
CREATE INDEX IF NOT EXISTS idx_ae_created_at ON public.automation_executions(created_at);

-- ========== SCHEDULED POSTS
CREATE TABLE IF NOT EXISTS public.scheduled_posts (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  time_morning time,
  time_afternoon time,
  time_evening time,
  target_audience text,
  is_active boolean DEFAULT true
);

-- ========== INVENTORY RULES
CREATE TABLE IF NOT EXISTS public.inventory_rules (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  product_id uuid REFERENCES public.products(id) ON DELETE CASCADE,
  reorder_point int NOT NULL DEFAULT 0,
  reorder_quantity int NOT NULL DEFAULT 0,
  supplier_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_inventory_rules_product_id ON public.inventory_rules(product_id);

-- ========== OPTIONAL: PRODUCT IMAGES
CREATE TABLE IF NOT EXISTS public.product_images (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  product_id uuid REFERENCES public.products(id) ON DELETE CASCADE,
  image_url text NOT NULL,
  position int DEFAULT 1,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_product_images_product_id ON public.product_images(product_id);

-- Примеры базовых данных
INSERT INTO public.users (telegram_id, name, is_admin, language)
VALUES (5720497431, 'Admin', true, 'ru')
ON CONFLICT (telegram_id) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO public.products (name, title, price, is_active)
SELECT 'Смартфон X', 'Смартфон X', 299.99, true
WHERE NOT EXISTS (SELECT 1 FROM public.products LIMIT 1);
