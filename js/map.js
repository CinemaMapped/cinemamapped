(function () {
  'use strict';

  // ── State ──────────────────────────────────────────────────
  var allPins      = [];
  var activeTheatre = 'all';
  var searchTerm   = '';
  var clusterGroup;
  var searchTimer;

  // ── Map init ───────────────────────────────────────────────
  var map = L.map('map', {
    center:              [48, 12],
    zoom:                5,
    minZoom:             2,
    maxZoom:             16,
    maxBounds:           [[-85, -200], [85, 200]],
    maxBoundsViscosity:  0.85,
    zoomControl:         true,
    attributionControl:  true,
  });

  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; <a href="https://carto.com/" target="_blank" rel="noopener">CARTO</a> &copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap</a>',
    subdomains:  'abcd',
    maxZoom:     19,
  }).addTo(map);

  // ── Cluster group ──────────────────────────────────────────
  clusterGroup = L.markerClusterGroup({
    showCoverageOnHover:  false,
    maxClusterRadius:     52,
    chunkedLoading:       true,
    iconCreateFunction: function (cluster) {
      return L.divIcon({
        className:  'gold-cluster',
        html:       '<div class="gold-cluster-inner">' + cluster.getChildCount() + '</div>',
        iconSize:   [34, 34],
        iconAnchor: [17, 17],
      });
    },
  });

  map.addLayer(clusterGroup);

  // ── Pin icon ───────────────────────────────────────────────
  function goldIcon() {
    return L.divIcon({
      className:  'gold-pin',
      html:       '<div class="gold-pin-dot"></div>',
      iconSize:   [12, 12],
      iconAnchor: [6, 6],
    });
  }

  // ── Panel ──────────────────────────────────────────────────
  var panel     = document.getElementById('pin-panel');
  var panelClose = document.getElementById('pin-close');

  function openPanel(pin) {
    document.getElementById('pin-badges').innerHTML =
      '<span class="badge badge-type">'    + escapeHtml(pin.type)    + '</span>' +
      '<span class="badge badge-theatre">' + escapeHtml(pin.theatre) + '</span>';

    document.getElementById('pin-title').textContent    = pin.title;
    document.getElementById('pin-location').textContent = pin.location;
    document.getElementById('pin-desc').textContent     = pin.description;

    var yearEl = document.getElementById('pin-year');
    yearEl.textContent = pin.year_portrayed ? 'Year portrayed: ' + pin.year_portrayed : '';

    var streamEl = document.getElementById('pin-streaming');
    if (pin.streaming && isHttpUrl(pin.streaming)) {
      streamEl.innerHTML =
        '<a href="' + escapeHtml(pin.streaming) + '" target="_blank" rel="noopener noreferrer">' +
        'Watch online &#x2197;</a>';
    } else {
      streamEl.innerHTML = '';
    }

    panel.classList.add('open');
    panel.setAttribute('aria-hidden', 'false');
  }

  function closePanel() {
    panel.classList.remove('open');
    panel.setAttribute('aria-hidden', 'true');
  }

  panelClose.addEventListener('click', closePanel);
  map.on('click', closePanel);

  // ── Render markers ─────────────────────────────────────────
  function renderMarkers() {
    clusterGroup.clearLayers();

    var term = searchTerm.toLowerCase().trim();

    allPins.forEach(function (pin) {
      var matchTheatre = activeTheatre === 'all' || pin.theatre === activeTheatre;
      var matchSearch  = !term ||
        pin.title.toLowerCase().includes(term) ||
        pin.location.toLowerCase().includes(term) ||
        pin.country.toLowerCase().includes(term);

      if (!matchTheatre || !matchSearch) return;

      var marker = L.marker([pin.lat, pin.lng], { icon: goldIcon() });

      marker.on('click', (function (p) {
        return function (e) {
          L.DomEvent.stopPropagation(e);
          openPanel(p);
        };
      }(pin)));

      clusterGroup.addLayer(marker);
    });
  }

  // ── Theatre filter chips ───────────────────────────────────
  document.querySelectorAll('.chip').forEach(function (chip) {
    chip.addEventListener('click', function () {
      document.querySelectorAll('.chip').forEach(function (c) {
        c.classList.remove('active');
      });
      chip.classList.add('active');
      activeTheatre = chip.dataset.theatre;
      closePanel();
      renderMarkers();
    });
  });

  // ── Search ─────────────────────────────────────────────────
  var searchInput = document.getElementById('map-search');

  searchInput.addEventListener('input', function () {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(function () {
      searchTerm = searchInput.value;
      closePanel();
      renderMarkers();
    }, 220);
  });

  // ── URL param: ?film=Title ──────────────────────────────────
  function applyUrlParams() {
    var params    = new URLSearchParams(window.location.search);
    var filmParam = params.get('film');

    if (!filmParam) return;

    searchInput.value = filmParam;
    searchTerm        = filmParam;
    renderMarkers();

    var filmPins = allPins.filter(function (p) {
      return p.title === filmParam;
    });

    if (filmPins.length > 0) {
      var bounds = L.latLngBounds(filmPins.map(function (p) {
        return [p.lat, p.lng];
      }));
      map.fitBounds(bounds, { padding: [80, 80], maxZoom: 8 });
    }
  }

  // ── Load data ──────────────────────────────────────────────
  fetch('data.json')
    .then(function (r) { return r.json(); })
    .then(function (data) {
      allPins = data;
      renderMarkers();
      applyUrlParams();
    })
    .catch(function (err) {
      console.error('CinemaMapped: failed to load data.json', err);
    });

  // ── Helpers ────────────────────────────────────────────────
  function escapeHtml(str) {
    var d = document.createElement('div');
    d.appendChild(document.createTextNode(String(str)));
    return d.innerHTML;
  }

  function isHttpUrl(str) {
    try {
      var u = new URL(str);
      return u.protocol === 'http:' || u.protocol === 'https:';
    } catch (_) {
      return false;
    }
  }

})();
