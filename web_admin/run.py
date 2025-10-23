#!/usr/bin/env python3
"""
Запуск веб-панели администратора
"""
# project/web_admin/run.py (в самом верху файла)
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv(filename=".env"), override=False)

import os
import sys

# Добавляем путь к модулям бота
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from web_admin.app import app

if __name__ == '__main__':
    # Настройки для разработки
    app.run(
        debug=True,
        host='0.0.0.0',
        port=5000
    )
