(function () {
  const mp42tsLED = document.getElementById('led-mp42ts');
  const ACTIVE_URL = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? `http://localhost:3000/api/active`
    : `http://${window.location.hostname}:3000/api/active`;
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
    [[ts2mxlLED, 'ts2mxl'], [mxl2ndiLED, 'mxl2ndi']].forEach(([led, svc]) => {
      fetch(`api/${svc}/status`, { headers: { 'Accept': 'application/json' } })
        .then(res => {
          if (!res.ok) throw new Error('Bad status ' + res.status);
          return res.json();
        })
        .then(data => {
          const status = data && data.string_value;
          if (status === 'Running') setLed(led, 'on');
          else if (status === 'Stopped') setLed(led, 'off');
          else setLed(led, 'err');
        })
        .catch(err => {
          setLed(led, 'err');
        });
    });
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

  ts2mxlStartBtn.addEventListener('click', () => {
    runningToggle('ts2mxl');
  });

  mxl2ndiStartBtn.addEventListener('click', () => {
    runningToggle('mxl2ndi');
  });

  // Initialize as unknown/off, then poll
  setLed(mp42tsLED, 'off');
  setLed(ts2mxlLED, 'off');
  setLed(mxl2ndiLED, 'off');
  poll();
  setInterval(poll, 2000);
})();
