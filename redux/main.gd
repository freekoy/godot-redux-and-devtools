#This is a GDScript script using Godot 3.x. 
#That means the old GDScript syntax is used. Here's a couple of important things to remember:
#- Use Spatial, not Node3D, and translation, not position
#- Use rad2deg, not rad_to_deg
#- Use instance, not instantiate
#- You can't use enumerate(OBJECT). Instead, use "for i in len(OBJECT):" 
#- Use true, not True, and false, not False
#
#Remember, this is not Python. It's GDScript for use in Godot.
#

extends Panel


var Store = load("res://redux/Store.gd")
const state = {
	"counter": 0,
	"todolist": [],
	"visibilityFilter": ""
}

const Action = {
	INCREMENT = "INCREMENT",
	DECREMENT = "DECREMENT",
	ADD_TODO = "ADD_TODO",
	TOGGLE_TODO = "TOGGLE_TODO",
	SET_VISIBILITY_FILTER = "SET_VISIBILITY_FILTER",
}

var reducerList = []

var store:Store

var diff_tree_list = []

# 记录数据变化，将数据变化发送给redux-devtools-extension的前台
var action_list = []
var state_list = []

func _ready():
	reducerList = ["todos_reducer", "counter_reducer"]

	store = Store.new(state, self, 'combinereducers')
	store.add_middleware(self, 'devtools_middleware')
	store.add_middleware(self, 'logger_action')
	store.subscribe(self, 'logger_state')
	store.subscribe(self, 'print_state_list_and_action_list')
	
	
	init_tab()


func test():

	dispatch(Action.INCREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	
	store.dispatch({
		type = Action.ADD_TODO,
		payload = {
			"text": "Learn Redux",
			"completed": false,
		}
	})

	store.dispatch({
		type = Action.ADD_TODO,
		payload = {
			"text": "Learn Godot",
			"completed": false,
		}
	})
	store.dispatch({
		type = Action.TOGGLE_TODO,
		payload = 0
	})
	
	tabs_content_render()


func INCREMENT(state, action):
	return wrapper({
		"counter": state.counter + action.payload,
	})

func counter_reducer(state, action):
	match action.type:
		Action.INCREMENT:
			return INCREMENT(state, action)

		Action.DECREMENT:
			return wrapper({
				"counter": state.counter - action.payload,
			})

func todos_reducer(state, action):
	match action.type:
		Action.ADD_TODO:
			state.todolist.push_back(action.payload)
			return wrapper({
				"todolist": state.todolist,
			})
		Action.TOGGLE_TODO:
			var index = action.payload
			var todo = state.todolist[index]
			var newTodo = merge(todo, {"completed": !todo.completed})
			var newTodoList = state.todolist
			newTodoList[index] = newTodo
			return wrapper({
				"todolist": newTodoList,
			})
		Action.SET_VISIBILITY_FILTER:
			if(action.payload == "SHOW_ALL"):
				return wrapper({
					"visibilityFilter": action.payload,
				})
			elif(action.payload == "SHOW_COMPLETED"):
				return wrapper({
					"visibilityFilter": action.payload,
				})
			elif(action.payload == "SHOW_ACTIVE"):
				return wrapper({
					"visibilityFilter": action.payload,
				})
			else:
				return wrapper({
					"visibilityFilter": action.payload,
				})


func logger_state(state):
	print("\n")
	print("state")
	print(to_json(state))
	pass # Replace with function body.
	
func logger_action(action):
	print("\n")
	print("action")
	print(to_json(action))
	return action

func createAction(type, payload):
	return {
		"type": type,
		"payload": payload,
	}


func wrapper(obj):
	var copyObj = obj
	return merge(store.state(), copyObj)

func merge(obj1,obj2):
	var obj3 = {}
	for key in obj1:
		obj3[key] = obj1[key]
	for key in obj2:
		obj3[key] = obj2[key]

	return obj3

func dispatch(type, payload):
	store.dispatch(createAction(type, payload))


func my_reducer(state, action):
	var tmp
	for i in range(0, len(reducerList)):
		var _func = funcref(self, reducerList[i])
		tmp = _func.call_func(state, action)
		if(tmp):
			return tmp
	if(tmp == null):
		printerr("Either the data is not being processed or there is a problem with the action tmp: ", tmp, " data: ", action)

func combinereducers(state, action):
	var res
	for i in range(0, len(reducerList)):
		var _func = funcref(self, reducerList[i])
		res = _func.call_func(state, action)
		if(res):
			return res
	if(res == null):
		printerr(reducerList)
		printerr("There is a problem with the reducer in combinereducers")
		printerr("")
		printerr("Either there is a problem with the action ", action, "  Either the data is not being processed", res)
		assert(false, "Please note")


func devtools_middleware(action):
	action_list.append(action.duplicate(true))
	state_list.append(store._state.duplicate(true))
	return action

# 通过重置，我们可以将state的数据重置为初始值
func reset():
	print("reset")	
	store._state = state_list[0]

# 通过跳转，我们可以将state的数据跳转到某个时间点的数据
func jump(data):
	print("jump")
	store._state = data

# 传入字典, 筛选出我们想要的动作
func filter_action(action_dict):
	print("filter_action")
	var _action_list = []
	for action in action_list:
		if(action.type == action_dict.type):
			_action_list.append(action)
	return _action_list
	
# 回放功能
func replay():
	reset()
	state_list.clear()
	state_list.append(store._state)
	for action in action_list:
		store.dispatch(action)

# 特定的动作
func run_action(action):
	store.dispatch(action)

# 回放特定的动作 通过索引
func replay_action_by_index(index):
	if index < 0 or index >= action_list.size():
		return
	store.dispatch(action_list[index])
	
# 通过导出，我们可以将state和action的数据导出到本地
func export_all():
	var file = File.new()
	file.open("user://export.txt", File.WRITE)
	file.store_line("action:")
	for action in action_list:
		file.store_line(to_json(action))
	file.store_line("state:")
	for state in state_list:
		file.store_line(to_json(state))
	file.close()
	$tips/Label.text = 'export complete'
	$tips.popup()


# 通过导入，我们可以将本地的数据导入到state
func import_all():
	var _action_list = []
	var _state_list = []
	var file = File.new()
	file.open("user://export.txt", File.READ) 
	var action = file.get_line()
	while action != "state:":
		if(action != "action:"):
			var _action = parse_json(action)
			if(typeof(_action) == TYPE_DICTIONARY):
				_action_list.append(_action)
		action = file.get_line()
	var state = file.get_line()
	while state != "":
		_state_list.append(parse_json(state))
		state = file.get_line()
	file.close()
	state_list = _state_list
	action_list = _action_list
	store._state = state_list.back()
	$tips/Label.text = 'import complete'
	$tips.popup()
	tabs_content_render()



# 打印state 和 action
func print_state_list_and_action_list(state):
	print("\n")
	print("state_list")
	print(state_list)
	print("action_list")
	print(action_list)


func test_reset():
	store._state = state_list[0]
	state_list = [store._state]
	action_list = []
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.DECREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	reset()
	assert(state_list[0] == store._state)
	print("The test reset succeeded")

func test_jump():
	store._state = state_list[0]
	state_list = [store._state]
	action_list = []
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.DECREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	jump(1)
	assert(state_list[1] == store._state)
	print("The test jump succeeded")

func test_filter():
	store._state = state_list[0]
	state_list = [store._state]
	action_list = []
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	dispatch(Action.DECREMENT, 1)
	dispatch(Action.INCREMENT, 1)
	var filter_list = filter_action({"type": Action.DECREMENT})
	print("The test filter succeeded")

func merge_two_list(a, b):
	print(a.size() == b.size())
	var c = []
	for i in range(a.size()):
		c.append(a[i])
		c.append(b[i])
	return c

func tabs_content_render():
	var all_tree:Tree = $HSplitContainer/left/TabContainer/all/Tree
	init_tree_render(all_tree, merge_two_list(state_list, action_list))

	var state_tree = $HSplitContainer/left/TabContainer/state/Tree
	init_tree_render(state_tree, state_list)

	action_tree_render(action_list)

func action_tree_render(data)	:
	var action_tree = $HSplitContainer/left/TabContainer/action/Tree
	init_tree_render(action_tree, data)

func init_tree_render(tree, data):
	tree.clear()
	var tree_root = tree.my_init()
	tree.renderTree(data, tree_root, "root")
	if(!tree.is_connected("button_pressed", self, 'tree_btn_event')):
		tree.connect("button_pressed", self, 'tree_btn_event')

func init_diff_tree_render(tree, data):
	tree.clear()
	var tree_root = tree.my_init()
	tree.renderTree(data, tree_root, "root")
	
func tree_btn_event(item, column, id):
	print('tree_btn_event ', item, ' ', column, ' ' , id)
	var data = item.get_metadata(0)
	print(data)
	
	var selected = -1
	var diff = 0
	var state = 1
	var action = 2
	
	if(id == 0):
		selected = diff
	elif(id == 1):
		if(data.has('type') and data.has('payload')):
			selected = action
		else:
			selected = state
	
	if(selected == diff):
		print('diff')
		var tree1 = $HSplitContainer/right/GridContainer/diff1
		var tree2 = $HSplitContainer/right/GridContainer/diff2
		
		if(diff_tree_list.size() >= 2):
			diff_tree_list = []
			diff_tree_list.append(data)
			tree1.clear()
			tree2.clear()
			init_diff_tree_render(tree1, data)
		elif(diff_tree_list.size() == 1):
			diff_tree_list.append(data)
			init_diff_tree_render(tree2, data)
		else:
			diff_tree_list.append(data)
			init_diff_tree_render(tree1, data)
	
	elif(selected == state):
		print('jump')
		jump(data)
		tabs_content_render()		
		
	elif(selected == action):
		print('action')
		run_action(data)
		tabs_content_render()
			
	pass

func _on_search_btn_pressed():
	var type_text = $HSplitContainer/left/search_input.text
	if(type_text == ""):
		var list = filter_action({
			type = type_text
		})
		action_tree_render(action_list)
	else:
		var list = filter_action({
			type = type_text
		})
		action_tree_render(list)
	pass # Replace with function body.


func btns_btn_hide():
	var btns = ['run_custom_action', 'export', 'import']
	for item in btns:
		get_node('HSplitContainer/right/btns/' + item).hide()
		
func all_btns_show():
	var btns = ['run_custom_action', 'export', 'import']
	for item in btns:
		get_node('HSplitContainer/right/btns/' + item).show()

func state_btns_show():
	var btns = ['run_custom_action', 'export', 'import']
	for item in btns:
		get_node('HSplitContainer/right/btns/' + item).show()
		
func action_btns_show():
	var btns = ['run_custom_action']
	for item in btns:
		get_node('HSplitContainer/right/btns/' + item).show()
		
func _on_TabContainer_tab_selected(tab):
	var all = 0
	var state = 1
	var action = 2
	btns_btn_hide()	
	match tab:
		all:
			all_btns_show()
		state:
			state_btns_show()
		action:
			action_btns_show()
		_:
			pass
	pass # Replace with function body.

func init_tab():
	var all = 0
	_on_TabContainer_tab_selected(all)
	tabs_content_render()


func _on_dispatch_action_pressed():
	print($custom_action_panel/TextEdit.text)
	var action = parse_json($custom_action_panel/TextEdit.text)
	dispatch(action.type, action.payload)
	tabs_content_render()
	$custom_action_panel.hide()
	pass # Replace with function body.




func _on_run_custom_action_pressed():
	$custom_action_panel.popup()
	pass # Replace with function body.
	
