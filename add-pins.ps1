$base = 'C:\Users\meewe\projects\cinemamapped'
$data = [System.IO.File]::ReadAllText("$base\data.json", [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$arr  = [System.Collections.Generic.List[object]]($data)
$id   = 286

function Pin($title, $type, $location, $country, $theatre, $lat, $lng, $seq, $desc, $hist, $year, $stream) {
    [PSCustomObject]@{
        id                 = $script:id++
        title              = $title
        type               = $type
        location           = $location
        country            = $country
        theatre            = $theatre
        lat                = $lat
        lng                = $lng
        sequence           = $seq
        description        = $desc
        historical_context = $hist
        year_portrayed     = $year
        streaming          = $stream
    }
}

$spr  = 'https://www.amazon.com/dp/B0H4JHTBPH?tag=cinemamapped-20'
$schl = 'https://www.amazon.com/dp/B00BEN0V8S?tag=cinemamapped-20'
$pian = 'https://www.amazon.com/dp/B084TNF6CZ?tag=cinemamapped-20'
$fall = 'https://www.amazon.com/dp/B0D4MNFVBJ?tag=cinemamapped-20'
$mota = 'https://www.amazon.com/dp/B0D8XJYBLV?tag=cinemamapped-20'

# SAVING PRIVATE RYAN

$arr.Add((Pin 'Saving Private Ryan' 'Film' 'Colleville-sur-Mer American Cemetery, Normandy' 'France' 'Western Front' 49.3588 -0.8629 3 `
    'The film opens and closes here -- an elderly James Ryan visits the grave of Captain Miller at the Normandy American Cemetery, overlooking Omaha Beach.' `
    'The Normandy American Cemetery at Colleville-sur-Mer holds 9,387 American military dead from the D-Day landings and subsequent operations. It overlooks the very beach where many of them fell on June 6, 1944.' `
    1944 $spr))

$arr.Add((Pin 'Saving Private Ryan' 'Film' 'Neuville-au-Plain, Normandy' 'France' 'Western Front' 49.4276 -1.2891 4 `
    'Miller is told Private Ryan was last spotted with a 101st Airborne patrol near this area -- setting the squad on their mission into the Normandy bocage.' `
    'Neuville-au-Plain was one of several Normandy villages where the 82nd Airborne fought in the days following D-Day, clearing German resistance and linking up with forces pushing inland from the beaches.' `
    1944 $spr))

$arr.Add((Pin 'Saving Private Ryan' 'Film' 'Sainte-Mere-Eglise, Normandy' 'France' 'Western Front' 49.4097 -1.3175 5 `
    'The 82nd Airborne drop zone -- the division Ryan served with. The town was the first French town liberated on D-Day, hours before the beach landings.' `
    'American paratroopers of the 82nd Airborne Division dropped into the area around Sainte-Mere-Eglise in the early hours of June 6, 1944. The town was secured by 0500 -- the first French commune liberated in the Normandy invasion.' `
    1944 $spr))

# SCHINDLERS LIST

$arr.Add((Pin "Schindler's List" 'Film' 'Auschwitz-Birkenau, Poland' 'Poland' 'Eastern Front' 50.0342 19.1784 4 `
    "SS commandant Amon Goth threatens to send Schindler's Jewish workers to Auschwitz. The camp functions as the constant off-screen threat hanging over every scene in Krakow and Plaszow." `
    'Auschwitz-Birkenau was the largest Nazi concentration and extermination camp, where approximately 1.1 million people were murdered between 1940 and 1945. Located 70km from Krakow, it is today a UNESCO World Heritage Site and memorial.' `
    1944 $schl))

$arr.Add((Pin "Schindler's List" 'Film' "Emalia Factory (now Schindler's Museum), Krakow" 'Poland' 'Eastern Front' 50.0430 19.9568 5 `
    "Schindler's Deutsche Emailwarenfabrik on Lipowa Street -- the enamelware factory where he employed 1,750 Jewish workers, knowingly protecting them from the camps by keeping them on the payroll." `
    "Oscar Schindler's factory at ul. Lipowa 4 in Krakow's Zablocie district is now the Schindler Museum, one of Poland's most visited historical sites. The original production hall and offices are preserved as they appeared during the occupation." `
    1943 $schl))

$arr.Add((Pin "Schindler's List" 'Film' "Amon Goth's villa, Plaszow" 'Poland' 'Eastern Front' 50.0294 20.0139 6 `
    'Commandant Goth shoots prisoners from the balcony of his white villa overlooking the Plaszow camp -- one of the most chilling images in the film, based directly on survivor testimony.' `
    'Amon Goth was commandant of the Plaszow forced labour camp from 1943 to 1944. He was known to shoot prisoners from his villa balcony. After the war, Goth was tried by a Polish court and executed in 1946 near the former Plaszow site.' `
    1943 $schl))

# DUNKIRK

$arr.Add((Pin 'Dunkirk' 'Film' 'Dunkirk East Mole, northern France' 'France' 'Western Front' 51.0411 2.3793 2 `
    'The East Mole -- the narrow concrete pier extending from Dunkirk harbour -- becomes the main embarkation point. Commander Bolton coordinates the evacuation from its exposed walkway as destroyers tie up alongside.' `
    'The East Mole at Dunkirk was never designed for large-scale embarkation. Necessity turned it into the primary boarding point during Operation Dynamo, allowing destroyers to take on thousands of men who could not be reached by small boats on the open beach.' `
    1940 ''))

$arr.Add((Pin 'Dunkirk' 'Film' 'Bray-Dunes, northern France' 'France' 'Western Front' 51.0683 2.5300 3 `
    'The wide tidal beaches east of Dunkirk where Allied soldiers waited for rescue -- often under Luftwaffe attack, with nowhere to take cover on the open sand.' `
    'Bray-Dunes, just east of Dunkirk near the Belgian border, formed part of the defensive perimeter held by French rearguard forces. French troops were among the last to leave, and thousands were captured when the perimeter collapsed on June 4, 1940.' `
    1940 ''))

$arr.Add((Pin 'Dunkirk' 'Film' 'Dover, Kent, England' 'United Kingdom' 'Western Front' 51.1279 1.3134 4 `
    'The port from which the civilian small craft fleet set out across the Channel. The white cliffs of Dover were the last sight of England for soldiers going in -- and the first sight for survivors coming home.' `
    'Dover served as the primary naval headquarters for Operation Dynamo, directed by Vice Admiral Bertram Ramsay from tunnels beneath Dover Castle. Over 800 civilian vessels answered the call and made the crossing, supplementing naval destroyers and minesweepers.' `
    1940 ''))

$arr.Add((Pin 'Dunkirk' 'Film' 'Weymouth, Dorset, England' 'United Kingdom' 'Western Front' 50.6097 -2.4575 5 `
    'Soldiers arrive home by train, offered cigarettes and tea by civilians on the platform. A boy reads the Churchill speech from a newspaper -- the nation learning what happened across the Channel.' `
    'Weymouth was one of several south coast ports used to disembark survivors of the Dunkirk evacuation. Troop trains distributed the men across Britain. The public reception ranged from relief to the quiet shame many soldiers felt at leaving France without fighting through.' `
    1940 ''))

# THE PIANIST

$arr.Add((Pin 'The Pianist' 'Film' 'Umschlagplatz, Warsaw' 'Poland' 'Eastern Front' 52.2574 20.9916 3 `
    'The Szpilman family is taken to the Umschlagplatz -- the deportation assembly point adjacent to Warsaw freight station -- where hundreds of thousands of Ghetto Jews were loaded onto trains to Treblinka.' `
    'The Umschlagplatz on Stawki Street was the collection point from which approximately 300,000 Jews from the Warsaw Ghetto were deported to the Treblinka extermination camp during the Grossaktion in summer 1942. A memorial now marks the site.' `
    1942 $pian))

$arr.Add((Pin 'The Pianist' 'Film' 'Nowogrodzka Street, Warsaw' 'Poland' 'Eastern Front' 52.2313 21.0049 4 `
    "Szpilman's first hiding place on the Aryan side of Warsaw -- a safe apartment arranged by former colleagues, where he watches the Ghetto Uprising from his window across the rooftops." `
    'After being pulled from the deportation line, Szpilman was smuggled to the Aryan side of Warsaw, where Polish friends moved him between safe houses. He was in the Nowogrodzka area when the Warsaw Ghetto Uprising began in April 1943.' `
    1943 $pian))

$arr.Add((Pin 'The Pianist' 'Film' 'Zoliborz district, Warsaw' 'Poland' 'Eastern Front' 52.2669 20.9839 5 `
    'A ruined villa in Zoliborz where Szpilman hides alone through the winter of 1944-45 -- and where German Captain Hosenfeld discovers him and asks him to play the piano.' `
    'After the Warsaw Uprising of 1944, most of the city was systematically destroyed by German engineers on Hitler orders. Szpilman spent months hiding in the rubble of Zoliborz until the Soviet advance in January 1945.' `
    1944 $pian))

# DOWNFALL

$arr.Add((Pin 'Downfall' 'Film' 'Reich Chancellery, Berlin' 'Germany' 'Western Front' 52.5116 13.3826 3 `
    "The New Reich Chancellery on Vossstrasse -- Hitler's seat of government -- burns above the underground bunker where the final decisions are made. Its grand halls are now strewn with the dead." `
    "Albert Speer's New Reich Chancellery, completed in 1939, was partially destroyed in the Battle of Berlin. Hitler spent his final weeks between the Chancellery and the underground Fuhrerbunker beneath its gardens. Soviet engineers demolished the ruins in the late 1940s -- nothing remains today." `
    1945 $fall))

$arr.Add((Pin 'Downfall' 'Film' 'Tempelhof Airport, Berlin' 'Germany' 'Western Front' 52.4736 13.4019 4 `
    'One of the last functioning airstrips in Berlin -- used by Albert Speer to fly in and out of the encircled city despite Hitler fury at the disloyalty of his architect.' `
    'Tempelhof Airport remained operational until late April 1945, serving as an entry and exit point for a besieged city. It was used for supply flights and by senior officials making final visits. Soviet forces captured it on April 27, 1945.' `
    1945 $fall))

# FURY

$arr.Add((Pin 'Fury' 'Film' 'Cologne, Germany' 'Germany' 'Western Front' 50.9333 6.9500 2 `
    'The tank crew passes through a ruined Cologne -- its cathedral improbably still standing amid total devastation -- advancing with the 2nd Armored Division into the German heartland in early 1945.' `
    'Cologne was captured by American forces on March 6-7, 1945 after heavy fighting. The city was 90 percent destroyed but Cologne Cathedral survived -- having been used by Allied navigators as a landmark for bombing missions.' `
    1945 ''))

$arr.Add((Pin 'Fury' 'Film' 'Magdeburg area, Saxony-Anhalt, Germany' 'Germany' 'Western Front' 52.1205 11.6276 3 `
    "The 2nd Armored Division's final advance through central Germany in April 1945 -- ruined villages and desperate last-stand resistance that forms the backdrop of Fury's final act." `
    'In April 1945, the US 2nd Armored Division drove through central Germany, reaching the Elbe River at Magdeburg on April 11-12. American forces halted there per the Elbe Agreement, waiting for Soviet forces -- leaving Berlin to the Red Army.' `
    1945 ''))

# MASTERS OF THE AIR

$arr.Add((Pin 'Masters of the Air' 'Series' 'Berlin, Germany' 'Germany' 'Western Front' 52.5200 13.4050 5 `
    '"The Big B" -- Berlin -- is the most feared target in the series, representing maximum range and the heaviest German defences. The missions to Berlin defined the cost of the strategic bombing campaign.' `
    'The US Eighth Air Force began sustained bombing of Berlin in March 1944. The 100th Bomb Group earned its nickname "The Bloody Hundredth" partly through catastrophic losses on long-range missions like these. Berlin air defences included hundreds of flak batteries and near-constant fighter cover.' `
    1944 $mota))

$arr.Add((Pin 'Masters of the Air' 'Series' 'Bremen, Germany' 'Germany' 'Western Front' 53.0793 8.8017 6 `
    'One of the Eighth Air Force earliest and most costly targets -- Bremen U-boat yards and aircraft factories drew repeated missions from 1942, with severe losses from Luftwaffe interception before long-range fighter escort arrived.' `
    'Bremen was attacked by the Eighth Air Force from its earliest operations in 1942. Its Focke-Wulf aircraft factories, U-boat yards, and oil refineries made it a priority target. The missions demonstrated both the potential and terrible cost of daylight precision bombing without fighter escort.' `
    1943 $mota))

# VALKYRIE

$arr.Add((Pin 'Valkyrie' 'Film' 'Plotzensee Prison, Berlin' 'Germany' 'Western Front' 52.5447 13.3178 4 `
    'The execution site -- where eight conspirators including Field Marshal von Witzleben were hanged on meat hooks with piano wire on August 8, 1944, filmed on Goebbels orders. Stauffenberg and three others had been shot in the Bendlerblock courtyard hours after the failed bomb.' `
    'Plotzensee Prison in Berlin Charlottenburg was used for the execution of resistance members throughout the Nazi period. Following the July 20 plot, nearly 200 people connected to the conspiracy were executed there. A memorial at the site commemorates over 2,500 people executed at Plotzensee between 1933 and 1945.' `
    1944 ''))

# WRITE UPDATED DATA

$json = $arr | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText("$base\data.json", $json, [System.Text.Encoding]::UTF8)
Write-Host "Done. Added $($id - 286) new pins. Total: $($arr.Count)"
