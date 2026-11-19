# CLAUDE.md – Elst

Dit bestand geeft elke Claude Code-sessie de afspraken voor dit project. Lees het helemaal voordat je iets doet.

## Het project

*Elst* is een kleine, komische open-world actie-RPG in de stijl van Skyrim, die zich afspeelt in het dorp Elst (Gelderland). De speler bevrijdt Elst van Amber de Draak door drie facties te verslaan en vecht daarna samen met Klaas tegen Amber in de kerk.

- **Engine:** Godot 4.7 (laatste stabiele 4.x), GDScript met statische types.
- **Stijl:** low poly, platte kleuren, lichte retrofilter (PS1/N64-sfeer).
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
```

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
- **Componenten** (`res://scripts/components/`): `HealthComponent`, `StaminaComponent`, `Hitbox`, `Hurtbox`, `StateMachine`, `State`, `LootDropper`. Vijanden en bazen hergebruiken deze. Een `Hitbox` raakt elke `Hurtbox` één keer per activatie; de eigenaar van de `Hurtbox` beslist via `hit_received` wat een treffer doet (blokkeren, pantser, schade).
- **State machines:** de eigenaar roept `StateMachine.physics_update()` aan in zijn eigen `_physics_process`, zodat hij daarna het lichaam kan bewegen. Input gaat automatisch naar de huidige state. De states van de speler staan in `res://scenes/player/states/`.
- **Physics interpolation** staat aan. Beweeg en animeer in `_physics_process`, niet in `_process`. Roep na een teleport `reset_physics_interpolation()` aan. De camera heeft zelf interpolation uit en volgt in `_process` de positie uit `get_global_transform_interpolated()`.
- **InputMap:** gebruik altijd acties, nooit vaste toetsen in code. Acties: `move_forward/back/left/right` (WASD), `sprint` (Shift), `jump` (Spatie), `dodge` (Alt), `attack` (LMB), `block_aim` (RMB), `interact` (E), `weapon_sword` (1), `weapon_crossbow` (2), `use_potion` (Q), `inventory` (Tab), `quest_log` (J), `quicksave` (F5), `quickload` (F9), `pause` (Esc), `toggle_retro_filter` (F1), `cycle_pixel_size` (F2). Toetsen gebruiken de fysieke keycode.
- **Collision layers met een naam:** 1 `wereld`, 2 `speler`, 3 `vijand`, 4 `speler_hitbox`, 5 `vijand_hitbox`, 6 `interactie`, 7 `tornado_grens`. Gebruik in code de constanten uit `PhysicsLayers` (`res://scripts/physics_layers.gd`).
- **Low-poly placeholders:** bouw personages, gebouwen en props uit Godot-primitieven (`BoxMesh`, `CapsuleMesh`, `CylinderMesh`, `PrismMesh`, CSG voor gebouwen) met vlakke kleuren (`StandardMaterial3D`, geen texturen). Een personage bestaat uit losse delen voor hoofd, romp, armen en benen, en heeft simpele animaties. Klaas: lang, breed, gespierd, blond haar, strakke kaak, zwarte zonnebril. Houd modellen in aparte scenes, zodat ze later te vervangen zijn door Blender- of CC0-modellen. Factiekleuren: Westeraam geel/zwart, OBC rood/navy, Bingo blauw/pastel, Amber amber/oranje, Klaas paars/goud.
- **Retrofilter:** `res://scenes/main/RetroScreen.tscn` rendert de 3D-wereld in een `SubViewport` op lage resolutie (Midden 640×360, Laag 960×540, Uit = volle resolutie) en schaalt die met nearest-neighbour op. `res://shaders/retro_post.gdshader` doet kleurkwantisatie (32 tinten), 4×4 Bayer-dithering, vignette en filmruis. De HUD staat buiten de viewport en blijft scherp. Werelden laad je met `RetroScreen.set_world()`. Gebruik voor muislook `InputEventMouseMotion.screen_relative`, want `relative` wordt geschaald door de filter.
- **Opslaan:** JSON in `user://saves/`. Nodes in de groep `persist` hebben `save_data() -> Dictionary` en `load_data(data: Dictionary)`. Elk bestand heeft een veld `save_version`. Niet opslaan tijdens baasgevechten en scènes.
- **Assets en audio:** alleen zelfgemaakt materiaal of CC0. Noteer bron en licentie in `CREDITS.md`. Download geen betaalde assets of assets met een onduidelijke licentie.
- **`.gitignore`:** `.godot/`, `export/`, `build/`, `*.tmp`, `.claude/settings.local.json`. Commit `.import`- en `*.uid`-bestanden wel.
- **`docs/`** heeft een `.gdignore`, zodat Godot de referentieplaatjes niet importeert of exporteert.
- **Werelden:** elke speelbare scene (`Elst.tscn`, de dungeons, de testarena) heeft een `GameWorld`-root met `location_name` en `default_spawn`, een eigen `Player` en spawnpunten (`Marker3D` in de groep `spawn_points`, gevonden op nodenaam). Een wereldwissel gaat via `EventBus.world_change_requested(scene_path, spawn_id)`: `Main` fadet naar zwart, wisselt de wereld en neemt HP en stamina mee via `Player.save_data()`/`load_data()`.
- **Interactie:** `Interactable` (laag 6) toont zijn `prompt` als de speler ervoor staat; E roept `interact()` aan. `DungeonEntrance` gebruikt dat voor deuren (op slot of naar een andere scene). `LocationArea` toont een plaatsnaam en zet `GameState.current_location`.
- **Elst:** `scenes/world/Elst.tscn` is één keer gegenereerd met een script en wordt nu gewoon in de editor bewerkt. De zes kernlocaties zijn aparte scenes in `scenes/world/locations/`. Huizen (`House`) en bomen (`TreeProp`) bouwen hun mesh in code met vertexkleuren (`LowPolyMesh`): één draw call per prop.
- **Navigatie:** `Elst.tscn` bakt zijn navmesh bij het laden op een thread, uit de colliders van nodes in de groep `navigation_source` (laag 1). Nieuwe statische geometrie hoort onder zo'n node. In headless tests moet je echte tijd laten verstrijken (`OS.delay_msec`) voordat de navmap klaar is.
- **Tests met `-s`:** het hoofdscript wordt gecompileerd voordat de autoloads bestaan. Gebruik daarin dus geen projectklassen die autoloads aanroepen (zoals `Player`) als type, maar `Variant`.

## Codeconventies

- Scenes in PascalCase (`Player.tscn`), scripts en mappen in snake_case (`player_controller.gd`). Een script staat naast de scene waar het bij hoort; gedeelde scripts staan in `res://scripts/`.
- Code, namen en commentaar in het Engels. Tekst die de speler ziet in het Nederlands.
- Documentatiecommentaar met `##` boven klassen, exports, signals en publieke functies. Kort en alleen waar het iets toevoegt.
- Tabs voor inspringen (Godot-standaard).
