# FMT Screenshot Editor

## Waarom ik dit deel

Ik ben geen programmeur en geen designer. Met AI maak ik tools en skills die ik zelf nodig heb. Ik deel ze om te laten zien wat er nu mogelijk is, je enthousiast te maken en je op gang te helpen. Gebruik dit als vertrekpunt: bouw erop voort en maak het passend bij jouw werk, smaak en wensen.

Zie je iets dat slimmer kan? Pak gerust je gereedschap — of je favoriete AI. Bugs melden mag ook. Je hoeft verbeteringen niet terug te geven; als je iets deelt, graag met behoud van licenties en credits van andere makers.

## Een vliegende start voor jouw eigen tool

Ik deel mijn tools zodat je iets werkends hebt om mee te beginnen. Gebruik ze zoals ze zijn, of maak ze passend bij je eigen smaak en wensen: andere kleuren, eigen vormgeving, een extra knop of een andere werkwijze.

Je hoeft de code niet eerst helemaal te begrijpen. Met ChatGPT of Claude kun je in gewone taal beschrijven wat je wilt veranderen en stap voor stap aan je eigen versie werken. Begin met één kleine aanpassing, bekijk het resultaat en bouw daarop verder.

Bugs melden is welkom. Nog liever zie ik dat je zelf gaat bouwen en aanpassen. Je hoeft daarvoor niet op mijn planning of toestemming te wachten: de code is beschikbaar onder MIT. Als je iets bruikbaars maakt, vind ik het leuk als je het deelt. Dat is geen verplichting. Voor een eigen versie die je verspreidt, gebruik je een eigen naam en logo; zie MERKVOORWAARDEN.md.

## Zelf verder met ChatGPT of Claude

1. Bewaar het originele bron-ZIP en pak een kopie uit voor jouw versie. Deze tool is voor macOS. Houd Sources, Resources en bouw.sh samen in de uitgepakte projectmap.
2. Begin een nieuwe gewone chat in ChatGPT of Claude. Voeg het volledige bron-ZIP toe en plak de startprompt hieronder. Zo heeft de AI ook het logo, de appgegevens en de licenties. Wordt ZIP niet ondersteund, vraag eerst hoe je de losse bestanden kunt aanleveren; alleen main.swift is onvoldoende om de hele app te bouwen.
3. Vraag om één concrete wijziging en een volledig aangepast project als download. Een gewone chat wijzigt niet rechtstreeks bestanden op je Mac. Pak de ontvangen ZIP uit in een nieuwe map; houd je origineel apart. Kan jouw AI-werkomgeving lokale bestanden bewerken, laat haar dan uitsluitend in jouw projectkopie werken.
4. Werkt een download niet? Zeg: “De download levert geen bestand op. Geef voor deze kleine aanpassing exact welke tekst ik zoek en wat ik vervang, met bestandsnaam en het aantal wijzigingen.” Gebruik een code-editor die gewone tekst bewaart; vermijd Teksteditor in opgemaakte tekstmodus. Vraag bij grotere wijzigingen opnieuw om complete bestanden, zodat je geen grote stukken hoeft samen te voegen.
5. Bouw en open de nieuwe versie met de stappen hieronder. Controleer de wijziging en daarna laden, tekst, PNG bewaren en heropenen. Bewaar een werkende versie voor de volgende wens. Een AI-melding “klaar” is nog geen geslaagde proef op jouw Mac.

### Startprompt om te kopiëren

> Dit is de broncode van een werkende Mac-app die ik naar mijn eigen smaak wil aanpassen. Ik ben geen programmeur. Lees eerst alle bestanden. Mijn eerste wens is: verander alleen de rode accentkleur van de bediening naar blauw #2563EB. Behoud het FMT-logo, de achtergrondkeuzes en de kleuren van de beeldexports. Maak de kleinste passende wijziging en behoud de andere functies. Lever het volledige aangepaste project als download en vermeld welke bestanden zijn veranderd. Kun je mijn lokale bestanden bewerken, werk dan uitsluitend in mijn projectkopie. Help me stap voor stap de app op mijn Mac te bouwen en te openen. Vermeld wat daadwerkelijk getest is en wat ik zelf nog moet controleren. Behoud de MIT-vermelding en de aparte FMT-merkvoorwaarden. Niets publiceren.

Vervang de kleurwens daarna door jouw eigen kleine wens. Deze blauwe bedieningskleur is op 21 oktober 2026 met ChatGPT beproefd; de terugval met exacte tekstwijzigingen bouwde en werkte op de test-Mac. De aangeboden download werkte in die proef niet. Claude en een Mac zonder bouwtools zijn niet getest.

### Zelf bouwen op je Mac

1. Open Terminal via Spotlight (Command+spatie, typ Terminal).
2. Controleer of de Apple-bouwtools beschikbaar zijn met `xcode-select -p`. Krijg je een fout, voer dan `xcode-select --install` uit en voltooi de Apple-installatie voordat je verdergaat. Een volledige Xcode-installatie is voor deze bouwroute niet nodig.
3. Typ `cd` en een spatie in Terminal. Sleep de uitgepakte projectmap vanuit Finder naar Terminal en druk op Enter. Kies de map waar je bouw.sh ziet, niet de bovenliggende downloadmap.
4. Voer `zsh bouw.sh` uit. Wacht tot je “Gebouwd:” ziet. Krijg je een fout, plak de volledige foutmelding in je AI-chat; geef geen wachtwoorden of persoonlijke bestanden mee.
5. Sluit alle eerdere FMT Screenshot-kopieën. Open de app vanuit deze projectmap: `open "FMT Screenshot Editor.app"`. Gebruik voor deze proef geen oud Dock-icoon. De kopie heeft dezelfde app-identiteit en lokale opslag als de kandidaat; het is dus geen leeg gebruikersprofiel. Wil je meerdere eigen versies naast elkaar gebruiken, vraag de AI dan ook om aparte appnaam, bundle-id, opslagmap en sneltoets.
6. Controleer of de knoppen en het korte lijntje blauw zijn, terwijl het logo en de rode achtergrond rood blijven. Importeer een onpersoonlijk proefbeeld, voeg tekst toe, bewaar PNG, open die PNG en stop/heropen de app. Deel eventuele foutmeldingen met de AI.

De app blijft voor de Mac. Een chat kan een Mac-app niet op een Linux-server controleren; bouwen en gebruiken moet op jouw Mac gebeuren. Mac-beveiligingsmeldingen en schermopnametoestemming kunnen per installatie verschillen.

## Installeren en gebruiken

Bronuitgave voor macOS; bouw lokaal met `zsh bouw.sh` en de Apple command line developer tools. Open daarna `FMT Screenshot Editor.app`.

De app heet FMT Screenshot Editor. FMT is de maker; je export bevat standaard geen FMT-naam, -logo of website.

Kies **Eigen stijl** om optioneel een naam in beeld (maximaal 60 tekens), eigen logo (afbeelding tot 10 MB) en website (maximaal 100 tekens, zonder spaties) toe te voegen. Klik op **Bewaar stijl** om de stijl te gebruiken en te onthouden. **Annuleren** laat je vorige stijl intact. Leeg naam en website en kies **Geen logo** voor een merkloze export. Het logo wordt lokaal als PNG-kopie opgeslagen; het oorspronkelijke bestand kan daarna op een andere plek staan. Het wordt proportioneel weergegeven, in de eigen kleuren. Je eigen stijl werkt voor screenshots én tekstkaarten.

Deze kandidaat heeft een eigen app-identiteit en opslagmap, los van de eerdere FMT Screenshot-kandidaat en de persoonlijke versie. Er worden geen oude FMT-stijlkeuzes overgenomen.

Maak een screenshot met de knop of Ctrl+Option+Command+S, of kies Laad afbeelding. Kies formaat en achtergrond, pas uitsnede en tekst aan, kopieer of bewaar PNG. Verleen alleen bij schermopname de gevraagde macOS-toestemming. Gebruik de persoonlijke app en kandidaat niet tegelijk vanwege de gedeelde sneltoets.

Deze kandidaat gebruikt een vet systeemlettertype. Er worden geen fontbestanden geleverd. Code gebruikt alleen Apple-frameworks; geen account, API-sleutel of server nodig.

## Privacy
De laatste afbeelding, citaat, onderschrift, eigen stijl (naam, logo en website) en opmaak worden automatisch lokaal bewaard in `~/Library/Application Support/FMT Screenshot Editor/`. Dit kan vertrouwelijke inhoud bevatten. Stop de kandidaat en verwijder alleen die map om het geheugen te wissen. Exports blijven op de door jou gekozen plek; kopiëren gebruikt het gedeelde macOS-klembord. De bron bevat geen upload- of telemetrieroute. Tijdelijke schermopnames worden na verwerking verwijderd; bij een crash kan een tijdelijk bestand achterblijven.

## Verspreiding
Dit is een lokaal ad-hoc ondertekende proefbouw. Geen notarisation, Developer ID-release of bewezen installatie op een andere Mac. De aanwezige minimumversie in appmetadata is geen geteste compatibiliteitsgarantie. De lokale bouw maakt alleen een binary voor de architectuur van de bouwmachine.

De code en technische documentatie vallen onder MIT; zie LICENSE. De FMT-naam, het logo en afgeleide iconen vallen onder afzonderlijke MERKVOORWAARDEN.md. Voor verspreide gewijzigde versies gebruik je een eigen merk. Zie RECHTEN.md voor de afbakening. De actuele stand staat in PUBLICATIESTATUS.md; de nog uit te voeren proef in TWEEDE-MAC.md. Lokale controlebewijzen staan buiten het bronpakket in controle/. Publiceer geen volledige werkmap: controlebestanden en lokale app horen buiten het bronpakket.

## Over de maker

Erwin Blom maakt wat hij zelf nodig heeft en deelt het om anderen op gang te helpen. Open in het appmenu **Over FMT Screenshot Editor** om deze bedoeling terug te lezen.


## Appicoon behouden bij updates

De bron bevat het vaste FMT-appicoon: witte tegel, zwart uitsnedekader met bewerkpen en target rechtsboven. Bouw na een update opnieuw met bouw.sh; deze controleert de icoonbronnen en maakt het icoon altijd opnieuw. De icoonbestanden staan in Resources/FMT-tool-icon.svg/.png en FMT-tool.iconset. Neem ze allemaal mee. Dit verandert de merkloze export en Eigen stijl niet. Voor een nieuwe bronuitgave: `python3 maak-bronpakket.py <versienaam>`; release-files.txt is de expliciete bestandenlijst.
