(function () {
  const mp42tsLED = document.getElementById('led-mp42ts');
  const ACTIVE_URL = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? `http://localhost:3000/api/active`
    : `http://${window.location.hostname}:3000/api/active`;
  const MP42TS_BASE = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? `http://localhost:3000`
    : `http://${window.location.hostname}:3000`;
  const ts2mxlLED = document.getElementById('led-ts2mxl');
  const mxl2ndiLED = document.getElementById('led-mxl2ndi');
  const ts2mxlStartBtn = document.getElementById('btn-ts2mxl');
  const mxl2ndiStartBtn = document.getElementById('btn-mxl2ndi');

  function setLed(led, state) {
    led.classList.remove('led-gray', 'led-green', 'led-red');
    if (state === 'on') led.classList.add('led-green');
    else if (state === 'off') led.classList.add('led-gray');
    else led.classList.add('led-red');
  }

  async function catenaStatus(svc) {
    const res = await fetch(`api/${svc}/status`, { headers: { 'Accept': 'application/json' } });
    if (!res.ok) return "err";
    const data = await res.json();
    const status = data && data.string_value;
    if (status === 'Running') return "on";
    else if (status === 'Stopped') return "off";
    else return "err";
  }

  async function poll() {
    try {
      const res = await fetch(ACTIVE_URL, { headers: { 'Accept': 'application/json' } });
      if (!res.ok) throw new Error('Bad status ' + res.status);
      const data = await res.json();
      const active = data && data.main;
      setLed(mp42tsLED, active ? 'on' : 'off');
    } catch (e) {
      setLed(mp42tsLED, 'err');
    }
    const ts2mxlStatus = await catenaStatus('ts2mxl');
    const mxl2ndiStatus = await catenaStatus('mxl2ndi');
    setLed(ts2mxlLED, ts2mxlStatus);
    setLed(mxl2ndiLED, mxl2ndiStatus);
    mxl2ndiStartBtn.disabled = (ts2mxlStatus !== 'on');
  }

  const runningToggle = (svc) => {
    fetch(`api/${svc}/status`, { headers: { 'Accept': 'application/json' } })
      .then(res => {
        if (!res.ok) throw new Error('Bad status ' + res.status);
        return res.json();
      })
      .then(data => {
        const status = data && data.string_value;
        if (status === 'Running') {
          // If already running, stop it
          return fetch(`api/${svc}/stop`, { method: 'POST' })
            .then(() => poll());
        } else {
          // If stopped or error, start it
          return fetch(`api/${svc}/start`, { method: 'POST' })
            .then(() => poll());
        }
      })
      .catch(() => {
        // On error, try starting it
        return fetch(`api/${svc}/start`, { method: 'POST' })
          .then(() => poll());
      });

  }

  async function toggleMp42ts() {
    try {
      const res = await fetch(`${MP42TS_BASE}/api/active`, { headers: { 'Accept': 'application/json' } });
      const data = await res.json();
      const isRunning = !!(data && data.main);
      if (isRunning) {
        await fetch(`${MP42TS_BASE}/api/stream/stop`, { method: 'POST' });
      } else {
        // Find first video under /videos via mp42ts API
        const filesRes = await fetch(`${MP42TS_BASE}/api/files`, { headers: { 'Accept': 'application/json' } });
        const files = await filesRes.json();
        const first = findFirstVideoPathInTree(files && files.tree);
        if (!first) throw new Error('No video found to start');
        await fetch(`${MP42TS_BASE}/api/stream/main`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ file: first })
        });
      }
    } catch (e) {
      // On error, try to start anyway using first video
      try {
        const filesRes = await fetch(`${MP42TS_BASE}/api/files`, { headers: { 'Accept': 'application/json' } });
        const files = await filesRes.json();
        const first = findFirstVideoPathInTree(files && files.tree);
        if (first) {
          await fetch(`${MP42TS_BASE}/api/stream/main`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ file: first })
          });
        }
      } catch {}
    } finally {
      poll();
    }
  }

  function findFirstVideoPathInTree(tree) {
    if (!Array.isArray(tree)) return null;
    for (const node of tree) {
      const p = findFirstVideoRec(node);
      if (p) return p;
    }
    return null;
  }

  function findFirstVideoRec(node) {
    if (!node) return null;
    if (node.type === 'file' && node.isVideo) return node.path;
    if (node.type === 'dir' && Array.isArray(node.children)) {
      for (const child of node.children) {
        const p = findFirstVideoRec(child);
        if (p) return p;
      }
    }
    return null;
  }

  ts2mxlStartBtn.addEventListener('click', () => {
    runningToggle('ts2mxl');
  });

  mxl2ndiStartBtn.addEventListener('click', () => {
    runningToggle('mxl2ndi');
  });

  // Toggle MP4→TS stream on click unless opening in new tab
  document.getElementById('btn-mp42ts').addEventListener('click', (ev) => {
    if (ev.ctrlKey || ev.metaKey || ev.shiftKey || ev.button !== 0) {
      // allow default navigation (open UI)
      return;
    }
    ev.preventDefault();
    toggleMp42ts();
  });

  // Initialize as unknown/off, then poll
  setLed(mp42tsLED, 'off');
  setLed(ts2mxlLED, 'off');
  setLed(mxl2ndiLED, 'off');
  poll();
  setInterval(poll, 2000);
})();
