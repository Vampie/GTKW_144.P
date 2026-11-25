# Kabouter als spelerfiguur — gids voor de agent die hem inbouwt

Dit document hoort bij `gnome.glb`. Het beschrijft wat er in het bestand zit en hoe je het
koppelt aan de bestaande figurencode. Alles onder "Feiten" is uit het bestand zelf uitgelezen.
Alles onder "Aanpak in Godot" is advies: controleer het tegen de code en de Godot-versie van het project.

## Feiten over het bestand

- Formaat: glTF 2.0 binair (`gnome.glb`, ca. 1,4 MB). Geen losse bestanden, geen textures, geen UV's.
- 1 skelet (armature `Gnome`, 19 botten), 8 mesh-onderdelen die er allemaal aan geskind zijn:
  `Body`, `Head`, `Beard`, `Hat`, `Arm_L`, `Arm_R`, `Leg_L`, `Leg_R`. Samen ca. 30.500 driehoeken.
- 8 materialen met alleen een egale kleur: `Clay_Suit`, `Clay_Hat`, `Clay_Skin`, `Clay_White`,
  `Eye_White`, `Eye_Pupil`, `Mouth_Dark`, `Teeth`.
- Maat: 1 eenheid = 1 meter. De figuur is **1,02 m hoog** inclusief muts. Voeten staan op y = 0,
  de oorsprong ligt op de grond midden tussen de voeten.
- Richting: de figuur kijkt naar **+Z**, Y is omhoog. Links van de figuur is +X.
- Animaties: 24 fps, gesampled, per bot rotatie; alleen `Hips` en `Body` hebben ook verplaatsing.
  Het bot `Root` beweegt in geen enkele clip (geen root motion).

### Botten

```
Root
└─ Hips
   ├─ Body
   │  ├─ Head
   │  │  ├─ Hat
   │  │  ├─ Beard
   │  │  └─ Jaw
   │  ├─ UpperArm_L ─ LowerArm_L ─ Hand_L
   │  └─ UpperArm_R ─ LowerArm_R ─ Hand_R
   ├─ UpperLeg_L ─ LowerLeg_L ─ Foot_L
   └─ UpperLeg_R ─ LowerLeg_R ─ Foot_R
```

Er zijn geen vingerbotten. `Hand_L` / `Hand_R` zijn bruikbaar als bevestigingspunt voor een voorwerp.

### Animaties (33 clips)

| Naam | Duur (s) | Lus | Ter plaatse | Gebruik |
|---|---|---|---|---|
| **Bewegen** | | | | |
| `Idle` | 2,50 | ja | ja | stilstaan |
| `Walk` | 1,00 | ja | ja | wandelen |
| `Run` | 0,67 | ja | ja | lopen en rennen |
| `Sprint` | 0,50 | ja | ja | voluit spurten, sterk voorover |
| `Crouch` | 2,50 | ja | ja | gehurkt stilzitten; heup 6 cm lager |
| `CrouchWalk` | 1,00 | ja | ja | gehurkt sluipen |
| `Turn` | 0,83 | ja | ja | ter plaatse trappelen terwijl de code het lichaam draait |
| **Lucht en hindernissen** | | | | |
| `Jump` | 1,00 | ja | ja | zweefhouding zolang de figuur in de lucht is |
| `Leap` | 1,25 | nee | ja | aanloopsprong: afzetten, strekken, landen; de code geeft afstand en hoogte |
| `Fall` | 0,67 | ja | ja | lang vallen, armen en benen maaien |
| `Land` | 0,58 | nee | ja | begint diep door de knieen (landing) en veert op naar staan |
| `Climb` | 1,83 | nee | **nee** | optrekken aan een rand; eindigt 0,45 m hoger en 0,20 m verder naar voren |
| `JumpFull` | 1,50 | ja | **nee** | volledige sprong met afzet en landing; heup gaat 22 cm omhoog |
| **Vechten** | | | | |
| `Punch` | 0,67 | nee | ja | rechtse directe; raakmoment op 50 % |
| `Kick` | 0,92 | nee | ja | voorwaartse trap met rechts; raakmoment op 48 % |
| `Block` | 2,00 | ja | ja | boksverdediging, vuisten voor de kin |
| `Dodge` | 0,75 | nee | ja | wegduiken naar links en terug |
| `Hit` | 0,58 | nee | ja | klap incasseren, achterover veren |
| `KnockDown` | 1,08 | nee | ja* | achterover tegen de grond; EINDIGT LIGGEND op de rug |
| `GetUp` | 1,42 | nee | ja* | BEGINT LIGGEND, komt via zit en hurk overeind |
| `Die` | 1,67 | nee | ja* | naar de borst grijpen, door de knieen, achterover; EINDIGT LIGGEND |
| **Wapens en voorwerpen** | | | | |
| `Aim` | 2,50 | ja | ja | rechterarm gestrekt naar voren op schouderhoogte, linkerhand ondersteunt |
| `Shoot` | 0,33 | ja | ja | terugslag; begint en eindigt in de Aim-houding, mag herhaald worden |
| `Reload` | 1,67 | nee | ja | herladen; begint en eindigt in de Aim-houding |
| `Throw` | 1,00 | nee | ja | bovenhandse worp met rechts; loslaten op 54 % |
| `PickUp` | 1,08 | nee | ja | bukken en met rechts iets oprapen; laagste punt op 40-52 % |
| **Voertuigen en zitten** | | | | |
| `EnterCar` | 2,50 | nee | **nee** | portier open, instappen, zitten, portier dicht; eindigt 0,40 m naar rechts |
| `Drive` | 2,00 | ja | ja | zittend rijden, handen aan het stuur |
| `ExitCar` | 2,50 | nee | **nee** | EnterCar achterstevoren; begint in Drive-houding 0,40 m rechts, eindigt staand op de oorsprong |
| `BailOut` | 1,42 | nee | ja | begint in Drive-houding, gaat plat, rolt een keer zijwaarts om de lengteas, staat op |
| `Sit` | 2,50 | ja | ja | gewoon zitten, handen op de knieen |
| **Extra** | | | | |
| `Angry` | 2,00 | ja | ja | vuisten omhoog, stampen |
| `Shout` | 2,00 | ja | ja | roepen, mond gaat open |

\* Bij `KnockDown`, `GetUp` en `Die` schuift de heup 10 cm naar achteren en 4 cm omlaag doordat de
figuur gaat liggen; de oorsprong blijft op zijn plek. Liggend steekt het hoofd ca. 0,6 m achter de
oorsprong uit.

"Lus = nee" betekent: een keer afspelen. Tenzij anders vermeld beginnen en eindigen die clips in
de gewone staande houding, zodat ze zonder sprong aansluiten op `Idle`.

`Aim`, `Shoot`, `Reload`, `Throw` en `PickUp` bevatten geen voorwerp: er zit geen wapen of bal in
het model. Hang een voorwerp aan het bot `Hand_R`.

De namen `Idle`, `Walk`, `Run` en `Jump` zijn exact die uit de gevraagde lijst, dus de bestaande
`ANIMS`-koppeling werkt daarvoor zonder aanpassing.

**Namen die afwijken van de Quaternius-lijst:** `Punch` bestaat nu. `SitDown` en `RecieveHit` bestaan
niet onder die naam: gebruik `Sit` (een doorlopende zithouding, geen overgang van staan naar zitten)
en `Hit`. Leg die koppeling vast in de eigen tabel voor de speler.

"Ter plaatse" betekent hier: de figuur verlaat zijn plek niet. Het bovenlijf deint wel enkele
millimeters tot 3 cm, en bij `Sit` en `Drive` staat de heup lager (zie hieronder).

## Details per bijzondere clip

### Jump
Een zwevende houding zonder hoogte, bedoeld voor code die het lichaam zelf verplaatst. Speel hem
zolang de figuur los van de grond is en blend terug naar `Idle`/`Walk`/`Run` bij het landen.
Gebruik `JumpFull` **niet** samen met een fysieke sprong: dan telt de hoogte dubbel.

### Sit
De heup zakt 7,2 cm ten opzichte van staan; de voeten blijven op y = 0. De onderkant van de buik
komt op ongeveer 0,10 m. Zet de figuur dus met zijn oorsprong op de **grond voor de stoel**, niet op
het zitvlak, of trek de zithoogte van de stoel af.

### Drive
De heup zakt 6,0 cm, de voeten staan ca. 11 cm naar voren en 1,5 cm van de grond (pedalen). De handen
houden een denkbeeldig stuur vast op ca. 0,34 m hoogte, 0,20 m voor de figuur en 0,11 m links en
rechts van het midden. De clip stuurt zelf licht heen en weer; er zijn geen aparte clips voor links
en rechts sturen.

### EnterCar
Volgt het verloop van GTA: San Andreas en speelt één keer.

- **Start:** staand naast het **linkerportier** (bestuurderskant), kijkend in de rijrichting van de wagen.
- **Einde:** de heup staat **0,40 m naar rechts** van de startplek (−X in de ruimte van de figuur),
  in exact dezelfde houding als het begin van `Drive`.
- De verplaatsing zit op het bot `Hips`, niet op `Root` en niet op de node. De node zelf blijft staan.

Verloop in de tijd (fractie van de clip): 0,13 hand naar de greep · 0,26 portier open ·
0,44 bukken en rechterbeen naar binnen · 0,63 zit, linkerbeen nog buiten · 0,76 linkerhand naar het
portier · 0,88 portier dicht · 1,00 rijhouding.

Aanbevolen volgorde:
1. Zet de figuur op `stoelpositie + 0,40 m naar links van de wagen`, met dezelfde richting als de wagen.
2. Speel `EnterCar` zonder lus. Schakel botsingen en eigen beweging van de speler uit.
3. Verplaats de node bij het einde in hetzelfde frame 0,40 m naar rechts (naar de stoel), maak hem
   kind van de wagen en start `Drive` **zonder blend**. Omdat begin- en eindhouding gelijk zijn, is de
   overgang onzichtbaar. Met blend zie je de figuur kort opzij schuiven.
4. Uitstappen: speel `ExitCar`. Zet de node eerst 0,40 m naar links (terug naar de plek naast het
   portier) en start de clip zonder blend; hij begint in de `Drive`-houding en eindigt staand.

De 0,40 m en de zithoogtes zijn geschat zonder het echte automodel. Past het niet, vraag dan een
nieuwe export: in de bron zijn het drie constanten (`SEAT_SIDE`, `SIT_DROP`, `DRIVE_DROP`).
Schaal de animatie niet in de engine om het passend te krijgen.

## Aanpak in Godot (advies, controleer zelf)

- **Lussen.** De glb bevat geen lus-informatie. Zet de lus bij het importeren of in code voor alle
  clips behalve `EnterCar`. Volgens de opdracht laat de code `Walk` al herhalen; `Idle`, `Run`,
  `Jump`, `Sit` en `Drive` moeten ook lussen.
- **Schaal.** De kabouter is 1,02 m. Zijn de andere figuren mensgroot, schaal dan de node van het
  model (niet het skelet) en pas de botsvorm aan de nieuwe hoogte aan.
- **Kijkrichting.** Het model kijkt naar +Z. Ga na hoe de bestaande figuren in hun scène staan en
  geef dit model dezelfde draaiing; ga er niet van uit dat het zonder draaien klopt.
- **Eén AnimationPlayer.** Alle acht meshes delen één skelet en één set animaties. Je hoeft niets
  per mesh aan te sturen.
- **Materialen.** Egale kleuren zonder textures; ze hebben geen speciale instellingen nodig.
  De muts is een eigen mesh (`Hat`) en kan apart verborgen worden.
- **Eigen koppeling voor de speler.** Alles behalve `Idle`, `Walk`, `Run`, `Jump` en `Punch` zijn
  namen die niet in `ANIMS` staan; zet ze in een aparte tabel voor de speler.
- **Eenmalige clips.** Zet voor alle clips met "Lus = nee" de lus uit, en wacht op het einde van de
  clip voor je terugschakelt. `KnockDown` en `Die` moeten op hun laatste frame blijven staan.

## Wat getest is en wat niet

- Getest: het bestand is uitgelezen (skelet, 19 gewrichten, 33 clips, verplaatsing per clip) en een
  eerdere versie is opnieuw ingeladen in Blender 5.2.
- **Niet getest: laden en afspelen in Godot.**
- Alle clips behalve `Idle`, `Walk`, `Run`, `Angry`, `Shout` en `JumpFull` zijn alleen numeriek
  gecontroleerd (uiterste posities van handen, voeten, hoofd en heup), **niet visueel beoordeeld**.
  Verwacht dat sommige houdingen bijsturing nodig hebben en meld welke.
- Bekend: bij `BailOut` zakken de handen tijdens de rol ca. 4 cm onder de grond; bij `Leap`, `Fall`
  en `PickUp` komen de voeten 1-2 cm onder y = 0.

## Bestanden in dit pakket

| Bestand | Inhoud |
|---|---|
| `gnome.glb` | het model, dit is het enige bestand dat het spel nodig heeft |
| `AGENT_GIDS.md` | dit document |
| `LEESMIJ.txt` | korte samenvatting voor mensen |
| `viewer.html` | dubbelklikken om model en clips te bekijken (heeft internet nodig) |
| `gnome.blend` | Blender-bron (Blender 5.2) |
| `preview.png` | voor-, zij- en achteraanzicht |
