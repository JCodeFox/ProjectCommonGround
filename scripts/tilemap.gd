extends TileMap

@export var stand: PackedScene

var selected_structure: int = 4

func _ready() -> void:
	update_cursors()

func _input(event: InputEvent) -> void:
	if not $Cursors.visible:
		return
	if not event is InputEventMouseButton or not event.pressed:
		return
	if Input.is_key_pressed(KEY_SHIFT):
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		selected_structure += 1
		update_cursors()
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		selected_structure -= 1
		update_cursors()

func update_cursors():
	if selected_structure < 0:
		selected_structure = 5
	selected_structure = selected_structure % 6
	
	$Cursors/CursorBuilding.visible = selected_structure < 4
	$Cursors/CursorBuilding.frame = selected_structure % 4
	
	$Cursors/CursorRoof.visible = not $Cursors/CursorBuilding.visible
	$Cursors/CursorRoof.frame_coords = [Vector2i(1, 7), Vector2i(16, 3)][(selected_structure - 4) % 2]
	$Cursors/CursorRoof/CursorRoof2.visible = selected_structure == 4

func _process(delta: float) -> void:
	var mouse_pos: Vector2i = get_global_mouse_position() / 16
	if get_global_mouse_position().x < 0:
		mouse_pos.x -= 1
	if get_global_mouse_position().y < 0:
		mouse_pos.y -= 1
	$Cursors/CursorRoof.position = $Cursors/CursorRoof.position.lerp(mouse_pos * 16, delta * 30)
	$Cursors/CursorBuilding.position = $Cursors/CursorRoof.position + Vector2(8, 24)
	
	$Cursors.visible = GlobalData.riding_vehicle != null
	if not $Cursors.visible:
		return
	
	if $Cursors/CursorBuilding.visible:
		if Input.is_action_just_pressed("place") and GlobalData.money >= 100:
			var new_stand: Node2D = stand.instantiate()
			new_stand.position = mouse_pos * 16 + Vector2i(8, 8)
			new_stand.add_to_group(["battery", "windup", "water", "food"][$Cursors/CursorBuilding.frame])
			new_stand.get_node("Icon").frame = $Cursors/CursorBuilding.frame
			new_stand.connect("input_event", stand_input_event.bind(new_stand))
			get_parent().add_child(new_stand)
			GlobalData.change_money_with_pos(-1, mouse_pos * 16)
	else:
		if Input.is_action_pressed("place") and GlobalData.money >= 5 and get_cell_atlas_coords(2, mouse_pos) != [Vector2i(1, 5), Vector2i(16, 3)][(selected_structure - 4) % 2]:
			dig(mouse_pos)
			set_cell(2, mouse_pos, 0, [Vector2i(1, 5), Vector2i(16, 3)][(selected_structure - 4) % 2])
			GlobalData.change_money_with_pos(-1, mouse_pos * 16)
		if Input.is_action_pressed("dig"):
			dig(mouse_pos)

func dig(location: Vector2i):
	if get_cell_atlas_coords(2, location) != Vector2i(-1, -1):
		erase_cell(2, location)
		GlobalData.change_money_with_pos(1, location * 16)

func stand_input_event(viewport: Node, event: InputEvent, shape_idx: int, stand: Node2D):
	if not $Cursors.visible:
		return
	if not event is InputEventMouseButton or not $Cursors/CursorBuilding.visible:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		stand.queue_free()
		GlobalData.change_money_with_pos(1, stand.position)
