create or replace function public.uuid_try(t text)
returns uuid
language plpgsql
stable
as $$
begin
  begin
    return t::uuid;
  exception when invalid_text_representation then
    return null;
  end;
end;
$$;
