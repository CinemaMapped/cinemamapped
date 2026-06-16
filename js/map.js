(function () {
  'use strict';

  // ── State ──────────────────────────────────────────────────
  var allPins       = [];
  var activeTheatre = 'all';
  var activeTitle   = '';
  var searchTerm    = '';
  var clusterGroup;
  var routeLayer    = null;
  var searchTimer;

  // ── Map init ───────────────────────────────────────────────
  var map = L.map('map', {
    center:             [48, 12],
    zoom:               5,
    minZoom:            2,
    maxZoom:            16,
    maxBounds:          [[-85, -200], [85, 200]],
    maxBoundsViscosity: 0.85,
    zoomControl:        true,
    attributionControl: true,
  });

  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; <a href="https://carto.com/" target="_blank" rel="noopener">CARTO</a> &copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap</a>',
    subdomains:  'abcd',
    maxZoom:     19,
  }).addTo(map);

  // ── Cluster group ──────────────────────────────────────────
  clusterGroup = L.markerClusterGroup({
    showCoverageOnHover: false,
    maxClusterRadius:    52,
    chunkedLoading:      true,
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

  // ── Route lines ────────────────────────────────────────────
  function clearRoute() {
    if (routeLayer) {
      map.removeLayer(routeLayer);
      routeLayer = null;
    }
  }

  function drawRoute(pins) {
    clearRoute();
    if (pins.length < 2) return;
    var sorted = pins.slice().sort(function (a, b) {
      return (a.sequence || 0) - (b.sequence || 0);
    });
    var latlngs = sorted.map(function (p) { return [p.lat, p.lng]; });
    routeLayer = L.polyline(latlngs, {
      color:     '#c9a84c',
      weight:    2,
      opacity:   0.55,
      dashArray: '6 8',
    }).addTo(map);
  }

  function drawRouteForTitle(title) {
    var pins = allPins.filter(function (p) { return p.title === title; });
    if (pins.length > 1 && pins.some(function (p) { return p.sequence != null; })) {
      drawRoute(pins);
    }
  }

  // ── Panel ──────────────────────────────────────────────────
  var panel      = document.getElementById('pin-panel');
  var panelClose = document.getElementById('pin-close');

  function openPanel(pin) {
    document.getElementById('pin-badges').innerHTML =
      '<span class="badge badge-type">'    + escapeHtml(pin.type)    + '</span>' +
      '<span class="badge badge-theatre">' + escapeHtml(pin.theatre) + '</span>';

    document.getElementById('pin-title').textContent    = pin.title;
    document.getElementById('pin-location').textContent = pin.location;
    document.getElementById('pin-desc').textContent     = pin.description;

    var historyWrap = document.getElementById('pin-history-wrap');
    if (pin.historical_context) {
      document.getElementById('pin-history-text').textContent = pin.historical_context;
      historyWrap.style.display = '';
    } else {
      historyWrap.style.display = 'none';
    }

    var yearEl = document.getElementById('pin-year');
    yearEl.textContent = pin.year_portrayed ? pin.year_portrayed : '';

    var watchEl = document.getElementById('pin-watch');
    if (pin.streaming && isHttpUrl(pin.streaming)) {
      watchEl.href          = escapeHtml(pin.streaming);
      watchEl.style.display = '';
    } else {
      watchEl.style.display = 'none';
    }

    panel.classList.add('open');
    panel.setAttribute('aria-hidden', 'false');

    // Always draw route for the clicked pin's film
    drawRouteForTitle(pin.title);

    if (window.gtag) {
      gtag('event', 'pin_click', {
        film_title:  pin.title,
        location:    pin.location,
        theatre:     pin.theatre,
        pin_type:    pin.type
      });
    }
  }

  function closePanel() {
    panel.classList.remove('open');
    panel.setAttribute('aria-hidden', 'true');
    // Only clear route if no title chip is locked
    if (!activeTitle) {
      clearRoute();
    }
  }

  panelClose.addEventListener('click', closePanel);
  map.on('click', closePanel);

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closePanel();
  });

  // ── Empty state ────────────────────────────────────────────
  var noResultsEl = document.getElementById('no-results');

  function updateEmptyState(count) {
    if (!noResultsEl) return;
    noResultsEl.style.display = count === 0 ? 'flex' : 'none';
  }

  // ── Pin count ──────────────────────────────────────────────
  var pinCountEl = document.getElementById('pin-count');

  function updatePinCount(visible) {
    if (!pinCountEl) return;
    if (visible < allPins.length) {
      pinCountEl.textContent = visible + ' of ' + allPins.length;
      pinCountEl.style.display = '';
    } else {
      pinCountEl.style.display = 'none';
    }
  }

  // ── Render markers ─────────────────────────────────────────
  function renderMarkers() {
    clusterGroup.clearLayers();
    clearRoute();

    var term        = searchTerm.toLowerCase().trim();
    var visiblePins = [];

    allPins.forEach(function (pin) {
      var matchTheatre = activeTheatre === 'all' || pin.theatre === activeTheatre;
      var matchTitle   = !activeTitle   || pin.title   === activeTitle;
      var matchSearch  = !term ||
        pin.title.toLowerCase().includes(term) ||
        pin.location.toLowerCase().includes(term) ||
        pin.country.toLowerCase().includes(term);

      if (!matchTheatre || !matchTitle || !matchSearch) return;

      visiblePins.push(pin);

      var marker = L.marker([pin.lat, pin.lng], { icon: goldIcon() });

      marker.on('click', (function (p) {
        return function (e) {
          L.DomEvent.stopPropagation(e);
          openPanel(p);
        };
      }(pin)));

      clusterGroup.addLayer(marker);
    });

    // Auto-draw route when all visible pins share one title
    if (visiblePins.length > 1) {
      var firstTitle  = visiblePins[0].title;
      var singleTitle = visiblePins.every(function (p) { return p.title === firstTitle; });
      var hasSequence = visiblePins.some(function (p) { return p.sequence != null; });
      if (singleTitle && hasSequence) {
        drawRoute(visiblePins);
      }
    }

    var count = clusterGroup.getLayers().length;
    updateEmptyState(count);
    updatePinCount(count);
  }

  // ── Title filter chips ─────────────────────────────────────
  document.querySelectorAll('.chip-title').forEach(function (chip) {
    chip.addEventListener('click', function () {
      document.querySelectorAll('.chip-title').forEach(function (c) {
        c.classList.remove('active');
      });
      chip.classList.add('active');

      var titleValue = chip.dataset.title;
      activeTitle = titleValue === 'all' ? '' : titleValue;

      if (window.gtag) {
        gtag('event', 'title_filter', { film_title: titleValue });
      }

      closePanel();
      renderMarkers();

      if (activeTitle) {
        var filmPins = allPins.filter(function (p) { return p.title === activeTitle; });
        if (filmPins.length > 0) {
          var bounds = L.latLngBounds(filmPins.map(function (p) { return [p.lat, p.lng]; }));
          map.fitBounds(bounds, { padding: [80, 80], maxZoom: 8 });
        }
      }
    });
  });

  // ── Theatre filter chips ───────────────────────────────────
  document.querySelectorAll('.chip:not(.chip-title)').forEach(function (chip) {
    chip.addEventListener('click', function () {
      document.querySelectorAll('.chip:not(.chip-title)').forEach(function (c) {
        c.classList.remove('active');
      });
      chip.classList.add('active');
      activeTheatre = chip.dataset.theatre;
      if (window.gtag) {
        gtag('event', 'theatre_filter', { theatre: activeTheatre });
      }
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
      if (!searchTerm && window.history.replaceState) {
        window.history.replaceState({}, '', window.location.pathname);
        document.title = 'WWII Film Locations Map - CinemaMapped';
      }
      if (searchTerm && window.gtag) {
        gtag('event', 'map_search', { search_term: searchTerm });
      }
      closePanel();
      renderMarkers();
    }, 220);
  });

  // ── URL param: ?film=Title ──────────────────────────────────
  function applyUrlParams() {
    var params    = new URLSearchParams(window.location.search);
    var filmParam = params.get('film');

    if (filmParam) {
      searchInput.value = filmParam;
      searchTerm        = filmParam;
      document.title    = filmParam + ' - CinemaMapped';
    }

    renderMarkers();

    if (filmParam) {
      var filmPins = allPins.filter(function (p) {
        return p.title.toLowerCase() === filmParam.toLowerCase();
      });
      if (filmPins.length > 0) {
        var bounds = L.latLngBounds(filmPins.map(function (p) {
          return [p.lat, p.lng];
        }));
        map.fitBounds(bounds, { padding: [80, 80], maxZoom: 8 });
      }
    }
  }

  // ── Mobile nav height sync ─────────────────────────────────
  function syncMapTop() {
    var nav = document.querySelector('.map-nav');
    if (!nav) return;
    document.documentElement.style.setProperty('--map-top', nav.offsetHeight + 'px');
  }
  syncMapTop();
  window.addEventListener('resize', syncMapTop);

  // ── Load data ──────────────────────────────────────────────
  fetch('data.json')
    .then(function (r) { return r.json(); })
    .then(function (data) {
      allPins = data;
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
