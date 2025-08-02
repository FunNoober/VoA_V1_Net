extends OmniLight3D

var player_settings = ConfigFile.new()

func _ready() -> void:
	EventBus.toggle_shadows.connect(toggle_shadows)

func toggle_shadows(toggled_on : bool):
	shadow_enabled = toggled_on
