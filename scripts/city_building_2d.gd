extends Node2D

# 城市建筑已经直接绘制进地图背景。这个节点只保存房屋归属与碰撞尺寸，
# 不再绘制矩形边框、名称牌或入口标记，避免与背景中的透视建筑错位。
var port_id = ""
var building_id = ""
var display_name = ""
var model_role = "hall"
var footprint = Rect2()
var npc_ids = []
var collision_size = Vector2.ZERO
var integrated_background = true
var visual_frame_enabled = false

func configure(city_port_id, building_data, world_scale = 1.0):
	port_id = str(city_port_id)
	building_id = str(building_data.get("id", "building"))
	display_name = str(building_data.get("name", "建筑"))
	footprint = Rect2(building_data.get("footprint", Rect2(0, 0, 160, 130)))
	npc_ids = Array(building_data.get("npc_ids", [])).duplicate()
	model_role = str(building_data.get("model", "hall"))
	collision_size = footprint.size * float(world_scale)
	visible = false
