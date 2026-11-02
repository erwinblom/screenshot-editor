# Wat is gecontroleerd?

Versie **2.0.0**, 2 november 2026. Dit bewijs hoort bij de gedeelde browserversie; de behouden Swift-app is een aparte Mac-route.

| Omgeving | Gecontroleerd |
|---|---|
| Windows Server 2025, Chrome 156.0.8078.80 | 24 controles geslaagd, inclusief klembord en direct openen van index.html. |
| Ubuntu 26.04, Chrome 156.0.8078.47 | Dezelfde 24 controles geslaagd. |
| macOS 26.6.2 ARM64, gehoste Chrome | 22 controles geslaagd, inclusief echte tabopname, PNG-export en volledige browserherstart. |
| Mac mini, macOS 27.0.1, Chrome 156.0.8078.76 | 23 controles geslaagd: dezelfde basis plus direct openen van index.html. |

Bewijs: [eerste matrix, drie platformen geslaagd](https://github.com/erwinblom/screenshot-editor/actions/runs/41519775104), [aanvullende Windows- en Linux-controles](https://github.com/erwinblom/screenshot-editor/actions/runs/41520016558). De aanvullende Mac26-job bleef in de wachtrij; daarvoor wordt geen succes geclaimd. De productcode van deze proeven is gelijk; de extra controles breiden alleen het bewijs uit.

De tests openen echte bestanden en maken echte PNG-downloads. Ze controleren afmetingen, beeldinhoud, eigen stijl, annuleren, uitsnede, exact pixelherstel na herladen en na volledig afsluiten/heropenen van Chrome, alle drie tekstkaartformaten en het wissen van werkgeheugen. De Windows/Linux-proef kopieert en plakt een echt PNG via het schone runnerklembord. Schermcapture gebruikt de echte browser-tabopname met automatische selectie van een synthetisch testtabblad; dit is geen handmatige bediening van iedere OS-keuzedialoog.

Een onafhankelijke uitvoerder doorliep daarnaast 20 gebruikscontroles en een AI-aanpasproef in een projectkopie: blauwe bedieningsknoppen, met behoud van rode PNG-uitvoer. De uiteindelijke appscreenshot en de Windows/Linux-uitvoer zijn visueel bekeken. Een agentproef is geen menselijke beginnerstest.

## Grenzen en bekende proefuitval

Een aanvullende **gehoste macOS14-proef** viel herhaalbaar uit doordat het Chrome-proces bij een PNG-download na browserherstart stopte met SIGTRAP, en met zichtbare Chrome met SIGSEGV. Zie [de laatste diagnose](https://github.com/erwinblom/screenshot-editor/actions/runs/41521364163). De precieze oorzaak is niet vastgesteld. macOS14 wordt daarom niet als geslaagd platform geclaimd; de afzonderlijke Mac-klembordproef is niet bewezen. PNG-download werkt in de hierboven geslaagde Mac-omgevingen.

Niet geclaimd: alle Linux-desktops/Wayland-combinaties, alle browser- of besturingssysteemversies, fysieke Windows-pc, native ondertekende installers of systeemwijde browsersneltoets. Chrome is getest; Edge is een bruikbare Chromium-route maar niet afzonderlijk in deze matrix getest. Voor een probleem met schermdelen blijft een bestaande screenshot laden beschikbaar. Voor de native Mac-app gelden de aparte beperkingen uit docs/NATIVE-MAC.md.
