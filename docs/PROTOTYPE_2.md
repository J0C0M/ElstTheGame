# Elst – Prototype 2

21-11-2026 · ontwerp voor Prototype 2, op basis van de notitie van de eigenaar ("Game idee prototype 2")

Prototype 1 (Fase 0 t/m 12) is de oorspronkelijke visie van *Elst*, van begin tot eind speelbaar. Prototype 2 bouwt daarop verder. Dit document is de bron van waarheid voor Prototype 2; waar het afwijkt van `docs/GDD.md` (het ontwerp van Prototype 1), geldt dit document.

## Doel

1. **Modellen** van veel hogere kwaliteit, maar nog steeds low poly. Dit is het belangrijkste en komt in de eerste fases. De filter, het licht en de sfeer van Prototype 1 blijven zoals ze zijn (besluit eigenaar). Het detailniveau van de modellen kiest de eigenaar uit vier voorstellen (zie *Modellen: vier voorstellen*).
2. **Personages:** de hoofdpersoon wordt **Gyan**. **Jules** en **Sven** komen erbij als de tweede en derde Elstenaar. Klaas wordt grafisch verbeterd. Dit verandert ook het verhaal.
3. **Bijcontent in de open wereld**, om Elst te vullen: als eerste Klaas' oude motor bij de lege velden naast het OBC Fort. Later volgt meer.

Wat in Prototype 1 werkt (combat, quests, opslaan, dungeons, bazen, geluid), blijft de basis. Prototype 2 verbetert en vult aan; het gooit niets weg zonder reden.

## Verhaal en personages

### De Elstenaars

In Prototype 1 is de speler "een niemand" die aan het eind van Klaas hoort dat hij "een echte Elstenaar" is. In Prototype 2 wordt dat de rode draad: rond Klaas vormt zich een groepje **Elstenaars**, mensen uit Elst die het tegen Amber opnemen.

| # | Elstenaar | Hoe hij erbij komt |
| --- | --- | --- |
| 1 | **Gyan** | De hoofdpersoon. Hij komt in Elst terecht, Klaas neemt hem onder zijn hoede (Quest 1). |
| 2 | **Jules** | Zit opgesloten in een kooi in de Westeraam-dungeon. Met de sleutel van de Vape-koning kan Gyan hem bevrijden. **Optioneel.** |
| 3 | **Sven** | Leidt een OBC-voorpost in de buurt van het OBC Fort en is daar een miniboss. Na zijn nederlaag kies je: overtuig hem om de kant van Klaas te kiezen, of vermoord hem. **Optioneel** (bijquest). |

Jules en Sven zijn allebei optioneel (besluit eigenaar, 21-11-2026): wie ze niet redt of overtuigt, ziet ze verder niet in de game.

De eigenaar werkt de karakterontwikkeling van Gyan, Jules en Sven later verder uit. De teksten hieronder zijn een startpunt.

### Gyan (hoofdpersoon)

- **Uiterlijk** (referentie `docs/reference/Gyan.png`, alleen lokaal): jong, slank, licht getinte huid, donkerbruin, warrig haar van gemiddelde lengte met een pony over het voorhoofd, bruine ogen, een grote, open lach. Een geruit overhemd (blauw-wit) als basiskleding; uitrusting blijft zichtbaar op het model, zoals nu.
- **Rol:** speelbaar personage, vervangt "de speler, een niemand". Klaas en de andere personages noemen hem bij naam.
- **Stille hoofdpersoon** (besluit eigenaar, 21-11-2026): Gyan zegt zelf niets. Anderen praten tegen hem; de keuzes in gesprekken blijven korte opties zonder eigen stem. Ook de zin bij de rand van Elst na het einde ("Waar ga ik heen?...") wordt een gedachte in beeld of een reactie van een ander.

### Jules (tweede Elstenaar)

- **Uiterlijk** (referentie `docs/reference/Jules.png`): lichte huid met sproeten, blond tot rossig, warrig haar met een lange pony, blauwgroene ogen, een sceptische, wat argwanende blik. Een donker groenbruine jas of hoodie.
- **In het verhaal** (besluit eigenaar, 21-11-2026): Jules zit in een kooi in de Westeraam-dungeon. De sleutel krijg je van de Vape-koning (hij laat hem vallen als je hem verslaat). Bevrijden is optioneel.
- **Bevrijd:** een korte scène waarin Jules Gyan op zijn eigen droge manier bedankt. Daarna kom je hem af en toe tegen in de open wereld, waar hij vecht tegen een paar drillers; je kunt hem helpen. Hij staat ook op het feest aan het eind.
- **Niet bevrijd:** Jules komt verder niet in de game voor.

### Sven (derde Elstenaar)

- **Uiterlijk** (referentie `docs/reference/Sven.png`): lichte huid, kort lichtbruin tot donkerblond haar met een zijscheiding, een brede kaak, een uitdagende, pruilende blik. Zwarte hoodie en een grote zwarte koptelefoon om zijn nek of op zijn hoofd.
- **Optioneel** (besluit eigenaar, 21-11-2026): de voorpost is een bijquest; het OBC Fort kan ook zonder Sven.
- **In het verhaal:** Sven leidt een **OBC-voorpost**, een kleiner kamp van het OBC in de buurt van het OBC Fort. Hij is daar een **miniboss** met zijn eigen aanvallen. Na zijn nederlaag ligt hij op de grond en kiest de speler:
  - **Overtuigen:** Sven kiest de kant van Klaas en wordt de derde Elstenaar. Daarna kom je hem af en toe tegen in de open wereld, waar hij meevecht tegen vijanden, net als Jules (besluit eigenaar).
  - **Vermoorden:** Sven is weg en komt verder niet in de game voor.
- De keuze wordt een vlag (`sven_spared` of `sven_killed`) die dialogen, het einde en eventueel de Inwijding beïnvloedt.

### Klaas

Blijft zoals hij is (lang, breed, gespierd, blond, strakke kaak, zonnebril die nooit afgaat, paars en goud), maar krijgt een veel gedetailleerder model (referentie `docs/reference/Klaas_sigma.png`): spiervorm in armen, borst en nek, een kaak en een kuif die kloppen, de gouden ketting, een strak shirt. Hij krijgt nieuwe animaties (flexen, lachen, wijzen) en een eigen stem.

### Wat blijft

Amber de Draak uit Zevenaar, de drie facties en hun bazen, het station, de kerk en het eindgevecht blijven. De spion in de mantel en "plan B" blijven een haak voor later; de eindscène wordt opnieuw gemaakt met de nieuwe personages.

### Nieuwe verloop van de hoofdquests

| # | Quest | Verandering in Prototype 2 |
| --- | --- | --- |
| 1 | Inleiding | Gyan heeft een naam; Klaas noemt hem "de eerste Elstenaar" zodra de tutorial af is. |
| 2 | Station Elst | Geen grote verandering. |
| 3 | Westeraam Getho | De Vape-koning laat de sleutel van Jules' kooi vallen; Jules bevrijden is een optioneel doel. |
| 4 | OBC Elst Fort | Geen verandering; de OBC-voorpost met Sven is een aparte bijquest in de buurt. |
| 5 | Bingo Club | Geen grote verandering. |
| 6 | Amber de Draak | De Elstenaars die je redde of overtuigde, staan op het feest aan het eind. |

## Bijcontent in de open wereld

Bijquests krijgen een eigen plek in het questlog (tabbladen *Hoofdquests* en *Bijquests*), een eigen kleur op het kompas en een kleine beloning. Ze zijn optioneel.

### Klaas' oude motor (eerste bijquest)

- Naast de lege velden bij het OBC Fort (zuidwesten van Elst, zie `docs/kaart_elst_spel.png`) staat een roestige, oude motor onder een zeil.
- Klaas herkent hem ("Mijn oude motor! Die dacht ik kwijt te zijn sinds Amber kwam.").
- **Besluit eigenaar:** vind de motor, breng hem naar Klaas, en daarna kan Gyan er meteen op rijden: sneller door Elst, met een eigen geluid. Geen onderdelen zoeken.

### Later

De eigenaar voegt meer bijcontent toe. Het systeem van Fase P2-10 is daarvoor gemaakt: nieuwe bijquests zijn alleen data (`QuestData` met een vlag `side_quest`) plus een plek in de wereld.

## Modellen: vier voorstellen

**Besluit eigenaar (21-11-2026):** de retrofilter, het licht, de mist en de sfeer van Prototype 1 blijven. Het gaat om de modellen: die moeten van veel hogere kwaliteit worden en low poly blijven. (Een eerste ronde voorbeelden van vier render-stijlen is daarom vervallen.)

De vier voorstellen hieronder verschillen in hoe de modellen gemaakt worden en hoeveel detail ze krijgen. Fase P2-1 bouwt een **modellab**: Klaas, Gyan, een driller en een huis in alle vier de varianten, in de echte filter van het spel naast elkaar, zodat de eigenaar kiest.

### M1. Verfijnde blokken

- **Wat:** dezelfde aanpak als nu (losse dozen, prisma's en kegels per lichaamsdeel), maar met veel meer onderdelen: afgeschuinde randen, handen met een duim, schoenen met een zool, kragen, zakken, haarplukken, gezichten met neus, wenkbrauwen en mond als eigen blokjes. Personages zo'n 300 tot 600 driehoeken.
- **Voor:** het snelst; past direct op de huidige generators en het huidige rig.
- **Tegen:** blijft herkenbaar "blokkig"; ronde vormen (spieren van Klaas, gezichten) blijven hoekig.
- **Werk:** klein.

### M2. Gefacetteerde low poly (aanbevolen)

- **Wat:** echte meshes per lichaamsdeel in plaats van dozen: getaperde armen en benen, een romp met borst en schouders, een hoofd met kaak, jukbeenderen, neus en oogkassen, haar als één gefacetteerde vorm met plukken. Vlak gekleurde facetten (geen texturen), zoals moderne low poly-personages. Personages zo'n 800 tot 1500 driehoeken, met ellebogen, knieën, polsen en enkels.
- **Voor:** veel herkenbaarder (Klaas' kaak en spieren, Gyans haar en lach, Jules' pony, Svens koptelefoon), blijft duidelijk low poly, past bij de filter; de meshes ontstaan nog steeds in code, dus vervangbaar.
- **Tegen:** een nieuwe mesh-generator en een nieuw rig nodig (P2-2).
- **Werk:** gemiddeld.

### M3. Gestileerd (grote koppen)

- **Wat:** zoals M2, maar met overdreven verhoudingen: grotere hoofden en handen, kortere lijven, gezichten met grote ogen en wenkbrauwen voor uitdrukkingen.
- **Voor:** heel expressief en grappig; gezichtsuitdrukkingen werken goed in scènes.
- **Tegen:** lijkt minder op de echte personen van de referentiefoto's; verandert het gevoel van het spel meer.
- **Werk:** gemiddeld.

### M4. PS2-niveau

- **Wat:** realistischer verhoudingen en meer detail: zo'n 2000 tot 4000 driehoeken per personage, vloeiendere vormen, kleding met plooien. Waarschijnlijk met Blender gemaakt in plaats van in code.
- **Voor:** het meest gedetailleerd.
- **Tegen:** het minst "low poly"; veel werk per model; moeilijker te maken en aan te passen vanuit scripts.
- **Werk:** groot.

**Advies:** M2. Het geeft de grootste stap in kwaliteit en herkenbaarheid zonder de low poly-stijl en de filter te verliezen, en we kunnen alles in code blijven maken.

## Techniek voor Prototype 2

- **Modellen:** volgens het gekozen voorstel (zie hierboven). De Python-generators (`tools/models/model_builder.py`) worden uitgebreid met echte meshes in plaats van alleen dozen: afgeronde en afgeschuinde vormen, getaperde ledematen, gezichten. De meshes worden als `ArrayMesh` in `.tres` of `.res` weggeschreven, zodat ze nog steeds door code ontstaan en later door Blender-modellen vervangen kunnen worden.
- **Rig:** personagemodellen krijgen meer gewrichten: ellebogen, knieën, polsen, enkels, nek en ruggengraat. `HumanoidModel` blijft de animaties in code spelen, met dezelfde actienamen, plus nieuwe (lachen, wijzen, zitten op een motor, in een kooi hangen).
- **Rendering:** de retrofilter, het licht en de mist blijven zoals in Prototype 1 (besluit eigenaar). Materialen blijven vlakke kleuren.
- **Wereld:** wegen worden echte meshes langs splines in plaats van een raster van 1 m; de grond krijgt zachtere overgangen; huizen krijgen types (rijtjeshuis, twee-onder-een-kap, flat, boerderij) en meer detail (ramen, deuren, dakgoten, schuurtjes, schuttingen).
- **Scènes:** het scènesysteem (`Cutscene`) krijgt korte camerapaden, close-ups met gezichtsuitdrukkingen en "blokkades" (waar wie staat), zodat de scènes van Prototype 1 (Klaas valt, het einde, de spion) opnieuw en beter gemaakt kunnen worden.
- **Stemmen:** iedere spreker krijgt een eigen stemblip (toonhoogte en klank), al begonnen in Fase 12 met `DialogueData.voice_pitch`.
- **Saves:** het save-formaat gaat naar versie 2. Saves van Prototype 1 laden niet meer; Prototype 2 begint met een nieuw spel (besluit eigenaar).
- **Schaal:** straten en wegen worden breder en de huizen iets hoger en ruimer geplaatst (besluit eigenaar). De zes locaties blijven op hun plek; het dorp eromheen schuift wat (in P2-5).

## Fases van Prototype 2

Werkwijze en git-regels blijven zoals in `CLAUDE.md`: één fase is één request en één branch vanaf `Development`, een commit per onderdeel, en mergen na "akkoord" op de testchecklist. De fases zijn genummerd P2-1 en verder.

| Fase | Branch | Inhoud | Klaar als |
| --- | --- | --- | --- |
| P2-0 | `Plan-Prototype-2` | Dit document, de beslissingen, de fases en de bijgewerkte documenten | De eigenaar is akkoord met het plan |
| P2-1 | `Build-Model-Style-Lab` | Klaas, Gyan, een driller en een huis in de vier modelvoorstellen (M1 t/m M4), naast elkaar in de filter van het spel | De eigenaar heeft een voorstel gekozen |
| P2-2 | `Build-Mesh-Toolkit-And-Rig` | De mesh-generator voor het gekozen voorstel, het nieuwe rig (ellebogen, knieën, polsen, enkels, nek, ruggengraat) en de nieuwe animaties in `HumanoidModel` | Een testpersonage loopt, vecht en flext met het nieuwe rig |
| P2-3 | `Upgrade-Character-Models` | Gyan, Klaas en de dorpelingen | Gyan en Klaas lijken op hun referenties en bewegen beter |
| P2-4 | `Upgrade-Enemy-And-Boss-Models` | Alle vijanden en bazen: drillers, vape-drillers, kakkers, fatbikers (rijhouding, draaiende wielen), opa's en oma's met eigen modellen, rolstoel-oma, cultisten, draakjes, de vier bazen | Elke vijand is van ver herkenbaar |
| P2-5 | `Upgrade-World-And-Roads` | Bredere straten, wegen als meshes, nieuwe huizen en bomen, props, de zes locaties, de grond | Elst oogt af, zonder blokkerige wegen |
| P2-6 | `Upgrade-Dungeons` | De vijf dungeons en het huis van Klaas met de nieuwe modellen en props | Alle interieurs passen bij de rest |
| P2-7 | `Add-Gyan-And-Story-Rework` | Gyan als (stille) hoofdpersoon, dialogen en scènes herschreven, de scènes van Prototype 1 opnieuw gemaakt (Klaas valt, het einde, de spion), stemmen per personage, save-formaat 2 | Het hele verhaal klopt met Gyan, van begin tot eind |
| P2-8 | `Add-Jules-Rescue` | Jules en zijn model, de kooi in de Westeraam-dungeon, de sleutel van de Vape-koning, Jules in de open wereld tegen drillers | Jules is te bevrijden en daarna in Elst te vinden; niet bevrijd zie je hem niet |
| P2-9 | `Add-Sven-Outpost-Miniboss` | De OBC-voorpost (bijquest bij het fort), Sven en zijn model, het minibossgevecht, de keuze en de gevolgen | Overtuigd helpt Sven in de open wereld; vermoord is hij weg |
| P2-10 | `Add-Side-Quests-And-Klaas-Motorbike` | Bijquests in het questlog en op het kompas, Klaas' oude motor vinden, naar Klaas brengen en erop rijden | De motor is te vinden en te berijden |
| P2-11 | `Polish-Prototype-2` | Balans, geluid en muziek bijwerken, bugfixes, laadschermen, export | Prototype 2 is van begin tot eind speelbaar zonder blokkerende bugs |

**Volgorde:** eerst de modellen (P2-1 t/m P2-6), zoals de eigenaar wil. Het verhaal (P2-7) komt daarna, omdat de nieuwe scènes de nieuwe modellen nodig hebben. Jules, Sven en de motor (P2-8 t/m P2-10) bouwen daarop voort.

## Beslissingen

Genomen door de eigenaar op 21-11-2026:

1. **Grafisch:** de filter, het licht en de sfeer blijven; de modellen worden van hogere kwaliteit en blijven low poly.
2. **Gyan** is een stille hoofdpersoon.
3. **Jules** is optioneel: een kooi in de Westeraam-dungeon, de sleutel van de Vape-koning; bevrijd vecht hij af en toe in de open wereld tegen drillers, anders zie je hem niet meer.
4. **Sven** is optioneel (bijquest): overtuigd vecht hij af en toe mee in de open wereld (zoals Jules), vermoord is hij weg.
5. **De motor:** vinden, naar Klaas brengen en meteen erop rijden, zonder onderdelen te zoeken.
6. **Saves:** saves van Prototype 1 laden niet; Prototype 2 begint met een nieuw spel.
7. **Schaal:** bredere straten, huizen iets hoger en ruimer.
8. **Controller:** niet in Prototype 2, later.
9. **De spion en plan B:** bewaren voor later; in Prototype 2 blijft het de haak in de (opnieuw gemaakte) eindscène.

**Nog open:** welk modelvoorstel (M1 t/m M4)? Dat kiest de eigenaar in het modellab van P2-1. Advies: M2.

## Overgenomen punten uit Prototype 1

Uit `docs/PROGRESS.md` (*Verzamelde punten voor Prototype 2*), nu ingedeeld bij de fases:

- Huizen, bomen en props mooier → P2-5.
- Blokkerige paden en wegen (raster van 1 m) → P2-5.
- Smalle straten en lage huizen → P2-5 (bredere straten, beslissing 7).
- Fatbikers en het fatbike-kindje: rijhouding en draaiende wielen → P2-4.
- Scènes opnieuw maken na de grafische overhaul, ook de eindscène met de spion → P2-7.
- Stemgeluidjes per personage → P2-7.
- Controller-ondersteuning → later (beslissing 8).
- Bijquests → P2-10.
- Eigen modellen voor de opa's en oma's, en de rolstoel-oma met buigende benen en draaiende wielen → P2-4.
