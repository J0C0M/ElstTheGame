"""Writes data/dialogue/klaas.tres: Klaas' conversation, with Quest 1 to 5.

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
Q4 = "q4_obc"
q4_offer = cond(min_inwijding=3, quest_id=Q4, quest_status=0, forbidden_flag="boss_fatbike_kindje")
q4_early = cond(min_inwijding=3, quest_id=Q4, quest_status=0, required_flag="boss_fatbike_kindje")
q4_active = cond(quest_id=Q4, quest_status=1)
q4_report = cond(quest_id=Q4, quest_status=1, quest_step="report")
q4_done = cond(quest_id=Q4, quest_status=2)
Q5 = "q5_bingo"
q5_offer = cond(min_inwijding=4, quest_id=Q5, quest_status=0, forbidden_flag="boss_grumpy_oma")
q5_early = cond(min_inwijding=4, quest_id=Q5, quest_status=0, required_flag="boss_grumpy_oma")
q5_active = cond(quest_id=Q5, quest_status=1)
q5_report = cond(quest_id=Q5, quest_status=1, quest_step="report")
q5_done = cond(quest_id=Q5, quest_status=2)
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
line("q4_report", "Het fatbike-kindje van zijn fiets geduwd? Dat had ik graag gezien.", "q4_reward", condition=q4_report, model_action="flex")
line("q4_reward", "Het OBC is weer van de leerlingen. Hier, 150 goud.", "hub", action="set_flag", value="q4_reported")
line("q5_report", "Grumpy Oma verslagen? Dan wordt het vanavond eindelijk weer een gezellige bingoavond.", "q5_reward", condition=q5_report, model_action="flex")
line("q5_reward", "Hier, 150 goud. En er is meer.", "q5_crossbow", action="set_flag", value="q5_reported")
line("q5_crossbow", "Je hebt al mijn klussen gedaan. Daarom krijg je mijn oude kruisboog. Druk op 2 om hem te pakken en houd de rechtermuisknop vast om te richten.", "hub",
     action="give_item", value="crossbow")
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
    choice("Heb je nog een klus?", "q4_offer", q4_offer),
    choice("Heb je nog een klus?", "q4_early", q4_early),
    choice("Heb je nog een klus?", "q4_busy", q4_active),
    choice("Heb je nog een klus?", "q5_offer", q5_offer),
    choice("Heb je nog een klus?", "q5_early", q5_early),
    choice("Heb je nog een klus?", "q5_busy", q5_active),
    choice("Heb je nog een klus?", "next_job", q5_done),
    choice("Vertel over Amber.", "lore_1"),
    choice("Waarom die zonnebril?", "glasses"),
    choice("Mag ik hier slapen?", "sleep_offer"),
    choice("Tot later.", "bye"),
])
line("q2_offer", "Station Elst is Ambers aanvoerlijn. Elke nacht rijden er treinen vol eiwitshakes en ander spul naar haar leger.", "q2_offer_2")
line("q2_offer_2", "Vier generators houden trein en spoor draaiende. Sla ze alle vier kapot. Pas op: achterin ligt haar depot, en dat bewaken ze goed.", "q2_offer_3")
line("q2_offer_3", "En zolang dat station draait, houdt Amber Westeraam, het OBC en de Bingo Club op slot. Eerst het station, dan pas de rest.", choices=[
    choice("Ik sloop dat station.", "q2_go", action="start_quest", value=Q2),
    choice("Nog even niet.", "hub"),
])
line("q2_go", "Zo mag ik het horen. De ingang zit in het gebouw naast het station. Het kompas wijst je de weg.", "hub")
line("q2_busy", "Die generators draaien nog. Ik hoor het gezoem tot hier.", "hub")
line("q2_early", "Wacht even. Het station ligt al plat? Ik had het je nog niet eens gevraagd.", "q2_early_2", model_action="flex")
line("q2_early_2", "Eerder klaar dan gevraagd. Dat noem ik inzet. Hier, je beloning.", "hub", action="start_quest", value=Q2)
line("q3_offer", "Nu het station plat ligt, zijn de deuren van de wijken open. Westeraam Getho is van de drillers. Hun baas noemt zichzelf de Vape-koning: de rijkste vapeverkoper van het dorp.", "q3_offer_2")
line("q3_offer_2", "Hij verstopt zich in zijn eigen vapewolken en schiet van daaruit. Loop recht op zijn wolk af, dan staat hij even te hoesten. Dat is je kans.", choices=[
    choice("Ik pak die Vape-koning.", "q3_go", action="start_quest", value=Q3),
    choice("Nog even niet.", "hub"),
])
line("q3_go", "Westeraam ligt aan de overkant van het spoor. De ingang zit in de flats. Neem drankjes mee.", "hub")
line("q3_busy", "De Vape-koning zit nog op zijn troon. Ik ruik het tot hier.", "hub")
line("q3_early", "Ik hoorde het al. De Vape-koning is verslagen, en ik had het je niet eens gevraagd.", "q3_early_2", model_action="flex")
line("q3_early_2", "Dat noem ik nou een echte Elstenaar in wording. Hier, je beloning.", "hub", action="start_quest", value=Q3)
line("q4_offer", "Bij het OBC hebben een stel kakkers de school ingenomen. Ze schieten met voetballen en rijden op fatbikes alsof het paarden zijn.", "q4_offer_2")
line("q4_offer_2", "Hun baas is een klein kindje op een veel te grote, opgevoerde fatbike. Hoor je de motor gieren, spring dan opzij. Knalt hij tegen een muur, dan is hij even versuft.", choices=[
    choice("Ik pak dat fatbike-kindje.", "q4_go", action="start_quest", value=Q4),
    choice("Nog even niet.", "hub"),
])
line("q4_go", "Het OBC ligt helemaal in het zuidwesten. Pas op voor de ballen.", "hub")
line("q4_busy", "Ik hoor die opgevoerde fatbike nog steeds gieren. Je bent nog niet klaar.", "hub")
line("q4_early", "Dat gegier is gestopt. Heb jij het fatbike-kindje al van zijn fiets geduwd?", "q4_early_2", model_action="flex")
line("q4_early_2", "Eerder klaar dan gevraagd. Ik ben trots op je. Hier, je beloning.", "hub", action="start_quest", value=Q4)
line("q5_offer", "De Bingo Club is een grot geworden. Opa's slaan met hun wandelstok, oma's springen je met hun tasje te lijf en de rolstoel-oma's schieten bingokaarten.", "q5_offer_2")
line("q5_offer_2", "Hun leider is Grumpy Oma: de nummer 1 van de bingo en een trouwe volger van Amber. Voor die oudjes is ze een messias. Ontwijk haar klap, spring over haar schokgolf en sla hard als ze uitgeput is.", choices=[
    choice("Ik pak Grumpy Oma.", "q5_go", action="start_quest", value=Q5),
    choice("Nog even niet.", "hub"),
])
line("q5_go", "De Bingo Club ligt vlak bij de kerk. Neem veel drankjes mee, en vergeet je bingokaart niet.", "hub")
line("q5_busy", "Ik hoor ze nog steeds BINGO roepen. Grumpy Oma zit nog in haar grot.", "hub")
line("q5_early", "Het is stil in de Bingo Club. Heb jij Grumpy Oma al verslagen?", "q5_early_2", model_action="flex")
line("q5_early_2", "Eerder klaar dan gevraagd. Ik ben trots op je. Hier, je beloning.", "q5_crossbow", action="start_quest", value=Q5)
line("next_job", "Nog niet. Rust uit. Ik roep je als Amber weer iets flikt.", "hub")
line("lore_1", "Amber kwam uit Arnhem-Zuid. Groot, oranje, slecht humeur. Ze nam Elst over en zette overal haar drillers neer.", "lore_2")
line("lore_2", "Sinds die dag draait er een tornado om het dorp. Niemand erin, niemand eruit. Station Elst is haar aanvoerlijn. Die moet kapot.", "hub")
line("glasses", "Deze bril gaat nooit af. Nooit. Volgende vraag.", "hub")
line("sleep_offer", "Het bed staat achterin. Schoenen uit. Slapen is ook trainen.", choices=[
    choice("Ik ga slapen.", action="sleep"),
    choice("Nog even niet.", "hub"),
])
line("bye", "Train hard. Of in elk geval een beetje.")

def write(path, starts):
    """Writes the lines made so far as one DialogueData, then starts afresh."""
    out = ['[gd_resource type="Resource" script_class="DialogueData" format=3]', '',
           '[ext_resource type="Script" path="res://scripts/data/dialogue_data.gd" id="1_data"]',
           '[ext_resource type="Script" path="res://scripts/data/dialogue_condition.gd" id="2_condition"]',
           '[ext_resource type="Script" path="res://scripts/data/dialogue_choice.gd" id="3_choice"]',
           '[ext_resource type="Script" path="res://scripts/data/dialogue_line.gd" id="4_line"]', '']
    for block in subs:
        out += block + [""]
    out += ['[resource]', 'script = ExtResource("1_data")', 'speaker = "Klaas"',
            "starts = Array[StringName]([" + ", ".join(f'&"{s}"' for s in starts) + "])",
            'lines = Array[ExtResource("4_line")]([' + ", ".join(f'SubResource("{l}")' for l in line_ids) + "])"]
    pathlib.Path(path).write_text("\n".join(out) + "\n")
    subs.clear()
    line_ids.clear()
    conditions.clear()


write("data/dialogue/klaas.tres", ["first_meeting", "tutorial_report", "tutorial_busy", "q2_report", "q3_report", "q4_report", "q5_report",
                                   "greeting_strong", "greeting"])

# Klaas in the church, at the gate of Amber's arena (Quest 6).
not_ready = cond(forbidden_flag="klaas_ready")
ready = cond(required_flag="klaas_ready")
line("church_hello", "Daar ben je. Amber zit achter die poort. Groot, heet en chagrijnig. Net als mijn ex.", condition=not_ready,
     model_action="flex", choices=[
         choice("Wat moet ik weten?", "church_tips"),
         choice("Ik wil nog wat kopen of verkopen.", action="open_shop"),
         choice("Ik ben er klaar voor.", "church_go"),
         choice("Nog even niet.", "church_wait"),
     ])
line("church_tips", "Achter een pilaar raakt haar vuur je niet. Vliegt ze, pak je kruisboog. Ligt ze op de grond of hijgt ze, sla dan op haar kop.",
     "church_tips_2")
line("church_tips_2", "En ik trek haar aandacht. Ik ben groter dan jij. Ze kijkt vanzelf naar mij.", choices=[
    choice("Ik wil nog wat kopen of verkopen.", action="open_shop"),
    choice("Ik ben er klaar voor.", "church_go"),
    choice("Nog even niet.", "church_wait"),
])
line("church_go", "Dan gaan we. Blijf naast me en sla. Voor Elst.", action="set_flag", value="klaas_ready", model_action="flex")
line("church_wait", "Rust uit op die bank. Ik ga nergens heen. Amber ook niet.")
line("church_ready", "De poort is open. Zeg het maar als je zover bent.", condition=ready, choices=[
    choice("Ik wil nog wat kopen of verkopen.", action="open_shop"),
    choice("Kom op, Klaas.", "church_go"),
])
write("data/dialogue/klaas_church.tres", ["church_hello", "church_ready"])
