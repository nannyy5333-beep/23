from __future__ import annotations
import logging
"""
Lightweight SQL router shim for Supabase PostgREST.

This module provides a **minimal** `execute_query` function so that legacy imports
(`from patches.sql_router import execute_query`) keep working. The real/feature-rich
implementation lives on the `SupabaseManager.execute_query` method in `supabase_db.py`.

Why this file exists:
- Some modules import `execute_query` at top-level but never call it.
- A previous version of this file accidentally tried to `from patches.sql_router import execute_query`
  (self-import), which caused a circular import during module initialization.
- We remove that self-import and expose a safe, working fallback instead.

If you want full control and better error handling, use `SupabaseManager.execute_query`.
"""

import os
import logging
import json
from typing import Any, List, Optional, Sequence, Union

try:
    import httpx  # used for direct RPC calls when needed
except Exception:  # pragma: no cover
    httpx = None  # type: ignore

# --------- Environment helpers ---------
def _env(name: str, default: str = "") -> str:
    v = os.getenv(name, default)
    if not isinstance(v, str):
        return default
    return v.strip().strip('"').strip("'").rstrip("/")

SUPABASE_URL: str = _env("SUPABASE_URL")
API_KEY: str = _env("SUPABASE_SERVICE_ROLE_KEY") or _env("SUPABASE_ANON_KEY")

# Prepare static headers for PostgREST
HEADERS = {
    "apikey": API_KEY or "",
    "Authorization": f"Bearer {API_KEY}" if API_KEY else "",
    "Content-Type": "application/json",
    # Prefer returning rows from insert/update/delete when possible
    "Prefer": "return=representation",
}

if not SUPABASE_URL or not API_KEY:
    logging.warning("[sql_router] SUPABASE_URL or API key not set; execute_query will be a no-op.")

def _param_substitute(sql: str, params: Optional[Sequence[Any]]) -> str:
    """Very simple/unsafe parameter interpolation.
    NOTE: For trusted internal calls only. Do NOT expose to user-input.
    Supports placeholders: ?, %s, or $1..$n (first match style wins).
    """
    if not params:
        return sql
    # Detect placeholder style per occurrence basis
    style = None
    if "%s" in sql:
        style = "%s"
    elif "?" in sql:
        style = "?"
    # Else we will try $1..$n
    result = sql
    if style in ("%s", "?"):
        for p in params:
            if isinstance(p, str):
                safe = p.replace("'", "''")
                rep = f"'{safe}'"
            elif isinstance(p, bool):
                rep = "true" if p else "false"
            elif p is None:
                rep = "NULL"
            else:
                rep = str(p)
            result = result.replace(style, rep, 1)
    else:
        # $1..$n style
        for i, p in enumerate(params, start=1):
            token = f"${i}"
            if token not in result:
                # nothing to replace — continue
                continue
            if isinstance(p, str):
                safe = p.replace("'", "''")
                rep = f"'{safe}'"
            elif isinstance(p, bool):
                rep = "true" if p else "false"
            elif p is None:
                rep = "NULL"
            else:
                rep = str(p)
            result = result.replace(token, rep)
    return result

def _rpc_exec_sql(sql: str) -> Optional[Union[List, dict]]:
    """Call the Postgres function `exec_sql(sql text)` via Supabase PostgREST.

    Requires a Postgres function named `exec_sql` in your database.
    """
    if not SUPABASE_URL or not API_KEY or httpx is None:
        return None
    url = f"{normalize_supabase_url(SUPABASE_URL)}/rest/v1/rpc/exec_sql"
    try:
        r = httpx.post(url, headers=HEADERS, json={"sql": sql}, timeout=60.0)
        # PostgREST returns JSON body; on error, it may return JSON with message/code
        if r.status_code >= 400:
            try:
                payload = r.json()
            except Exception:
                payload = {"message": r.text}
            logging.error("[sql_router] RPC exec_sql error %s: %s", r.status_code, payload)
            return None
        # Successful
        try:
            return r.json()
        except Exception:
            # Some RPCs may return no content
            return None
    except Exception as e:  # network or other issues
        logging.exception("[sql_router] RPC exec_sql call failed: %s", e)
        return None


def execute_query(sql: str, use_service_role: bool = True, timeout: float = 20.0):
    """
    Unified contract:
      - SELECT -> list of row dicts ([], if empty/error)
      - DML/DDL -> {"row_count": N} or {"error": "...", "code": "..."}
    """
    base = normalize_supabase_url(SUPABASE_URL)
    if not base:
        logger.error("SUPABASE_URL is empty")
        return [] if (sql or "").strip().lower().startswith("select") else {"error": "empty-url"}

    api_key = SUPABASE_SERVICE_ROLE_KEY if (use_service_role and SUPABASE_SERVICE_ROLE_KEY) else SUPABASE_ANON_KEY
    headers = {
        "apikey": api_key,
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }
    url = f"{base}/rest/v1/rpc/exec_sql"

    sql_str = (sql or "").strip()
    is_select = sql_str.lower().startswith("select")

    try:
        r = httpx.post(url, headers=headers, json={"sql": sql_str}, timeout=timeout)
    except Exception as e:
        logger.exception("exec_sql request failed: %s", e)
        return [] if is_select else {"error": str(e)}

    if r.status_code != 200:
        body = r.text[:200]
        logger.error("exec_sql http %s: %s", r.status_code, body)
        return [] if is_select else {"error": f"http {r.status_code}", "details": body}

    try:
        data = r.json()
    except Exception:
        body = r.text[:200]
        logger.error("exec_sql invalid json: %s", body)
        return [] if is_select else {"error": "invalid-json", "details": body}

    if isinstance(data, dict):
        if isinstance(data.get("result"), list):
            return data["result"]
        if "row_count" in data:
            return {"row_count": data["row_count"]}
        if "error" in data:
            return [] if is_select else {"error": data.get("error"), "code": data.get("code")}
    elif isinstance(data, list):
        return data

    return [] if is_select else {"row_count": 0}


    """Fallback, backward-compatible query executor.
    - Logs a deprecation notice.
    - If possible, calls the `exec_sql` RPC using service role key.
    - Returns the JSON-decoded payload or None on failure.
    """
    logging.warning("[sql_router] Deprecated: use SupabaseManager.execute_query instead.")
    sql = query.strip()
    if params:
        sql = _param_substitute(sql, params)
    # Try RPC
    return _rpc_exec_sql(sql)

__all__ = ["execute_query"]

logger = logging.getLogger('sql_router')

def normalize_supabase_url(u: str | None) -> str | None:
    if not u: return None
    u = u.strip().strip('"').strip("'")
    while u.endswith('/'):
        u = u[:-1]
    for suf in ("/rest/v1","/auth/v1","/storage/v1","/realtime/v1","/functions/v1"):
        if u.endswith(suf):
            u = u[:-len(suf)]
            while u.endswith('/'):
                u = u[:-1]
    return u

