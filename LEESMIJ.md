# Screenshot Editor gebruiken

De aanbevolen versie voor **Mac, Windows en Linux** staat in index.html. Lees [Beginnen, dagelijks gebruik en Zo pas je Screenshot Editor aan](README.md).

Alle benodigde browserbestanden zitten in dit pakket. Python is alleen nodig voor de optionele lokale starter; Node.js alleen voor ontwikkelaarstests. Er is geen cloudaccount of AI-sleutel nodig.

## Bestaande native Mac-versie

De oorspronkelijke Swift/AppKit-bron is behouden in Sources/. Met Apple Command Line Tools bouw je die via `zsh bouw.sh`; open daarna FMT Screenshot Editor.app. Deze versie werkt uitsluitend op macOS, heeft een andere opslagplaats dan de browserversie en krijgt geen Windows/Linux-binary door dit bouwcommando.

De browserversie gebruikt een schermkiezer en heeft geen globale sneltoets. De native Mac-versie gebruikt macOS-schermopname en Ctrl+Option+Command+S. Gebruik de [native handleiding](docs/NATIVE-MAC.md) alleen voor die oudere bouwroute. De daarin genoemde Mac-proeven gelden niet als platformbewijs voor de browserversie.
