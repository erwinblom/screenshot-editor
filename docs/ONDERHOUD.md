# Onderhoud: vaste afspraken voor de officiële FMT-uitgave

Deze afspraken gelden voor de maker bij het uitbrengen van de officiële FMT Screenshot Editor. Wie een eigen versie maakt, volgt `AGENTS.md` in de hoofdmap en is hier niet aan gebonden.

## Vaste appiconen
Behoud de FMT-familie: witte tegel, zwart functiesymbool, canoniek target rechtsboven met rode stip. De versiebeheerbare bron staat in Resources/FMT-tool-icon.svg/.png en FMT-tool.iconset. bouw.sh controleert de bronhashes en bouwt het icoon steeds opnieuw; neem deze assets mee in ieder bronpakket. Iconen veranderen de exportstijl niet.

De goedgekeurde uniforme set van 3 november 2026 is leidend: identieke tegel- en targetgeometrie, uitsnedekader met pen. Behoud alle standaard- en Retina-maten (icp4–icp6, ic07–ic14) in de bronset en bronpakketten. Resources/FMT-tool.icns bewaart de goedgekeurde ICNS inclusief Retina-maten; Sources/icon.swift kopieert deze gecontroleerde bron ongewijzigd; teken het functiesymbool niet opnieuw.
