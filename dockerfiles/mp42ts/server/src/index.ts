import express from 'express';
import cors from 'cors';
import path from 'path';
import fs, { Dirent } from 'fs';
import { spawn } from 'child_process';
import { lookup as mimeLookup } from 'mime-types';
import { v4 as uuidv4 } from 'uuid';
// eslint-disable-next-line @typescript-eslint/no-explicit-any
declare const process: any;

const app = express();
app.use(cors());
app.use(express.json());

// Disable client-side caching for static assets to see changes immediately
app.use((req: express.Request, res: express.Response, next) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  next();
});

const VIDEOS_DIR = process.env.VIDEOS_DIR || '/videos';
const SHM_DIR = '/dev/shm';
const INFO_PATH = path.join(SHM_DIR, 'info.json');
const MAIN_TS = path.join(SHM_DIR, 'main.ts');

// Track running ffmpeg processes
type Mode = 'main' | 'own';
type FileNode = { type: 'file'; name: string; path: string; isVideo: boolean };
type DirNode = { type: 'dir'; name: string; path: string; children: NodeType[] };
type NodeType = FileNode | DirNode;

const processes: Record<string, { pid: number; mode: Mode; input: string; output: string }> = {};

async function ffprobeJson(inputPath: string) {
  return new Promise<any>((resolve) => {
    const args = ['-v', 'quiet', '-show_format', '-show_streams', '-print_format', 'json', inputPath];
    const pr = spawn('ffprobe', args);
    let buf = '';
    pr.stdout.on('data', (d: any) => { buf += String(d); });
    pr.stderr.on('data', () => {});
    pr.on('close', () => {
      try {
        resolve(JSON.parse(buf));
      } catch {
        resolve({});
      }
    });
  });
}

async function writeInfo() {
  const mainActive = Object.values(processes).find(p => p.mode === 'main');
  const info = mainActive ? await ffprobeJson(mainActive.input) : {};
  try {
    if (!fs.existsSync(SHM_DIR)) fs.mkdirSync(SHM_DIR, { recursive: true });
    fs.writeFileSync(INFO_PATH, JSON.stringify(info, null, 2));
  } catch (e) {
    console.error('Failed to write info.json:', e);
  }
}

function isVideo(file: string) {
  const type = mimeLookup(file) || '';
  return String(type).startsWith('video/');
}

function listFilesRecursive(dir: string): NodeType[] {
  const entries: Dirent[] = fs.readdirSync(dir, { withFileTypes: true });
  return entries.map((e: Dirent): NodeType => {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      const children = listFilesRecursive(full);
      const node: DirNode = { type: 'dir', name: e.name, path: full, children };
      return node;
    } else {
      const node: FileNode = { type: 'file', name: e.name, path: full, isVideo: isVideo(full) };
      return node;
    }
  });
}

function startFfmpeg(inputPath: string, outputPath: string, mode: Mode) {
  const args = [
    '-y',
    '-stream_loop', '-1',
    '-fflags', '+genpts',
    '-re',
    '-i', inputPath,
    '-f', 'mpegts',
    '-codec:v', 'mpeg2video',
    '-codec:a', 'mp2',
    outputPath
  ];
  const ff = spawn('ffmpeg', args, { stdio: 'ignore' });
  const id = uuidv4();
  processes[id] = { pid: ff.pid ?? Date.now(), mode, input: inputPath, output: outputPath };
  console.log(`[stream:${mode}] started`, { input: inputPath, output: outputPath, pid: ff.pid });
  ff.on('exit', () => {
    delete processes[id];
    console.log(`[stream:${mode}] exited`, { input: inputPath, output: outputPath });
    writeInfo();
  });
  writeInfo();
  return { id };
}

function stopAll() {
  Object.keys(processes).forEach(id => {
    try { process.kill(processes[id].pid); } catch {}
    delete processes[id];
  });
  console.log('[stream] all streams stopped');
  writeInfo();
}

app.get('/api/files', (req: express.Request, res: express.Response) => {
  try {
    const tree = listFilesRecursive(VIDEOS_DIR);
    res.json({ root: VIDEOS_DIR, tree });
  } catch (e) {
    res.status(500).json({ error: 'Failed to list files', details: String(e) });
  }
});

app.post('/api/stream/main', (req: express.Request, res: express.Response) => {
  const { file } = req.body as { file: string };
  if (!file || !fs.existsSync(file)) return res.status(400).json({ error: 'Invalid file' });
  console.log('[stream] switching main stream to', file);
  stopAll();
  if (!fs.existsSync(SHM_DIR)) fs.mkdirSync(SHM_DIR, { recursive: true });
  const out = MAIN_TS;
  const { id } = startFfmpeg(file, out, 'main');
  res.json({ id, output: out });
});

// 'stream to own' removed per request

app.post('/api/stream/stop', (req: express.Request, res: express.Response) => {
  stopAll();
  res.json({ ok: true });
});

app.get('/api/info', (req: express.Request, res: express.Response) => {
  try {
    const info = fs.existsSync(INFO_PATH) ? JSON.parse(fs.readFileSync(INFO_PATH, 'utf-8')) : {};
    res.json(info);
  } catch (e) {
    res.status(500).json({ error: 'Failed to read info.json', details: String(e) });
  }
});

// Active stream status (path of current main input)
app.get('/api/active', (req: express.Request, res: express.Response) => {
  try {
    const main = Object.values(processes).find(p => p.mode === 'main');
    res.json({ main: main ? { input: main.input, output: main.output } : null });
  } catch (e) {
    res.status(500).json({ error: 'Failed to read active status', details: String(e) });
  }
});

// Serve static web UI
app.use('/', express.static(path.join(process.env.WEB_DIR || path.join(process.cwd(), 'web'))));

// Serve thumbnails if present
app.get('/api/thumbnail', (req: express.Request, res: express.Response) => {
  const p = String(req.query.path || '');
  if (!p) return res.status(400).send('missing path');
  if (!fs.existsSync(p)) return res.status(404).send('not found');
  res.sendFile(p);
});

// Cleanup endpoint (used by preStop)
app.post('/api/cleanup', (req: express.Request, res: express.Response) => {
  stopAll();
  cleanupTsFiles();
  res.json({ ok: true });
});

// Serve mounted videos (including thumbnails) directly
app.use('/videos', express.static(VIDEOS_DIR));

const PORT = Number(process.env.PORT || 3000);
app.listen(PORT, () => {
  console.log(`Server listening on :${PORT}`);
});

function cleanupTsFiles() {
  try {
    if (!fs.existsSync(SHM_DIR)) return;
    const files = fs.readdirSync(SHM_DIR);
    for (const f of files) {
      if (f.endsWith('.ts')) {
        try { fs.unlinkSync(path.join(SHM_DIR, f)); } catch (e) { console.error('Failed to remove', f, e); }
      }
    }
    try {
      if (fs.existsSync(INFO_PATH)) fs.unlinkSync(INFO_PATH);
    } catch (e) {
      console.error('Failed to remove info.json', e);
    }
  } catch (e) {
    console.error('Cleanup error:', e);
  }
}

let shuttingDown = false;
function handleShutdown(signal: string) {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log('Received', signal, '- cleaning up...');
  try {
    stopAll();
    cleanupTsFiles();
  } finally {
    process.exit(0);
  }
}

process.on('SIGTERM', () => handleShutdown('SIGTERM'));
process.on('SIGINT', () => handleShutdown('SIGINT'));
process.on('exit', () => {
  if (!shuttingDown) {
    try { cleanupTsFiles(); } catch {}
  }
});
