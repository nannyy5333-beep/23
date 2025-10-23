
import os, sys, json, httpx, base64
from urllib.parse import urlsplit

def _env(k):
    v = os.getenv(k, "") or ""
    return v.strip().strip('"').strip("'").rstrip("/")

def mask(s, keep=4):
    if not s: return "(empty)"
    if len(s) <= keep*2: return s[0] + "…" + s[-1]
    return s[:keep] + "…" + s[-keep:]

SUPABASE_URL = _env("SUPABASE_URL")
ANON = _env("SUPABASE_ANON_KEY")
SRV  = _env("SUPABASE_SERVICE_ROLE_KEY")
API  = SRV or ANON

print("SUPABASE_URL =", SUPABASE_URL)
print("ANON  =", mask(ANON))
print("SRV   =", mask(SRV))
print("Using =", "SERVICE_ROLE" if SRV else "ANON")

def die(msg):
    print("❌", msg); sys.exit(2)

# Basic URL sanity
if not SUPABASE_URL or "your-project-url" in SUPABASE_URL or "<project-ref>" in SUPABASE_URL:
    die("SUPABASE_URL выглядит как плейсхолдер. Возьми реальный URL из Settings → API.")
sp = urlsplit(SUPABASE_URL)
if not sp.scheme.startswith("http") or not sp.netloc:
    die(f"SUPABASE_URL некорректный: {SUPABASE_URL!r}")

# Basic JWT-ish sanity
if not API or not API.startswith("ey"):
    print("⚠️  Ключ не похож на JWT (обычно начинается с 'ey'). Проверь, что это ключ из Settings → API.")
headers = {"apikey": API, "Authorization": f"Bearer {API}"}

def try_req(path):
    url = f"{SUPABASE_URL}{path}"
    try:
        r = httpx.get(url, headers=headers, timeout=15)
        return r
    except Exception as e:
        die(f"Не удалось обратиться к {url}: {e}")

# 1) Touch REST root
r = try_req("/rest/v1/")
print("REST /rest/v1 status:", r.status_code)
if r.status_code == 401 and "Invalid API key" in r.text:
    die("Invalid API key — ключ неверный или не к этому проекту.")
elif r.status_code in (200, 404):
    print("✅ Базовый доступ к REST есть (200/404 ок).")
else:
    print("ℹ️ Ответ:", r.status_code, r.text[:200])

# 2) Try a minimal table list (should 404, ok) and a bogus table (also ok)
r2 = try_req("/rest/v1/unknown_table?select=*")
print("Unknown table status:", r2.status_code, "(expected 401/404/406 — это ок)")

print("🎉 Healthcheck завершён. Если здесь нет ❌ — ключи и URL выглядят рабочими.")
