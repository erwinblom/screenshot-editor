# Screenshot Editor aanpassen: instructies voor de AI

Je helpt iemand die deze editor naar eigen smaak wil maken. Ga ervan uit dat die persoon geen programmeur is. Dit bestand vertelt wat je vrij mag veranderen en wat heel moet blijven.

## Hoe je werkt

- Werk in een kopie van de map. Het origineel blijft onaangeroerd.
- Maak één wijziging per keer, zo klein als kan.
- Leg in gewone taal uit wat je hebt veranderd en hoe de gebruiker dat zelf controleert.
- Zeg eerlijk wat je werkelijk hebt getest en wat niet.
- Publiceer, verstuur of upload niets. Vraag de gebruiker niet om persoonlijke screenshots.
- Kun je de bestanden niet zelf bewerken? Lever dan het complete aangepaste project terug.

## Waar alles staat

De browserversie bestaat uit drie bestanden.

| Wat | Waar |
|---|---|
| Beeldformaten en achtergrondkleuren van de PNG | het blok INSTELLINGEN bovenaan `web/app.js`, plus de bijbehorende `<option>` in `index.html` |
| Hoe de PNG eruitziet: lettergroottes, marges, kader, plaats van naam, logo en onderschrift | de functie `draw()` in `web/app.js` |
| Kleuren, letters en indeling van de editor zelf | `web/style.css`, te beginnen bij `:root` |
| Knoppen, velden en teksten op het scherm | `index.html` |
| Meldingen onder de knoppen | de `status(...)`-regels in `web/app.js` |
| Maximale bestandsgrootte en toegestane bestandstypen | de functie `fileData()` in `web/app.js` |
| Naam van het gedownloade bestand | `a.download` bij de knop `save` in `web/app.js` |
| Het lokale adres en de poort van de starter | `start.py` |

`Sources/`, `bouw.sh` en `Resources/Info.plist` horen bij een oudere Mac-app. Laat die met rust, tenzij de gebruiker er uitdrukkelijk om vraagt.

## Vrij te veranderen

Kleuren, letters, indeling, naam, logo, icoon, alle teksten, de taal, extra beeldformaten, extra achtergronden, een vast onderschrift, nieuwe knoppen en nieuwe functies. Dit is een vertrekpunt: de vormgeving en de iconen van de maker zijn geen voorschrift.

## Wat heel moet blijven

1. **Het werkgeheugen.** De laatste afbeelding, tekst en stijl komen terug na sluiten en heropenen. De naam `fmt-screenshot-editor-web` van de opslag blijft gelijk; met een andere naam lijkt bestaand werk verdwenen.
2. **De PNG bevat wat het voorbeeld toont.** Geen toegevoegd logo of verplichte naamsvermelding. De eigen stijl van de gebruiker blijft optioneel.
3. **Alles blijft lokaal.** Geen upload, tracking, externe scripts of externe fonts. De regel `Content-Security-Policy` in `index.html` bewaakt dat; versoepel die alleen als de gebruiker er uitdrukkelijk om vraagt en leg uit wat het betekent.
4. **Schermopname stopt meteen na één beeld**, zonder geluid.
5. **De starter is alleen op de eigen computer bereikbaar** (`127.0.0.1`).
6. **`LICENSE` blijft in de map**, met de naam van de oorspronkelijke maker.

## Controleren na elke wijziging

Laat de gebruiker dit zelf doen in Chrome of Edge:

1. Open `index.html` en laad een afbeelding.
2. Schrijf een onderschrift, wissel van formaat en achtergrond.
3. Maak een tekstkaart via **Citaat / slogan**.
4. Klik **Bewaar PNG** en open het bestand.
5. Sluit de browser helemaal en open opnieuw. Staat het werk er nog?

Wie Node.js heeft, kan `npm ci` en `npm test` draaien. Chrome en Python moeten dan geïnstalleerd zijn. De test controleert onder meer de PNG. Verander je bewust hoe het beeld eruitziet, pas dan ook `tests/browser.cjs` aan en zeg dat erbij.

Voeg je een bestand toe dat in de download hoort, zet het dan ook in `release-files.txt`.

## Een eigen versie delen

Voor eigen gebruik hoeft de gebruiker niets te hernoemen. Wil hij zijn versie verspreiden, dan gelden de afspraken in `docs/MERKVOORWAARDEN.md`: eigen naam, eigen logo en eigen icoon, en geen FMT of fastmovingtargets.nl meer in beeld. Vervang dan de naam in `<title>`, `<h1>` en de voettekst van `index.html` en het icoon `Resources/FMT-tool-icon.png`. "Gebaseerd op FMT Screenshot Editor" vermelden mag.

De afspraken in `docs/ONDERHOUD.md` gelden alleen voor de officiële FMT-uitgave, niet voor een eigen versie.
