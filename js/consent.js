(function () {
  'use strict';

  var CONSENT_KEY = 'cm_analytics';
  var GA_ID = 'G-5CRC6PPQLM';

  // Consent Mode v2 — set denied defaults immediately (required for EU/EEA)
  window.dataLayer = window.dataLayer || [];
  function gtag() { dataLayer.push(arguments); }
  window.gtag = gtag;
  gtag('consent', 'default', {
    analytics_storage:    'denied',
    ad_storage:           'denied',
    ad_user_data:         'denied',
    ad_personalization:   'denied',
    wait_for_update:       500
  });

  function loadGA() {
    gtag('consent', 'update', { analytics_storage: 'granted' });
    var s = document.createElement('script');
    s.async = true;
    s.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID;
    document.head.appendChild(s);
    gtag('js', new Date());
    gtag('config', GA_ID);
  }

  function denyGA() {
    gtag('consent', 'update', { analytics_storage: 'denied' });
  }

  function getConsent() {
    try { return localStorage.getItem(CONSENT_KEY); } catch (e) { return null; }
  }

  function setConsent(val) {
    try { localStorage.setItem(CONSENT_KEY, val); } catch (e) {}
  }

  function removeBanner() {
    var b = document.getElementById('cookie-banner');
    if (b) {
      b.classList.add('cookie-banner--out');
      setTimeout(function () { if (b.parentNode) b.parentNode.removeChild(b); }, 300);
    }
  }

  function showBanner() {
    var banner = document.createElement('div');
    banner.id = 'cookie-banner';
    banner.setAttribute('role', 'dialog');
    banner.setAttribute('aria-label', 'Cookie consent');
    banner.innerHTML =
      '<div class="cookie-banner-inner">' +
        '<p class="cookie-banner-text">We use Google Analytics to understand how visitors use CinemaMapped. No personal data is sold or shared. ' +
          '<a href="/privacy.html" class="cookie-banner-link">Privacy policy</a>' +
        '</p>' +
        '<div class="cookie-banner-actions">' +
          '<button id="cookie-accept" class="cookie-btn cookie-btn--accept">Accept</button>' +
          '<button id="cookie-decline" class="cookie-btn cookie-btn--decline">Decline</button>' +
        '</div>' +
      '</div>';

    document.body.appendChild(banner);

    document.getElementById('cookie-accept').addEventListener('click', function () {
      setConsent('yes');
      loadGA();
      removeBanner();
    });

    document.getElementById('cookie-decline').addEventListener('click', function () {
      setConsent('no');
      denyGA();
      removeBanner();
    });
  }

  var consent = getConsent();
  if (consent === 'yes') {
    loadGA();
  } else if (consent === 'no') {
    denyGA();
  } else {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', showBanner);
    } else {
      showBanner();
    }
  }
})();
