# Generate film pages, country pages, and index pages for CinemaMapped SEO
$base = 'C:\Users\meewe\projects\cinemamapped'
foreach ($d in @("$base\films", "$base\countries")) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

$data = [System.IO.File]::ReadAllText("$base\data.json", [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$filmsMetaRaw = [System.IO.File]::ReadAllText("$base\films-meta.json", [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$filmsMeta = @{}
$filmsMetaRaw.PSObject.Properties | ForEach-Object { $filmsMeta[$_.Name] = $_.Value }

$countriesMetaRaw = [System.IO.File]::ReadAllText("$base\countries-meta.json", [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$countriesMeta = @{}
$countriesMetaRaw.PSObject.Properties | ForEach-Object { $countriesMeta[$_.Name] = $_.Value }

function HtmlEncode($str) {
    if (-not $str) { return '' }
    return $str.ToString() -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;'
}

function ToSlug($str) {
    if (-not $str) { return '' }
    $s = $str.ToLower()
    $s = $s -replace [char]0x0142, 'l'
    $s = $s -replace [char]0x0141, 'l'
    $s = $s -replace [char]0x00DF, 'ss'
    $s = $s -replace [char]0x00E6, 'ae'
    $s = $s -replace [char]0x00F8, 'o'
    $s = $s -replace [char]0x0111, 'd'
    $norm = $s.Normalize([System.Text.NormalizationForm]::FormD)
    $ascii = [System.Text.RegularExpressions.Regex]::Replace($norm, '[^\x00-\x7F]', '')
    $ascii = $ascii -replace "[^a-z0-9\s]", ''
    $ascii = $ascii -replace '\s+', '-'
    $ascii = $ascii -replace '-+', '-'
    return $ascii.Trim('-')
}

$faviconUri = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 500 500'%3E%3Crect width='500' height='500' rx='60' fill='%230d0d0d'/%3E%3Ctext x='250' y='360' font-family='Arial Black,Arial,sans-serif' font-size='340' font-weight='900' text-anchor='middle' fill='%23c9a84c'%3EC%3C/text%3E%3C/svg%3E"

# Assign slugs to all pins (same algorithm as generate-pin-pages.ps1)
$usedSlugs = @{}
foreach ($pin in $data) {
    $b2 = "$(ToSlug $pin.title)-$(ToSlug $pin.location)"
    if ($usedSlugs.ContainsKey($b2)) {
        $usedSlugs[$b2]++
        $sl = "$b2-$($usedSlugs[$b2])"
    } else {
        $usedSlugs[$b2] = 1
        $sl = $b2
    }
    $pin | Add-Member -NotePropertyName 'slug' -NotePropertyValue $sl -Force
}

# Group pins by title and country
$byTitle   = @{}
$byCountry = @{}
foreach ($pin in $data) {
    if (-not $byTitle.ContainsKey($pin.title))     { $byTitle[$pin.title]     = @() }
    if (-not $byCountry.ContainsKey($pin.country)) { $byCountry[$pin.country] = @() }
    $byTitle[$pin.title]     += $pin
    $byCountry[$pin.country] += $pin
}

$filmCount_total    = 0
$countryCount_total = 0

# â”€â”€ FILM PAGES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$allTitles = ($data | Select-Object -ExpandProperty title -Unique | Sort-Object)

foreach ($title in $allTitles) {
    $pins        = @($byTitle[$title])
    $titleSlug   = ToSlug $title
    $titleHtml   = HtmlEncode $title
    $type        = $pins[0].type
    $theatre     = $pins[0].theatre
    $typeHtml    = HtmlEncode $type
    $theatreHtml = HtmlEncode $theatre
    $pinCount    = $pins.Count
    $typeWord    = if ($type -eq 'Series') { 'series' } else { 'film' }
    $locWord     = if ($pinCount -eq 1) { 'location' } else { 'locations' }

    $filmCountriesList = @($pins | Select-Object -ExpandProperty country -Unique | Sort-Object)
    $filmCountriesHtml = ($filmCountriesList | ForEach-Object { HtmlEncode $_ }) -join ', '

    $years     = @($pins | Select-Object -ExpandProperty year_portrayed | Sort-Object -Unique)
    $yearRange = if ($years.Count -gt 1) { "$($years[0])-$($years[-1])" } else { "$($years[0])" }

    $streaming = ($pins | Where-Object { $_.streaming } | Select-Object -First 1).streaming

    # Map init JS
    $lats   = @($pins | Select-Object -ExpandProperty lat)
    $lngs   = @($pins | Select-Object -ExpandProperty lng)
    $minLat = ($lats | Measure-Object -Minimum).Minimum
    $maxLat = ($lats | Measure-Object -Maximum).Maximum
    $minLng = ($lngs | Measure-Object -Minimum).Minimum
    $maxLng = ($lngs | Measure-Object -Maximum).Maximum

    if ($pinCount -eq 1) {
        $mapInitJs = "m.setView([$($pins[0].lat), $($pins[0].lng)], 8);"
    } else {
        $mapInitJs = "m.fitBounds([[$minLat, $minLng], [$maxLat, $maxLng]], { padding: [40, 40] });"
    }

    $markersJs = ($pins | ForEach-Object {
        "    L.circleMarker([$($_.lat), $($_.lng)], { radius:7, color:'#c9a84c', fillColor:'#c9a84c', fillOpacity:1, weight:2, interactive:false }).addTo(m);"
    }) -join "`n"

    # Location cards
    $locationCards = ($pins | ForEach-Object {
        $locHtml   = HtmlEncode $_.location
        $pinSlug   = $_.slug
        $descShort = ''
        if ($_.description) {
            $d = $_.description
            $descShort = if ($d.Length -gt 160) { (HtmlEncode $d.Substring(0, 157)) + '...' } else { HtmlEncode $d }
        }
        $histBlock = ''
        if ($_.historical_context) {
            $h = $_.historical_context
            $histHtml = if ($h.Length -gt 220) { (HtmlEncode $h.Substring(0, 217)) + '...' } else { HtmlEncode $h }
            $histBlock = "`n      <p class=`"location-card-history`">$histHtml</p>"
        }
        "    <div class=`"location-card`">`n      <div class=`"location-card-name`">$locHtml</div>`n      <p class=`"location-card-desc`">$descShort</p>$histBlock`n      <a href=`"/locations/$pinSlug`" class=`"location-card-link`">View location &rarr;</a>`n    </div>"
    }) -join "`n"

    # Watch button
    $watchBlock = ''
    if ($streaming) {
        $streamSafe  = HtmlEncode $streaming
        $titleJsonSafe = $title -replace "'", "\'" -replace '"', '\"'
        $watchBlock = "    <a class=`"pin-watch-btn`" href=`"$streamSafe`" target=`"_blank`" rel=`"noopener noreferrer sponsored`" onclick=`"if(window.gtag)gtag('event','watch_click',{film_title:'$titleJsonSafe',source:'film_page'})`">Watch $titleHtml on Amazon &#x2197;</a>`n    <p class=`"pin-affiliate-note`">As an Amazon Associate I earn from qualifying purchases.</p>`n"
    }

    # Related films: other films sharing at least one country, sorted by pin count desc, max 6
    $relatedFilms = @{}
    foreach ($otherTitle in $allTitles) {
        if ($otherTitle -eq $title) { continue }
        $otherPins = @($byTitle[$otherTitle])
        $otherCountries = @($otherPins | Select-Object -ExpandProperty country -Unique)
        $shared = ($otherCountries | Where-Object { $filmCountriesList -contains $_ })
        if ($shared) { $relatedFilms[$otherTitle] = $otherPins.Count }
    }
    $relatedTop = $relatedFilms.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 6

    $relatedCards = ($relatedTop | ForEach-Object {
        $rt     = $_.Key
        $rtHtml = HtmlEncode $rt
        $rtSlug = ToSlug $rt
        $rtPins = @($byTitle[$rt])
        $rtType = $rtPins[0].type
        $rtCnt  = $rtPins.Count
        $rtLoc  = if ($rtCnt -eq 1) { 'location' } else { 'locations' }
        "      <a href=`"/films/$rtSlug`" class=`"related-card`">`n        <div class=`"related-card-title`">$rtHtml</div>`n        <div class=`"related-card-meta`"><span class=`"badge badge-type`">$rtType</span><span>$rtCnt $rtLoc</span></div>`n      </a>"
    }) -join "`n"

    $relatedSection = ''
    if ($relatedTop.Count -gt 0) {
        $relatedSection = "    <div class=`"pin-page-section related-section`">`n      <div class=`"pin-desc-label related-section-label`">Also explore</div>`n      <div class=`"related-grid`">`n$relatedCards`n      </div>`n    </div>`n"
    }

    $canonUrl  = "https://cinemamapped.com/films/$titleSlug"
    $mapUrl    = "/map?film=" + [Uri]::EscapeDataString($title)
    $titleJson = $title -replace '"', '\"'
    $descMeta  = "$titleHtml WWII $typeWord - $pinCount real historical $locWord tracked on CinemaMapped across $filmCountriesHtml."
    $intro     = "$titleHtml is a WWII $typeWord set on the $theatreHtml during $yearRange. CinemaMapped has mapped $pinCount real historical $locWord where the story takes place, spanning $filmCountriesHtml. Each pin marks the actual place depicted - not where the $typeWord was shot, but where the historical events happened."

    $synopsisRaw = $filmsMeta[$title]
    $aboutContent = if ($synopsisRaw) {
        $synHtml = HtmlEncode $synopsisRaw
        $locationLine = "CinemaMapped has mapped $pinCount real historical $locWord where the story takes place, spanning $filmCountriesHtml."
        "<p class=`"pin-page-text`">$synHtml</p><p class=`"pin-page-text`" style=`"margin-top:8px;color:var(--text-muted);font-size:14px;`">$locationLine</p>"
    } else {
        "<p class=`"pin-page-text`">$intro</p>"
    }

    $schemaJson = "  {`n    `"@context`": `"https://schema.org`",`n    `"@type`": `"ItemList`",`n    `"name`": `"$titleJson filming locations`",`n    `"description`": `"Real WWII historical locations where $titleJson is set, tracked on CinemaMapped.`",`n    `"url`": `"$canonUrl`",`n    `"numberOfItems`": $pinCount`n  }"

    $html  = "---`n---`n"
    $html += "<!DOCTYPE html>`n<html lang=`"en`">`n<head>`n"
    $html += "  <meta charset=`"UTF-8`">`n"
    $html += "  <meta name=`"viewport`" content=`"width=device-width, initial-scale=1.0`">`n"
    $html += "  <title>$titleHtml Filming Locations - Where Was It Set? | CinemaMapped</title>`n"
    $html += "  <meta name=`"description`" content=`"$descMeta`">`n"
    $html += "  <link rel=`"icon`" href=`"$faviconUri`">`n"
    $html += "  <link rel=`"icon`" href=`"/favicon.ico`">`n"
    $html += "  <link rel=`"canonical`" href=`"$canonUrl`">`n"
    $html += "  <meta property=`"og:title`" content=`"$titleHtml Filming Locations | CinemaMapped`">`n"
    $html += "  <meta property=`"og:description`" content=`"$descMeta`">`n"
    $html += "  <meta property=`"og:type`" content=`"article`">`n"
    $html += "  <meta property=`"og:url`" content=`"$canonUrl`">`n"
    $html += "  <meta property=`"og:image`" content=`"https://cinemamapped.com/og-image.svg`">`n"
    $html += "  <script type=`"application/ld+json`">`n$schemaJson`n  </script>`n"
    $html += "  <link rel=`"preconnect`" href=`"https://fonts.googleapis.com`">`n"
    $html += "  <link rel=`"preconnect`" href=`"https://fonts.gstatic.com`" crossorigin>`n"
    $html += "  <link href=`"https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@300;400;500;600&display=swap`" rel=`"stylesheet`">`n"
    $html += "  <link rel=`"stylesheet`" href=`"https://unpkg.com/leaflet@1.9.4/dist/leaflet.css`">`n"
    $html += "  <link rel=`"stylesheet`" href=`"/style.css?v=10`">`n"
    $html += "</head>`n<body>`n`n"

    $html += "  <nav class=`"nav`">`n"
    $html += "    <a href=`"/`" class=`"nav-logo`">Cinema<em>Mapped</em></a>`n"
    $html += "    <div style=`"display:flex;gap:12px;align-items:center;`">`n"
    $html += "      <a href=`"/films`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Films &amp; Series</a>`n"
    $html += "      <a href=`"/countries`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Countries</a>`n"
    $html += "      <a href=`"/film-locations`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Guide</a>`n"
    $html += "      <a href=`"/map`" class=`"btn btn-filled`">Explore the Map</a>`n"
    $html += "    </div>`n  </nav>`n`n"

    $html += "  <div class=`"pin-page-hero`">`n"
    $html += "    <div class=`"pin-page-breadcrumb`"><a href=`"/`">CinemaMapped</a> &rsaquo; <a href=`"/films`">Films &amp; Series</a> &rsaquo; $titleHtml</div>`n"
    $html += "    <div class=`"pin-page-badges`"><span class=`"badge badge-type`">$typeHtml</span><span class=`"badge badge-theatre`">$theatreHtml</span><span class=`"pin-page-year`">$yearRange</span></div>`n"
    $html += "    <h1 class=`"pin-page-h1`">$titleHtml Filming Locations</h1>`n"
    $html += "    <p class=`"pin-page-title-line`">$pinCount $locWord &middot; $filmCountriesHtml</p>`n"
    $html += "  </div>`n`n"

    $html += "  <div id=`"film-map`" class=`"pin-page-map`" style=`"height:360px;`"></div>`n`n"

    $html += "  <div class=`"pin-page-body`">`n"
    $html += "    <div class=`"pin-page-section`"><div class=`"pin-desc-label`">About</div>$aboutContent</div>`n"
    $html += "    <div class=`"pin-divider`"></div>`n"
    $html += "    <div class=`"pin-page-section`">`n"
    $html += "      <div class=`"pin-desc-label`">Locations ($pinCount)</div>`n"
    $html += "      <div class=`"location-cards-grid`">`n"
    $html += "$locationCards`n"
    $html += "      </div>`n    </div>`n"
    if ($watchBlock) { $html += "$watchBlock" }
    if ($relatedSection) { $html += "$relatedSection" }
    $html += "    <div class=`"pin-page-cta`"><a href=`"$mapUrl`" class=`"btn btn-filled`">Explore $titleHtml on the map &rarr;</a></div>`n"
    $html += "  </div>`n`n"

    $html += "  <footer class=`"footer`">`n"
    $html += "    <span class=`"footer-brand`">Cinema<em style=`"color:var(--accent)`">Mapped</em></span>`n"
    $html += "    <span class=`"footer-copy`">&copy; 2026 CinemaMapped &nbsp;&middot;&nbsp;<a href=`"/privacy`" style=`"color:var(--text-muted);text-decoration:none;`">Privacy Policy</a>&nbsp;&middot;&nbsp;<a href=`"/terms`" style=`"color:var(--text-muted);text-decoration:none;`">Terms of Use</a></span>`n"
    $html += "  </footer>`n`n"

    $html += "  <script src=`"https://unpkg.com/leaflet@1.9.4/dist/leaflet.js`"></script>`n"
    $html += "  <script>`n"
    $html += "    var m = L.map('film-map', { zoomControl:true, attributionControl:false, scrollWheelZoom:false });`n"
    $html += "    $mapInitJs`n"
    $html += "    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { subdomains:'abcd', maxZoom:19 }).addTo(m);`n"
    $html += "$markersJs`n"
    $html += "  </script>`n"
    $html += "  <script src=`"/js/consent.js?v=3`"></script>`n"
    $html += "</body>`n</html>`n"

    [System.IO.File]::WriteAllText("$base\films\$titleSlug.html", $html, [System.Text.Encoding]::UTF8)
    $filmCount_total++
}

Write-Host "Film pages: $filmCount_total"

# â”€â”€ COUNTRY PAGES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$allCountries = ($data | Select-Object -ExpandProperty country -Unique | Sort-Object)

foreach ($country in $allCountries) {
    $pins          = @($byCountry[$country])
    $countrySlug   = ToSlug $country
    $countryHtml   = HtmlEncode $country
    $pinCount      = $pins.Count
    $locWord       = if ($pinCount -eq 1) { 'location' } else { 'locations' }

    $filmTitles    = @($pins | Select-Object -ExpandProperty title -Unique | Sort-Object)
    $filmCount     = $filmTitles.Count
    $filmWord      = if ($filmCount -eq 1) { 'title' } else { 'titles' }

    $dominantTheatre = ($pins | Group-Object theatre | Sort-Object Count -Descending | Select-Object -First 1).Name
    $theatreHtml     = HtmlEncode $dominantTheatre

    $lats   = @($pins | Select-Object -ExpandProperty lat)
    $lngs   = @($pins | Select-Object -ExpandProperty lng)
    $minLat = ($lats | Measure-Object -Minimum).Minimum
    $maxLat = ($lats | Measure-Object -Maximum).Maximum
    $minLng = ($lngs | Measure-Object -Minimum).Minimum
    $maxLng = ($lngs | Measure-Object -Maximum).Maximum

    if ($pinCount -eq 1) {
        $mapInitJs = "m.setView([$($pins[0].lat), $($pins[0].lng)], 8);"
    } else {
        $mapInitJs = "m.fitBounds([[$minLat, $minLng], [$maxLat, $maxLng]], { padding: [40, 40] });"
    }

    $markersJs = ($pins | ForEach-Object {
        "    L.circleMarker([$($_.lat), $($_.lng)], { radius:7, color:'#c9a84c', fillColor:'#c9a84c', fillOpacity:1, weight:2, interactive:false }).addTo(m);"
    }) -join "`n"

    # Film sections (grouped by title)
    $filmSectionsHtml = ($filmTitles | ForEach-Object {
        $ft       = $_
        $ftHtml   = HtmlEncode $ft
        $ftSlug   = ToSlug $ft
        $ftPins   = @($pins | Where-Object { $_.title -eq $ft })
        $ftType   = $ftPins[0].type
        $liItems  = ($ftPins | ForEach-Object {
            $locHtml = HtmlEncode $_.location
            $pinSlug = $_.slug
            "        <li><a href=`"/locations/$pinSlug`">$locHtml</a></li>"
        }) -join "`n"
        "    <div class=`"pin-page-section`">`n      <div class=`"pin-desc-label`"><a href=`"/films/$ftSlug`" style=`"color:var(--accent);text-decoration:none;`">$ftHtml</a> <span class=`"badge badge-type`" style=`"font-size:10px;vertical-align:middle;`">$ftType</span></div>`n      <ul class=`"related-list`">`n$liItems`n      </ul>`n    </div>`n    <div class=`"pin-divider`"></div>"
    }) -join "`n"

    # Country editorial intro
    $countryIntroRaw = $countriesMeta[$country]
    $countryIntroHtml = if ($countryIntroRaw) { HtmlEncode $countryIntroRaw } else { '' }

    # Related countries: same dominant theatre, sorted by pin count desc, max 6, exclude self
    $relatedCountries = ($allCountries | Where-Object { $_ -ne $country } | ForEach-Object {
        $oc = $_
        $ocPins = @($byCountry[$oc])
        $ocTheatre = ($ocPins | Group-Object theatre | Sort-Object Count -Descending | Select-Object -First 1).Name
        if ($ocTheatre -eq $dominantTheatre) { [PSCustomObject]@{ Name=$oc; Count=$ocPins.Count } }
    } | Where-Object { $_ } | Sort-Object Count -Descending | Select-Object -First 6)

    $relatedCountryCards = ($relatedCountries | ForEach-Object {
        $rc     = $_.Name
        $rcHtml = HtmlEncode $rc
        $rcSlug = ToSlug $rc
        $rcCnt  = $_.Count
        $rcLoc  = if ($rcCnt -eq 1) { 'location' } else { 'locations' }
        $rcFilms = ($byCountry[$rc] | Select-Object -ExpandProperty title -Unique | Measure-Object).Count
        $rcFilmWord = if ($rcFilms -eq 1) { 'title' } else { 'titles' }
        "      <a href=`"/countries/$rcSlug`" class=`"related-card`">`n        <div class=`"related-card-title`">$rcHtml</div>`n        <div class=`"related-card-meta`"><span>$rcCnt $rcLoc</span><span>&middot; $rcFilms $rcFilmWord</span></div>`n      </a>"
    }) -join "`n"

    $countryRelatedSection = ''
    if ($relatedCountryCards) {
        $countryRelatedSection = "    <div class=`"pin-page-section related-section`">`n      <div class=`"pin-desc-label related-section-label`">Also explore</div>`n      <div class=`"related-grid`">`n$relatedCountryCards`n      </div>`n    </div>`n"
    }

    $canonUrl   = "https://cinemamapped.com/countries/$countrySlug"
    $descMeta   = "WWII film locations in $country - $pinCount $locWord across $filmCount $filmWord tracked on CinemaMapped. Where are Band of Brothers, Saving Private Ryan and more actually set?"
    $intro      = "CinemaMapped has mapped $pinCount real WWII film $locWord in $countryHtml, drawn from $filmCount $filmWord. Each pin marks the actual historical place depicted in the film - not a filming location, but where the events happened."

    $html  = "---`n---`n"
    $html += "<!DOCTYPE html>`n<html lang=`"en`">`n<head>`n"
    $html += "  <meta charset=`"UTF-8`">`n"
    $html += "  <meta name=`"viewport`" content=`"width=device-width, initial-scale=1.0`">`n"
    $html += "  <title>WWII Film Locations in $countryHtml | CinemaMapped</title>`n"
    $html += "  <meta name=`"description`" content=`"$descMeta`">`n"
    $html += "  <link rel=`"icon`" href=`"$faviconUri`">`n"
    $html += "  <link rel=`"icon`" href=`"/favicon.ico`">`n"
    $html += "  <link rel=`"canonical`" href=`"$canonUrl`">`n"
    $html += "  <meta property=`"og:title`" content=`"WWII Film Locations in $countryHtml | CinemaMapped`">`n"
    $html += "  <meta property=`"og:description`" content=`"$descMeta`">`n"
    $html += "  <meta property=`"og:type`" content=`"article`">`n"
    $html += "  <meta property=`"og:url`" content=`"$canonUrl`">`n"
    $html += "  <meta property=`"og:image`" content=`"https://cinemamapped.com/og-image.svg`">`n"
    $html += "  <link rel=`"preconnect`" href=`"https://fonts.googleapis.com`">`n"
    $html += "  <link rel=`"preconnect`" href=`"https://fonts.gstatic.com`" crossorigin>`n"
    $html += "  <link href=`"https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@300;400;500;600&display=swap`" rel=`"stylesheet`">`n"
    $html += "  <link rel=`"stylesheet`" href=`"https://unpkg.com/leaflet@1.9.4/dist/leaflet.css`">`n"
    $html += "  <link rel=`"stylesheet`" href=`"/style.css?v=10`">`n"
    $html += "</head>`n<body>`n`n"

    $html += "  <nav class=`"nav`">`n"
    $html += "    <a href=`"/`" class=`"nav-logo`">Cinema<em>Mapped</em></a>`n"
    $html += "    <div style=`"display:flex;gap:12px;align-items:center;`">`n"
    $html += "      <a href=`"/films`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Films &amp; Series</a>`n"
    $html += "      <a href=`"/film-locations`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Guide</a>`n"
    $html += "      <a href=`"/map`" class=`"btn btn-filled`">Explore the Map</a>`n"
    $html += "    </div>`n  </nav>`n`n"

    $html += "  <div class=`"pin-page-hero`">`n"
    $html += "    <div class=`"pin-page-breadcrumb`"><a href=`"/`">CinemaMapped</a> &rsaquo; <a href=`"/countries`">Countries</a> &rsaquo; $countryHtml</div>`n"
    $html += "    <div class=`"pin-page-badges`"><span class=`"badge badge-theatre`">$theatreHtml</span></div>`n"
    $html += "    <h1 class=`"pin-page-h1`">WWII Film Locations in $countryHtml</h1>`n"
    $html += "    <p class=`"pin-page-title-line`">$pinCount $locWord &middot; $filmCount $filmWord</p>`n"
    $html += "  </div>`n`n"

    $html += "  <div id=`"country-map`" class=`"pin-page-map`" style=`"height:360px;`"></div>`n`n"

    $html += "  <div class=`"pin-page-body`">`n"
    $overviewIntro = if ($countryIntroHtml) { "<p class=`"pin-page-text`">$countryIntroHtml</p><p class=`"pin-page-text`" style=`"margin-top:8px;color:var(--text-muted);font-size:14px;`">$intro</p>" } else { "<p class=`"pin-page-text`">$intro</p>" }
    $html += "    <div class=`"pin-page-section`"><div class=`"pin-desc-label`">Overview</div>$overviewIntro</div>`n"
    $html += "    <div class=`"pin-divider`"></div>`n"
    $html += "$filmSectionsHtml`n"
    if ($countryRelatedSection) { $html += "$countryRelatedSection" }
    $html += "    <div class=`"pin-page-cta`"><a href=`"/map`" class=`"btn btn-filled`">Explore all locations on the map &rarr;</a></div>`n"
    $html += "  </div>`n`n"

    $html += "  <footer class=`"footer`">`n"
    $html += "    <span class=`"footer-brand`">Cinema<em style=`"color:var(--accent)`">Mapped</em></span>`n"
    $html += "    <span class=`"footer-copy`">&copy; 2026 CinemaMapped &nbsp;&middot;&nbsp;<a href=`"/privacy`" style=`"color:var(--text-muted);text-decoration:none;`">Privacy Policy</a>&nbsp;&middot;&nbsp;<a href=`"/terms`" style=`"color:var(--text-muted);text-decoration:none;`">Terms of Use</a></span>`n"
    $html += "  </footer>`n`n"

    $mapId = 'country-map'
    $html += "  <script src=`"https://unpkg.com/leaflet@1.9.4/dist/leaflet.js`"></script>`n"
    $html += "  <script>`n"
    $html += "    var m = L.map('$mapId', { zoomControl:true, attributionControl:false, scrollWheelZoom:false });`n"
    $html += "    $mapInitJs`n"
    $html += "    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { subdomains:'abcd', maxZoom:19 }).addTo(m);`n"
    $html += "$markersJs`n"
    $html += "  </script>`n"
    $html += "  <script src=`"/js/consent.js?v=3`"></script>`n"
    $html += "</body>`n</html>`n"

    [System.IO.File]::WriteAllText("$base\countries\$countrySlug.html", $html, [System.Text.Encoding]::UTF8)
    $countryCount_total++
}

Write-Host "Country pages: $countryCount_total"

# â”€â”€ FILMS INDEX PAGE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$filmCards = ($allTitles | ForEach-Object {
    $t          = $_
    $tHtml      = HtmlEncode $t
    $tSlug      = ToSlug $t
    $tPins      = @($byTitle[$t])
    $tType      = $tPins[0].type
    $tTheatre   = $tPins[0].theatre
    $tCount     = $tPins.Count
    $tLocWord   = if ($tCount -eq 1) { 'location' } else { 'locations' }
    $tYearNums  = @($tPins | Where-Object { $_.year_portrayed } | Select-Object -ExpandProperty year_portrayed | Sort-Object)
    $tYear      = if ($tYearNums.Count -gt 0) { if ($tYearNums[0] -eq $tYearNums[-1]) { [string]$tYearNums[0] } else { "$($tYearNums[0])&ndash;$($tYearNums[-1])" } } else { '' }
    $tYearSpan  = if ($tYear) { "<span class=`"index-card-year`">$tYear</span>" } else { '' }
    $tStream    = ($tPins | Where-Object { $_.streaming } | Select-Object -First 1).streaming
    $tTitleSafe = $t -replace "'", "\'"
    $tWatchHtml = if ($tStream) {
        $tStreamSafe = HtmlEncode $tStream
        "`n      <a href=`"$tStreamSafe`" class=`"index-card-watch`" target=`"_blank`" rel=`"noopener noreferrer sponsored`" onclick=`"event.stopPropagation();if(window.gtag)gtag('event','watch_click',{film_title:'$tTitleSafe',source:'films_index'})`">Watch on Amazon &#x2197;</a>"
    } else { '' }
    "    <div class=`"index-card`" data-type=`"$tType`" data-theatre=`"$tTheatre`">`n      <a href=`"/films/$tSlug`" class=`"index-card-link`">`n        <div class=`"index-card-title`">$tHtml</div>`n        <div class=`"index-card-meta`"><span class=`"badge badge-type`">$tType</span><span class=`"badge badge-theatre`">$tTheatre</span>$tYearSpan<span>$tCount $tLocWord</span></div>`n      </a>$tWatchHtml`n    </div>"
}) -join "`n"

$totalPins   = $data.Count
$totalTitles = $allTitles.Count

$filmsIndex  = "---`n---`n"
$filmsIndex += "<!DOCTYPE html>`n<html lang=`"en`">`n<head>`n"
$filmsIndex += "  <meta charset=`"UTF-8`">`n"
$filmsIndex += "  <meta name=`"viewport`" content=`"width=device-width, initial-scale=1.0`">`n"
$filmsIndex += "  <title>All WWII Films &amp; Series Locations | CinemaMapped</title>`n"
$filmsIndex += "  <meta name=`"description`" content=`"Browse all $totalTitles WWII films and series tracked on CinemaMapped. Find real historical locations for Band of Brothers, Saving Private Ryan, Schindler's List and more.`">`n"
$filmsIndex += "  <link rel=`"icon`" href=`"$faviconUri`">`n"
$filmsIndex += "  <link rel=`"icon`" href=`"/favicon.ico`">`n"
$filmsIndex += "  <link rel=`"canonical`" href=`"https://cinemamapped.com/films`">`n"
$filmsIndex += "  <link rel=`"preconnect`" href=`"https://fonts.googleapis.com`">`n"
$filmsIndex += "  <link rel=`"preconnect`" href=`"https://fonts.gstatic.com`" crossorigin>`n"
$filmsIndex += "  <link href=`"https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@300;400;500;600&display=swap`" rel=`"stylesheet`">`n"
$filmsIndex += "  <link rel=`"stylesheet`" href=`"/style.css?v=10`">`n"
$filmsIndex += "</head>`n<body>`n`n"
$filmsIndex += "  <nav class=`"nav`">`n"
$filmsIndex += "    <a href=`"/`" class=`"nav-logo`">Cinema<em>Mapped</em></a>`n"
$filmsIndex += "    <div style=`"display:flex;gap:12px;align-items:center;`">`n"
$filmsIndex += "      <a href=`"/films`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Films &amp; Series</a>`n"
$filmsIndex += "      <a href=`"/countries`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Countries</a>`n"
$filmsIndex += "      <a href=`"/film-locations`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Guide</a>`n"
$filmsIndex += "      <a href=`"/map`" class=`"btn btn-filled`">Explore the Map</a>`n"
$filmsIndex += "    </div>`n  </nav>`n`n"
$filmsIndex += "  <div class=`"index-hero`">`n"
$filmsIndex += "    <h1>ALL WWII FILMS &amp; SERIES</h1>`n"
$filmsIndex += "    <p>$totalTitles titles &middot; $totalPins real historical locations</p>`n"
$filmsIndex += "    <p class=`"index-hero-sub`">From Normandy to Stalingrad, Iwo Jima to the Atlantic &mdash; trace the real places behind every WWII story.</p>`n"
$filmsIndex += "  </div>`n`n"
$filmsIndex += "  <div class=`"index-filter-bar`">`n"
$filmsIndex += "    <button class=`"chip active`" data-filter-type=`"all`">All</button>`n"
$filmsIndex += "    <button class=`"chip`" data-filter-type=`"Film`">Films</button>`n"
$filmsIndex += "    <button class=`"chip`" data-filter-type=`"Series`">Series</button>`n"
$filmsIndex += "    <div class=`"index-filter-sep`"></div>`n"
$filmsIndex += "    <button class=`"chip`" data-filter-theatre=`"Western Front`">Western Front</button>`n"
$filmsIndex += "    <button class=`"chip`" data-filter-theatre=`"Eastern Front`">Eastern Front</button>`n"
$filmsIndex += "    <button class=`"chip`" data-filter-theatre=`"Pacific`">Pacific</button>`n"
$filmsIndex += "    <button class=`"chip`" data-filter-theatre=`"North Africa`">N. Africa</button>`n"
$filmsIndex += "    <button class=`"chip`" data-filter-theatre=`"Atlantic`">Atlantic</button>`n"
$filmsIndex += "    <button class=`"chip`" data-filter-theatre=`"Mediterranean`">Mediterranean</button>`n"
$filmsIndex += "    <span class=`"filter-count-label`" id=`"filter-count`">$totalTitles titles</span>`n"
$filmsIndex += "  </div>`n"
$filmsIndex += "  <div class=`"index-grid`">`n"
$filmsIndex += "$filmCards`n"
$filmsIndex += "  </div>`n`n"
$filmsIndex += "  <footer class=`"footer`">`n"
$filmsIndex += "    <span class=`"footer-brand`">Cinema<em style=`"color:var(--accent)`">Mapped</em></span>`n"
$filmsIndex += "    <span class=`"footer-copy`">&copy; 2026 CinemaMapped &nbsp;&middot;&nbsp;<a href=`"/privacy`" style=`"color:var(--text-muted);text-decoration:none;`">Privacy Policy</a>&nbsp;&middot;&nbsp;<a href=`"/terms`" style=`"color:var(--text-muted);text-decoration:none;`">Terms of Use</a></span>`n"
$filmsIndex += "  </footer>`n"
$filmsIndex += "  <script>`n"
$filmsIndex += "(function(){`n"
$filmsIndex += "  var at='all',ath='all';`n"
$filmsIndex += "  function run(){`n"
$filmsIndex += "    var cards=document.querySelectorAll('.index-card[data-type]'),n=0;`n"
$filmsIndex += "    cards.forEach(function(c){`n"
$filmsIndex += "      var ok=(at==='all'||c.dataset.type===at)&&(ath==='all'||c.dataset.theatre===ath);`n"
$filmsIndex += "      c.style.display=ok?'':'none';if(ok)n++;`n"
$filmsIndex += "    });`n"
$filmsIndex += "    var el=document.getElementById('filter-count');`n"
$filmsIndex += "    if(el)el.textContent=n+' title'+(n===1?'':'s');`n"
$filmsIndex += "  }`n"
$filmsIndex += "  document.querySelectorAll('[data-filter-type]').forEach(function(b){`n"
$filmsIndex += "    b.addEventListener('click',function(){`n"
$filmsIndex += "      document.querySelectorAll('[data-filter-type]').forEach(function(x){x.classList.remove('active');});`n"
$filmsIndex += "      b.classList.add('active');at=b.dataset.filterType;run();`n"
$filmsIndex += "    });`n"
$filmsIndex += "  });`n"
$filmsIndex += "  document.querySelectorAll('[data-filter-theatre]').forEach(function(b){`n"
$filmsIndex += "    b.addEventListener('click',function(){`n"
$filmsIndex += "      document.querySelectorAll('[data-filter-theatre]').forEach(function(x){x.classList.remove('active');});`n"
$filmsIndex += "      b.classList.add('active');ath=b.dataset.filterTheatre;run();`n"
$filmsIndex += "    });`n"
$filmsIndex += "  });`n"
$filmsIndex += "})();`n"
$filmsIndex += "  </script>`n"
$filmsIndex += "  <script src=`"/js/consent.js?v=3`"></script>`n"
$filmsIndex += "</body>`n</html>`n"

[System.IO.File]::WriteAllText("$base\films.html", $filmsIndex, [System.Text.Encoding]::UTF8)
Write-Host "films.html written"

# â”€â”€ COUNTRIES INDEX PAGE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$flagMap = @{
    'Germany'                = 'de'
    'France'                 = 'fr'
    'Poland'                 = 'pl'
    'United Kingdom'         = 'gb'
    'Netherlands'            = 'nl'
    'United States'          = 'us'
    'Japan'                  = 'jp'
    'Norway'                 = 'no'
    'Russia'                 = 'ru'
    'Italy'                  = 'it'
    'Belgium'                = 'be'
    'Czech Republic'         = 'cz'
    'Denmark'                = 'dk'
    'Finland'                = 'fi'
    'Greece'                 = 'gr'
    'Hungary'                = 'hu'
    'Austria'                = 'at'
    'Spain'                  = 'es'
    'Romania'                = 'ro'
    'Ukraine'                = 'ua'
    'Belarus'                = 'by'
    'Slovakia'               = 'sk'
    'Estonia'                = 'ee'
    'Morocco'                = 'ma'
    'Tunisia'                = 'tn'
    'Libya'                  = 'ly'
    'Egypt'                  = 'eg'
    'Indonesia'              = 'id'
    'Philippines'            = 'ph'
    'Singapore'              = 'sg'
    'China'                  = 'cn'
    'Australia'              = 'au'
    'Papua New Guinea'       = 'pg'
    'Solomon Islands'        = 'sb'
    'Marshall Islands'       = 'mh'
    'Palau'                  = 'pw'
    'Kiribati'               = 'ki'
    'Thailand'               = 'th'
    'Mongolia'               = 'mn'
    'Argentina'              = 'ar'
    'Bosnia and Herzegovina' = 'ba'
    'Equatorial Guinea'      = 'gq'
}

$regionMap = @{
    'Germany'                = 'Europe'
    'France'                 = 'Europe'
    'Poland'                 = 'Europe'
    'United Kingdom'         = 'Europe'
    'Netherlands'            = 'Europe'
    'Norway'                 = 'Europe'
    'Russia'                 = 'Europe'
    'Italy'                  = 'Europe'
    'Belgium'                = 'Europe'
    'Czech Republic'         = 'Europe'
    'Denmark'                = 'Europe'
    'Finland'                = 'Europe'
    'Greece'                 = 'Europe'
    'Hungary'                = 'Europe'
    'Austria'                = 'Europe'
    'Spain'                  = 'Europe'
    'Romania'                = 'Europe'
    'Ukraine'                = 'Europe'
    'Belarus'                = 'Europe'
    'Slovakia'               = 'Europe'
    'Estonia'                = 'Europe'
    'Bosnia and Herzegovina' = 'Europe'
    'Japan'                  = 'Pacific'
    'Indonesia'              = 'Pacific'
    'Philippines'            = 'Pacific'
    'Singapore'              = 'Pacific'
    'China'                  = 'Pacific'
    'Australia'              = 'Pacific'
    'Papua New Guinea'       = 'Pacific'
    'Solomon Islands'        = 'Pacific'
    'Marshall Islands'       = 'Pacific'
    'Palau'                  = 'Pacific'
    'Kiribati'               = 'Pacific'
    'Thailand'               = 'Pacific'
    'Mongolia'               = 'Pacific'
    'Pacific Ocean'          = 'Pacific'
    'Morocco'                = 'Africa'
    'Tunisia'                = 'Africa'
    'Libya'                  = 'Africa'
    'Egypt'                  = 'Africa'
    'Equatorial Guinea'      = 'Africa'
    'United States'          = 'Americas'
    'Argentina'              = 'Americas'
    'Atlantic Ocean'         = 'Americas'
    'International waters'   = 'Americas'
}

$countriesSorted = ($allCountries | Sort-Object { -(@($byCountry[$_]).Count) })

$countryCards = ($countriesSorted | ForEach-Object {
    $c         = $_
    $cHtml     = HtmlEncode $c
    $cSlug     = ToSlug $c
    $cPins     = @($byCountry[$c])
    $cCount    = $cPins.Count
    $cLocWord  = if ($cCount -eq 1) { 'location' } else { 'locations' }
    $cFilms    = ($cPins | Select-Object -ExpandProperty title -Unique | Measure-Object).Count
    $cFilmWord = if ($cFilms -eq 1) { 'title' } else { 'titles' }
    $cCode     = $flagMap[$c]
    $cFlagHtml = if ($cCode) { "<img src=`"https://flagcdn.com/20x15/$cCode.png`" width=`"20`" height=`"15`" alt=`"`" class=`"index-card-flag`" loading=`"lazy`">" } else { '' }
    $cRegion   = $regionMap[$c]; if (-not $cRegion) { $cRegion = 'Other' }
    $cTopFilm  = ($cPins | Group-Object title | Sort-Object Count -Descending | Select-Object -First 1).Name
    $cTopLine  = if ($cTopFilm) { "`n        <div class=`"index-card-top-film`">$(HtmlEncode $cTopFilm)</div>" } else { '' }
    "    <div class=`"index-card`" data-region=`"$cRegion`">`n      <a href=`"/countries/$cSlug`" class=`"index-card-link`">`n        <div class=`"index-card-title`">$cFlagHtml$cHtml</div>`n        <div class=`"index-card-meta`"><span>$cCount $cLocWord</span><span>&middot; $cFilms $cFilmWord</span></div>$cTopLine`n      </a>`n    </div>"
}) -join "`n"

$totalCountries = $allCountries.Count

$countriesIndex  = "---`n---`n"
$countriesIndex += "<!DOCTYPE html>`n<html lang=`"en`">`n<head>`n"
$countriesIndex += "  <meta charset=`"UTF-8`">`n"
$countriesIndex += "  <meta name=`"viewport`" content=`"width=device-width, initial-scale=1.0`">`n"
$countriesIndex += "  <title>WWII Film Locations by Country | CinemaMapped</title>`n"
$countriesIndex += "  <meta name=`"description`" content=`"Browse WWII film locations by country. $totalCountries countries tracked on CinemaMapped - find real historical locations in France, Germany, Poland, the UK and more.`">`n"
$countriesIndex += "  <link rel=`"icon`" href=`"$faviconUri`">`n"
$countriesIndex += "  <link rel=`"icon`" href=`"/favicon.ico`">`n"
$countriesIndex += "  <link rel=`"canonical`" href=`"https://cinemamapped.com/countries`">`n"
$countriesIndex += "  <link rel=`"preconnect`" href=`"https://fonts.googleapis.com`">`n"
$countriesIndex += "  <link rel=`"preconnect`" href=`"https://fonts.gstatic.com`" crossorigin>`n"
$countriesIndex += "  <link href=`"https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@300;400;500;600&display=swap`" rel=`"stylesheet`">`n"
$countriesIndex += "  <link rel=`"stylesheet`" href=`"/style.css?v=10`">`n"
$countriesIndex += "</head>`n<body>`n`n"
$countriesIndex += "  <nav class=`"nav`">`n"
$countriesIndex += "    <a href=`"/`" class=`"nav-logo`">Cinema<em>Mapped</em></a>`n"
$countriesIndex += "    <div style=`"display:flex;gap:12px;align-items:center;`">`n"
$countriesIndex += "      <a href=`"/films`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Films &amp; Series</a>`n"
$countriesIndex += "      <a href=`"/film-locations`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Guide</a>`n"
$countriesIndex += "      <a href=`"/map`" class=`"btn btn-filled`">Explore the Map</a>`n"
$countriesIndex += "    </div>`n  </nav>`n`n"
$countriesIndex += "  <div class=`"index-hero`">`n"
$countriesIndex += "    <h1>WWII FILMS &amp; SERIES BY COUNTRY</h1>`n"
$countriesIndex += "    <p>$totalCountries countries &middot; $totalPins real historical locations</p>`n"
$countriesIndex += "    <p class=`"index-hero-sub`">One global conflict, every front. Explore which countries appear in WWII cinema &mdash; and which films are set there.</p>`n"
$countriesIndex += "  </div>`n`n"
$countriesIndex += "  <div class=`"index-filter-bar`">`n"
$countriesIndex += "    <button class=`"chip active`" data-filter-region=`"all`">All</button>`n"
$countriesIndex += "    <button class=`"chip`" data-filter-region=`"Europe`">Europe</button>`n"
$countriesIndex += "    <button class=`"chip`" data-filter-region=`"Pacific`">Asia &amp; Pacific</button>`n"
$countriesIndex += "    <button class=`"chip`" data-filter-region=`"Africa`">N. Africa</button>`n"
$countriesIndex += "    <button class=`"chip`" data-filter-region=`"Americas`">Americas</button>`n"
$countriesIndex += "    <span class=`"filter-count-label`" id=`"country-filter-count`">$totalCountries countries</span>`n"
$countriesIndex += "  </div>`n"
$countriesIndex += "  <div class=`"index-grid`">`n"
$countriesIndex += "$countryCards`n"
$countriesIndex += "  </div>`n`n"
$countriesIndex += "  <footer class=`"footer`">`n"
$countriesIndex += "    <span class=`"footer-brand`">Cinema<em style=`"color:var(--accent)`">Mapped</em></span>`n"
$countriesIndex += "    <span class=`"footer-copy`">&copy; 2026 CinemaMapped &nbsp;&middot;&nbsp;<a href=`"/privacy`" style=`"color:var(--text-muted);text-decoration:none;`">Privacy Policy</a>&nbsp;&middot;&nbsp;<a href=`"/terms`" style=`"color:var(--text-muted);text-decoration:none;`">Terms of Use</a></span>`n"
$countriesIndex += "  </footer>`n"
$countriesIndex += "  <script>`n"
$countriesIndex += "(function(){`n"
$countriesIndex += "  var ar='all';`n"
$countriesIndex += "  function run(){`n"
$countriesIndex += "    var cards=document.querySelectorAll('.index-card[data-region]'),n=0;`n"
$countriesIndex += "    cards.forEach(function(c){`n"
$countriesIndex += "      var ok=(ar==='all'||c.dataset.region===ar);`n"
$countriesIndex += "      c.style.display=ok?'':'none';if(ok)n++;`n"
$countriesIndex += "    });`n"
$countriesIndex += "    var el=document.getElementById('country-filter-count');`n"
$countriesIndex += "    if(el)el.textContent=n+' countr'+(n===1?'y':'ies');`n"
$countriesIndex += "  }`n"
$countriesIndex += "  document.querySelectorAll('[data-filter-region]').forEach(function(b){`n"
$countriesIndex += "    b.addEventListener('click',function(){`n"
$countriesIndex += "      document.querySelectorAll('[data-filter-region]').forEach(function(x){x.classList.remove('active');});`n"
$countriesIndex += "      b.classList.add('active');ar=b.dataset.filterRegion;run();`n"
$countriesIndex += "    });`n"
$countriesIndex += "  });`n"
$countriesIndex += "})();`n"
$countriesIndex += "  </script>`n"
$countriesIndex += "  <script src=`"/js/consent.js?v=3`"></script>`n"
$countriesIndex += "</body>`n</html>`n"

[System.IO.File]::WriteAllText("$base\countries.html", $countriesIndex, [System.Text.Encoding]::UTF8)
Write-Host "countries.html written"

# â”€â”€ UPDATE SITEMAP.XML â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$today = (Get-Date).ToString('yyyy-MM-dd')

$sitemapUrls = @()
$sitemapUrls += "  <url><loc>https://cinemamapped.com/</loc><lastmod>$today</lastmod><changefreq>weekly</changefreq><priority>1.0</priority></url>"
$sitemapUrls += "  <url><loc>https://cinemamapped.com/map</loc><lastmod>$today</lastmod><changefreq>weekly</changefreq><priority>0.9</priority></url>"
$sitemapUrls += "  <url><loc>https://cinemamapped.com/film-locations</loc><lastmod>$today</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>"
$sitemapUrls += "  <url><loc>https://cinemamapped.com/films</loc><lastmod>$today</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>"
$sitemapUrls += "  <url><loc>https://cinemamapped.com/countries</loc><lastmod>$today</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>"

foreach ($t in $allTitles) {
    $tSlug = ToSlug $t
    $sitemapUrls += "  <url><loc>https://cinemamapped.com/films/$tSlug</loc><lastmod>$today</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>"
}
foreach ($c in $allCountries) {
    $cSlug = ToSlug $c
    $sitemapUrls += "  <url><loc>https://cinemamapped.com/countries/$cSlug</loc><lastmod>$today</lastmod><changefreq>monthly</changefreq><priority>0.7</priority></url>"
}

# Re-add all pin pages
$usedSlugs2 = @{}
foreach ($pin in $data) {
    $b2 = "$(ToSlug $pin.title)-$(ToSlug $pin.location)"
    if ($usedSlugs2.ContainsKey($b2)) {
        $usedSlugs2[$b2]++
        $sl = "$b2-$($usedSlugs2[$b2])"
    } else {
        $usedSlugs2[$b2] = 1
        $sl = $b2
    }
    $sitemapUrls += "  <url><loc>https://cinemamapped.com/locations/$sl</loc><lastmod>$today</lastmod><changefreq>monthly</changefreq><priority>0.7</priority></url>"
}

$sitemap  = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n"
$sitemap += "<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n"
$sitemap += ($sitemapUrls -join "`n")
$sitemap += "`n</urlset>`n"

[System.IO.File]::WriteAllText("$base\sitemap.xml", $sitemap, [System.Text.Encoding]::UTF8)
Write-Host "sitemap.xml updated - $($sitemapUrls.Count) URLs total"
Write-Host "Done. Film pages: $filmCount_total | Country pages: $countryCount_total"

