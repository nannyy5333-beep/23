
-- 20251021_05_delete_policies_and_public_catalog_rpc.sql
-- Часть 1. Политики DELETE: запрет для anon/authenticated на каталог и заказы, разрешение только service_role.
DO $$
DECLARE
  _schema text;
  _name text;
  pol RECORD;
BEGIN
  FOR _schema,_name IN
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_schema IN ('public','shop')
      AND table_name IN ('categories','subcategories','brands','products','orders','order_items')
  LOOP
    -- Сносим все существующие DELETE-политики
    FOR pol IN
      SELECT polname
      FROM pg_policy p
      JOIN pg_class c ON c.oid = p.polrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = _schema AND c.relname = _name AND p.polcmd = 'd'
    LOOP
      EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I;', pol.polname, _schema, _name);
    END LOOP;

    -- Разрешаем DELETE только service_role
    EXECUTE format('CREATE POLICY %I_delete_service_only ON %I.%I FOR DELETE TO service_role USING (TRUE);', _name, _schema, _name);

    -- Явно запрещаем DELETE для anon и authenticated
    EXECUTE format('CREATE POLICY %I_delete_no_anon ON %I.%I FOR DELETE TO anon USING (FALSE);', _name, _schema, _name);
    EXECUTE format('CREATE POLICY %I_delete_no_auth ON %I.%I FOR DELETE TO authenticated USING (FALSE);', _name, _schema, _name);
  END LOOP;
END $$;

-- Часть 2. Публичные RPC для каталога (invoker, без обхода RLS).
-- Определяем рабочую схему продуктов (public или shop)
CREATE OR REPLACE FUNCTION public._catalog_products_schema()
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='products') THEN
    RETURN 'public';
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='shop' AND table_name='products') THEN
    RETURN 'shop';
  ELSE
    RAISE EXCEPTION 'Table products not found in public or shop schema';
  END IF;
END;
$$;

-- Список товаров с пагинацией/поиском/сортировкой и фильтрами
CREATE OR REPLACE FUNCTION public.catalog_list(
  _limit int DEFAULT 24,
  _offset int DEFAULT 0,
  _sort text DEFAULT 'new',           -- 'new' | 'price_asc' | 'price_desc' | 'name'
  _q text DEFAULT NULL,               -- поиск по tsv или name ILIKE
  _category uuid DEFAULT NULL,
  _subcategory uuid DEFAULT NULL,
  _brand uuid DEFAULT NULL
)
RETURNS TABLE(
  id uuid,
  name text,
  price numeric,
  brand_id uuid,
  category_id uuid,
  subcategory_id uuid,
  created_at timestamptz
)
LANGUAGE plpgsql
AS $$
DECLARE
  s text := public._catalog_products_schema();
  has_name bool; has_price bool; has_brand bool; has_cat bool; has_subcat bool; has_created bool; has_tsv bool;
  sql text;
  order_by text := 'id DESC';
BEGIN
  -- Проверяем наличие колонок
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='name') INTO has_name;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='price') INTO has_price;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='brand_id') INTO has_brand;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='category_id') INTO has_cat;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='subcategory_id') INTO has_subcat;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='created_at') INTO has_created;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='tsv') INTO has_tsv;

  -- Сортировка
  IF _sort = 'new' AND has_created THEN
    order_by := 'created_at DESC';
  ELSIF _sort = 'price_asc' AND has_price THEN
    order_by := 'price ASC';
  ELSIF _sort = 'price_desc' AND has_price THEN
    order_by := 'price DESC';
  ELSIF _sort = 'name' AND has_name THEN
    order_by := 'name ASC';
  END IF;

  -- Конструируем SELECT с подстановками NULL для отсутствующих колонок
  sql := format($f$
    SELECT
      id,
      %1$s AS name,
      %2$s AS price,
      %3$s AS brand_id,
      %4$s AS category_id,
      %5$s AS subcategory_id,
      %6$s AS created_at
    FROM %I.products
    WHERE TRUE
  $f$, s,
    CASE WHEN has_name THEN 'name' ELSE 'NULL::text' END,
    CASE WHEN has_price THEN 'price' ELSE 'NULL::numeric' END,
    CASE WHEN has_brand THEN 'brand_id' ELSE 'NULL::uuid' END,
    CASE WHEN has_cat THEN 'category_id' ELSE 'NULL::uuid' END,
    CASE WHEN has_subcat THEN 'subcategory_id' ELSE 'NULL::uuid' END,
    CASE WHEN has_created THEN 'created_at' ELSE 'NULL::timestamptz' END
  );

  -- Фильтры
  IF _q IS NOT NULL AND _q <> '' THEN
    IF has_tsv THEN
      sql := sql || ' AND tsv @@ plainto_tsquery(''simple'', $q$ ' || replace(_q, '''', '''''') || ' $q$)';
    ELSIF has_name THEN
      sql := sql || ' AND name ILIKE '%' || quote_literal('%' || _q || '%') || '%'' ';
    END IF;
  END IF;

  IF _category IS NOT NULL AND has_cat THEN
    sql := sql || ' AND category_id = $1';
  END IF;
  IF _subcategory IS NOT NULL AND has_subcat THEN
    sql := sql || ' AND subcategory_id = $2';
  END IF;
  IF _brand IS NOT NULL AND has_brand THEN
    sql := sql || ' AND brand_id = $3';
  END IF;

  sql := sql || format(' ORDER BY %s LIMIT GREATEST($4,0) OFFSET GREATEST($5,0)', order_by);

  RETURN QUERY EXECUTE sql USING _category, _subcategory, _brand, _limit, _offset;
END;
$$;

-- Получение одного товара по id
CREATE OR REPLACE FUNCTION public.catalog_get(p_id uuid)
RETURNS TABLE(
  id uuid,
  name text,
  price numeric,
  brand_id uuid,
  category_id uuid,
  subcategory_id uuid,
  created_at timestamptz
)
LANGUAGE plpgsql
AS $$
DECLARE
  s text := public._catalog_products_schema();
  has_name bool; has_price bool; has_brand bool; has_cat bool; has_subcat bool; has_created bool;
  sql text;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='name') INTO has_name;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='price') INTO has_price;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='brand_id') INTO has_brand;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='category_id') INTO has_cat;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='subcategory_id') INTO has_subcat;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=s AND table_name='products' AND column_name='created_at') INTO has_created;

  sql := format($f$
    SELECT
      id,
      %1$s AS name,
      %2$s AS price,
      %3$s AS brand_id,
      %4$s AS category_id,
      %5$s AS subcategory_id,
      %6$s AS created_at
    FROM %I.products
    WHERE id = $1
    LIMIT 1
  $f$, s,
    CASE WHEN has_name THEN 'name' ELSE 'NULL::text' END,
    CASE WHEN has_price THEN 'price' ELSE 'NULL::numeric' END,
    CASE WHEN has_brand THEN 'brand_id' ELSE 'NULL::uuid' END,
    CASE WHEN has_cat THEN 'category_id' ELSE 'NULL::uuid' END,
    CASE WHEN has_subcat THEN 'subcategory_id' ELSE 'NULL::uuid' END,
    CASE WHEN has_created THEN 'created_at' ELSE 'NULL::timestamptz' END
  );

  RETURN QUERY EXECUTE sql USING p_id;
END;
$$;
