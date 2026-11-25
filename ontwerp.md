# GTKW 144.P: ontwerp

Laatst bijgewerkt: 25 november 2026.

## Idee

Een 3D-spel waarin je rondloopt in een grote omgeving en naar mensen roept. Elke persoon reageert op zijn eigen manier.

## Uitgangspunten

- Hobbyproject. Eerst komt er een speelbaar prototype. Over publiceren beslissen we later.
- Eén speler. De mensen in het spel zijn computergestuurde figuren (NPC's).
- Zandbak: de eerste versie heeft geen doel of opdracht. Een doel kan later volgen als het roepen leuk aanvoelt.
- Platform: Windows-pc. Een browserversie kan later via de webexport van Godot.

## Techniek

- Engine: Godot 4.7, met GDScript als taal.
- De map `Game/` bevat het Godot-project. Andere documenten staan in de hoofdmap.
- Doelhardware: een laptop met een geïntegreerde Intel Iris Xe. Het spel moet minstens 30 beelden per seconde halen.

## Wereld

- Low-poly stijl.
- Een stadspark van 500 × 500 m. Het kan later groeien tot ongeveer 1 km.
- Het park heeft gras, paden, bomen, bankjes en een vijver. Aan de rand liggen straten met gebouwen als decor; je kunt er niet naar binnen.
- Een script bouwt het park op. De vijver en de hoofdpaden liggen vast. Bomen, bankjes en kleine paden worden willekeurig geplaatst met een vaste seed, dus elke keer op dezelfde plek.
- Het is altijd een zonnige namiddag: geen dag/nacht en geen weer.
- Modellen komen uit gratis CC0-pakketten: personages met animaties van Quaternius, de omgeving van Kenney.

## Speler

- Third-person: de camera zweeft achter het personage en gaat niet door muren.
- Besturing met toetsenbord en muis:

| Actie | Toets |
| --- | --- |
| Lopen | WASD |
| Camera draaien | Muis |
| Rennen | Shift |
| Springen | Spatie |
| Roepen | Linkermuisknop vasthouden |

## Roepen

- Hoe langer je de linkermuisknop vasthoudt, hoe harder je roept en hoe groter het bereik.
- Terwijl je vasthoudt, toont een cirkel op de grond het bereik.
- Er is één soort roep: "Hé!".
- Later: roepen met de microfoon, waarbij het volume het bereik bepaalt.

## Mensen

- Ongeveer 30 mensen. De meesten wandelen over de paden naar willekeurige plekken. Een paar zitten op een bankje of staan in groepjes.
- Alleen wie binnen het bereik is, hoort je.
- Er zijn vier karaktertypes:

| Type | Reactie |
| --- | --- |
| Nieuwsgierig | Draait zich om, komt naar je toe en zwaait |
| Schrikachtig | Schrikt en rent weg |
| Chagrijnig | Blijft staan en roept iets terug |
| Koptelefoon | Negeert je |

- De reactie verschijnt in een tekstballon boven het hoofd. Na ongeveer 10 seconden gaan de mensen weer hun gang.

## Geluid

- De eerste versie heeft geen geluid, alleen tekstballonnen.
- Daarna komen zelf opgenomen geluiden: de eigen roep en een paar reacties, volgens een opnamelijst.
- Geen achtergrondmuziek.

## Mijlpaal 1: eerste speelbare versie

- Het park van 500 × 500 m met gras, paden, bomen, bankjes, een vijver en de rand met straten en gebouwen.
- Een speelbaar personage dat loopt, rent en springt, met de third-person camera.
- Ongeveer 30 mensen die wandelen, zitten of in groepjes staan.
- Roepen met de linkermuisknop, met de cirkel die het bereik toont.
- De vier reactietypes met tekstballonnen.
- Minstens 30 beelden per seconde op de Iris Xe.

Niet in mijlpaal 1: geluid, microfoon, doel of opdracht, menu, opslaan, dag/nacht, multiplayer en controller.

## Werkwijze

- Elke wijziging wordt gecontroleerd met automatische screenshots uit het spel. Daarna volgen een speeltest en feedback.
- Versiebeheer met git. De remote staat op GitHub.
