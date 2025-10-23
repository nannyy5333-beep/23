# Telegram Shop Bot - Setup Guide

## Критичные исправления

Все обрезанные фрагменты кода и проблемы устранены:
- ✅ Удалён хардкод токенов из config.py
- ✅ Миграция с SQLite на Supabase Postgres
- ✅ Исправлены переменные окружения (SUPABASE_URL, SUPABASE_ANON_KEY)
- ✅ Удалена зависимость python-telegram-bot (используется REST API)
- ✅ Удалены SQLite-файлы (database_backup.py, fix_database.py)
- ✅ config.py и logger.py полностью рабочие
- ✅ scheduled_posts.py SimpleScheduler работает
- ✅ web_admin/app.py login декоратор исправлен

## Требования

- Python 3.8+
- PostgreSQL через Supabase
- Telegram Bot Token

## Установка

### 1. Установите зависимости

```bash
pip install -r requirements.txt
```

### 2. Настройте переменные окружения

Отредактируйте файл `.env`:

```env
# Supabase Database
SUPABASE_URL=https://iyfkwocoifpygsrovbqh.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Telegram Bot (ОБЯЗАТЕЛЬНО!)
TELEGRAM_BOT_TOKEN=your_bot_token_here
POST_CHANNEL_ID=your_channel_id_here
ADMIN_TELEGRAM_ID=your_telegram_id_here
ADMIN_NAME=YourName

# Flask Admin Panel
FLASK_SECRET_KEY=generate-random-secret-key-here
ENVIRONMENT=development
```

**ВАЖНО:**
- `TELEGRAM_BOT_TOKEN` - получите от @BotFather
- `POST_CHANNEL_ID` - ID канала (формат: `-1001234567890`)
- `ADMIN_TELEGRAM_ID` - ваш Telegram ID (получите от @userinfobot)

### 3. Инициализируйте базу данных

База данных Supabase уже содержит схему со всеми таблицами:
- users, categories, products, orders
- cart, reviews, favorites, notifications
- loyalty_points, promo_codes, shipments
- inventory_rules, marketing_campaigns
- scheduled_posts, и 20+ других таблиц

RLS-политики настроены для безопасности.

### 4. Запустите бота

```bash
python3 main.py
```

### 5. Запустите веб-админку (опционально)

```bash
cd web_admin
python3 run.py
```

Админка будет доступна по адресу: http://localhost:5000

## Архитектура

### Основные компоненты:

- `main.py` - главный файл бота (REST API к Telegram)
- `supabase_db.py` - менеджер БД Supabase
- `handlers.py` - обработчики команд бота
- `scheduled_posts.py` - планировщик автопостов
- `web_admin/` - Flask-панель администратора
- `config.py` - конфигурация (без хардкода!)
- `logger.py` - система логирования

### Модули:

- **CRM**: управление клиентами, сегментация
- **Analytics**: аналитика продаж и пользователей
- **Financial**: финансовые отчёты, ROI
- **Inventory**: управление складом, автозаказы
- **Marketing**: автоматизация маркетинга
- **AI Features**: рекомендации, умные уведомления
- **Promotions**: промокоды, скидки
- **Logistics**: доставка, трекинг

## Безопасность

- Все секреты читаются из ENV (не хардкодятся!)
- RLS-политики Supabase защищают данные
- JWT для API (если используется)
- Rate limiting для защиты от спама

## Troubleshooting

### Ошибка: "TELEGRAM_BOT_TOKEN environment variable is required"
Установите переменную окружения в `.env`

### Ошибка: "cannot import name 'create_client' from 'supabase'"
Установите: `pip install supabase==2.10.0 postgrest==0.17.2`

### Бот не отвечает
1. Проверьте токен бота
2. Проверьте подключение к интернету
3. Проверьте логи: `tail -f bot.log`

### Автопосты не отправляются
1. Убедитесь, что бот админ в канале
2. Проверьте `POST_CHANNEL_ID` в `.env`
3. Проверьте расписание в админ-панели

## Веб-админка

Логин: используйте значение из `ADMIN_NAME` (по умолчанию: Admin)

Доступные функции:
- Управление товарами/категориями
- Просмотр заказов и клиентов
- Финансовая аналитика
- Управление инвентарём
- Создание автопостов
- CRM и сегментация
- Отчёты и статистика

## Что дальше?

1. Добавьте тестовые товары через админ-панель
2. Настройте автопосты для канала
3. Создайте промокоды для клиентов
4. Настройте правила инвентаризации
5. Добавьте поставщиков в систему

## Поддержка

При возникновении проблем:
1. Проверьте логи: `bot.log` и `bot_errors.log`
2. Проверьте переменные окружения в `.env`
3. Убедитесь, что все зависимости установлены
