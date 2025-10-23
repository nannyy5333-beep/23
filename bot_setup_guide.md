# 🤖 Telegram Shop Bot - Инструкция по запуску

## Текущий статус

✅ Код исправлен и готов к работе
❌ Не установлены зависимости
❌ Не заполнен .env файл

## Что нужно сделать (2 шага)

### Шаг 1: Установите зависимости

```bash
cd /home/duck/DC/Telegram/Finil\ v/project
pip3 install -r requirements.txt
```

**Проверка:**
```bash
python3 -c "from supabase import create_client; print('✅ OK')"
```

### Шаг 2: Заполните .env файл

Откройте `.env`:
```bash
nano .env
```

Замените эти строки на реальные значения:

```env
TELEGRAM_BOT_TOKEN=ваш_токен_здесь
POST_CHANNEL_ID=ваш_id_канала_здесь
ADMIN_TELEGRAM_ID=ваш_id_здесь
```

**Где взять эти данные:**
- TELEGRAM_BOT_TOKEN - от @BotFather
- POST_CHANNEL_ID - от @userinfobot (перешлите сообщение из канала)
- ADMIN_TELEGRAM_ID - от @userinfobot (отправьте /start)

**Подробно:** [HOW_TO_GET_CREDENTIALS.md](HOW_TO_GET_CREDENTIALS.md)

### Готово! Запустите бота:

```bash
python3 run_bot.py
```

## Исправленные ошибки

### 1. ✅ Конфликт зависимостей
- Было: `postgrest==0.17.2` (несовместимо)
- Стало: `postgrest>=0.18.0,<0.19.0` (работает)

### 2. ✅ Отсутствующий модуль
- Удалён импорт `database_backup` (не используется)

### 3. ✅ Runtime исправления
- Добавлен метод `execute_query` в SupabaseManager
- SQLite→Postgres конвертация дат
- Автосоздание logs/ директории
- RPC функция exec_sql в Supabase

## Структура проекта

```
project/
├── run_bot.py           ← Запуск бота (python3 run_bot.py)
├── run_web.py           ← Запуск админки (python3 run_web.py)
├── main.py              ← Логика бота
├── supabase_db.py       ← База данных
├── config.py            ← Конфигурация
├── .env                 ← ⚠️ Заполните это!
├── requirements.txt     ← ✅ Исправлено
└── web_admin/           ← Админ-панель
```

## Команды бота

После запуска, в Telegram:

- `/start` - Начать работу
- `/menu` - Главное меню
- `/catalog` - Каталог товаров
- `/cart` - Корзина
- `/orders` - Мои заказы
- `/help` - Помощь

## Админ-панель

После запуска `python3 run_web.py`:

Откройте: http://localhost:5000

Возможности:
- 📦 Управление товарами
- 📋 Просмотр заказов
- 👥 CRM клиентов
- 📊 Аналитика
- 📅 Отложенные посты
- 💰 Финансовые отчёты

## Документация

| Файл | Описание |
|------|----------|
| **[QUICK_FIX_NOW.md](QUICK_FIX_NOW.md)** | 🚨 Быстрое решение за 5 минут |
| **[HOW_TO_GET_CREDENTIALS.md](HOW_TO_GET_CREDENTIALS.md)** | 🔑 Как получить токены |
| **[START_HERE.md](START_HERE.md)** | 🚀 Полная инструкция |
| **[DEPENDENCY_FIX.md](DEPENDENCY_FIX.md)** | 📦 Исправление зависимостей |
| **[INSTALL.md](INSTALL.md)** | 📚 Детальная установка |
| **[README.md](README.md)** | 📖 Обзор проекта |

## Проблемы и решения

### ImportError: cannot import name 'create_client'

**Решение:**
```bash
pip3 install -r requirements.txt
```

### ValueError: POST_CHANNEL_ID is required

**Решение:**
Заполните `.env` - см. [HOW_TO_GET_CREDENTIALS.md](HOW_TO_GET_CREDENTIALS.md)

### ModuleNotFoundError: No module named 'database_backup'

**Решение:**
Уже исправлено - импорт удалён из main.py

### ERROR: conflicting dependencies postgrest

**Решение:**
Уже исправлено в `requirements.txt` - просто установите:
```bash
pip3 install -r requirements.txt
```

## Минимальная команда для запуска

```bash
cd /home/duck/DC/Telegram/Finil\ v/project
pip3 install -r requirements.txt
nano .env  # Заполните 3 строки
python3 run_bot.py
```

## Проверка работы

1. Запустите бота: `python3 run_bot.py`
2. Должно появиться:
   ```
   ============================================================
   🤖 Starting Telegram Shop Bot...
   ============================================================
   Bot started successfully!
   ```
3. Откройте бота в Telegram
4. Отправьте `/start`
5. Должно появиться приветствие с меню

## Что дальше?

После запуска:

1. ✅ Добавьте товары через админку
2. ✅ Настройте категории
3. ✅ Протестируйте заказы
4. ✅ Настройте автопосты в канал
5. ✅ Деплой на сервер (см. DEPLOYMENT.md)

---

**Время на запуск:** 5-10 минут
**Требования:** Python 3.8+, pip, Telegram Bot Token

🎉 **Готово! Бот готов к использованию!**
