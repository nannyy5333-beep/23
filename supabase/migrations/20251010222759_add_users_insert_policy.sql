/*
  # Add INSERT policy for users table
  
  1. Changes
    - Add policy to allow anyone to insert new users (registration)
    - This is needed for bot registration to work
  
  2. Security
    - Policy allows INSERT for new telegram users
    - Once created, users can only read/update their own data
*/

-- Allow anyone to register (insert new user)
CREATE POLICY "Allow user registration"
  ON users
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);
