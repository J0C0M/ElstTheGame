# Plan Fase 11 – Quest 6: Amber de Draak

Branch: `Add-Amber-Final-Battle`. Dit plan werkt de laatste fase van Prototype 1 uit, op basis van het GDD (*De Kerk van Amber*, *Amber, het verloop*, Quest 6) en de besluiten van de eigenaar. Na akkoord op dit plan bouwen we het onderdeel voor onderdeel, met één commit per onderdeel. Het plan is opgesplitst in drie blokken, zodat het over meerdere sessies kan en de branch na elk blok speelbaar blijft.

## Klaar als

De game is van begin tot eind uit te spelen:

1. Na de drie factiebazen gaan de kerkdeuren open en wordt Quest 6 actief.
2. Je vecht je door de kerk naar beneden, naar Klaas.
3. Je verslaat Amber samen met Klaas. Klaas sneuvelt halverwege en je wekt hem weer tot leven met de gouden Tren-spuit.
4. De tornado verdwijnt, de eindscène en de aftiteling spelen.
5. Daarna loop je vrij rond in het bevrijde Elst.

Opslaan, laden en doodgaan werken overal. Alle tests slagen, ook een nieuwe `test_amber.gd`.

## Besluiten die al vastliggen

- **De kerk gaat open** na de drie factiebazen (`boss_vape_koning`, `boss_fatbike_kindje`, `boss_grumpy_oma`).
- **Je begint boven in het kerkgebouw**, met een echt kerkinterieur. Via trappen en gangen ga je steeds dieper onder de grond, langs een paar doodlopende kamers.
- **Vijanden van alle facties** zitten door elkaar in de kerk, even sterk als in hun eigen dungeon. Wie door het station verzwakt was, blijft dat.
- **Klaas wacht voor de arena.** Je kunt er een laatste keer met hem praten en spullen kopen en verkopen. Er is ook een checkpoint met autosave.
- **De arena** is een enorme ronde ruimte met 5 lange pilaren, die dekking geven tegen vuuradem en vuurballen.
- **Amber** heeft 2 × 800 HP. Klaas vecht de eerste helft mee en sneuvelt in een scène. De tweede helft vecht je alleen.
- **Scènes** zijn eenvoudig (tekst en camera), maar wel compleet. Ze worden in Prototype 2 opnieuw gemaakt.
- **Na de eindscène** loop je vrij rond in het bevrijde Elst.

## Blok A – De weg naar Amber (af)

Afwijking bij het bouwen: de arena ligt op −15 m, net als de voorkamer.

### A1. Kerkdeuren en Quest 6 (`Open the church and start Quest 6`)

- `GameState` zet de vlag `church_open` zodra de drie bazenvlaggen gezet zijn, ook als ze al gezet waren bij het laden. De bestaande `church_open`-variabele volgt die vlag.
- `ChurchDoor` in `Kerk.tscn` krijgt `unlocked_by_flag = &"church_open"` en `target_scene = res://scenes/dungeons/Kerk.tscn`.
- Quest 6 (`data/quests/q6_amber.tres`) start vanzelf als `church_open` gezet wordt, zoals het GDD zegt. Er komt een melding, en Amber spreekt de speler toe "via de tornado" (een melding in amberkleur, zoals het GDD bij Amber beschrijft).
- **Doelen:**
  1. Ga de Kerk van Amber in (`REACH`, `location_id` van de kerk).
  2. Daal af naar het hart van de kerk (`REACH`, het gebied bij Klaas).
  3. Praat met Klaas (`FLAG klaas_ready`).
  4. Versla Amber samen met Klaas (`FLAG boss_amber`).
  5. Wek Klaas met de gouden Tren-spuit (`FLAG klaas_revived`).
- **Beloning:** Inwijding 6 en het einde van de game.
- **Klaas in zijn huis:** hij krijgt nieuwe regels voor Quest 6 ("De kerk is open. Ik wacht beneden op je.") in `tools/data/gen_klaas_dialogue.py`, in plaats van "Nog niet".

### A2. Builder voor hoogteverschil (`Let the dungeon builder stack rooms at different heights`)

`dungeon_builder.py` kan nu alleen vlakke ruimtes op hoogte 0 maken. Voor de kerk komt erbij:

- **Hoogte per ruimte:** de vloer van een ruimte kan op een eigen hoogte liggen, bijvoorbeeld 0, −5, −10 of −15 m.
- **Hellingen:** schuine vlakken van hooguit 35°, met een draai om de X-as. Over een helling loopt de speler omhoog en omlaag, en de navmesh werkt erop (`agent_max_slope = 40`).
- **Draaiing voor muren en blokken:** een draai om de Y-as. Daarmee bouwen we een ronde arena uit muurstukken en schuine dingen in de kerk.
- **Glow-blokken:** voor glas-in-lood, kaarsen en amberkleurige scheuren.

De vier bestaande dungeons blijven exact hetzelfde. Dat controleer ik door ze opnieuw te genereren: dat mag geen verschil geven.

### A3. De kerk-dungeon (`Build the church dungeon from the nave down to the arena`)

`tools/dungeons/gen_kerk.py` bouwt `scenes/dungeons/Kerk.tscn`. Dit wordt de grootste dungeon, ongeveer 30 vijanden.

| Niveau | Ruimtes | Sfeer en inhoud | Vijanden |
|---|---|---|---|
| 0 m – het kerkgebouw | Portaal, schip, zijbeuken, koor | Middenpad met rijen kerkbanken, pilaren tussen schip en zijbeuken, een altaar met amberkleurige vlammen, preekstoel, orgel met pijpen, doopvont, glas-in-lood (gloeiend), Amber-banieren. Achter het altaar een trap naar beneden | Drillers, vape-drillers, bingo-opa's |
| −5 m – de crypte | Gang met grafnissen, grafkamer, 2 doodlopende kamers | Sarcofagen, kaarsen, smalle gangen. In de ene doodlopende kamer een kist, de andere is een hinderlaag | Laag drillers, boze oma's, rolstoel-oma's |
| −10 m – de catacomben | Gangenstelsel, brede tunnel, 1 doodlopende kamer | Doolhofachtig, amberkleurige scheuren in de muren. De fatbikers hebben een brede tunnel om te chargeren | Voetballers, fatbikers, vape-drillers |
| −15 m – de voorkamer | Rustige ruimte voor de arenadeur | Klaas, een `Checkpoint` (autosave) en een `RestBench`. Grote dichte deuren naar de arena | – |
| −18 m – de arena | Ronde ruimte, ongeveer 44 m doorsnee en 16 m hoog | 5 lange pilaren in een ring, een koepel, amberkleurige gloed uit de vloer | Amber |

- **Teruggaan:** de trappen zijn hellingen, dus je kunt ook terug naar boven en naar buiten.
- **`test_world`:** krijgt de kerk in `DEEPEST`, met een route over de navmesh van de ingang naar de arena.
- **Na het einde:** verslagen dungeon (`cleared_flag = boss_amber`), dus leeg met een paar feestende inwoners.

### A4. Vijanden in de kerk (`Fill the church with every faction`)

- **Vijanden:** de bestaande vijandscenes met hun eigen `EnemyData`. Westeraam en OBC blijven dus verzwakt.
- **Kijkrichting:** via `aim_enemies()`, met een hoog aandeel dat naar de speler kijkt (zoals de Bingo Club). De laatste dungeon is de zwaarste.
- **Eigen kerkvijanden:** komen er alleen als de eigenaar daarvoor kiest (zie *Open beslissingen*, punt 1).

### A5. Klaas voor de arena (`Put Klaas at the arena door with his last talk and shop`)

- **Klaas als NPC:** een instantie van `Klaas.tscn` in de voorkamer, met een eigen dialoog `data/dialogue/klaas_church.tres` (ook uit `gen_klaas_dialogue.py`).
- **Gesprek:** een laatste peptalk, "Laat zien wat je hebt" (`open_shop`, kopen en verkopen), en "Ik ben er klaar voor" (`set_flag klaas_ready`).
- **Arenadeuren:** gaan open bij `klaas_ready`. Klaas loopt dan als bondgenoot mee de arena in (zie B2).
- **Na doodgaan:** de checkpoint-save brengt je terug in de voorkamer. Klaas staat er weer, en je praat opnieuw met hem om te beginnen.

**Na blok A** kun je de hele kerk door tot aan Klaas, met de winkel en het checkpoint. Amber zelf ontbreekt nog.

## Blok B – Het gevecht

### B1. Amber-model (`Add the low-poly Amber model`)

`tools/models/gen_amber.py` bouwt `scenes/bosses/AmberModel.tscn`: een grote low-poly draak van zo'n 12 m lang.

- **Lijf:** romp, lange nek, kop met hoorns en gloeiende ogen, vleugels met vliezen, staart met stekels en vier poten.
- **Kleuren:** amber en oranje schubben, een donkere buik en gloeiende ogen en keel.
- **Animaties in code** (`amber_model.gd`, geen `HumanoidModel`):
  - lopen, ademen;
  - inademen voor de vuuradem (de keel gloeit), vuuradem;
  - staartzwiep, vleugelslag;
  - opstijgen, vliegen in een cirkel, neerstorten, uitgeput liggen;
  - de dood.

### B2. Klaas als bondgenoot (`Add Klaas as an ally who fights Amber`)

`scenes/npcs/KlaasAlly.tscn` is een `CharacterBody3D` met `KlaasModel` en een eigen kleine state machine.

- **Bewegen:** buiten het gevecht volgt hij de speler. In het gevecht loopt hij naar Amber toe en slaat haar om de ~1,6 s (schade uit een `.tres`).
- **Aandacht trekken:** zolang hij meevecht, kiest Amber hem in ongeveer 35% van haar aanvallen als doelwit, zoals het GDD vraagt.
- **Onsterfelijk:** gewone schade doet hem niets. Hij wankelt en roept iets ("Is dat alles, hagedis?"). Alleen in de scène sneuvelt hij.
- **Als Amber vliegt:** hij kijkt omhoog en roept "Pak je kruisboog!".

### B3. Amber, levensbalk 1 (`Add Amber's first health bar with breath, tail, wings and flight`)

`scenes/bosses/Amber.tscn` met `amber.gd` en `data/enemies/amber.tres`. Ze volgt het patroon van de andere bazen: opslaan geblokkeerd, `boss_*`-signalen, arenadeur dicht en een vlag als ze verslagen is.

| Aanval | Wanneer | Waarschuwing | Effect | Kans voor de speler |
|---|---|---|---|---|
| Vuuradem | Doelwit voor haar | 0,8 s: kop naar achteren, keel gloeit | Een kegel vuur van ~14 m, 2 s lang, elke 0,25 s schade. Een pilaar tussen jou en haar houdt het vuur tegen (straal vanaf de bek) | Daarna staat ze 2 s hijgend met de kop laag: kop ×2 schade |
| Staartzwiep | Speler naast of achter haar | 0,6 s: staart omhoog | Zwiep in een boog, schade en terugslag | Ontwijken of springen |
| Vleugelwind | Speler te dichtbij | 0,5 s: vleugels wijd | 2,5 s wind die je wegduwt (`apply_wind`) | Achter een pilaar staan |
| Opvliegen met vuurregen | Om de ~25 s | Ze stijgt op | Ze cirkelt boven de arena. Rode cirkels op de grond, na 1 s een vuurbal met een brandende plek (`FirePatch`) | Drie pijlen of 90 kruisboogschade: ze stort neer en ligt 4 s versuft, kop ×2. Na ~12 s landt ze vanzelf |

- **Schade:** het lijf krijgt gewone schade, de kop dubbel in de kansmomenten. Dat is de les van Grumpy Oma: niet te vergevingsgezind, maar wel eerlijk.
- **HUD:** de grote balk toont "Amber de Draak – 1/2" en daarna "2/2".

### B4. De overgang: Klaas sneuvelt (`Add the scene where Klaas saves the player`)

- **Stil:** als balk 1 leeg is, is Amber even onkwetsbaar en stopt alles.
- **Scène:**
  1. De camera gaat naar Amber, die een fatale vuurbal laadt op de speler.
  2. Klaas rent ertussen, duwt de speler weg en wordt geraakt.
  3. Hij valt neer, met tekstregels van Klaas en Amber. Hij blijft liggen in de arena.
- **Systeem:** `scripts/cutscene/cutscene.gd`, een kleine reeks stappen: camera naar een punt, tekst (E gaat verder), animatie, wachten en fade. Tijdens een scène kun je niet bewegen en niet opslaan. Het wordt ook gebruikt in C1 en C2.

### B5. Amber, levensbalk 2 (`Add Amber's furious second phase`)

- **Woedend:** 30% sneller, een rodere gloed en vaker vuurregen.
- **Brandende plekken:** ze laat een spoor van brandende plekken achter waar ze loopt en na een vuuradem.
- **Hulp:** op 2/3 en 1/3 van balk 2 roept ze 2–3 drillers op.
- **Haar dood:** ze stort neer en haar ogen doven. De gouden Tren-spuit valt gloeiend op de grond.

**Na blok B** is het hele gevecht speelbaar, tot de Tren-spuit.

## Blok C – Het einde

### C1. Klaas weer tot leven (`Revive Klaas with the golden Tren syringe`)

- Je pakt de Tren-spuit op. Het questdoel wordt dan "Gebruik de spuit op Klaas".
- E bij Klaas: een scène waarin Klaas opstaat, flext en iets droogs zegt. Vlag `klaas_revived`.

### C2. De tornado verdwijnt (`Make the tornado disappear after Amber`)

- **Scène:** na een fade naar Elst kijkt de camera naar de tornado, die in ~6 s krimpt en vervaagt.
- **Daarna:** zodra `boss_amber` gezet is, ook na laden, is de tornado weg (`TornadoBorder.dissolve()`). De mist trekt op naar helder weer, met lichtere lucht en mist veel verder weg.
- **De rand:** de wereld eindigt nog steeds bij de oude ring, maar zonder wind en tornado. Er komt een onzichtbare grens met een vriendelijke melding (zie *Open beslissingen*, punt 4).

### C3. Eindscène, aftiteling en vrij spelen (`Add the end scene, credits and free roaming`)

- **Feest:** de kerk wordt een feestplek, met een `LiberatedArea` met dorpelingen, lichtjes en slingers op het kerkplein.
- **Eindscène:** op het kerkplein noemt Klaas je "een echte Elstenaar". Inwijding wordt 6.
- **Aftiteling:** rolt over het scherm, met namen en de CC0-bronnen uit `CREDITS.md`. Daarna speel je verder in het bevrijde Elst.
- **Na het einde:** Klaas in zijn huis krijgt nieuwe regels.

### C4. Tests en documentatie (`Test and document Phase 11`)

`tests/test_amber.gd` speelt Quest 6 na:

1. De kerk is dicht tot de drie bazen verslagen zijn, en Quest 6 start vanzelf.
2. In de dungeon zitten vijanden van alle facties, en het checkpoint werkt.
3. Klaas' winkel en "klaar" openen de arena.
4. Balk 1:
   - de vuuradem raakt, maar niet achter een pilaar;
   - de staartzwiep en de wind werken;
   - vliegen, neergeschoten worden en de kop ×2 werken.
5. De overgang laat Klaas sneuvelen.
6. Balk 2 is woedend en roept drillers op.
7. Haar dood geeft de Tren-spuit, en daarmee wek je Klaas weer tot leven.
8. De tornado is weg, ook na opnieuw laden.
9. Het einde staat in de save, en de kerk is een feestplek.

Verder:
- `test_world` krijgt de route door de kerk.
- `PROGRESS.md`, `CLAUDE.md`, `README.md` en het GDD worden bijgewerkt, met afwijkingen.
- Een testchecklist voor de eigenaar.

## Open beslissingen voor de eigenaar

1. **Eigen kerkvijanden?** Mijn voorstel:
   - **Amber-cultisten:** dorpelingen in amber-oranje gewaden. Hun gezang maakt vijanden in de buurt woest. Dit is goedkoop te maken met de bestaande onderdelen.
   - **Draakjes:** kleine vliegende draakjes die vuurballen spugen. Zo oefen je met de kruisboog voor Amber. Dit is nieuw werk, want vliegende vijanden bestaan nog niet.

   Advies: beide, met de draakjes alleen in de catacomben.
2. **Quest 6 start vanzelf** als de kerk opengaat, met een toespraak van Amber via de tornado en een nieuwe regel van Klaas in zijn huis. (Advies: ja, zo staat het in het GDD.)
3. **Klaas loopt niet mee door de dungeon.** Hij wacht voor de arena, zoals het GDD zegt. (Advies: ja.)
4. **De rand van de wereld na het einde:** een onzichtbare grens bij de oude ring met een melding als "Je hoeft nergens meer heen. Elst is weer van jou." (Advies: ja. Het alternatief is lopen tot de grond ophoudt.)
5. **Aftiteling:** welke naam of namen wil je erin? Bijvoorbeeld "Een game van J0C0M", plus Godot en de CC0-bronnen.
6. **Getallen:** de startwaarden staan in de tabel van B3 en in `amber.tres`. Balans stellen we bij in Fase 12.

## Volgorde en sessies

| Blok | Onderdelen | Wat je daarna kunt testen |
|---|---|---|
| A | A1–A5 | De kerk open, de hele dungeon door, Klaas, de winkel, het checkpoint |
| B | B1–B5 | Het hele gevecht met Klaas, tot de Tren-spuit |
| C | C1–C4 | Het einde van de game, de aftiteling, vrij rondlopen en alle tests |

Na elk blok volgt een korte testronde. Na blok C komt de volledige testchecklist en daarna het akkoord om te mergen.
