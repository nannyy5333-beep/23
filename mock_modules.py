#!/usr/bin/env python3
"""
Mock modules for testing without installing dependencies
"""
import sys
from unittest.mock import MagicMock

# Create mock modules
mock_modules = {
    'supabase': MagicMock(),
    'flask': MagicMock(),
    'werkzeug': MagicMock(),
    'jinja2': MagicMock(),
    'psutil': MagicMock(),
    'redis': MagicMock(),
    'dotenv': MagicMock(),
}

# Mock supabase specifically
class MockClient:
    def __init__(self, *args, **kwargs):
        self.table = MagicMock(return_value=self)
        self.select = MagicMock(return_value=self)
        self.insert = MagicMock(return_value=self)
        self.update = MagicMock(return_value=self)
        self.delete = MagicMock(return_value=self)
        self.eq = MagicMock(return_value=self)
        self.execute = MagicMock(return_value={'data': [], 'error': None})

def create_client(*args, **kwargs):
    return MockClient()

mock_modules['supabase'].create_client = create_client
mock_modules['supabase'].Client = MockClient

# Mock flask
class MockFlask:
    def __init__(self, *args, **kwargs):
        self.config = {}
        self.secret_key = None

    def route(self, *args, **kwargs):
        def decorator(f):
            return f
        return decorator

    def run(self, *args, **kwargs):
        pass

    def before_request(self, *args, **kwargs):
        def decorator(f):
            return f
        return decorator

    def after_request(self, *args, **kwargs):
        def decorator(f):
            return f
        return decorator

    def errorhandler(self, *args, **kwargs):
        def decorator(f):
            return f
        return decorator

mock_modules['flask'].Flask = MockFlask
mock_modules['flask'].request = MagicMock()
mock_modules['flask'].jsonify = lambda x: x
mock_modules['flask'].render_template = lambda *args, **kwargs: ""
mock_modules['flask'].redirect = lambda x: x
mock_modules['flask'].url_for = lambda x: x
mock_modules['flask'].session = {}

# Mock dotenv
def load_dotenv(*args, **kwargs):
    pass

mock_modules['dotenv'].load_dotenv = load_dotenv

# Install mocks
for module_name, module in mock_modules.items():
    sys.modules[module_name] = module

print("Mock modules installed successfully!")
