create or replace function public.exec_sql(sql text)
returns json
language plpgsql
security definer
as $$
declare
  _sql      text := btrim(sql);
  _head     text := lower(split_part(_sql, ' ', 1));
  rows_json json;
  rowcount  bigint;
begin
  if _sql is null or _sql = '' then
    return '[]'::json;
  end if;

  if position('returning' in lower(_sql)) > 0
     or _head in ('select','with','values')
  then
    execute format(
      'with q as (%s) select coalesce(json_agg(q), ''[]''::json) from q',
      _sql
    ) into rows_json;

    return coalesce(rows_json, '[]'::json);
  end if;

  execute _sql;
  get diagnostics rowcount = row_count;
  return json_build_object('rows_affected', coalesce(rowcount, 0));
end;
$$;

revoke execute on function public.exec_sql(text) from public, anon, authenticated;
grant  execute on function public.exec_sql(text) to service_role;
