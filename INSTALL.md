# Installation Guide

## Prerequisites

### Install Python and pip

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
```

#### macOS
```bash
brew install python3
```

#### Windows
Download from https://www.python.org/downloads/

## Installation Steps

### 1. Create virtual environment (recommended)

```bash
cd project
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate  # Windows
```

### 2. Install dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Verify Supabase installation

```bash
python3 -c "from supabase import create_client, Client; print('✅ Supabase OK')"
```

If this fails, install manually:

```bash
pip install supabase==2.10.0
# postgrest установится автоматически с правильной версией (>=0.18)
```

### 4. Configure environment

```bash
cp .env.example .env
nano .env  # Edit with your values
```

Required variables:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
TELEGRAM_BOT_TOKEN=your_bot_token
POST_CHANNEL_ID=your_channel_id
ADMIN_TELEGRAM_ID=your_telegram_id
ADMIN_NAME=YourName
FLASK_SECRET_KEY=random-secret-key
```

### 5. Test configuration

```bash
export $(cat .env | xargs)
python3 -c "from config import BOT_TOKEN; print('✅ Config OK')"
python3 -c "from logger import logger; print('✅ Logger OK')"
python3 -c "from supabase_db import SupabaseManager; print('✅ DB OK')"
```

### 6. Run the bot

```bash
python3 run_bot.py
```

### 7. Run the admin panel (separate terminal)

```bash
python3 run_web.py
```

## Troubleshooting

### ImportError: cannot import name 'create_client' from 'supabase'

This means supabase package is not properly installed.

**Solution:**
```bash
pip uninstall supabase postgrest -y
pip install supabase==2.10.0 postgrest==0.17.2
```

Verify:
```bash
python3 -c "import supabase; print(supabase.__version__)"
```

### ModuleNotFoundError: No module named 'dotenv'

**Solution:**
```bash
pip install python-dotenv
```

### ModuleNotFoundError: No module named 'flask'

**Solution:**
```bash
pip install flask werkzeug jinja2 gunicorn
```

### All modules missing

Install all at once:
```bash
pip install -r requirements.txt
```

## Requirements.txt Content

The project needs these packages:

```
python-dotenv==1.0.0
requests==2.31.0
psutil==5.9.6
redis==5.0.1
sentry-sdk==1.38.0
prometheus-client==0.19.0
cryptography==41.0.7
supabase==2.10.0
postgrest==0.17.2
flask==2.3.3
werkzeug==2.3.7
jinja2==3.1.2
gunicorn==21.2.0
```

## Virtual Environment Benefits

Using venv isolates project dependencies:

```bash
# Create
python3 -m venv venv

# Activate
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Install
pip install -r requirements.txt

# Deactivate when done
deactivate
```

## Docker Installation (Alternative)

If you prefer Docker:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python3", "run_bot.py"]
```

Build and run:
```bash
docker build -t telegram-shop-bot .
docker run --env-file .env telegram-shop-bot
```

## System Requirements

- Python 3.8 or higher
- 512MB RAM minimum (1GB recommended)
- Internet connection
- Telegram Bot Token
- Supabase account (free tier works)

## Next Steps

After successful installation:

1. Get Telegram Bot Token from @BotFather
2. Create Supabase project (free at supabase.com)
3. Get your Telegram ID from @userinfobot
4. Create Telegram channel, add bot as admin
5. Fill .env with real values
6. Run `python3 run_bot.py`
7. Test bot in Telegram
8. Run `python3 run_web.py` for admin panel

## Support

If installation fails:
1. Check Python version: `python3 --version` (need 3.8+)
2. Check pip: `pip3 --version`
3. Try virtual environment
4. Check internet connection
5. Review error messages carefully

For specific package errors, install individually:
```bash
pip install supabase
pip install flask
pip install requests
# etc.
```
