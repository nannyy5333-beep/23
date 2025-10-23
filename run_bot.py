#!/usr/bin/env python3
"""
Entry point for Telegram Bot
Run: python run_bot.py
"""
import os
import sys

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

# Add project to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

if __name__ == '__main__':
    from main import TelegramShopBot
    from config import BOT_TOKEN

    print("=" * 60)
    print("🤖 Starting Telegram Shop Bot...")
    print("=" * 60)

    bot = TelegramShopBot(BOT_TOKEN)
    bot.run()
