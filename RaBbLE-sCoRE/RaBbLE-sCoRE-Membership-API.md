# RaBbLE-sCoRE-Membership-API.md — Invite, Summon, Sessions

```
transcribe ~ grimoire >> sCoRE membership API: invite tokens, summoning, persistent sessions // %MEMBERSHIP_API%
```

> **What this is:** Technical spec for the EP1 membership layer in sCoRE. Defines new files, new endpoints, and changes to existing files needed to support the Pair model.
> **Context:** [Membership Model](../RaBbLE-Collective/RaBbLE-Membership-Model.md) · [Service Plan](../RaBbLE-Collective/RaBbLE-Service-Plan.md) · [sCoRE Architecture](RaBbLE-sCoRE-Architecture.md)

---

## New Files

### `server/users.py`

Persistent user profiles and invite tokens. Replaces the in-memory `_users_by_*` dicts in `auth_routes.py`.

**Data directory:** `$DATA_DIR/` (env var, default `data/`)

```
data/
├── users/
│   └── {user_id}.json       # UserProfile
├── invites/
│   └── {token}.json         # InviteToken
└── sessions/
    └── {user_id}/
        └── {session_id}.json # SessionRecord (owned by sessions.py)
```

**Models:**

```python
class UserProfile(BaseModel):
    id: str                        # UUID
    handle: str                    # unique slug (e.g. "alice")
    display_name: str
    email: Optional[str] = None
    join_date: str                 # ISO 8601
    intention: str                 # ≤500 chars, loaded in every session context
    llm_backend: str = "hosted_openrouter"
    byo_key_enc: Optional[str] = None   # Fernet-encrypted if BYO
    tier: str = "collective"       # EP1 default
    api_key: str                   # rbbl_{token_urlsafe(32)}

class InviteToken(BaseModel):
    token: str                     # URL-safe random string (32 bytes)
    created_by: str                # admin user_id
    created_at: str                # ISO 8601
    expires_at: str                # ISO 8601, default +7 days
    note: Optional[str] = None     # human label ("for alice")
    consumed: bool = False
    consumed_by: Optional[str] = None  # user_id after summon
```

**llm_backend values:**
- `hosted_openrouter` — default; Collective's OpenRouter key
- `hosted_groq` — Collective's Groq key
- `byo_openrouter` — user's OpenRouter key (stored encrypted)
- `byo_openai` — user's OpenAI key (stored encrypted) [post-EP1]
- `byo_anthropic` — user's Anthropic key (stored encrypted) [post-EP1]

**Key functions:**
```python
def get_data_dir() -> Path                              # Returns DATA_DIR, creates subdirs on first call
def _fernet() -> Fernet                                 # Key derived from JWT_SECRET (32-byte pad)
def encrypt_key(plain: str) -> str                      # Fernet encrypt
def decrypt_key(enc: str) -> str                        # Fernet decrypt

def create_user(profile: UserProfile) -> UserProfile    # Writes to data/users/{id}.json
def get_user(user_id: str) -> Optional[UserProfile]
def get_user_by_handle(handle: str) -> Optional[UserProfile]
def get_user_by_api_key(api_key: str) -> Optional[UserProfile]
def save_user(profile: UserProfile) -> None             # Overwrite
def list_handles() -> set[str]                          # Fast uniqueness check

def create_invite(created_by: str, note: str = "", expires_days: int = 7) -> InviteToken
def get_invite(token: str) -> Optional[InviteToken]
def consume_invite(token: str, user_id: str) -> bool    # Returns False if expired/consumed
def list_invites() -> list[InviteToken]                 # Admin use
```

---

### `server/sessions.py`

Persistent conversation threads. Separate from `workflows.py` (which remains unchanged for structured tasks).

**Model:**

```python
class SessionMessage(BaseModel):
    role: str                  # "user" | "assistant"
    content: str
    timestamp: str             # ISO 8601

class SessionRecord(BaseModel):
    session_id: str            # UUID
    user_id: str
    created_at: str            # ISO 8601
    last_active: str           # ISO 8601
    title: Optional[str]       # Auto-set from first exchange ("first 8 words...")
    messages: list[SessionMessage] = []
```

**Storage:** `data/sessions/{user_id}/{session_id}.json`

**Key functions:**
```python
def create_session(user_id: str) -> SessionRecord
def get_session(session_id: str, user_id: str) -> Optional[SessionRecord]
def list_user_sessions(user_id: str) -> list[SessionRecord]   # Sorted newest-first, no messages
def append_message(session_id: str, user_id: str, role: str, content: str) -> None
def get_or_create_default(user_id: str) -> SessionRecord      # Gets most recent or creates new
def _auto_title(messages: list[SessionMessage]) -> str        # First user message, truncated to 8 words
```

---

## Changes to Existing Files

### `server/auth.py`

Add `handle` to JWT claims:

```python
def make_token(user_id: str, name: str, tier: str = "free", handle: str = "") -> str:
    payload = {
        "sub": user_id,
        "name": name,
        "handle": handle,   # ← new
        "tier": tier,
        "exp": datetime.utcnow() + timedelta(seconds=TTL),
    }
```

---

### `server/auth_routes.py`

**New endpoints** (add to existing router):

```python
# ── Admin: create invite ──────────────────────────────────────────────
POST /api/v1/admin/invites
    Auth: requires admin tier (X-Admin-Key or JWT with tier=="admin")
    Body: { note?: str, expires_days?: int = 7 }
    Returns: { token, url: "https://joinrabble.world/summon/{token}", expires_at, note }
    Status: 201

# ── Public: summon (register via invite) ─────────────────────────────
POST /api/v1/users/summon
    Auth: none (invite token is auth)
    Body: {
        invite_token: str,
        handle: str,          # slug, ≤24 chars, lowercase alphanum + hyphen
        display_name: str,
        intention: str,       # ≤500 chars
        llm_backend: str = "hosted_openrouter",
        byo_key?: str         # required if llm_backend starts with "byo_"
    }
    Returns: { api_key, user_id, handle, token: JWT, session_id }
    Status: 201
    Errors: 400 (invalid token), 409 (handle taken), 422 (validation)

# ── Authenticated: profile ────────────────────────────────────────────
GET /api/v1/users/me
    Auth: bearer or api_key
    Returns: full UserProfile (minus byo_key_enc)
    
PUT /api/v1/users/me
    Auth: bearer or api_key
    Body: { display_name?, intention?, llm_backend?, byo_key? }
    Returns: updated UserProfile
```

**Migration:** `POST /api/v1/auth/register` keeps its behavior but writes to file-based store. `_users_by_*` dicts replaced by `users.py` calls.

---

### `server/llm.py`

**New providers** (add to `BUILTIN_PROVIDERS`):

```python
"openai": {
    "url": "https://api.openai.com/v1/chat/completions",
    "api_key_env": "OPENAI_API_KEY",
},
"anthropic": {
    # Anthropic OpenAI-compat endpoint
    "url": "https://api.anthropic.com/v1/messages",   # Note: NOT compat; handle separately
    "api_key_env": "ANTHROPIC_API_KEY",
    "extra_headers": {"anthropic-version": "2023-06-01"},
    "type": "anthropic",   # Flag for special handling
},
```

**New function: per-user backend routing**

```python
def resolve_user_chain(user: dict, model_tier: str = "medium") -> list[dict]:
    """
    Returns the model chain for this user based on their llm_backend setting.
    Falls back to DEFAULT_MODEL_CHAINS[model_tier] if backend is hosted.
    For BYO backends, returns a single-item chain using the user's key.
    """
    backend = user.get("llm_backend", "hosted_openrouter")
    if backend == "hosted_groq":
        # Use Groq-first chain
        return [c for c in DEFAULT_MODEL_CHAINS[model_tier] if c["provider"] == "groq"] \
               or DEFAULT_MODEL_CHAINS[model_tier]
    elif backend == "byo_openrouter":
        byo_key = user.get("byo_key_plain")  # Decrypted by caller
        if byo_key:
            return [{"provider": "openrouter_byo", "model": DEFAULT_MODEL_CHAINS[model_tier][0]["model"],
                     "api_key_override": byo_key}]
    elif backend == "byo_openai":
        byo_key = user.get("byo_key_plain")
        if byo_key:
            return [{"provider": "openai", "model": "gpt-4o", "api_key_override": byo_key}]
    # Default: hosted_openrouter chain
    return DEFAULT_MODEL_CHAINS[model_tier]
```

**Signature changes** — add optional `user` param to public functions:

```python
async def stream_chat(
    messages: list[dict],
    system_prompt: str,
    model_tier: str = "medium",
    user: dict | None = None,        # ← new; if provided, uses resolve_user_chain
) -> AsyncGenerator[str, None]: ...

async def complete_chat(
    messages: list[dict],
    system_prompt: str,
    model_tier: str = "medium",
    user: dict | None = None,        # ← new
) -> str: ...
```

---

### `server/main.py`

**New session routes:**

```python
# Create or get default session
POST /api/v1/sessions
    Auth: required
    Body: {} (empty, or { resume: bool = true })
    Returns: { session_id, created_at, last_active, title, message_count }
    Status: 201 (created) or 200 (resumed existing)

# List user sessions
GET /api/v1/sessions
    Auth: required
    Returns: [ { session_id, title, created_at, last_active, message_count } ]

# Get session with history
GET /api/v1/sessions/{session_id}
    Auth: required
    Returns: full SessionRecord including messages

# Send message in session (streaming)
POST /api/v1/sessions/{session_id}/message
    Auth: required
    Body: { content: str, model_tier?: str = "auto" }
    Returns: SSE stream (same format as /api/v1/chat)
    Effect: appends user message + assistant response to session history
```

**Update existing chat routes** to pass `user` dict to `llm.stream_chat` / `llm.complete_chat` for per-user backend routing.

**System prompt for sessions** — inject user's intention:

```python
def build_session_prompt(user: dict, workflow_type: str = "default") -> str:
    base = agents.rabble_system_prompt(workflow_type)
    intention = user.get("intention", "")
    handle = user.get("handle", "")
    if intention:
        base += f"\n\n---\nYou are speaking with {handle}. Their intention: {intention}"
    return base
```

---

### Storage — ephemeral (free tier)

> **The live service runs on Render's free tier, which has NO persistent disk.**
> Data lives at `DATA_DIR=/tmp/rabble-data` and resets on restart/cold-sleep. Durable
> client state lives in the browser (`localStorage`: `rabble_jwt`, `rabble_session_id`).
> Persistent membership data (users/invites) needs an external store or a paid plan with a
> disk — deferred. `render.yaml` is **reference-only** (the live service is a plain Web
> Service, not a Blueprint); env is set via `spells/render-ctl.sh`. See
> `RaBbLE-sCoRE-Architecture.md → Deployment (Live — Render)`.

---

## New World Pages

### `world/summon.html`

The summoning ceremony. Reached via `joinrabble.world/summon?token={token}` or `joinrabble.world/summon.html?token={token}`.

**Flow:**
1. Page loads → extract `?token=` from URL
2. If no token: show "You need an invitation" message
3. If token present: show summoning form
4. Form: display_name, handle, intention (textarea), llm_backend select, optional BYO key field
5. Submit → `POST /api/v1/users/summon` → store JWT + api_key in localStorage → redirect to `RaBbLE-Chat.html`

**Visual:** Uses Aether classes + summoning-specific CSS. Should feel ceremonial — not a signup form.

### `world/account.html`

Account management. Reached from chat header or direct link.

**Sections:**
- Identity: handle, display_name, join_date, intention (editable)
- Backend: current llm_backend, change + BYO key entry
- Session history: list of past sessions with links
- Export: download session history as JSON
- Pair info: entity ID, session count

---

## sCoRE Chat Page Updates

**`world/RaBbLE-Chat.html`** — add auth gate:
- On load: check localStorage for JWT → if none, redirect to `summon.html` (or show login modal)
- Show user handle + entity pairing ID in header

**`world/js/RaBbLE-chat.js`** — session-aware:
- On init: get or create session via `POST /api/v1/sessions`
- Load session history into message list on resume
- Send messages via `POST /api/v1/sessions/{session_id}/message` (streaming)
- Include JWT in Authorization header

---

## Data Directory Bootstrap

`server/users.py` must call `get_data_dir()` at import time to ensure directories exist. This is idempotent.

```python
def get_data_dir() -> Path:
    base = Path(os.getenv("DATA_DIR", "data"))
    for subdir in ("users", "invites", "sessions"):
        (base / subdir).mkdir(parents=True, exist_ok=True)
    return base
```

---

## Backward Compatibility

- `POST /api/v1/auth/register` — still works, creates UserProfile with auto-handle from name
- `POST /api/v1/auth/token` — still works, exchanges api_key for JWT (now with handle)
- `GET /api/v1/auth/me` — still works, returns same shape
- `/api/v1/chat` — still works, now uses per-user backend if user is authenticated with profile
- Workflows — unchanged

---

```
transcribe ~ grimoire >> sCoRE membership API spec locked for ep1 // %MEMBERSHIP_API%
```
