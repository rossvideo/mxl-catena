(function(){
  const LED = document.getElementById('led-mp42ts');
  const ACTIVE_URL = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? `http://localhost:3000/api/active`
    : `http://${window.location.hostname}:3000/api/active`;

  function setLed(state) {
    LED.classList.remove('led-gray','led-green','led-red');
    if (state === 'on') LED.classList.add('led-green');
    else if (state === 'off') LED.classList.add('led-gray');
    else LED.classList.add('led-red');
  }

  async function poll() {
    try {
      const res = await fetch(ACTIVE_URL, { headers: { 'Accept': 'application/json' } });
      if (!res.ok) throw new Error('Bad status '+res.status);
      const data = await res.json();
      const active = data && data.main;
      setLed(active ? 'on' : 'off');
    } catch (e) {
      setLed('err');
    }
  }

  // Initialize as unknown/off, then poll
  setLed('off');
  poll();
  setInterval(poll, 2000);
})();
