"""Writes data/dialogue/klaas.tres: Klaas' conversation, with Quest 1 to 3.

Run from the project root: python3 tools/data/gen_klaas_dialogue.py
"""
import pathlib

conditions = {}
subs = []


def cond(**fields):
    key = tuple(sorted(fields.items()))
    if key not in conditions:
        cid = f"Condition_{len(conditions) + 1}"
        conditions[key] = cid
        lines = [f'[sub_resource type="Resource" id="{cid}"]', 'script = ExtResource("2_condition")']
        for name, value in fields.items():
            lines.append(f'{name} = &"{value}"' if isinstance(value, str) else f"{name} = {value}")
        subs.append(lines)
    return conditions[key]


choice_count = 0


def choice(text, next_id="", condition=None, action="", value=""):
    global choice_count
    choice_count += 1
    cid = f"Choice_{choice_count}"
    lines = [f'[sub_resource type="Resource" id="{cid}"]', 'script = ExtResource("3_choice")', f'text = "{text}"']
    if next_id:
        lines.append(f'next = &"{next_id}"')
    if condition:
        lines.append(f'condition = SubResource("{condition}")')
    if action:
        lines.append(f'action = &"{action}"')
    if value:
        lines.append(f'action_value = "{value}"')
    subs.append(lines)
    return cid


line_ids = []


def line(id_, text, next_id="", choices=(), condition=None, action="", value="", model_action=""):
    lid = f"Line_{id_}"
    lines = [f'[sub_resource type="Resource" id="{lid}"]', 'script = ExtResource("4_line")', f'id = &"{id_}"', f'text = "{text}"']
    if next_id:
        lines.append(f'next = &"{next_id}"')
    if choices:
        lines.append('choices = Array[ExtResource("3_choice")]([' + ", ".join(f'SubResource("{c}")' for c in choices) + "])")
    if condition:
        lines.append(f'condition = SubResource("{condition}")')
    if action:
        lines.append(f'action = &"{action}"')
    if value:
        lines.append(f'action_value = "{value}"')
    if model_action:
        lines.append(f'model_action = &"{model_action}"')
    subs.append(lines)
    line_ids.append(lid)


Q1 = "q1_tutorial"
q1_first_talk = cond(quest_id=Q1, quest_status=1, quest_step="talk_to_klaas")
q1_report = cond(quest_id=Q1, quest_status=1, quest_step="report")
q1_active = cond(quest_id=Q1, quest_status=1)
q1_done = cond(quest_id=Q1, quest_status=2)
Q2 = "q2_station"
q2_offer = cond(min_inwijding=1, quest_id=Q2, quest_status=0, forbidden_flag="station_cleared")
q2_early = cond(min_inwijding=1, quest_id=Q2, quest_status=0, required_flag="station_cleared")
q2_active = cond(quest_id=Q2, quest_status=1)
q2_report = cond(quest_id=Q2, quest_status=1, quest_step="report")
Q3 = "q3_westeraam"
# Klaas gives the quests in order, so Inwijding 2 means Quest 2 is done.
q3_offer = cond(min_inwijding=2, quest_id=Q3, quest_status=0, forbidden_flag="boss_vape_koning")
q3_early = cond(min_inwijding=2, quest_id=Q3, quest_status=0, required_flag="boss_vape_koning")
q3_active = cond(quest_id=Q3, quest_status=1)
q3_report = cond(quest_id=Q3, quest_status=1, quest_step="report")
q3_done = cond(quest_id=Q3, quest_status=2)
shop_open = cond(min_inwijding=1)
strong = cond(min_inwijding=3)

line("first_meeting", "Hé. Jij bent nieuw hier. Dat zie ik aan je loopje.", "first_2", condition=q1_first_talk, model_action="flex")
line("first_2", "Ik ben Klaas. Ik beschermde Elst. Tot Amber de Draak kwam, met haar leger drillers uit Arnhem-Zuid.", "first_3")
line("first_3", "Nu zit ik ondergedoken in mijn eigen huis. Niet mijn sterkste moment. Maar jij kunt me helpen.", choices=[
    choice("Wat moet ik doen?", "tutorial_1"),
    choice("Waarom die zonnebril?", "first_glasses"),
])
line("first_glasses", "Deze bril gaat nooit af. Nooit. Volgende vraag.", choices=[choice("Wat moet ik doen?", "tutorial_1")])
line("tutorial_1", "Eerst wil ik zien wat je kunt. Hier, een zwaard. Roestig, maar het snijdt.", "tutorial_2",
     action="give_item", value="rusty_sword")
line("tutorial_2", "Ga naar buiten. Sprint, spring en ontwijk. Sla daarna mijn trainingspop kapot en leer blokkeren bij de sparringpop.", "tutorial_3")
line("tutorial_3", "Raak je de weg kwijt? Je questlog staat onder J, en het kompas bovenin wijst de weg. Vooruit.",
     action="set_flag", value="q1_met_klaas")
line("tutorial_report", "Twee drillers in één keer. Niet slecht, voor een niemand.", "tutorial_reward", condition=q1_report, model_action="flex")
line("tutorial_reward", "Je bent nu ingewijd. Mijn winkel staat voor je open. En hier, wat goud en twee drankjes. Niet alles in één keer opmaken.", "hub",
     action="set_flag", value="q1_reported")
line("tutorial_busy", "Ik zie nog geen resultaten. Kijk in je questlog als je niet weet wat je moet doen.", condition=q1_active)
line("q2_report", "Het is stil op het spoor. Geen trein meer voor Amber. Dat heb jij gedaan.", "q2_reward", condition=q2_report, model_action="flex")
line("q2_reward", "Zonder aanvoer zijn haar drillers in Westeraam en bij het OBC een stuk slapper. Hier, je beloning.", "hub",
     action="set_flag", value="q2_reported")
line("q3_report", "De Vape-koning is weg? Dan kan Westeraam eindelijk weer ademen.", "q3_reward", condition=q3_report, model_action="flex")
line("q3_reward", "De mensen lopen alweer over straat. Hier, 150 goud. Die heb je verdiend.", "hub",
     action="set_flag", value="q3_reported")
line("greeting_strong", "Kijk eens wie er spieren krijgt. Bijna zoveel als ik. Bijna.", "hub", condition=strong, model_action="flex")
line("greeting", "Daar is mijn favoriete niemand.", "hub")
line("hub", "Wat wil je?", choices=[
    choice("Laat je winkel zien.", condition=shop_open, action="open_shop"),
    choice("Heb je nog een klus?", "q2_offer", q2_offer),
    choice("Heb je nog een klus?", "q2_early", q2_early),
    choice("Heb je nog een klus?", "q2_busy", q2_active),
    choice("Heb je nog een klus?", "q3_offer", q3_offer),
    choice("Heb je nog een klus?", "q3_early", q3_early),
    choice("Heb je nog een klus?", "q3_busy", q3_active),
    choice("Heb je nog een klus?", "next_job", q3_done),
    choice("Vertel over Amber.", "lore_1"),
    choice("Waarom die zonnebril?", "glasses"),
    choice("Mag ik hier slapen?", "sleep_offer"),
    choice("Tot later.", "bye"),
])
line("q2_offer", "Station Elst is Ambers aanvoerlijn. Elke nacht rijden er treinen vol eiwitshakes en ander spul naar haar leger.", "q2_offer_2")
line("q2_offer_2", "Vier generators houden trein en spoor draaiende. Sla ze alle vier kapot. Pas op: achterin ligt haar depot, en dat bewaken ze goed.", choices=[
    choice("Ik sloop dat station.", "q2_go", action="start_quest", value=Q2),
    choice("Nog even niet.", "hub"),
])
line("q2_go", "Zo mag ik het horen. De ingang zit in het gebouw naast het station. Het kompas wijst je de weg.", "hub")
line("q2_busy", "Die generators draaien nog. Ik hoor het gezoem tot hier.", "hub")
line("q2_early", "Wacht even. Het station ligt al plat? Ik had het je nog niet eens gevraagd.", "q2_early_2", model_action="flex")
line("q2_early_2", "Eerder klaar dan gevraagd. Dat noem ik inzet. Hier, je beloning.", "hub", action="start_quest", value=Q2)
line("q3_offer", "Westeraam Getho is van de drillers. Hun baas noemt zichzelf de Vape-koning: de rijkste vapeverkoper van het dorp.", "q3_offer_2")
line("q3_offer_2", "Hij verstopt zich in zijn eigen vapewolken en schiet van daaruit. Loop recht op zijn wolk af, dan staat hij even te hoesten. Dat is je kans.", choices=[
    choice("Ik pak die Vape-koning.", "q3_go", action="start_quest", value=Q3),
    choice("Nog even niet.", "hub"),
])
line("q3_go", "Westeraam ligt aan de overkant van het spoor. De ingang zit in de flats. Neem drankjes mee.", "hub")
line("q3_busy", "De Vape-koning zit nog op zijn troon. Ik ruik het tot hier.", "hub")
line("q3_early", "Ik hoorde het al. De Vape-koning is verslagen, en ik had het je niet eens gevraagd.", "q3_early_2", model_action="flex")
line("q3_early_2", "Dat noem ik nou een echte Elstenaar in wording. Hier, je beloning.", "hub", action="start_quest", value=Q3)
line("next_job", "Nog niet. Rust uit. Ik roep je als Amber weer iets flikt.", "hub")
line("lore_1", "Amber kwam uit Arnhem-Zuid. Groot, oranje, slecht humeur. Ze nam Elst over en zette overal haar drillers neer.", "lore_2")
line("lore_2", "Sinds die dag draait er een tornado om het dorp. Niemand erin, niemand eruit. Station Elst is haar aanvoerlijn. Die moet kapot.", "hub")
line("glasses", "Deze bril gaat nooit af. Nooit. Volgende vraag.", "hub")
line("sleep_offer", "Het bed staat achterin. Schoenen uit. Slapen is ook trainen.", choices=[
    choice("Ik ga slapen.", action="sleep"),
    choice("Nog even niet.", "hub"),
])
line("bye", "Train hard. Of in elk geval een beetje.")

out = ['[gd_resource type="Resource" script_class="DialogueData" format=3]', '',
       '[ext_resource type="Script" path="res://scripts/data/dialogue_data.gd" id="1_data"]',
       '[ext_resource type="Script" path="res://scripts/data/dialogue_condition.gd" id="2_condition"]',
       '[ext_resource type="Script" path="res://scripts/data/dialogue_choice.gd" id="3_choice"]',
       '[ext_resource type="Script" path="res://scripts/data/dialogue_line.gd" id="4_line"]', '']
for block in subs:
    out += block + [""]
out += ['[resource]', 'script = ExtResource("1_data")', 'speaker = "Klaas"',
        'starts = Array[StringName]([&"first_meeting", &"tutorial_report", &"tutorial_busy", &"q2_report", &"q3_report", &"greeting_strong", &"greeting"])',
        'lines = Array[ExtResource("4_line")]([' + ", ".join(f'SubResource("{l}")' for l in line_ids) + "])"]
pathlib.Path("data/dialogue/klaas.tres").write_text("\n".join(out) + "\n")
