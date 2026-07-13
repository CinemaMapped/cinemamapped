(function () {
  'use strict';

  // ── Hero background map ───────────────────────────────────
  var heroMapEl = document.getElementById('hero-map');
  if (heroMapEl && typeof L !== 'undefined') {
    var heroMap = L.map('hero-map', {
      center:              [50, 18],
      zoom:                5,
      dragging:            false,
      touchZoom:           false,
      scrollWheelZoom:     false,
      doubleClickZoom:     false,
      boxZoom:             false,
      keyboard:            false,
      zoomControl:         false,
      attributionControl:  false,
      tap:                 false,
    });

    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd',
      maxZoom:    19,
    }).addTo(heroMap);

    fetch('data.json')
      .then(function (r) { return r.json(); })
      .then(function (pins) {
        pins.forEach(function (pin) {
          L.circleMarker([pin.lat, pin.lng], {
            radius:      4,
            color:       '#c9a84c',
            fillColor:   '#c9a84c',
            fillOpacity: 0.85,
            weight:      0,
            interactive: false,
          }).addTo(heroMap);
        });
      });
  }

  fetch('data.json')
    .then(function (r) { return r.json(); })
    .then(function (data) {
      var counts   = {};
      var theatres = {};
      var types    = {};
      var theatreSet = {};
      var countrySet = {};

      data.forEach(function (pin) {
        if (!counts[pin.title]) {
          counts[pin.title]   = 0;
          theatres[pin.title] = pin.theatre;
          types[pin.title]    = pin.type;
        }
        counts[pin.title]++;
        theatreSet[pin.theatre] = true;
        countrySet[pin.country] = true;
      });

      // ── Update stats dynamically ──────────────────────────
      var totalPins     = data.length;
      var totalTitles   = Object.keys(counts).length;
      var totalTheatres = Object.keys(theatreSet).length;
      var totalCountries = Object.keys(countrySet).length;

      setText('hero-stat-pins',     totalPins);
      setText('hero-stat-titles',   totalTitles);
      setText('hero-stat-theatres', totalCountries);
      setText('stat-pins',          totalPins);
      setText('stat-titles',        totalTitles);
      setText('stat-theatres',      totalTheatres);
      setText('stat-countries',     totalCountries + '+');
      setText('cta-count',         totalPins);

      // ── Build featured film scroll ────────────────────────
      var sorted = Object.keys(counts)
        .sort(function (a, b) { return counts[b] - counts[a]; });

      // Top 8 by pin count
      var top  = sorted.slice(0, 8);
      // Up to 4 from the rest, spread across different theatres not already in top 8
      var rest = sorted.slice(8);
      var topTheatres = {};
      top.forEach(function (t) { topTheatres[theatres[t]] = true; });

      var extras = [];
      rest.forEach(function (t) {
        if (extras.length < 4 && !topTheatres[theatres[t]]) {
          extras.push(t);
          topTheatres[theatres[t]] = true;
        }
      });
      // Fill remaining slots from rest if extras didn't reach 4
      rest.forEach(function (t) {
        if (extras.length < 4 && extras.indexOf(t) === -1) {
          extras.push(t);
        }
      });

      var featured = top.concat(extras);

      var container = document.getElementById('film-scroll');
      if (!container) return;

      container.innerHTML = featured.map(function (title) {
        var count  = counts[title];
        var href   = 'map.html?film=' + encodeURIComponent(title);
        var plural = count !== 1 ? 's' : '';

        return (
          '<a href="' + href + '" class="film-card" role="listitem">' +
            '<div class="film-card-badges">' +
              '<span class="badge badge-type">'    + escapeHtml(types[title])    + '</span>' +
              '<span class="badge badge-theatre">' + escapeHtml(theatres[title]) + '</span>' +
            '</div>' +
            '<div class="film-card-title">' + escapeHtml(title) + '</div>' +
            '<div class="film-card-count"><strong>' + count + '</strong> location' + plural + '</div>' +
          '</a>'
        );
      }).join('');
    })
    .catch(function () {
      /* silent fail */
    });

  function setText(id, value) {
    var el = document.getElementById(id);
    if (el) el.textContent = value;
  }

  function escapeHtml(str) {
    var d = document.createElement('div');
    d.appendChild(document.createTextNode(String(str)));
    return d.innerHTML;
  }
})();
