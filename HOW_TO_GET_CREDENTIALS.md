# 🔑 Как получить учётные данные для бота

## Проблема

```
ValueError: POST_CHANNEL_ID environment variable is required
```

Это означает, что в `.env` файле нужно заполнить реальные значения вместо плейсхолдеров.

## Что нужно заполнить в .env

```env
# ✅ Supabase - уже заполнено правильно
SUPABASE_URL=https://iyfkwocoifpygsrovbqh.supabase.co
SUPABASE_ANON_KEY=eyJ... (уже есть)

# ❌ Telegram - нужно заполнить!
TELEGRAM_BOT_TOKEN=your_bot_token_here          ← ЗАМЕНИТЕ
POST_CHANNEL_ID=your_channel_id_here            ← ЗАМЕНИТЕ
ADMIN_TELEGRAM_ID=your_admin_telegram_id_here   ← ЗАМЕНИТЕ
ADMIN_NAME=Admin                                 ← Можете оставить или изменить

# ✅ Flask - можно оставить как есть для разработки
FLASK_SECRET_KEY=your-secret-key-change-in-production
ENVIRONMENT=development
```

## Пошаговая инструкция

### 1. Получите TELEGRAM_BOT_TOKEN

1. Откройте Telegram
2. Найдите бота **@BotFather**
3. Отправьте команду `/newbot` (или `/mybots` если уже есть бот)
4. Следуйте инструкциям:
   - Введите имя бота (например: "My Shop Bot")
   - Введите username бота (должен заканчиваться на `bot`, например: `myshop_bot`)
5. BotFather даст вам токен вида: `1234567890:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`
6. **Скопируйте этот токен!**

**Пример токена:**
```
7891011121:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw
```

### 2. Получите POST_CHANNEL_ID

#### Вариант А: Создать новый канал

1. В Telegram создайте новый канал:
   - Нажмите ☰ → "New Channel"
   - Введите название (например: "Shop Updates")
   - Выберите "Public" или "Private"
   - Создайте канал

2. Добавьте вашего бота как администратора:
   - Зайдите в канал → ⚙️ Settings → Administrators
   - "Add Administrator"
   - Найдите вашего бота (по username)
   - Дайте права "Post Messages"

3. Получите ID канала:
   - Найдите бота **@userinfobot**
   - Перешлите любое сообщение из вашего канала @userinfobot
   - Он ответит с Chat ID вида: `-1001234567890`
   - **Скопируйте этот ID!**

**Пример ID:**
```
-1001234567890
```

#### Вариант Б: Использовать существующий канал

Если у вас уже есть канал:
1. Добавьте бота как администратора (см. выше)
2. Получите ID через @userinfobot

### 3. Получите ADMIN_TELEGRAM_ID

1. Найдите бота **@userinfobot** в Telegram
2. Отправьте ему `/start`
3. Он ответит с вашим ID вида: `123456789`
4. **Скопируйте ваш ID!**

**Пример ID:**
```
123456789
```

### 4. Измените ADMIN_NAME (опционально)

Просто впишите ваше имя или ник:
```env
ADMIN_NAME=Ваше_Имя
```

## Обновите .env файл

Откройте файл `.env`:

```bash
cd /home/duck/DC/Telegram/Finil\ v/project
nano .env
```

Замените плейсхолдеры на реальные значения:

```env
# Supabase Database
SUPABASE_URL=https://iyfkwocoifpygsrovbqh.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5Zmt3b2NvaWZweWdzcm92YnFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxMjQ0MzMsImV4cCI6MjA3NTcwMDQzM30.-cUKbJXPeTVaVWTSQHtwPB4B4nxHTwqf_ov8tJqqrNU

# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=7891011121:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw  ← ВАШ ТОКЕН
POST_CHANNEL_ID=-1001234567890                                    ← ВАШ ID КАНАЛА
ADMIN_TELEGRAM_ID=123456789                                       ← ВАШ ID
ADMIN_NAME=YourName

# Flask Configuration
FLASK_SECRET_KEY=random-secret-key-123456
ENVIRONMENT=development
LOG_LEVEL=INFO
```

Сохраните файл:
- В nano: `Ctrl+O` → `Enter` → `Ctrl+X`

## Проверка

Попробуйте запустить бота:

```bash
python3 run_bot.py
```

Если всё правильно, вы увидите:
```
============================================================
🤖 Starting Telegram Shop Bot...
============================================================
Bot started successfully! Waiting for messages...
```

Если ошибка всё ещё есть - проверьте что:
- ✅ Нет пробелов до/после `=`
- ✅ Нет кавычек вокруг значений
- ✅ Токен бота полный (длинный!)
- ✅ ID канала начинается с `-100`
- ✅ ID админа - только цифры

## Правильный формат .env

```env
TELEGRAM_BOT_TOKEN=1234567890:ABCdef-1234567890
POST_CHANNEL_ID=-1001234567890
ADMIN_TELEGRAM_ID=123456789
```

## Неправильный формат ❌

```env
# НЕ ТАК:
TELEGRAM_BOT_TOKEN = "1234567890:ABCdef"        ❌ Пробелы и кавычки
POST_CHANNEL_ID=1001234567890                   ❌ Нет минуса
ADMIN_TELEGRAM_ID="123456789"                   ❌ Кавычки
```

## Тестирование

После заполнения .env:

```bash
# 1. Запустите бота
python3 run_bot.py

# 2. Откройте Telegram
# 3. Найдите вашего бота (по username)
# 4. Отправьте /start
# 5. Должно появиться приветствие!
```

## Если всё равно не работает

### Проверьте переменные окружения:

```bash
cd /home/duck/DC/Telegram/Finil\ v/project
source .env
echo $TELEGRAM_BOT_TOKEN
echo $POST_CHANNEL_ID
echo $ADMIN_TELEGRAM_ID
```

Должны вывестись ваши значения (не `your_bot_token_here`!)

### Проверьте формат:

```bash
cat .env | grep -E "TOKEN|CHANNEL|ADMIN"
```

Убедитесь что нет плейсхолдеров.

## Минимальный рабочий .env

Для быстрого старта (скопируйте и подставьте свои значения):

```env
SUPABASE_URL=https://iyfkwocoifpygsrovbqh.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5Zmt3b2NvaWZweWdzcm92YnFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxMjQ0MzMsImV4cCI6MjA3NTcwMDQzM30.-cUKbJXPeTVaVWTSQHtwPB4B4nxHTwqf_ov8tJqqrNU
TELEGRAM_BOT_TOKEN=ЗАМЕНИТЕ_НА_ВАШ_ТОКЕН
POST_CHANNEL_ID=ЗАМЕНИТЕ_НА_ВАШ_ID_КАНАЛА
ADMIN_TELEGRAM_ID=ЗАМЕНИТЕ_НА_ВАШ_ID
ADMIN_NAME=Admin
FLASK_SECRET_KEY=my-secret-key-123
ENVIRONMENT=development
LOG_LEVEL=INFO
```

## Готово! 🎉

После заполнения всех значений бот запустится без ошибок.

---

**Нужна помощь?** Проверьте:
- [START_HERE.md](START_HERE.md) - общая инструкция
- [QUICKSTART.md](QUICKSTART.md) - быстрый старт
- [README.md](README.md) - обзор проекта
