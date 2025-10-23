# Deployment Guide - Telegram Shop Bot

## Готовность к запуску

✅ **Конфигурация**: Всё через ENV, нет хардкода
✅ **Логгер**: Экспортирует стандартный `logging.Logger`
✅ **База данных**: Единая Supabase Postgres для бота и админки
✅ **Входные точки**: Раздельные для бота и веб-панели
✅ **Зависимости**: Объединены в один `requirements.txt`

## Структура проекта

```
project/
├── run_bot.py              # Запуск бота
├── run_web.py              # Запуск веб-админки
├── main.py                 # Основной код бота
├── supabase_db.py          # Менеджер БД
├── config.py               # Конфигурация (только ENV)
├── logger.py               # Логирование
├── requirements.txt        # Все зависимости
├── Procfile               # Для Render/Heroku
├── .env                   # Локальные переменные (не коммитить!)
├── .env.example           # Шаблон переменных
├── web_admin/             # Flask админ-панель
│   ├── app.py            # Flask приложение
│   ├── bot_integration.py
│   └── templates/        # HTML шаблоны
└── handlers.py, crm.py, etc.
```

## Быстрый старт (локально)

### 1. Установите зависимости

```bash
pip install -r requirements.txt
```

### 2. Настройте .env

Скопируйте `.env.example` в `.env` и заполните:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key

TELEGRAM_BOT_TOKEN=1234567890:ABC...
POST_CHANNEL_ID=-1001234567890
ADMIN_TELEGRAM_ID=123456789
ADMIN_NAME=YourName

FLASK_SECRET_KEY=random-secret-key-here
ENVIRONMENT=development
```

### 3. Запустите бота

```bash
python run_bot.py
```

### 4. Запустите админку (опционально)

```bash
python run_web.py
# Откройте http://localhost:5000
```

## Деплой на Render.com

### Вариант 1: Два сервиса (рекомендуется)

**Сервис 1: Web Admin (Web Service)**
```
Build Command: pip install -r requirements.txt
Start Command: gunicorn -w 4 -b 0.0.0.0:$PORT "run_web:app"
```

**Сервис 2: Telegram Bot (Background Worker)**
```
Build Command: pip install -r requirements.txt
Start Command: python run_bot.py
```

### Вариант 2: Один сервис с Procfile

Render автоматически прочитает `Procfile`:
```
web: gunicorn -w 4 -b 0.0.0.0:$PORT "run_web:app"
bot: python run_bot.py
```

### Переменные окружения на Render

Добавьте в Environment Variables:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...
TELEGRAM_BOT_TOKEN=1234567890:ABC...
POST_CHANNEL_ID=-1001234567890
ADMIN_TELEGRAM_ID=123456789
ADMIN_NAME=Admin
FLASK_SECRET_KEY=production-secret-key
ENVIRONMENT=production
LOG_LEVEL=INFO
```

## Деплой на Heroku

```bash
heroku create your-shop-bot
heroku config:set TELEGRAM_BOT_TOKEN=...
heroku config:set SUPABASE_URL=...
# ... остальные переменные
git push heroku main
```

Heroku автоматически использует `Procfile` для запуска обоих процессов.

## Архитектура

### Бот (run_bot.py → main.py)
- Работает как долгоживущий процесс
- Опрашивает Telegram API через REST (urllib)
- Обрабатывает сообщения, команды, callback-кнопки
- Автопосты по расписанию (scheduled_posts.py)
- Подключается к Supabase для данных

### Админка (run_web.py → web_admin/app.py)
- Flask web-приложение
- Gunicorn для production
- Аутентификация через сессии
- Управление товарами, заказами, постами
- Та же БД Supabase что и бот

### База данных (supabase_db.py)
- **Единый источник данных** для бота и админки
- Supabase Postgres (33 таблицы)
- RLS-политики для безопасности
- Миграции уже применены

### Логирование (logger.py)
- Экспортирует стандартный `logging.Logger`
- Ротация файлов логов
- Отдельный лог для ошибок
- Настраивается через ENV (LOG_LEVEL)

## Проверка работоспособности

```bash
# Тест конфигурации
export TELEGRAM_BOT_TOKEN=test
export POST_CHANNEL_ID=test
export ADMIN_TELEGRAM_ID=123
python -c "from config import BOT_TOKEN; print('✅ Config OK')"

# Тест логгера
python -c "from logger import logger; print('✅ Logger OK')"

# Тест БД (требует реальные ключи Supabase)
export SUPABASE_URL=...
export SUPABASE_ANON_KEY=...
python -c "from supabase_db import SupabaseManager; db = SupabaseManager(); print('✅ DB OK')"
```

## Мониторинг

Логи сохраняются в:
- `bot.log` - основные логи
- `bot_errors.log` - только ошибки
- `logs/security.log` - события безопасности

На production используйте:
- Sentry (через `SENTRY_DSN` ENV)
- Prometheus (через `PROMETHEUS_PORT` ENV)

## Масштабирование

**Бот**: Один экземпляр достаточно (Telegram long-polling)
**Админка**: Можно масштабировать горизонтально (Gunicorn workers)
**БД**: Supabase автоматически масштабируется

## Troubleshooting

### Бот не получает сообщения
- Проверьте `TELEGRAM_BOT_TOKEN`
- Убедитесь, что бот запущен
- Проверьте логи: `tail -f bot.log`

### Админка не открывается
- Проверьте порт: `PORT` ENV (по умолчанию 5000)
- Проверьте `FLASK_SECRET_KEY` установлен

### Ошибки БД
- Проверьте `SUPABASE_URL` и `SUPABASE_ANON_KEY`
- Убедитесь, что миграции применены
- Проверьте RLS-политики в Supabase Dashboard

### Автопосты не отправляются
- Бот должен быть админом в канале
- Проверьте `POST_CHANNEL_ID` (формат: `-1001234567890`)
- Проверьте расписание в админ-панели

## Безопасность

✅ Все секреты через ENV (не в коде!)
✅ RLS-политики Supabase
✅ Rate limiting на API
✅ HTTPS обязателен на production
✅ FLASK_SECRET_KEY должен быть случайным

## Следующие шаги

1. Заполните `.env` реальными значениями
2. Получите токен бота от @BotFather
3. Создайте канал, сделайте бота админом
4. Запустите `python run_bot.py`
5. Откройте админку `python run_web.py`
6. Добавьте товары через админку
7. Протестируйте бота в Telegram
8. Задеплойте на Render/Heroku
