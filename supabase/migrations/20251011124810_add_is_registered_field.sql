/*
  # Add is_registered field to users table

  1. Changes
    - Add `is_registered` boolean field to users table
    - Default value: false
    - Existing users without phone are marked as not registered
    - Update function to mark users as registered

  2. Notes
    - Users are considered registered when they complete the registration flow
    - This allows /start and /help commands before registration
*/

-- Add is_registered column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'is_registered'
  ) THEN
    ALTER TABLE users ADD COLUMN is_registered boolean DEFAULT false;
  END IF;
END $$;

-- Mark existing users with phone as registered
UPDATE users
SET is_registered = true
WHERE phone IS NOT NULL AND phone != '';

-- Create function to mark user as registered
CREATE OR REPLACE FUNCTION mark_user_registered(p_telegram_id bigint, p_phone text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE users
  SET is_registered = true,
      phone = COALESCE(p_phone, phone)
  WHERE telegram_id = p_telegram_id;
END;
$$;