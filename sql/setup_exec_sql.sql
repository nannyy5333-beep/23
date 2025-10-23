-- Устойчивый exec_sql, возвращающий JSONB
-- Сначала удалим старую сигнатуру (если была другой return type):
DROP FUNCTION IF EXISTS public.exec_sql(text);

CREATE OR REPLACE FUNCTION public.exec_sql(sql_text text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
BEGIN
  EXECUTE format('SELECT json_agg(t) FROM (%s) t', sql_text) INTO result;
  RETURN COALESCE(result, '[]'::jsonb);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('code', SQLSTATE, 'message', SQLERRM);
END;
$$;
