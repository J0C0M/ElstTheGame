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
| 5 | `Add-Klaas-Dialogue-And-Shop` | Gebouwd, wacht op akkoord |
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
- **`Elst.tscn`** is één keer met een script gegenereerd (wegen, huizen, bomen en weilanden op basis van een vaste seed). Het script staat niet in de repo: de scene is nu de bron en wordt verder in de editor bewerkt.
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

## Voorlopige kaartindeling

`kaart_elst.png` ontbreekt nog. Tot die er is, gebruiken we deze indeling: de kerk in het midden, de andere vijf locaties eromheen. De richtingen volgen ruwweg het echte Elst (de kerk in het centrum, het station en het spoor aan de oostkant, Westeraam ten noordoosten van het station, de Over Betuwe College-kant ver in het zuidwesten). Het huis van Klaas staat op een korte loopafstand van alles, zodat het een goede hub is.

Godot-coördinaten in meters: +X is oost, −Z is noord. De kaart is ca. 500 × 500 m. De tornado is een ring met een vaste muur op 240 m van het midden; vanaf 222 m duwt de wind je terug.

| Kleur | Locatie | Plek | Positie (x, z) |
|---|---|---|---|
| Roze | De Kerk van Amber | Midden | (0, 0) |
| Paars | Huis van Klaas | Zuid, vlak bij het centrum | (−20, 110) |
| Blauw | Bingo Club Boomer Cave | West | (−130, −20) |
| Groen | Elst Station + gebouw ernaast | Oost, aan het spoor | (125, 30) |
| Geel | Westeraam Getho | Noordoost, voorbij het spoor | (160, −105) |
| Rood | OBC Elst Fort | Zuidwest | (−130, 130) |

- Het spoor loopt van noord naar zuid op ongeveer x = 110.
- Hoofdwegen lopen van de kerk naar elke locatie. Daartussen staan woonstraten en weilanden.
- De Aamsche Plas ligt in het zuidoosten rond (165, 128), het industrieterrein tussen het spoor en de plas.
- Fase 2 heeft dit uitgewerkt in `Elst.tscn`. Komt `kaart_elst.png` er alsnog, dan schuiven we de locaties in de editor en passen we deze tabel aan.
