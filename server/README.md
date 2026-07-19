# upscaler-bridge

A small FastAPI service backing the app's optional server-side features —
debug logging, temporary cloud storage for imports/exports, custom presets,
device settings backup, and a model registry — mirroring Lumisound's
`ios-bridge` pattern. **Live**: deployed at
`https://upscaler-bridge.xenusanimations.studio` (see `docker-compose.yml`
in the `music` compose project, `upscaler-bridge` service).

Every endpoint here is verified end-to-end against a throwaway MariaDB
container before being deployed — round-tripped requests, correct
byte-exact image storage, TTL expiry actually firing, upsert correctness —
not just "the code compiles."

## Endpoints

**Debug logging**
- `POST /log/upscale` — records one upscale attempt (see `UpscaleLogEntry`)
- `GET /log/history?device_id=...&limit=&offset=` — recent entries
- `POST /log/action` — records one non-upscale action (Save, Compare Models,
  Cutout, a Settings change, ...) with a free-form `detail` JSON string
  (see `ActionLogEntry`)
- `GET /log/action-history?device_id=...&action=...&limit=&offset=` —
  recent action entries

**Temporary image storage** (imports = pre-upscale, exports = post-upscale;
both auto-expire — see "Expiry" below)
- `POST /import` (multipart: `device_id`, `ttl_hours` optional, `file`)
- `GET /import/{id}` — raw image bytes
- `GET /import?device_id=...` — metadata list (no image bytes)
- `DELETE /import/{id}`
- `POST /export` (multipart: `device_id`, `history_id` optional, `ttl_hours`
  optional, `file`) — `history_id` links back to the `upscale_history` row
  that produced this result
- `GET /export/{id}`, `GET /export?device_id=...`, `DELETE /export/{id}`

**Custom presets** (named model+overlap combos, permanent — not TTL'd)
- `POST /presets` — upsert by `(device_id, name)`, returns the stored `id`
- `GET /presets?device_id=...`
- `DELETE /presets/{id}`

**Device settings backup/restore** (manually-triggered — no accounts, so
this is a per-device_id backup slot, not automatic multi-device sync)
- `PUT /device-settings` — upsert
- `GET /device-settings?device_id=...` — 404 if never backed up

**Model registry**
- `GET /models` — metadata for available models (display name, description,
  license, tile size, scale factor)

`GET /health` needs no auth; everything else requires
`Authorization: Bearer <key>` if `UPSCALER_BRIDGE_API_KEY` is set.

## Expiry

`image_imports`/`image_exports` rows carry an `expires_at`; a background
loop (started in the FastAPI `lifespan`) deletes expired rows hourly, and
every import/export write also triggers a best-effort opportunistic
cleanup pass — so expiry doesn't solely depend on the hourly timer.
`ttl_hours` defaults to 24, capped at 168 (7 days). This is scratch
storage, not a photo library — nothing here is meant to be permanent.

## Uploads

Capped at 20MB per file (`MAX_UPLOAD_BYTES` in `main.py`) — comfortably
under typical MariaDB `max_allowed_packet` defaults. Raise both together if
larger uploads are ever needed. Image dimensions are read server-side via
Pillow rather than trusted from client-supplied metadata.

## Running

Environment variables (all have dev-friendly defaults except `DB_PASSWORD`,
which has none on purpose — set it explicitly):

| Variable | Default |
|---|---|
| `DB_HOST` | `127.0.0.1` |
| `DB_PORT` | `3306` |
| `DB_USER` | `upscaler` |
| `DB_PASSWORD` | *(none — required)* |
| `DB_NAME` | `image_upscaler` |
| `UPSCALER_BRIDGE_API_KEY` | *(none — auth disabled)* |
| `PORT` | `8003` |

```bash
pip install -r requirements.txt
DB_PASSWORD=... uvicorn main:app --host 0.0.0.0 --port 8003
```

Or via Docker:

```bash
docker build -t upscaler-bridge .
docker run -p 8003:8003 -e DB_HOST=... -e DB_PASSWORD=... upscaler-bridge
```
