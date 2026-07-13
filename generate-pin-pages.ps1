# Generate individual pin pages for CinemaMapped
$base   = 'C:\Users\meewe\projects\cinemamapped'
$outDir = "$base\locations"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$data = [System.IO.File]::ReadAllText("$base\data.json", [System.Text.Encoding]::UTF8) | ConvertFrom-Json

function HtmlEncode($str) {
    if (-not $str) { return '' }
    return $str.ToString() -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;'
}

function ToSlug($str) {
    if (-not $str) { return '' }
    $s = $str.ToLower()
    # Handle chars that don't decompose via Unicode NFD
    $s = $s -replace [char]0x0142, 'l'   # l-stroke (l with stroke)
    $s = $s -replace [char]0x0141, 'l'   # L-stroke
    $s = $s -replace [char]0x00DF, 'ss'  # eszett
    $s = $s -replace [char]0x00E6, 'ae'  # ae ligature
    $s = $s -replace [char]0x00F8, 'o'   # o-stroke
    $s = $s -replace [char]0x0111, 'd'   # d-stroke
    # NFD decomposition splits e.g. e-acute into e + combining accent, then strip combining chars
    $norm = $s.Normalize([System.Text.NormalizationForm]::FormD)
    $ascii = [System.Text.RegularExpressions.Regex]::Replace($norm, '[^\x00-\x7F]', '')
    $ascii = $ascii -replace "[^a-z0-9\s]", ''
    $ascii = $ascii -replace '\s+', '-'
    $ascii = $ascii -replace '-+', '-'
    return $ascii.Trim('-')
}

# Group pins by title for related links
$byTitle = @{}
foreach ($pin in $data) {
    if (-not $byTitle.ContainsKey($pin.title)) { $byTitle[$pin.title] = @() }
    $byTitle[$pin.title] += $pin
}

# First pass: assign slugs (handle duplicates)
$usedSlugs = @{}
foreach ($pin in $data) {
    $base2 = "$(ToSlug $pin.title)-$(ToSlug $pin.location)"
    if ($usedSlugs.ContainsKey($base2)) {
        $usedSlugs[$base2]++
        $slug = "$base2-$($usedSlugs[$base2])"
    } else {
        $usedSlugs[$base2] = 1
        $slug = $base2
    }
    $pin | Add-Member -NotePropertyName 'slug' -NotePropertyValue $slug -Force
}

# Favicon data URI (no special chars that confuse PS parser)
$faviconUri = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 500 500'%3E%3Crect width='500' height='500' rx='60' fill='%230d0d0d'/%3E%3Ctext x='250' y='360' font-family='Arial Black,Arial,sans-serif' font-size='340' font-weight='900' text-anchor='middle' fill='%23c9a84c'%3EC%3C/text%3E%3C/svg%3E"

# Second pass: write HTML files
$count = 0
foreach ($pin in $data) {
    $slug        = $pin.slug
    $titleHtml   = HtmlEncode $pin.title
    $locHtml     = HtmlEncode $pin.location
    $countryHtml = HtmlEncode $pin.country
    $theatreHtml = HtmlEncode $pin.theatre
    $descHtml    = HtmlEncode $pin.description
    $histHtml    = HtmlEncode $pin.historical_context
    $typeHtml    = HtmlEncode $pin.type
    $year        = $pin.year_portrayed
    $lat         = $pin.lat
    $lng         = $pin.lng
    $streaming   = $pin.streaming
    $canonUrl    = "https://cinemamapped.com/locations/$slug"
    $mapUrl      = "/map?film=" + [Uri]::EscapeDataString($pin.title)
    $schemaType  = if ($pin.type -eq 'Series') { 'TVSeries' } else { 'Movie' }
    $descMeta    = ($descHtml -replace '"', '&quot;') -replace "`n", ' '
    $descJson    = ($pin.description -replace '"', '\"') -replace '\\', '\\'
    $histJson    = ($pin.historical_context -replace '"', '\"') -replace '\\', '\\'
    $locJson     = $pin.location -replace '"', '\"'
    $titleJson   = $pin.title -replace '"', '\"'

    # Watch button
    $watchBlock = ''
    if ($streaming) {
        $streamSafe = HtmlEncode $streaming
        $watchBlock = "    <a class=`"pin-watch-btn`" href=`"$streamSafe`" target=`"_blank`" rel=`"noopener noreferrer sponsored`">Watch on Amazon &#x2197;</a>`n    <p class=`"pin-affiliate-note`">As an Amazon Associate I earn from qualifying purchases.</p>"
    }

    # Related pins
    $relBlock = ''
    $related = @($byTitle[$pin.title] | Where-Object { $_.id -ne $pin.id } | Select-Object -First 6)
    if ($related.Count -gt 0) {
        $liItems = ($related | ForEach-Object {
            $rLoc  = HtmlEncode $_.location
            $rSlug = $_.slug
            "        <li><a href=`"/locations/$rSlug`">$rLoc</a></li>"
        }) -join "`n"
        $relBlock = "    <div class=`"pin-related`">`n      <div class=`"pin-desc-label`">Other $titleHtml locations</div>`n      <ul class=`"related-list`">`n$liItems`n      </ul>`n    </div>"
    }

    $html  = "---`n---`n"
    $html += "<!DOCTYPE html>`n<html lang=`"en`">`n<head>`n"
    $html += "  <meta charset=`"UTF-8`">`n"
    $html += "  <meta name=`"viewport`" content=`"width=device-width, initial-scale=1.0`">`n"
    $html += "  <title>$locHtml - $titleHtml | CinemaMapped</title>`n"
    $html += "  <meta name=`"description`" content=`"$locHtml, $countryHtml. As seen in $titleHtml ($year). $descMeta`">`n"
    $html += "  <link rel=`"icon`" href=`"$faviconUri`">`n"
    $html += "  <link rel=`"icon`" href=`"/favicon.ico`">`n"
    $html += "  <link rel=`"canonical`" href=`"$canonUrl`">`n"
    $html += "  <meta property=`"og:title`" content=`"$locHtml - $titleHtml`">`n"
    $html += "  <meta property=`"og:description`" content=`"$descMeta`">`n"
    $html += "  <meta property=`"og:type`" content=`"article`">`n"
    $html += "  <meta property=`"og:url`" content=`"$canonUrl`">`n"
    $html += "  <meta property=`"og:image`" content=`"https://cinemamapped.com/og-image.svg`">`n"
    $html += "  <script type=`"application/ld+json`">`n  {`n    `"@context`": `"https://schema.org`",`n    `"@type`": `"Place`",`n    `"name`": `"$locJson`",`n    `"geo`": { `"@type`": `"GeoCoordinates`", `"latitude`": $lat, `"longitude`": $lng },`n    `"url`": `"$canonUrl`",`n    `"isPartOf`": { `"@type`": `"$schemaType`", `"name`": `"$titleJson`" }`n  }`n  </script>`n"
    $html += "  <link rel=`"preconnect`" href=`"https://fonts.googleapis.com`">`n"
    $html += "  <link rel=`"preconnect`" href=`"https://fonts.gstatic.com`" crossorigin>`n"
    $html += "  <link href=`"https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@300;400;500;600&display=swap`" rel=`"stylesheet`">`n"
    $html += "  <link rel=`"stylesheet`" href=`"https://unpkg.com/leaflet@1.9.4/dist/leaflet.css`">`n"
    $html += "  <link rel=`"stylesheet`" href=`"/style.css`">`n"
    $html += "</head>`n<body>`n`n"

    # Nav
    $html += "  <nav class=`"nav`">`n"
    $html += "    <a href=`"/`" class=`"nav-logo`">Cinema<em>Mapped</em></a>`n"
    $html += "    <div style=`"display:flex;gap:12px;align-items:center;`">`n"
    $html += "      <a href=`"/films`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Films &amp; Series</a>`n"
    $html += "      <a href=`"/countries`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Countries</a>`n"
    $html += "      <a href=`"/film-locations`" class=`"btn`" style=`"font-size:11px;padding:8px 16px;`">Guide</a>`n"
    $html += "      <a href=`"/map`" class=`"btn btn-filled`">Explore the Map</a>`n"
    $html += "    </div>`n  </nav>`n`n"

    # Hero
    $html += "  <div class=`"pin-page-hero`">`n"
    $html += "    <div class=`"pin-page-breadcrumb`"><a href=`"/`">CinemaMapped</a> &rsaquo; <a href=`"$mapUrl`">$titleHtml</a> &rsaquo; $locHtml</div>`n"
    $html += "    <div class=`"pin-page-badges`"><span class=`"badge badge-type`">$typeHtml</span><span class=`"badge badge-theatre`">$theatreHtml</span><span class=`"pin-page-year`">$year</span></div>`n"
    $html += "    <h1 class=`"pin-page-h1`">$locHtml</h1>`n"
    $html += "    <p class=`"pin-page-title-line`">$titleHtml &mdash; $countryHtml</p>`n"
    $html += "  </div>`n`n"

    # Map
    $html += "  <div id=`"pin-map`" class=`"pin-page-map`"></div>`n`n"

    # Body
    $html += "  <div class=`"pin-page-body`">`n"
    $html += "    <div class=`"pin-page-section`"><div class=`"pin-desc-label`">Scene</div><p class=`"pin-page-text`">$descHtml</p></div>`n"
    $html += "    <div class=`"pin-divider`"></div>`n"
    $html += "    <div class=`"pin-page-section`"><div class=`"pin-desc-label`">History</div><p class=`"pin-page-text`">$histHtml</p></div>`n"
    if ($watchBlock) { $html += "$watchBlock`n" }
    if ($relBlock)   { $html += "$relBlock`n" }
    $html += "    <div class=`"pin-page-cta`"><a href=`"$mapUrl`" class=`"btn btn-filled`">See all $titleHtml locations &rarr;</a></div>`n"
    $html += "  </div>`n`n"

    # Footer
    $html += "  <footer class=`"footer`">`n"
    $html += "    <span class=`"footer-brand`">Cinema<em style=`"color:var(--accent)`">Mapped</em></span>`n"
    $html += "    <span class=`"footer-copy`">&copy; 2026 CinemaMapped &nbsp;&middot;&nbsp;<a href=`"/privacy`" style=`"color:var(--text-muted);text-decoration:none;`">Privacy Policy</a>&nbsp;&middot;&nbsp;<a href=`"/terms`" style=`"color:var(--text-muted);text-decoration:none;`">Terms of Use</a></span>`n"
    $html += "  </footer>`n`n"

    # Scripts
    $html += "  <script src=`"https://unpkg.com/leaflet@1.9.4/dist/leaflet.js`"></script>`n"
    $html += "  <script>`n"
    $html += "    var m = L.map('pin-map', { zoomControl:true, attributionControl:false, scrollWheelZoom:false });`n"
    $html += "    m.setView([$lat, $lng], 8);`n"
    $html += "    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { subdomains:'abcd', maxZoom:19 }).addTo(m);`n"
    $html += "    L.circleMarker([$lat, $lng], { radius:9, color:'#c9a84c', fillColor:'#c9a84c', fillOpacity:1, weight:2, interactive:false }).addTo(m);`n"
    $html += "  </script>`n"
    $html += "  <script src=`"/js/consent.js?v=3`"></script>`n"
    $html += "</body>`n</html>`n"

    [System.IO.File]::WriteAllText("$outDir\$slug.html", $html, [System.Text.Encoding]::UTF8)
    $count++
}

Write-Host "Done. Generated $count pin pages in $outDir"
