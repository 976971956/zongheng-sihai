class_name GameState
extends RefCounted

const SAVE_VERSION = 2
const SAVE_PATH = "user://tides_save.json"
const ENEMY_RESPAWN_SECONDS = 20.0
const LEGACY_VOYAGE_ORIGIN_Y = 1580.0
const LEGACY_VOYAGE_DESTINATION_Y = 365.0
const DIFFICULTY_NORMAL = "normal"
const DIFFICULTY_ADVENTURE = "adventure"
const DIFFICULTY_NAMES = {DIFFICULTY_NORMAL: "普通", DIFFICULTY_ADVENTURE: "冒险"}

var rng = RandomNumberGenerator.new()
var player = {}
var inventory = {}
var equipment = {}
var quest_index = 0
var quest_progress = 0
var defeated = {}
var message_history = []
var active_battle = {}
var statuses = {}
var party_members = []
var companion_unlocked = false
var pet = {}
var dungeon_cleared = {}
var cargo = {}
var cargo_costs = {}
var ship = {}
var trade_day = 1
var trade_profit = 0
var trade_volume = 0
var trade_lifetime_profit = 0
var market_activity = {}
var port_reputation = {}
var trade_order_cycles = {}
var completed_trade_orders = {}
var voyage_protection = 0
var active_voyage = {}
var battle_stance = "balanced"
var auto_heal_threshold = 35
var auto_cure_status = true
var equipment_upgrades = {}
var trade_contract_claimed = false
var trade_contract_count = 0
var active_card = ""
var discoveries = {}
var bounty_index = 0
var bounty_progress = 0
var bounty_cycles = 0
var enemy_respawns = {}
var meal_buff_battles = 0
var difficulty = DIFFICULTY_NORMAL

func _init():
	rng.randomize()
	new_game()

func new_game():
	difficulty = DIFFICULTY_NORMAL
	player = {
		"name": "失忆的航者", "title": "海边苏醒者", "level": 1, "xp": 0, "hp": 94,
		"silver": 72, "location": "alisa_hut", "battles": 0, "victories": 0
	}
	inventory = {"small_milk": 3, "sea_salt_bread": 2, "universal_medicine": 1}
	equipment = {"weapon": "rusty_sabre", "head": "", "body": "", "waist": "", "boots": "", "charm": ""}
	quest_index = 0
	quest_progress = 0
	defeated = {}
	active_battle = {}
	statuses = {}
	party_members = []
	companion_unlocked = false
	pet = {}
	dungeon_cleared = {}
	cargo = {}
	cargo_costs = {}
	ship = {"name": "海燕号", "hull_id": "sea_swallow", "owned_hulls": ["sea_swallow"], "capacity": 12, "speed": 1, "hold_level": 0, "armor": 0, "cannon_level": 0}
	trade_day = 1
	trade_profit = 0
	trade_volume = 0
	trade_lifetime_profit = 0
	market_activity = {}
	port_reputation = {}
	trade_order_cycles = {}
	for port_id in GameData.TRADE_PORTS:
		port_reputation[str(port_id)] = 0
		trade_order_cycles[str(port_id)] = 0
	completed_trade_orders = {}
	voyage_protection = 0
	active_voyage = {}
	battle_stance = "balanced"
	auto_heal_threshold = 35
	auto_cure_status = true
	equipment_upgrades = {}
	trade_contract_claimed = false
	trade_contract_count = 0
	active_card = ""
	discoveries = {}
	bounty_index = 0
	bounty_progress = 0
	bounty_cycles = 0
	enemy_respawns = {}
	meal_buff_battles = 0
	message_history = ["你从海边小屋醒来，已经不记得自己的名字。"]
	player.hp = get_stats().max_hp

func difficulty_name():
	return str(DIFFICULTY_NAMES.get(difficulty, DIFFICULTY_NAMES[DIFFICULTY_NORMAL]))

func set_difficulty(value):
	var resolved = str(value)
	if not resolved in DIFFICULTY_NAMES:
		return {"ok": false, "message": "未知的游戏难度。"}
	if not active_battle.is_empty():
		return {"ok": false, "message": "战斗进行中不能切换难度。"}
	difficulty = resolved
	save_game()
	return {"ok": true, "message": "游戏难度已切换为%s。" % difficulty_name(), "difficulty": difficulty}

func reset_progress():
	var preserved_difficulty = difficulty if difficulty in DIFFICULTY_NAMES else DIFFICULTY_NORMAL
	new_game()
	difficulty = preserved_difficulty
	save_game()
	return {"ok": true, "message": "游戏进度已重置，难度保留为%s。" % difficulty_name()}

func difficulty_enemy_hp(base_hp):
	return int(ceil(float(base_hp) * (1.25 if difficulty == DIFFICULTY_ADVENTURE else 1.0)))

func difficulty_enemy_attack(base_attack):
	return int(ceil(float(base_attack) * (1.12 if difficulty == DIFFICULTY_ADVENTURE else 1.0)))

func difficulty_battle_reward(base_reward):
	return int(round(float(base_reward) * (1.20 if difficulty == DIFFICULTY_ADVENTURE else 1.0)))

func get_stats():
	var level = int(player.level)
	var stats = {
		"max_hp": 94 + (level - 1) * 18,
		"attack": 10 + (level - 1) * 3,
		"defense": 4 + (level - 1) * 2,
		"speed": 6 + (level - 1),
		"drop_bonus": 0.0
	}
	for slot in equipment:
		var item_id = equipment[slot]
		if item_id == "" or not GameData.ITEMS.has(item_id):
			continue
		var item = GameData.ITEMS[item_id]
		stats.drop_bonus += float(item.get("drop_bonus", 0.0))
		for key in item.get("stats", {}):
			stats[key] = stats.get(key, 0) + int(item.stats[key])
		var upgrade_level = int(equipment_upgrades.get(item_id, 0))
		if upgrade_level > 0:
			for key in item.get("stats", {}):
				var base_value = int(item.stats[key])
				var bonus_rate = 0.10 if key == "max_hp" else 0.14
				stats[key] = stats.get(key, 0) + max(1, int(round(float(base_value) * bonus_rate))) * upgrade_level

	var set_bonus_stats = equipment_set_bonus_stats()
	stats.drop_bonus += float(set_bonus_stats.get("drop_bonus", 0.0))
	for key in ["max_hp", "attack", "defense", "speed"]:
		stats[key] += int(set_bonus_stats.get(key, 0))

	# One monster card can be active at a time, creating a readable build choice.
	match active_card:
		"ghost_card": stats.defense += 3
		"bear_card": stats.max_hp = int(round(float(stats.max_hp) * 1.08))
		"tide_card": stats.speed += 4
		"corsair_card": stats.attack += 4
	if meal_buff_battles > 0:
		stats.max_hp += 45
		stats.attack += 6
		stats.defense += 3

	# One online teammate grants 5% attack/defense in the original rules.
	var team_bonus = min(0.20, float(party_members.size()) * 0.05)
	stats.attack = int(round(float(stats.attack) * (1.0 + team_bonus)))
	stats.defense = int(round(float(stats.defense) * (1.0 + team_bonus)))
	return stats

func get_power():
	var stats = get_stats()
	var pet_power = 16 if not pet.is_empty() else 0
	return int(stats.attack * 2.2 + stats.defense * 1.8 + stats.max_hp * 0.35 + stats.speed + pet_power)

func move_to(location_id):
	if not active_battle.is_empty():
		return {"ok": false, "message": "战斗中不能移动，请先撤退。"}
	if not GameData.LOCATIONS.has(location_id):
		return {"ok": false, "message": "目的地不存在。"}
	var current = GameData.LOCATIONS[player.location]
	var allowed = false
	var required_level = 1
	var selected_edge = {}
	for edge in current.exits:
		if edge.to == location_id:
			allowed = true
			required_level = int(edge.get("level", 1))
			selected_edge = edge
			break
	if not allowed:
		return {"ok": false, "message": "无法从这里直接前往该地点。"}
	if int(player.level) < required_level:
		return {"ok": false, "message": "需要达到 Lv.%d 才能进入。" % required_level}
	var exit_lock = get_exit_lock(selected_edge)
	if exit_lock != "":
		return {"ok": false, "message": exit_lock}
	var was_in_dungeon = _is_dungeon_location(player.location)
	var enters_dungeon = not was_in_dungeon and _is_dungeon_location(location_id)
	if enters_dungeon:
		dungeon_cleared = {}
	player.location = location_id
	if was_in_dungeon and not _is_dungeon_location(location_id):
		dungeon_cleared = {}
	var quest_completed = _advance_quest("visit", location_id)
	message_history.push_front("抵达了%s。" % GameData.LOCATIONS[location_id].name)
	_trim_history()
	save_game()
	return {"ok": true, "message": "已抵达%s" % GameData.LOCATIONS[location_id].name, "quest_completed": quest_completed}

func arrive_from_2d(location_id):
	if not active_battle.is_empty():
		return {"ok": false, "message": "战斗中不能移动。", "quest_completed": false}
	if not GameData.LOCATIONS.has(location_id):
		return {"ok": false, "message": "地点不存在。", "quest_completed": false}
	if player.location == location_id:
		return {"ok": true, "message": "", "quest_completed": false}
	player.location = location_id
	var quest_completed = _advance_quest("visit", location_id)
	message_history.push_front("步行抵达%s。" % GameData.LOCATIONS[location_id].name)
	_trim_history()
	save_game()
	return {"ok": true, "message": "进入%s" % GameData.LOCATIONS[location_id].name, "quest_completed": quest_completed}

func get_exit_lock(edge):
	var required_enemy = str(edge.get("requires_defeat", ""))
	if required_enemy == "" or bool(dungeon_cleared.get(required_enemy, false)):
		return ""
	return "通往下一层的道路尚未开放，请先击败%s。" % GameData.ENEMIES[required_enemy].name

func _is_dungeon_location(location_id):
	return str(location_id).begins_with("training_dungeon_") or str(location_id).begins_with("black_sail_") or str(location_id).begins_with("white_whale_") or str(location_id).begins_with("legacy_")

func talk_to(npc_id):
	var location = GameData.LOCATIONS[player.location]
	if not npc_id in location.npcs or not GameData.NPCS.has(npc_id):
		return {"ok": false, "message": "对方不在这里。"}
	var npc = GameData.NPCS[npc_id]
	var current_quest = get_current_quest()
	var quest_id = str(current_quest.get("id", ""))
	var quest_completed = _advance_quest("talk", npc_id)
	message_history.push_front("与%s交谈。" % npc.name)
	_trim_history()
	save_game()
	return {"ok": true, "message": GameData.quest_dialogue(quest_id, npc_id), "npc_name": npc.name, "quest_completed": quest_completed}

func rest():
	if not active_battle.is_empty():
		return {"ok": false, "message": "战斗中不能休息。"}
	var stats = get_stats()
	if int(player.hp) >= int(stats.max_hp) and statuses.is_empty():
		return {"ok": false, "message": "你的状态很好，不需要休息。"}
	player.hp = stats.max_hp
	statuses = {}
	message_history.push_front("你在酒馆休息，体力与状态已完全恢复。")
	_trim_history()
	save_game()
	return {"ok": true, "message": "休息完毕，体力与状态已经恢复。"}

func use_item(item_id):
	if int(inventory.get(item_id, 0)) <= 0:
		return {"ok": false, "message": "背包中没有这个物品。"}
	var item = GameData.ITEMS.get(item_id, {})
	if item.get("type", "") != "consumable":
		return {"ok": false, "message": "这个物品不能直接使用。"}
	var stats = get_stats()
	var before = int(player.hp)
	var healed = 0
	var cured = false
	var meal_activated = false
	if int(item.get("heal", 0)) > 0 and before < int(stats.max_hp):
		player.hp = min(int(stats.max_hp), before + int(item.heal))
		healed = int(player.hp) - before
	if bool(item.get("cure_status", false)) and not statuses.is_empty():
		statuses = {}
		cured = true
	if int(item.get("meal_battles", 0)) > 0 and meal_buff_battles <= 0:
		meal_buff_battles = int(item.meal_battles)
		meal_activated = true
	if healed == 0 and not cured and not meal_activated:
		return {"ok": false, "message": "现在不需要使用%s。" % item.name}
	_remove_item(item_id, 1)
	var details = []
	if healed > 0:
		details.append("恢复%d点体力" % healed)
	if cured:
		details.append("解除所有不良状态")
	if meal_activated:
		details.append("接下来%d场战斗获得餐食加成" % meal_buff_battles)
	message_history.push_front("使用%s，%s。" % [item.name, "，".join(details)])
	_trim_history()
	save_game()
	return {"ok": true, "message": "%s：%s" % [item.name, "，".join(details)]}

func buy_item(item_id):
	if not GameData.ITEMS.has(item_id):
		return {"ok": false, "message": "商品不存在。"}
	var item = GameData.ITEMS[item_id]
	var price = int(item.get("price", 0))
	if int(player.silver) < price:
		return {"ok": false, "message": "银币不足，还差 %d。" % (price - int(player.silver))}
	player.silver -= price
	_add_item(item_id, 1)
	message_history.push_front("在海风市场购买了%s。" % item.name)
	_trim_history()
	save_game()
	return {"ok": true, "message": "购买成功：%s" % item.name}

func buy_vendor_item(npc_id, item_id):
	var vendor_id = str(npc_id)
	var resolved_item_id = str(item_id)
	if not GameData.VENDOR_SHOPS.has(vendor_id) or not GameData.vendor_sells_item(vendor_id, resolved_item_id):
		return {"ok": false, "message": "这位商人不出售该物品。"}
	var current_location = GameData.LOCATIONS.get(str(player.location), {})
	if current_location.is_empty() or vendor_id not in current_location.get("npcs", []):
		return {"ok": false, "message": "需要到商人面前才能购买。"}
	if not GameData.ITEMS.has(resolved_item_id):
		return {"ok": false, "message": "商品不存在。"}
	var item = GameData.ITEMS[resolved_item_id]
	var price = int(item.get("price", 0))
	if int(player.silver) < price:
		return {"ok": false, "message": "银币不足，还差 %d。" % (price - int(player.silver))}
	player.silver -= price
	_add_item(resolved_item_id, 1)
	var shop_name = str(GameData.VENDOR_SHOPS[vendor_id].name)
	message_history.push_front("在%s购买了%s。" % [shop_name, item.name])
	_trim_history()
	save_game()
	return {"ok": true, "message": "购买成功：%s（-%d银币）" % [item.name, price], "item_id": resolved_item_id, "price": price}

func identify_unknown():
	if int(inventory.get("unknown_equipment", 0)) <= 0:
		return {"ok": false, "message": "没有需要鉴定的未知道具。"}
	if int(player.silver) < 5:
		return {"ok": false, "message": "鉴定需要 5 银币。"}
	player.silver -= 5
	_remove_item("unknown_equipment", 1)
	var item_id = GameData.IDENTIFY_POOL[rng.randi_range(0, GameData.IDENTIFY_POOL.size() - 1)]
	_add_item(item_id, 1)
	message_history.push_front("鉴定出%s。" % GameData.ITEMS[item_id].name)
	_trim_history()
	save_game()
	return {"ok": true, "message": "鉴定成功：%s" % GameData.ITEMS[item_id].name, "item_id": item_id}

func equip_item(item_id):
	if int(inventory.get(item_id, 0)) <= 0:
		return {"ok": false, "message": "背包中没有这件装备。"}
	var item = GameData.ITEMS.get(item_id, {})
	if item.get("type", "") != "equipment":
		return {"ok": false, "message": "这不是装备。"}
	var slot = item.slot
	var old_item = equipment.get(slot, "")
	_remove_item(item_id, 1)
	if old_item != "":
		_add_item(old_item, 1)
	equipment[slot] = item_id
	player.hp = min(int(player.hp), int(get_stats().max_hp))
	message_history.push_front("装备了%s。" % item.name)
	_trim_history()
	save_game()
	return {"ok": true, "message": "已装备 %s" % item.name}

func equipment_item_score(item_id):
	if not GameData.ITEMS.has(item_id):
		return 0
	var item = GameData.ITEMS[item_id]
	if str(item.get("type", "")) != "equipment":
		return 0
	var item_stats = item.get("stats", {})
	var level = equipment_upgrade_level(item_id)
	var score = 0.0
	for key in item_stats:
		var value = int(item_stats[key])
		if level > 0:
			var bonus_rate = 0.10 if key == "max_hp" else 0.14
			value += max(1, int(round(float(value) * bonus_rate))) * level
		match str(key):
			"max_hp": score += float(value) * 0.35
			"attack": score += float(value) * 2.2
			"defense": score += float(value) * 1.8
			"speed": score += float(value) * 1.2
	score += float(item.get("drop_bonus", 0.0)) * 100.0
	return int(round(score))

func equipment_set_counts(loadout = null):
	var resolved_loadout = equipment if typeof(loadout) != TYPE_DICTIONARY else Dictionary(loadout)
	var counts = {}
	for set_id in GameData.EQUIPMENT_SETS:
		counts[str(set_id)] = 0
	for slot in resolved_loadout:
		var item_id = str(resolved_loadout[slot])
		if item_id == "" or not GameData.ITEMS.has(item_id):
			continue
		var set_id = str(GameData.ITEMS[item_id].get("set", ""))
		if set_id != "" and GameData.EQUIPMENT_SETS.has(set_id):
			counts[set_id] = int(counts.get(set_id, 0)) + 1
	return counts

func equipment_set_bonus_stats(loadout = null):
	var bonus_stats = {"max_hp": 0, "attack": 0, "defense": 0, "speed": 0, "drop_bonus": 0.0}
	var counts = equipment_set_counts(loadout)
	for set_id in GameData.EQUIPMENT_SETS:
		var piece_count = int(counts.get(str(set_id), 0))
		for stage in Array(GameData.EQUIPMENT_SETS[set_id].bonuses):
			if piece_count < int(stage.pieces):
				continue
			bonus_stats.drop_bonus += float(stage.get("drop_bonus", 0.0))
			for key in Dictionary(stage.get("stats", {})):
				bonus_stats[key] = bonus_stats.get(key, 0) + int(stage.stats[key])
	return bonus_stats

func equipment_set_progress(loadout = null):
	var counts = equipment_set_counts(loadout)
	var progress = []
	for set_id in GameData.EQUIPMENT_SETS:
		var definition = Dictionary(GameData.EQUIPMENT_SETS[set_id])
		var stages = []
		for stage in Array(definition.bonuses):
			stages.append({"pieces": int(stage.pieces), "text": str(stage.text), "active": int(counts.get(str(set_id), 0)) >= int(stage.pieces)})
		progress.append({"id": str(set_id), "name": str(definition.name), "count": int(counts.get(str(set_id), 0)), "total": int(definition.total), "stages": stages})
	return progress

func equipment_set_name(item_id):
	if not GameData.ITEMS.has(str(item_id)):
		return ""
	var set_id = str(GameData.ITEMS[str(item_id)].get("set", ""))
	return str(GameData.EQUIPMENT_SETS[set_id].name) if GameData.EQUIPMENT_SETS.has(set_id) else ""

func dominant_equipment_set():
	var counts = equipment_set_counts()
	var selected_id = ""
	var selected_count = 0
	for set_id in counts:
		if int(counts[set_id]) > selected_count:
			selected_id = str(set_id)
			selected_count = int(counts[set_id])
	if selected_id == "":
		return {}
	var definition = Dictionary(GameData.EQUIPMENT_SETS[selected_id])
	return {"id": selected_id, "name": str(definition.name), "count": selected_count, "total": int(definition.total)}

func owns_equipment_item(item_id):
	if int(inventory.get(str(item_id), 0)) > 0:
		return true
	return str(item_id) in equipment.values()

func sea_set_weighted_drop_pool(set_id):
	var pool = []
	for item_id in GameData.equipment_set_items(str(set_id)):
		pool.append(str(item_id))
		# 缺件拥有三倍权重；仍保留重复件，保证刷装与强化材料循环不会被切断。
		if not owns_equipment_item(str(item_id)):
			pool.append(str(item_id))
			pool.append(str(item_id))
	return pool

func equipment_loadout_score(loadout = null):
	var resolved_loadout = equipment if typeof(loadout) != TYPE_DICTIONARY else Dictionary(loadout)
	var score = 0
	for item_id in resolved_loadout.values():
		score += equipment_item_score(str(item_id))
	var bonus = equipment_set_bonus_stats(resolved_loadout)
	score += int(round(float(bonus.max_hp) * 0.35 + float(bonus.attack) * 2.2 + float(bonus.defense) * 1.8 + float(bonus.speed) * 1.2 + float(bonus.drop_bonus) * 100.0))
	return score

func equipment_score_delta(item_id):
	if not GameData.ITEMS.has(item_id):
		return 0
	var slot = str(GameData.ITEMS[item_id].get("slot", ""))
	var candidate_loadout = equipment.duplicate(true)
	candidate_loadout[slot] = str(item_id)
	return equipment_loadout_score(candidate_loadout) - equipment_loadout_score(equipment)

func equip_recommended():
	var equipped_names = []
	for pass_index in range(GameData.SLOT_NAMES.size()):
		var best_item_id = ""
		var best_delta = 0
		for item_id in inventory:
			if int(inventory[item_id]) <= 0 or not GameData.ITEMS.has(item_id) or str(GameData.ITEMS[item_id].get("type", "")) != "equipment":
				continue
			var delta = equipment_score_delta(str(item_id))
			if delta > best_delta:
				best_delta = delta
				best_item_id = str(item_id)
		if best_item_id == "":
			break
		var result = equip_item(best_item_id)
		if bool(result.get("ok", false)):
			equipped_names.append(str(GameData.ITEMS[best_item_id].name))
	if equipped_names.is_empty():
		return {"ok": false, "message": "当前已穿戴背包中战力最高的装备。", "count": 0}
	return {"ok": true, "message": "已自动换上：%s" % "、".join(equipped_names), "count": equipped_names.size()}

func story_progress():
	var total = GameData.QUESTS.size()
	var completed = clamp(quest_index, 0, total)
	var chapter = GameData.STORY_CHAPTERS.back()
	for entry in GameData.STORY_CHAPTERS:
		if completed <= int(entry.end):
			chapter = entry
			break
	var chapter_total = int(chapter.end) - int(chapter.start) + 1
	var chapter_completed = clamp(completed - int(chapter.start), 0, chapter_total)
	var volume = GameData.STORY_VOLUMES.back()
	for entry in GameData.STORY_VOLUMES:
		if completed <= int(entry.end):
			volume = entry
			break
	var volume_total = int(volume.end) - int(volume.start) + 1
	var volume_completed = clamp(completed - int(volume.start), 0, volume_total)
	return {"completed": completed, "total": total, "volume": str(volume.title), "volume_completed": volume_completed, "volume_total": volume_total, "chapter": str(chapter.title), "chapter_completed": chapter_completed, "chapter_total": chapter_total, "summary": str(chapter.summary)}

func completed_story_titles(limit = 3):
	var titles = []
	var first = max(0, quest_index - int(limit))
	for index in range(first, min(quest_index, GameData.QUESTS.size())):
		titles.append(str(GameData.QUESTS[index].title))
	return titles

func quest_action_steps():
	var quest = get_current_quest()
	if quest.is_empty():
		return ["主线已经完成，可继续贸易、悬赏与远征。"]
	var objective = Dictionary(quest.objective)
	var objective_type = str(objective.type)
	var target_id = str(objective.target)
	var need = int(objective.need)
	var remaining = max(0, need - int(quest_progress))
	var steps = []
	match objective_type:
		"talk":
			var npc_location = _quest_npc_location(target_id)
			steps.append("前往%s" % _quest_location_name(npc_location))
			steps.append("与%s交谈" % GameData.NPCS[target_id].name)
		"visit":
			for cargo_id in Dictionary(objective.get("cargo", {})):
				var cargo_good = Dictionary(GameData.TRADE_GOODS[str(cargo_id)])
				var cargo_need = int(objective.cargo[cargo_id])
				var cargo_held = int(cargo.get(str(cargo_id), 0))
				if cargo_held < cargo_need:
					steps.append("启航前到%s采购%s×%d（现有%d/%d）" % [_quest_location_name(str(cargo_good.origin)), str(cargo_good.name), cargo_need - cargo_held, cargo_held, cargo_need])
			steps.append("前往%s" % _quest_location_name(target_id))
		"kill":
			var enemy_location = _quest_enemy_location(target_id)
			var enemy = Dictionary(GameData.ENEMIES[target_id])
			if int(player.hp) * 2 < int(get_stats().max_hp):
				steps.append("当前体力不足一半，先到旅店休息或使用恢复补给")
			steps.append("前往%s，击败Lv.%d %s×%d" % [_quest_location_name(enemy_location), int(enemy.level), str(enemy.name), remaining])
			if need > 1:
				steps.append("普通怪物击败后约%d秒刷新，可在附近探索等待" % int(ENEMY_RESPAWN_SECONDS))
		"trade_buy":
			var good = Dictionary(GameData.TRADE_GOODS[target_id])
			var origin = str(good.origin)
			steps.append("前往%s，找%s" % [_quest_location_name(origin), GameData.NPCS[str(GameData.TRADE_PORTS[origin].merchant_npc)].name])
			steps.append("买入%s×%d（任务进度%d/%d）" % [str(good.name), remaining, int(quest_progress), need])
		"trade_sell":
			var sell_good = Dictionary(GameData.TRADE_GOODS[target_id])
			var held = int(cargo.get(target_id, 0))
			var destination = str(objective.get("location", ""))
			if destination == "":
				var opportunity = best_trade_opportunity()
				destination = str(opportunity.get("destination", player.location))
			if held < remaining:
				steps.append("货舱还缺%s×%d，先到%s采购" % [str(sell_good.name), remaining - held, _quest_location_name(str(sell_good.origin))])
			steps.append("航行至%s，在当地市场卖出%s×%d" % [_quest_location_name(destination), str(sell_good.name), remaining])
		"upgrade_equipment":
			steps.append("打开角色信息，确认%s部位已经装备物品" % GameData.SLOT_NAMES[target_id])
			steps.append("消耗银币强化%s一次" % GameData.SLOT_NAMES[target_id])
		"upgrade_ship":
			steps.append("前往任意已发现港口，与当地船匠交谈")
			steps.append("选择“加固船体”并升级一次")
		"trade_order":
			var order = Dictionary(GameData.TRADE_ORDERS[target_id])
			var order_good_id = str(order.good)
			var order_good = Dictionary(GameData.TRADE_GOODS[order_good_id])
			var held_amount = int(cargo.get(order_good_id, 0))
			if held_amount < int(order.amount):
				steps.append("到%s采购%s×%d（现有%d/%d）" % [_quest_location_name(str(order_good.origin)), str(order_good.name), int(order.amount) - held_amount, held_amount, int(order.amount)])
			steps.append("前往%s，找商会订单负责人交付“%s”" % [_quest_location_name(str(order.port)), str(order.title)])
		"trade_reputation":
			steps.append("当前九港总声望%d/%d" % [total_trade_reputation(), need])
			steps.append("完成港口商会订单，或在异地盈利出售至少一批货物")
		"prepare_voyage":
			steps.append("前往任意已发现港口，与港务负责人交谈")
			steps.append("购买一次护航物资；下一次正常航行风险降低并防止风暴损货")
		"cook":
			var recipe = Dictionary(GameData.RECIPES[target_id])
			for good_id in recipe.cargo:
				var ingredient = Dictionary(GameData.TRADE_GOODS[str(good_id)])
				var ingredient_need = int(recipe.cargo[good_id])
				var ingredient_held = int(cargo.get(str(good_id), 0))
				steps.append("%s：%d/%d，产地%s" % [str(ingredient.name), ingredient_held, ingredient_need, _quest_location_name(str(ingredient.origin))])
			steps.append("带齐原料后前往%s厨房烹制%s" % [_quest_location_name(str(recipe.port)), str(recipe.name)])
		_:
			steps.append(GameData.objective_name(objective))
	return steps

func _quest_npc_location(npc_id):
	for location_id in GameData.LOCATIONS:
		if str(npc_id) in Array(GameData.LOCATIONS[location_id].get("npcs", [])):
			return str(location_id)
	return str(player.location)

func _quest_enemy_location(enemy_id):
	for location_id in GameData.LOCATIONS:
		if str(enemy_id) in Array(GameData.LOCATIONS[location_id].get("enemies", [])):
			return str(location_id)
	return str(player.location)

func _quest_location_name(location_id):
	var resolved = str(location_id)
	if GameData.TRADE_PORTS.has(resolved):
		return "%s港" % GameData.TRADE_PORTS[resolved].name
	if GameData.LOCATIONS.has(resolved):
		return str(GameData.LOCATIONS[resolved].name)
	return "当前地点"

func equip_card(item_id):
	if int(inventory.get(item_id, 0)) <= 0:
		return {"ok": false, "message": "你还没有这张怪物卡。"}
	var item = GameData.ITEMS.get(item_id, {})
	if str(item.get("type", "")) != "card":
		return {"ok": false, "message": "这不是可启用的怪物卡。"}
	active_card = str(item_id)
	player.hp = min(int(player.hp), int(get_stats().max_hp))
	message_history.push_front("启用%s，获得专属加成。" % item.name)
	_trim_history()
	save_game()
	return {"ok": true, "message": "已启用%s：%s" % [item.name, item.description]}

func claim_discovery(discovery_id):
	if not GameData.DISCOVERIES.has(discovery_id):
		return {"ok": false, "message": "这里没有可调查的线索。"}
	if bool(discoveries.get(discovery_id, false)):
		return {"ok": false, "message": "这条线索已经调查过了。"}
	var data = GameData.DISCOVERIES[discovery_id]
	discoveries[discovery_id] = true
	player.silver += int(data.get("silver", 0))
	var item_id = str(data.get("item", ""))
	if item_id != "" and GameData.ITEMS.has(item_id):
		_add_item(item_id, 1)
	var reward_text = "%d银币" % int(data.get("silver", 0))
	if item_id != "":
		reward_text += "、%s×1" % GameData.ITEMS[item_id].name
	message_history.push_front("发现%s，获得%s。" % [data.name, reward_text])
	_trim_history()
	save_game()
	return {"ok": true, "name": data.name, "lore": data.lore, "reward_text": reward_text}

func get_bounty():
	if GameData.BOUNTIES.is_empty():
		return {}
	return GameData.BOUNTIES[bounty_index % GameData.BOUNTIES.size()]

func bounty_can_claim():
	var bounty = get_bounty()
	return not bounty.is_empty() and bounty_progress >= int(bounty.need)

func claim_bounty():
	var bounty = get_bounty()
	if bounty.is_empty() or not bounty_can_claim():
		return {"ok": false, "message": "当前悬赏目标尚未完成。"}
	var silver_reward = int(bounty.silver) + bounty_cycles * 8
	player.silver += silver_reward
	var leveled = _add_xp(int(bounty.exp))
	if bounty_cycles % 2 == 1:
		_add_item("unknown_equipment", 1)
	var completed_title = str(bounty.title)
	bounty_index = (bounty_index + 1) % GameData.BOUNTIES.size()
	bounty_cycles += 1
	bounty_progress = 0
	message_history.push_front("完成悬赏「%s」，获得%d银币。" % [completed_title, silver_reward])
	_trim_history()
	save_game()
	return {"ok": true, "message": "悬赏完成：%d银币、%d经验" % [silver_reward, int(bounty.exp)], "leveled": leveled}

func _advance_bounty(enemy_id):
	var bounty = get_bounty()
	if bounty.is_empty() or str(bounty.target) != str(enemy_id) or bounty_can_claim():
		return false
	bounty_progress = min(int(bounty.need), bounty_progress + 1)
	return bounty_can_claim()

func recruit_companion():
	if not companion_unlocked:
		return {"ok": false, "message": "完成「失窃的矿石」后，才有人愿意加入你的队伍。"}
	if not party_members.is_empty():
		return {"ok": false, "message": "%s已经在队伍中。" % party_members[0]}
	party_members = ["见习水手·卢卡"]
	message_history.push_front("见习水手·卢卡加入队伍，攻防提高5%。")
	_trim_history()
	save_game()
	return {"ok": true, "message": "组队成功：攻防提高 5%"}

func leave_party():
	if party_members.is_empty():
		return {"ok": false, "message": "当前没有队友。"}
	party_members = []
	save_game()
	return {"ok": true, "message": "已离开当前队伍。"}

func enemy_respawn_remaining(enemy_id):
	var deadline = float(enemy_respawns.get(str(enemy_id), 0.0))
	return max(0.0, deadline - float(Time.get_unix_time_from_system()))

func story_recommended_sea_level():
	var current_quest = clamp(int(quest_index), 0, GameData.QUESTS.size())
	if current_quest < 7:
		return 3
	if current_quest < 19:
		return 8
	if current_quest < 28:
		return 16
	if current_quest < 38:
		return 24
	var recommended = 30
	for expedition_id in GameData.EXPEDITIONS:
		var expedition = Dictionary(GameData.EXPEDITIONS[expedition_id])
		if current_quest >= int(expedition.quest_start):
			recommended = max(recommended, int(expedition.min_level))
	return recommended

func sea_encounter_level(enemy_id, zone_id):
	var player_level = max(1, int(player.level))
	# 主线只做段内修正，避免异常存档让任务等级远超角色等级。
	var story_level = clamp(story_recommended_sea_level(), max(1, player_level - 18), min(GameData.MAX_LEVEL, player_level + 10))
	var blended = int(round(float(player_level) * 0.72 + float(story_level) * 0.28))
	var resolved_zone = str(zone_id)
	var band = GameData.sea_zone_level_band(resolved_zone)
	var zone_offset = int(GameData.SEA_ZONE_LEVEL_OFFSETS.get(resolved_zone, 0))
	var enemy_offset = int(GameData.SEA_ENEMY_LEVEL_OFFSETS.get(str(enemy_id), 0))
	return clamp(blended + zone_offset + enemy_offset, int(band.min), int(band.max))

func _scaled_sea_enemy_profile(enemy_id, threat_level):
	var profile = Dictionary(GameData.ENEMIES[str(enemy_id)]).duplicate(true)
	var base_level = max(1, int(profile.level))
	var resolved_level = clamp(int(threat_level), 1, GameData.MAX_LEVEL)
	var scale = max(0.18, float(resolved_level + 7) / float(base_level + 7))
	profile.level = resolved_level
	profile.hp = max(30, int(round(float(profile.hp) * pow(scale, 1.30))))
	profile.attack = max(7, int(round(float(profile.attack) * pow(scale, 1.05))))
	profile.defense = max(1, int(round(float(profile.defense) * pow(scale, 1.02))))
	profile.speed = max(4, int(round(float(profile.speed) * pow(scale, 0.78))))
	profile.exp = max(18, int(round(float(profile.exp) * pow(scale, 1.12))))
	var silver_scale = pow(scale, 0.92)
	profile.silver = [
		max(4, int(round(float(profile.silver[0]) * silver_scale))),
		max(7, int(round(float(profile.silver[1]) * silver_scale)))
	]
	return profile

func _battle_enemy_profile():
	if active_battle.is_empty():
		return {}
	if active_battle.has("enemy_profile") and typeof(active_battle.enemy_profile) == TYPE_DICTIONARY:
		return Dictionary(active_battle.enemy_profile)
	return Dictionary(GameData.ENEMIES.get(str(active_battle.get("enemy_id", "")), {}))

func start_battle(enemy_id):
	if not GameData.ENEMIES.has(enemy_id):
		return {"ok": false, "message": "敌人不存在。"}
	var location = GameData.LOCATIONS[player.location]
	var sea_encounter = not active_voyage.is_empty() and bool(GameData.ENEMIES[enemy_id].get("sea_enemy", false))
	if not sea_encounter and not enemy_id in location.enemies:
		return {"ok": false, "message": "这个敌人不在当前区域。"}
	var respawn_remaining = enemy_respawn_remaining(enemy_id)
	if respawn_remaining > 0.0:
		return {"ok": false, "message": "%s尚未重新出现，约%d秒后可再次挑战。" % [GameData.ENEMIES[enemy_id].name, int(ceil(respawn_remaining))], "respawn_remaining": respawn_remaining}
	if not active_battle.is_empty():
		if active_battle.enemy_id == enemy_id:
			return get_battle_view()
		return {"ok": false, "message": "你正在与其他敌人战斗。"}
	var enemy = Dictionary(GameData.ENEMIES[enemy_id])
	var sea_zone_id = ""
	var loot_tier_name = ""
	var sea_set_boss = {}
	if sea_encounter:
		var encounter = sea_encounter(str(active_voyage.get("current_encounter_id", "")))
		sea_zone_id = str(encounter.get("zone_id", GameData.sea_zone_for_port(str(active_voyage.get("origin", player.location)))))
		var threat_level = int(encounter.get("threat_level", sea_encounter_level(enemy_id, sea_zone_id)))
		enemy = _scaled_sea_enemy_profile(enemy_id, threat_level)
		loot_tier_name = str(GameData.sea_equipment_tier(threat_level).name)
		if bool(encounter.get("set_boss", false)):
			sea_set_boss = GameData.sea_set_boss(sea_zone_id, enemy_id)
			if not sea_set_boss.is_empty():
				enemy.name = str(sea_set_boss.boss_name)
				enemy.rank = "海域 Boss"
				var set_definition = Dictionary(GameData.EQUIPMENT_SETS[str(sea_set_boss.set_id)])
				loot_tier_name = "%s整套 · %d%%随机掉落" % [str(set_definition.name), int(round(float(sea_set_boss.drop_rate) * 100.0))]
	var scaled_enemy_hp = difficulty_enemy_hp(int(enemy.hp))
	active_battle = {
		"enemy_id": enemy_id, "enemy_hp": scaled_enemy_hp, "enemy_max_hp": scaled_enemy_hp,
		"enemy_profile": enemy, "sea_zone_id": sea_zone_id,
		"sea_zone_name": str(GameData.SEA_REGIONS.get(sea_zone_id, {}).get("name", "")),
		"loot_tier_name": loot_tier_name, "sea_balance_version": GameData.SEA_BALANCE_VERSION,
		"sea_set_id": str(sea_set_boss.get("set_id", "")), "sea_set_drop_rate": float(sea_set_boss.get("drop_rate", 0.0)),
		"round": 1, "focus": 0, "skill_prepared": false, "sea_battle": sea_encounter, "log": [enemy.intro]
	}
	player.battles += 1
	save_game()
	var view = get_battle_view()
	view.logs = [enemy.intro]
	return view

func get_battle_view():
	if active_battle.is_empty():
		return {"ok": false, "message": "当前没有战斗。"}
	var enemy = _battle_enemy_profile()
	var combat_stats = get_battle_stats()
	var sea_battle = bool(active_battle.get("sea_battle", false))
	return {
		"ok": true, "battle_over": false, "won": false,
		"enemy_id": active_battle.enemy_id, "enemy_name": enemy.name, "enemy_rank": enemy.rank, "enemy_level": int(enemy.level),
		"enemy_hp": int(active_battle.enemy_hp), "enemy_max_hp": int(active_battle.enemy_max_hp),
		"player_level": int(player.level), "player_hp": int(player.hp), "player_max_hp": int(get_stats().max_hp),
		"player_attack": int(combat_stats.attack), "player_defense": int(combat_stats.defense),
		"sea_battle": sea_battle, "combatant_name": str(ship.name) if sea_battle else str(player.name),
		"ship_role": ship_role(), "ship_hull_id": str(ship.get("hull_id", "sea_swallow")), "ship_cannon_power": ship_cannon_power(),
		"round": int(active_battle.round), "statuses": statuses.duplicate(), "logs": [],
		"battle_stance": battle_stance, "enemy_intent": get_enemy_intent(),
		"sea_zone_id": str(active_battle.get("sea_zone_id", "")), "sea_zone_name": str(active_battle.get("sea_zone_name", "")),
		"loot_tier_name": str(active_battle.get("loot_tier_name", "")), "dynamic_threat": sea_battle,
		"sea_set_id": str(active_battle.get("sea_set_id", "")), "sea_set_drop_rate": float(active_battle.get("sea_set_drop_rate", 0.0)),
		"auto_heal_threshold": auto_heal_threshold, "auto_cure_status": auto_cure_status,
		"focus": battle_focus(), "focus_max": 3, "difficulty": difficulty, "difficulty_name": difficulty_name()
	}

func battle_focus():
	return clamp(int(active_battle.get("focus", 0)), 0, 3) if not active_battle.is_empty() else 0

func skill_attack():
	if active_battle.is_empty():
		return {"ok": false, "message": "当前没有战斗。"}
	if battle_focus() < 3:
		return {"ok": false, "message": "潮势不足，普通攻击或坚守可积蓄潮势。"}
	active_battle.skill_prepared = true
	return attack_once()

func set_battle_stance(value):
	if not str(value) in ["assault", "balanced", "guard", "plunder"]:
		return {"ok": false, "message": "未知的战斗姿态。"}
	battle_stance = str(value)
	save_game()
	return {"ok": true, "message": "战斗姿态已调整。"}

func get_enemy_intent():
	if active_battle.is_empty():
		return ""
	var enemy = _battle_enemy_profile()
	var special = enemy.get("special", {})
	var every = int(special.get("every", 0))
	if every > 0 and int(active_battle.round) % every == 0:
		return "⚠ %s正在蓄力" % str(special.get("name", "强力攻击"))
	return "准备普通攻击"

func auto_use_battle_supplies():
	var logs = []
	if active_battle.is_empty():
		return {"ok": false, "used": false, "logs": logs}
	if auto_cure_status and not statuses.is_empty() and int(inventory.get("universal_medicine", 0)) > 0:
		var cure = use_item("universal_medicine")
		if bool(cure.get("ok", false)):
			logs.append("自动补给｜使用万能药解除异常状态。")
	if auto_heal_threshold > 0:
		var hp_ratio = float(player.hp) / max(1.0, float(get_stats().max_hp)) * 100.0
		if hp_ratio <= float(auto_heal_threshold):
			for item_id in ["sea_salt_bread", "small_milk", "stamina_tonic"]:
				if int(inventory.get(item_id, 0)) <= 0:
					continue
				var heal = use_item(item_id)
				if bool(heal.get("ok", false)):
					logs.append("自动补给｜使用%s，%s" % [GameData.ITEMS[item_id].name, str(heal.get("message", "恢复体力。"))])
				break
	return {"ok": true, "used": not logs.is_empty(), "logs": logs}

func attack_once():
	if active_battle.is_empty():
		return {"ok": false, "message": "当前没有战斗。"}
	var enemy_id = active_battle.enemy_id
	var enemy = _battle_enemy_profile()
	var stats = get_battle_stats()
	var logs = []
	var player_attack = int(stats.attack)
	var player_speed = int(stats.speed)
	var uses_skill = bool(active_battle.get("skill_prepared", false)) and battle_focus() >= 3
	var special = enemy.get("special", {})
	var special_every = int(special.get("every", 0))
	var counters_special = uses_skill and special_every > 0 and int(active_battle.round) % special_every == 0
	match battle_stance:
		"assault": player_attack = max(1, int(round(float(player_attack) * 1.18)))
		"guard": player_attack = max(1, int(round(float(player_attack) * 0.86)))
		"plunder": player_attack = max(1, int(round(float(player_attack) * 0.92)))
	if uses_skill:
		player_attack = max(1, int(round(float(player_attack) * 1.75)))
		active_battle.focus = battle_focus() - 3
		active_battle.skill_prepared = false
	if statuses.has("虚弱"):
		player_attack = max(1, int(round(player_attack * 0.75)))
	if statuses.has("缓慢"):
		player_speed = max(1, int(round(player_speed * 0.70)))
	var player_first = player_speed >= int(enemy.speed)
	var round_number = int(active_battle.round)

	if player_first:
		_player_strike(enemy, player_attack, round_number, logs, uses_skill)
		if int(active_battle.enemy_hp) > 0:
			_pet_strike(enemy, round_number, logs)
		if int(active_battle.enemy_hp) > 0:
			_enemy_strike(enemy, stats, round_number, logs, counters_special)
	else:
		_enemy_strike(enemy, stats, round_number, logs, counters_special)
		if int(player.hp) > 0:
			_player_strike(enemy, player_attack, round_number, logs, uses_skill)
			if int(active_battle.enemy_hp) > 0:
				_pet_strike(enemy, round_number, logs)
	if not uses_skill and int(player.hp) > 0:
		var focus_gain = 2 if battle_stance == "guard" else 1
		active_battle.focus = min(3, battle_focus() + focus_gain)
		if int(active_battle.focus) >= 3:
			logs.append("潮势已满｜可发动舷炮齐射，若敌人正在蓄力可削弱其技能。" if bool(active_battle.get("sea_battle", false)) else "潮势已满｜可发动破浪斩，若敌人正在蓄力可削弱其技能。")

	_apply_status_tick(logs)
	_tick_statuses()
	active_battle.round = round_number + 1
	active_battle.log.append_array(logs)
	if active_battle.log.size() > 30:
		active_battle.log = active_battle.log.slice(active_battle.log.size() - 30)

	if int(active_battle.enemy_hp) <= 0:
		return _finish_battle_win(enemy_id, logs)
	if int(player.hp) <= 0:
		return _finish_battle_loss(enemy_id, logs)

	save_game()
	var result = get_battle_view()
	result.logs = logs
	return result

func auto_attack():
	if active_battle.is_empty():
		return {"ok": false, "message": "当前没有战斗。"}
	var all_logs = ["已开启自动攻击。"]
	var last_result = {}
	for _step in range(40):
		var should_counter = battle_focus() >= 3 and str(get_enemy_intent()).begins_with("⚠")
		last_result = skill_attack() if should_counter else attack_once()
		if not last_result.get("ok", false):
			return last_result
		all_logs.append_array(last_result.get("logs", []))
		if bool(last_result.get("battle_over", false)):
			break
	last_result.logs = all_logs
	return last_result

func flee_battle():
	if active_battle.is_empty():
		return {"ok": false, "message": "当前没有战斗。"}
	var enemy = GameData.ENEMIES[active_battle.enemy_id]
	var flee_chance = ship_escape_chance() if bool(active_battle.get("sea_battle", false)) else 0.72
	if rng.randf() <= flee_chance:
		active_battle = {}
		statuses = {}
		if not active_voyage.is_empty():
			active_voyage.current_encounter_id = ""
		save_game()
		return {"ok": true, "battle_over": true, "won": false, "fled": true, "enemy_name": enemy.name, "enemy_rank": enemy.rank, "logs": ["你抓住空隙撤出了战斗。"]}
	var result = attack_once()
	result.logs.push_front("撤退失败，%s追了上来！" % enemy.name)
	return result

func _player_strike(enemy, player_attack, round_number, logs, uses_skill = false):
	var result = _roll_attack(player_attack, enemy.defense, int(player.level), int(enemy.level))
	active_battle.enemy_hp = max(0, int(active_battle.enemy_hp) - int(result.damage))
	var sea_battle = bool(active_battle.get("sea_battle", false))
	if sea_battle and result.miss and uses_skill:
		logs.append("第%d回合｜%s舷炮齐射，炮弹落在%s侧舷之外。" % [round_number, str(ship.name), enemy.name])
	elif sea_battle and result.miss:
		logs.append("第%d回合｜%s舰炮射击，被%s抢先转向避开。" % [round_number, str(ship.name), enemy.name])
	elif sea_battle and uses_skill:
		logs.append("第%d回合｜舷炮齐射！%s命中%s，耐久-%d！" % [round_number, str(ship.name), enemy.name, result.damage])
	elif sea_battle and result.crit:
		logs.append("第%d回合｜舰炮命中水线！%s耐久-%d。" % [round_number, enemy.name, result.damage])
	elif sea_battle:
		logs.append("第%d回合｜%s开炮命中%s，耐久-%d。" % [round_number, str(ship.name), enemy.name, result.damage])
	elif result.miss and uses_skill:
		logs.append("第%d回合｜你发动破浪斩，刀锋擦过%s。" % [round_number, enemy.name])
	elif result.miss:
		logs.append("第%d回合｜你的攻击被%s避开。" % [round_number, enemy.name])
	elif uses_skill:
		logs.append("第%d回合｜破浪斩！潮光贯穿%s，体力-%d！" % [round_number, enemy.name, result.damage])
	elif result.crit:
		logs.append("第%d回合｜气贯全身，致命一击！%s体力-%d。" % [round_number, enemy.name, result.damage])
	else:
		logs.append("第%d回合｜你向%s发起攻击，体力-%d。" % [round_number, enemy.name, result.damage])

func _pet_strike(enemy, round_number, logs):
	if pet.is_empty():
		return
	var damage = max(1, int(round(float(get_stats().attack) * 0.28 - float(enemy.defense) * 0.15)))
	active_battle.enemy_hp = max(0, int(active_battle.enemy_hp) - damage)
	logs.append("第%d回合｜宠物%s扑向敌人，追加%d点伤害。" % [round_number, pet.name, damage])

func _enemy_strike(enemy, stats, round_number, logs, special_weakened = false):
	var effective_defense = int(stats.defense)
	if battle_stance == "assault":
		effective_defense = max(0, int(round(float(effective_defense) * 0.90)))
	elif battle_stance == "guard":
		effective_defense = int(round(float(effective_defense) * 1.28))
	if statuses.has("诅咒"):
		effective_defense = max(0, int(round(effective_defense * 0.80)))
	var enemy_attack = difficulty_enemy_attack(int(enemy.attack))
	var special = enemy.get("special", {})
	var special_every = int(special.get("every", 0))
	var uses_special = special_every > 0 and round_number % special_every == 0
	if uses_special:
		enemy_attack = int(round(float(enemy_attack) * float(special.get("damage_multiplier", 1.0))))
		if special_weakened:
			enemy_attack = max(1, int(round(float(enemy_attack) * 0.55)))
	var result = _roll_attack(enemy_attack, effective_defense, int(enemy.level), int(player.level))
	player.hp = max(0, int(player.hp) - int(result.damage))
	if result.miss:
		logs.append("第%d回合｜你避开了%s的攻击。" % [round_number, enemy.name])
	elif uses_special and special_weakened:
		var counter_name = "舷炮齐射" if bool(active_battle.get("sea_battle", false)) else "破浪斩"
		logs.append("第%d回合｜%s打乱了%s的%s，你的体力仅-%d。" % [round_number, counter_name, enemy.name, str(special.get("name", "强力攻击")), result.damage])
	elif uses_special:
		logs.append("第%d回合｜%s施放%s，你的体力-%d！" % [round_number, enemy.name, str(special.get("name", "强力攻击")), result.damage])
	elif result.crit:
		logs.append("第%d回合｜%s发动猛击，你的体力-%d！" % [round_number, enemy.name, result.damage])
	else:
		logs.append("第%d回合｜%s向你发起攻击，体力-%d。" % [round_number, enemy.name, result.damage])
	var effect_chance = float(enemy.get("effect", {}).get("chance", 0.0))
	var incoming_effect = str(enemy.get("effect", {}).get("name", ""))
	if active_card == "ghost_card" and incoming_effect == "诅咒":
		effect_chance *= 0.50
	elif active_card == "tide_card" and incoming_effect == "缓慢":
		effect_chance *= 0.50
	if int(result.damage) > 0 and enemy.has("effect") and rng.randf() <= effect_chance:
		var effect_name = enemy.effect.name
		statuses[effect_name] = max(int(statuses.get(effect_name, 0)), int(enemy.effect.rounds))
		logs.append("状态变化｜你陷入%s（%d回合）。" % [effect_name, int(enemy.effect.rounds)])

func _apply_status_tick(logs):
	if statuses.has("中毒") and int(player.hp) > 0:
		var damage = max(3, int(round(float(get_stats().max_hp) * 0.04)))
		player.hp = max(0, int(player.hp) - damage)
		logs.append("状态伤害｜毒素发作，你的体力-%d。" % damage)

func _tick_statuses():
	var expired = []
	for status_name in statuses:
		statuses[status_name] = int(statuses[status_name]) - 1
		if int(statuses[status_name]) <= 0:
			expired.append(status_name)
	for status_name in expired:
		statuses.erase(status_name)

func _finish_battle_win(enemy_id, round_logs):
	var enemy = _battle_enemy_profile()
	var defeated_enemy_max_hp = int(active_battle.get("enemy_max_hp", difficulty_enemy_hp(int(enemy.hp))))
	var was_sea_battle = bool(active_battle.get("sea_battle", false))
	var sea_zone_id = str(active_battle.get("sea_zone_id", ""))
	var sea_zone_name = str(active_battle.get("sea_zone_name", ""))
	var loot_tier_name = str(active_battle.get("loot_tier_name", ""))
	var finishing_stance = battle_stance
	player.victories += 1
	player.hp = max(1, int(player.hp))
	var exp_reward = difficulty_battle_reward(int(enemy.exp))
	var silver = difficulty_battle_reward(rng.randi_range(int(enemy.silver[0]), int(enemy.silver[1])))
	player.silver += silver
	var leveled = _add_xp(exp_reward)
	defeated[enemy_id] = int(defeated.get(enemy_id, 0)) + 1
	if _is_dungeon_location(str(player.location)):
		dungeon_cleared[enemy_id] = true
	var sea_victory = not active_voyage.is_empty() and bool(enemy.get("sea_enemy", false))
	if sea_victory:
		mark_sea_encounter_defeated(str(active_voyage.get("current_encounter_id", "")))
	elif not _is_dungeon_location(str(player.location)):
		enemy_respawns[str(enemy_id)] = float(Time.get_unix_time_from_system()) + ENEMY_RESPAWN_SECONDS
	var quest_completed = _advance_quest("kill", enemy_id)
	var bounty_completed = _advance_bounty(enemy_id)
	var drop_id = ""
	var stats = get_stats()
	var stance_drop_bonus = 0.14 if finishing_stance == "plunder" else 0.0
	var difficulty_drop_bonus = 0.10 if difficulty == DIFFICULTY_ADVENTURE else 0.0
	var sea_set_id = str(active_battle.get("sea_set_id", ""))
	var sea_set_drop_rate = float(active_battle.get("sea_set_drop_rate", 0.0))
	var drop_chance = 1.0 if enemy.rank in ["首领", "副本 Boss"] else min(0.90, 0.22 + float(stats.drop_bonus) + stance_drop_bonus + difficulty_drop_bonus)
	if sea_set_id != "":
		# 套装 Boss 保持随机掉落；寻宝属性、冒险难度与掠夺姿态可把概率推高，但不会变成必掉。
		drop_chance = min(0.92, sea_set_drop_rate + float(stats.drop_bonus) * 0.35 + stance_drop_bonus * 0.5 + difficulty_drop_bonus * 0.5)
	if rng.randf() <= drop_chance:
		var drop_pool = sea_set_weighted_drop_pool(sea_set_id) if sea_set_id != "" else Array(enemy.get("drops", []))
		if sea_set_id == "" and was_sea_battle and rng.randf() <= 0.45:
			drop_pool = GameData.sea_equipment_pool(sea_zone_id, int(enemy.level))
		if drop_pool.is_empty():
			drop_pool = Array(enemy.get("drops", []))
		if not drop_pool.is_empty():
			drop_id = str(drop_pool[rng.randi_range(0, drop_pool.size() - 1)])
			_add_item(drop_id, 1)
	round_logs.append("战斗胜利！获得%d经验、%d银币。" % [exp_reward, silver])
	if drop_id != "":
		round_logs.append("套装猎场掉落：%s（缺件拥有更高权重）。" % GameData.ITEMS[drop_id].name if sea_set_id != "" else "百宝箱拾取：%s。" % GameData.ITEMS[drop_id].name)
	message_history.push_front("击败%s，获得%d经验。" % [enemy.name, exp_reward])
	_trim_history()
	active_battle = {}
	statuses = {}
	_consume_meal_battle()
	save_game()
	return {
		"ok": true, "battle_over": true, "won": true, "fled": false,
		"enemy_id": enemy_id, "enemy_name": enemy.name, "enemy_rank": enemy.rank, "enemy_level": int(enemy.level),
		"enemy_hp": 0, "enemy_max_hp": defeated_enemy_max_hp, "player_level": int(player.level), "player_hp": int(player.hp), "player_max_hp": int(get_stats().max_hp),
		"sea_battle": was_sea_battle, "combatant_name": str(ship.name) if was_sea_battle else str(player.name),
		"sea_zone_id": sea_zone_id, "sea_zone_name": sea_zone_name, "loot_tier_name": loot_tier_name, "dynamic_threat": was_sea_battle,
		"sea_set_id": sea_set_id, "sea_set_drop_rate": sea_set_drop_rate,
		"round": 0, "statuses": {}, "logs": round_logs,
		"exp": exp_reward, "silver": silver, "drop": drop_id, "leveled": leveled, "new_level": int(player.level),
		"quest_completed": quest_completed, "bounty_completed": bounty_completed, "battle_stance": finishing_stance
	}

func _finish_battle_loss(enemy_id, round_logs):
	var enemy = _battle_enemy_profile()
	var was_sea_battle = bool(active_battle.get("sea_battle", false))
	var sea_zone_id = str(active_battle.get("sea_zone_id", ""))
	var sea_zone_name = str(active_battle.get("sea_zone_name", ""))
	var loot_tier_name = str(active_battle.get("loot_tier_name", ""))
	var voyage_origin = str(active_voyage.get("origin", ""))
	var lost_at_sea = voyage_origin in GameData.TRADE_PORTS
	var remaining_enemy_hp = int(active_battle.get("enemy_hp", enemy.hp))
	var defeated_enemy_max_hp = int(active_battle.get("enemy_max_hp", difficulty_enemy_hp(int(enemy.hp))))
	var defeated_player_hp = int(player.hp)
	var recovery_ratio = 0.25 if difficulty == DIFFICULTY_ADVENTURE else 0.35
	player.hp = max(1, int(get_stats().max_hp * recovery_ratio))
	var recovered_hp = int(player.hp)
	player.location = voyage_origin if lost_at_sea else "venice_tavern"
	if lost_at_sea:
		active_voyage = {}
	statuses = {}
	active_battle = {}
	dungeon_cleared = {}
	_consume_meal_battle()
	round_logs.append("你失去了意识。护航船把你送回%s，未损失装备和银币。" % GameData.TRADE_PORTS[voyage_origin].name if lost_at_sea else "你失去了意识。巡逻队把你送回酒馆，未损失装备和银币。")
	message_history.push_front("挑战%s失败，被送回%s。" % [enemy.name, GameData.TRADE_PORTS[voyage_origin].name] if lost_at_sea else "挑战%s失败，被送回威尼斯酒馆。" % enemy.name)
	_trim_history()
	save_game()
	return {
		"ok": true, "battle_over": true, "won": false, "fled": false,
		"enemy_id": enemy_id, "enemy_name": enemy.name, "enemy_rank": enemy.rank, "enemy_level": int(enemy.level),
		"enemy_hp": remaining_enemy_hp, "enemy_max_hp": defeated_enemy_max_hp, "player_level": int(player.level),
		"player_hp": defeated_player_hp, "player_max_hp": int(get_stats().max_hp), "recovered_hp": recovered_hp, "round": 0, "statuses": {},
		"sea_battle": was_sea_battle, "combatant_name": str(ship.name) if was_sea_battle else str(player.name),
		"sea_zone_id": sea_zone_id, "sea_zone_name": sea_zone_name, "loot_tier_name": loot_tier_name, "dynamic_threat": was_sea_battle,
		"logs": round_logs, "exp": 0, "silver": 0, "drop": "", "leveled": false, "new_level": int(player.level),
		"return_port": voyage_origin if lost_at_sea else "venice_tavern", "lost_at_sea": lost_at_sea
	}

func _roll_attack(attack, defense, attacker_level, defender_level):
	var miss_chance = clamp(0.06 + float(defender_level - attacker_level) * 0.025, 0.03, 0.18)
	if rng.randf() < miss_chance:
		return {"damage": 0, "miss": true, "crit": false}
	var raw = max(1.0, float(attack) - float(defense) * 0.52)
	var damage = int(round(raw * rng.randf_range(0.90, 1.10)))
	var crit = rng.randf() < 0.11
	if crit:
		damage = int(round(damage * 1.55))
	return {"damage": max(1, damage), "miss": false, "crit": crit}

func _consume_meal_battle():
	if meal_buff_battles <= 0:
		return
	meal_buff_battles -= 1
	player.hp = min(int(player.hp), int(get_stats().max_hp))

func _add_xp(amount):
	var leveled = false
	if int(player.level) >= GameData.MAX_LEVEL:
		player.xp = 0
		return false
	player.xp += amount
	while int(player.xp) >= GameData.xp_needed(int(player.level)) and int(player.level) < GameData.MAX_LEVEL:
		player.xp -= GameData.xp_needed(int(player.level))
		player.level += 1
		leveled = true
		player.hp = get_stats().max_hp
		message_history.push_front("升到 Lv.%d，体力已完全恢复！" % int(player.level))
	if int(player.level) >= GameData.MAX_LEVEL:
		player.xp = 0
	return leveled

func get_current_quest():
	if quest_index >= GameData.QUESTS.size():
		return {}
	return GameData.QUESTS[quest_index]

func quest_can_claim():
	var quest = get_current_quest()
	return not quest.is_empty() and quest_progress >= int(quest.objective.need)

func claim_quest():
	var quest = get_current_quest()
	if quest.is_empty():
		return {"ok": false, "message": "当前没有进行中的任务。"}
	if not quest_can_claim():
		return {"ok": false, "message": "任务目标尚未完成。"}
	var reward = quest.reward
	player.silver += int(reward.get("silver", 0))
	var leveled = _add_xp(int(reward.get("exp", 0)))
	var item_name = ""
	if reward.has("item") and GameData.ITEMS.has(reward.item):
		_add_item(reward.item, 1)
		item_name = GameData.ITEMS[reward.item].name
	if bool(reward.get("companion", false)):
		companion_unlocked = true
	if reward.has("pet") and GameData.PETS.has(reward.pet):
		pet = GameData.PETS[reward.pet].duplicate(true)
		pet.id = reward.pet
	if reward.has("title"):
		player.title = str(reward.title)
	var old_title = quest.title
	quest_index += 1
	quest_progress = 0
	_sync_current_quest_progress()
	var next_quest = get_current_quest()
	var chapter_complete = next_quest.is_empty()
	message_history.push_front("完成任务「%s」。" % old_title)
	_trim_history()
	save_game()
	var reward_text = "%d经验、%d银币" % [int(reward.get("exp", 0)), int(reward.get("silver", 0))]
	if item_name != "":
		reward_text += "、%s" % item_name
	if reward.has("pet"):
		reward_text += "、宠物%s" % GameData.PETS[reward.pet].name
	if reward.has("title"):
		reward_text += "、称号「%s」" % str(reward.title)
	return {
		"ok": true, "message": "任务完成！获得%s" % reward_text, "reward_text": reward_text,
		"completed_title": old_title, "leveled": leveled, "reward_item": reward.get("item", ""),
		"next_quest": next_quest, "chapter_complete": chapter_complete, "trade_unlocked": is_trade_unlocked()
	}

func _advance_quest(action_type, target, amount = 1):
	var quest = get_current_quest()
	if quest.is_empty():
		return false
	var was_complete = quest_can_claim()
	var objective = quest.objective
	var required_location = str(objective.get("location", ""))
	var at_required_location = required_location == "" or str(player.location) == required_location
	if objective.type == action_type and objective.target == target and at_required_location:
		quest_progress = min(int(objective.need), quest_progress + amount)
	return not was_complete and quest_can_claim()

func _sync_current_quest_progress():
	var quest = get_current_quest()
	if quest.is_empty():
		return false
	var was_complete = quest_can_claim()
	var objective = quest.objective
	if str(objective.type) == "trade_reputation" and str(objective.target) == "total":
		quest_progress = min(int(objective.need), total_trade_reputation())
	elif str(objective.type) == "prepare_voyage" and str(objective.target) == "storm_kit" and voyage_protection > 0:
		quest_progress = min(int(objective.need), 1)
	return not was_complete and quest_can_claim()

func is_trade_unlocked():
	return quest_index >= 7

func equipment_upgrade_level(item_id):
	return int(equipment_upgrades.get(str(item_id), 0))

func equipment_upgrade_cost(slot):
	var item_id = str(equipment.get(str(slot), ""))
	if item_id == "" or not GameData.ITEMS.has(item_id):
		return 0
	var level = equipment_upgrade_level(item_id)
	return 55 + level * 85 + int(round(float(GameData.ITEMS[item_id].get("price", 0)) * (0.18 + float(level) * 0.025)))

func equipment_upgrade_requirements(slot):
	var item_id = str(equipment.get(str(slot), ""))
	if item_id == "" or not GameData.ITEMS.has(item_id):
		return {"target": 0, "silver": 0, "dragon_spring_water": 0, "forging_blueprint": 0}
	var target = equipment_upgrade_level(item_id) + 1
	return {
		"target": target,
		"silver": equipment_upgrade_cost(slot),
		"dragon_spring_water": 0 if target <= 3 else (1 if target <= 7 else 2),
		"forging_blueprint": 1 if target >= 8 else 0
	}

func equipment_upgrade_requirement_text(slot):
	var requirements = equipment_upgrade_requirements(slot)
	if int(requirements.target) <= 0:
		return ""
	var parts = ["%d银" % int(requirements.silver)]
	if int(requirements.dragon_spring_water) > 0:
		parts.append("龙泉水×%d" % int(requirements.dragon_spring_water))
	if int(requirements.forging_blueprint) > 0:
		parts.append("图纸×%d" % int(requirements.forging_blueprint))
	return " + ".join(parts)

func upgrade_equipped(slot):
	var item_id = str(equipment.get(str(slot), ""))
	if item_id == "" or not GameData.ITEMS.has(item_id):
		return {"ok": false, "message": "该部位没有可以强化的装备。"}
	var level = equipment_upgrade_level(item_id)
	if level >= 10:
		return {"ok": false, "message": "%s已经强化至当前上限+10。" % GameData.ITEMS[item_id].name}
	var cost = equipment_upgrade_cost(slot)
	if int(player.silver) < cost:
		return {"ok": false, "message": "强化需要%d银币，可以先通过港口贸易积累资金。" % cost}
	var requirements = equipment_upgrade_requirements(slot)
	var water_need = int(requirements.dragon_spring_water)
	var blueprint_need = int(requirements.forging_blueprint)
	if int(inventory.get("dragon_spring_water", 0)) < water_need:
		return {"ok": false, "message": "强化至+%d还需要龙泉水×%d，可在贝里昂锻造铺购买。" % [level + 1, water_need]}
	if int(inventory.get("forging_blueprint", 0)) < blueprint_need:
		return {"ok": false, "message": "强化至+%d还需要强化图纸×%d，可在贝里昂锻造铺购买。" % [level + 1, blueprint_need]}
	player.silver -= cost
	if water_need > 0:
		_remove_item("dragon_spring_water", water_need)
	if blueprint_need > 0:
		_remove_item("forging_blueprint", blueprint_need)
	equipment_upgrades[item_id] = level + 1
	player.hp = min(int(player.hp), int(get_stats().max_hp))
	var quest_completed = _advance_quest("upgrade_equipment", str(slot))
	message_history.push_front("%s强化至+%d。" % [GameData.ITEMS[item_id].name, level + 1])
	_trim_history()
	save_game()
	return {"ok": true, "message": "%s强化成功：+%d（-%d银币）" % [GameData.ITEMS[item_id].name, level + 1, cost], "level": level + 1, "cost": cost, "quest_completed": quest_completed}

func port_reputation_value(port_id = ""):
	var resolved_port = str(player.location) if str(port_id) == "" else str(port_id)
	return max(0, int(port_reputation.get(resolved_port, 0)))

func total_trade_reputation():
	var total = 0
	for port_id in GameData.TRADE_PORTS:
		total += port_reputation_value(str(port_id))
	return total

func _add_port_reputation(port_id, amount):
	var resolved_port = str(port_id)
	if not GameData.TRADE_PORTS.has(resolved_port) or int(amount) <= 0:
		return false
	port_reputation[resolved_port] = min(30, port_reputation_value(resolved_port) + int(amount))
	return _sync_current_quest_progress()

func current_trade_order(port_id = ""):
	var resolved_port = str(player.location) if str(port_id) == "" else str(port_id)
	if not GameData.TRADE_PORTS.has(resolved_port):
		return {}
	var quest = get_current_quest()
	if not quest.is_empty() and str(quest.objective.type) == "trade_order":
		var story_order_id = str(quest.objective.target)
		var story_order = GameData.TRADE_ORDERS.get(story_order_id, {})
		if not story_order.is_empty() and str(story_order.port) == resolved_port and not bool(completed_trade_orders.get(story_order_id, false)):
			var result = story_order.duplicate(true)
			result.id = story_order_id
			result.story = true
			return result
	var rotation = GameData.PORT_ORDER_ROTATION.get(resolved_port, [])
	if rotation.is_empty():
		return {}
	var cycle = max(0, int(trade_order_cycles.get(resolved_port, 0)))
	var order_id = str(rotation[cycle % rotation.size()])
	var order = GameData.TRADE_ORDERS[order_id].duplicate(true)
	order.id = order_id
	order.story = false
	return order

func trade_order_can_claim(port_id = ""):
	var order = current_trade_order(port_id)
	return not order.is_empty() and str(player.location) == str(order.port) and int(cargo.get(str(order.good), 0)) >= int(order.amount)

func claim_trade_order():
	var order = current_trade_order()
	if order.is_empty():
		return {"ok": false, "message": "当前港口暂时没有可交付的订单。"}
	var good_id = str(order.good)
	var amount = int(order.amount)
	var held = int(cargo.get(good_id, 0))
	if held < amount:
		return {"ok": false, "message": "交付「%s」还需要%s×%d，当前%d。" % [order.title, GameData.TRADE_GOODS[good_id].name, amount, held]}
	var old_cost = int(cargo_costs.get(good_id, 0))
	var removed_cost = int(round(float(old_cost) * float(amount) / float(max(1, held))))
	var market_income = trade_sell_price(good_id) * amount
	var bonus = int(order.bonus)
	var income = market_income + bonus
	var realized_profit = income - removed_cost
	_remove_item_from_cargo(good_id, amount)
	player.silver += income
	trade_profit += income
	trade_lifetime_profit += realized_profit
	trade_volume += amount
	var order_id = str(order.id)
	if bool(order.get("story", false)):
		completed_trade_orders[order_id] = true
	else:
		trade_order_cycles[str(order.port)] = int(trade_order_cycles.get(str(order.port), 0)) + 1
	var quest_completed = _advance_quest("trade_order", order_id)
	quest_completed = _add_port_reputation(str(order.port), int(order.reputation)) or quest_completed
	message_history.push_front("完成%s订单「%s」，获得%d银币并提升%d声望。" % [GameData.TRADE_PORTS[str(order.port)].name, order.title, income, int(order.reputation)])
	_trim_history()
	save_game()
	return {"ok": true, "message": "订单完成：%s\n货款%d + 奖金%d｜实际利润%+d｜声望+%d" % [order.title, market_income, bonus, realized_profit, int(order.reputation)], "income": income, "bonus": bonus, "realized_profit": realized_profit, "reputation": int(order.reputation), "quest_completed": quest_completed}

func buy_voyage_protection():
	if not is_trade_unlocked() or not GameData.TRADE_PORTS.has(player.location):
		return {"ok": false, "message": "只能在港口购买护航物资。"}
	if voyage_protection > 0:
		return {"ok": false, "message": "护航物资已经装船，将在下一次航行中使用。"}
	var cost = 45
	if int(player.silver) < cost:
		return {"ok": false, "message": "购买护航物资需要%d银币。" % cost}
	player.silver -= cost
	trade_profit -= cost
	voyage_protection = 1
	var quest_completed = _advance_quest("prepare_voyage", "storm_kit")
	message_history.push_front("护航物资已装船：下一次航行风险降低并免除一次风暴损失。")
	_trim_history()
	save_game()
	return {"ok": true, "message": "护航物资已装船（-%d银币）\n下一次航行风险-8，并免除一次风暴损失。" % cost, "cost": cost, "quest_completed": quest_completed}

func trade_contract_progress():
	return clamp(max(0, int(trade_profit)), 0, trade_contract_target())

func trade_contract_target():
	return 120 + trade_contract_count * 60

func trade_contract_can_claim():
	return is_trade_unlocked() and trade_contract_progress() >= trade_contract_target()

func claim_trade_contract():
	if not trade_contract_can_claim():
		return {"ok": false, "message": "本轮贸易净利润达到%d银币后才能领取。" % trade_contract_target()}
	var completed_round = trade_contract_count + 1
	var silver_reward = 90 + trade_contract_count * 35
	trade_contract_claimed = true
	player.silver += silver_reward
	_add_item("unknown_equipment", 1)
	trade_contract_count += 1
	trade_profit = 0
	message_history.push_front("完成第%d轮商会委托，获得%d银币和未知道具。" % [completed_round, silver_reward])
	_trim_history()
	save_game()
	return {"ok": true, "message": "第%d轮商会奖励：%d银币、未知道具×1\n新一轮委托已开启。" % [completed_round, silver_reward]}

func best_trade_opportunity():
	var opportunities = trade_route_opportunities(1)
	return {} if opportunities.is_empty() else Dictionary(opportunities[0])

func trade_route_opportunities(limit = 3):
	if not GameData.TRADE_PORTS.has(player.location):
		return []
	var opportunities = []
	var origin = str(player.location)
	var free_space = cargo_space_free()
	for destination in GameData.TRADE_PORTS:
		if str(destination) == origin:
			continue
		if not is_port_unlocked(str(destination)):
			continue
		var route = GameData.trade_route(origin, str(destination))
		if route.is_empty():
			continue
		var days = voyage_days_for_distance(int(route.get("distance_nm", 1)))
		for good_id in GameData.port_stock(origin):
			var good = GameData.TRADE_GOODS[good_id]
			var buy_price = trade_buy_price(good_id)
			var sell_price = trade_sell_price_at(str(destination), str(good_id), trade_day + days)
			var space = max(1, int(good.space))
			var units = min(market_supply_remaining(str(good_id), origin), int(floor(float(free_space) / float(space))))
			units = min(units, int(floor(float(player.silver) / float(max(1, buy_price)))))
			if units <= 0:
				continue
			var sale_total = projected_sale_total_at(str(destination), str(good_id), trade_day + days, units)
			var total_profit = sale_total - buy_price * units
			var occupied_space = units * space
			var plan = voyage_plan(str(destination))
			opportunities.append({
				"good_id": str(good_id), "destination": str(destination), "days": days,
				"units": units, "space": occupied_space, "buy": buy_price, "sell": sell_price,
				"capital": buy_price * units, "sale_total": sale_total, "total_profit": total_profit,
				"profit_per_space": int(floor(float(total_profit) / float(max(1, occupied_space)))),
				"risk": int(plan.get("risk", 0)), "distance_nm": int(route.get("distance_nm", 0))
			})
	opportunities.sort_custom(func(a, b):
		if int(a.profit_per_space) == int(b.profit_per_space):
			return int(a.total_profit) > int(b.total_profit)
		return int(a.profit_per_space) > int(b.profit_per_space)
	)
	if int(limit) > 0 and opportunities.size() > int(limit):
		opportunities.resize(int(limit))
	return opportunities

func cargo_used():
	var used = 0
	for good_id in cargo:
		if GameData.TRADE_GOODS.has(good_id):
			used += int(cargo[good_id]) * int(GameData.TRADE_GOODS[good_id].space)
	return used

func cargo_capacity():
	var hull = current_ship_hull()
	return int(hull.capacity) + int(ship.get("hold_level", 0)) * 6

func cargo_space_free():
	return max(0, cargo_capacity() - cargo_used())

func cargo_load_percent():
	return int(round(float(cargo_used()) * 100.0 / float(max(1, cargo_capacity()))))

func _market_activity_key(port_id, good_id):
	return "%s|%s" % [str(port_id), str(good_id)]

func _market_activity_entry(port_id, good_id):
	var entry = Dictionary(market_activity.get(_market_activity_key(port_id, good_id), {}))
	if int(entry.get("day", 0)) != int(trade_day):
		return {"day": int(trade_day), "bought": 0, "sold": 0}
	return {"day": int(trade_day), "bought": max(0, int(entry.get("bought", 0))), "sold": max(0, int(entry.get("sold", 0)))}

func _record_market_activity(port_id, good_id, kind, amount):
	var entry = _market_activity_entry(port_id, good_id)
	entry[str(kind)] = int(entry.get(str(kind), 0)) + max(0, int(amount))
	market_activity[_market_activity_key(port_id, good_id)] = entry

func _market_daily_variation(port_id, good_id, salt, day_override = -1):
	var resolved_day = int(trade_day) if int(day_override) < 1 else int(day_override)
	var key = "%s:%s:%d:%d" % [str(port_id), str(good_id), resolved_day, int(salt)]
	var seed = 0
	for index in range(key.length()):
		seed = (seed + key.unicode_at(index) * (index + 5)) % 997
	return seed % 5

func market_supply_limit(good_id, port_id = ""):
	var resolved_port = str(player.location) if str(port_id) == "" else str(port_id)
	if not GameData.TRADE_GOODS.has(str(good_id)) or not GameData.port_sells_good(resolved_port, str(good_id)):
		return 0
	var good = GameData.TRADE_GOODS[str(good_id)]
	return int(good.get("supply", 8)) + _market_daily_variation(resolved_port, str(good_id), 17) + int(floor(float(port_reputation_value(resolved_port)) / 5.0))

func market_supply_remaining(good_id, port_id = ""):
	var resolved_port = str(player.location) if str(port_id) == "" else str(port_id)
	return max(0, market_supply_limit(str(good_id), resolved_port) - int(_market_activity_entry(resolved_port, str(good_id)).bought))

func market_demand_limit(good_id, port_id = "", day_override = -1):
	var resolved_port = str(player.location) if str(port_id) == "" else str(port_id)
	if not GameData.TRADE_GOODS.has(str(good_id)) or not GameData.TRADE_PORTS.has(resolved_port):
		return 0
	var good = GameData.TRADE_GOODS[str(good_id)]
	return int(good.get("demand", 8)) + _market_daily_variation(resolved_port, str(good_id), 31, day_override) + int(floor(float(port_reputation_value(resolved_port)) / 6.0))

func market_demand_remaining(good_id, port_id = ""):
	var resolved_port = str(player.location) if str(port_id) == "" else str(port_id)
	return max(0, market_demand_limit(str(good_id), resolved_port) - int(_market_activity_entry(resolved_port, str(good_id)).sold))

func _demand_price_multiplier(sold_before, demand_limit):
	if int(sold_before) < int(demand_limit):
		return 1.0
	if int(sold_before) < int(demand_limit) * 2:
		return 0.88
	return 0.76

func projected_sale_total_at(port_id, good_id, day, amount, sold_before = 0):
	var base_price = trade_sell_price_at(str(port_id), str(good_id), int(day))
	var demand_limit = market_demand_limit(str(good_id), str(port_id), int(day))
	var total = 0
	for index in range(max(0, int(amount))):
		total += max(1, int(floor(float(base_price) * _demand_price_multiplier(int(sold_before) + index, demand_limit))))
	return total

func trade_sale_quote(good_id, amount = 1):
	if not GameData.TRADE_PORTS.has(str(player.location)) or not GameData.TRADE_GOODS.has(str(good_id)):
		return {}
	var actual_amount = min(max(0, int(amount)), int(cargo.get(str(good_id), 0)))
	var sold_before = int(_market_activity_entry(str(player.location), str(good_id)).sold)
	var total = projected_sale_total_at(str(player.location), str(good_id), trade_day, actual_amount, sold_before)
	return {"amount": actual_amount, "total": total, "average": int(floor(float(total) / float(max(1, actual_amount)))), "demand_remaining": market_demand_remaining(str(good_id))}

func current_ship_hull():
	return Dictionary(GameData.SHIP_HULLS.get(str(ship.get("hull_id", "sea_swallow")), GameData.SHIP_HULLS.sea_swallow))

func owned_ship_ids():
	var owned = []
	for hull_id in Array(ship.get("owned_hulls", ["sea_swallow"])):
		var resolved_id = str(hull_id)
		if GameData.SHIP_HULLS.has(resolved_id) and not resolved_id in owned:
			owned.append(resolved_id)
	if not "sea_swallow" in owned:
		owned.push_front("sea_swallow")
	return owned

func owns_ship(hull_id):
	return str(hull_id) in owned_ship_ids()

func ship_role():
	return str(current_ship_hull().get("role", "帆船"))

func ship_armor():
	return int(current_ship_hull().armor) + int(ship.get("armor", 0))

func ship_cannon_power():
	return int(current_ship_hull().get("cannon", 0)) + int(ship.get("cannon_level", 0)) * 4

func ship_trade_bonus():
	return int(current_ship_hull().get("trade_bonus", 0))

func ship_dive_bonus():
	return int(current_ship_hull().get("dive_bonus", 0))

func ship_escape_chance():
	return clamp(0.72 + float(current_ship_hull().get("escape_bonus", 0)) / 100.0, 0.30, 0.92)

func get_battle_stats():
	var stats = get_stats().duplicate(true)
	if not active_battle.is_empty() and bool(active_battle.get("sea_battle", false)):
		stats.attack = int(stats.attack) + ship_cannon_power()
		stats.defense = int(stats.defense) + ship_armor() * 2 + int(current_ship_hull().get("sea_defense", 0))
		stats.speed = int(stats.speed) + int(round(float(ship_speed_profile().knots) * 0.35))
	return stats

func ship_speed_profile():
	return GameData.ship_speed_profile(int(ship.get("speed", 1)), str(ship.get("hull_id", "sea_swallow")))

func voyage_days_for_distance(distance_nm):
	return GameData.voyage_days(distance_nm, int(ship.get("speed", 1)), str(ship.get("hull_id", "sea_swallow")))

func cargo_average_cost(good_id):
	var count = int(cargo.get(good_id, 0))
	if count <= 0:
		return 0
	return int(round(float(cargo_costs.get(good_id, 0)) / float(count)))

func cargo_market_value():
	var value = 0
	for good_id in cargo:
		if GameData.TRADE_GOODS.has(good_id):
			value += trade_sell_price(good_id) * int(cargo[good_id])
	return value

func cargo_unrealized_profit():
	var profit = 0
	for good_id in cargo:
		if GameData.TRADE_GOODS.has(good_id):
			profit += trade_sell_price(good_id) * int(cargo[good_id]) - int(cargo_costs.get(good_id, 0))
	return profit

func max_buyable_cargo(good_id):
	if not GameData.TRADE_GOODS.has(good_id) or not GameData.TRADE_PORTS.has(player.location):
		return 0
	if not GameData.port_sells_good(str(player.location), str(good_id)):
		return 0
	var good = GameData.TRADE_GOODS[good_id]
	var by_space = int(floor(float(cargo_capacity() - cargo_used()) / float(good.space)))
	var price = trade_buy_price(good_id)
	var by_silver = int(floor(float(player.silver) / float(max(1, price))))
	var by_supply = market_supply_remaining(str(good_id))
	return max(0, min(by_space, min(by_silver, by_supply)))

func trade_buy_price(good_id):
	return trade_buy_price_at(str(player.location), good_id, trade_day)

func trade_sell_price(good_id):
	var base_price = trade_sell_price_at(str(player.location), good_id, trade_day)
	if not GameData.TRADE_PORTS.has(str(player.location)) or not GameData.TRADE_GOODS.has(str(good_id)):
		return base_price
	var activity = _market_activity_entry(str(player.location), str(good_id))
	return max(1, int(floor(float(base_price) * _demand_price_multiplier(int(activity.sold), market_demand_limit(str(good_id))))))

func trade_buy_price_at(port_id, good_id, day):
	var market_price = GameData.trade_market_price(str(port_id), str(good_id), int(day))
	var discount = min(0.10, float(port_reputation_value(str(port_id))) * 0.005)
	return max(1, int(round(float(market_price) * (1.0 - discount))))

func trade_sell_price_at(port_id, good_id, day):
	var market_price = GameData.trade_market_price(str(port_id), str(good_id), int(day))
	var sell_rate = 0.90 + min(0.05, float(port_reputation_value(str(port_id))) * 0.0025)
	var is_export_sale = str(GameData.TRADE_GOODS.get(str(good_id), {}).get("origin", "")) != str(port_id)
	var hull_bonus = float(ship_trade_bonus()) / 100.0 if is_export_sale else 0.0
	return max(1, int(floor(float(market_price) * (sell_rate + hull_bonus))))

func buy_cargo(good_id, amount = 1):
	if not is_trade_unlocked():
		return {"ok": false, "message": "完成威尼斯四层试炼后才会获得贸易船。"}
	if not GameData.TRADE_PORTS.has(player.location) or not GameData.TRADE_GOODS.has(good_id):
		return {"ok": false, "message": "这里不能购买这种货物。"}
	if not GameData.port_sells_good(str(player.location), str(good_id)):
		var origin_id = str(GameData.TRADE_GOODS[good_id].get("origin", ""))
		var origin_name = str(GameData.TRADE_PORTS.get(origin_id, {"name": "其他港口"}).name)
		return {"ok": false, "message": "%s不出售%s，请前往%s采购。" % [GameData.TRADE_PORTS[player.location].name, GameData.TRADE_GOODS[good_id].name, origin_name]}
	var good = GameData.TRADE_GOODS[good_id]
	var price = trade_buy_price(good_id)
	var actual_amount = min(max(1, int(amount)), max_buyable_cargo(good_id))
	if actual_amount <= 0:
		return {"ok": false, "message": "银币或货舱空间不足，无法继续买入。"}
	var total = price * actual_amount
	player.silver -= total
	cargo[good_id] = int(cargo.get(good_id, 0)) + actual_amount
	cargo_costs[good_id] = int(cargo_costs.get(good_id, 0)) + total
	trade_profit -= total
	trade_volume += actual_amount
	_record_market_activity(str(player.location), str(good_id), "bought", actual_amount)
	var quest_completed = _advance_quest("trade_buy", str(good_id), actual_amount)
	message_history.push_front("在%s买入%d%s%s。" % [GameData.TRADE_PORTS[player.location].name, actual_amount, good.unit, good.name])
	_trim_history()
	save_game()
	return {"ok": true, "message": "买入%s×%d，支出%d银币" % [good.name, actual_amount, total], "price": price, "amount": actual_amount, "total": total, "quest_completed": quest_completed}

func sell_cargo(good_id, amount = 1):
	if not is_trade_unlocked() or not GameData.TRADE_PORTS.has(player.location):
		return {"ok": false, "message": "当前不在可交易港口。"}
	if int(cargo.get(good_id, 0)) <= 0 or not GameData.TRADE_GOODS.has(good_id):
		return {"ok": false, "message": "货舱中没有这种货物。"}
	var good = GameData.TRADE_GOODS[good_id]
	var current_quest = get_current_quest()
	var required_sale_port = ""
	if not current_quest.is_empty() and str(current_quest.objective.type) == "trade_sell" and str(current_quest.objective.target) == str(good_id):
		required_sale_port = str(current_quest.objective.get("location", ""))
	var wrong_quest_port = required_sale_port != "" and str(player.location) != required_sale_port
	var old_count = int(cargo[good_id])
	var actual_amount = min(max(1, int(amount)), old_count)
	var sale_quote = trade_sale_quote(str(good_id), actual_amount)
	var price = int(sale_quote.get("average", trade_sell_price(good_id)))
	var total = int(sale_quote.get("total", price * actual_amount))
	var old_cost = int(cargo_costs.get(good_id, 0))
	var removed_cost = int(round(float(old_cost) * float(actual_amount) / float(old_count)))
	var realized_profit = total - removed_cost
	player.silver += total
	trade_profit += total
	trade_lifetime_profit += realized_profit
	var quest_completed = _advance_quest("trade_sell", str(good_id), actual_amount)
	var left = old_count - actual_amount
	if left <= 0:
		cargo.erase(good_id)
		cargo_costs.erase(good_id)
	else:
		cargo[good_id] = left
		cargo_costs[good_id] = max(0, old_cost - removed_cost)
	trade_volume += actual_amount
	_record_market_activity(str(player.location), str(good_id), "sold", actual_amount)
	if realized_profit > 0:
		quest_completed = _add_port_reputation(str(player.location), max(1, int(floor(float(actual_amount) / 3.0)))) or quest_completed
	message_history.push_front("在%s卖出%d%s%s。" % [GameData.TRADE_PORTS[player.location].name, actual_amount, good.unit, good.name])
	_trim_history()
	save_game()
	var demand_after = market_demand_remaining(str(good_id))
	var sale_message = "卖出%s×%d，收入%d银币（均价%d）｜实际盈亏%+d\n本港高价需求剩余%d%s；继续抛售会压低收购价。" % [good.name, actual_amount, total, price, realized_profit, demand_after, good.unit]
	if wrong_quest_port:
		sale_message += "\n主线要求在%s出售，本次交易不计入任务进度。" % GameData.TRADE_PORTS[required_sale_port].name
	return {"ok": true, "message": sale_message, "price": price, "amount": actual_amount, "total": total, "realized_profit": realized_profit, "quest_completed": quest_completed, "wrong_quest_port": wrong_quest_port}

func buy_max_cargo(good_id):
	return buy_cargo(good_id, max_buyable_cargo(good_id))

func sell_all_cargo(good_id):
	return sell_cargo(good_id, int(cargo.get(good_id, 0)))

func available_recipes(port_id = ""):
	var resolved_port = str(player.location) if str(port_id) == "" else str(port_id)
	var recipes = []
	for recipe_id in GameData.RECIPES:
		var recipe = GameData.RECIPES[recipe_id]
		if str(recipe.port) == resolved_port:
			var entry = recipe.duplicate(true)
			entry.id = str(recipe_id)
			recipes.append(entry)
	return recipes

func cook_provision(recipe_id):
	if not GameData.RECIPES.has(recipe_id):
		return {"ok": false, "message": "这份食谱尚未学会。"}
	var recipe = GameData.RECIPES[recipe_id]
	if str(player.location) != str(recipe.port):
		return {"ok": false, "message": "这份餐食只能在%s厨房烹制。" % GameData.TRADE_PORTS[str(recipe.port)].name}
	for good_id in recipe.cargo:
		var need = int(recipe.cargo[good_id])
		var held = int(cargo.get(good_id, 0))
		if held < need:
			return {"ok": false, "message": "还缺少%s×%d，货舱现有%d。" % [GameData.TRADE_GOODS[good_id].name, need - held, held]}
	var fee = int(recipe.get("silver", 0))
	if int(player.silver) < fee:
		return {"ok": false, "message": "还需要%d银币支付厨房费用。" % fee}
	for good_id in recipe.cargo:
		_remove_item_from_cargo(str(good_id), int(recipe.cargo[good_id]))
	player.silver -= fee
	trade_profit -= fee
	_add_item(str(recipe.result), 1)
	var quest_completed = _advance_quest("cook", str(recipe_id))
	message_history.push_front("在马耳他厨房烹制了%s。" % recipe.name)
	_trim_history()
	save_game()
	return {"ok": true, "message": "烹制完成：%s×1\n%s" % [recipe.name, recipe.description], "item": str(recipe.result), "quest_completed": quest_completed}

func voyage_risk(port_id):
	var route = GameData.trade_route(str(player.location), str(port_id))
	if route.is_empty():
		return 0
	return _voyage_risk_for_route(route)

func _voyage_risk_for_route(route):
	var card_risk_bonus = 4 if active_card == "corsair_card" else 0
	var protection_bonus = 8 if voyage_protection > 0 else 0
	var difficulty_risk = 6 if difficulty == DIFFICULTY_ADVENTURE else 0
	return clamp(int(route.get("risk", 15)) + difficulty_risk - ship_armor() * 6 - card_risk_bonus - protection_bonus, 4, 60)

func voyage_plan(port_id, origin_override = ""):
	var origin = str(origin_override) if str(origin_override) != "" else str(player.location)
	var destination = str(port_id)
	var route = GameData.trade_route(origin, destination)
	if route.is_empty():
		return {}
	var distance_nm = max(1, int(route.get("distance_nm", int(route.get("days", 1)) * 420)))
	var tier_id = GameData.sea_voyage_tier(distance_nm)
	var tier = GameData.SEA_VOYAGE_TIERS[tier_id]
	var speed_profile = ship_speed_profile()
	var days = voyage_days_for_distance(distance_nm)
	# 原版正常出航会消耗体力；按航程分段收费，避免远洋和近海只差一张地图。
	var stamina_cost = max(3, int(ceil(float(distance_nm) / 900.0)) + 1)
	var dive_tier_bonus = {"coastal": 0, "regional": 10, "oceanic": 20}.get(tier_id, 0)
	var dive_chance = clamp(35 + int(dive_tier_bonus) + ship_dive_bonus() + int(round(float(get_stats().drop_bonus) * 100.0)), 35, 85)
	var risk = _voyage_risk_for_route(route)
	var threat_count = 4
	if distance_nm > int(GameData.SEA_VOYAGE_TIERS.coastal.max_distance_nm):
		threat_count = 7
	if tier_id == "oceanic":
		threat_count = 9
	if distance_nm >= 4800:
		threat_count = 12
	if threat_count >= 7 and (ship_armor() >= 3 or voyage_protection > 0):
		threat_count -= 1
	var zone_ids = Array(route.get("zone_ids", GameData.sea_zones_for_route(origin, destination)))
	var enemy_plan = _voyage_enemy_roster(zone_ids, tier_id, threat_count)
	var enemy_ids = Array(enemy_plan.enemy_ids)
	var enemy_levels = Array(enemy_plan.enemy_levels)
	var recommended_level = 1
	for enemy_level in enemy_levels:
		recommended_level = max(recommended_level, int(enemy_level))
	return {
		"origin": origin, "destination": destination,
		"distance_nm": distance_nm, "tier": tier_id, "tier_name": str(tier.name),
		"days": days, "ship_level": int(ship.get("speed", 1)),
		"speed_knots": float(speed_profile.knots), "nm_per_day": int(speed_profile.nm_per_day),
		"world_speed": float(speed_profile.world_speed),
		"stamina_cost": stamina_cost, "dive_chance": dive_chance,
		"risk": risk, "threat_count": enemy_ids.size(), "enemy_ids": enemy_ids, "enemy_levels": enemy_levels,
		"enemy_zones": Array(enemy_plan.enemy_zones), "zone_ids": zone_ids,
		"waters_text": str(route.get("waters_text", GameData.sea_waters_text(zone_ids))),
		"waters_level_text": GameData.sea_level_band_text(zone_ids),
		"recommended_level": recommended_level, "description": str(tier.description)
	}

func _voyage_enemy_roster(zone_ids, tier_id, threat_count):
	var candidates = []
	var candidate_zones = {}
	for zone_id in Array(zone_ids):
		for enemy_id in Array(GameData.SEA_ZONE_ENEMIES.get(str(zone_id), [])):
			var resolved_enemy = str(enemy_id)
			if not resolved_enemy in candidates:
				candidates.append(resolved_enemy)
				candidate_zones[resolved_enemy] = str(zone_id)
	if not "coastal_pirate" in candidates:
		candidates.append("coastal_pirate")
		candidate_zones["coastal_pirate"] = str(Array(zone_ids).front()) if not Array(zone_ids).is_empty() else "mediterranean"
	var level_cap = int(player.level) + 8
	if tier_id == "coastal":
		level_cap = min(level_cap, 12)
	elif tier_id == "regional":
		level_cap = max(12, min(level_cap, 29))
	else:
		level_cap = max(36, level_cap)
	level_cap = max(5, level_cap)
	var eligible = []
	for enemy_id in candidates:
		var enemy_level = int(GameData.ENEMIES[str(enemy_id)].level)
		if enemy_level <= level_cap and (str(enemy_id) != "black_flag_privateer" or int(player.level) >= 45):
			eligible.append(str(enemy_id))
	var target_level = min(max(1, int(player.level)), level_cap)
	eligible.sort_custom(func(a, b):
		var level_a = int(GameData.ENEMIES[str(a)].level)
		var level_b = int(GameData.ENEMIES[str(b)].level)
		var delta_a = abs(level_a - target_level)
		var delta_b = abs(level_b - target_level)
		return level_a > level_b if delta_a == delta_b else delta_a < delta_b
	)
	var desired_count = int(threat_count)
	var enemy_ids = []
	var enemy_zones = []
	var route_boss = GameData.sea_set_boss_for_route(zone_ids, int(player.level))
	if desired_count > 0 and not route_boss.is_empty() and str(route_boss.enemy_id) in eligible:
		enemy_ids.append(str(route_boss.enemy_id))
		candidate_zones[str(route_boss.enemy_id)] = str(route_boss.zone_id)
	if desired_count > 0 and not Array(zone_ids).is_empty():
		var origin_signatures = Array(GameData.SEA_ZONE_SIGNATURE_ENEMIES.get(str(Array(zone_ids).front()), []))
		for enemy_id in eligible:
			if str(enemy_id) in origin_signatures:
				enemy_ids.append(str(enemy_id))
				break
	if desired_count >= 2:
		var strongest_enemy = ""
		var strongest_level = -1
		for enemy_id in eligible:
			var enemy_level = int(GameData.ENEMIES[str(enemy_id)].level)
			if not str(enemy_id) in enemy_ids and enemy_level > strongest_level:
				strongest_enemy = str(enemy_id)
				strongest_level = enemy_level
		if strongest_enemy != "":
			enemy_ids.append(strongest_enemy)
	if desired_count >= 3 and not Array(zone_ids).is_empty():
		var destination_signatures = Array(GameData.SEA_ZONE_SIGNATURE_ENEMIES.get(str(Array(zone_ids).back()), []))
		for enemy_id in eligible:
			if str(enemy_id) in destination_signatures and not str(enemy_id) in enemy_ids:
				enemy_ids.append(str(enemy_id))
				break
	for enemy_id in eligible:
		if enemy_ids.size() >= desired_count:
			break
		if not str(enemy_id) in enemy_ids:
			enemy_ids.append(str(enemy_id))
	var repeat_cursor = 0
	while enemy_ids.size() < desired_count and not eligible.is_empty():
		enemy_ids.append(str(eligible[repeat_cursor % eligible.size()]))
		repeat_cursor += 1
	for enemy_id in enemy_ids:
		enemy_zones.append(str(candidate_zones.get(str(enemy_id), "mediterranean")))
	var enemy_levels = []
	for index in range(enemy_ids.size()):
		enemy_levels.append(sea_encounter_level(str(enemy_ids[index]), str(enemy_zones[index])))
	return {"enemy_ids": enemy_ids, "enemy_zones": enemy_zones, "enemy_levels": enemy_levels}

func _build_sea_encounters(plan):
	var encounters = []
	var enemy_ids = Array(plan.get("enemy_ids", []))
	var enemy_zones = Array(plan.get("enemy_zones", []))
	var enemy_levels = Array(plan.get("enemy_levels", []))
	var zone_ids = Array(plan.get("zone_ids", []))
	var lateral_offsets = [-260.0, 230.0, -150.0, 310.0, -330.0, 120.0, 360.0, -210.0, 180.0, -390.0, 285.0, -95.0]
	var origin_position = GameData.sea_port_position(str(plan.origin))
	var destination_position = GameData.sea_port_position(str(plan.destination))
	var direction = destination_position - origin_position
	var perpendicular = Vector2(-direction.y, direction.x).normalized()
	var spawned_set_bosses = {}
	for index in range(enemy_ids.size()):
		var enemy_id = str(enemy_ids[index])
		var zone_id = str(enemy_zones[index]) if index < enemy_zones.size() else "mediterranean"
		var threat_level = int(enemy_levels[index]) if index < enemy_levels.size() else sea_encounter_level(enemy_id, zone_id)
		var progress = (float(index) + 1.0) / float(enemy_ids.size() + 1)
		var lateral = lateral_offsets[index % lateral_offsets.size()]
		var position = origin_position.lerp(destination_position, progress) + perpendicular * lateral
		position.x = clamp(position.x, 120.0, GameData.SEA_GLOBAL_WORLD_SIZE.x - 120.0)
		position.y = clamp(position.y, 120.0, GameData.SEA_GLOBAL_WORLD_SIZE.y - 120.0)
		var boss = GameData.sea_set_boss(zone_id, enemy_id)
		var is_set_boss = not boss.is_empty() and int(player.level) >= int(boss.unlock_level) and not spawned_set_bosses.has(zone_id)
		if is_set_boss:
			spawned_set_bosses[zone_id] = true
			threat_level = max(threat_level, int(boss.unlock_level))
		var loot_name = str(GameData.sea_equipment_tier(threat_level).name)
		if is_set_boss:
			loot_name = "%s整套 · %d%%" % [str(GameData.EQUIPMENT_SETS[str(boss.set_id)].name), int(round(float(boss.drop_rate) * 100.0))]
		encounters.append({
			"id": "sea_%d" % (index + 1), "enemy_id": enemy_id,
			"kind": "pirate" if enemy_id in ["coastal_pirate", "ocean_raider", "black_flag_privateer"] else "monster",
			"zone_id": zone_id, "threat_level": threat_level,
			"loot_tier_name": loot_name, "set_boss": is_set_boss, "set_id": str(boss.get("set_id", "")) if is_set_boss else "", "progress": progress,
			"x": position.x, "y": position.y, "defeated": false
		})
	return encounters

func _voyage_layout(plan):
	var distance_nm = int(plan.distance_nm)
	var origin = GameData.sea_port_position(str(plan.origin))
	var destination = GameData.sea_port_position(str(plan.destination))
	var direction = destination - origin
	var perpendicular = Vector2(-direction.y, direction.x).normalized()
	var treasure = origin.lerp(destination, 0.36) - perpendicular * 260.0
	var storm = origin.lerp(destination, 0.64) + perpendicular * 270.0
	return {
		"world_width": GameData.SEA_GLOBAL_WORLD_SIZE.x, "world_height": GameData.SEA_GLOBAL_WORLD_SIZE.y,
		"route_span": origin.distance_to(destination),
		"origin_x": origin.x, "origin_y": origin.y,
		"destination_x": destination.x, "destination_y": destination.y,
		"treasure_x": treasure.x, "treasure_y": treasure.y,
		"storm_x": storm.x, "storm_y": storm.y, "storm_radius": 132.0
	}

func begin_voyage(port_id):
	var destination = str(port_id)
	if not is_trade_unlocked():
		return {"ok": false, "message": "航海尚未解锁。"}
	if not active_voyage.is_empty():
		return {"ok": false, "message": "海燕号已经在航行中。"}
	if not GameData.TRADE_PORTS.has(str(player.location)) or not GameData.TRADE_PORTS.has(destination):
		return {"ok": false, "message": "必须从真实港口出航。"}
	if destination == str(player.location):
		return {"ok": false, "message": "海燕号已经停泊在这里。"}
	if not is_port_unlocked(destination):
		return {"ok": false, "message": "该港口尚未从主线海图中解锁。"}
	var plan = voyage_plan(destination)
	if plan.is_empty():
		return {"ok": false, "message": "无法计算两座港口之间的航海距离。"}
	if int(player.hp) <= int(plan.stamina_cost):
		return {"ok": false, "message": "本航程需要%d体力，当前只有%d。请先在酒馆休息或使用补给，至少保留1点体力再出航。" % [int(plan.stamina_cost), int(player.hp)]}
	var escorted = voyage_protection > 0
	player.hp -= int(plan.stamina_cost)
	var layout = _voyage_layout(plan)
	var unlocked_ports = []
	for map_port_id in GameData.TRADE_PORTS:
		if is_port_unlocked(str(map_port_id)):
			unlocked_ports.append(str(map_port_id))
	active_voyage = {
		"origin": str(player.location), "destination": destination,
		"region": GameData.sea_region_for_route(str(player.location), destination),
		"days": int(plan.days), "risk": int(plan.risk),
		"distance_nm": int(plan.distance_nm), "tier": str(plan.tier), "tier_name": str(plan.tier_name),
		"zone_ids": Array(plan.zone_ids), "waters_text": str(plan.waters_text), "waters_level_text": str(plan.waters_level_text),
		"sea_balance_version": GameData.SEA_BALANCE_VERSION,
		"unlocked_ports": unlocked_ports,
		"recommended_level": int(plan.recommended_level),
		"stamina_cost": int(plan.stamina_cost), "dive_chance": int(plan.dive_chance),
		"ship_level": int(plan.ship_level), "speed_knots": float(plan.speed_knots),
		"nm_per_day": int(plan.nm_per_day), "world_speed": float(plan.world_speed),
		"world_width": float(layout.world_width), "world_height": float(layout.world_height),
		"route_span": float(layout.route_span),
		"origin_x": float(layout.origin_x), "origin_y": float(layout.origin_y),
		"destination_x": float(layout.destination_x), "destination_y": float(layout.destination_y),
		"treasure_x": float(layout.treasure_x), "treasure_y": float(layout.treasure_y),
		"storm_x": float(layout.storm_x), "storm_y": float(layout.storm_y), "storm_radius": float(layout.storm_radius),
		"x": float(layout.origin_x), "y": float(layout.origin_y), "pirate_defeated": false,
		"treasure_claimed": false, "storm_resolved": false,
		"encounters": _build_sea_encounters(plan), "current_encounter_id": "",
		"escorted": escorted
	}
	if escorted:
		voyage_protection = 0
	message_history.push_front("%s从%s正常出航，消耗%d体力，航经%s：%d海里，预计%d日。" % [str(ship.name), GameData.TRADE_PORTS[str(player.location)].name, int(plan.stamina_cost), str(active_voyage.waters_text), int(active_voyage.distance_nm), int(active_voyage.days)])
	_trim_history()
	save_game()
	return {"ok": true, "message": "自由航线已启航：消耗%d体力，航经%s，%s，共%d海里，侦测到%d处威胁。驾驶%s抵达%s。" % [int(plan.stamina_cost), str(plan.waters_text), str(plan.tier_name), int(plan.distance_nm), int(plan.threat_count), str(ship.name), GameData.TRADE_PORTS[destination].name], "voyage": active_voyage.duplicate(true)}

func update_voyage_position(position, persist = false):
	if active_voyage.is_empty():
		return
	var point = Vector2(position)
	active_voyage.x = float(point.x)
	active_voyage.y = float(point.y)
	if persist:
		save_game()

func update_sea_encounter_position(encounter_id, position):
	if active_voyage.is_empty():
		return
	var point = Vector2(position)
	var encounters = Array(active_voyage.get("encounters", []))
	for index in range(encounters.size()):
		var encounter = Dictionary(encounters[index])
		if str(encounter.get("id", "")) == str(encounter_id):
			encounter.x = point.x
			encounter.y = point.y
			encounters[index] = encounter
			active_voyage.encounters = encounters
			return

func voyage_position():
	if active_voyage.is_empty():
		return Vector2.ZERO
	return Vector2(float(active_voyage.get("x", 540.0)), float(active_voyage.get("y", active_voyage.get("origin_y", LEGACY_VOYAGE_ORIGIN_Y))))

func voyage_progress():
	if active_voyage.is_empty():
		return 0.0
	var origin = Vector2(float(active_voyage.get("origin_x", 540.0)), float(active_voyage.get("origin_y", LEGACY_VOYAGE_ORIGIN_Y)))
	var destination = Vector2(float(active_voyage.get("destination_x", 540.0)), float(active_voyage.get("destination_y", LEGACY_VOYAGE_DESTINATION_Y)))
	var route_vector = destination - origin
	if route_vector.length_squared() < 1.0:
		return 0.0
	return clamp((voyage_position() - origin).dot(route_vector) / route_vector.length_squared(), 0.0, 1.0)

func voyage_remaining_distance():
	if active_voyage.is_empty():
		return 0
	return int(round(float(active_voyage.get("distance_nm", 0)) * (1.0 - voyage_progress())))

func sea_encounters_remaining():
	if active_voyage.is_empty():
		return 0
	var remaining = 0
	for encounter in Array(active_voyage.get("encounters", [])):
		if not bool(encounter.get("defeated", false)):
			remaining += 1
	return remaining

func sea_encounter(encounter_id):
	for encounter in Array(active_voyage.get("encounters", [])):
		if str(encounter.get("id", "")) == str(encounter_id):
			return Dictionary(encounter)
	return {}

func sea_enemy_id():
	if active_voyage.is_empty():
		return ""
	for encounter in Array(active_voyage.get("encounters", [])):
		if not bool(encounter.get("defeated", false)):
			return str(encounter.get("enemy_id", "coastal_pirate"))
	return ""

func start_sea_encounter(encounter_id):
	if active_voyage.is_empty():
		return {"ok": false, "message": "当前不在航行中。"}
	var encounter = sea_encounter(encounter_id)
	if encounter.is_empty() or bool(encounter.get("defeated", false)):
		return {"ok": false, "message": "这处海上威胁已经消失。"}
	active_voyage.current_encounter_id = str(encounter_id)
	return start_battle(str(encounter.enemy_id))

func mark_sea_encounter_defeated(encounter_id = ""):
	if active_voyage.is_empty():
		return
	var resolved_id = str(encounter_id) if str(encounter_id) != "" else str(active_voyage.get("current_encounter_id", ""))
	var encounters = Array(active_voyage.get("encounters", []))
	for index in range(encounters.size()):
		var encounter = Dictionary(encounters[index])
		if str(encounter.get("id", "")) == resolved_id or (resolved_id == "" and not bool(encounter.get("defeated", false))):
			encounter.defeated = true
			encounters[index] = encounter
			break
	active_voyage.encounters = encounters
	active_voyage.current_encounter_id = ""
	active_voyage.pirate_defeated = sea_encounters_remaining() == 0
	save_game()

func mark_sea_pirate_defeated():
	mark_sea_encounter_defeated()

func claim_sea_treasure(mode = "salvage"):
	if active_voyage.is_empty():
		return {"ok": false, "message": "这里没有正在进行的航程。"}
	if bool(active_voyage.get("treasure_claimed", false)):
		return {"ok": false, "message": "漂流货箱已经打捞过了。"}
	var resolved_mode = "dive" if str(mode) == "dive" else "salvage"
	var silver = 18 + int(active_voyage.get("days", 1)) * 5 + int(active_voyage.get("distance_nm", 0)) / 240
	active_voyage.treasure_claimed = true
	if resolved_mode == "dive":
		var chance = int(active_voyage.get("dive_chance", 35))
		var found = rng.randi_range(1, 100) <= chance
		if found:
			var tier_id = str(active_voyage.get("tier", "coastal"))
			var pools = {
				"coastal": ["coral_ring", "universal_medicine"],
				"regional": ["aquamarine_pendant", "corsair_card"],
				"oceanic": ["corsair_card", "unknown_equipment"]
			}
			var pool = Array(pools.get(tier_id, pools.coastal))
			var item_id = str(pool[rng.randi_range(0, pool.size() - 1)])
			_add_item(item_id, 1)
			message_history.push_front("航途中潜水寻宝，找到%s。" % GameData.ITEMS[item_id].name)
			_trim_history()
			save_game()
			return {"ok": true, "mode": resolved_mode, "found": true, "item": item_id, "message": "潜入旧货箱下方的沉船舱，找到%s×1。" % GameData.ITEMS[item_id].name}
		silver = max(6, int(silver / 3))
		player.silver += silver
		message_history.push_front("航途中潜水寻宝未发现遗物，回收%d银币。" % silver)
		_trim_history()
		save_game()
		return {"ok": true, "mode": resolved_mode, "found": false, "silver": silver, "message": "沉船舱已经被潮水冲空，只回收了%d银币。" % silver}
	player.silver += silver
	message_history.push_front("航途中稳妥打捞漂流货箱，获得%d银币。" % silver)
	_trim_history()
	save_game()
	return {"ok": true, "mode": resolved_mode, "message": "水手从漂流货箱里找到%d银币。" % silver, "silver": silver}

func resolve_sea_storm():
	if active_voyage.is_empty():
		return {"ok": false, "message": "这里没有正在进行的航程。"}
	if bool(active_voyage.get("storm_resolved", false)):
		return {"ok": false, "message": "这片风暴已经穿过。"}
	active_voyage.storm_resolved = true
	if bool(active_voyage.get("escorted", false)):
		active_voyage.escorted = false
		save_game()
		return {"ok": true, "message": "风暴袭来，本航程的护航物资固定住桅杆和货舱，没有损失。", "protected": true}
	var cargo_ids = cargo.keys()
	cargo_ids.sort()
	if not cargo_ids.is_empty():
		var lost_id = str(cargo_ids[0])
		var lost_count = 2 if str(active_voyage.get("tier", "coastal")) == "oceanic" else 1
		lost_count = min(lost_count, int(cargo.get(lost_id, 0)))
		_remove_item_from_cargo(lost_id, lost_count)
		save_game()
		return {"ok": true, "message": "巨浪打进货舱，损失%d%s%s。" % [lost_count, GameData.TRADE_GOODS[lost_id].unit, GameData.TRADE_GOODS[lost_id].name], "protected": false, "lost_count": lost_count}
	var repair_cost = min(int(player.silver), 12 + int(active_voyage.get("risk", 15)))
	player.silver -= repair_cost
	trade_profit -= repair_cost
	save_game()
	return {"ok": true, "message": "船体被巨浪擦伤，靠岸前需要预留%d银币修理。" % repair_cost, "protected": false}

func complete_voyage(port_id = ""):
	if active_voyage.is_empty():
		return {"ok": false, "message": "没有可以结算的航程。"}
	var voyage = active_voyage.duplicate(true)
	var destination = str(port_id) if str(port_id) != "" else str(voyage.destination)
	var origin = str(voyage.origin)
	if not GameData.TRADE_PORTS.has(destination) or destination == origin:
		return {"ok": false, "message": "请选择启航港以外的港口靠岸。"}
	var actual_route = GameData.trade_route(origin, destination)
	if actual_route.is_empty():
		return {"ok": false, "message": "无法结算这座港口的航程。"}
	var actual_distance = int(actual_route.distance_nm)
	var actual_days = voyage_days_for_distance(actual_distance)
	trade_day += actual_days
	player.location = destination
	active_voyage = {}
	var quest_completed = _advance_quest("visit", destination)
	message_history.push_front("%s从%s航行%d日，抵达%s。" % [str(ship.name), GameData.TRADE_PORTS[origin].name, actual_days, GameData.TRADE_PORTS[destination].name])
	_trim_history()
	save_game()
	var diversion_text = "\n已在大地图中改靠新港。" if destination != str(voyage.destination) else ""
	return {"ok": true, "message": "抵达%s · 完成%d海里航程 · 用时%d日%s\n海盗、海怪、风暴和打捞均已在海域中即时结算。" % [GameData.TRADE_PORTS[destination].name, actual_distance, actual_days, diversion_text], "days": actual_days, "distance_nm": actual_distance, "from": origin, "destination": destination, "quest_completed": quest_completed}

func abort_voyage():
	if active_voyage.is_empty():
		return {"ok": false, "message": "当前没有航程。"}
	var origin = str(active_voyage.origin)
	active_voyage = {}
	player.location = origin
	save_game()
	return {"ok": true, "origin": origin, "message": "%s返航至%s。" % [str(ship.name), GameData.TRADE_PORTS[origin].name]}

func transfer_to(port_id):
	var destination = str(port_id)
	if not is_trade_unlocked() or not GameData.TRADE_PORTS.has(str(player.location)) or not GameData.TRADE_PORTS.has(destination):
		return {"ok": false, "message": "现在无法使用港口传送。"}
	if not is_port_unlocked(destination):
		return {"ok": false, "message": "该港口尚未发现。"}
	var route = GameData.trade_route(str(player.location), destination)
	if route.is_empty():
		return {"ok": false, "message": "无法计算两座港口之间的传送距离。"}
	var fee = int(route.fee)
	if int(player.silver) < fee:
		return {"ok": false, "message": "还需要%d银币支付传送费。" % (fee - int(player.silver))}
	var origin = str(player.location)
	player.silver -= fee
	trade_profit -= fee
	trade_day += 1
	player.location = destination
	var quest_completed = _advance_quest("visit", destination)
	message_history.push_front("支付%d银币，从%s传送至%s。" % [fee, GameData.TRADE_PORTS[origin].name, GameData.TRADE_PORTS[destination].name])
	_trim_history()
	save_game()
	return {"ok": true, "message": "已传送至%s · 费用%d银币 · 用时1日\n传送不会触发海上战斗与打捞。" % [GameData.TRADE_PORTS[destination].name, fee], "fee": fee, "days": 1, "from": origin, "destination": destination, "quest_completed": quest_completed}

func is_port_unlocked(port_id):
	var resolved_port = str(port_id)
	if not GameData.TRADE_PORTS.has(resolved_port):
		return false
	if str(player.location) == resolved_port:
		return true
	return quest_index >= int(GameData.PORT_UNLOCK_QUEST.get(resolved_port, 0))

func sail_to(port_id):
	if not is_trade_unlocked():
		return {"ok": false, "message": "贸易航线尚未解锁。"}
	if not GameData.TRADE_PORTS.has(player.location) or not GameData.TRADE_PORTS.has(port_id):
		return {"ok": false, "message": "航线目的地不存在。"}
	if not is_port_unlocked(port_id):
		return {"ok": false, "message": "该港口尚未从主线海图中解锁。继续推进章节即可发现这条航路。"}
	var route = GameData.trade_route(player.location, port_id)
	if route.is_empty():
		return {"ok": false, "message": "无法计算两座港口之间的航海距离。"}
	var fee = int(route.fee)
	if int(player.silver) < fee:
		return {"ok": false, "message": "至少需要%d银币支付航费。" % fee}
	var from_name = GameData.TRADE_PORTS[player.location].name
	var from_port = str(player.location)
	var days = voyage_days_for_distance(int(route.get("distance_nm", 1)))
	player.silver -= fee
	trade_profit -= fee
	trade_day += days
	player.location = port_id
	var quest_completed = _advance_quest("visit", str(port_id))
	var protected_voyage = voyage_protection > 0
	var risk = max(4, int(route.get("risk", 15)) - ship_armor() * 6 - (4 if active_card == "corsair_card" else 0) - (8 if protected_voyage else 0))
	if protected_voyage:
		voyage_protection = 0
	var event_message = "航程平安。"
	var event_roll = rng.randi_range(1, 100)
	if event_roll <= risk:
		if protected_voyage:
			event_message = "遭遇风暴，护航物资稳住货舱，未受损失。"
		else:
			var cargo_ids = cargo.keys()
			cargo_ids.sort()
			if not cargo_ids.is_empty():
				var lost_id = str(cargo_ids[rng.randi_range(0, cargo_ids.size() - 1)])
				_remove_item_from_cargo(lost_id, 1)
				event_message = "遭遇风暴，损失1%s%s。" % [GameData.TRADE_GOODS[lost_id].unit, GameData.TRADE_GOODS[lost_id].name]
			else:
				var repair_cost = min(int(player.silver), 8 + risk)
				player.silver -= repair_cost
				trade_profit -= repair_cost
				event_message = "遭遇风暴，支付%d银币修理船体。" % repair_cost
	elif event_roll >= 88:
		var discovery = 18 + days * 4
		player.silver += discovery
		trade_profit += discovery
		event_message = "途中发现漂流货箱，获得%d银币。" % discovery
	message_history.push_front("海燕号从%s航行%d日，抵达%s。%s" % [from_name, days, GameData.TRADE_PORTS[port_id].name, event_message])
	_trim_history()
	save_game()
	return {"ok": true, "message": "抵达%s · 航费%d · 用时%d日\n%s" % [GameData.TRADE_PORTS[port_id].name, fee, days, event_message], "days": days, "fee": fee, "risk": risk, "event": event_message, "from": from_port, "protected": protected_voyage, "quest_completed": quest_completed}

func _remove_item_from_cargo(good_id, count):
	var old_count = int(cargo.get(good_id, 0))
	var removed = min(old_count, int(count))
	var old_cost = int(cargo_costs.get(good_id, 0))
	var removed_cost = int(round(float(old_cost) * float(removed) / float(max(1, old_count))))
	var left = old_count - removed
	if left <= 0:
		cargo.erase(good_id)
		cargo_costs.erase(good_id)
	else:
		cargo[good_id] = left
		cargo_costs[good_id] = max(0, old_cost - removed_cost)

func upgrade_ship(kind):
	if not is_trade_unlocked():
		return {"ok": false, "message": "贸易船尚未解锁。"}
	var cost = 0
	var message = ""
	if kind == "hold":
		if int(ship.get("hold_level", 0)) >= 3:
			return {"ok": false, "message": "货舱隔板已强化到最高。"}
		cost = 180 + int(ship.get("hold_level", 0)) * 140
		message = "货舱隔板提升至Lv.%d，容量达到%d格" % [int(ship.get("hold_level", 0)) + 1, cargo_capacity() + 6]
	elif kind == "speed":
		if int(ship.get("speed", 1)) >= 4:
			return {"ok": false, "message": "船帆速度已升到最高。"}
		cost = 220 + (int(ship.get("speed", 1)) - 1) * 100
		var next_level = int(ship.get("speed", 1)) + 1
		var next_profile = GameData.ship_speed_profile(next_level, str(ship.get("hull_id", "sea_swallow")))
		message = "船帆提升至Lv.%d · %.1f节（%d海里/日）" % [next_level, float(next_profile.knots), int(next_profile.nm_per_day)]
	elif kind == "armor":
		if int(ship.get("armor", 0)) >= 3:
			return {"ok": false, "message": "船体护甲已升到最高。"}
		cost = 240 + int(ship.get("armor", 0)) * 130
		message = "船体护甲提升至%d级，航行风险降低" % (int(ship.get("armor", 0)) + 1)
	elif kind == "cannon":
		if int(ship.get("cannon_level", 0)) >= 3:
			return {"ok": false, "message": "舰炮已经强化到最高。"}
		cost = 260 + int(ship.get("cannon_level", 0)) * 160
		message = "舰炮提升至Lv.%d，海战攻击达到%d" % [int(ship.get("cannon_level", 0)) + 1, ship_cannon_power() + 4]
	else:
		return {"ok": false, "message": "未知的船只改造。"}
	if int(player.silver) < cost:
		return {"ok": false, "message": "改造需要%d银币。" % cost}
	player.silver -= cost
	if kind == "hold":
		ship.hold_level = int(ship.get("hold_level", 0)) + 1
		ship.capacity = cargo_capacity()
	elif kind == "speed":
		ship.speed = int(ship.get("speed", 1)) + 1
	elif kind == "armor":
		ship.armor = int(ship.get("armor", 0)) + 1
	else:
		ship.cannon_level = int(ship.get("cannon_level", 0)) + 1
	var quest_completed = _advance_quest("upgrade_ship", str(kind))
	message_history.push_front("%s完成改造：%s。" % [str(ship.name), message])
	_trim_history()
	save_game()
	return {"ok": true, "message": "%s（-%d银币）" % [message, cost], "cost": cost, "quest_completed": quest_completed}

func buy_ship(hull_id):
	var resolved_id = str(hull_id)
	if not is_trade_unlocked() or not GameData.TRADE_PORTS.has(str(player.location)):
		return {"ok": false, "message": "只能在港口船行购买船只。"}
	if not GameData.SHIP_HULLS.has(resolved_id):
		return {"ok": false, "message": "这艘船不存在。"}
	var offered_id = str(GameData.TRADE_PORTS[str(player.location)].get("ship_offer", ""))
	if offered_id != resolved_id:
		return {"ok": false, "message": "本港船老板不出售这艘船。"}
	if str(ship.get("hull_id", "sea_swallow")) == resolved_id:
		return {"ok": false, "message": "这正是你当前使用的船。"}
	if owns_ship(resolved_id):
		return switch_ship(resolved_id)
	var hull = Dictionary(GameData.SHIP_HULLS[resolved_id])
	var new_capacity = int(hull.capacity) + int(ship.get("hold_level", 0)) * 6
	if cargo_used() > new_capacity:
		return {"ok": false, "message": "新船只能装%d格，请先卖出%d格货物。" % [new_capacity, cargo_used() - new_capacity]}
	var price = int(hull.price)
	if int(player.silver) < price:
		return {"ok": false, "message": "购买%s还差%d银币。" % [str(hull.name), price - int(player.silver)]}
	player.silver -= price
	var owned = owned_ship_ids()
	owned.append(resolved_id)
	ship.owned_hulls = owned
	ship.hull_id = resolved_id
	ship.name = str(hull.name)
	ship.capacity = cargo_capacity()
	message_history.push_front("在%s船行购入%s。" % [GameData.TRADE_PORTS[str(player.location)].name, str(hull.name)])
	_trim_history()
	save_game()
	return {"ok": true, "message": "已购入并启用%s（-%d银币）\n%s｜基础%.1f节 · 货舱%d格 · 船甲%d · 舰炮%d｜船装已转装，旧船保留在船队。" % [str(hull.name), price, str(hull.role), float(hull.base_knots), cargo_capacity(), ship_armor(), ship_cannon_power()], "cost": price, "purchased": true}

func switch_ship(hull_id):
	var resolved_id = str(hull_id)
	if not is_trade_unlocked() or not GameData.TRADE_PORTS.has(str(player.location)) or not active_voyage.is_empty():
		return {"ok": false, "message": "只能靠港后在船坞换乘船只。"}
	if not GameData.SHIP_HULLS.has(resolved_id) or not owns_ship(resolved_id):
		return {"ok": false, "message": "这艘船尚未加入你的船队。"}
	if str(ship.get("hull_id", "sea_swallow")) == resolved_id:
		return {"ok": false, "message": "这正是你当前使用的船。"}
	var hull = Dictionary(GameData.SHIP_HULLS[resolved_id])
	var new_capacity = int(hull.capacity) + int(ship.get("hold_level", 0)) * 6
	if cargo_used() > new_capacity:
		return {"ok": false, "message": "%s只能装%d格，请先卖出%d格货物。" % [str(hull.name), new_capacity, cargo_used() - new_capacity]}
	ship.hull_id = resolved_id
	ship.name = str(hull.name)
	ship.capacity = cargo_capacity()
	message_history.push_front("在%s船坞换乘%s。" % [GameData.TRADE_PORTS[str(player.location)].name, str(hull.name)])
	_trim_history()
	save_game()
	return {"ok": true, "message": "已换乘%s｜%s\n%.1f节 · 货舱%d格 · 船甲%d · 舰炮%d" % [str(hull.name), str(hull.role), float(ship_speed_profile().knots), cargo_capacity(), ship_armor(), ship_cannon_power()], "switched": true}

func _add_item(item_id, count):
	inventory[item_id] = int(inventory.get(item_id, 0)) + count

func _remove_item(item_id, count):
	var left = int(inventory.get(item_id, 0)) - count
	if left <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = left

func _trim_history():
	if message_history.size() > 8:
		message_history.resize(8)

func _normalize_active_voyage():
	if active_voyage.is_empty():
		return
	var origin = str(active_voyage.get("origin", ""))
	var destination = str(active_voyage.get("destination", ""))
	var plan = voyage_plan(destination, origin)
	if plan.is_empty():
		active_voyage = {}
		return
	if not active_voyage.has("distance_nm"):
		active_voyage.distance_nm = int(plan.distance_nm)
	if not active_voyage.has("tier"):
		active_voyage.tier = str(plan.tier)
	if not active_voyage.has("tier_name"):
		active_voyage.tier_name = str(plan.tier_name)
	if not active_voyage.has("zone_ids"):
		active_voyage.zone_ids = Array(plan.zone_ids)
	if not active_voyage.has("waters_text"):
		active_voyage.waters_text = str(plan.waters_text)
	active_voyage.waters_level_text = str(plan.waters_level_text)
	active_voyage.recommended_level = int(plan.recommended_level)
	if not active_voyage.has("stamina_cost"):
		active_voyage.stamina_cost = int(plan.stamina_cost)
	if not active_voyage.has("dive_chance"):
		active_voyage.dive_chance = int(plan.dive_chance)
	if not active_voyage.has("unlocked_ports"):
		var migrated_ports = []
		for port_id in GameData.TRADE_PORTS:
			if is_port_unlocked(str(port_id)):
				migrated_ports.append(str(port_id))
		active_voyage.unlocked_ports = migrated_ports
	var had_dynamic_layout = active_voyage.has("world_width") and is_equal_approx(float(active_voyage.get("world_width", 0.0)), GameData.SEA_GLOBAL_WORLD_SIZE.x) and is_equal_approx(float(active_voyage.get("world_height", 0.0)), GameData.SEA_GLOBAL_WORLD_SIZE.y)
	var legacy_progress = clamp((LEGACY_VOYAGE_ORIGIN_Y - float(active_voyage.get("y", LEGACY_VOYAGE_ORIGIN_Y))) / (LEGACY_VOYAGE_ORIGIN_Y - LEGACY_VOYAGE_DESTINATION_Y), 0.0, 1.0)
	var old_origin = Vector2(float(active_voyage.get("origin_x", 0.0)), float(active_voyage.get("origin_y", 0.0)))
	var old_destination = Vector2(float(active_voyage.get("destination_x", 0.0)), float(active_voyage.get("destination_y", 0.0)))
	var old_route = old_destination - old_origin
	if old_route.length_squared() >= 1.0:
		var old_position = Vector2(float(active_voyage.get("x", old_origin.x)), float(active_voyage.get("y", old_origin.y)))
		legacy_progress = clamp((old_position - old_origin).dot(old_route) / old_route.length_squared(), 0.0, 1.0)
	var layout = _voyage_layout(plan)
	for layout_key in layout:
		active_voyage[layout_key] = layout[layout_key]
	active_voyage.ship_level = int(plan.ship_level)
	active_voyage.speed_knots = float(plan.speed_knots)
	active_voyage.nm_per_day = int(plan.nm_per_day)
	active_voyage.world_speed = float(plan.world_speed)
	active_voyage.days = int(plan.days)
	if not had_dynamic_layout:
		var migrated_position = GameData.sea_port_position(origin).lerp(GameData.sea_port_position(destination), legacy_progress)
		active_voyage.x = migrated_position.x
		active_voyage.y = migrated_position.y
	var saved_encounters = active_voyage.get("encounters", [])
	var needs_balance_migration = int(active_voyage.get("sea_balance_version", 0)) < GameData.SEA_BALANCE_VERSION
	var needs_encounter_migration = not had_dynamic_layout or typeof(saved_encounters) != TYPE_ARRAY or Array(saved_encounters).is_empty()
	if not needs_encounter_migration:
		for saved_encounter in Array(saved_encounters):
			if not Dictionary(saved_encounter).has("progress"):
				needs_encounter_migration = true
				break
	if needs_encounter_migration:
		var defeated_ids = []
		var legacy_encounters = Array(saved_encounters) if typeof(saved_encounters) == TYPE_ARRAY else []
		for old_encounter in legacy_encounters:
			if bool(Dictionary(old_encounter).get("defeated", false)):
				defeated_ids.append(str(Dictionary(old_encounter).get("id", "")))
		active_voyage.encounters = _build_sea_encounters(plan)
		if bool(active_voyage.get("pirate_defeated", false)) or not defeated_ids.is_empty():
			var cleared = []
			for encounter in Array(active_voyage.encounters):
				var migrated = Dictionary(encounter)
				migrated.defeated = bool(active_voyage.get("pirate_defeated", false)) or str(migrated.id) in defeated_ids
				cleared.append(migrated)
			active_voyage.encounters = cleared
	else:
		var normalized_encounters = []
		for saved_encounter in Array(saved_encounters):
			var normalized = Dictionary(saved_encounter)
			var zone_id = str(normalized.get("zone_id", "mediterranean"))
			var enemy_id = str(normalized.get("enemy_id", "coastal_pirate"))
			if needs_balance_migration or not normalized.has("threat_level"):
				normalized.threat_level = sea_encounter_level(enemy_id, zone_id)
			if needs_balance_migration or not normalized.has("loot_tier_name"):
				normalized.loot_tier_name = str(GameData.sea_equipment_tier(int(normalized.threat_level)).name)
			normalized_encounters.append(normalized)
		active_voyage.encounters = normalized_encounters
	active_voyage.sea_balance_version = GameData.SEA_BALANCE_VERSION
	if not active_voyage.has("current_encounter_id"):
		active_voyage.current_encounter_id = ""
	if not active_voyage.has("escorted"):
		active_voyage.escorted = voyage_protection > 0
		if bool(active_voyage.escorted):
			voyage_protection = 0

func save_game():
	var payload = {
		"save_version": SAVE_VERSION, "player": player, "inventory": inventory, "equipment": equipment,
		"quest_index": quest_index, "quest_progress": quest_progress, "defeated": defeated,
		"message_history": message_history, "active_battle": active_battle, "statuses": statuses,
		"party_members": party_members, "companion_unlocked": companion_unlocked, "pet": pet,
		"dungeon_cleared": dungeon_cleared, "cargo": cargo, "cargo_costs": cargo_costs, "ship": ship,
		"trade_day": trade_day, "trade_profit": trade_profit, "trade_volume": trade_volume,
		"trade_lifetime_profit": trade_lifetime_profit, "market_activity": market_activity, "port_reputation": port_reputation,
		"trade_order_cycles": trade_order_cycles, "completed_trade_orders": completed_trade_orders,
		"voyage_protection": voyage_protection, "active_voyage": active_voyage,
		"battle_stance": battle_stance, "auto_heal_threshold": auto_heal_threshold, "auto_cure_status": auto_cure_status,
		"equipment_upgrades": equipment_upgrades, "trade_contract_claimed": trade_contract_claimed,
		"trade_contract_count": trade_contract_count, "active_card": active_card, "discoveries": discoveries,
		"bounty_index": bounty_index, "bounty_progress": bounty_progress, "bounty_cycles": bounty_cycles,
		"enemy_respawns": enemy_respawns, "meal_buff_battles": meal_buff_battles
		,"difficulty": difficulty
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))

func has_save():
	return FileAccess.file_exists(SAVE_PATH)

func load_game():
	if not has_save():
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	if int(parsed.get("save_version", 1)) < SAVE_VERSION:
		var old_player = parsed.get("player", {})
		var old_level = int(old_player.get("level", 1))
		var old_silver = int(old_player.get("silver", 72))
		new_game()
		player.level = clamp(old_level, 1, 5)
		player.silver = max(72, old_silver)
		player.hp = get_stats().max_hp
		message_history = ["旧版存档已迁移：保留等级和银币，从原版开局重新启程。"]
		save_game()
		return true
	player = parsed.get("player", player)
	if not player.has("title"):
		player.title = "海边苏醒者"
	inventory = parsed.get("inventory", inventory)
	equipment = parsed.get("equipment", equipment)
	for slot in GameData.SLOT_NAMES:
		if not equipment.has(slot):
			equipment[slot] = ""
	quest_index = int(parsed.get("quest_index", 0))
	quest_progress = int(parsed.get("quest_progress", 0))
	defeated = parsed.get("defeated", {})
	message_history = parsed.get("message_history", [])
	active_battle = parsed.get("active_battle", {})
	statuses = parsed.get("statuses", {})
	party_members = parsed.get("party_members", [])
	companion_unlocked = bool(parsed.get("companion_unlocked", false))
	pet = parsed.get("pet", {})
	dungeon_cleared = parsed.get("dungeon_cleared", {})
	cargo = parsed.get("cargo", {})
	cargo_costs = parsed.get("cargo_costs", {})
	if typeof(cargo_costs) != TYPE_DICTIONARY:
		cargo_costs = {}
	ship = parsed.get("ship", {"name": "海燕号", "hull_id": "sea_swallow", "owned_hulls": ["sea_swallow"], "capacity": 12, "speed": 1, "hold_level": 0, "armor": 0, "cannon_level": 0})
	trade_day = max(1, int(parsed.get("trade_day", 1)))
	trade_profit = int(parsed.get("trade_profit", 0))
	trade_volume = max(0, int(parsed.get("trade_volume", 0)))
	trade_lifetime_profit = int(parsed.get("trade_lifetime_profit", 0))
	market_activity = parsed.get("market_activity", {})
	if typeof(market_activity) != TYPE_DICTIONARY:
		market_activity = {}
	port_reputation = parsed.get("port_reputation", {"venice_dock": 0, "ragusa_dock": 0, "alexandria_dock": 0})
	if typeof(port_reputation) != TYPE_DICTIONARY:
		port_reputation = {}
	trade_order_cycles = parsed.get("trade_order_cycles", {"venice_dock": 0, "ragusa_dock": 0, "alexandria_dock": 0})
	if typeof(trade_order_cycles) != TYPE_DICTIONARY:
		trade_order_cycles = {}
	completed_trade_orders = parsed.get("completed_trade_orders", {})
	if typeof(completed_trade_orders) != TYPE_DICTIONARY:
		completed_trade_orders = {}
	voyage_protection = clamp(int(parsed.get("voyage_protection", 0)), 0, 1)
	active_voyage = parsed.get("active_voyage", {})
	if typeof(active_voyage) != TYPE_DICTIONARY:
		active_voyage = {}
	elif not active_voyage.is_empty():
		var saved_origin = str(active_voyage.get("origin", ""))
		var saved_destination = str(active_voyage.get("destination", ""))
		if not GameData.TRADE_PORTS.has(saved_origin) or not GameData.TRADE_PORTS.has(saved_destination) or GameData.trade_route(saved_origin, saved_destination).is_empty():
			active_voyage = {}
		else:
			player.location = saved_origin
			_normalize_active_voyage()
	meal_buff_battles = clamp(int(parsed.get("meal_buff_battles", 0)), 0, 3)
	difficulty = str(parsed.get("difficulty", DIFFICULTY_NORMAL))
	if not difficulty in DIFFICULTY_NAMES:
		difficulty = DIFFICULTY_NORMAL
	for trade_port_id in GameData.TRADE_PORTS:
		port_reputation[str(trade_port_id)] = clamp(int(port_reputation.get(str(trade_port_id), 0)), 0, 30)
		trade_order_cycles[str(trade_port_id)] = max(0, int(trade_order_cycles.get(str(trade_port_id), 0)))
	battle_stance = str(parsed.get("battle_stance", "balanced"))
	if not battle_stance in ["assault", "balanced", "guard", "plunder"]:
		battle_stance = "balanced"
	auto_heal_threshold = int(parsed.get("auto_heal_threshold", 35))
	if not auto_heal_threshold in [0, 35, 55]:
		auto_heal_threshold = 35
	auto_cure_status = bool(parsed.get("auto_cure_status", true))
	equipment_upgrades = parsed.get("equipment_upgrades", {})
	trade_contract_claimed = bool(parsed.get("trade_contract_claimed", false))
	trade_contract_count = max(0, int(parsed.get("trade_contract_count", 1 if trade_contract_claimed else 0)))
	active_card = str(parsed.get("active_card", ""))
	discoveries = parsed.get("discoveries", {})
	bounty_index = clamp(int(parsed.get("bounty_index", 0)), 0, max(0, GameData.BOUNTIES.size() - 1))
	bounty_progress = max(0, int(parsed.get("bounty_progress", 0)))
	bounty_cycles = max(0, int(parsed.get("bounty_cycles", 0)))
	enemy_respawns = parsed.get("enemy_respawns", {})
	if typeof(enemy_respawns) != TYPE_DICTIONARY:
		enemy_respawns = {}
	else:
		for respawn_key in enemy_respawns.keys():
			var deadline_type = typeof(enemy_respawns[respawn_key])
			if not deadline_type in [TYPE_FLOAT, TYPE_INT] or float(enemy_respawns[respawn_key]) <= 0.0:
				enemy_respawns.erase(respawn_key)
	if active_card != "" and (not GameData.ITEMS.has(active_card) or int(inventory.get(active_card, 0)) <= 0):
		active_card = ""
	if not ship.has("name"):
		ship.name = "海燕号"
	if not ship.has("hull_id") or not GameData.SHIP_HULLS.has(str(ship.get("hull_id", ""))):
		ship.hull_id = "sea_swallow"
	var migrated_owned_hulls = []
	for owned_hull_id in Array(ship.get("owned_hulls", ["sea_swallow", str(ship.hull_id)])):
		var resolved_owned_id = str(owned_hull_id)
		if GameData.SHIP_HULLS.has(resolved_owned_id) and not resolved_owned_id in migrated_owned_hulls:
			migrated_owned_hulls.append(resolved_owned_id)
	if not "sea_swallow" in migrated_owned_hulls:
		migrated_owned_hulls.push_front("sea_swallow")
	if not str(ship.hull_id) in migrated_owned_hulls:
		migrated_owned_hulls.append(str(ship.hull_id))
	ship.owned_hulls = migrated_owned_hulls
	if not ship.has("hold_level"):
		ship.hold_level = clamp(int(round(float(max(0, int(ship.get("capacity", 12)) - 12)) / 6.0)), 0, 3)
	ship.hold_level = clamp(int(ship.get("hold_level", 0)), 0, 3)
	ship.speed = clamp(int(ship.get("speed", 1)), 1, 4)
	ship.armor = clamp(int(ship.get("armor", 0)), 0, 3)
	ship.cannon_level = clamp(int(ship.get("cannon_level", 0)), 0, 3)
	ship.name = str(current_ship_hull().name)
	ship.capacity = cargo_capacity()
	for good_id in cargo.keys():
		if not GameData.TRADE_GOODS.has(good_id) or int(cargo[good_id]) <= 0:
			cargo.erase(good_id)
			cargo_costs.erase(good_id)
		elif not cargo_costs.has(good_id):
			cargo_costs[good_id] = trade_buy_price(good_id) * int(cargo[good_id])
	if not GameData.LOCATIONS.has(player.get("location", "")):
		player.location = "alisa_hut"
		active_battle = {}
	if not active_battle.is_empty() and not GameData.ENEMIES.has(active_battle.get("enemy_id", "")):
		active_battle = {}
	elif not active_battle.is_empty() and not active_battle.has("sea_battle"):
		active_battle.sea_battle = not active_voyage.is_empty() and bool(GameData.ENEMIES[str(active_battle.enemy_id)].get("sea_enemy", false))
	if not active_battle.is_empty() and bool(active_battle.get("sea_battle", false)) and (not active_battle.has("enemy_profile") or int(active_battle.get("sea_balance_version", 0)) < GameData.SEA_BALANCE_VERSION):
		var migrated_encounter = sea_encounter(str(active_voyage.get("current_encounter_id", "")))
		var migrated_zone_id = str(migrated_encounter.get("zone_id", "mediterranean"))
		var migrated_level = int(migrated_encounter.get("threat_level", sea_encounter_level(str(active_battle.enemy_id), migrated_zone_id)))
		var old_max_hp = max(1, int(active_battle.get("enemy_max_hp", GameData.ENEMIES[str(active_battle.enemy_id)].hp)))
		var old_hp_ratio = clamp(float(active_battle.get("enemy_hp", old_max_hp)) / float(old_max_hp), 0.0, 1.0)
		active_battle.enemy_profile = _scaled_sea_enemy_profile(str(active_battle.enemy_id), migrated_level)
		active_battle.enemy_max_hp = difficulty_enemy_hp(int(active_battle.enemy_profile.hp))
		active_battle.enemy_hp = max(1, int(round(float(active_battle.enemy_max_hp) * old_hp_ratio)))
		active_battle.sea_zone_id = migrated_zone_id
		active_battle.sea_zone_name = str(GameData.SEA_REGIONS.get(migrated_zone_id, {}).get("name", ""))
		active_battle.loot_tier_name = str(GameData.sea_equipment_tier(migrated_level).name)
		active_battle.sea_balance_version = GameData.SEA_BALANCE_VERSION
	if int(player.level) >= GameData.MAX_LEVEL:
		player.level = GameData.MAX_LEVEL
		player.xp = 0
	quest_index = clamp(quest_index, 0, GameData.QUESTS.size())
	_sync_current_quest_progress()
	player.hp = clamp(int(player.hp), 1, int(get_stats().max_hp))
	return true
