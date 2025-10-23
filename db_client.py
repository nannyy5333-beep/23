
import os, httpx
def _env(k): 
    v = os.getenv(k, "").strip().strip('"').strip("'").rstrip("/")
    return v
SUPABASE_URL  = _env("SUPABASE_URL")
API_KEY       = _env("SUPABASE_SERVICE_ROLE_KEY") or _env("SUPABASE_ANON_KEY")
HEADERS = {"apikey": API_KEY, "Authorization": f"Bearer {API_KEY}", "Content-Type":"application/json"}
def _url(p): return f"{SUPABASE_URL}{p}"
