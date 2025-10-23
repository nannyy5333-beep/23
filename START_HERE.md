# 🚀 START HERE - Telegram Shop Bot

## Ваша ситуация

Вы получили две ошибки при запуске:

1. ✅ **ИСПРАВЛЕНО:** `ImportError: cannot import name 'create_client'`
2. ✅ **ИСПРАВЛЕНО:** Конфликт зависимостей `postgrest==0.17.2` vs `>=0.18`

## Быстрый старт (3 команды)

```bash
# 1. Перейдите в проект
cd /home/duck/DC/Telegram/Finil\ v/project

# 2. Установите зависимости (исправленная версия)
pip3 install -r requirements.txt

# 3. Настройте .env и запустите
cp .env.example .env
nano .env  # Заполните ваши данные
python3 run_bot.py
```

## Что было исправлено

### 1. Конфликт зависимостей ✅

**Было (не работало):**
```txt
supabase==2.10.0
postgrest==0.17.2  ❌ Конфликт!
```

**Стало (работает):**
```txt
supabase==2.10.0
postgrest>=0.18.0,<0.19.0  ✅ Совместимо!
```

### 2. Отсутствие зависимостей ✅

Теперь `requirements.txt` содержит все правильные версии:
- ✅ supabase==2.10.0
- ✅ postgrest>=0.18.0,<0.19.0
- ✅ flask==2.3.3
- ✅ и все остальное

### 3. Runtime исправления ✅

В коде проекта исправлено:
- ✅ `execute_query` метод в SupabaseManager
- ✅ SQLite → Postgres конвертация дат
- ✅ Автосоздание logs/ директории
- ✅ RPC функция exec_sql в Supabase

## Пошаговая инструкция

### Шаг 1: Установите зависимости

```bash
cd /home/duck/DC/Telegram/Finil\ v/project

# Если были старые версии - удалите
pip3 uninstall supabase postgrest -y

# Установите правильные версии
pip3 install -r requirements.txt
```

### Шаг 2: Проверьте установку

```bash
python3 -c "from supabase import create_client; print('✅ Supabase работает!')"
python3 -c "from flask import Flask; print('✅ Flask работает!')"
python3 -c "import requests; print('✅ Requests работает!')"
```

Если все 3 команды вывели ✅ - отлично, идём дальше!

### Шаг 3: Настройте .env

⚠️ **ВАЖНО:** См. подробную инструкцию → **[HOW_TO_GET_CREDENTIALS.md](HOW_TO_GET_CREDENTIALS.md)**

```bash
nano .env
```

Заполните эти поля:

```env
# Supabase (уже есть в .env)
SUPABASE_URL=https://iyfkwocoifpygsrovbqh.supabase.co
SUPABASE_ANON_KEY=eyJ...

# Telegram (нужно заполнить!)
TELEGRAM_BOT_TOKEN=1234567890:ABC-DEF...
POST_CHANNEL_ID=-1001234567890
ADMIN_TELEGRAM_ID=123456789
ADMIN_NAME=YourName

# Flask
FLASK_SECRET_KEY=any-random-string-here
ENVIRONMENT=development
```

### Шаг 4: Получите недостающие данные

#### Telegram Bot Token
1. Откройте Telegram
2. Найдите @BotFather
3. Отправьте `/newbot` или `/mybots`
4. Скопируйте токен (вида `1234567890:ABC...`)

#### Channel ID
1. Создайте канал в Telegram
2. Добавьте вашего бота как администратора
3. Найдите @userinfobot
4. Перешлите любое сообщение из канала @userinfobot
5. Скопируйте Chat ID (вида `-1001234567890`)

#### Your Telegram ID
1. Найдите @userinfobot
2. Отправьте `/start`
3. Скопируйте ваш ID (вида `123456789`)

### Шаг 5: Запустите бота

```bash
python3 run_bot.py
```

Вы должны увидеть:
```
============================================================
🤖 Starting Telegram Shop Bot...
============================================================
```

### Шаг 6: Запустите админку (опционально)

В другом терминале:

```bash
cd /home/duck/DC/Telegram/Finil\ v/project
python3 run_web.py
```

Откройте http://localhost:5000 в браузере.

## Возможные проблемы и решения

### Проблема: pip3 не найден

**Решение:**
```bash
sudo apt update
sudo apt install python3-pip
```

### Проблема: Ошибка при установке зависимостей

**Решение:**
```bash
pip3 install --upgrade pip
pip3 install -r requirements.txt
```

### Проблема: ModuleNotFoundError при запуске

**Решение:**
```bash
# Установите конкретный пакет
pip3 install supabase
pip3 install flask
# и т.д.
```

### Проблема: ValueError: TELEGRAM_BOT_TOKEN/POST_CHANNEL_ID is required

**Решение:**
Заполните `.env` файл правильными значениями.

**Подробная инструкция:** [HOW_TO_GET_CREDENTIALS.md](HOW_TO_GET_CREDENTIALS.md)

## Структура файлов

```
project/
├── run_bot.py              ← Запуск бота
├── run_web.py              ← Запуск админки
├── main.py                 ← Код бота
├── supabase_db.py          ← База данных
├── config.py               ← Конфигурация
├── .env                    ← Ваши секреты (создайте!)
├── .env.example            ← Шаблон
├── requirements.txt        ← Зависимости (исправлено!)
└── web_admin/              ← Админ-панель
    ├── app.py
    └── templates/
```

## Документация

Если что-то непонятно, читайте:

- **[DEPENDENCY_FIX.md](DEPENDENCY_FIX.md)** - исправление конфликта postgrest
- **[FIX_IMPORT_ERROR.md](FIX_IMPORT_ERROR.md)** - решение ImportError
- **[QUICKSTART.md](QUICKSTART.md)** - быстрый старт
- **[INSTALL.md](INSTALL.md)** - детальная установка
- **[FINAL_FIXES.md](FINAL_FIXES.md)** - runtime исправления
- **[README.md](README.md)** - обзор проекта
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - деплой на сервер

## Готово! 🎉

После выполнения всех шагов:

1. ✅ Зависимости установлены
2. ✅ .env настроен
3. ✅ Бот запущен
4. ✅ Можно тестировать в Telegram

## Следующие шаги

1. Откройте бота в Telegram
2. Отправьте `/start`
3. Добавьте товары через админку
4. Протестируйте заказы
5. Настройте автопосты

---

**Need help?** Все инструкции находятся в документации выше.
