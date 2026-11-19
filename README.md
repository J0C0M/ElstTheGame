# Elst

Een kleine, komische open-world actie-RPG in de stijl van Skyrim, die zich afspeelt in het dorp Elst (Gelderland). Bevrijd Elst van Amber de Draak: sloop haar aanvoerlijn bij Station Elst, versla de drie facties die het dorp bezetten en neem het daarna samen met Klaas tegen Amber op in de kerk.

- **Engine:** Godot 4.7, GDScript
- **Stijl:** low poly met platte kleuren en een lichte retrofilter
- **Platform:** pc (Windows en Linux), muis en toetsenbord

De game wordt in 13 fases gebouwd. Zie [`docs/GDD.md`](docs/GDD.md) voor het ontwerp en [`docs/PROGRESS.md`](docs/PROGRESS.md) voor de stand van zaken.

## Openen in Godot

1. Installeer [Godot 4.7](https://godotengine.org/download) (de standaardversie, niet .NET).
2. Start Godot, kies **Importeren** en selecteer `project.godot` in deze map.
3. Druk op **F5** (of de afspeelknop) om de hoofdscene `res://scenes/main/Main.tscn` te starten. Je komt in het hoofdmenu; met **Nieuw spel** begin je in Elst, in de tuin van Klaas. Het kompas bovenin wijst je de weg naar Klaas, die je de eerste quest geeft.

Vanaf de commandoregel:

```bash
godot --path .
```

## Besturing

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
| Retrofilter aan/uit | F1 |
| Pixelgrootte wisselen (laag, midden, uit) | F2 |

De toetsen zitten in de InputMap van het project. Niet alles werkt al: dat hangt af van de fase waarin het project zit. Tijdens het spelen is de muis gevangen voor de camera; in het pauzemenu is hij vrij.

## Opslaan

Opslaan werkt zoals in Skyrim: via het pauzemenu (Esc) met een eigen naam, met een quicksave (F5, laden met F9) en automatisch bij het binnengaan van een dungeon, bij slapen en na elk questdoel. Ga je dood, dan laadt de nieuwste save. De saves staan in de gebruikersmap van Godot, in `saves/`.

## Testen

```bash
godot --headless --path . -s res://tests/check_resources.gd
godot --headless --path . --fixed-fps 60 -s res://tests/test_player_combat.gd
godot --headless --path . --fixed-fps 60 -s res://tests/test_world.gd
godot --headless --path . --fixed-fps 60 -s res://tests/test_save.gd
godot --headless --path . --fixed-fps 60 -s res://tests/test_enemies.gd
godot --headless --path . --fixed-fps 60 -s res://tests/test_klaas.gd
godot --headless --path . --fixed-fps 60 -s res://tests/test_quests.gd
godot --headless --path . --fixed-fps 60 -s res://tests/test_station.gd
godot --headless --path . --fixed-fps 60 -s res://tests/test_westeraam.gd
godot --headless --path . --fixed-fps 60 -s res://tests/test_obc.gd
godot --headless --path . --fixed-fps 60 -s res://tests/test_bingo.gd
```

De eerste laadt alle scenes, scripts en resources. De tweede speelt de testarena met gesimuleerde input en controleert lopen, stamina, ontwijken, aanvallen, blokkeren, parry, doodgaan en terugkomen. De derde start het spel in Elst en controleert het startpunt, de navmesh, de kerk die op slot zit, de tornado en de weg in en uit elke dungeon. De vierde test opslaan en laden, de vijfde de vijanden, de buit en de kisten, de zesde Klaas, zijn winkel en de uitrusting. De zevende speelt Quest 1 (de tutorial) van begin tot eind en controleert het kompas, het questlog en opslaan halverwege. De achtste speelt Quest 2: de station-dungeon, de vier generators, het verzwakkingseffect en de beloning. De negende speelt Quest 3: de vape-drillers, het gevecht met de Vape-koning en de bevrijde gebieden met dorpelingen. De tiende speelt Quest 4: de voetballers, de fatbikers en het gevecht met het fatbike-kindje. De elfde speelt Quest 5: de oma's en hun BINGO!, het checkpoint, het gevecht met Grumpy Oma en de kruisboog.

## Mappen

```
autoload/   EventBus, GameState, SaveManager, QuestManager, AudioManager, Settings
scenes/     main, world, dungeons, player, npcs, enemies, bosses, ui
scripts/    components (HealthComponent, Hitbox, ...) en data (Resource-klassen)
data/       .tres-bestanden voor items, vijanden, quests en dialogen
shaders/    retro_post.gdshader
assets/     modellen, audio, fonts
docs/       GDD, voortgang en referentiebeelden
tests/      headless tests
tools/      Python-scripts, zoals de generator van Elst (tools/map)
```

## Credits

Zie [`CREDITS.md`](CREDITS.md).
