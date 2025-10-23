#!/usr/bin/env bash
set -euo pipefail

# === ЗАПОЛНИТЕ ПРАВИЛЬНЫЕ ДАННЫЕ ===
SUPABASE_DB_HOST="db.<PROJECT_REF>.supabase.co"  # пример: db.ljavtkhgkpbshmsdqyko.supabase.co
SUPABASE_DB_PORT="5432"
SUPABASE_DB_NAME="postgres"
SUPABASE_DB_USER="postgres"
SUPABASE_DB_PASSWORD="<ВАШ_ПАРОЛЬ_ИЗ_DASHBOARD>"  # НЕ anon/service_role key!

export DATABASE_URL="postgres://${SUPABASE_DB_USER}:${SUPABASE_DB_PASSWORD}@${SUPABASE_DB_HOST}:${SUPABASE_DB_PORT}/${SUPABASE_DB_NAME}?sslmode=require"

# Проверка наличия psql
if ! command -v psql >/dev/null 2>&1; then
  echo "psql не найден. Установите: sudo apt-get install -y postgresql-client"
  exit 1
fi

echo "[1/2] Применяем sql/setup_exec_sql.sql ..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$(dirname "$0")/../sql/setup_exec_sql.sql"

echo "[2/2] Применяем sql/minimal_schema.sql ..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$(dirname "$0")/../sql/minimal_schema.sql"

echo "Готово."
