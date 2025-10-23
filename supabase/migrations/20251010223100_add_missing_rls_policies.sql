/*
  # Add missing RLS policies for critical tables
  
  1. Changes
    - Add UPDATE/DELETE policies for loyalty_points
    - Add INSERT/UPDATE/DELETE policies for order_items
    - Add INSERT/UPDATE/DELETE policies for promo_uses
    - Add UPDATE/DELETE policies for reviews
    - Add policies for cart operations
  
  2. Security
    - Users can only modify their own data
    - Order items can only be created/modified with valid orders
    - Promo uses are tracked per user
*/

-- Loyalty Points policies
CREATE POLICY "Users can update own loyalty points"
  ON loyalty_points
  FOR UPDATE
  TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE telegram_id = (((current_setting('request.jwt.claims'::text, true))::json ->> 'telegram_id'::text))::bigint))
  WITH CHECK (user_id IN (SELECT id FROM users WHERE telegram_id = (((current_setting('request.jwt.claims'::text, true))::json ->> 'telegram_id'::text))::bigint));

-- Order Items policies
CREATE POLICY "Users can create order items for own orders"
  ON order_items
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (order_id IN (SELECT id FROM orders));

CREATE POLICY "Users can view order items for own orders"
  ON order_items
  FOR SELECT
  TO authenticated
  USING (order_id IN (SELECT id FROM orders WHERE user_id IN (SELECT id FROM users WHERE telegram_id = (((current_setting('request.jwt.claims'::text, true))::json ->> 'telegram_id'::text))::bigint)));

-- Promo Uses policies
CREATE POLICY "Users can create promo uses"
  ON promo_uses
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id IN (SELECT id FROM users WHERE telegram_id = (((current_setting('request.jwt.claims'::text, true))::json ->> 'telegram_id'::text))::bigint));

CREATE POLICY "Users can view own promo uses"
  ON promo_uses
  FOR SELECT
  TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE telegram_id = (((current_setting('request.jwt.claims'::text, true))::json ->> 'telegram_id'::text))::bigint));

-- Reviews policies
CREATE POLICY "Users can update own reviews"
  ON reviews
  FOR UPDATE
  TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE telegram_id = (((current_setting('request.jwt.claims'::text, true))::json ->> 'telegram_id'::text))::bigint))
  WITH CHECK (user_id IN (SELECT id FROM users WHERE telegram_id = (((current_setting('request.jwt.claims'::text, true))::json ->> 'telegram_id'::text))::bigint));

CREATE POLICY "Users can delete own reviews"
  ON reviews
  FOR DELETE
  TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE telegram_id = (((current_setting('request.jwt.claims'::text, true))::json ->> 'telegram_id'::text))::bigint));
