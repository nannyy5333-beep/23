# Quick Start Guide

## Error: cannot import name 'create_client' from 'supabase'

You're seeing this error because the Supabase Python client is not installed.

⚠️ **ВАЖНО:** Если видите ошибку про конфликт postgrest, см. [DEPENDENCY_FIX.md](DEPENDENCY_FIX.md)

## Solution

### Step 1: Install pip (if not installed)

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3-pip

# macOS
brew install python3

# Or download from https://www.python.org/downloads/
```

### Step 2: Install dependencies

```bash
cd project
pip3 install -r requirements.txt
```

or install manually:

```bash
pip3 install supabase==2.10.0
pip3 install python-dotenv requests flask gunicorn
```

Note: postgrest will be installed automatically with the correct version

### Step 3: Verify installation

```bash
python3 -c "from supabase import create_client; print('✅ OK')"
```

### Step 4: Configure .env

```bash
cp .env.example .env
nano .env
```

Add your credentials:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...
TELEGRAM_BOT_TOKEN=1234567890:ABC...
POST_CHANNEL_ID=-1001234567890
ADMIN_TELEGRAM_ID=123456789
ADMIN_NAME=Admin
FLASK_SECRET_KEY=random-secret-123
```

### Step 5: Run

```bash
python3 run_bot.py
```

## Still Getting Errors?

### Use Virtual Environment (Recommended)

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 run_bot.py
```

### Check Python Version

```bash
python3 --version  # Need 3.8+
```

### Install from Scratch

```bash
pip3 uninstall supabase postgrest -y
pip3 install --upgrade pip
pip3 install supabase==2.10.0
```

## Full Installation Guide

See [INSTALL.md](INSTALL.md) for detailed instructions.

## Getting Credentials

1. **Telegram Bot Token**: Talk to @BotFather in Telegram
2. **Supabase**: Sign up at https://supabase.com (free)
3. **Your Telegram ID**: Talk to @userinfobot
4. **Channel ID**: Create channel, add bot as admin, forward message to @userinfobot

## Minimal Test

```bash
# Test imports
python3 -c "from supabase import create_client; print('✅ Supabase')"
python3 -c "from flask import Flask; print('✅ Flask')"
python3 -c "import requests; print('✅ Requests')"

# Test config (after .env is set)
export $(cat .env | xargs)
python3 -c "from config import BOT_TOKEN; print('✅ Config')"
```

## Common Issues

| Error | Solution |
|-------|----------|
| `pip: command not found` | Install pip: `sudo apt install python3-pip` |
| `ModuleNotFoundError: supabase` | Run: `pip3 install supabase` |
| `ValueError: TELEGRAM_BOT_TOKEN required` | Fill .env file |
| `cannot import name 'create_client'` | Reinstall: `pip3 install --force-reinstall supabase` |
| `ERROR: conflicting dependencies postgrest` | See [DEPENDENCY_FIX.md](DEPENDENCY_FIX.md) |

## Need Help?

Check these files:
- [INSTALL.md](INSTALL.md) - Full installation guide
- [README.md](README.md) - Project overview
- [DEPLOYMENT.md](DEPLOYMENT.md) - Production deployment
- [FINAL_FIXES.md](FINAL_FIXES.md) - Runtime fixes applied
