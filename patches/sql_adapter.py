# Compatibility shim: legacy imports expect patches.sql_adapter.execute_query
from .sql_router import execute_query
