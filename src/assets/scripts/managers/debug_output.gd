extends RichTextLabel

var time_since_last_clear : float = 0

func _ready():
	EventBus.debug_output.connect(debug_output)
	
#func _process(delta):
	#time_since_last_clear += delta
	#if time_since_last_clear >= 10:
		#time_since_last_clear = 0
		#text = ""
	
func debug_output(output : String):
	text += output
