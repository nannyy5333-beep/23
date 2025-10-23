# Pre-Launch Checklist ✅

## ⚠️ ВАЖНО: Установка зависимостей

Перед запуском установите все зависимости:

```bash
# Убедитесь что pip установлен
python3 -m pip --version

# Установите зависимости
pip3 install -r requirements.txt

# Проверьте Supabase
python3 -c "from supabase import create_client; print('✅ OK')"
```

**Если получаете ошибку:** `ImportError: cannot import name 'create_client' from 'supabase'`

Смотрите [QUICKSTART.md](QUICKSTART.md) для решения.

## ✅ Исправлено

- [x] **Секреты через ENV** - config.py читает только ENV, без хардкода
- [x] **Логгер исправлен** - экспортирует стандартный `logging.Logger`
- [x] **Единая БД** - Supabase Postgres для бота и админки
- [x] **Входные точки** - `run_bot.py` и `run_web.py` как раздельные процессы
- [x] **Зависимости** - объединены в один `requirements.txt`
- [x] **Убрано** - python-telegram-bot (используется REST API)
- [x] **Убрано** - SQLite-файлы и database_backup.py
- [x] **Procfile** - для Render/Heroku деплоя
- [x] **.env.example** - шаблон переменных окружения
- [x] **Документация** - DEPLOYMENT.md с гайдами

## 🚀 Готово к запуску

### Локально

1. Скопируйте `.env.example` → `.env`
2. Заполните обязательные переменные:
   - `TELEGRAM_BOT_TOKEN` (от @BotFather)
   - `POST_CHANNEL_ID` (ID канала)
   - `ADMIN_TELEGRAM_ID` (ваш Telegram ID)
3. Установите: `pip install -r requirements.txt`
4. Запустите бота: `python run_bot.py`
5. Запустите админку: `python run_web.py`

### Production (Render/Heroku)

**Два сервиса (рекомендуется):**

**Сервис 1 - Web Admin:**
```
Type: Web Service
Build: pip install -r requirements.txt
Start: gunicorn -w 4 -b 0.0.0.0:$PORT "run_web:app"
```

**Сервис 2 - Telegram Bot:**
```
Type: Background Worker
Build: pip install -r requirements.txt
Start: python run_bot.py
```

**Environment Variables (оба сервиса):**
```
SUPABASE_URL=https://iyfkwocoifpygsrovbqh.supabase.co
SUPABASE_ANON_KEY=eyJ...
TELEGRAM_BOT_TOKEN=<ваш токен>
POST_CHANNEL_ID=<ID канала>
ADMIN_TELEGRAM_ID=<ваш ID>
ADMIN_NAME=Admin
FLASK_SECRET_KEY=<случайная строка>
ENVIRONMENT=production
LOG_LEVEL=INFO
```

## 📦 Что входит в проект

### Основные компоненты
- ✅ Telegram бот (REST API через urllib)
- ✅ Flask веб-админка
- ✅ Supabase Postgres БД (33 таблицы)
- ✅ Планировщик автопостов
- ✅ CRM и аналитика
- ✅ Управление инвентарём
- ✅ Финансовые отчёты
- ✅ Промокоды и лояльность
- ✅ AI-рекомендации
- ✅ Мониторинг и логи

### Веб-админка функции
- 📊 Dashboard с метриками
- 🛍 Управление товарами/категориями
- 📦 Просмотр и обработка заказов
- 👥 CRM и клиенты
- 📈 Аналитика продаж
- 💰 Финансовые отчёты
- 📱 Создание автопостов
- 🏭 Управление складом
- 🎁 Промокоды и акции

## 🔍 Тестирование

```bash
# Проверка конфигурации
export TELEGRAM_BOT_TOKEN=test
export POST_CHANNEL_ID=test
export ADMIN_TELEGRAM_ID=123
python -c "from config import BOT_TOKEN; print('✅ Config OK')"

# Проверка логгера
python -c "from logger import logger; logger.info('Test'); print('✅ Logger OK')"

# Проверка БД (нужны реальные ключи)
export SUPABASE_URL=https://iyfkwocoifpygsrovbqh.supabase.co
export SUPABASE_ANON_KEY=eyJ...
python -c "from supabase_db import SupabaseManager; db = SupabaseManager(); print('✅ DB OK')"
```

## ⚠️ Важные моменты

1. **Токен бота** - получите новый от @BotFather (старый скомпрометирован)
2. **Канал** - создайте канал, добавьте бота как админа
3. **Secrets** - на production используйте сильные FLASK_SECRET_KEY
4. **RLS** - Supabase RLS-политики уже настроены
5. **Логи** - проверяйте `bot.log` и `bot_errors.log`

## 🐛 Если что-то не работает

### Бот не отвечает
```bash
tail -f bot.log
# Проверьте TELEGRAM_BOT_TOKEN
```

### Админка ошибка 500
```bash
# Проверьте FLASK_SECRET_KEY установлен
# Проверьте SUPABASE_URL и SUPABASE_ANON_KEY
```

### Автопосты не идут
- Бот должен быть админом в канале
- POST_CHANNEL_ID правильный (формат: -1001234567890)
- Проверьте расписание в админке

## 📚 Документация

- `SETUP.md` - подробная инструкция по настройке
- `DEPLOYMENT.md` - гайд по деплою
- `README.md` - обзор проекта
- `.env.example` - шаблон переменных

## ✨ Готово!

Проект полностью рабочий и готов к деплою. Все критичные проблемы исправлены:
- Нет хардкода секретов
- Нет обрезанного кода
- Единая БД
- Правильные входные точки
- Рабочий логгер
