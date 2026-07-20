(function () {
  'use strict';

  // â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  var allPins       = [];
  var activeTheatre = 'all';
  var activeTitle   = '';
  var searchTerm    = '';
  var clusterGroup;
  var routeLayer    = null;
  var searchTimer;

  // â”€â”€ Theatre colours â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  var THEATRE_COLORS = {
    'Western Front': '#c9a84c',
    'Eastern Front': '#c94c4c',
    'Pacific':       '#4c9bc9',
    'North Africa':  '#c98b4c',
    'Atlantic':      '#4c6ec9',
    'Mediterranean': '#4cc9b0',
  };
  function theatreColor(t) { return THEATRE_COLORS[t] || '#8a8880'; }

  // â”€â”€ Map init â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ Cluster group â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  clusterGroup = L.markerClusterGroup({
    showCoverageOnHover: false,
    maxClusterRadius:    window.innerWidth < 768 ? 70 : 52,
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

  // â”€â”€ Pin icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  function goldIcon() {
    return L.divIcon({
      className:  'gold-pin',
      html:       '<div class="gold-pin-dot"></div>',
      iconSize:   [12, 12],
      iconAnchor: [6, 6],
    });
  }

  function toSlug(str) {
    return str.toLowerCase()
      .replace(/[^a-z0-9\s]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');
  }

  // â”€â”€ Route lines â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ Panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  var panel      = document.getElementById('pin-panel');
  var panelClose = document.getElementById('pin-close');

  function openPanel(pin) {
    var tc = theatreColor(pin.theatre);
    var theatreBadge = pin.theatre
      ? '<span class="badge badge-theatre" style="color:' + tc + ';border-color:' + tc + '4d">' + escapeHtml(pin.theatre) + '</span>'
      : '';
    document.getElementById('pin-badges').innerHTML =
      '<span class="badge badge-type">' + escapeHtml(pin.type) + '</span>' + theatreBadge;

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

    var filmLinkEl = document.getElementById('pin-film-link');
    if (filmLinkEl) {
      filmLinkEl.href = '/films/' + toSlug(pin.title);
    }

    panel.classList.add('open');
    panel.setAttribute('aria-hidden', 'false');

    if (pin.id && window.history.replaceState) {
      window.history.replaceState({}, '', '?pin=' + pin.id);
    }

    clearRoute();
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
    if (window.history.replaceState) {
      var url = window.location.pathname + (window.location.search.replace(/[?&]pin=[^&]*/g, '').replace(/^&/, '?') || '');
      window.history.replaceState({}, '', url);
    }
    if (!activeTitle) {
      clearRoute();
    }
  }

  panelClose.addEventListener('click', closePanel);
  map.on('click', closePanel);

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closePanel();
  });

  // â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  var noResultsEl = document.getElementById('no-results');

  function updateEmptyState(count) {
    if (!noResultsEl) return;
    noResultsEl.style.display = count === 0 ? 'flex' : 'none';
  }

  // â”€â”€ Pin count â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ Render markers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ Title filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  document.querySelectorAll('.chip-title').forEach(function (chip) {
    chip.addEventListener('click', function () {
      document.querySelectorAll('.chip-title').forEach(function (c) {
        c.classList.remove('active');
      });
      chip.classList.add('active');

      var titleValue = chip.dataset.title;
      activeTitle = titleValue === 'all' ? '' : titleValue;

      // Selecting a title clears the theatre filter and any URL search term
      searchTerm = '';
      searchInput.value = '';
      if (activeTitle) {
        activeTheatre = 'all';
        document.querySelectorAll('.chip:not(.chip-title)').forEach(function (c) {
          c.classList.toggle('active', c.dataset.theatre === 'all');
        });
      }

      if (window.gtag) {
        gtag('event', 'title_filter', { film_title: titleValue });
      }

      closePanel();
      renderMarkers();
      updateResetBtn();

      if (activeTitle) {
        var filmPins = allPins.filter(function (p) { return p.title === activeTitle; });
        if (filmPins.length > 0) {
          var bounds = L.latLngBounds(filmPins.map(function (p) { return [p.lat, p.lng]; }));
          map.fitBounds(bounds, { padding: [80, 80], maxZoom: 8 });
        }
      }
    });
  });

  // â”€â”€ Theatre filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  document.querySelectorAll('.chip:not(.chip-title)').forEach(function (chip) {
    chip.addEventListener('click', function () {
      document.querySelectorAll('.chip:not(.chip-title)').forEach(function (c) {
        c.classList.remove('active');
      });
      chip.classList.add('active');
      activeTheatre = chip.dataset.theatre;

      // Selecting a theatre clears the title filter and any URL search term
      searchTerm = '';
      searchInput.value = '';
      activeTitle = '';
      document.querySelectorAll('.chip-title').forEach(function (c) {
        c.classList.toggle('active', c.dataset.title === 'all');
      });

      if (window.gtag) {
        gtag('event', 'theatre_filter', { theatre: activeTheatre });
      }
      closePanel();
      renderMarkers();
      updateResetBtn();

      if (activeTheatre !== 'all') {
        var theatrePins = allPins.filter(function (p) { return p.theatre === activeTheatre; });
        if (theatrePins.length > 0) {
          var bounds = L.latLngBounds(theatrePins.map(function (p) { return [p.lat, p.lng]; }));
          map.fitBounds(bounds, { padding: [80, 80], maxZoom: 8 });
        }
      } else {
        map.setView([48, 12], 5);
      }
    });
  });

  // â”€â”€ Search â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ URL param: ?film=Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  function applyUrlParams() {
    var params    = new URLSearchParams(window.location.search);
    var filmParam = params.get('film');
    var pinParam  = params.get('pin');

    if (filmParam) {
      searchInput.value = filmParam;
      searchTerm        = filmParam;
      document.title    = filmParam + ' - CinemaMapped';
    }

    renderMarkers();

    if (pinParam) {
      var pinId     = parseInt(pinParam, 10);
      var deepPin   = allPins.find(function (p) { return p.id === pinId; });
      if (deepPin) {
        map.setView([deepPin.lat, deepPin.lng], 10);
        openPanel(deepPin);
      }
    } else if (filmParam) {
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

  // â”€â”€ Reset button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  var resetBtn = document.getElementById('map-reset');

  function updateResetBtn() {
    if (!resetBtn) return;
    var isFiltered = activeTheatre !== 'all' || activeTitle || searchTerm;
    resetBtn.style.display = isFiltered ? '' : 'none';
  }

  if (resetBtn) {
    resetBtn.addEventListener('click', function () {
      activeTheatre = 'all';
      activeTitle   = '';
      searchTerm    = '';
      searchInput.value = '';
      document.querySelectorAll('.chip-title').forEach(function (c) {
        c.classList.toggle('active', c.dataset.title === 'all');
      });
      document.querySelectorAll('.chip:not(.chip-title)').forEach(function (c) {
        c.classList.toggle('active', c.dataset.theatre === 'all');
      });
      closePanel();
      renderMarkers();
      updateResetBtn();
      map.setView([48, 12], 5);
    });
  }

  // â”€â”€ Mobile nav height sync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  function syncMapTop() {
    var nav = document.querySelector('.map-nav');
    if (!nav) return;
    document.documentElement.style.setProperty('--map-top', nav.offsetHeight + 'px');
  }
  syncMapTop();
  window.addEventListener('resize', syncMapTop);

  // â”€â”€ Load data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  fetch('data.json?v=5')
    .then(function (r) { return r.json(); })
    .then(function (data) {
      allPins = data;
      applyUrlParams();
    })
    .catch(function (err) {
      console.error('CinemaMapped: failed to load data.json', err);
    });

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

