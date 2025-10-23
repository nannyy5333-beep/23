#!/usr/bin/env python3
"""
Entry point for Web Admin Panel
Run: python run_web.py
Or with Gunicorn: gunicorn -w 4 -b 0.0.0.0:5000 "run_web:app"
"""
import os
import sys

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

# Add project to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from web_admin.app import app

if __name__ == '__main__':
    print("=" * 60)
    print("🌐 Starting Web Admin Panel...")
    print("=" * 60)
    print(f"Admin URL: http://localhost:5000")
    print(f"Login with: {os.getenv('ADMIN_NAME', 'Admin')}")
    print("=" * 60)

    app.run(
        host='0.0.0.0',
        port=int(os.getenv('PORT', 5000)),
        debug=os.getenv('ENVIRONMENT') == 'development'
    )
