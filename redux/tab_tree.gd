extends Tree

onready var add_icon = preload("res://redux/diff.png")
onready var jump_icon = preload("res://redux/jump.png")
onready var action_icon = preload("res://redux/action.png")

var noBtn = false

func _ready():
	print(self.name)
	if('diff' in self.name):
		noBtn = true
	pass

# render tree on node
func renderTree(data, node, des):
	var tree = self.create_item(node)
	if data is Array:
		tree.set_text(0, " " + des + "  :  Array")
		if(!noBtn):
			tree.add_button(0, add_icon, -1, false, "diff")
		tree.set_metadata(0, data)
		# 遍历data 并传入tree 和 item 和 index
		for index in range(data.size()):
			renderTree(data[index], tree, str(index))
	elif data is Dictionary:
		tree.set_text(0, " " + des + "  :  Dictionary")
		if(!noBtn):
			tree.add_button(0, add_icon, -1, false, "diff")
			if(data.has('type') and data.has('payload')):
				tree.add_button(0, action_icon, -1, false, "dispatch action")
			else:
				tree.add_button(0, jump_icon, -1, false, "jump")
		tree.set_metadata(0, data)
		for key in data:
			renderTree(data[key], tree, key)
	else:
		tree.set_text(0, des + " " + str(data))

# my init
# return node_root
func my_init():
	var node_root = create_item()
	set_hide_root(true)
	return node_root