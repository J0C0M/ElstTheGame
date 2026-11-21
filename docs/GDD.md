# Elst – Game Design Document

Nov 18, 2026 · @Jocom

> **Dit is het ontwerp van Prototype 1** (Fase 0 t/m 12). Voor Prototype 2 geldt `docs/PROTOTYPE_2.md`: daar is de hoofdpersoon **Gyan**, komen de Elstenaars **Jules** en **Sven** erbij, krijgt de game veel gedetailleerdere graphics en komt er bijcontent. Waar dat document afwijkt van dit GDD, geldt dat document.

## Overzicht

*Elst* is een kleine, komische open-world actie-RPG in de stijl van Skyrim, die zich afspeelt in het dorp Elst (Gelderland). De speler bevrijdt Elst van Amber de Draak door drie kwaadaardige facties te verslaan en neemt het daarna samen met Klaas op tegen Amber in de kerk.

| Onderdeel | Keuze |
| --- | --- |
| Engine | Godot 4 (laatste stabiele 4.x), GDScript |
| Genre | Third-person open-world actie-RPG, kort (3–5 uur speeltijd) |
| Platform | PC (Windows/Linux), muis + toetsenbord; controller later |
| Stijl | Low poly, platte kleuren, lichte retrofilter |
| Wereld | Eén aaneengesloten kaart van Elst van ca. 500 × 500 m, omringd door een tornado |
| Opslaan | Vrij opslaan, quicksave en autosave, net als in Skyrim |
| Inhoud | 6 hoofdquests, 4 dungeons, 4 bazen, 1 bondgenoot (Klaas) |

**Ontwerppijlers**

1. **Elst herkenbaar en grappig.** Echte plekken uit Elst, overdreven vijanden en droge humor.
2. **Klein maar af.** Liever één compact dorp dat helemaal af is dan een grote, lege wereld.
3. **Vrijheid zoals in Skyrim.** De drie facties mogen in elke volgorde. De wereld verandert zichtbaar als een gebied bevrijd is.
4. **Simpele, strakke combat.** Zwaard, blokkeren, ontwijken en later de kruisboog. Geen magie voor de speler.

## Verhaal & lore

Amber de Draak heeft Elst overgenomen en Klaas moet de speler helpen haar macht te breken.

**Voor de game.** Elst was een vredig dorp. Klaas regeerde er min of meer: iedereen kende hem en hij beschermde het dorp. Op een dag kwam Amber de Draak met haar leger van drillers uit Arnhem-Zuid. Dat was te veel voor Klaas. Amber nam Elst over en Klaas moest onderduiken in zijn eigen huis. Alle vredige dorpelingen verdwenen. Sinds Ambers komst draait er een gigantische tornado om Elst heen, zodat niemand erin of eruit kan.

**Waar Amber vandaan komt.** Amber komt uit Zevenaar. Dat was het eerste wat ze veroverde. Pas daarna trok ze naar Arnhem en Arnhem-Zuid, en vandaar naar Elst. De Zevenaarders die bij haar bleven, zijn haar sindsdien trouw: de Amber-cultisten (drillers in een pufferjack onder een amberkleurig gewaad, met vuurvapes) en de drillers op de draakjes. Ze zijn zo diep met Amber verbonden dat ze bij haar blijven, in de kerk. Daarom kom je ze nergens anders tegen.

**Tijdens de game.** De speler is een niemand die in Elst terechtkomt. Klaas neemt de speler onder zijn hoede. Om Amber te verzwakken moet de speler eerst haar aanvoerlijn kapotmaken (Station Elst) en daarna de drie facties verslaan die Elst voor haar bezetten. Elke bevrijde wijk loopt weer vol met blije dorpelingen.

**De Bingo Club.** Grumpy Oma is de nummer 1 bingowinnaar van Elst en een trouwe volger van Amber. Omdat niemand vaker BINGO riep dan zij, zien de oma's en opa's van de Bingo Club haar als hun leider, bijna als een messias. Onder haar is de gezellige bingoclub een grot geworden, de Boomer Cave.

**Einde.** Als de drie facties verslagen zijn, gaan de deuren van de kerk open. Daar vechten de speler en Klaas tegen Amber. Halverwege offert Klaas zich op om de speler te redden van een fatale aanval. Als Amber verslagen is, laat ze de gouden Tren-spuit vallen. Daarmee wekt de speler Klaas weer tot leven. De tornado verdwijnt en Elst is gered.

## Personages

| Personage | Rol | Uiterlijk (low poly) | Gedrag |
| --- | --- | --- | --- |
| De speler | Hoofdpersoon, een niemand | Simpele, neutrale figuur. Uitrusting is zichtbaar op het model | Kan geen magie. Gebruikt alleen een zwaard en later de kruisboog |
| Klaas | Mentor, questgever, winkelier, bondgenoot in het eindgevecht | Lang, breed en gespierd, blond haar, strakke kaak, zonnebril (die gaat nooit af) | Zelfverzekerd, kort van stof, droog grappig. Is trots op de speler als die een dungeon eerder afmaakt dan gevraagd |
| Amber de Draak | Eindbaas, heerser over Elst | Grote low-poly draak met amberkleurige schubben en gloeiende ogen | Hooghartig en boos. Spreekt de speler via de tornado af en toe toe |
| Dorpelingen | Sfeer, beloning na een bevrijde wijk | Simpele, vrolijke figuren met variatie in kleur en hoed | Lopen rond, zwaaien en zeggen korte zinnetjes |

**Klaas in detail**

- Woont in zijn huis (paars op de kaart). Dat huis is de hub: quests ophalen, winkel, opslaan en slapen.
- Zijn relatie met de speler loopt via de **Inwijding** (zie Quests, Inwijding & progressie).
- In Quest 6 vecht hij mee als door de AI bestuurde bondgenoot. Hij kan niet doodgaan door gewone schade, alleen in de geschreven scène.
- Referentiefoto: `Klaas_sigma.png`, aangeleverd door de eigenaar. Hij staat lokaal in `docs/reference/` en niet in de openbare repo, omdat het een foto van een echt persoon is.

## Wereld & kaart van Elst

De wereld is één compacte kaart van Elst. De kerk staat in het midden en vijf andere kernlocaties liggen eromheen. Bij de indeling volgen we de kaart die de eigenaar heeft aangeleverd (`kaart_elst.png`, lokaal in `docs/reference/`). `tools/map/gen_elst.py` bouwt de wereld daaruit.

| Kleur op kaart | Locatie | Functie | Bewoners voor bevrijding | Na bevrijding |
| --- | --- | --- | --- | --- |
| Paars | Huis van Klaas | Hub: quests, winkel, opslaan | Klaas | Dorpelingen rond het huis na Quest 1 |
| Groen | Elst Station + gebouw ernaast | Dungeon Quest 2 (geen baas) | Driller army | Station werkt weer, dorpelingen op het perron |
| Geel | Westeraam Getho | Dungeon Quest 3 | Driller army, vape-drillers | Dorpelingen in de wijk |
| Rood | OBC Elst Fort | Dungeon Quest 4 | Kakker-voetbaljongens, fatbikers | Dorpelingen op het plein |
| Blauw | Bingo Club Boomer Cave | Dungeon Quest 5 | Bingo-opa's, boze oma's, rolstoel-oma's | Een vrolijke bingoavond |
| Roze | De Kerk van Amber (centrum) | Dungeon en eindgevecht Quest 6 | Vijanden van alle facties, Amber (binnen) | Kerk wordt een feestplek |

**Opbouw van de wereld**

- **Buiten:** straten, huizen, weilanden, de spoorlijn en wat herkenbare Elster details. Alles bestaat uit low-poly blokken.
- **Dungeons:** elke dungeon is een aparte scene (een interieur). Je gaat erin via een deur of ingang in de open wereld. Laden gebeurt met een korte overgang.
- **Factie-dungeons** (Westeraam Getho, OBC Elst Fort, Bingo Club Boomer Cave) zijn groter dan Station Elst en hebben twee delen: eerst het eerste gedeelte, dan een checkpoint binnen in de dungeon (een rustige ruimte met een autosave en een bank om uit te rusten), en daarna het tweede gedeelte met de baas.
- **De Kerk van Amber** is de laatste en zwaarste dungeon. Hij gaat van boven naar beneden:
  1. **Boven, in het kerkgebouw:** je begint in de kerk zelf. Het interieur is dat van een echte kerk: een middenpad met kerkbanken, een altaar, een preekstoel, een orgel en glas-in-loodramen, met Ambers kleuren (amber en oranje).
  2. **Ondergronds:** via een trap ga je naar beneden, een gangenstelsel in. Met nog meer trappen ga je steeds dieper onder de grond. Onderweg zijn er een paar doodlopende kamers.
  3. **Vijanden:** door de hele dungeon kom je de vijanden van alle andere dungeons door elkaar tegen: laag drillers, drillers, vape-drillers, kakker-voetbaljongens, fatbikers, bingo-opa's, boze oma's en rolstoel-oma's. Ze zijn even sterk als in hun eigen dungeon.
  4. **Klaas bij de arena:** aan het einde van de gangen staat Klaas voor de ingang van de baasarena. Je kunt hier nog één keer met hem praten en spullen kopen en verkopen. Hier is ook een checkpoint met autosave.
  5. **De baasarena:** een enorme ronde ruimte met 5 lange pilaren, die dekking geven tegen Ambers vuuradem en vuurballen. Hier vecht je tegen Amber de Draak. Klaas vecht de eerste helft mee, tot hij sneuvelt (zie *Amber, het verloop*); de tweede helft doe je alleen.
- **Vijanden buiten:** rond elke factielocatie zwerven patrouilles van die factie. Na het verslaan van de dungeon spawnen ze daar niet meer.
- **Verslagen dungeons:** is de baas verslagen (of in Station Elst de laatste generator), dan blijft de dungeon leeg: de vijanden komen niet terug, ook niet na opnieuw laden. Ga je eruit en weer naar binnen, dan lopen er een paar inwoners rond, net als buiten in een bevrijd gebied.
- **Wereldstaat:** per gebied wordt bijgehouden of het bezet of bevrijd is. Een bevrijd gebied krijgt dorpelingen, andere muziek en een warmere kleur.

**De tornado-grens**

- Een ring van draaiende wind, stof en rondvliegend puin rond de kaart. Je ziet hem vanaf overal in Elst.
- Loopt de speler ertegenaan, dan duwt de wind hem terug. Er verschijnt een melding als “De tornado is te sterk. Je kunt Elst niet ontsnappen.”
- Na de dood van Amber lost de tornado in een korte scène op. Daarna is de lucht helder.

## Gameplay, combat & besturing

De speler loopt in third person door Elst en vecht van dichtbij met het zwaard. Na Quest 5 kan hij ook van afstand vechten met de kruisboog.

**Speler-stats**

| Stat | Startwaarde | Werking |
| --- | --- | --- |
| Levens (HP) | 100 | Bij 0 ga je dood en laad je de laatste save |
| Stamina | 100 | Kost iets bij sprinten, zware aanval, ontwijken en blokkeren. Laadt na 1 s weer op |
| Goud | 0 | Om uitrusting en drankjes bij Klaas te kopen |
| Inwijding | 0 | Band met Klaas (0–6). Speelt nieuwe winkelspullen vrij |

**Combat**

- **Lichte aanval:** snelle zwaardslag. Twee keer achter elkaar geeft een combo.
- **Zware aanval:** ingedrukt houden, langzamer, ×1,8 schade, kost 25 stamina.
- **Blokkeren:** 70% minder schade van voren. Precies op tijd blokkeren (parry, 0,2 s) zet de vijand kort uit balans.
- **Ontwijken:** rol met korte onkwetsbaarheid (0,3 s), kost 20 stamina.
- **Kruisboog (na Quest 5):** richten met de rechtermuisknop, schieten met de linker. Een pijl doet 30 schade en herladen duurt 0,9 s. Elke pijl is op: je krijgt er 15 bij de kruisboog en draagt er hooguit 30. Meer koop je bij Klaas (5 voor 15 goud) of vind je bij vijanden en in kisten. Handig tegen Amber als ze vliegt.
- **Healing potion:** snel gebruiken met een sneltoets, met een korte animatie waarin je kwetsbaar bent.
- **Vijanden** tonen een levensbalk boven hun hoofd. Bazen hebben een grote balk onderin beeld.

**Besturing (muis + toetsenbord)**

| Actie | Toets |
| --- | --- |
| Lopen / sprinten | WASD / Shift |
| Camera | Muis |
| Springen | Spatie |
| Ontwijken | Alt (of dubbel tikken op een richting) |
| Lichte / zware aanval | Linkermuisknop (tik / ingedrukt) |
| Blokkeren / richten | Rechtermuisknop |
| Interactie (praten, deur, kist) | E |
| Wapen wisselen | 1 = zwaard, 2 = kruisboog |
| Healing potion | Q |
| Inventaris / questlog | Tab / J |
| Quicksave / quickload | F5 / F9 |
| Pauzemenu | Esc |
| Dev powers aan/uit (alleen in debug builds, voor het testen) | ` (vliegen: Spatie omhoog, Ctrl omlaag) |

Doodgaan stuurt je terug naar het laatste save- of autosavemoment.

## Facties, vijanden & bazen

Elke factie heeft eigen vijanden, een eigen dungeon en een eindbaas met één duidelijk te leren aanvalspatroon. Station Elst heeft vijanden, maar geen baas. De waarden hieronder zijn startwaarden die we tijdens het testen bijstellen.

**Gewone vijanden**

| Vijand | Factie / plek | HP | Schade | Gedrag |
| --- | --- | --- | --- | --- |
| Laag driller | Station Elst | 20 | 6 | Zwakke melee, valt aan in groepjes van 2–3 |
| Driller | Westeraam Getho | 58 | 8 | Puffer jacket, gezicht zichtbaar. Melee, flankeert de speler |
| Vape-driller (mage) | Westeraam Getho | 30 | 10 | Puffer jacket met capuchon, geen gezicht te zien. Houdt afstand en schiet langzame vape-wolkjes die even blijven hangen |
| Kakker-voetbaljongen | OBC Elst Fort | 35 | 8 | Schiet voetballen, 60% kans om raak te schieten. Houdt afstand |
| Fatbiker | OBC Elst Fort | 60 | 15 | Rijdt op een fatbike alsof het een paard is. Cirkelt rond en chargeert |
| Bingo-opa | Bingo Club Boomer Cave | 35 | 6 | De simpele vijand: een oude, wijze opa die bingofeitjes en bingonummers roept, op je af rent en je met zijn wandelstok slaat |
| Boze oma | Bingo Club Boomer Cave | 45 | 10 | Springt van ver met een lange sprong op je af en slaat je dan met haar paarse leren tasje. Sla je haar te lang niet, dan springt ze weer weg en wacht ze even voordat ze opnieuw aanvalt |
| Rolstoel-oma | Bingo Club Boomer Cave | 50 | 7 per kaart | Heel sloom in haar rolstoel. Schiet als een kanon salvo's van 3 bingokaarten op je af en rolt bij elk schot een stukje achteruit |

**Bazen**

| Baas | Dungeon | HP | Aanvallen | Zwakke plek / kans voor de speler |
| --- | --- | --- | --- | --- |
| De Vape-koning (rijkste vapeverkoper van Westeraam) | Westeraam Getho | 400 | Verstopt zich in één van 4 vape-wolken en schiet daaruit dodelijke vape-wolkjes (15 schade). Onder 50% schiet hij er 3 tegelijk | Ren naar zijn wolk. Hij is dan 4 s kwetsbaar en vlucht daarna naar een andere wolk |
| Het fatbike-kindje (erg klein, wit, met blauwe ogen, op een veel te grote opgevoerde fatbike) | OBC Elst Fort | 450 | Chargeert in een rechte lijn. Je ziet het aankomen aan een gierende motor en een lijn op de grond. Onder 50% chargeert hij 2 keer achter elkaar | Ontwijk de charge. Knalt hij tegen een muur, dan staat hij 3 s versuft |
| Grumpy Oma (nummer 1 bingowinnaar, trouwe volger van Amber, de messias van de Bingo Club; een enorme, gespierde oma die eruitziet als een woest beest) | Bingo Club Boomer Cave | 650 | Sjokt op je af en geeft een trage, goed zichtbare klap met haar handtas, vaak gevolgd door een snelle tweede, daarna moet ze even op adem komen. Blijf je buiten haar bereik, dan gooit ze een waaier bingokaarten. Springt en ground slamt (schokgolf, spring eroverheen) en draait als een tornado door de arena (dan kun je haar niet raken). Op 2/3 en 1/3 van haar HP roept ze “BINGO!” en komen haar volgelingen helpen; die worden woest. Onder 30% wordt ze sneller en slamt ze twee keer achter elkaar | Na een ground slam en na de tornado staat ze 1,8 s uitgeput en krijgt ze 35% extra schade. Pareer je haar klap, dan raakt ze ook uitgeput |
| Amber de Draak | De Kerk van Amber | 2 × 1050 | Houdt afstand en cirkelt om je heen. Fase 1: vuuradem in een kegel (een rode waaier op de grond waarschuwt, met een schaduw achter elke pilaar), staartzwiep, vleugelwind die je wegduwt, opvliegen met een regen van vuurballen. Raak je haar een paar keer snel achter elkaar, dan rent ze brullend een rondje langs de muur. Fase 2: woedend en sneller, zwaait haar vuur, stampt ringen van vuur over de vloer (spring eroverheen), laat brandende plekken achter en roept cultisten uit Zevenaar op | Raak haar met de kruisboog als ze vliegt, dan stort ze neer. Op de grond is haar kop kwetsbaar na een vuuradem |

**Amber, het verloop**

1. **Levensbalk 1:** Klaas vecht mee en trekt een deel van haar aandacht naar zich toe.
2. **Overgang:** als balk 1 leeg is, zet Amber een fatale aanval op de speler in. Klaas duwt de speler weg, wordt geraakt en sterft (korte scène, tekst en camera).
3. **Levensbalk 2:** de speler vecht alleen. Amber is in deze fase woedend.
4. **Einde:** Amber valt. De gouden Tren-spuit valt op de grond. De speler gebruikt hem op Klaas, die weer tot leven komt. Daarna verdwijnt de tornado en volgt de eindscène.

## Quests, Inwijding & progressie

De game heeft 6 hoofdquests die Klaas één voor één geeft. De drie factie-dungeons (Quest 3–5) mag de speler in elke volgorde doen. Sidequests kunnen later worden toegevoegd.

| # | Quest | Locatie | Doel | Beloning |
| --- | --- | --- | --- | --- |
| 1 | Inleiding & tutorial | Huis van Klaas + omgeving | Klaas legt lore en besturing uit: lopen, aanvallen, blokkeren, ontwijken, potions, winkel, opslaan. Eindigt met een oefengevecht tegen 2 laag drillers | Roestig zwaard, 2 kleine potions, 20 goud, Inwijding 1 |
| 2 | De aanvoer van Elst kapotmaken | Elst Station + het gebouw ernaast | Vecht je door de station-dungeon en sla de 4 generators voor trein en spoor kapot. Geen baas, wel een zwaarbewaakte laatste ruimte | 75 goud, Inwijding 2. Vijanden van Westeraam en OBC krijgen 20% minder HP |
| 3 | Westeraam Getho | Westeraam Getho | Versla de vijanden en de Vape-koning | 150 goud, kans op loot, Inwijding +1 |
| 4 | OBC Elst Fort | OBC Elst Fort | Versla de vijanden en het fatbike-kindje | 150 goud, kans op loot, Inwijding +1 |
| 5 | Bingo Club Boomer Cave | Bingo Club Boomer Cave | Versla de vijanden en Grumpy Oma | 150 goud, kans op loot, Inwijding +1 |
| 6 | Versla Amber de Draak | De Kerk van Amber | Vecht je vanuit de kerk door de gangen eronder naar beneden, praat met Klaas bij de arena en versla Amber samen met hem | Gouden Tren-spuit, einde van de game |

**Regels voor de volgorde**

- **Moeilijkheid:** de factie-dungeons worden steeds iets zwaarder: eerst Westeraam Getho, dan OBC Elst Fort (iets sterker) en als zwaarste de Bingo Club Boomer Cave. Dat geldt ook als de speler een andere volgorde kiest. Zwaarder betekent meer vijanden, iets meer HP en schade, en een sterkere baas. Vroege vijanden (station, Westeraam) waarschuwen alleen hun buren vlakbij; in het OBC en de Bingo Club gaat de waarschuwing door de hele kamer. Ook kijken bij de start meer vijanden naar de deur waardoor de speler binnenkomt: in Station Elst kijken ze een willekeurige kant op, in de Bingo Club kijken bijna alle vijanden naar je.
- Klaas geeft de quests in volgorde 1 t/m 6. Station Elst is vanaf het begin open. De drie factie-dungeons gaan pas open als Station Elst gesloopt is; Klaas zegt dat als hij Quest 2 geeft. De kerk zit op slot tot de drie factiebazen verslagen zijn.
- Maak je een factie-dungeon af voordat Klaas die quest gegeven heeft, dan telt hij toch. Bij je volgende bezoek is Klaas trots op je (eigen tekstregel) en wordt de quest afgestreept. Je krijgt de beloning dan alsnog.
- **Kruisboog:** krijg je van Klaas zodra Quest 2 t/m 5 allemaal af zijn.
- **Kerkdeuren:** gaan open zodra de drie factiebazen verslagen zijn. Quest 6 wordt dan actief.

**Inwijding (band met Klaas): +1 per afgeronde hoofdquest, in elke volgorde**

| Niveau | Hoe | Wat het vrijspeelt |
| --- | --- | --- |
| 0 | Start | Alleen gesprekken |
| 1 | Quest 1 af | Winkel open: kleine potion, ijzeren zwaard, leren pantser |
| 2 | 2 quests af | Grote potion |
| 3 | 3 quests af | Stalen zwaard, ijzeren pantser |
| 4 | 4 quests af | Stalen pantser |
| 5 | Quest 1 t/m 5 af | Kruisboog, Klaas' zwaard |
| 6 | Amber verslagen | Eindscène: Klaas noemt je een echte Elstenaar |

In het questlog (J) staan actieve en afgeronde quests, het huidige doel en een markering op het kompas bovenin beeld.

## Economie, loot, uitrusting & Klaas' winkel

Goud komt uit vijanden, kisten en questbeloningen. In de dungeons heb je een kleine kans op een beter zwaard of pantser. Wie pech heeft, koopt het bij Klaas.

**Goud en loot**

- Gewone vijand: 3–10 goud. Kist in een dungeon: 20–40 goud. Baas: 100 goud plus de questbeloning.
- Kans op uitrusting: kist 8%, baas 35%. De kans geldt voor het volgende item dat je nog niet hebt, dus je vindt nooit iets slechters.
- Vijanden laten soms een kleine potion vallen (5%).

**Uitrusting**

| Item | Type | Waarde | Prijs bij Klaas | Vrij vanaf Inwijding |
| --- | --- | --- | --- | --- |
| Roestig zwaard | Zwaard | 10 schade | Start | – |
| IJzeren zwaard | Zwaard | 16 schade | 80 goud | 1 |
| Stalen zwaard | Zwaard | 24 schade | 200 goud | 3 |
| Klaas' zwaard | Zwaard | 34 schade | 400 goud | 5 |
| Gewone kleding | Pantser | 0% minder schade | Start | – |
| Leren pantser | Pantser | 15% minder schade | 70 goud | 1 |
| IJzeren pantser | Pantser | 30% minder schade | 180 goud | 3 |
| Stalen pantser | Pantser | 45% minder schade | 350 goud | 4 |
| Kleine healing potion | Verbruik | +40 HP | 20 goud | 1 |
| Grote healing potion | Verbruik | +100 HP | 50 goud | 2 |
| Kruisboog | Wapen | 30 schade per pijl | Beloning, niet te koop | 5 |
| Kruisboogpijlen (5) | Munitie | Maximaal 30 mee | 15 goud | 5 |

**Inventaris**

- Eén zwaardslot, één pantserslot en één kruisboogslot. Een betere vondst wordt automatisch aangetrokken (met een melding).
- Je kunt maximaal 10 potions meenemen.
- Oude uitrusting verkoop je aan Klaas voor 40% van de prijs.

## Opslaan, quicksave & laden

Zoals in Skyrim kan de speler bijna overal opslaan: handmatig, met een quicksave of via een autosave.

| Soort | Hoe | Slots | Wanneer niet |
| --- | --- | --- | --- |
| Handmatig opslaan | Pauzemenu → Opslaan | Onbeperkt, met een naam | Tijdens een baasgevecht, scène of val |
| Quicksave | F5 | 1 slot, wordt overschreven | Tijdens een baasgevecht, scène of val |
| Quickload | F9 | Laadt de quicksave | – |
| Autosave | Automatisch: bij het betreden van een dungeon, na een afgerond questdoel en bij slapen bij Klaas | 3 slots, het oudste wordt overschreven | – |

**Wat er in een save zit**

- Speler: positie, rotatie, HP, stamina, goud, inventaris, uitrusting, Inwijding.
- Quests: status per quest (niet gestart, actief, af) en de stap binnen de quest.
- Wereld: welke gebieden bevrijd zijn, welke kisten open zijn, welke generators kapot zijn en of de kerk open is.
- Huidige scene (open wereld of welke dungeon) en de speeltijd.
- Metadata: versienummer van het save-formaat, datum en tijd, locatienaam en een kleine screenshot voor het laadmenu.

**Techniek in het kort:** JSON-bestanden in `user://saves/`. Elke node die iets moet onthouden zit in de groep `persist` en heeft `save_data()` en `load_data()`. Een versieveld maakt het mogelijk om oude saves later om te zetten. Vijanden in dungeons spawnen opnieuw bij het laden, maar verslagen bazen en bevrijde gebieden blijven bewaard.

## Visuele stijl, retrofilter & audio

Alles is low poly met platte kleuren. Een lichte retrofilter geeft het geheel een PS1/N64-sfeer zonder dat het onleesbaar wordt.

**Modellen**

- Personages en gebouwen worden gebouwd uit simpele vormen (box, capsule, cilinder, prisma) met vlakke kleuren en `flat shading`. Er zijn geen texturen nodig.
- Elk personage bestaat uit losse delen (hoofd, romp, armen, benen) die met eenvoudige animaties bewegen (`AnimationPlayer`, of in code).
- Later kunnen de placeholdermodellen vervangen worden door modellen uit Blender of CC0-packs (bijvoorbeeld Kenney), zonder iets aan de gameplaycode te veranderen.
- Kleuren per factie: Westeraam geel/zwart, OBC rood/navy, Bingo blauw/pastel, Amber amber/oranje, Klaas paars/goud.

**Retrofilter (licht)**

- De 3D-wereld wordt intern op lage resolutie gerenderd (640 × 360) en daarna scherp opgeschaald (nearest).
- Lichte kleurkwantisatie (ongeveer 32 tinten per kanaal) met subtiele ordered dithering.
- Een zachte vignette en heel lichte filmruis. Geen zware scanlines.
- Mist op afstand, waardoor de tornado mooi in de verte opgaat.
- In de instellingen kun je de filter aan- en uitzetten en de pixelgrootte kiezen (laag, midden, uit). De HUD wordt op volle resolutie getekend, zodat tekst scherp blijft.

**Audio**

- Eenvoudige placeholdergeluiden: zwaardslag, treffer, blokkeren, voetstappen, de tornado als achtergrondgeluid.
- Muziek per toestand: rustig dorp, bezet gebied, dungeon, baasgevecht en het einde.
- Alleen CC0-audio of zelfgemaakte audio, met de bron vermeld in `CREDITS.md`.

## Technisch ontwerp in Godot

De game wordt gebouwd in Godot 4 met GDScript met statische types. Een paar autoloads houden de globale toestand bij en signals koppelen de systemen los van elkaar.

**Mappenstructuur**

```
res://
  autoload/        GameState, SaveManager, QuestManager, EventBus, AudioManager
  scenes/
    main/          Main.tscn (scenewissels, overgangen), MainMenu, PauseMenu
    world/         Elst.tscn (open wereld), Tornado, gebieden per factie
    dungeons/      Station, Westeraam, OBC, BingoCave, Kerk
    player/        Player.tscn, camera, wapens
    npcs/          Klaas, Dorpeling
    enemies/       basis-vijand + varianten per factie
    bosses/        VapeKoning, FatbikeKindje, GrumpyOma, Amber
    ui/            HUD, Inventaris, Questlog, Winkel, Dialoog, Laadmenu
  scripts/
    components/    HealthComponent, Hitbox, Hurtbox, StateMachine, LootDropper
    data/          Resources: ItemData, EnemyData, QuestData, DialogueData
  data/            .tres-bestanden voor items, vijanden, quests en dialogen
  shaders/         retro_post.gdshader
  assets/          modellen, audio, fonts
docs/              GDD.md, reference/ (kaart_elst.png, Klaas_sigma.png)
tests/             headless tests
```

**Kernsystemen**

| Systeem | Verantwoordelijk voor |
| --- | --- |
| `EventBus` | Globale signals, zoals `enemy_killed`, `boss_defeated`, `quest_updated`, `area_liberated` |
| `GameState` | Goud, Inwijding, bevrijde gebieden, kerk open of dicht, vlaggen |
| `QuestManager` | Quests laden uit `QuestData`, stappen bijhouden, regels voor eerder afgemaakte dungeons |
| `SaveManager` | Opslaan, quicksave, autosave en laden via de groep `persist`. Versie van het save-formaat |
| Componenten | HP, schade (hitbox/hurtbox), loot, state machine voor de AI |
| Vijand-AI | State machine: idle → patrouille → achtervolgen → aanvallen → terugtrekken. Navigatie met `NavigationAgent3D` |
| Baas-AI | Eigen state machine per baas met fases op basis van HP-drempels |
| Dialoog | Simpele dialoogboom uit `DialogueData` met voorwaarden (quest-status, Inwijding) |
| Retrofilter | `SubViewport` op lage resolutie plus een post-process shader. De HUD staat erbuiten |

**Afspraken**

- Gameplaywaarden (HP, schade, prijzen) staan in `.tres`-resources en niet hard in de code, zodat je ze makkelijk kunt bijstellen.
- Collision layers krijgen een vaste naam in de projectinstellingen: wereld, speler, vijand, hitbox, interactie.
- Inputacties staan in de InputMap (`attack`, `block`, `dodge`, `interact`, `quicksave`, …) en niet als vaste toetsen in de code.
- Elke fase moet na afloop starten zonder fouten in de console.
- **Dev powers** (alleen in debug builds, niet opgeslagen): met `` ` `` wordt de speler onkwetsbaar, kan de speler vliegen en drie keer zo snel lopen, en doodt elke treffer meteen. Bedoeld om snel door de game te testen.

## Ontwikkelfases

Het project wordt in 13 fases gebouwd. Na elke fase moet de game speelbaar zijn. Elke fase is één request aan Claude Code, met een eigen branch vanaf `Development`. Binnen een fase komt er een commit per afgerond onderdeel.

0. **Fundament** — branch `Setup-Project-Foundation`
   - Godot-project, mappenstructuur, lege autoloads, InputMap, collision layers, `.gitignore`, `README.md`, `CLAUDE.md`, `docs/GDD.md`.
   - Retrofilter (SubViewport + shader) en een testscene met een paar blokken.
   - Klaar als: het project start zonder fouten en de filter werkt en is uit te zetten.
1. **Speler & combat** — `Add-Player-Controller-And-Combat`
   - Third-person speler, camera, lopen, sprinten, springen, ontwijken, zwaardcombo, zware aanval, blokkeren en parry.
   - HP, stamina, een HUD met balken en een testarena met een trainingspop.
   - Klaar als: je de pop kunt slaan en kapotmaken en de stamina klopt.
2. **Wereld van Elst (blockout)** — `Build-Elst-World-Blockout`
   - Open wereld volgens de kaart: 6 kernlocaties, straten, spoor, kerk in het midden.
   - Tornado-grens, mist, licht, navigatiemesh en dungeoningangen met een scenewissel en een overgang.
   - Klaar als: je overal kunt lopen, de tornado je tegenhoudt en je in en uit een lege dungeon kunt.
3. **Opslaan & menu's** — `Add-Save-System`
   - SaveManager, quicksave (F5) en quickload (F9), autosave, opslaan- en laadmenu.
   - Hoofdmenu, pauzemenu, instellingen (filter, gevoeligheid, volume).
   - Klaar als: positie, HP en scene na opslaan en laden precies terugkomen.
4. **Vijanden & loot** — `Add-Enemy-AI-And-Loot`
   - Basisvijand met state machine en navigatie, laag driller en driller als eerste varianten.
   - Goud, loot-drops, kisten, doodgaan en herladen.
   - Klaar als: vijanden patrouilleren, aanvallen, sterven en goud laten vallen.
5. **Klaas, dialoog & winkel** — `Add-Klaas-Dialogue-And-Shop`
   - Klaas-model, zijn huis, dialoogsysteem, winkel, inventaris en uitrusting, potions, Inwijding.
   - Klaar als: je met Klaas praat, iets koopt en het aantrekt, en dat zichtbaar is.
6. **Questsysteem & Quest 1** — `Add-Quest-System-And-Tutorial`
   - QuestManager, questlog, kompasmarkering, de tutorialquest met uitleg en oefengevecht.
   - Klaar als: Quest 1 van begin tot eind speelbaar is en in de save blijft.
7. **Quest 2: Station Elst** — `Add-Station-Dungeon`
   - Station-dungeon, 4 generators, een zwaarbewaakte laatste ruimte en het verzwakkingseffect.
8. **Quest 3: Westeraam Getho** — `Add-Westeraam-Dungeon`
   - Dungeon, vape-drillers, de Vape-koning en het systeem voor bevrijde gebieden (dorpelingen, geen spawns meer).
9. **Quest 4: OBC Elst Fort** — `Add-OBC-Fort-Dungeon`
   - Dungeon, voetbaljongens, fatbikers en het fatbike-kindje.
10. **Quest 5: Bingo Club Boomer Cave** — `Add-Bingo-Cave-Dungeon`
    - Dungeon, bingo-opa's, boze oma's, rolstoel-oma's, Grumpy Oma en de kruisboog als beloning.
    - Klaar als: alle drie de dungeons na Station Elst in elke volgorde te doen zijn, ook voordat Klaas ze geeft.
11. **Quest 6: Amber de Draak** — `Add-Amber-Final-Battle`
    - Kerkdeuren, de kerk-dungeon (boven in het kerkgebouw, dan trappen en gangen ondergronds met doodlopende kamers, vijanden van alle facties door elkaar), Klaas voor de arena (praten, winkel), de ronde arena met 5 pilaren, Klaas als bondgenoot, Amber met 2 levensbalken, de scène met Klaas, de gouden Tren-spuit, de tornado die verdwijnt, de eindscène en credits.
12. **Afwerking & build** — `Polish-And-Release-Build`
    - Audio, balans, bugfixes, laadschermen, export presets voor Windows en Linux.
    - Klaar als: de game van begin tot eind uit te spelen is zonder blokkerende bugs.

## Aannames & open punten

Keuzes waar de idee-notitie niets zei of zichzelf tegensprak, met het besluit van de eigenaar (20-11-2026).

**Aannames (bevestigd door de eigenaar)**

- Quest 5 in de notitie zegt “Je valt OBC Elst Fort Dungeon aan”. Dit moet Bingo Club Boomer Cave zijn.
- De kerk gaat open na de drie factiebazen. Daarvoor is Station Elst ook nodig, want zonder het station gaan de factie-dungeons niet open.
- Station Elst slopen maakt de vijanden van Westeraam en OBC zwakker (20% minder HP). Zo heeft Quest 2 ook een effect in het spel.
- Station Elst is vanaf het begin open, de factie-dungeons na het station en de kerk na de drie factiebazen.
- In de kerk zijn de vijanden hetzelfde als in hun eigen dungeon, ook wat sterkte betreft: wie door het station verzwakt was, blijft dat.
- Bij Klaas voor de arena is ook een checkpoint met autosave, zodat je na doodgaan in het baasgevecht daar terugkomt.
- Na de eindscène mag de speler vrij door het bevrijde Elst blijven lopen.
- Alle getallen (HP, schade, prijzen, kansen) zijn startwaarden voor het testen. Ze staan in de `.tres`-bestanden; waar we van dit document afwijken, staat dat in `docs/PROGRESS.md`.
- **Scènes in Prototype 1** (Klaas die sneuvelt, de tornado die verdwijnt, de eindscène) zijn eenvoudig, met tekst en camera, maar wel compleet. Na de grafische overhaul van Prototype 2 maken we ze opnieuw.

**Besloten open punten**

- [x] `kaart_elst.png` en `Klaas_sigma.png` zijn aangeleverd door de eigenaar en staan lokaal in `docs/reference/`.
- [x] De 5 pilaren in de arena geven dekking tegen Ambers vuuradem en vuurballen.
- [x] Geen controller in Prototype 1; die komt in een later prototype.
- [x] Geen stemmen. Dialoog blijft tekst in tekstblokjes zoals nu. In Prototype 2 maken de NPC's en de speler geluidjes op het ritme van de tekst, net als in *Undertale*.

**Nog open**

- [x] Welke sidequests komen er? In Prototype 2: als eerste Klaas' oude motor bij de velden van het OBC Fort; later meer (zie `docs/PROTOTYPE_2.md`).
- [x] Eigen vijanden in de kerk, naast die van de andere dungeons: **Amber-cultisten** uit Zevenaar, drillers in een zwart pufferjack onder een amber-oranje gewaad, die Amber aanbidden. Ze vapen vuur met een rode vuurvape, en hun gezang maakt vijanden in de buurt woest en geneest ze. En **draakjes** met een driller op hun rug, die vuurballen spugen; daar oefen je de kruisboog op voordat Amber gaat vliegen. Valt een draakje, dan vecht de driller te voet verder (eigenaar, Fase 11).
