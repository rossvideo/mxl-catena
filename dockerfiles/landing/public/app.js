(function () {
  const ACTIVE_URL = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? `http://localhost:3000/api/active`
    : `http://${window.location.hostname}:3000/api/active`;
  const MP42TS_BASE = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? `http://localhost:3000`
    : `http://${window.location.hostname}:3000`;

  // Initialize Mermaid after transforming blocks
  mermaid.initialize({ startOnLoad: true, securityLevel: 'loose' });

  function setLed(led, state) {
    led.classList.remove('led-gray', 'led-green', 'led-red');
    if (state === 'on') led.classList.add('led-green');
    else if (state === 'off') led.classList.add('led-gray');
    else led.classList.add('led-red');
  }

  function animateEdge(edge, state) {
    if (state === "on") edge.classList.add('edge-animation-fast');
    else edge.classList.remove('edge-animation-fast');
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
    const mp42tsLED = document.getElementById('led-mp42ts');
    const ts2mxlLED = document.getElementById('led-ts2mxl');
    const pat2mxlLED = document.getElementById('led-pat2mxl');
    const mxl2ndiLED = document.getElementById('led-mxl2ndi');
    const e1 = document.getElementById('e1');
    const e2 = document.getElementById('e2');
    const e3 = document.getElementById('e3');
    const e4 = document.getElementById('e4');
    // mermaid not rendered yet
    if (!mp42tsLED  || !ts2mxlLED || !pat2mxlLED || !mxl2ndiLED) return;
    if (e1 === null || e2 === null || e3 === null || e4 === null) return;
    try {
      const res = await fetch(ACTIVE_URL, { headers: { 'Accept': 'application/json' } });
      if (!res.ok) throw new Error('Bad status ' + res.status);
      const data = await res.json();
      const active = data && data.main;
      setLed(mp42tsLED, active ? 'on' : 'off');
      animateEdge(e1, active ? 'on' : 'off');
    } catch (e) {
      setLed(mp42tsLED, 'err');
      animateEdge(e1, 'err');
    }
    const ts2mxlStatus = await catenaStatus('ts2mxl');
    const mxl2ndiStatus = await catenaStatus('mxl2ndi');
    const pat2mxlStatus = 'on'; // always on
    setLed(ts2mxlLED, ts2mxlStatus);
    animateEdge(e2, ts2mxlStatus);
    setLed(mxl2ndiLED, mxl2ndiStatus);
    animateEdge(e4, mxl2ndiStatus);
    setLed(pat2mxlLED, pat2mxlStatus);
    animateEdge(e3, pat2mxlStatus);
    // mxl2ndiStartBtn.disabled = (ts2mxlStatus !== 'on');
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

  window.asdf = function() {
    alert('Callback invoked');
  }

  // ts2mxlStartBtn.addEventListener('click', () => {
  //   runningToggle('ts2mxl');
  // });

  // mxl2ndiStartBtn.addEventListener('click', () => {
  //   runningToggle('mxl2ndi');
  // });

  // Toggle MP4→TS stream on click unless opening in new tab
  // document.getElementById('btn-mp42ts').addEventListener('click', (ev) => {
  //   if (ev.ctrlKey || ev.metaKey || ev.shiftKey || ev.button !== 0) {
  //     // allow default navigation (open UI)
  //     return;
  //   }
  //   ev.preventDefault();
  //   toggleMp42ts();
  // });

  // Initialize as unknown/off, then poll
  // setLed(mp42tsLED, 'off');
  // setLed(ts2mxlLED, 'off');
  // setLed(mxl2ndiLED, 'off');
  poll();
  setTimeout(poll, 500);
  setInterval(poll, 2000);
})();
