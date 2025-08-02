extends VBoxContainer

var credits = "
quaternius.com/packs/ultimategun.html - Quaternius' Ultimate Guns Pack
f8studios.itch.io/snakes-authentic-gun-sounds - Snake's Authentic Gun Sounds
wilkingames.itch.io/premium-weapon-pack - Wilkin's Premium Weapon Pack
makotohiramatsu.itch.io/abandoned - MakotoHiramatsu's Post-Apocalyptic Music and Sound Scapes
poly.pizza/m/dwSTUGtcaN sketchfab.com/3d-models/low-poly-solider-character-78fd3dc82c66487baf883e0d8f54938b - Umair Yaqub's Soldier
davidkbd.itch.io/code-injection-dark-techno-music-pack - DavidKBD's Code Injection Pack
ggbot.itch.io/quinquefive-font - GGBot's Quinquefive Font
Tactical Music: Deceived - Avery_Alexander - Sourced from YoUtube
Retro w98 GUI - comp3interactive - Sourced from itch.io
Ventilation_Variant1 - MidFag - Sourced from opengameart.org
Western - shalpin - Sourced from opengameart.org
Stylized Sky with Procedural Sun and Moon - krzmig - Sourced from godotshaders.com
Godot Plush - FR3NKD - Sourced from Gumroad
"

func _ready() -> void:
	var content = "[ul]" + credits + "[/ul]"
	$CreditsContent/CreditsContent.text = content
