# Voortgang

Hier staat per fase wat af is, welke keuzes zijn gemaakt, waar we van het GDD afwijken en wat nog openstaat.

## Overzicht

| Fase | Branch | Status |
|---|---|---|
| 0 | `Setup-Project-Foundation` | Af, gemerged naar `Development` |
| 1 | `Add-Player-Controller-And-Combat` | Gebouwd, wacht op akkoord |
| 2 | `Build-Elst-World-Blockout` | Nog niet begonnen |
| 3 | `Add-Save-System` | Nog niet begonnen |
| 4 | `Add-Enemy-AI-And-Loot` | Nog niet begonnen |
| 5 | `Add-Klaas-Dialogue-And-Shop` | Nog niet begonnen |
| 6 | `Add-Quest-System-And-Tutorial` | Nog niet begonnen |
| 7 | `Add-Station-Dungeon` | Nog niet begonnen |
| 8 | `Add-Westeraam-Dungeon` | Nog niet begonnen |
| 9 | `Add-OBC-Fort-Dungeon` | Nog niet begonnen |
| 10 | `Add-Bingo-Cave-Dungeon` | Nog niet begonnen |
| 11 | `Add-Amber-Final-Battle` | Nog niet begonnen |
| 12 | `Polish-And-Release-Build` | Nog niet begonnen |

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
- [ ] **`docs/reference/kaart_elst.png` ontbreekt.** Tot die er is, geldt de voorlopige kaartindeling hieronder.
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
- `FilterTest.tscn` is niet meer de startwereld, maar staat er nog. Fase 2 vervangt hem door Elst.

### Aandachtspunten voor de volgende fases

- Vijanden in Fase 4 kunnen `HealthComponent`, `Hitbox`, `Hurtbox` en `StateMachine` overnemen zoals de trainingspop en de speler dat doen. `Hitbox.parried` is het signaal om uit balans te raken.
- Na een teleport of het laden van een save: `reset_physics_interpolation()` op de verplaatste node en `camera.snap_behind_target()` voor de speler (zie `Player.respawn()`).

## Voorlopige kaartindeling

`kaart_elst.png` ontbreekt nog. Tot die er is, gebruiken we deze indeling: de kerk in het midden, de andere vijf locaties eromheen. De richtingen volgen ruwweg het echte Elst (de kerk in het centrum, het station en het spoor aan de oostkant, Westeraam ten noordoosten van het station, de Over Betuwe College-kant ver in het zuidwesten). Het huis van Klaas staat op een korte loopafstand van alles, zodat het een goede hub is.

Godot-coördinaten in meters: +X is oost, −Z is noord. De kaart is ca. 500 × 500 m, met de tornado als ring op ongeveer 240 m van het midden.

| Kleur | Locatie | Plek | Positie (x, z) |
|---|---|---|---|
| Roze | De Kerk van Amber | Midden | (0, 0) |
| Paars | Huis van Klaas | Zuid, vlak bij het centrum | (−20, 110) |
| Blauw | Bingo Club Boomer Cave | West | (−130, −20) |
| Groen | Elst Station + gebouw ernaast | Oost, aan het spoor | (125, 30) |
| Geel | Westeraam Getho | Noordoost, voorbij het spoor | (190, −110) |
| Rood | OBC Elst Fort | Zuidwest | (−170, 170) |

- Het spoor loopt van noord naar zuid op ongeveer x = 110.
- Hoofdwegen lopen van de kerk naar elke locatie. Daartussen staan woonstraten en weilanden.
- Fase 2 werkt dit uit. Komt `kaart_elst.png` er alsnog, dan volgen we die en passen we deze tabel aan.
