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

- Het spel begint in vrij spel. In het park staan vijf telefooncellen met glazen ruiten, elk in een eigen kleur: blauw, groen, paars, oranje en roze. Boven elke cel zweeft een draaiende gele pijl zolang er geen ronde bezig is. De blauwe staat vlak voor de plek waar de speler begint.
- E bij een telefooncel start een ronde: zoek de kabouter in de kleur van die cel.
- Bij elke ronde verstoppen vijf kabouter-vrienden zich, één per kleur. Hun muts en pak hebben hun kleur, en hun omtrek pulseert in die kleur, alsof ze radioactief zijn. Er hangt ook een pulserend lichtje rond hen.
- Ze staan op een willekeurige plek bij een boom: minstens 80 m van de speler, minstens 30 m van elkaar en niet op een pad. Ze blijven staan.
- Ze horen je 3 keer zo ver als de bezoekers: een volle roep (45 m) bereikt hen tot 135 m ver. Wie je hoort, antwoordt "Hier!" in een grote ballon in zijn eigen kleur, 3 seconden door alles heen zichtbaar.
- Wie je gevonden hebt, loopt vanaf dan in een rijtje achter je aan. Stap je in een auto, dan gaan de gevonden kabouters op het dak staan (de kabouter heeft geen zitanimatie). Zijn telefooncel gaat dicht (geen pijl meer).
- Na de vijfde staat er "Alle vijf gevonden!". Ze blijven bij je. In de vijver verschijnt op een eilandje een reusachtige gouden kabouter van ongeveer 22 m, met rond de vijver een sokkel in elke kleur.
- Sta je bij een sokkel, dan zet O de kabouter van die kleur erop. Hij roept "Hoera!" en kijkt naar de gouden kabouter.
- Staan ze alle vijf op hun sokkel, dan spuwt de gouden kabouter onophoudelijk confetti uit zijn mond en uit zijn achterwerk: telkens een fontein plus regelmatige knallen. Er verschijnt geen melding.
- De gele pijlen boven de telefooncellen komen terug. E bij een telefooncel vraagt "Alles opnieuw beginnen?" met Yup en Nope, Nope is gekozen. Met pijl links en rechts (of A en D) kies je, met Enter bevestig je. Yup zet alles terug: vrienden naar huis, gouden kabouter en confetti weg, alle telefooncellen open.
- Kom je bij een verkeerde kabouter, dan zegt hij "Ik ben het niet!". Kom je binnen 2 m van de juiste, dan is hij gevonden: je ziet je tijd, hoe vaak je riep en hoeveel mensen je chagrijnig maakte. Enter brengt je terug naar vrij spel.
- Er is geen tijdslimiet en je kunt niet verliezen. De bezoekers worden niet teruggezet bij een nieuwe ronde.
- De HUD toont bovenaan de opdracht in de kleur van de ronde, de tijd en het aantal keer geroepen, onderaan de besturing en rechtsboven de fps.
- Code: `Game/scripts/hunt.gd` (telefooncellen, rondes en HUD) en `Game/scripts/friend.gd` (de vrienden en hun gloed). Testoptie `--found` start een blauwe ronde met de blauwe vriend naast de speler.

## Auto's

- In elke geparkeerde auto kun je instappen: sta er binnen 3,5 m van en druk op E. Met E stap je weer uit, naast de auto.
- Besturing: W gas, S remmen en achteruit, A en D sturen. Topsnelheid 90 km/u. De auto kan niet omslaan en stuurt alleen als hij rijdt.
- De auto rijdt door mensen heen. Wie voor de auto staat, springt met "Aaah!" opzij.
- Roepen wordt toeteren ("TOET!"): het werkt als roepen, maar reikt 1,5 keer zo ver.
- Code: `Game/scripts/car.gd`. Testoptie `--drive` zet de speler in de dichtstbijzijnde auto met vol gas.

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
