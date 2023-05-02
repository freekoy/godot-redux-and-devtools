extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
#	test code
	test()
#	your code
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func test():
	$Panel.show()
	$Panel.test()

func _on_btn_pressed():
	$Panel.visible = !$Panel.visible
	pass # Replace with function body.
