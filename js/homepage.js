(function () {
  'use strict';

  fetch('data.json')
    .then(function (r) { return r.json(); })
    .then(function (data) {
      var counts   = {};
      var theatres = {};
      var types    = {};

      data.forEach(function (pin) {
        if (!counts[pin.title]) {
          counts[pin.title]   = 0;
          theatres[pin.title] = pin.theatre;
          types[pin.title]    = pin.type;
        }
        counts[pin.title]++;
      });

      var sorted = Object.keys(counts)
        .map(function (title) { return [title, counts[title]]; })
        .sort(function (a, b) { return b[1] - a[1]; })
        .slice(0, 12);

      var container = document.getElementById('film-scroll');
      if (!container) return;

      container.innerHTML = sorted.map(function (pair) {
        var title  = pair[0];
        var count  = pair[1];
        var href   = 'map.html?film=' + encodeURIComponent(title);
        var plural = count !== 1 ? 's' : '';

        return (
          '<a href="' + href + '" class="film-card" role="listitem">' +
            '<div class="film-card-badges">' +
              '<span class="badge badge-type">' + escapeHtml(types[title]) + '</span>' +
              '<span class="badge badge-theatre">' + escapeHtml(theatres[title]) + '</span>' +
            '</div>' +
            '<div class="film-card-title">' + escapeHtml(title) + '</div>' +
            '<div class="film-card-count"><strong>' + count + '</strong> location' + plural + '</div>' +
          '</a>'
        );
      }).join('');
    })
    .catch(function () {
      /* silent fail — section stays empty, rest of page is static */
    });

  function escapeHtml(str) {
    var d = document.createElement('div');
    d.appendChild(document.createTextNode(String(str)));
    return d.innerHTML;
  }
})();
