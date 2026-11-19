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
| 10 | `Add-Bingo-Cave-Dungeon` | Gebouwd, wacht op akkoord |
| 11 | `Add-Amber-Final-Battle` | Nog niet begonnen |
| 12 | `Polish-And-Release-Build` | Nog niet begonnen |

Tussendoor: `Align-Elst-With-Map` (de kaart verwerken) is af en gemerged naar `Development`. `Lock-Faction-Dungeons-And-Expand-Westeraam` (factie-dungeons op slot en een groter Westeraam) is af en gemerged naar `Development`.

## Prototypes

- **Prototype 1** bestaat uit Fase 0 t/m 12: de oorspronkelijke visie van de game, van begin tot eind speelbaar. Daar werken we nu aan.
- **Prototype 2** begint pas als Prototype 1 af is. Wat erin komt, bepaalt de eigenaar dan. Een van de belangrijkste punten wordt graphics en details, waarschijnlijk met nog andere tweaks.
- **Tot die tijd** blijven modellen en wegen placeholders. Steek er alleen tijd in als de gameplay of de leesbaarheid het nodig heeft. Visuele punten die we tegenkomen, komen in de lijst hieronder.

### Verzamelde punten voor Prototype 2

- Modellen van objecten in de wereld (huizen, bomen, props) zijn nog niet mooi en kunnen veel beter (eigenaar, 19-11-2026).
- Paden en wegen zijn erg blokkerig en visueel slecht uitgewerkt: de grond is een raster van 1 m (eigenaar, 19-11-2026).
- Straten zijn op deze schaal maar 2 tot 3 m breed; daardoor zijn de huizen laag gehouden (zie *Kaart verwerken*).
- Fatbikers en het fatbike-kindje zitten op hun fiets met lopende benen; een echte rijhouding en draaiende wielen ontbreken nog.
- Oma's, opa's en Grumpy Oma zijn aangepaste kopieën van het driller-model. Een eigen model (handtas, rollator, krulletjes) maakt ze beter herkenbaar.
- De kruisboog is twee blokjes in de hand; een echt model en een zichtbare pijl op de boog ontbreken nog.

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

## Fase 10 – Quest 5: Bingo Club Boomer Cave

### Wat is af

- **Bingo-dungeon** (`scenes/dungeons/BingoCave.tscn`, gebouwd door `tools/dungeons/gen_bingo.py`): ongeveer 70 × 190 m met 24 vijanden (OBC 20, Westeraam 18), de zwaarste factie-dungeon, in twee delen met een checkpoint ertussen.
  - Deel 1, de bingoclub: de entree, een grote bingozaal met lange tafels en een podium met de bingomolen, de keuken (kist) en een gang.
  - Checkpoint: de koffiekamer, met een autosave en een rustbank.
  - Deel 2, de Boomer Cave: een grote grot met stalagmieten (kist), een grotgang en het hol van Grumpy Oma.
- **Boze oma's** (45 HP, 10 schade): slaan snel met hun handtas en rennen hard.
- **Bingo-opa's** (35 HP, 6 schade): roepen tijdens het gevecht bingonummers ("B-12!"). Elke vierde roep is "BINGO!": oma's binnen 10 m worden dan 5 s woest ("WOEST!" boven hun hoofd) en doen 25% meer schade. Pak dus eerst de opa's.
- **Nieuw in `Enemy`:** `buff_damage(factor, seconden, woord)` en `get_damage()`; aanvallen en projectielen gebruiken die.
- **Grumpy Oma** (550 HP, 18 schade, `scenes/bosses/GrumpyOma.tscn`): een enorme, dikke oma die vecht als een hulk.
  - Dichtbij geeft ze een klap.
  - Om de 3,5 s doet ze afwisselend een **grondslag** (ze springt naar je toe en bij de landing loopt er een schokgolf over de vloer: spring eroverheen) of een **tornado** (3 s ronddraaien door het hol, elke 0,7 s schade).
  - Na een grondslag of tornado is ze 2 s **uitgeput** ("* uitgeput *"): alleen dan krijgt ze volle schade. Anders vangt haar handtas 75% op.
  - Onder 30% HP wordt ze 35% sneller.
  - Tijdens het gevecht gaat het hek van het hol dicht en kun je niet opslaan. Ze laat 100 goud vallen en heeft kans op uitrusting.
- **Bingo Club bevrijd:** in Elst staan twee boze oma's en een bingo-opa bij de Bingo Club. Na Grumpy Oma (`boss_grumpy_oma`) lopen er dorpelingen ("BINGO! Echt waar deze keer!").
- **Quest 5 "Bingo Club Boomer Cave"** (`data/quests/q5_bingo.tres`): Klaas geeft hem na Quest 4 (Inwijding 4). Doelen: versla Grumpy Oma en ga terug naar Klaas. Beloning: 150 goud en Inwijding 5. Ook eerder verslagen telt.
- **De kruisboog:** na Quest 5 geeft Klaas zijn oude kruisboog (30 schade). Toets 2 pakt de kruisboog, toets 1 het zwaard. Met de rechtermuisknop richt je: de camera zoomt in, de speler kijkt mee met de camera en er verschijnt een vizier. Met de linkermuisknop schiet je een pijl (`scenes/player/Bolt.tscn`) naar het midden van het vizier; herladen duurt 0,9 s. Met de kruisboog kun je niet blokkeren.
- **Tests:** `tests/test_bingo.gd` (29 checks, allemaal geslaagd). `test_world` loopt ook in de Bingo-dungeon een route van de ingang naar Grumpy Oma. De andere tests slagen ook.

### Keuzes en afwijkingen

- **Grumpy Oma heeft 550 HP** in plaats van de 500 uit het GDD, zodat ze sterker is dan het fatbike-kindje (450), volgens de moeilijkheidsopbouw van de eigenaar.
- **Buiten haar uitputting komt 25% van de schade door**, zodat het gevecht niet vastloopt als je het patroon nog niet doorhebt, maar wachten op haar uitputting wel veel sneller gaat.
- **De Bingo Club wordt niet zwakker na het station**, net als de bazen. Het GDD noemt verzwakking alleen voor Westeraam en OBC.
- **De kruisboog** komt van Klaas na Quest 5, ook als je Grumpy Oma al eerder versloeg. Er zijn nog geen pijlen om te tellen; de kruisboog schiet onbeperkt met een herlaadtijd.
- **Na Quest 5** zegt Klaas "Nog niet" als je om een klus vraagt, tot Fase 11.

### Aandachtspunten voor de volgende fases

- Fase 11: de kerk gaat open als `boss_vape_koning`, `boss_fatbike_kindje` en `boss_grumpy_oma` gezet zijn. Klaas vecht mee; de kruisboog is handig tegen Amber in de lucht.
- Fase 12: geluid voor de bingonummers, de schokgolf en de kruisboog.

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

- [ ] **Bron van de kaart** (Google Maps of OpenStreetMap). Tot dat duidelijk is, staat `kaart_elst.png` niet in de repo en kan het script alleen draaien als de kaart lokaal in `docs/reference/` staat. Ook het raster `elst_ground.png` is van de kaart afgeleid.
- [ ] **Ligging van het spoor** bevestigen.
- [x] **`test_enemies` faalde af en toe** in de stationsdungeon, omdat de vijanden willekeurig patrouilleren. Sinds Fase 7 speelt de test in een eigen, langere testkamer. In Fase 8 faalde de groepscheck nog één keer, omdat een patrouille te ver weg liep; nu staan de vijanden voor die check eerst op hun beginplek.

## Kaartindeling

Zie *Kaart verwerken* hierboven. Godot-coördinaten in meters: +X is oost, −Z is noord. De wereld volgt `docs/reference/kaart_elst.png` op 1,05 m per kaartpixel.
