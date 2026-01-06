# streamer-web

Dockerized Node.js tool that serves a simple webpage to browse a mounted videos directory and control ffmpeg-based streaming to MPEG-TS files stored in `/dev/shm`.

## Features
- Lists nested videos from mounted `VIDEOS_DIR`.
- Per-file controls: "stream to main", "stream to own", "stop streams".
- Main stream writes to `/dev/shm/main.ts`.
- Own streams write to `/dev/shm/own-<uuid>.ts`.
- `/dev/shm/info.json` tracks active streams and last update time.
- Cleans up `.ts` files when the container stops.

## Quick Start

Create or choose a host videos directory, then run:

```bash
export VIDEOS_DIR_HOST=/path/to/your/videos
docker compose up --build
```

Open `http://localhost:3000` to view the UI.

## API
- `GET /api/files`: List nested files under `/videos`.
- `POST /api/stream/main { file }`: Stream selected file to `/dev/shm/main.ts`.
- `POST /api/stream/own { file }`: Stream selected file to a unique `/dev/shm/own-<uuid>.ts`.
- `POST /api/stream/stop`: Stop all ffmpeg processes.
- `GET /api/info`: Read `/dev/shm/info.json` contents.
- `POST /api/cleanup`: Internal cleanup endpoint used on container stop; deletes all `.ts` files in `/dev/shm`.

## Notes
- Requires ffmpeg (installed in the container).
- Only files detected as videos (via MIME) enable streaming buttons.
- Mounted `/dev/shm` must exist on the host; typical on Linux.
