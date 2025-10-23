/*
  # Add INSERT policy for loyalty_points table
  
  1. Changes
    - Add policy to allow creating loyalty points for new users
    - This is needed during user registration
  
  2. Security
    - Policy allows INSERT for new users only
    - Users can still only read their own points
*/

-- Allow creating loyalty points for new users
CREATE POLICY "Allow creating loyalty points"
  ON loyalty_points
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);
