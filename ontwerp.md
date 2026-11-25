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
- Modellen komen uit gratis CC0-pakketten:
  - personages: Ultimate Animated Characters van Quaternius (20 figuren, met animaties zoals Idle, Walk, Run, Jump, SitDown, Punch en RecieveHit);
  - omgeving, van Kenney: Nature Kit, City Kit Roads, City Kit Suburban, City Kit Commercial, Car Kit en bankjes uit de Graveyard Kit of Holiday Kit.
- Het personagepakket heeft geen zwaai- of boosanimatie. Groeten wordt een sprongetje (`Jump`), boos zijn een stoot in de lucht (`Punch`) en schrikken `RecieveHit`. Die koppeling staat in `ANIMS` bovenaan `Game/scripts/person.gd`.

## Speler

- Third-person: de camera zweeft achter het personage en gaat niet door muren.
- Het personage is een kabouter van 1 m hoog, een eigen model in `Game/assets/characters/gnome/`. Hij heeft de animaties Idle, Walk, Run, Jump en Shout. Shout speelt na het roepen, zolang hij stilstaat.
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
- Humeur: elke keer dat iemand je hoort, ergert hij zich één punt meer. Bij drie punten wordt hij chagrijnig en zegt hij "Nu is het genoeg!".
- Per 20 seconden zonder roepen zakt de ergernis één punt. Onder één punt reageert hij weer volgens zijn eigen karakter.
- Mensen met een koptelefoon horen je niet en ergeren zich dus ook niet.

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

## Mijlpaal 2: zoek je vriend

- Ergens in het park staat een tweede kabouter met een blauwe muts. Elke ronde staat hij op een willekeurige plek bij een boom, minstens 80 m van de speler en niet op een pad. Hij blijft staan.
- Hij hoort je 3 keer zo ver als de bezoekers: een volle roep (45 m) bereikt hem tot 135 m ver.
- Hoort hij je roepen, dan antwoordt hij "Hier!" met een grote ballon die 3 seconden door alles heen zichtbaar is. Hij antwoordt altijd. Andere hulp is er niet.
- Kom je binnen 2 m van hem, dan is hij gevonden. Je ziet je tijd, hoe vaak je riep en hoeveel mensen je chagrijnig maakte. Met Enter begint een nieuwe ronde.
- Er is geen tijdslimiet en je kunt niet verliezen. De bezoekers worden niet teruggezet bij een nieuwe ronde.
- De HUD toont bovenaan de opdracht, de tijd en het aantal keer geroepen, onderaan de besturing en rechtsboven de fps.
- Code: `Game/scripts/hunt.gd` (rondes en HUD) en `Game/scripts/friend.gd` (de vriend). Testoptie `--found` zet de vriend naast de speler.

## Spelen en testen

- Open `Game/project.godot` in Godot 4.7 en druk op F5.
- Zelftest van het park: `Godot_console --headless --path Game -s res://tests/selfcheck.gd`.
- Testopties na `--` op de opdrachtregel:
  - `--top`: het hele park van bovenaf;
  - `--demo`: de speler roept vanzelf na een halve seconde;
  - `--bench`: draait de camera 10 seconden rond en toont de fps;
  - `--cam=x,y,z,tx,ty,tz`: kijkt vanaf punt x,y,z naar punt tx,ty,tz.
- De grootte en draaiing van de modellen staan als constanten bovenaan `Game/scripts/park.gd` en `Game/scripts/person.gd`.

## Werkwijze

- Elke wijziging wordt gecontroleerd met automatische screenshots uit het spel. Daarna volgen een speeltest en feedback.
- Versiebeheer met git. De remote staat op GitHub.
