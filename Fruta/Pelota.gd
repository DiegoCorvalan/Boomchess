extends RigidBody2D

@export var size_level:int = 1
@export var base_radius:float = 6.0
@export var color:Color = Color(1, 1, 1)

const SCENE_PATH := "res://Fruta/Pelota.tscn"
const SIZE_GROWTH := 1.3

var _is_merging: bool = false

func _ready():
	contact_monitor = false
	max_contacts_reported = 8
	_update_shape_radius()
	queue_redraw()

func _update_shape_radius():
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	# Ensure the shape resource is unique per instance before mutating
	if shape_node.shape != null and not shape_node.shape.resource_local_to_scene:
		shape_node.shape = shape_node.shape.duplicate()
		shape_node.shape.resource_local_to_scene = true
	var circle: CircleShape2D = shape_node.shape as CircleShape2D
	if circle != null:
		circle.radius = base_radius * pow(SIZE_GROWTH, float(size_level - 1))
		queue_redraw()
	# Also keep Area2D shape in sync if present
	var area_shape := get_node_or_null("Area2D/CollisionShape2D") as CollisionShape2D
	if area_shape != null and area_shape.shape is CircleShape2D:
		if area_shape.shape != null and not area_shape.shape.resource_local_to_scene:
			area_shape.shape = area_shape.shape.duplicate()
			area_shape.shape.resource_local_to_scene = true
		var area_circle: CircleShape2D = area_shape.shape as CircleShape2D
		area_circle.radius = base_radius * pow(SIZE_GROWTH, float(size_level - 1))

func _draw():
	# Visual circle so the size change is visible
	var r := base_radius * pow(SIZE_GROWTH, float(size_level - 1))
	draw_circle(Vector2.ZERO, r, color)

func _deferred_merge_with_equal(other:RigidBody2D) -> void:
	var parent := get_parent()
	if parent == null:
		return

	# Spawn larger pelota
	var scene: PackedScene = load(SCENE_PATH)
	if scene == null:
		return
	var new_pelota: RigidBody2D = scene.instantiate() as RigidBody2D
	if "size_level" in new_pelota:
		new_pelota.size_level = size_level + 1
	# Position at midpoint
	new_pelota.position = (position + other.position) * 0.5
	# Inherit average velocity
	if "linear_velocity" in new_pelota:
		new_pelota.linear_velocity = (linear_velocity + other.linear_velocity) * 0.5
	
	parent.add_child(new_pelota)

	# Award points based on resulting ball size
	if (typeof(Global) != TYPE_NIL) and ("add_points_for_size" in Global):
		Global.add_points_for_size(new_pelota.size_level)

	# Remove the two originals
	other.queue_free()
	queue_free()


func _on_area_2d_area_entered(area):
	# Merge via Area2D with equal-sized Pelotas
	if area == null:
		return
	var other := area.get_parent() as RigidBody2D
	if other == null or other == self:
		return
	# Ensure it's the same scene/script
	var same_scene := false
	if "scene_file_path" in other:
		same_scene = other.scene_file_path == SCENE_PATH and scene_file_path == SCENE_PATH
	else:
		same_scene = other.get_script() == get_script()
	if not same_scene:
		return
	# Equal size check
	if not ("size_level" in other):
		return
	if other.size_level != size_level:
		return
	# Tie-break to avoid double merge
	if other.get_instance_id() > get_instance_id():
		return
	call_deferred("_deferred_merge_with_equal", other)
