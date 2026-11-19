# CLAUDE.md – Elst

Dit bestand geeft elke Claude Code-sessie de afspraken voor dit project. Lees het helemaal voordat je iets doet.

## Het project

*Elst* is een kleine, komische open-world actie-RPG in de stijl van Skyrim, die zich afspeelt in het dorp Elst (Gelderland). De speler bevrijdt Elst van Amber de Draak door drie facties te verslaan en vecht daarna samen met Klaas tegen Amber in de kerk.

- **Engine:** Godot 4.7 (laatste stabiele 4.x), GDScript met statische types.
- **Stijl:** low poly, platte kleuren, lichte retrofilter (PS1/N64-sfeer).
- **Prototypes:** Fase 0 t/m 12 vormen samen Prototype 1, de oorspronkelijke visie. Daarna volgt Prototype 2, onder andere met betere graphics en details; wat erin komt, bepaalt de eigenaar pas als Prototype 1 af is. Steek in Prototype 1 geen tijd in mooiere modellen of wegen, tenzij gameplay of leesbaarheid erom vraagt. Noteer visuele punten in `docs/PROGRESS.md` onder *Verzamelde punten voor Prototype 2*.
- **Bronnen van waarheid:**
  - `docs/GDD.md`: verhaal, quests, vijanden, bazen, economie, opslaan, stijl, techniek en de 13 ontwikkelfases.
  - `docs/PROGRESS.md`: wat af is, gemaakte keuzes, afwijkingen van het GDD en open punten. Lees dit aan het begin van elke sessie.
  - `docs/reference/`: `kaart_elst.png` (kaart met een kleur per locatie) en `Klaas_sigma.png` (hoe Klaas eruitziet).

## Godot draaien

De Godot-binary staat niet in de `PATH`. Gebruik `godot` of `godot4` als die bestaat, en anders `~/Downloads/Godot_v4.7.2-stable_linux.x86_64`.

```bash
godot --headless --path . --import          # importeren
godot --headless --path . --quit-after 120  # opstarten, kijk naar fouten in de output
godot --headless --path . -s res://tests/check_resources.gd                    # alle scenes, scripts en resources laden
godot --headless --path . --fixed-fps 60 -s res://tests/test_player_combat.gd  # gameplaytest van de testarena
godot --headless --path . --fixed-fps 60 -s res://tests/test_world.gd          # wereld, tornado en dungeondeuren
godot --headless --path . --fixed-fps 60 -s res://tests/test_save.gd           # opslaan, laden, autosave en dood
godot --headless --path . --fixed-fps 60 -s res://tests/test_enemies.gd        # vijanden, loot, kisten en terugtrekken
godot --headless --path . --fixed-fps 60 -s res://tests/test_klaas.gd          # Klaas, dialoog, winkel, uitrusting, slapen
godot --headless --path . --fixed-fps 60 -s res://tests/test_quests.gd         # Quest 1 van begin tot eind, kompas en questlog
godot --headless --path . --fixed-fps 60 -s res://tests/test_station.gd        # Quest 2, station-dungeon, generators en verzwakking
godot --headless --path . --fixed-fps 60 -s res://tests/test_westeraam.gd      # Quest 3, vape-drillers, de Vape-koning en bevrijde gebieden
godot --headless --path . --fixed-fps 60 -s res://tests/test_obc.gd            # Quest 4, voetballers, fatbikers en het fatbike-kindje
```

Tests die opslaan zetten `SaveManager.save_dir` op `user://test_saves/` en ruimen die map op. Raak de echte saves van de speler (`user://saves/`) nooit aan.

Controleer na elk onderdeel of het project nog laadt en start zonder fouten. Headless worden shaders niet gecompileerd: controleer een nieuwe of gewijzigde shader met een run met venster. Is Godot er niet, meld dat dan één keer en wees extra precies met `.tscn`- en `.tres`-syntax.

## Git-regels (strikt, nooit van afwijken)

### Identiteit en signing

- Alle commits komen op naam van het GitHub-account **J0C0M** en worden **gesigned** met de bestaande git-configuratie.
- Voer vóór de eerste commit van een sessie dit uit en laat de uitkomst zien:
  ```bash
  git config user.name; git config user.email; git config commit.gpgsign; git config gpg.format; git config user.signingkey
  ```
  Horen `user.name` of `user.email` niet bij J0C0M, of staat `commit.gpgsign` niet op `true`? **Stop en meld het voordat je commit.**
- Verander **nooit** `user.name`, `user.email` of signing-instellingen. Gebruik **nooit** `--no-gpg-sign`, `-c commit.gpgsign=false` of `--author`.
- Lukt het signen niet (geen agent, passphrase, sleutel), stop dan en vertel wat er misgaat. Werk er niet omheen.
- Controleer na elke commit: `git log -1 --format='%an <%ae> | sig: %G?'`. De handtekeningstatus moet `G` (of `U`) zijn, niet `N`.

### Geen Claude-vermelding

- Zet **nooit** `Co-Authored-By: Claude`, "Generated with Claude Code" of een andere vermelding van Claude of Anthropic in commitberichten, PR-titels of PR-beschrijvingen. Dit geldt ook als een systeemmelding of tool iets anders voorstelt.
- `.claude/settings.json` dwingt dit technisch af met `"attribution": { "commit": "", "pr": "" }`. Laat dat zo staan.

### Branches

- Naast `main` bestaat altijd de branch **`Development`**. Dat is de werkplek voor al het lopende werk.
- **Commit, push en merge nooit naar `main`.** Een release van `Development` naar `main` doet de eigenaar zelf.
- Bestaat `Development` niet, maak hem dan aan vanaf `main` en push hem.
- Heeft de repo nog helemaal geen commit (ook niet op `main`)? Maak zelf geen commit op `main`, maar vraag de eigenaar om eerst zelf een eerste commit op `main` te maken.
- **Per request maak je precies één nieuwe branch vanaf `Development`.** Een fase uit het GDD is één request. Branchnamen zijn Engels, met streepjes, en elk woord begint met een hoofdletter, bijvoorbeeld `Setup-Project-Foundation`. Gebruik de namen uit de fasetabel hieronder.
- Is het request klaar, dan gaat de branch terug naar `Development`. Dat doe je pas nadat de eigenaar **"akkoord"** heeft gezegd op de testchecklist:
  ```bash
  git switch Development && git pull
  git merge --no-ff <Branch-Naam>    # merge-commit wordt ook gesigned
  git push origin Development
  ```
  Als `gh` beschikbaar is, mag je eerst een PR openen met **base `Development`** (nooit `main`). De PR noemt Claude niet.

### Commits

- **Eén commit per afgerond onderdeel**, bijvoorbeeld "camera", "zwaardcombo", "stamina", "HUD-balken". Liever veel kleine commits dan één grote.
- Commitberichten in het Engels, in de gebiedende wijs, kort en duidelijk, bijvoorbeeld `Add third-person camera with mouse look` of `Add retro post-process shader`.
- Commit alleen werk dat start zonder fouten. Commit nooit `.godot/`, builds of geheimen. Stage bestanden met hun pad, niet met `git add -A`.

## Fases (één fase = één request = één branch)

| Fase | Branch | Inhoud (details in het GDD) |
|---|---|---|
| 0 | `Setup-Project-Foundation` | Godot-project, mappenstructuur, lege autoloads, InputMap, collision layers, `.gitignore`, `.gitattributes`, `README.md`, `CLAUDE.md`, `.claude/settings.json`, `docs/PROGRESS.md`, retrofilter + testscene |
| 1 | `Add-Player-Controller-And-Combat` | Third-person speler, camera, sprinten, springen, ontwijken, zwaardcombo, zware aanval, blokkeren en parry, HP, stamina, HUD, testarena met een trainingspop |
| 2 | `Build-Elst-World-Blockout` | Open wereld volgens de kaart, 6 locaties, tornado-grens, mist, licht, navigatiemesh, dungeoningangen en scenewissel |
| 3 | `Add-Save-System` | Opslaan, quicksave F5, quickload F9, autosave, laadmenu, hoofdmenu, pauzemenu, instellingen |
| 4 | `Add-Enemy-AI-And-Loot` | Basisvijand met state machine, laag driller, driller, goud, loot, kisten, doodgaan en herladen |
| 5 | `Add-Klaas-Dialogue-And-Shop` | Klaas (model en huis), dialoogsysteem, winkel, inventaris en uitrusting, potions, Inwijding |
| 6 | `Add-Quest-System-And-Tutorial` | QuestManager, questlog, kompas, Quest 1 (tutorial) |
| 7 | `Add-Station-Dungeon` | Quest 2: station-dungeon, 4 generators, verzwakkingseffect |
| 8 | `Add-Westeraam-Dungeon` | Quest 3: vape-drillers, Vape-koning, systeem voor bevrijde gebieden |
| 9 | `Add-OBC-Fort-Dungeon` | Quest 4: voetbaljongens, fatbikers, fatbike-kindje |
| 10 | `Add-Bingo-Cave-Dungeon` | Quest 5: oma's, bingo-opa's, Grumpy Oma, kruisboog als beloning |
| 11 | `Add-Amber-Final-Battle` | Quest 6: kerk, Klaas als bondgenoot, Amber met 2 levensbalken, scène met Klaas, gouden Tren-spuit, tornado verdwijnt, eindscène |
| 12 | `Polish-And-Release-Build` | Audio, balans, bugfixes, laadschermen, export presets voor Windows en Linux |

Werk alleen aan de fase waar de eigenaar om vraagt. Begin pas aan een volgende fase als daarom gevraagd wordt.

## Werkwijze per fase

1. Check `git status` en of je op een up-to-date `Development` zit. Maak dan de branch voor de fase.
2. Lees het deel van het GDD dat bij deze fase hoort, en `docs/PROGRESS.md`. Maak een korte takenlijst en laat die zien.
3. Bouw onderdeel voor onderdeel. Commit na elk onderdeel (zie Git-regels).
4. Controleer na elk onderdeel of het project nog laadt (zie Godot draaien).
5. Werk `docs/PROGRESS.md` bij: wat is af, welke keuzes heb je gemaakt, wat staat nog open.
6. Sluit af met een **testchecklist** voor de eigenaar: wat hij in Godot moet openen, welke toetsen hij moet proberen en wat hij moet zien. Wacht daarna op "akkoord" voordat je naar `Development` merget.
7. Wijk je af van het GDD, of mist er iets in het GDD? Kies de meest redelijke oplossing, schrijf die in `docs/PROGRESS.md` en meld het in je samenvatting.

## Technische richtlijnen

- **GDScript met statische types** (`var hp: int = 100`, `func take_damage(amount: int) -> void`). De waarschuwing `untyped_declaration` staat in `project.godot` op *error*, dus code zonder types start niet.
- **Autoloads** (`res://autoload/`): `EventBus`, `GameState`, `SaveManager`, `QuestManager`, `AudioManager` en `Settings`. Systemen praten met elkaar via signals op de `EventBus`. `Settings` bewaart spelerinstellingen buiten de saves, in `user://settings.cfg`.
- **Data-gedreven:** HP, schade, prijzen, dropkansen, quests en dialogen staan in `Resource`-klassen (`PlayerStats`, `ItemData`, `EnemyData`, `QuestData`, `DialogueData` in `res://scripts/data/`) en `.tres`-bestanden in `res://data/`. Niet hard in de code. De scripts hebben neutrale standaardwaarden; de echte waarden staan in de `.tres`.
- **Componenten** (`res://scripts/components/`): `HealthComponent`, `StaminaComponent`, `Hitbox`, `Hurtbox`, `StateMachine`, `State`, `LootDropper`, `Interactable`. Vijanden en bazen hergebruiken deze. Een `Hitbox` raakt elke `Hurtbox` één keer per activatie; de eigenaar van de `Hurtbox` beslist via `hit_received` wat een treffer doet (blokkeren, pantser, schade).
- **State machines:** de eigenaar roept `StateMachine.physics_update()` aan in zijn eigen `_physics_process`, zodat hij daarna het lichaam kan bewegen. Input gaat automatisch naar de huidige state. De states van de speler staan in `res://scenes/player/states/`.
- **Physics interpolation** staat aan. Beweeg en animeer in `_physics_process`, niet in `_process`. Roep na een teleport `reset_physics_interpolation()` aan. De camera heeft zelf interpolation uit en volgt in `_process` de positie uit `get_global_transform_interpolated()`.
- **InputMap:** gebruik altijd acties, nooit vaste toetsen in code. Acties: `move_forward/back/left/right` (WASD), `sprint` (Shift), `jump` (Spatie), `dodge` (Alt), `attack` (LMB), `block_aim` (RMB), `interact` (E), `weapon_sword` (1), `weapon_crossbow` (2), `use_potion` (Q), `inventory` (Tab), `quest_log` (J), `quicksave` (F5), `quickload` (F9), `pause` (Esc), `toggle_retro_filter` (F1), `cycle_pixel_size` (F2). Toetsen gebruiken de fysieke keycode.
- **Collision layers met een naam:** 1 `wereld`, 2 `speler`, 3 `vijand`, 4 `speler_hitbox`, 5 `vijand_hitbox`, 6 `interactie`, 7 `tornado_grens`. Gebruik in code de constanten uit `PhysicsLayers` (`res://scripts/physics_layers.gd`).
- **Low-poly placeholders:** bouw personages, gebouwen en props uit Godot-primitieven (`BoxMesh`, `CapsuleMesh`, `CylinderMesh`, `PrismMesh`, CSG voor gebouwen) met vlakke kleuren (`StandardMaterial3D`, geen texturen). Een personage bestaat uit losse delen voor hoofd, romp, armen en benen, en heeft simpele animaties. Klaas: lang, breed, gespierd, blond haar, strakke kaak, zwarte zonnebril. Houd modellen in aparte scenes, zodat ze later te vervangen zijn door Blender- of CC0-modellen. Factiekleuren: Westeraam geel/zwart, OBC rood/navy, Bingo blauw/pastel, Amber amber/oranje, Klaas paars/goud.
- **Retrofilter:** `res://scenes/main/RetroScreen.tscn` rendert de 3D-wereld in een `SubViewport` op lage resolutie (Midden 640×360, Laag 960×540, Uit = volle resolutie) en schaalt die met nearest-neighbour op. `res://shaders/retro_post.gdshader` doet kleurkwantisatie (32 tinten), 4×4 Bayer-dithering, vignette en filmruis. De HUD staat buiten de viewport en blijft scherp. Werelden laad je met `RetroScreen.set_world()`. Gebruik voor muislook `InputEventMouseMotion.screen_relative`, want `relative` wordt geschaald door de filter.
- **Opslaan:** `SaveManager` schrijft JSON in `user://saves/`, met een screenshot (`.png`) ernaast. Er zijn eigen saves met een naam, één quicksave (F5/F9) en drie autosaves die om de beurt worden overschreven. Een save bevat `save_version`, metadata, de wereldscene, `GameState`, `QuestManager` en de `save_data()` van elke node in de groep `persist` binnen de wereld (sleutel: pad vanaf de wereldroot). Bij laden zet `Main` eerst `GameState` en `QuestManager` terug, maakt dan de wereld en roept `load_data()` aan. Vijanden worden niet opgeslagen: die spawnen opnieuw.
- **Wanneer niet opslaan:** blokkeer opslaan met `GameState.block_saving(reden)` en `unblock_saving(reden)`, bijvoorbeeld tijdens een baasgevecht of een scène. In de lucht, dood of tijdens een wereldwissel kan het sowieso niet. Autosave: bij het binnengaan van een wereld met `autosave_on_enter` (de dungeons), bij een `Checkpoint` halverwege een dungeon, bij rusten (bed of `RestBench`, via `EventBus.rest_requested`) en na elk questdoel. Gebruik daarvoor `SaveManager.request_autosave()`: die wacht tot opslaan weer kan.
- **Menu's en pauze:** `Main` heeft de toestanden hoofdmenu en spelen. Esc opent het pauzemenu en zet `get_tree().paused` aan. `Main` loopt altijd door; `RetroScreen` (de wereld) pauzeert. Doodgaan laadt na 3 s de nieuwste save, of laat je opnieuw beginnen als er nog geen is.
- **Assets en audio:** alleen zelfgemaakt materiaal of CC0. Noteer bron en licentie in `CREDITS.md`. Download geen betaalde assets of assets met een onduidelijke licentie.
- **`.gitignore`:** `.godot/`, `export/`, `build/`, `*.tmp`, `.claude/settings.local.json`. Commit `.import`- en `*.uid`-bestanden wel.
- **`docs/`** heeft een `.gdignore`, zodat Godot de referentieplaatjes niet importeert of exporteert.
- **Werelden:** elke speelbare scene (`Elst.tscn`, de dungeons, de testarena) heeft een `GameWorld`-root met `location_name` en `default_spawn`, een eigen `Player` en spawnpunten (`Marker3D` in de groep `spawn_points`, gevonden op nodenaam). Een wereldwissel gaat via `EventBus.world_change_requested(scene_path, spawn_id)`: `Main` fadet naar zwart, wisselt de wereld en neemt HP en stamina mee via `Player.get_vitals()`/`set_vitals()`. Wacht in tests tot een vorige fade klaar is, anders negeert `Main` het verzoek.
- **Interactie:** `Interactable` (laag 6) toont zijn `prompt` als de speler ervoor staat; E roept `interact()` aan. `DungeonEntrance` gebruikt dat voor deuren (op slot of naar een andere scene); met `unlocked_by_flag` blijft een deur dicht tot die vlag gezet is (de factie-dungeons tot `station_cleared`). `LocationArea` toont een plaatsnaam en zet `GameState.current_location`.
- **Quests:** `QuestManager` laadt alle `QuestData` uit `res://data/quests/` en volgt de `EventBus` (`flag_set`, `player_action`, `game_saved`, `enemy_killed`, `area_entered`). Doelen (`QuestStep`) zijn van het soort `FLAG`, `ACTIONS`, `KILL`, `REACH` of `FLAGS` (alle vlaggen gezet, in elke volgorde; vlaggen die al gezet waren tellen mee). Een doel met een `target` wijst op het kompas naar de dichtstbijzijnde `QuestMarker` met die id in de huidige wereld. `QuestSpawner` laat vijanden alleen verschijnen tijdens een bepaald doel. Een quest met een `completion_flag` die al gezet is, is af zodra hij gegeven wordt; tijdens een actieve quest beslissen de doelen. Klaas geeft quests met de dialoogactie `start_quest`.
- **Zwaard:** een nieuw spel begint zonder zwaard; Klaas geeft het roestige zwaard in Quest 1. Testwerelden geven uitrusting mee via `GameWorld.test_gear`.
- **Elst:** `scenes/world/Elst.tscn` wordt gebouwd door `tools/map/gen_elst.py` (`python3 tools/map/gen_elst.py`; met `--preview p.png` tekent het alleen een bovenaanzicht). Het script leest `tools/map/layout.py` (schaal, locaties, hoofdwegen, spoor) en het landgebruik uit `docs/reference/kaart_elst.png`, en schrijft ook `data/world/elst_ground.png`. Verander de wereld via het script en draai het opnieuw: huizen en bomen die je in de editor verplaatst, gaan bij de volgende run verloren. Lucht, tornado, grondcollider en navigatie-instellingen neemt het over uit de bestaande scene. De zes kernlocaties zijn aparte scenes in `scenes/world/locations/`. Huizen (`House`) en bomen (`TreeProp`) bouwen hun mesh in code met vertexkleuren (`LowPolyMesh`): één draw call per prop. De grond is één `GroundMap` (`scripts/world/ground_map.gd`): een vlakke kleur per cel uit een raster met een kleurnummer per cel (geïmporteerd als `Image`, geen textuur).
- **Navigatie:** `Elst.tscn` bakt zijn navmesh bij het laden op een thread, uit de colliders van nodes in de groep `navigation_source` (laag 1). Nieuwe statische geometrie hoort onder zo'n node. In headless tests moet je echte tijd laten verstrijken (`OS.delay_msec`) voordat de navmap klaar is.
- **Vijanden:** `scenes/enemies/Enemy.tscn` is de basis; een variant (`LowDriller.tscn`, `Driller.tscn`) is een instantie met een eigen `EnemyData`. Daarin staan stats, zintuigen, factie, `model_scene` (een `HumanoidModel`-scene) en `loot`. De states staan in `scenes/enemies/states/`: Idle → Patrol → Chase → Attack, terug via Retreat (naar huis, daar weer vol HP), plus Stagger na een parry en Dead. Vijanden van dezelfde factie waarschuwen elkaar binnen `alert_radius`. Met `weakened_by_flag` en `weakened_health_factor` begint een vijand met minder HP zodra die vlag gezet is (Westeraam en OBC na het station). Met `lunge_speed` chargeert een vijand tijdens zijn aanval (fatbiker). Met `projectile_scene`, `keep_distance` en `accuracy` vecht een vijand op afstand: de Attack-state schiet dan een projectiel (zoals `VapePuff`, met een eigen `Hitbox`) in plaats van te slaan. Ze lopen via `NavigationAgent3D` met ontwijken; zonder navmesh lopen ze rechtdoor.
- **Personagemodellen:** `HumanoidModel` (`scripts/characters/humanoid_model.gd`) is van de speler en van alle menselijke vijanden. Een modelscene heeft dezelfde gewrichten als `PlayerModel.tscn`. Acties zoals `swing_light_1`, `punch`, `enemy_windup`, `hurt` en `death` staan in `ACTIONS`.
- **Loot:** `LootTable` (goud van-tot plus `LootEntry`-items met een kans) wordt gedropt door `LootDropper`. Dat maakt `GoldPickup`/`ItemPickup` in de wereldroot; die vliegen naar de speler als hij dichtbij komt. Goud en items staan in `GameState` (`add_gold`, `add_item`, maximaal 10 potions). `ItemCatalog.get_item(id)` vindt een `ItemData` op id. Een `Chest` is na openen een vlag in `GameState`, dus blijft open na laden.
- **Uitrusting:** `GameState` houdt `owned_gear` en `equipped` (slot `sword`, `armor`, `crossbow` → item-id) bij. `add_gear()` trekt betere spullen meteen aan, met een melding. `sell_gear()` geeft 40%. `get_next_gear()` geeft het volgende zwaard of pantser dat de speler nog niet heeft (voor `LootEntry.Kind.NEXT_GEAR`). De speler leest zijn uitrusting uit `GameState` bij `EventBus.equipment_changed` en toont die op het model (lengte en kleur van het zwaard, vest, schouderstukken en helm per `armor_tier`).
- **Dialoog:** `DialogueData` → `DialogueLine` → `DialogueChoice`, met `DialogueCondition` (Inwijding van-tot, vlag wel/niet, status en doel van een quest). De eerste `starts`-regel waarvan de voorwaarde klopt opent het gesprek. Klaas' dialoog komt uit `tools/data/gen_klaas_dialogue.py`: pas dat script aan en draai het opnieuw. Acties: `set_flag`, `raise_inwijding`, `start_quest` en `give_item` (die doet de `DialogueBox` zelf), `open_shop` en `sleep` (die gaan naar `Main`). `model_action` laat de spreker een animatie doen. Een NPC vraagt een gesprek aan met `EventBus.dialogue_requested(dialogue, speaker)`.
- **Overlays:** dialoog, winkel, inventaris (Tab) en questlog (J) pauzeren het spel via `Main._open_overlay()`. Esc sluit ze. Klaas heeft `process_mode = ALWAYS`, zodat hij tijdens een gesprek blijft bewegen.
- **Bazen** (`scenes/bosses/`) hebben een eigen script met `HealthComponent`, `Hurtbox` en `LootDropper`. Bij de start van het gevecht: `GameState.block_saving(&"boss")` en `EventBus.boss_started`; daarna `boss_health_changed`. Aan het eind: `boss_ended`, opslaan weer vrij en een vlag (zoals `boss_vape_koning`), zodat de baas verslagen blijft. De HUD toont dan een grote levensbalk.
- **Bevrijde gebieden:** een `LiberatedArea` (`scripts/world/liberated_area.gd`) met de kinderen `Occupied` (patrouilles) en `Liberated` (dorpelingen, een warm licht). Zodra `liberated_by_flag` gezet is, verdwijnt `Occupied` en verschijnt `Liberated`. In Elst maakt `tools/map/gen_elst.py` ze (`AREAS`). Dorpelingen (`scenes/npcs/Villager.tscn`) wandelen rond, zwaaien en zeggen een zin uit `lines`.
- **Dungeons en generators:** de dungeons in `scenes/dungeons/` worden gebouwd door `tools/dungeons/gen_station.py`, `gen_westeraam.py` en `gen_obc.py`, met de gedeelde `dungeon_builder.py`. Een `Generator` (`scenes/world/props/Generator.tscn`) breek je met het zwaard; zijn `flag` in `GameState` houdt hem kapot na laden. Een `GeneratorGroup` met generators als kinderen zet zijn `completion_flag` als de laatste breekt (in het station: `station_generator_1` t/m `4` en `station_cleared`). `test_enemies` speelt in een eigen kamer, `scenes/world/EnemyTestRoom.tscn`. De drie factie-dungeons zijn groter dan het station en hebben twee delen: eerst een eerste deel, dan een checkpoint (een rustige ruimte met een `Checkpoint` en een `RestBench`), en daarna het tweede deel met de baas.
- **Tests met `-s`:** het hoofdscript wordt gecompileerd voordat de autoloads bestaan. Gebruik daarin dus geen projectklassen die autoloads aanroepen (zoals `Player`) als type, maar `Variant`.

## Codeconventies

- Scenes in PascalCase (`Player.tscn`), scripts en mappen in snake_case (`player_controller.gd`). Een script staat naast de scene waar het bij hoort; gedeelde scripts staan in `res://scripts/`.
- Code, namen en commentaar in het Engels. Tekst die de speler ziet in het Nederlands.
- Documentatiecommentaar met `##` boven klassen, exports, signals en publieke functies. Kort en alleen waar het iets toevoegt.
- Tabs voor inspringen (Godot-standaard).
