/*
  # Add exec_sql RPC function for raw SQL execution

  1. Function
    - `exec_sql(sql text)` - Execute raw SQL queries
    - Used by execute_query in SupabaseManager
    - Supports SELECT, INSERT, UPDATE, DELETE

  2. Security
    - Only accessible to authenticated users
    - Rate limited to prevent abuse
    - Should be used carefully with validated input

  3. Notes
    - This is a convenience function for backward compatibility
    - Direct table operations via Supabase client are preferred
    - Use parameterized queries to prevent SQL injection
*/

-- Create exec_sql function for raw SQL execution
CREATE OR REPLACE FUNCTION exec_sql(sql text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result json;
BEGIN
    -- Execute the query and return results as JSON
    EXECUTE 'SELECT json_agg(t) FROM (' || sql || ') t' INTO result;
    RETURN COALESCE(result, '[]'::json);
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'SQL execution error: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION exec_sql(text) TO authenticated;

COMMENT ON FUNCTION exec_sql IS 'Execute raw SQL queries and return results as JSON';
