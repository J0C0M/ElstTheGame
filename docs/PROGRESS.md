# Voortgang

Hier staat per fase wat af is, welke keuzes zijn gemaakt, waar we van het GDD afwijken en wat nog openstaat.

## Overzicht

| Fase | Branch | Status |
|---|---|---|
| 0 | `Setup-Project-Foundation` | Af, gemerged naar `Development` |
| 1 | `Add-Player-Controller-And-Combat` | Af, gemerged naar `Development` |
| 2 | `Build-Elst-World-Blockout` | Af, gemerged naar `Development` |
| 3 | `Add-Save-System` | Af, gemerged naar `Development` |
| 4 | `Add-Enemy-AI-And-Loot` | Af, gemerged naar `Development` |
| 5 | `Add-Klaas-Dialogue-And-Shop` | Af, gemerged naar `Development` |
| 6 | `Add-Quest-System-And-Tutorial` | Af, gemerged naar `Development` |
| 7 | `Add-Station-Dungeon` | Af, gemerged naar `Development` |
| 8 | `Add-Westeraam-Dungeon` | Af, gemerged naar `Development` |
| 9 | `Add-OBC-Fort-Dungeon` | Af, gemerged naar `Development` |
| 10 | `Add-Bingo-Cave-Dungeon` | Af, gemerged naar `Development` |
| 11 | `Add-Amber-Final-Battle` | Af, gemerged naar `Development` |
| 12 | `Polish-And-Release-Build` | Gebouwd, wacht op akkoord; exporteren wacht op de export templates |

Tussendoor: `Rebalance-Grumpy-Oma-And-Crossbow` (Grumpy Oma zwaarder, pijlen voor de kruisboog) wacht op akkoord. `Align-Elst-With-Map` (de kaart verwerken) is af en gemerged naar `Development`. `Lock-Faction-Dungeons-And-Expand-Westeraam` (factie-dungeons op slot en een groter Westeraam) is af en gemerged naar `Development`. `Add-Dev-Powers-And-Enemy-Facing` (dev powers, vijanden in dungeons, nieuwe locaties) is gebouwd en wacht op akkoord.

## Prototypes

- **Prototype 1** bestaat uit Fase 0 t/m 12: de oorspronkelijke visie van de game, van begin tot eind speelbaar. Daar werken we nu aan.
- **Prototype 2** begint pas als Prototype 1 af is. Wat erin komt, bepaalt de eigenaar dan. Een van de belangrijkste punten wordt graphics en details, waarschijnlijk met nog andere tweaks.
- **Tot die tijd** blijven modellen en wegen placeholders. Steek er alleen tijd in als de gameplay of de leesbaarheid het nodig heeft. Visuele punten die we tegenkomen, komen in de lijst hieronder.

### Verzamelde punten voor Prototype 2

- Modellen van objecten in de wereld (huizen, bomen, props) zijn nog niet mooi en kunnen veel beter (eigenaar, 19-11-2026).
- Paden en wegen zijn erg blokkerig en visueel slecht uitgewerkt: de grond is een raster van 1 m (eigenaar, 19-11-2026).
- Straten zijn op deze schaal maar 2 tot 3 m breed; daardoor zijn de huizen laag gehouden (zie *Kaart verwerken*).
- Fatbikers en het fatbike-kindje zitten op hun fiets met lopende benen; een echte rijhouding en draaiende wielen ontbreken nog.
- Scènes (Klaas die sneuvelt, de tornado die verdwijnt, de eindscène) worden in Prototype 1 eenvoudig maar compleet, en na de grafische overhaul opnieuw gemaakt (eigenaar, 20-11-2026). De eindscène met het figuur in de mantel en "plan B" moet in Prototype 2 sowieso opnieuw, omdat er personages bijkomen of veranderen.
- Dialoog met geluidjes op het ritme van de tekst, zoals in *Undertale* (eigenaar, 20-11-2026): in Prototype 1 al gedaan met één blip per spreker; in Prototype 2 eventueel eigen stemmen per personage.
- Controller-ondersteuning komt in een later prototype; sidequests bespreken we bij het ontwerp van Prototype 2.
- De oma's en opa's zijn aangepaste kopieën van het driller-model (met tasje, wandelstok of rolstoel). Een eigen model maakt ze beter herkenbaar. De benen van de rolstoel-oma zijn stijve balken en de wielen draaien niet.

## Fase 0 – Fundament

### Wat is af

- Godot 4.7-project "Elst": venster 1280×720, Forward+, stretch-modus `canvas_items` met aspect `expand`, hoofdscene `res://scenes/main/Main.tscn`.
- Mappenstructuur uit het GDD, met een `.gitkeep` in lege mappen.
- Lege autoloads `EventBus`, `GameState`, `SaveManager`, `QuestManager` en `AudioManager`, plus `Settings` (zie keuzes).
- InputMap met alle acties en toetsen uit het GDD, plus `toggle_retro_filter` (F1) en `cycle_pixel_size` (F2).
- Collision layers 1–7 met een naam, en `PhysicsLayers` met de bitwaarden voor in code.
- Retrofilter: `RetroScreen.tscn` (SubViewport op lage resolutie, nearest-neighbour opgeschaald) met `shaders/retro_post.gdshader` (32 tinten per kanaal, 4×4 Bayer-dithering, zachte vignette, heel lichte filmruis). De HUD staat erbuiten en blijft scherp.
- Testscene `res://scenes/world/FilterTest.tscn`: grondvlak, wegen, de zes locaties als gekleurde blokken in de factiekleuren, bomen, een tornadomuur in de verte, zon, lucht en mist, en een camera die langzaam rond de kerk draait.
- `.gitignore`, `.gitattributes`, `README.md`, `CLAUDE.md`, `CREDITS.md`, `.claude/settings.json`, `docs/GDD.md` en dit bestand.

### Keuzes en afwijkingen

- **Extra autoload `Settings`.** De prompt noemt vijf autoloads. Instellingen (filter, pixelgrootte, later gevoeligheid en volume) horen niet in een save, maar moeten wel overal bereikbaar zijn. Daarom staat er een zesde autoload `Settings`, die `user://settings.cfg` bijhoudt en `EventBus.settings_changed` uitzendt. Het instellingenmenu van Fase 3 bouwt hierop.
- **Pixelgrootte.** *Midden* (standaard) rendert op 640×360, *Laag* geeft kleinere pixels op 960×540, *Uit* rendert op de volle resolutie van het venster. De hoogte ligt vast en de breedte volgt de beeldverhouding van het venster. In een venster van 1920×1080 zijn Midden en Laag precies 3× en 2× opgeschaald.
- **F1 zet de hele filter uit**, dus de shader en de lage resolutie. Met F2 wissel je de pixelgrootte. Beide keuzes worden bewaard in `user://settings.cfg`. Tot het instellingenmenu er is (Fase 3) is F2 de enige manier om de pixelgrootte te kiezen.
- **Hoe het opschalen werkt.** `RetroScreen` is een `SubViewportContainer` met `stretch` aan. Het script maakt de container zo klein als de renderresolutie en schaalt hem met `scale` terug naar schermvullend. Zo werken ook niet-gehele schalen en een echte volle resolutie, wat met `stretch_shrink` (alleen gehele getallen) niet kan. De container stuurt input gewoon door naar de wereld.
- **SubViewport-instellingen.** De wereld heeft een eigen `World3D` (`own_world_3d`), `handle_input_locally` staat uit zodat afgehandelde input niet nog eens bij de HUD aankomt, en `audio_listener_enable_3d` staat aan voor 3D-geluid vanuit de camera.
- **Collision layers** hebben de Nederlandse namen uit de prompt (`wereld`, `speler`, `vijand`, `speler_hitbox`, `vijand_hitbox`, `interactie`, `tornado_grens`). In code gebruik je de Engelse constanten van `PhysicsLayers`.
- **Statische types worden afgedwongen**: `untyped_declaration` staat op *error*.
- **Toetsen** gebruiken de fysieke keycode, zodat WASD ook op andere toetsenbordindelingen goed zit. Dubbel tikken om te ontwijken komt in Fase 1, in code.
- **`docs/.gdignore`** zorgt dat Godot de referentieplaatjes in `docs/` niet importeert en niet in builds stopt.

### Aandachtspunten voor de volgende fases

- Gebruik voor muislook `InputEventMouseMotion.screen_relative`. `relative` wordt in de SubViewport geschaald door de retrofilter, waardoor de gevoeligheid per pixelgrootte zou verschillen.
- Werelden en dungeons komen in de SubViewport via `RetroScreen.set_world()`. HUD en menu's komen in een `CanvasLayer` in `Main.tscn`, buiten de viewport.
- De testscene `FilterTest.tscn` en het filterinfo-label linksboven zijn tijdelijk. Ze maken plaats voor de testarena (Fase 1) en de echte wereld (Fase 2).

### Open punten

- [x] **Git-identiteit en signing.** Waren niet ingesteld. Op verzoek van de eigenaar staan ze nu in de lokale config van deze repo: `J0C0M <caviagamer.2018@gmail.com>`, met SSH-signing via `~/.ssh/id_ed25519`. Voor het label "Verified" op GitHub moet die sleutel daar als *Signing Key* zijn toegevoegd.
- [ ] **`docs/reference/kaart_elst.png`** is op 19-11-2026 aangeleverd en de wereld volgt hem nu (zie *Kaart verwerken*). De kaart zelf staat nog niet in de repo: eerst moet duidelijk zijn waar hij vandaan komt.
- [ ] **`docs/reference/Klaas_sigma.png`** staat lokaal klaar, maar is nog niet gecommit. De repo is openbaar, dus de foto zou dan voor iedereen zichtbaar zijn. De eigenaar beslist.
- [ ] Godot staat niet in de `PATH`. Controles draaien met `~/Downloads/Godot_v4.7.2-stable_linux.x86_64`.
- [ ] `gh` is niet geïnstalleerd. Merges naar `Development` gaan dus met `git merge` in plaats van via een PR.
- [ ] In de root staat een ongetrackte map `new-game-project/` (een leeg Godot-project uit de projectmanager). Godot slaat hem over, maar meldt bij elke import "Detected another project.godot". De eigenaar kan hem weggooien.

## Fase 1 – Speler & combat

### Wat is af

- **Componenten:** `HealthComponent`, `StaminaComponent`, `Hitbox`, `Hurtbox` (met `HitData`), `StateMachine` en `State`.
- **Data:** `PlayerStats` (`data/player/player_stats.tres`), `ItemData` (roestig zwaard, gewone kleding) en `EnemyData` (trainingspop, sparringpop).
- **Speler** (`scenes/player/Player.tscn`) met de states Move, Dodge, Attack, Block, Hurt en Dead:
  - lopen (4,5 m/s), sprinten (7,5 m/s, 15 stamina/s), springen;
  - ontwijken met Alt of dubbel tikken: een rol van 4,5 m in 0,5 s, kost 20 stamina, de eerste 0,3 s onkwetsbaar;
  - lichte aanval (10 schade) met een tweede slag als combo (×1,25 = 13), zware aanval door vast te houden (×1,8 = 18, 25 stamina);
  - blokkeren (70% minder schade van voren, 15 stamina per geblokte klap) en parry (blok binnen 0,2 s voor de klap);
  - geraakt worden (korte stagger en terugduw), doodgaan en terugkomen.
- **Model** (`PlayerModel.tscn`): losse blokken voor hoofd, romp, armen, benen en zwaard, met animaties in code voor stilstaan, lopen, sprinten, springen, de drie slagen, blokkeren, parry, rollen, geraakt worden en doodgaan.
- **Camera** (`PlayerCamera.tscn`): third person over de rechterschouder, muislook, spring arm tegen muren.
- **HUD** (`scenes/ui/HUD.tscn`): balken voor HP en stamina linksonder. De staminabalk knippert rood als er te weinig stamina is. Daarnaast "Parry!" bij een parry en "Je bent dood" bij doodgaan.
- **Trainingspoppen** (`scenes/enemies/TrainingDummy.tscn`): wiebelen bij een klap, tonen een levensbalk boven het hoofd, vallen bij 0 HP in stukken uit elkaar en staan na 4 s weer op. De sparringpop (rode band) draait naar je toe en slaat elke 2 s met een knuppel (10 schade). Hij kondigt dat 0,7 s vooraf aan: de knuppel gaat omhoog en de zak kleurt rood.
- **Testarena** (`scenes/world/TestArena.tscn`) als startwereld: zandring met twee poppen, muren, kratten, een helling met platform en pilaren voor de camera. Rechtsboven staat een uitleg van de besturing.
- **Tests:** `tests/check_resources.gd` laadt alles; `tests/test_player_combat.gd` speelt de arena en controleert 30 dingen (allemaal geslaagd).

### Keuzes en afwijkingen

- **Combo:** het GDD zegt alleen "twee keer achter elkaar geeft een combo". De tweede slag doet ×1,25 schade en gaat de andere kant op.
- **Zware aanval:** telt als je de knop 0,25 s vasthoudt. Is er te weinig stamina, dan wordt het een lichte slag en knippert de staminabalk.
- **Stamina:** lichte slagen en springen zijn gratis, want het GDD noemt alleen sprinten, zware aanval, ontwijken en blokkeren. Is de stamina op tijdens het sprinten, dan sprint je pas weer na het loslaten van Shift.
- **Blokkeren:** elke geblokte klap kost 15 stamina. Zonder genoeg stamina breekt je blok: volle schade en 0,8 s stagger. "Van voren" betekent binnen 75° van je kijkrichting.
- **Parry:** alleen een verse druk op blokkeren telt, niet een blok dat je al vasthield. De aanvaller staat zo lang uit balans als zijn `EnemyData` zegt (sparringpop 1,6 s).
- **Doodgaan:** opslaan bestaat nog niet, dus in de testarena kom je na 3 s terug op het startpunt. In Fase 3 wordt dat "de laatste save laden".
- **Sparringpop:** staat niet in het GDD. Zonder iets dat terugslaat zijn blokkeren, parry en ontwijken niet te testen.
- **Muis:** wordt gevangen zodra het venster focus heeft. Esc geeft hem vrij, tot het pauzemenu er is (Fase 3). Een klik vangt hem weer en telt dan niet als aanval. De muisgevoeligheid (0,15° per pixel) staat in `Settings` en wordt bewaard; het instellingenmenu volgt in Fase 3.
- **Physics interpolation** staat aan, zodat bewegen soepel is op schermen boven 60 Hz. Daarom animeert alles in `_physics_process` en volgt de camera de geïnterpoleerde positie.
- **Pantser:** wordt al meegerekend bij schade (gewone kleding: 0%).
- **Levensbalk boven vijanden:** staat in de 3D-wereld, dus de retrofilter maakt hem ook pixelig. Bij volle HP is hij verborgen.
- **Animaties** staan in code (keyframes per pose), zonder `AnimationPlayer`. Een later Blender-model kan dezelfde `play_action()`-namen krijgen.
- `FilterTest.tscn` is niet meer de startwereld. In Fase 2 is hij weggehaald.

### Aandachtspunten voor de volgende fases

- Vijanden in Fase 4 kunnen `HealthComponent`, `Hitbox`, `Hurtbox` en `StateMachine` overnemen zoals de trainingspop en de speler dat doen. `Hitbox.parried` is het signaal om uit balans te raken.
- Na een teleport of het laden van een save: `reset_physics_interpolation()` op de verplaatste node en `camera.snap_behind_target()` voor de speler (zie `Player.respawn()`).

## Fase 2 – Wereld van Elst (blockout)

### Wat is af

- **Open wereld** `scenes/world/Elst.tscn`, ongeveer 470 × 470 m binnen de tornado, met:
  - wegen van de kerk naar elke locatie en een ring van wegen eromheen;
  - woonstraten met 113 huizen en 261 bomen;
  - het spoor van noord naar zuid met overwegen;
  - weilanden in de buitenring, een industrieterrein achter het station en de Aamsche Plas.
- **Zes kernlocaties** als eigen scenes in `scenes/world/locations/`, in de factiekleuren:
  - de Kerk van Amber met toren, spits en amberkleurige banieren; de deur zit op slot;
  - het huis van Klaas met tuin en heg; hier begin je;
  - Bingo Club Boomer Cave, een blauwe hal met een rotsige grotingang en een BINGO-bord;
  - Elst Station met perron, overkapping, stationsgebouw en het gebouw ernaast met generators;
  - Westeraam Getho, vier gele en zwarte flats rond een plein;
  - OBC Elst Fort, een school met torens, een muur, een poort en een voetbalveld.
- **Tornado** (`Tornado.tscn`) als ring rond de kaart:
  - twee draaiende stofmuren met een eigen shader en rondvliegend puin, van overal te zien;
  - vanaf 222 m duwt de wind je terug (harder dan sprinten) en verschijnt "De tornado is te sterk. Je kunt Elst niet ontsnappen.";
  - een vaste muur op 240 m houdt iedereen binnen.
- **Mist en licht:** een amberkleurige, wat sombere lucht met mist, zodat de tornado in de verte vervaagt. Een zon met schaduwen tot 140 m.
- **Navigatiemesh:** wordt bij het laden van Elst in ongeveer 0,3 s op een thread gebakken. Er lopen paden van het huis van Klaas naar alle vier de dungeoningangen.
- **Dungeoningangen en lege dungeons:**
  - E voor een deur fadet naar zwart en zet je in de dungeon (`scenes/dungeons/Station`, `Westeraam`, `OBC` en `BingoCave`);
  - elke dungeon is een lege kamer in de factiekleuren met een bord ("dungeon volgt in fase …") en een deur terug naar dezelfde ingang in Elst;
  - HP en stamina gaan mee.
- **Systemen:**
  - `Interactable` met de prompt "[E] …" op de HUD;
  - meldingen op het scherm;
  - `LocationArea` met de plaatsnaam groot in beeld als je een locatie binnenloopt;
  - `GameWorld` met spawnpunten en terugkomen na de dood;
  - wereldwissels met een fade in `Main`.
- **Test:** `tests/test_world.gd` controleert het startpunt, de navmesh, de kerkdeur, de tornado en alle vier de dungeons heen en terug (allemaal geslaagd).

### Keuzes en afwijkingen

- **Kaart:** `kaart_elst.png` ontbreekt nog steeds. Ik heb de voorlopige indeling hieronder gebruikt. OBC en Westeraam staan dichter bij het midden dan eerst gepland, want op de oude plek lagen ze bijna in de tornado.
- **Industrieterrein en Aamsche Plas** staan niet in het GDD, maar passen bij het echte Elst en vullen de oostkant. De plas heeft een onzichtbare oever, dus je kunt er niet in lopen.
- **De kerk** heeft nog geen interieur. De deur meldt dat hij op slot zit tot de drie facties verslagen zijn. Fase 11 koppelt dat aan `GameState`.
- **Het huis van Klaas** is in deze fase alleen van buiten. Klaas zelf, het interieur, de winkel en slapen komen in Fase 5.
- **Doodgaan** brengt je terug op het startpunt van de wereld waar je bent (in een dungeon de ingang). Fase 3 vervangt dat door "de laatste save laden".
- **Navmesh:** wordt bij het laden gebakken in plaats van als bestand in de repo te staan. Zo blijft hij kloppen terwijl de blockout nog verandert. Het mesh-resource wordt gedeeld, dus terugkomen in Elst bakt niet opnieuw.
- **Huizen en bomen** bouwen hun mesh in code met vertexkleuren. Zo is elk prop één draw call. In de editor blijven het gewone nodes die je kunt verplaatsen, met `size` en kleuren in de inspector.
- **`Elst.tscn`** is één keer met een script gegenereerd (wegen, huizen, bomen en weilanden op basis van een vaste seed). Sinds *Kaart verwerken* staat de generator wel in de repo (`tools/map/gen_elst.py`).
- **De testarena** is gebleven als losse scene om combat te testen (open hem in de editor en druk op F6). Het spel start nu in Elst.

### Aandachtspunten voor de volgende fases

- Fase 3 (opslaan) kan `GameState.current_location` gebruiken als locatienaam in de save, en moet `Player.save_data()` uitbreiden met positie en rotatie.
- Vijanden (Fase 4) kunnen meteen de navmesh van Elst gebruiken. Nieuwe statische geometrie moet onder een node in de groep `navigation_source` komen.
- Bevrijde gebieden (Fase 8) kunnen per locatiescene dorpelingen en een warmere kleur krijgen. De `LocationArea` per locatie heeft daarvoor al een `id`.

## Fase 3 – Opslaan & menu's

### Wat is af

- **SaveManager:**
  - eigen saves met een naam (onbeperkt aantal);
  - één quicksave: F5 slaat op, F9 laadt;
  - drie autosaves die om de beurt worden overschreven, gemaakt bij het binnengaan van een dungeon.
- **Elke save** is een JSON-bestand in `user://saves/` met een screenshot van 192×108 ernaast. Erin staan:
  - `save_version`;
  - metadata: soort, naam, datum, plaats en speeltijd;
  - de wereldscene, `GameState` en `QuestManager`;
  - de data van nodes in de groep `persist`: nu de speler, met positie, draaiing, camerahoek, HP en stamina.
- **GameState** houdt nu ook goud, Inwijding, bevrijde gebieden, de kerkdeur, vlaggen (kisten, generators) en de speeltijd bij. Opslaan kan geblokkeerd worden met een reden.
- **Doodgaan** laadt na 3 s de nieuwste save. Is er nog geen save, dan begin je opnieuw bij het startpunt.
- **Hoofdmenu** met Elst op de achtergrond: een camera draait langzaam rond de kerk. Knoppen: Doorgaan, Nieuw spel, Laden, Instellingen en Afsluiten.
- **Pauzemenu** (Esc): het spel staat stil. Knoppen: Verder spelen, Opslaan, Laden, Instellingen, Naar hoofdmenu en Afsluiten.
- **Opslaan- en laadmenu:** een lijst met screenshot, naam, plaats, datum en speeltijd. Je kunt overschrijven, laden en verwijderen (met "Zeker?").
- **Instellingen:**
  - retrofilter, pixelgrootte en volledig scherm;
  - muisgevoeligheid;
  - volume voor alles, muziek en effecten (audiobussen `Music` en `SFX`).
  - Alles wordt meteen toegepast en bewaard.
- **Menuthema** (`scenes/ui/menu_theme.tres`) in de kleuren van Amber: donker met amberkleurige randen.
- **Test:** `tests/test_save.gd` (23 checks, allemaal geslaagd). De wereldtest en de combattest slagen nog steeds.

### Keuzes en afwijkingen

- **Screenshot in de save:** komt uit de 3D-wereld zelf, zonder HUD en menu's, en dus ook met de retropixels. Headless (in tests) is er geen screenshot.
- **Niet opslaan:** dat kan niet in de lucht, als je dood bent of tijdens een wereldwissel. Baasgevechten en scènes kunnen opslaan blokkeren met `GameState.block_saving()`. Het pauzemenu zet de knop Opslaan dan uit.
- **Laden:** zet eerst `GameState` en `QuestManager` terug, daarna komt de wereld. Zo kan een wereld in `_ready()` al zien wat er bevrijd is.
- **Volume:** de schuiven werken al op de audiobussen, maar er is nog geen geluid (Fase 12).
- **Volledig scherm** staat er als extra instelling bij. Het GDD noemt het niet, maar het is handig.
- **Autosave:** alleen bij dungeons, want quests (Fase 6) en slapen bij Klaas (Fase 5) bestaan nog niet. Daar hoeft straks alleen `SaveManager.autosave()` bij.
- **Escape** opent nu het pauzemenu en geeft de muis niet meer zomaar vrij. In menu's is de muis vrij.
- **Het label met filterinfo** linksboven is weg; de filter staat nu in de instellingen. F1 en F2 werken nog wel.
- **Een `-s`-test** wordt gecompileerd voordat de autoloads bestaan. De tests zetten daarom `SaveManager.save_dir` via `root.get_node("SaveManager")`, en de echte saves blijven onaangeraakt.

### Aandachtspunten voor de volgende fases

- Nieuwe dingen die bewaard moeten blijven:
  - kisten en generators: een vlag in `GameState` (`set_flag`);
  - nodes met eigen toestand: in de groep `persist` met `save_data()` en `load_data()`.
- Fase 5 breidt `Player.save_data()` uit met goud en uitrusting, of zet die in `GameState`.

## Fase 4 – Vijanden & loot

### Wat is af

- **Basisvijand** `scenes/enemies/Enemy.tscn` met een state machine:
  - Idle → Patrol (willekeurige plek rond huis) → Chase → Attack, plus Retreat, Stagger en Dead;
  - zintuigen: een zichtkegel met zichtlijn, gehoor dichtbij, en 360° zicht zodra hij je kent;
  - een groep van dezelfde factie waarschuwt elkaar;
  - navigatie met `NavigationAgent3D` en ontwijken van elkaar;
  - aanvallen met een duidelijke aanloop: de arm gaat omhoog, daarna de klap;
  - een parry zet hem uit balans; een treffer duwt hem iets terug;
  - een levensbalk boven het hoofd.
- **Laag driller** (leger van Amber, rond het station): 30 HP, 6 schade, grijs trainingspak met oranje strepen, pet en plank. Valt aan in een groepje van drie.
- **Driller** (Westeraam): 40 HP, 8 schade, zwarte puffer met gele rits, muts, vuisten. **Flankeert**: loopt eerst om je heen naar je zijkant en valt dan aan.
- **Terugtrekken:** wie je 5 s niet ziet, of te ver van huis raakt, loopt terug naar huis en heeft daar weer volle HP.
- **Doodgaan:** de vijand valt om, laat buit vallen, meldt `EventBus.enemy_killed` en zakt na 4 s weg. Na laden staan alle vijanden er weer.
- **Buit:**
  - `LootTable` met goud van-tot en items met een kans;
  - een vijand geeft 3–10 goud en heeft 5% kans op een kleine healing potion;
  - munten en drankjes springen eruit en vliegen naar je toe als je dichtbij komt.
- **Kisten** (`scenes/world/props/Chest.tscn`): openen met E (20–40 goud). Een open kist blijft open na opslaan en laden (vlag in `GameState`).
- **GameState:** goud en een inventaris (maximaal 10 potions), beide in de save.
- **HUD:** goud en drankjes boven de balken, en een korte regel voor alles wat je oppakt ("+7 goud").
- **Waar ze staan:**
  - in Elst drie laag drillers ten noorden van het station en twee drillers op de weg naar Westeraam;
  - in de stationdungeon drie laag drillers en een kist;
  - in de Westeraam-dungeon twee drillers en een kist.
  - Alle vier de dungeons bakken nu een navmesh.
- **Gedeeld model:** `PlayerModel` heet nu `HumanoidModel` (`scripts/characters/humanoid_model.gd`), voor speler en vijanden. Er zijn twee nieuwe acties bij: `enemy_windup` en `punch`.
- **Test:** `tests/test_enemies.gd` (21 checks, allemaal geslaagd). De vier andere tests slagen nog steeds.

### Keuzes en afwijkingen

- **Terugtrekken** (uit het GDD) betekent hier: terug naar huis als de speler ontkomt, en daar genezen. Vijanden vluchten dus niet bij weinig HP.
- **Laag drillers** horen bij het leger van Amber (factie `amber`) en hebben daarom de oranje accentkleur. Drillers zijn van Westeraam: geel en zwart.
- **Wapens:** laag drillers hebben een plank en drillers hun vuisten. Er zijn bewust geen messen of vuurwapens.
- **Uitrusting als buit** (kist 8%, baas 35%, "altijd het volgende item dat je nog niet hebt") komt in Fase 5, samen met inventaris en uitrusting. `LootTable` kan dat straks via een `LootEntry`.
- **Potions** kun je al oppakken, maar drinken met Q komt in Fase 5.
- **Buit op de grond** wordt niet opgeslagen. Na laden staan de vijanden er weer en laten ze opnieuw iets vallen.
- **Plaatsing:** de vijanden en kisten in Elst en de twee dungeons zijn tijdelijk, om te testen. Fase 7 en 8 bouwen die dungeons echt uit, en Fase 8 laat patrouilles verdwijnen na een bevrijding.
- **Doodgaan en herladen** van de speler bestond al sinds Fase 3. Deze fase test vooral dat de vijanden na laden terug zijn.

### Aandachtspunten voor de volgende fases

- Fase 5: drankjes drinken met Q, uitrusting als buit (`LootEntry` met een "volgende uitrusting"-regel) en de winkel. Goud staat al in `GameState`.
- Fase 7: het verzwakkingseffect (20% minder HP voor Westeraam en OBC). Dat kan in `Enemy._ready()` met een vlag in `GameState`.
- Fase 8: geen patrouilles meer na een bevrijding. Zet de vijanden per gebied onder een node die naar `GameState.liberated_areas` kijkt.
- Nieuwe vijanden: maak een `EnemyData` met een `model_scene` en een instantie van `Enemy.tscn`. Afstandsvijanden (vape-drillers, voetballers) hebben een eigen aanvalsstate nodig.

## Fase 5 – Klaas, dialoog & winkel

### Wat is af

- **Klaas** (`scenes/npcs/Klaas.tscn`, model `KlaasModel.tscn`): lang, breed en gespierd, met een strak paars shirt, blond haar met een kuif, een strakke kaak, een zwarte zonnebril en een gouden ketting. Hij draait naar je toe als je in de buurt komt, praat als je op E drukt en "flext" bij zijn begroeting.
- **Huis van Klaas:** de voordeur in Elst leidt naar het interieur (`scenes/world/interiors/KlaasHouse.tscn`). Daar staan Klaas achter een toonbank, een bed, een halterrek, een spiegel en eiwitshakes op de plank.
- **Dialoogsysteem:** `DialogueData` met regels, keuzes, voorwaarden (Inwijding, vlaggen) en acties. Het dialoogvenster typt de tekst uit en toont genummerde keuzes. Klaas' gesprek staat in `data/dialogue/klaas.tres`: een eerste kennismaking, het verhaal over Amber, de zonnebril, de winkel en slapen. Hij begroet je anders als je hem al kent, en nog anders vanaf Inwijding 3.
- **Winkel:**
  - alles uit de tabel in het GDD, met prijzen;
  - dicht tot Inwijding 1, elk item vanaf zijn eigen Inwijding-niveau;
  - wat je koopt en beter is, trek je meteen aan;
  - oude uitrusting verkoop je voor 40% (gedragen spullen niet);
  - maximaal 10 drankjes.
- **Inventaris (Tab):** wat je draagt per slot, al je spullen met "Aantrekken", je drankjes, goud en Inwijding.
- **Uitrusting zichtbaar:** het zwaard krijgt de lengte en kleur van het item (roestig, ijzer, staal, het paarse zwaard van Klaas). Pantser toont een vest (leer), schouderstukken (ijzer) en een helm (staal). Pantser haalt ook echt schade af.
- **Drankjes:** Q drinkt het drankje dat het beste past (klein +40, groot +100). Tijdens het drinken loop je langzaam. Word je geraakt voordat het drankje werkt, dan houd je het.
- **Slapen** in het bed (of via Klaas): je bent weer helemaal fit en er komt een autosave.
- **Buit:** een kist heeft 8% kans op het volgende zwaard of pantser dat je nog niet hebt. Je vindt dus nooit iets slechters. Het item ligt dan als zwaardje op de grond.
- **Opslaan:** uitrusting, Inwijding en vlaggen gaan mee in de save.
- **Test:** `tests/test_klaas.gd` (36 checks, allemaal geslaagd). De andere vijf tests slagen nog steeds.

### Keuzes en afwijkingen

- **Tijdelijke Inwijding 1:** volgens het GDD opent de winkel pas na Quest 1. Die quest komt in Fase 6. Tot dan kun je in het eerste gesprek kiezen voor "Wijd me dan in", en dat geeft Inwijding 1. Fase 6 haalt die keuze weg en geeft de Inwijding als beloning van de tutorial.
- **Startuitrusting:** je begint met het roestige zwaard en gewone kleding. Het GDD noemt het roestige zwaard ook als beloning van Quest 1; Fase 6 beslist of je eerst zonder zwaard begint.
- **Interieur:** het huis van Klaas is een eigen scene (zoals een dungeon, maar zonder autosave bij binnenkomst), zodat er plek is voor een bed en een toonbank.
- **Pauze:** gesprekken, de winkel en de inventaris zetten het spel op pauze. Vijanden kunnen je dan dus niets doen.
- **Klaas' zwaard en de kruisboog** zijn nooit buit (`can_drop` uit). De kruisboog is niet te koop; die krijg je in Fase 10.
- **Bazen** krijgen hun 35% kans op uitrusting in hun eigen fase, met dezelfde `NEXT_GEAR`-regel.

### Aandachtspunten voor de volgende fases

- Fase 6:
  - Quest 1 geeft Inwijding 1, 2 kleine drankjes en 20 goud. Verwijder dan de keuze "Wijd me dan in" uit `klaas.tres` (regels `task` en `hub`).
  - `DialogueCondition` krijgt voorwaarden voor de status van een quest.
  - Klaas' trotse regel ("eerder klaar dan gevraagd") past in dezelfde dialoog.
- Fase 11: Klaas als bondgenoot kan `KlaasModel.tscn` en het `HumanoidModel` hergebruiken.

## Fase 6 – Questsysteem & Quest 1

### Wat is af

- **Questdata:** `QuestData` (titel, omschrijving, doelen, beloning, `completion_flag`) en `QuestStep` met vier soorten doelen:
  - `FLAG`: een vlag in `GameState`, bijvoorbeeld uit een gesprek;
  - `ACTIONS`: dingen die de speler doet, zoals sprinten, springen, ontwijken, blokkeren, drinken of opslaan;
  - `KILL`: een aantal vijanden met een bepaald `EnemyData`-id;
  - `REACH`: een gebied of wereld binnengaan.
- **QuestManager** (autoload) laadt alles uit `data/quests/` en volgt de `EventBus`. Hij houdt per quest de status bij (niet begonnen, actief, af), het huidige doel en de voortgang ("1/2"). Bij elk afgerond doel komt er een melding en een autosave. Aan het eind volgt de beloning: goud, items of uitrusting, en Inwijding +1. Alles gaat mee in de save.
- **Quest 1 "Inleiding"** (`data/quests/q1_tutorial.tres`):
  1. praat met Klaas in zijn huis (hij geeft je het roestige zwaard);
  2. sprint, spring en ontwijk in de tuin;
  3. sla de trainingspop kapot;
  4. blokkeer een klap van de sparringpop (die slaat terug);
  5. drink het drankje dat Klaas je geeft;
  6. sla je spel op (F5 of via het pauzemenu);
  7. oefengevecht tegen 2 laag drillers, die pas op dat moment in de tuin verschijnen;
  8. ga terug naar Klaas. Hij opent zijn winkel en geeft 20 goud, 2 kleine drankjes en Inwijding 1.
- **Tuin van Klaas:** een trainingspop, een sparringpop met een knuppel en een `QuestSpawner` voor het oefengevecht.
- **Kompas** bovenin beeld: windrichtingen die meedraaien met de camera, en een gouden ruit met de afstand naar het huidige doel. Doelen zijn `QuestMarker`-nodes met een of meer ids. Binnen bij Klaas wijst het kompas naar de deur als het doel buiten ligt.
- **Huidig doel in de HUD:** onder het kompas, met de voortgang erbij ("Inleiding: Oefengevecht ... (1/2)").
- **Questlog (J):** actieve en afgeronde quests, de omschrijving, de doelen (✓ af, ▶ huidig) en de beloning. Het spel pauzeert zolang hij open is.
- **Klaas praat over de quest:** een eerste kennismaking, een duwtje naar het questlog zolang de tutorial loopt, en een trotse regel als je klaar bent. Daarna kun je naar zijn winkel, of vragen of hij nog een klus heeft ("nog niet", tot Fase 7).
- **Test:** `tests/test_quests.gd` (32 checks, allemaal geslaagd) speelt Quest 1 van een nieuw spel tot de beloning, met opslaan en laden halverwege en aan het eind. De andere zes tests slagen nog steeds.

### Keuzes en afwijkingen

- **Je begint zonder zwaard.** Klaas geeft het roestige zwaard in het eerste gesprek, niet pas als beloning aan het eind: anders kun je de zwaardles niet doen. Probeer je zonder zwaard aan te vallen of te blokkeren, dan zegt de HUD dat je eerst met Klaas moet praten. In de testarena krijg je het zwaard meteen (`test_gear` op `GameWorld`).
- **De rest van de beloning** (20 goud, 2 kleine drankjes, Inwijding 1) komt aan het eind, zoals in het GDD. De tijdelijke keuze "Wijd me dan in" uit Fase 5 is weg.
- **Drinken mag nu ook met volle HP.** Anders kan de drankles vastlopen. Het drankje is dan gewoon op.
- **De winkel** legt Klaas uit in zijn laatste regel, en het gesprek gaat daarna meteen naar de keuze "Laat je winkel zien". Er is geen apart doel "koop iets", want je hebt dan nog te weinig goud.
- **"Eerder af dan gevraagd":** een quest met een `completion_flag` die al gezet is, is meteen af zodra Klaas hem geeft, met de beloning erbij. Fase 8–10 zetten die vlag als de baas verslagen is; Klaas' trotse regel komt in die fases.
- **Autosave na een doel** gebruikt `SaveManager.request_autosave()`. Kan opslaan op dat moment niet (in de lucht, tijdens een wereldwissel), dan probeert hij het elke halve seconde opnieuw.
- **Oude saves** van voor Fase 6 hebben geen questdata. Ze laden gewoon, maar Quest 1 start dan niet. Begin een nieuw spel om de tutorial te spelen.
- **Quests 2 t/m 6** komen in hun eigen fase. Klaas zegt tot dan "nog niet" als je om een klus vraagt.

### Aandachtspunten voor de volgende fases

- Een nieuwe quest is een `.tres` in `data/quests/`. Geef doelen een `target` en zet een `QuestMarker` met dat id in de wereld, dan werkt het kompas vanzelf.
- Klaas geeft de volgende quest met de dialoogactie `start_quest`, met de id van de quest als `action_value`. Voorwaarden in `DialogueCondition` kunnen kijken naar de status en het huidige doel van een quest.
- Fase 7: Quest 2 eindigt na 4 generators (`KILL` of `FLAG` per generator) en zet het verzwakkingseffect aan.
- Fase 8–10: zet bij de dood van de baas de `completion_flag` van de quest, zodat de dungeon ook telt als Klaas hem nog niet gegeven heeft.

## Fase 7 – Quest 2: Station Elst

### Wat is af

- **Station-dungeon** (`scenes/dungeons/Station.tscn`, gebouwd door `tools/dungeons/gen_station.py`). Vijf ruimtes, van de ingang naar achteren:
  - de stationshal met poortjes en een kiosk (2 laag drillers);
  - de perronhal met pilaren, het spoor en een geparkeerde wagon *AMBER EXPRESS* (3 laag drillers, generator 1);
  - een werkplaats aan de westkant (2 laag drillers, generator 2 en een kist);
  - de spoortunnel met rood licht (2 laag drillers, generator 3);
  - het aanvoerdepot van Amber: zwaar bewaakt door 6 laag drillers, met generator 4 op een verhoging en een kist.
- **Generators** (`scenes/world/props/Generator.tscn`, 60 HP): je slaat ze kapot met het zwaard. Een kapotte generator wordt donker, helt over en geeft een rookwolk. Een vlag in `GameState` onthoudt dat, ook na laden. De `GeneratorGroup` telt af ("Nog 3 te gaan") en zet `station_cleared` zodra de laatste kapot is.
- **Quest 2 "De aanvoer van Elst kapotmaken"** (`data/quests/q2_station.tres`): Klaas geeft hem na Quest 1, bij "Heb je nog een klus?". Doelen: sla de vier generators kapot (de HUD telt 1/4) en ga terug naar Klaas. Beloning: 75 goud en Inwijding 2.
- **Verzwakkingseffect:** zodra het station plat ligt, hebben de drillers van Westeraam 20% minder HP (40 → 32). De laag drillers van Amber zelf niet. Het staat in de data: `weakened_by_flag` en `weakened_health_factor` in `EnemyData`.
- **Eerder klaar dan gevraagd:** sloop je het station voordat Klaas erom vraagt, dan merkt hij dat bij "Heb je nog een klus?". Hij is trots en je krijgt de beloning alsnog.
- **Kompas:** in Elst wijst het naar de deur van het gebouw naast het station, in de dungeon naar de dichtstbijzijnde generator die nog draait, en daarna naar de uitgang.
- **Questsysteem:** een nieuw soort doel, `FLAGS`: alle vlaggen gezet, in elke volgorde, ook als ze al eerder gezet waren. Het kompas kiest nu de dichtstbijzijnde markering.
- **Tests:** `tests/test_station.gd` (29 checks, allemaal geslaagd) speelt Quest 2 van de opdracht tot de beloning, met opslaan en laden in de dungeon en het geval dat je eerder klaar bent. De andere zeven tests slagen ook. `test_enemies` speelt nu in een eigen testkamer (`scenes/world/EnemyTestRoom.tscn`), en `test_save` gebruikt plekken naast de ingang.

### Keuzes en afwijkingen

- **Alleen laag drillers** in de station-dungeon, zoals in het GDD: in groepjes van twee of drie, en zes in het depot.
- **Een `completion_flag` maakt een actieve quest niet meer meteen af.** Dan beslissen de doelen, zodat je nog terugmeldt bij Klaas. Alleen als de vlag al gezet is wanneer Klaas de quest geeft, is hij meteen af.
- **Generators** gebruiken `EnemyData` voor hun HP (`data/enemies/station_generator.tres`).
- **De bevrijding van het station** ("station werkt weer, dorpelingen op het perron") komt met het systeem voor bevrijde gebieden in Fase 8.
- **Na Quest 2** zegt Klaas "Nog niet" als je om een klus vraagt, tot Fase 8.
- **Klaas' dialoog** wordt nu ook door een script in de repo gemaakt (`tools/data/gen_klaas_dialogue.py`). Pas dat script aan en draai het opnieuw, in plaats van `klaas.tres` met de hand te bewerken.

### Aandachtspunten voor de volgende fases

- Fase 8: `station_cleared` kan meetellen als bevrijding van het station. Geef de vape-drillers `weakened_by_flag = &"station_cleared"` en `weakened_health_factor = 0.8`. (Gedaan in Fase 8.)
- Fase 9: hetzelfde voor de voetbaljongens en de fatbikers. Of de bazen ook zwakker worden, beslissen we in hun eigen fase.
- Fase 10: de kruisboog komt van Klaas zodra Quest 2 t/m 5 af zijn.

## Fase 9 – Quest 4: OBC Elst Fort

### Wat is af

- **OBC-dungeon** (`scenes/dungeons/OBC.tscn`, gebouwd door `tools/dungeons/gen_obc.py`): ongeveer 70 × 190 m met 20 vijanden (Westeraam heeft er 18), in twee delen met een checkpoint ertussen.
  - Deel 1, de school: een grote aula zoals in het echte OBC (hoge witte hal, een houten zittrap, glazen galerijen op twee verdiepingen, ringlampen en groene banken), de kantine (kist), een gang met kluisjes en een grote gymzaal.
  - Checkpoint: de docentenkamer, met een autosave en een rustbank.
  - Deel 2, achter de school: het binnenplein waar fatbikers rondrijden (kist), het fietsenhok en het sportveld met de baas.
- **Kakker-voetbaljongens** (38 HP, 10 schade): rode polo, witte kraag, een navy trui over de schouders en blond haar. Ze houden afstand en schieten voetballen; 60% gaat recht op je af, de rest mist.
- **Fatbikers** (80 HP, 16 schade): rijden op een rood-zwarte fatbike, cirkelen om je heen (flankeren) en chargeren dan met hoge snelheid.
- **De fatbike** (`scenes/enemies/models/Fatbike.tscn`, gemaakt door `tools/models/gen_fatbike.py`): een low-poly fiets met frame, vork, spatborden, dikke banden met velgen, accu, koplamp en uitlaat. `fatbike.gd` kleurt de onderdelen per berijder: rood met zwart voor de fatbikers, zwart met donkergrijs voor het fatbike-kindje.
- **Nieuw in `EnemyData`:** `lunge_speed` (de charge van een fatbiker) en `accuracy` met `miss_angle` (hoe vaak een schot raak gaat).
- **Het fatbike-kindje** (450 HP, 25 schade per charge, `scenes/bosses/FatbikeKid.tscn`), na feedback van de eigenaar uitgebreid:
  - een klein, bleek jongetje met blauwe ogen bovenop een enorme, opgevoerde fatbike in zwart en donkergrijs (wielen van zo'n 2 m);
  - voor elke charge maakt hij een wheelie met een burn-out (rook van het achterwiel, vlammen uit de uitlaat) en roept hij iets kakkerigs ("Mijn vader is advocaat!", "Opzij, boomer!"), terwijl een rode lijn op de grond laat zien waar hij heen gaat; dan chargeert hij in een rechte lijn;
  - zijn opgevoerde motor laat een spoor van brandende plekken achter (8 schade, 4 s), dus je moet echt opzij en niet in zijn lijn blijven staan;
  - op de helft roept hij "JONGENS, HELP!" en komen er twee voetballers bij;
  - knalt hij tegen een muur, dan is hij 2,6 s versuft, en alleen dan kun je hem raken; het sportveld is 26 × 26 m, zodat je hem op tijd bereikt;
  - onder 50% chargeert hij twee keer achter elkaar, de tweede keer sneller;
  - tijdens het gevecht gaat het hek van het sportveld dicht en kun je niet opslaan; hij laat 100 goud vallen en heeft 35% kans op uitrusting.
- **OBC bevrijd:** in Elst spelen twee voetballers en een fatbiker op het schoolplein. Na het fatbike-kindje (`boss_fatbike_kindje`) lopen er dorpelingen.
- **Quest 4 "OBC Elst Fort"** (`data/quests/q4_obc.tres`): Klaas geeft hem na Quest 3. Doelen: versla het fatbike-kindje en ga terug naar Klaas. Beloning: 150 goud en Inwijding 4. Ook eerder verslagen telt.
- **Bugfix na de eerste test van de eigenaar:** een rek in de docentenkamer stond voor de deur naar deel 2, zodat je er niet langs kon. De tests merkten dat niet, omdat ze de speler verplaatsen. `test_world` loopt nu voor elke dungeon een route over de navmesh van de ingang naar het einde (laatste generator of baas). Op de oude OBC-scene faalt die check, op de nieuwe slaagt hij.
- **Bugfix:** boven de brede opening tussen het hoge binnenplein en de lage docentenkamer zat een gat in de muur (net als, kleiner, tussen de parkeergarage en de fietsenkelder in Westeraam). Een brede opening kan in `dungeon_builder.py` nu een bovenkant krijgen (`(midden, breedte, hoogte)`), en de muur daarboven wordt dichtgemaakt.
- **Tests:** `tests/test_obc.gd` (29 checks, allemaal geslaagd). De andere negen tests slagen ook.

### Keuzes en afwijkingen

- **Het motorgeluid** uit het GDD is voorlopig de tekst "VRRRRMMM!" boven zijn hoofd, en de fiets trilt. Echt geluid komt in Fase 12.
- **De voetballen** gebruiken hetzelfde script als de vapewolkjes, maar zijn sneller en verdwijnen meteen na een muur.
- **De fatbikers** rijden op een fiets, maar hun benen lopen nog mee (placeholder; staat ook bij de punten voor Prototype 2).
- **Moeilijkheid (besluit eigenaar):** de factie-dungeons worden steeds iets zwaarder: Westeraam, dan OBC, dan de Bingo Club. Het OBC heeft daarom meer vijanden dan Westeraam (20 tegen 18), zijn vijanden hebben iets meer HP en schade (fatbikers 80 HP), en het fatbike-kindje heeft 450 HP in plaats van de 350 uit het GDD (de Vape-koning heeft 400). Het GDD is bijgewerkt.
- **Het fatbike-kindje** is niet zwakker na het station, net als de Vape-koning.
- **Versuft 2,6 s in plaats van 3 s** (GDD), op verzoek van de eigenaar, samen met een kleiner sportveld, zodat het gevecht in balans blijft.
- **Na Quest 4** zegt Klaas "Nog niet" als je om een klus vraagt, tot Fase 10.

### Aandachtspunten voor de volgende fases

- Fase 10: de Bingo Club Boomer Cave wordt de zwaarste factie-dungeon (meer vijanden dan het OBC, Grumpy Oma sterker dan het fatbike-kindje), op dezelfde manier opgebouwd: groter dan het station, twee delen met een checkpoint, een `LiberatedArea` in `tools/map/gen_elst.py` en Quest 5 in `tools/data/gen_klaas_dialogue.py`. Daarna geeft Klaas de kruisboog (Quest 2 t/m 5 af).

## Fase 12 – Afwerking & build

### Wat is af

- **Eigen geluid en muziek** (`tools/audio/gen_audio.py`, `assets/audio/`): alles gesynthetiseerd met oscillatoren, ruis, envelopes en filters, dus eigen werk. 37 geluidseffecten (zwaardslagen, treffers, blokkeren en pareren, voetstappen, springen en landen, ontwijken, drankje, munten en spullen, kist, deur, generator, kruisboog en pijl, vijanden, vape, voetbal, fatbike-motor, schokgolf, vuuradem, drakengebrul, vleugels, inslagen, BINGO, quest af, doodgaan), een tornadowind-loop en vijf muziekloops: dorp, bezet gebied, dungeon, baasgevecht en het einde. Opnieuw maken: `python3 tools/audio/gen_audio.py` (met ffmpeg).
- **`AudioManager`:** kiest twee keer per seconde de muziek, met een crossfade: baasgevecht → `boss`; aftiteling, en het feest op het kerkplein na het einde → `ending`; in een dungeon → `dungeon`; in Elst binnen een locatie die nog bezet is → `occupied`; anders `village`. Dicht bij de tornado waait de wind, harder naarmate je dichter bij de ring komt. `play_sfx()` speelt een geluid overal, `play_sfx_at()` op een plek in de wereld (zachter op afstand).
- **Geluiden in het spel:** bij de speler (zwaard, ontwijken, springen, landen, voetstappen, treffers en blokken, drankje, kruisboog met herlaadklik), vijanden (treffer, dood en hun aanval: `EnemyData.attack_sound`), kisten, deuren, generators, pijlen, en alle bazen (de Vape-koning, het fatbike-kindje, Grumpy Oma en Amber). Muntjes, spullen, pareren, quest af en doodgaan via de `EventBus`.
- **Laadscherm** (`LoadingScreen.tscn`): bij elke wereldwissel, nieuw spel en het laden van een save verschijnt op het zwart de naam van de plek, een tip (15 tips) en een voortgangsbalk. De wereld laadt nu op de achtergrond, pas nadat het beeld zwart is (eerst haperde het beeld even vóór de overgang). In headless runs (de tests) laadt de wereld direct.
- **Export presets** (`export_presets.cfg`) voor Windows (`export/windows/Elst.exe`) en Linux (`export/linux/Elst.x86_64`), met de pck ingebakken; `tests/`, `tools/` en `docs/` gaan niet mee. Dev powers zitten alleen in debug-builds.
- **Na de eerste luisterbeurt van de eigenaar:** voetstappen zijn zachter, lager en dumper (een zachte plof in plaats van geruis) en klinken minder vaak; de deur is nu een klink, een zacht piepend scharnier, een zuchtje lucht en een gedempte dreun bij het dichtvallen; E spammen bij een deur speelt het geluid nog maar één keer (de deur wacht tot de overgang loopt).
- **Stemgeluidjes in gesprekken:** terwijl de tekst verschijnt, "praat" de spreker met een korte blip per paar letters, op de toonhoogte van zijn stem (`DialogueData.voice_pitch`; Klaas klinkt lekker diep), zoals in Undertale. Leestekens en spaties blijven stil.
- **Tests:** alle 11 testsuites slagen.

### Keuzes en afwijkingen

- **Balans:** geen grote wijzigingen in deze fase; de balans is tijdens Fase 10 en 11 al met de eigenaar bijgesteld. Verdere punten volgen uit het speeltesten.
- **Bij het afsluiten** meldt Godot dat er nog geluid in gebruik is (de muziek zit nog in de mixer). Dat is een melding van de engine zelf bij het afsluiten, niet tijdens het spelen.

### Open punten

- [ ] **Export templates:** Godot 4.7.2 heeft voor exporteren de export templates nodig (in `~/.local/share/godot/export_templates/4.7.2.stable/`). Die zijn nog niet geïnstalleerd; zonder kan er geen `.exe` of Linux-build gemaakt worden.
- [ ] De geluiden en muziek moeten nog beluisterd worden door de eigenaar: harder, zachter of anders kan in `gen_audio.py`.

## Fase 11 – Quest 6: Amber de Draak

Het plan staat in `docs/FASE_11_PLAN.md` (goedgekeurd door de eigenaar, met mijn adviezen voor de open beslissingen). Het werk gaat in drie blokken.

### Wat is af (blok A, de weg naar Amber)

- **Kerkdeuren en Quest 6:** `GameState` zet de vlag `church_open` zodra de drie factiebazen verslagen zijn, ook bij het laden van een oudere save. De kerkdeur gaat dan open. Quest 6 (`q6_amber.tres`) start vanzelf via het nieuwe `start_flag` van `QuestData`, met een melding van Amber "door de tornado" (`start_message`).
- **Doelen van Quest 6:** ga de kerk in, daal af naar het hart van de kerk, praat met Klaas, versla Amber samen met Klaas, en gebruik de Tren-spuit op Klaas. De laatste twee komen in blok B en C.
- **Dungeonbouwer:** ruimtes kunnen op hun eigen vloerhoogte liggen. Er zijn hellingen tussen de niveaus, gedraaide en gloeiende blokken, en een ronde ruimte (`round_room`). De vier oude dungeons komen er byte voor byte gelijk uit.
- **De kerk-dungeon** (`tools/dungeons/gen_kerk.py`, `scenes/dungeons/Kerk.tscn`), de grootste dungeon met 28 vijanden van alle facties:
  - **0 m, de kerk:** het portaal, het schip met banken en een rode loper, zijbeuken achter arcades, glas-in-lood en banieren, het koor met altaar, kaarsen, preekstoel en orgel, en de sacristie met de trap.
  - **−5 m, de crypte:** grafnissen, een grafkamer met sarcofagen, een doodlopende kamer met een kist en een hinderlaag.
  - **−10 m, de catacomben:** een kruispunt, een lange gang naar een doodlopende kamer met een kist, en een brede tunnel waar de fatbikers kunnen chargeren. Amberkleurige scheuren en fakkels.
  - **−15 m, de voorkamer:** checkpoint met autosave, een rustbank, Klaas en de poort naar de ronde arena (44 m doorsnee, 5 pilaren, een gloeiend hart).
- **Vijanden:** even sterk als in hun eigen dungeon. 85% kijkt naar de deur waardoor de speler binnenkomt.
- **Feedback van de eigenaar op blok A, verwerkt:**
  - **Ontbrekende muren:** waar een smalle trap op een bredere ruimte uitkwam, of een lage ruimte op een hogere, bleef een stuk muur open. Nu zijn de trappen 6 m breed, net als hun deuren, en bouwt steeds de hogere of bredere ruimte de muur. `open_sides()` in `dungeon_builder.py` controleert dat geen zijde open blijft; `gen_kerk.py` stopt als dat toch gebeurt. De vier andere dungeons zijn ook gecontroleerd: alles dicht.
  - **Het tweede deel was saai:**
    - De Amber-cultisten en draakjes uit het plan zijn erbij.
    - De catacomben zijn een hoge grot met schedelwanden, amberkristallen en stalactieten.
    - Het heiligdom van Amber heeft een drakenkop als afgodsbeeld, banken, kaarsen, cultisten en een kist.
    - In de fietstunnel staan twee vuurroosters die om de beurt opvlammen, met puin en schedels.
    - Bij de arenapoort staan drakenbeelden met vuurschalen.
    - De onderste lagen zijn veel lichter. Nu 36 vijanden.
  - **Amber-cultisten** (40 HP, 8 schade, met een staf): hun gezang ("AMBER! AMBER!") maakt om de 6 s alle vijanden binnen 10 m woest (+25%, 5 s), van elke factie.
  - **Draakjes** (30 HP): vliegen op ~3,6 m hoogte, cirkelen om je heen en spugen vuurballen. Af en toe duiken ze om te bijten, en alleen dan raakt je zwaard ze. De kruisboog raakt ze altijd.
- **Klaas bij de arena:** een eigen gesprek (`klaas_church.tres`) met tips, de winkel (kopen en verkopen) en "Ik ben er klaar voor". Dat zet `klaas_ready`, en dan gaat de arenapoort (`FlagGate`) open. Tijdens Quest 6 is Klaas niet thuis zodra er geen andere quest meer op hem wacht; op zijn plek ligt een briefje. Thuis vraag je hem "Wat nu met Amber?".
- **Fix: balans van de drillers** (eigenaar):
  - Laag drillers hebben 20 HP (was 30): met het roestige zwaard dood in twee slagen.
  - Drillers hebben 58 HP (was 40), na het station 46: met het ijzeren zwaard dood in drie slagen.
- **Fix: slimmere zintuigen, maar niet te slim** (eigenaar):
  - Vijanden horen je binnen 6 m (was 4).
  - Dichtbij zien ze ook vanuit hun ooghoek (160°).
  - Ze kijken naar je hoofd én borst, zodat een bankje je niet meer verbergt.
- **Fix: waarschuwen** (eigenaar): een vijand die je opmerkt of die je in de rug slaat, waarschuwt zijn buren één keer.
  - Station en Westeraam: alleen binnen 7 m, zonder kettingreactie, dus geen hele kamer tegelijk.
  - OBC en Bingo Club (`alert_chain`): de waarschuwing gaat door, zodat een hele kamer op je af kan komen, zoals eerst.
- **Tests:** `tests/test_amber.gd` (20 checks na blok A). `test_world` loopt de route door de kerk tot Klaas. `test_enemies` controleert het waarschuwen. `test_station` gebruikt de nieuwe HP.

### Wat is af (blok B, het gevecht)

- **Amber-model** (`tools/models/gen_amber.py`, `AmberModel.tscn`, `amber_model.gd`): een draak van zo'n 12 m. Ze heeft een romp met stekels, een lange nek en een kop met hoorns, gloeiende ogen, een kaak die opengaat en een keel die gloeit. Verder vleugels met vliezen, een staart in drie delen en vier poten. Haar houdingen: rust, inademen, vuuradem, hijgen, staart, vleugels, vliegen, versuft en dood.
- **Klaas als bondgenoot** (`KlaasAlly.tscn`, `klaas_ally.gd`):
  - Na "Ik ben er klaar voor" stapt de Klaas bij de poort opzij (`leave_on_flag`) en volgt de bondgenoot je.
  - In het gevecht loopt hij naar Amber en slaat haar om de 1,6 s voor 14 schade. Amber kiest hem in 35% van haar aanvallen.
  - Raakt ze hem, dan wankelt hij en roept iets ("Is dat alles, hagedis?"). Als ze vliegt, roept hij "Pak je kruisboog!".
- **Amber, balk 1** (`Amber.tscn`, `amber.gd`, `amber.tres`, 2 × 800 HP). Elke aanval wordt aangekondigd:
  - **Vuuradem:** 0,8 s inademen, dan 2 s een kegel vuur tot 14 m, 8 schade per kwart seconde. Een pilaar ertussen houdt het tegen. Daarna hijgt ze 2 s met haar kop laag, en dan doet een klap op haar kop dubbele schade.
  - **Staart:** een zwiep (20 schade) naar wie naast of achter haar staat.
  - **Vleugels:** 2,5 s wind die je wegblaast; een pilaar beschermt je ook dan.
  - **Vliegen:** om de 25 s vliegt ze op en spuwt ze vuurballen (`AmberMeteor`): een rode ring, 1 s later de inslag (18 schade) met een brandende plek. Een pilaar vangt ze op. Drie kruisboogpijlen (90 schade) halen haar neer; versuft ligt ze 4 s, met haar kop dubbel kwetsbaar. Anders landt ze na 12 s.
  - Een klap die kop en lijf allebei raakt, telt één keer.
- **De overgang** (`scripts/cutscene/cutscene.gd`, `EventBus.subtitle_requested`, ondertitels onderin de HUD):
  1. Als balk 1 leeg is, laadt Amber een vuurbal op de speler.
  2. Klaas springt ertussen, wordt geraakt en valt (`klaas_fallen`).
  3. Na een paar regels tekst begint balk 2.
  - Tijdens de scène beweegt de speler niet en kan niet opslaan.
- **Amber, balk 2:**
  - Ze is woedend: 30% sneller, met een rode gloed, en ze vliegt vaker.
  - Waar ze loopt en na haar vuuradem laat ze brandende plekken achter.
  - Op 66% en 33% roept ze telkens twee drillers op.
- **Haar dood:** `boss_amber`, opslaan weer vrij, de poort open, en de gouden Tren-spuit (`TrenSpuit.tscn`) op de grond. Oppakken zet `tren_spuit_found`. Laad je daarna een save, dan ligt Klaas er nog en ook de spuit, zolang je die niet had.
- **Tests:** `test_amber.gd` heeft nu 36 checks, voor de hele weg tot en met het oppakken van de spuit.

### Verbeteringen aan blok B (feedback van de eigenaar, 20-11-2026)

- **Nieuw model voor Amber** (`tools/models/gen_amber.py`, met de nieuwe gedeelde `tools/models/model_builder.py`):
  - een diepe borst en heupen met buikplaten en een rij stekels;
  - een nek in drie delen en een kop met wenkbrauwbogen, schuine gloeiende ogen, gebogen hoorns, wangpunten, tanden, tong en een kaak die opengaat;
  - een staart in vier delen met een schoppunt, en vier poten met knieën en klauwen;
  - echte vleermuisvleugels: arm, onderarm en vier vingers met een vlies ertussen (`MembraneMesh`) dat meebuigt. De vleugels vouwen langs haar rug, spreiden voor de windstoot en klappen in de lucht met een snelle neerslag en een tragere opslag met gebogen ellebogen, terwijl haar lijf op elke slag meedeint (`DragonWingRig`).
  - Opstijgen is nu door de knieën zakken en dan afzetten, landen gaat met remmende vleugels. Ze is op 85% geschaald (zo'n 16 m lang).
- **Niet meer in de pilaren:** markers op haar kop, bek, nek, borst, heupen en staart (en vleugeltips als die gespreid zijn) houden haar hele lijf buiten de pilaren en de muur. Haar botsingsdoos botst niet meer met de wereld, want die bleef haken terwijl haar lijf vrij was. Een windstoot doet ze alleen als haar vleugels de ruimte hebben.
- **Nieuw vuur:**
  - Bij het inademen verschijnt een rode waaier op de grond, met een felle rand, die laat zien waar het vuur komt (zoals de rode lijn van het fatbike-kindje). Achter een pilaar is een schaduw in de waaier: daar ben je veilig.
  - Ze richt in het eerste deel van het inademen en zet dan vast, zodat je opzij kunt. In haar tweede balk zwaait ze de vlammen van links naar rechts; de waaier toont dan het hele gebied.
  - De vlammen stromen uit haar bek, groeien en koelen af van geel naar donkerrood, en slaan stuk tegen een pilaar. Schade, waaier en vlammen gebruiken dezelfde straal vanuit haar bek.
- **Slimmere AI:**
  - Ze rent niet meer recht op je af: ze houdt 9 tot 15 m afstand en cirkelt om haar doelwit, van richting wisselend.
  - Staat haar doelwit achter een pilaar, dan loopt ze eromheen om een vuurlijn te vinden; verstop je je langer dan 4 s, dan vliegt ze op.
  - Elke aanval heeft een eigen cooldown (vuur 8 s, in balk 2 korter), en tussen twee aanvallen zit een pauze, dus geen vuur achter elkaar.
- **Rondje langs de rand:** raak je haar vier keer binnen 6 s, dan brult ze en rent ze in een spiraal door een opening tussen de pilaren naar buiten, een rondje langs de muur (wie in de weg staat wordt vertrapt en weggeduwd) en door een andere opening weer naar binnen. Daarna kan dat 16 s niet.
- **Vaker vliegen:** om de 16 s (was 25), in balk 2 om de 11 s, en wat lager (8 m) zodat ze niet tegen het plafond klapt.
- **Grotere arena:** 27 m straal in plaats van 22 m, met de pilaren op 13,5 m. Een draak van 16 m paste niet door de openingen tussen de pilaren en de muur. De ingang ligt nog op dezelfde plek; het midden van de arena is 5 m naar het zuiden geschoven (z = −233).
- **Amber-cultisten** zijn sterker en hebben een nieuw model (`tools/models/gen_cultist.py`): een amberkleurige mantel met een donkere cape, een puntkap met schaduw en gloeiende ogen, een gouden halfmasker, een gloeiende hanger en een staf met gouden klauwen om een amberkristal. Ze hebben 75 HP (was 40), houden afstand en schieten twee amberkleurige vuurbollen tegelijk (`AmberOrb`, 12 schade). Ze waarschuwen de hele kamer, en hun gezang geneest alle vijanden in de buurt met 12 HP, naast de woede.
- **Draakjes met een driller erop** (`tools/models/gen_dragonling.py`): een mini-draak van zo'n 3,5 m met dezelfde vleugels als Amber, een zadel, en een laag driller met zijn plank die de teugels vasthoudt (`HumanoidModel.straddle`). Bij een duik slaat de ruiter met zijn plank. Ze hebben 45 HP. Valt het draakje, dan tuimelt de ruiter eraf en vecht hij te voet verder (zie de tweede ronde hieronder). Onder een laag plafond vliegen ze lager.
- **Tweede ronde feedback (eigenaar, 20-11-2026):**
  - Amber vliegt iets vaker: om de 13 s (was 16), in balk 2 om de 9 s.
  - Haar rondje langs de muur gaat sneller: 13,5 m/s (was 10).
  - Ze heeft 900 HP per balk (was 800), dus 1800 in totaal.
  - **Nieuwe aanval in balk 2, de vuurstamp:** staat de speler binnen 14 m, dan steigert ze 1 s en stampt ze. Twee ringen van vuur lopen na elkaar over de vloer (16 schade): spring eroverheen. Daarna kan dat 9 s niet. De eerste keer meldt het spel "Amber steigert! Spring over het vuur!".
  - **Cultisten uit Zevenaar:** "ZEVENAAR" staat in goud op de rug van hun cape. Onder de mantel zijn ze nog een beetje driller: een zwart pufferjack met ribbels en een oranje rits aan de open voorkant, een pufferkraag en pufferboordjes, en witte sneakers. Verder is het ontwerp gelijk gebleven.
  - **Cultisten echt driller, met een vuurvape (derde ronde):** het bovenlijf is nu een zwart pufferjack met ribbels rondom, een hoge pufferkraag, een oranje rits en pufferkouwen met oranje strepen. De amberkleurige puntkap, het gouden masker, de gloeiende hanger, de cape met ZEVENAAR en het gewaad vanaf de heupen zijn gebleven. De staf is vervangen door een rode vuurvape (een rode mod met een gloeiend scherm en een tank vol vuur). Hun aanval werkt hetzelfde (twee wolkjes tegelijk, 12 schade, dezelfde snelheid), maar het zijn nu oranje vuurwolkjes (`FireVapePuff`, de vape-wolk van Westeraam in vuurkleur) en ze zetten de vape aan hun mond, zoals de vape-drillers. `AmberOrb` is weg.
  - **Lore van Zevenaar (eigenaar):** Amber komt uit Zevenaar en veroverde dat als eerste, voordat ze in Arnhem terechtkwam. De cultisten en de drillers op de draakjes komen uit Zevenaar en zijn haar sindsdien trouw; daarom zie je ze pas in de kerk. Het staat in het GDD, en Klaas vertelt het bij de arenapoort ("Wie zijn die figuren in die oranje gewaden?").
  - **Ruiters in pufferjacks:** de driller op een draakje is nu een drakenrijder (`DragonRiderModel.tscn`): het zwarte pufferjack van de driller met een oranje rits, oranje strepen op de mouwen en een oranje band om de beanie (Ambers leger), en zijn plank. Valt het draakje, dan vecht hij te voet verder als `DragonRider.tscn` (`dragon_rider.tres`, even sterk als een laag driller).
- **Tests:** `test_amber.gd` controleert nu ook de vuurstamp, de waarschuwing op de grond, de schaduw van een pilaar, het cirkelen, dat haar lijf nooit in een pilaar of muur komt (ook niet tijdens het rondje), het rondje zelf, het genezen en schieten van de cultisten en de ruiter van het draakje.

### Keuzes en afwijkingen

- **De arena ligt op −15 m,** net als de voorkamer, en niet op −18 m zoals in het plan. Een extra trap voor de arena voegde niets toe.
- **Klaas is tijdens Quest 6 niet thuis,** zodat hij niet op twee plekken tegelijk staat. Zijn winkel is dan bij de arena. Hij blijft wel thuis zolang er nog een quest is om in te leveren: versla je de derde baas vóór je verslag doet, dan krijg je eerst nog je beloning en de kruisboog.
- **Laag driller en driller** hebben andere HP dan het GDD (30 en 40); het GDD is bijgewerkt.

### Vierde ronde aan Amber (eigenaar, 20-11-2026)

- In haar tweede balk roept ze geen drillers meer, maar twee keer twee Amber-cultisten uit Zevenaar.
- Ze heeft 1050 HP per balk (was 900).
- **Vijfde ronde:** de hete zone loopt nu van het midden van haar lijf tot haar bek en is 3,2 m breed naar beide kanten (eerst begon hij pas voor haar borst, waardoor je naast haar voorpoten veilig stond). Bovendien duwt de hitte je elk frame onder haar vandaan.
- **Zesde ronde:** de camera van een scène (`Cutscene.look()` en `glide()`) schuift nu vóór een pilaar of muur die tussen de camera en het onderwerp staat, zoals de camera van de speler; zo is geen scène meer geblokkeerd, waar je ook stond. Amber kiest voor haar rondje de opening tussen de pilaren waar ze al naartoe kijkt, stuurt om pilaren heen en gaat meteen door naar de ring als ze een halve seconde niet vooruitkomt (eerst bleef ze tot 5 s hangen als haar rechte weg langs een pilaar liep).
- **Zevende ronde (video van de eigenaar):** de scène van Klaas wordt nu dichter bij het midden opgezet, tussen de pilaren in, en elk camerastandpunt wordt gecontroleerd tegen de echte pilaarposities (anders aan de andere kant, of dichterbij); de camera kijkt op ooghoogte in plaats van omhoog naar Ambers kop. De camera van `Cutscene` blijft ook 1,6 m vóór een muur of pilaar (de zichtbare pilaren zijn breder dan hun botsingsvorm). Gecontroleerd met screenshots, ook toen het gevecht vlak achter een pilaar begon.
- **De opoffering van Klaas opnieuw:** de scène wordt in het midden van de arena opgezet, zodat elk shot duidelijk is: een breed shot van opzij met Amber, de speler en Klaas; over de schouder van de speler zakt Ambers kop omlaag naar de speler en groeit de vuurbal in haar bek; Klaas roept "NEE!" en rent van opzij aan; in slow motion duikt hij (nieuwe actie `dive`) in de baan van de vuurbal, die hem raakt met een flits en terugwerpt; de speler wankelt; daarna close op Klaas op de grond.
- **Onder haar nek is het niet meer veilig:** wie tijdens haar vuuradem onder haar nek staat (van haar borst tot haar bek, 2,4 m naar beide kanten), krijgt dezelfde vuurschade. De rode zone op de grond loopt daar door, en de onderkant van haar nek gloeit fel met een oranje licht eronder, al vanaf het inademen.

### Wat is af (blok C, het einde)

- **C1, Klaas weer tot leven:** bij de gevallen Klaas staat "[E] Gebruik de Tren-spuit op Klaas" (zonder spuit zegt het spel waar die ligt). Een korte scène: de speler drukt de spuit in zijn arm, een gouden flits, Klaas staat op en flext ("...Tren?", "Zie je? Mijn bril is niet eens afgevallen."). Daarna gaan ze samen naar buiten: een fade naar het kerkplein in Elst. Quest 6 heeft een laatste doel "Ga met Klaas naar buiten" (vlag `elst_saved`).
- **C2, de tornado verdwijnt:** `TornadoBorder.dissolve()` laat de stofmuren vervagen en inzakken, het puin wegdraaien en de mist optrekken naar helder weer. Met de vlag `tornado_gone` blijft hij weg, ook na laden; bij de oude ring duwt geen wind meer. Loop je Elst uit (verder dan 222 m), dan speelt een korte scène: "Waar ga ik heen? Ik blijf het nog even vieren in Elst!", waarna je je omdraait, een paar meter terugloopt en weer zelf speelt (op verzoek van de eigenaar, in plaats van alleen een onzichtbare grens). De vaste ring op 240 m blijft als vangnet. Mist en muren worden als kopie aangepast, zodat een oudere save weer de tornado heeft.
- **C3, de eindscène** (`scripts/world/ending.gd`, node `Ending` in `scenes/world/locations/Kerk.tscn`), zoals de eigenaar hem beschreef: de dorpelingen zijn terug, de tornado zakt weg, Klaas feliciteert de speler en maakt hem een echte Elstenaar, in de verte meldt een figuur in een mantel (`SpyModel.tscn`, gezicht nooit te zien, met een telefoon) aan zijn baas dat de held Amber verslagen heeft en dat plan B ingaat, en daarna feest op het kerkplein (`PartyDecor.tscn`: lichtjes, vlaggetjes, een tafel met eiwitshakes, een podium met discobal, "ELST IS VRIJ!" op de toren, acht dorpelingen). Dan rolt de aftiteling (`Credits.tscn`, overslaan met E of Esc) en speel je vrij verder. Met de vlag `ending_pending` speelt de scène opnieuw als je een save laadt die ertussenin gemaakt is.
- **Klaas thuis** begroet je daarna als "mijn Elstenaar" en weet bij "Heb je nog een klus?" iets van een vent in een mantel. Zijn verhaal over Amber noemt nu Zevenaar.
- **Tests:** `test_amber.gd` speelt het einde helemaal na (Klaas wekken, naar buiten, feest, tornado weg, spion, Inwijding 6, aftiteling, geen wind meer, opslaan en laden).

### Keuzes en afwijkingen

- **Naar buiten met een fade:** na het wekken lopen de speler en Klaas niet de hele kerk-dungeon weer omhoog; een fade brengt ze naar het kerkplein. Dat scheelt vier verdiepingen teruglopen.
- **De eindscène is eenvoudig** (camera, ondertitels, simpele animaties) en staat los van de rest, omdat hij in Prototype 2 opnieuw gemaakt wordt.
- **Nog niet in de editor bekeken:** de scène is alleen headless getest. Camerahoeken en de plek van de spion kunnen nog bijgesteld worden na de test van de eigenaar.

## Kaart van het spel en Elst zonder de bronkaart

- **`gen_elst.py` heeft `kaart_elst.png` niet meer nodig.** Het las de kaart alleen voor het grondraster, en dat raster (`data/world/elst_ground.png`) staat in de repo. Ontbreekt de kaart, dan gebruikt het script het raster; `Elst.tscn` komt er byte voor byte hetzelfde uit (gecontroleerd: 443 huizen, 482 bomen).
- **Nieuwe kaart van Elst zoals in het spel** (`tools/map/render_map.py`, `docs/kaart_elst_spel.png`), in de stijl van de referentiekaart: straten, tuinen, parken, weilanden en water uit het raster, alle huizen en bomen uit dezelfde willekeurige ronde als `gen_elst.py`, de hoofdwegen, het spoor met overwegen, de zes locaties met hun deur, de tornadoring, een legenda, een schaalstok en het noorden. Draai het script opnieuw als de wereld verandert.
- **Let op:** de kaart die de eigenaar op 20-11-2026 stuurde was de plantekening van `render_plan.py` (met "oude plekken"), niet de bronkaart van 520 × 419 pixels. Die bronkaart is nu niet meer nodig.

## Grumpy Oma zwaarder en de kruisboog met pijlen (`Rebalance-Grumpy-Oma-And-Crossbow`)

Twee punten van de eigenaar na de verbeteringen aan blok B van Fase 11 (20-11-2026).

### Wat is af

- **Grumpy Oma was te makkelijk** en deed te weinig met haar aanvallen. Nu:
  - 650 HP (was 550) en 18 schade per klap (was 16);
  - ze loopt sneller (3,8 m/s, was 3) en doet om de 4 s (was 5) een grondslag of tornado; de tornado duurt langer en is sneller;
  - na haar klap komt vaak (50%, woedend altijd) een snelle tweede klap met de achterkant van haar hand;
  - blijf je 1,2 s buiten haar bereik, dan gooit ze een waaier van vijf bingokaarten ("BINGO-KAARTEN!", 10 schade per kaart, om de 4 s), zodat je haar niet veilig van afstand kunt beschieten;
  - woedend (onder 30%) slamt ze twee keer achter elkaar;
  - ze is korter uitgeput (1,8 s, was 2,5) en krijgt dan 35% extra schade (was 50%).
- **Pijlen voor de kruisboog:**
  - Elk schot kost een pijl. Je krijgt er 15 bij de kruisboog en draagt er hooguit 30. Zijn ze op, dan schiet de kruisboog niet en zegt het spel waar je nieuwe vindt.
  - Klaas verkoopt ze per 5 voor 15 goud (thuis en bij de arena). Vijanden laten soms 2 pijlen vallen (15%), kisten vaak 4 (70%), maar alleen als je de kruisboog hebt.
  - De HUD toont "x/30 pijlen" naast de drankjes. Op de grond liggen pijlen als een bundeltje.
  - Een oude save met de kruisboog krijgt bij het laden eenmalig de 15 pijlen.
- **Vijanden komen op een schutter af:** een vijand die je raakt, gaat 15 s op jacht, samen met zijn groep in de buurt. Hij geeft niet op als hij je niet ziet en mag ver van huis, dus hij loopt niet meer terug om te genezen terwijl je hem van ver beschiet.
- **Tests:** `test_bingo` controleert de nieuwe aanvallen van Grumpy Oma en de pijlen (15 bij de kruisboog, één per schot, daarna een gespannen pees met een pijl, niet schieten zonder pijlen, kopen per 5, maximaal 30); `test_enemies` controleert dat een beschoten vijand en zijn groep de schutter opzoeken.

- **Kruisboog, pijl en schieten mooier** (derde verzoek):
  - Nieuw model (`tools/models/gen_crossbow.py`, `CrossbowModel.tscn`): een houten kolf met ijzeren kolfplaat, wangstuk, greep, trekker en ijzeren banden, een groef met noot, een vizier, een stalen boog in twee armen met gouden tippen, een voetbeugel, een pees en een pijl in de groef.
  - Nieuwe pijl (`BoltModel.tscn`): een stalen breedkop, een ijzeren ring, een houten schacht en drie veren (één rood). In de lucht vliegt hij met de punt vooruit en een vage streep erachter. Hij blijft steken in muren (4 s) en in de vijand die hij raakt (en beweegt dan mee). Een straal per frame zorgt dat een snelle pijl niet door een dunne muur of vijand heen schiet (`bolt.gd`).
  - Richten: de speler draait zijn romp een kwart, zoals met een geweer, houdt de kolf tegen de borst met de rechterhand aan de greep en de linker eronder, en de armen gaan mee omhoog en omlaag met de camera (`HumanoidModel.set_aim()`).
  - Schieten: de pees schiet naar voren, de kruisboog slaat omhoog (terugslag), gaat dan omlaag terwijl de linkerhand de pees terugtrekt (de armen van de boog buigen mee) en komt weer omhoog met een nieuwe pijl in de groef (`crossbow_shoot`, 0,9 s). De pijl vertrekt bij de punt van de kruisboog.

### Keuzes en afwijkingen

- **Pijlen oprapen na het schieten** zit er niet in: verschoten pijlen zijn op. Vinden doe je ze bij vijanden en in kisten.
- **De prijs** (3 goud per pijl) is een startwaarde; drankjes kosten 20 goud.

## Fase 10 – Quest 5: Bingo Club Boomer Cave

### Wat is af

- **Bingo-dungeon** (`scenes/dungeons/BingoCave.tscn`, gebouwd door `tools/dungeons/gen_bingo.py`): ongeveer 70 × 190 m met 25 vijanden (OBC 20, Westeraam 18). Dit is de zwaarste factie-dungeon, in twee delen met een checkpoint ertussen.
  - Deel 1, de bingoclub: de entree, een grote bingozaal met lange tafels en een podium met de bingomolen, de keuken (kist) en een gang.
  - Checkpoint: de koffiekamer, met een autosave en een rustbank.
  - Deel 2, de Boomer Cave: een grote grot met stalagmieten (kist), een grotgang en het hol van Grumpy Oma.
- **Lore (eigenaar):** Grumpy Oma is de nummer 1 bingowinnaar van Elst en een trouwe volger van Amber. De oma's en opa's van de Bingo Club zien haar als hun leider, bijna als een messias. Dat staat nu ook in het GDD en in Klaas' tekst bij Quest 5.
- **Bingo-opa's** (35 HP, 6 schade): de simpele vijand. Ze rennen op je af, slaan met hun wandelstok en roepen ondertussen bingonummers ("G-52!", met de juiste letter) en bingofeitjes ("88: twee dikke dames!").
- **Boze oma's** (45 HP, 10 schade):
  - Ze springen van tot 11 m afstand in een lange sprong (met een koprol) op je af en slaan je dan met hun paarse leren tasje.
  - Sla je ze 3,5 s niet, dan springen ze weer weg (8 m) en wachten ze 2 s voordat ze opnieuw aanvallen.
  - Nieuw in `EnemyData`: `leap_range`, `leap_time`, `patience`, `hop_away_distance` en `hop_away_wait`, met een eigen `Leap`-state.
- **Rolstoel-oma's** (50 HP, 7 schade per kaart), nieuw:
  - Heel sloom in een rolstoel (`RolstoelOmaModel.tscn`, een zittende oma; `HumanoidModel.seated`).
  - Ze schieten als een kanon salvo's van 3 bingokaarten in een waaier (`BingoCard.tscn`) en rollen bij elk schot een stukje achteruit.
  - Nieuw in `EnemyData`: `burst_count`, `burst_spread` en `recoil`.
- **Grumpy Oma** (550 HP, `scenes/bosses/GrumpyOma.tscn`), na feedback van de eigenaar helemaal opnieuw:
  - **Model** (`tools/models/gen_grumpy_oma.py`): een enorme, gebogen oma als een woest beest. Ze heeft een brede borst met een bult van spieren, blote armen met aders tot aan haar knieën en korte, dikke benen in steunkousen. Haar kleine, boze kop heeft rode ogen, een onderbeet en een grijs permanentje met krulspelden. Ze draagt een groot paars handtas, plus een gouden sjerp en een medaille met een 1, omdat ze de bingokampioen is. De levensbalk heet "Grumpy Oma, bingokampioen".
  - **Klap** (16 schade): ze sjokt op je af (langzamer dan jij loopt) en haalt duidelijk zichtbaar 0,8 s uit. Ze richt alleen in de eerste helft, dus opzij stappen werkt. Na de klap moet ze 1,1 s op adem komen, en pas daarna kan ze weer slaan. Pareer je de klap, dan is ze meteen uitgeput.
  - **Grondslag:** om de 5 s doet ze afwisselend een grondslag of een tornado. Bij de grondslag zakt ze eerst door haar knieën, springt dan naar je toe en stuurt een schokgolf over de vloer (spring eroverheen).
  - **Tornado:** 3 s, langzamer dan sprinten. Treffers ketsen af.
  - **Uitgeput:** na een grondslag, een tornado of een parry staat ze 2,5 s uitgeput en krijgt ze 50% extra schade. De rest van de tijd krijgt ze gewone schade.
  - **Volgelingen:** op 2/3 en 1/3 van haar HP roept ze "BINGO!" en komen er telkens twee volgelingen het hol in: eerst een boze oma en een bingo-opa, daarna een rolstoel-oma en een boze oma. Alle bingovijanden in de buurt worden 6 s woest (+25% schade).
  - Onder 30% wordt ze 30% sneller. Tijdens het gevecht gaat het hek van het hol dicht en kun je niet opslaan.
- **Bingo Club bevrijd:** in Elst staan twee boze oma's en een bingo-opa bij de Bingo Club. Na Grumpy Oma (`boss_grumpy_oma`) lopen er dorpelingen ("BINGO! Echt waar deze keer!").
- **Quest 5 "Bingo Club Boomer Cave"** (`data/quests/q5_bingo.tres`): Klaas geeft hem na Quest 4 (Inwijding 4). Doelen: versla Grumpy Oma en ga terug naar Klaas. Beloning: 150 goud en Inwijding 5. Ook eerder verslagen telt.
- **De kruisboog:** na Quest 5 geeft Klaas zijn oude kruisboog (30 schade).
  - Toets 2 pakt de kruisboog, toets 1 het zwaard.
  - Met de rechtermuisknop richt je: de camera zoomt in, de speler kijkt mee met de camera en er verschijnt een vizier.
  - Met de linkermuisknop schiet je een pijl (`scenes/player/Bolt.tscn`) naar het midden van het vizier. Herladen duurt 0,9 s.
  - Met de kruisboog kun je niet blokkeren.
- **Tests:** `tests/test_bingo.gd` (41 checks, allemaal geslaagd). `test_world` loopt ook in de Bingo-dungeon een route van de ingang naar Grumpy Oma. De andere tests slagen ook.

### Keuzes en afwijkingen

- **Grumpy Oma heeft 550 HP** in plaats van de 500 uit het eerste GDD, zodat ze sterker is dan het fatbike-kindje (450). Het GDD is bijgewerkt.
- **Eerste versie, afgekeurd door de eigenaar:** Grumpy Oma rende op je af en sloeg snel achter elkaar. Buiten haar uitputting kwam maar 25% van je schade door. Daardoor ging je snel dood en deed je bijna geen schade. Nu zijn haar klappen traag en zichtbaar, heeft ze na elke klap een rustmoment, krijgt ze altijd gewone schade en krijgt ze extra schade als ze uitgeput is.
- **Het BINGO!-effect** van de opa's uit de eerste versie is weg; de opa's zijn nu de simpele vijand. Het effect zit nu bij Grumpy Oma: haar "BINGO!" maakt haar volgelingen woest.
- **De Bingo Club wordt niet zwakker na het station**, net als de bazen. Het GDD noemt verzwakking alleen voor Westeraam en OBC.
- **De kruisboog** komt van Klaas na Quest 5, ook als je Grumpy Oma al eerder versloeg. Er zijn nog geen pijlen om te tellen; de kruisboog schiet onbeperkt met een herlaadtijd.
- **Na Quest 5** zegt Klaas "Nog niet" als je om een klus vraagt, tot Fase 11.

### Aandachtspunten voor de volgende fases

- Fase 11: de kerk gaat open als `boss_vape_koning`, `boss_fatbike_kindje` en `boss_grumpy_oma` gezet zijn. Volg het kerkplan in het GDD (*De Kerk van Amber*): boven in het kerkgebouw beginnen, dan trappen en gangen ondergronds met doodlopende kamers en vijanden van alle facties, Klaas voor de arena (praten en winkel) en een ronde arena met 5 pilaren. Klaas vecht mee tot hij sneuvelt; de kruisboog is handig tegen Amber in de lucht.
- Fase 12: geluid voor de bingonummers, de schokgolf, de rolstoel en de kruisboog.

## Dev powers, vijanden en locaties (`Add-Dev-Powers-And-Enemy-Facing`)

Verzoeken van de eigenaar na Fase 10, voor Fase 11.

### Wat is af

- **Dev powers** voor het testen. De backtick-toets (`` ` ``) zet ze aan en uit, alleen in debug builds (de editor en debug-exports, niet in een release). Je ziet "DEV POWERS" rechtsboven in beeld.
  - Je krijgt geen schade.
  - Je vliegt: Spatie gaat omhoog, Ctrl omlaag, en loslaten houdt je op hoogte.
  - Je loopt drie keer zo snel, en sprinten kost geen stamina.
  - Elke treffer van de speler (zwaard of kruisboog) doodt meteen, ook bij bazen en generators, wat de baas ook normaal met een treffer doet.
  - De dev powers worden niet opgeslagen.
- **Kijkrichting van vijanden in de dungeons.** Eerst keken bijna alle vijanden van de ingang af, vooral in het station. `aim_enemies()` in `dungeon_builder.py` draait ze nu bij het genereren. Een deel kijkt naar de deur waardoor de speler hun kamer binnenkomt (een beetje schuin), de rest kijkt een willekeurige kant op. Die deur wordt per kamer gevonden door vanaf de ingang door de deuren te lopen. Een vaste seed geeft elke run dezelfde stand.

| Dungeon | Kijkt naar de speler |
|---|---|
| Station | 8 van de 15, de rest willekeurig |
| Westeraam | 10 van de 18 |
| OBC | 17 van de 20 |
| Bingo Club | 21 van de 25 |

- **Tests:** `test_player_combat` controleert nu ook de dev powers. Alle tests slagen.
- **Verslagen dungeons blijven leeg** (tweede verzoek, 20-11-2026). Een dungeon met de vlag van zijn baas (Station Elst: `station_cleared`) haalt bij het laden zijn vijanden weg, ook na opnieuw laden. Kom je door de deur weer binnen, dan lopen er vier inwoners met eigen zinnen ("De treinen rijden weer!"). Laad je een save die in de dungeon gemaakt is, dan blijft hij helemaal leeg. `test_save` controleert beide.
- **Bugfix:** een vijand die doodging tijdens een treffer liet zijn buit vallen midden in een botsing, en dan gaf Godot een foutmelding. Dat gebeurde vooral met dev powers, maar ook bij gewone kills met buit. De buit verschijnt nu een frame later.
- **Dev powers en schade:** gecontroleerd in de Bingo-dungeon met echte vijanden. Je krijgt geen schade, en elke klap doodt.
- **Vijanden buiten** bij het station en Westeraam stonden ergens in de straat. Nu bewaken drie laag drillers het depot van Amber en het stationsplein, en drie drillers (één extra) de binnenplaats van Westeraam, met hun gezicht naar de ingang.
- **Nieuwe buitenkant van vier locaties** (`tools/map/gen_locations.py`, met `BoxCluster` voor de details):
  - **Station:** een stationshal met glazen pui, luifel en glazen dakrand, een klok op een paal, en het perron met overkapping, banken, vertrekbord, naamborden en een kaartautomaat. Op het plein staan fietsenrekken vol fietsen, een bushokje, een broodjeskiosk, bomen in bakken en lantaarns. Het depot van Amber is een golfplaten hal met een oranje band, "AMBER LOGISTIEK", rolluiken, banieren, pallets eiwitshakes, vaten, een container, schijnwerpers en een hek met prikkeldraad. Het spoor en het perron liggen precies waar ze lagen.
  - **Westeraam:** drie gele galerijflats met op elke verdieping een galerij met zwart-geel hek, wasgoed en schotelantennes, en een geel-zwarte plint. Op de binnenplaats staan een uitgebrande auto, een brandende ton met vuurlicht, containers, winkelwagens, een oude bank, een kapotte schommel, een basketbalpaal en scooters. Verder: graffiti, een portiek met gestreepte luifel en vapewolken, een neon-vapeshop, en een zwart hek met poort onder een "WESTERAAM GETHO"-bord.
  - **OBC Elst Fort:** het fort is behouden en versterkt met hogere rode bakstenen muren met kantelen en banieren, vier torens met kantelen, schietgaten en rood-navy vlaggen, en een poortgebouw met een opgetrokken valhek en een "OBC ELST FORT"-bord. Binnen staan de school met rode band, navy luifel en fietsen, en het voetbalveld met lijnen, doelen met netten, dug-outs, lichtmasten en een scorebord.
  - **Bingo Club:** het blauwe clubhuis met een grotmond van rotsen en stalactieten om de deur, een "BOOMER CAVE"-bordje en een groot BINGO-bord met lampjes. Verder gestreepte luifels, bloembakken, banken en rollators, en een parkeerplaats met vakken, drie scootmobielen met vlaggetje, de Bingo Express (minibus), een reuzen-bingobal (B-12), hagen en lantaarns.

- **Kerk en Huis van Klaas mooier** (derde verzoek): `gen_locations.py` maakt voor beide een decoratie-scene (`KerkDecor.tscn`, `KlaasHouseDecor.tscn`), die als `Decor` in de met de hand gemaakte scenes hangt. Zo blijven deuren, markers en de vergrendeling van de kerk ongemoeid.
  - **Kerk:** steunberen en glas-in-loodramen langs het schip, een stenen portaal met twee vuurschalen, een roosvenster en een amberkleurige ruit op de toren, klokken en galmgaten, een kerkhof met grafstenen achter een stenen muurtje, en banken, lantaarns en bestrating op het plein.
  - **Huis van Klaas:** een veranda met gouden zuilen en een gouden K, een gouden rand, een schoorsteen, bloembakken, tuinverlichting langs het pad, een buitengym ("SIGMA GYM"), een paarse auto met gouden streep, een barbecue met parasol, een brievenbus en een paars-gouden vlag. Het oefenveld voor de deur blijft vrij.

- **Buiten de tornado** (vierde verzoek): Elst gebruikt nu dieptemist (van 50 m tot volledig dicht op 235 m, ook over de lucht), zodat je niet meer ver over de ring heen kijkt. Er staan 160 bomen buiten de tornado. Het spoor (ballastbed en rails) loopt 760 m lang door de tornado heen de mist in, en de hoofdwegen die de ring raken lopen 160 m door. Huizen en bomen in het dorp zijn niet verschoven: de bomen buiten krijgen een eigen random-reeks.

### Keuzes en afwijkingen (tweede verzoek)

- **Inwoners verschijnen alleen als je door de deur binnenkomt**, niet bij het laden van een save in de dungeon. Zo blijft de dungeon na opnieuw laden leeg, zoals gevraagd.
- **Mooiere locaties in Prototype 1:** CLAUDE.md zegt geen tijd in mooiere modellen te steken, maar de eigenaar vroeg er nu zelf om. Het blijft low poly met platte kleuren.
- **De huizen in Elst zijn niet verschoven:** huizen blijven weg van vaste plekken (`CLEAR_SPOTS`, de oude patrouilleplekken), anders zou het verplaatsen van de vijanden het hele dorp opnieuw schudden.
- **Plan voor de kerk (eigenaar, 20-11-2026)** staat in het GDD en in de fasetabel van `CLAUDE.md`. Je begint boven in het kerkgebouw en gaat via trappen en gangen steeds dieper ondergronds, langs doodlopende kamers en vijanden van alle facties. Aan het eind wacht Klaas voor de arena (praten, kopen en verkopen), en de arena is een ronde ruimte met 5 pilaren.
- **GDD bijgewerkt** met de dev powers, de kijkrichting van vijanden, de bron van de kaart en de herlaadtijd van de kruisboog (0,9 s, zoals gebouwd).

### Keuzes en afwijkingen

- **Ctrl om omlaag te vliegen** is een nieuwe actie (`dev_fly_down`), net als `toggle_dev_powers`.
- **Westeraam** (geen wens genoemd) zit tussen het station en het OBC in, zodat de moeilijkheid oploopt.

## Factie-dungeons op slot en een groter Westeraam (`Lock-Faction-Dungeons-And-Expand-Westeraam`)

Twee punten van de eigenaar, na Fase 8 en voor Fase 9.

### Wat is af

- **De factie-dungeons zitten op slot tot het station plat ligt.** De deuren van Westeraam, OBC en de Bingo Club hebben `unlocked_by_flag = &"station_cleared"`. Zolang die vlag ontbreekt, meldt de deur: "De deur zit op slot. Zolang Station Elst Amber bevoorraadt, houdt ze deze plek dicht. Sloop eerst het station." De kerk blijft op slot tot Fase 11.
- **Klaas zegt het bij Quest 2:** "En zolang dat station draait, houdt Amber Westeraam, het OBC en de Bingo Club op slot. Eerst het station, dan pas de rest." Bij Quest 3 begint hij met "Nu het station plat ligt, zijn de deuren van de wijken open."
- **Westeraam is groter en heeft twee delen**, met een checkpoint ertussen (ongeveer 65 × 158 m en 18 vijanden; het station is 56 × 114 m met 15):
  - deel 1, de flats: het portiek, de galerij, de vape shop en de binnenplaats, daarna de kelderstrap;
  - de checkpoint: de fietsenkelder, zonder vijanden, met fietsen, een snoepautomaat en een rustbank;
  - deel 2, onder de flats: een parkeergarage met pilaren en geparkeerde auto's, een vape-lab, een gouden gang met twee drillers, en daarachter het Vape-paleis.
- **Checkpoint** (`scenes/world/props/Checkpoint.tscn`): de eerste keer dat je erin loopt, slaat het spel automatisch op. Ga je daarna dood, dan begin je weer bij de checkpoint en niet bij de ingang.
- **Rustbank** (`scenes/world/props/RestBench.tscn`): met E rust je even uit. Je krijgt je HP en stamina terug en het spel slaat op, net als het bed bij Klaas. Bed en bank sturen allebei `EventBus.rest_requested` met hun eigen tekst.
- **Tests:** `test_world` controleert dat de drie deuren op slot zitten zolang het station draait, `test_station` controleert Klaas' nieuwe zin, en `test_westeraam` de checkpoint en de bank. Alle acht tests slagen.

### Keuzes en afwijkingen

- **Het GDD is bijgewerkt** met beide besluiten: de volgorde (eerst het station, dan de facties) en de factie-dungeons met twee delen en een checkpoint.
- **Een checkpoint geldt per bezoek:** loop je de dungeon opnieuw in, dan slaat hij weer op als je hem bereikt. Laad je een save in de kelder zelf, dan slaat hij niet meteen opnieuw op.
- **De rustbank** heelt helemaal, zoals slapen. Dat maakt de pauze tussen de twee delen echt een pauze.

### Aandachtspunten voor de volgende fases

- Fase 9 en 10: OBC Elst Fort en Bingo Club Boomer Cave krijgen dezelfde opbouw. Ze worden groter dan het station, met een eerste deel, een checkpoint (`Checkpoint` en `RestBench`) en een tweede deel met de baas. Bouw ze met `tools/dungeons/dungeon_builder.py`.

## Fase 8 – Quest 3: Westeraam Getho

### Wat is af

- **Westeraam-dungeon** (`scenes/dungeons/Westeraam.tscn`, gebouwd door `tools/dungeons/gen_westeraam.py`; daarna groter gemaakt, zie *Factie-dungeons op slot en een groter Westeraam*). Vijf ruimtes, van de ingang naar achteren:
  - het portiek van de flats;
  - een lange galerij (2 drillers);
  - een vape shop (2 vape-drillers en een kist);
  - de binnenplaats met scooters en een uitgebrand autowrak (2 drillers, 2 vape-drillers en een kist);
  - het Vape-paleis met een gouden troon, een rode loper en vier vapewolken.
- **Vape-drillers** (30 HP, 10 schade): een hoodie met capuchon, geen gezicht te zien en een vape in de hand. Ze houden afstand, lopen achteruit als je te dichtbij komt en blazen langzame vapewolkjes die even blijven hangen. Blokkeren en parry werken ertegen. Na het station hebben ze 24 HP.
- **Afstandsaanvallen voor vijanden:** `projectile_scene` en `keep_distance` in `EnemyData`. Vijanden zonder projectiel blijven gewoon slaan.
- **De Vape-koning** (400 HP, 15 schade per wolkje, `scenes/bosses/VapeKing.tscn`):
  - hij verstopt zich in een van de vier wolken en schiet van daaruit; in zijn wolk flikkert een gouden glinstering;
  - loop je zijn wolk in, dan staat hij 4 s te hoesten en kun je hem raken; daarna vlucht hij naar een andere wolk;
  - terwijl hij vlucht, loopt het hele paleis vol dichte vape, zodat je niet goed ziet waar hij heen gaat; zodra hij in zijn nieuwe wolk zit, trekt die weer op (op verzoek van de eigenaar);
  - onder 50% blaast hij drie wolkjes tegelijk;
  - hij laat 100 goud vallen en heeft 35% kans op uitrusting.
- **Baasgevecht:** een grote levensbalk onderin beeld. Opslaan is geblokkeerd zolang het gevecht loopt. Een verslagen baas blijft verslagen na laden (vlag `boss_vape_koning`).
- **Bevrijde gebieden** (`LiberatedArea`): zodra zijn vlag gezet is, ruilt een gebied in Elst zijn patrouilles in voor dorpelingen en een warm licht. Er zijn drie gebieden:
  - de straat van Klaas, na Quest 1 (`q1_reported`);
  - het stationsplein, zodra de generators kapot zijn (`station_cleared`);
  - Westeraam, zodra de Vape-koning valt (`boss_vape_koning`).
- **Dorpelingen** (`scenes/npcs/Villager.tscn`): vrolijke figuren, elk met een eigen kleur shirt, broek en huid, en soms een muts. Ze wandelen rond. Kom je dichtbij, dan zwaaien ze en zeggen ze iets, zoals "De treinen rijden weer!".
- **Quest 3 "Westeraam Getho"** (`data/quests/q3_westeraam.tres`): Klaas geeft hem na Quest 2. Doelen: versla de Vape-koning en ga terug naar Klaas. Beloning: 150 goud en Inwijding +1 (dat is dan 3). Versla je hem eerder, dan is Klaas trots en krijg je de beloning alsnog.
- **Gedeelde dungeonbouwer** (`tools/dungeons/dungeon_builder.py`): het station en Westeraam gebruiken dezelfde code. De stationsdungeon kwam er hetzelfde uit, op één regel na: `default_spawn = &"Entrance"`, die sinds Fase 7 ontbrak.
- **Bugfix:** na doodgaan bleef "Je bent dood" in beeld staan, omdat de geladen save een nieuwe speler maakt. De HUD haalt het bericht nu weg zodra er weer een levende speler is; `test_save` controleert dat.
- **Tests:** `tests/test_westeraam.gd` (41 checks, allemaal geslaagd). Die speelt de bevrijde gebieden, de vape-drillers, het hele baasgevecht met opslaan en laden, de beloning en het geval dat je eerder klaar bent. De andere acht tests slagen ook.

### Keuzes en afwijkingen

- **Een warmere kleur** voor een bevrijd gebied is een warm licht boven dat gebied. Andere muziek per gebied komt met de audio in Fase 12.
- **Wanneer een gebied bevrijd is,** volgt uit zijn vlag. Het veld `GameState.liberated_areas` uit Fase 3 wordt daarom niet gebruikt; het blijft wel in de saves staan.
- **De bazen worden niet zwakker na het station**, alleen de gewone vijanden. Het GDD zegt "vijanden van Westeraam en OBC krijgen 20% minder HP"; ik lees bazen daar niet in, zodat het gevecht zijn uitdaging houdt.
- **De Vape-koning** heeft geen state machine, maar een eenvoudig script met vijf toestanden (wachten, verstopt, kwetsbaar, vluchten, dood). Hij gebruikt wel `HealthComponent`, `Hurtbox` en `LootDropper`.
- **"Kans op loot"** als beloning van Quest 3 is de 35% kans op uitrusting die de baas laat vallen.
- **Na Quest 3** zegt Klaas "Nog niet" als je om een klus vraagt, tot Fase 9.

### Aandachtspunten voor de volgende fases

- Fase 9: OBC wordt een vierde `LiberatedArea` in `tools/map/gen_elst.py` (AREAS), met de vlag van het fatbike-kindje. Voetbaljongens kunnen schieten met een eigen `projectile_scene`. Het fatbike-kindje kan het patroon van de Vape-koning volgen: opslaan blokkeren, de `boss_*`-signalen en een vlag.
- Fase 10: hetzelfde voor de Bingo Club.
- Fase 11: de kerk gaat open als de vlaggen van de drie bazen gezet zijn.
- Fase 12: muziek per gebied, bezet of bevrijd.

## Kaart verwerken (`Align-Elst-With-Map`)

Status: af, gemerged naar `Development`.

### Wat is af

- **Elst volgt nu `kaart_elst.png`.** `tools/map/gen_elst.py` bouwt `scenes/world/Elst.tscn` opnieuw op. Het gebruikt `tools/map/layout.py` (schaal, midden, locaties, hoofdwegen en spoor) en leest het landgebruik uit de kaart.
- **Schaal en midden:** 1,05 m per kaartpixel. Het midden van de tornado ligt tussen de zes locaties in, op kaartpixel (220, 242). De tornado blijft even groot (wind vanaf 222 m, muur op 240 m).
- **Locaties** (wereldpositie x, z in meters, deur = lokale −z):

| Locatie | Positie | Deur naar | Opmerking |
|---|---|---|---|
| Kerk | (25, −109) | oostzuidoost, naar de doorgaande weg | gedraaid (yaw −2,146); plein van 64 naar 46 m |
| Bingo Club | (−27, −104) | zuid | iets ten westen van de blauwe vlek, naast de kerk |
| Huis van Klaas | (35, 3) | noord, naar de kerk | bijna in het midden van de ring |
| Station | (112, −97) | zuid, naar de weg langs het station | omgedraaid: perron en spoor aan de oostkant |
| Westeraam | (157, −69) | zuid | aan de oostkant van het spoor |
| OBC Fort | (−172, 78) | oost, naar de weg in het zuidwesten | |

- **Grond:** één `GroundMap` (`scripts/world/ground_map.gd`), een mesh met een vlakke kleur per vierkante meter uit het raster `data/world/elst_ground.png`. Dat raster bevat per cel een kleurnummer en is geen textuur. Erin staan de straten van de kaart, tuinen, een lappendeken van weilanden, parken en sportvelden, water, het spoor en geplaveide grond onder de locaties. Alles samen is één draw call.
- **Wegen:** de hoofdwegen (8 m breed) zijn overgetrokken van de kaart. De straten komen rechtstreeks uit de kaart.
- **443 huizen** langs de straten, met de deur naar de straat, en **322 bomen** in parken, tuinen en weilanden.
- **Spoor** van noord naar zuid op x = 127, tussen het station en Westeraam, met drie overwegen.
- **Water:** de grotere vijvers en de westpunt van de Aamsche Plas liggen binnen de tornado. Onzichtbare randen houden je eruit.
- **Vijanden buiten:** drie laag drillers op de Stationsstraat en twee drillers ten zuiden van Westeraam.
- **Tests:** alle zeven slagen. `test_save` gebruikt nu plekken naast het startpunt in plaats van vaste coördinaten. `test_enemies` wacht tot de navmesh van Elst klaar is (ongeveer 0,2 s).

### Keuzes en afwijkingen

- **De tornado staat om het midden van de locaties, niet om de kerk.** Op de kaart ligt OBC zo ver naar het zuidwesten dat het anders buiten de ring valt. "Kerk in het midden" uit het GDD lees ik als het midden van het dorp.
- **De kerk** staat met de voorkant naar de doorgaande weg, en het kerkplein is kleiner (46 in plaats van 64 m). **Het station** is omgedraaid: het perron ligt aan het spoor en het stationsplein aan de weg aan de zuidkant.
- **De Bingo Club** staat zo'n 20 m ten westen van zijn blauwe vlek, omdat het kerkplein groter is dan de roze vlek.
- **Straten zijn 2 tot 3 m breed**, zoals de kaart ze op deze schaal geeft. Een cel breder liet te weinig ruimte voor huizen. De huizen zijn daarom laag gehouden.
- **Geen industrieterrein meer:** dat staat niet op de kaart. De Aamsche Plas ligt grotendeels buiten de tornado.
- **`Elst.tscn` komt nu uit het script.** Verander de wereld via het script en draai het opnieuw. Huizen en bomen die je in de editor verplaatst, gaan bij de volgende run verloren. Lucht, tornado, grondcollider en navigatie-instellingen neemt het script over uit de bestaande scene.

### Open punten

- [x] **Bron van de kaart:** `kaart_elst.png` is de kaart die de eigenaar heeft aangeleverd (19-11-2026). Hij staat lokaal in `docs/reference/` en nog niet in de repo. `gen_elst.py` kan dus alleen draaien als de kaart daar staat. Het raster `elst_ground.png` is van de kaart afgeleid en staat wel in de repo.
- [ ] **Ligging van het spoor** bevestigen.
- [x] **`test_enemies` faalde af en toe** in de stationsdungeon, omdat de vijanden willekeurig patrouilleren. Sinds Fase 7 speelt de test in een eigen, langere testkamer. In Fase 8 faalde de groepscheck nog één keer, omdat een patrouille te ver weg liep; nu staan de vijanden voor die check eerst op hun beginplek.

## Kaartindeling

Zie *Kaart verwerken* hierboven. Godot-coördinaten in meters: +X is oost, −Z is noord. De wereld volgt `docs/reference/kaart_elst.png` op 1,05 m per kaartpixel.
