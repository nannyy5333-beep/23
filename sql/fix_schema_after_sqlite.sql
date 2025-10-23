-- автоматические правила
CREATE TABLE IF NOT EXISTS public.automation_rules (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  trigger_type text NOT NULL,
  conditions  jsonb NOT NULL DEFAULT '{}'::jsonb,
  actions     jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- чтобы можно было "ON CONFLICT (name) DO NOTHING"
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'automation_rules_name_unique'
  ) THEN
    ALTER TABLE public.automation_rules
      ADD CONSTRAINT automation_rules_name_unique UNIQUE (name);
  END IF;
END$$;

-- фиксим таблицу исполнения правил (если нет created_at)
ALTER TABLE public.automation_executions
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS user_id uuid;

CREATE INDEX IF NOT EXISTS idx_automation_executions_user_id
  ON public.automation_executions (user_id);
CREATE INDEX IF NOT EXISTS idx_automation_executions_created_at
  ON public.automation_executions (created_at);

-- индексы на orders для дат и пользователя
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders (user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders (created_at);

