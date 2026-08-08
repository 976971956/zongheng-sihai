class_name GameState
extends RefCounted

const SAVE_VERSION = 2
const SAVE_PATH = "user://tides_save.json"

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
var ship = {}
var trade_day = 1
var trade_profit = 0
var trade_volume = 0
var battle_stance = "balanced"
var auto_heal_threshold = 35
var auto_cure_status = true
var equipment_upgrades = {}
var trade_contract_claimed = false

func _init():
	rng.randomize()
	new_game()

func new_game():
	player = {
		"name": "失忆的航者", "level": 1, "xp": 0, "hp": 94,
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
	ship = {"name": "海燕号", "capacity": 12, "speed": 1, "armor": 0}
	trade_day = 1
	trade_profit = 0
	trade_volume = 0
	battle_stance = "balanced"
	auto_heal_threshold = 35
	auto_cure_status = true
	equipment_upgrades = {}
	trade_contract_claimed = false
	message_history = ["你从海边小屋醒来，已经不记得自己的名字。"]
	player.hp = get_stats().max_hp

func get_stats():
	var level = int(player.level)
	var stats = {
		"max_hp": 94 + (level - 1) * 18,
		"attack": 10 + (level - 1) * 3,
		"defense": 4 + (level - 1) * 2,
		"speed": 6 + (level - 1),
		"drop_bonus": 0.0
	}
	var warrior_count = 0
	for slot in equipment:
		var item_id = equipment[slot]
		if item_id == "" or not GameData.ITEMS.has(item_id):
			continue
		var item = GameData.ITEMS[item_id]
		if item.get("set", "") == "warrior":
			warrior_count += 1
		stats.drop_bonus += float(item.get("drop_bonus", 0.0))
		for key in item.get("stats", {}):
			stats[key] = stats.get(key, 0) + int(item.stats[key])
		var upgrade_level = int(equipment_upgrades.get(item_id, 0))
		if upgrade_level > 0:
			for key in item.get("stats", {}):
				var base_value = int(item.stats[key])
				var bonus_rate = 0.10 if key == "max_hp" else 0.14
				stats[key] = stats.get(key, 0) + max(1, int(round(float(base_value) * bonus_rate))) * upgrade_level

	# The original early Warrior set was desirable mainly for item-find.
	if warrior_count >= 2:
		stats.drop_bonus += 0.08
	if warrior_count >= 4:
		stats.drop_bonus += 0.12

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
	return str(location_id).begins_with("training_dungeon_") or str(location_id).begins_with("black_sail_")

func talk_to(npc_id):
	var location = GameData.LOCATIONS[player.location]
	if not npc_id in location.npcs or not GameData.NPCS.has(npc_id):
		return {"ok": false, "message": "对方不在这里。"}
	var npc = GameData.NPCS[npc_id]
	var quest_completed = _advance_quest("talk", npc_id)
	message_history.push_front("与%s交谈。" % npc.name)
	_trim_history()
	save_game()
	return {"ok": true, "message": npc.dialogue, "npc_name": npc.name, "quest_completed": quest_completed}

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
	if int(item.get("heal", 0)) > 0 and before < int(stats.max_hp):
		player.hp = min(int(stats.max_hp), before + int(item.heal))
		healed = int(player.hp) - before
	if bool(item.get("cure_status", false)) and not statuses.is_empty():
		statuses = {}
		cured = true
	if healed == 0 and not cured:
		return {"ok": false, "message": "现在不需要使用%s。" % item.name}
	_remove_item(item_id, 1)
	var details = []
	if healed > 0:
		details.append("恢复%d点体力" % healed)
	if cured:
		details.append("解除所有不良状态")
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

func start_battle(enemy_id):
	if not GameData.ENEMIES.has(enemy_id):
		return {"ok": false, "message": "敌人不存在。"}
	var location = GameData.LOCATIONS[player.location]
	if not enemy_id in location.enemies:
		return {"ok": false, "message": "这个敌人不在当前区域。"}
	if not active_battle.is_empty():
		if active_battle.enemy_id == enemy_id:
			return get_battle_view()
		return {"ok": false, "message": "你正在与其他敌人战斗。"}
	var enemy = GameData.ENEMIES[enemy_id]
	active_battle = {
		"enemy_id": enemy_id, "enemy_hp": int(enemy.hp), "enemy_max_hp": int(enemy.hp),
		"round": 1, "log": [enemy.intro]
	}
	player.battles += 1
	save_game()
	var view = get_battle_view()
	view.logs = [enemy.intro]
	return view

func get_battle_view():
	if active_battle.is_empty():
		return {"ok": false, "message": "当前没有战斗。"}
	var enemy = GameData.ENEMIES[active_battle.enemy_id]
	return {
		"ok": true, "battle_over": false, "won": false,
		"enemy_id": active_battle.enemy_id, "enemy_name": enemy.name, "enemy_rank": enemy.rank, "enemy_level": int(enemy.level),
		"enemy_hp": int(active_battle.enemy_hp), "enemy_max_hp": int(active_battle.enemy_max_hp),
		"player_level": int(player.level), "player_hp": int(player.hp), "player_max_hp": int(get_stats().max_hp),
		"round": int(active_battle.round), "statuses": statuses.duplicate(), "logs": [],
		"battle_stance": battle_stance, "enemy_intent": get_enemy_intent(),
		"auto_heal_threshold": auto_heal_threshold, "auto_cure_status": auto_cure_status
	}

func set_battle_stance(value):
	if not str(value) in ["assault", "balanced", "guard", "plunder"]:
		return {"ok": false, "message": "未知的战斗姿态。"}
	battle_stance = str(value)
	save_game()
	return {"ok": true, "message": "战斗姿态已调整。"}

func get_enemy_intent():
	if active_battle.is_empty():
		return ""
	var enemy = GameData.ENEMIES.get(str(active_battle.enemy_id), {})
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
	var enemy = GameData.ENEMIES[enemy_id]
	var stats = get_stats()
	var logs = []
	var player_attack = int(stats.attack)
	var player_speed = int(stats.speed)
	match battle_stance:
		"assault": player_attack = max(1, int(round(float(player_attack) * 1.18)))
		"guard": player_attack = max(1, int(round(float(player_attack) * 0.86)))
		"plunder": player_attack = max(1, int(round(float(player_attack) * 0.92)))
	if statuses.has("虚弱"):
		player_attack = max(1, int(round(player_attack * 0.75)))
	if statuses.has("缓慢"):
		player_speed = max(1, int(round(player_speed * 0.70)))
	var player_first = player_speed >= int(enemy.speed)
	var round_number = int(active_battle.round)

	if player_first:
		_player_strike(enemy, player_attack, round_number, logs)
		if int(active_battle.enemy_hp) > 0:
			_pet_strike(enemy, round_number, logs)
		if int(active_battle.enemy_hp) > 0:
			_enemy_strike(enemy, stats, round_number, logs)
	else:
		_enemy_strike(enemy, stats, round_number, logs)
		if int(player.hp) > 0:
			_player_strike(enemy, player_attack, round_number, logs)
			if int(active_battle.enemy_hp) > 0:
				_pet_strike(enemy, round_number, logs)

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
		last_result = attack_once()
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
	if rng.randf() <= 0.72:
		active_battle = {}
		statuses = {}
		save_game()
		return {"ok": true, "battle_over": true, "won": false, "fled": true, "enemy_name": enemy.name, "enemy_rank": enemy.rank, "logs": ["你抓住空隙撤出了战斗。"]}
	var result = attack_once()
	result.logs.push_front("撤退失败，%s追了上来！" % enemy.name)
	return result

func _player_strike(enemy, player_attack, round_number, logs):
	var result = _roll_attack(player_attack, enemy.defense, int(player.level), int(enemy.level))
	active_battle.enemy_hp = max(0, int(active_battle.enemy_hp) - int(result.damage))
	if result.miss:
		logs.append("第%d回合｜你的攻击被%s避开。" % [round_number, enemy.name])
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

func _enemy_strike(enemy, stats, round_number, logs):
	var effective_defense = int(stats.defense)
	if battle_stance == "assault":
		effective_defense = max(0, int(round(float(effective_defense) * 0.90)))
	elif battle_stance == "guard":
		effective_defense = int(round(float(effective_defense) * 1.28))
	if statuses.has("诅咒"):
		effective_defense = max(0, int(round(effective_defense * 0.80)))
	var enemy_attack = int(enemy.attack)
	var special = enemy.get("special", {})
	var special_every = int(special.get("every", 0))
	var uses_special = special_every > 0 and round_number % special_every == 0
	if uses_special:
		enemy_attack = int(round(float(enemy_attack) * float(special.get("damage_multiplier", 1.0))))
	var result = _roll_attack(enemy_attack, effective_defense, int(enemy.level), int(player.level))
	player.hp = max(0, int(player.hp) - int(result.damage))
	if result.miss:
		logs.append("第%d回合｜你避开了%s的攻击。" % [round_number, enemy.name])
	elif uses_special:
		logs.append("第%d回合｜%s施放%s，你的体力-%d！" % [round_number, enemy.name, str(special.get("name", "强力攻击")), result.damage])
	elif result.crit:
		logs.append("第%d回合｜%s发动猛击，你的体力-%d！" % [round_number, enemy.name, result.damage])
	else:
		logs.append("第%d回合｜%s向你发起攻击，体力-%d。" % [round_number, enemy.name, result.damage])
	if int(result.damage) > 0 and enemy.has("effect") and rng.randf() <= float(enemy.effect.chance):
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
	var enemy = GameData.ENEMIES[enemy_id]
	var finishing_stance = battle_stance
	player.victories += 1
	player.hp = max(1, int(player.hp))
	var silver = rng.randi_range(int(enemy.silver[0]), int(enemy.silver[1]))
	player.silver += silver
	var leveled = _add_xp(int(enemy.exp))
	defeated[enemy_id] = int(defeated.get(enemy_id, 0)) + 1
	if enemy_id in ["dungeon_guard", "stone_puppet", "tide_beast", "vermilion_phantom", "corsair_deckhand", "corsair_raider", "corsair_guard", "corsair_captain"]:
		dungeon_cleared[enemy_id] = true
	var quest_completed = _advance_quest("kill", enemy_id)
	var drop_id = ""
	var stats = get_stats()
	var stance_drop_bonus = 0.14 if finishing_stance == "plunder" else 0.0
	var drop_chance = 1.0 if enemy.rank in ["首领", "副本 Boss"] else min(0.90, 0.22 + float(stats.drop_bonus) + stance_drop_bonus)
	if rng.randf() <= drop_chance and enemy.drops.size() > 0:
		drop_id = enemy.drops[rng.randi_range(0, enemy.drops.size() - 1)]
		_add_item(drop_id, 1)
	round_logs.append("战斗胜利！获得%d经验、%d银币。" % [int(enemy.exp), silver])
	if drop_id != "":
		round_logs.append("百宝箱拾取：%s。" % GameData.ITEMS[drop_id].name)
	message_history.push_front("击败%s，获得%d经验。" % [enemy.name, int(enemy.exp)])
	_trim_history()
	active_battle = {}
	statuses = {}
	save_game()
	return {
		"ok": true, "battle_over": true, "won": true, "fled": false,
		"enemy_id": enemy_id, "enemy_name": enemy.name, "enemy_rank": enemy.rank, "enemy_level": int(enemy.level),
		"enemy_hp": 0, "enemy_max_hp": int(enemy.hp), "player_level": int(player.level), "player_hp": int(player.hp), "player_max_hp": int(get_stats().max_hp),
		"round": 0, "statuses": {}, "logs": round_logs,
		"exp": int(enemy.exp), "silver": silver, "drop": drop_id, "leveled": leveled, "new_level": int(player.level),
		"quest_completed": quest_completed, "battle_stance": finishing_stance
	}

func _finish_battle_loss(enemy_id, round_logs):
	var enemy = GameData.ENEMIES[enemy_id]
	var remaining_enemy_hp = int(active_battle.get("enemy_hp", enemy.hp))
	var defeated_player_hp = int(player.hp)
	player.hp = max(1, int(get_stats().max_hp * 0.35))
	var recovered_hp = int(player.hp)
	player.location = "venice_tavern"
	statuses = {}
	active_battle = {}
	dungeon_cleared = {}
	round_logs.append("你失去了意识。巡逻队把你送回酒馆，未损失装备和银币。")
	message_history.push_front("挑战%s失败，被送回威尼斯酒馆。" % enemy.name)
	_trim_history()
	save_game()
	return {
		"ok": true, "battle_over": true, "won": false, "fled": false,
		"enemy_id": enemy_id, "enemy_name": enemy.name, "enemy_rank": enemy.rank, "enemy_level": int(enemy.level),
		"enemy_hp": remaining_enemy_hp, "enemy_max_hp": int(enemy.hp), "player_level": int(player.level),
		"player_hp": defeated_player_hp, "player_max_hp": int(get_stats().max_hp), "recovered_hp": recovered_hp, "round": 0, "statuses": {},
		"logs": round_logs, "exp": 0, "silver": 0, "drop": "", "leveled": false, "new_level": int(player.level)
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
	var old_title = quest.title
	quest_index += 1
	quest_progress = 0
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
	if objective.type == action_type and objective.target == target:
		quest_progress = min(int(objective.need), quest_progress + amount)
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
	return 55 + level * 70 + int(round(float(GameData.ITEMS[item_id].get("price", 0)) * 0.22))

func upgrade_equipped(slot):
	var item_id = str(equipment.get(str(slot), ""))
	if item_id == "" or not GameData.ITEMS.has(item_id):
		return {"ok": false, "message": "该部位没有可以强化的装备。"}
	var level = equipment_upgrade_level(item_id)
	if level >= 3:
		return {"ok": false, "message": "%s已经强化至当前上限+3。" % GameData.ITEMS[item_id].name}
	var cost = equipment_upgrade_cost(slot)
	if int(player.silver) < cost:
		return {"ok": false, "message": "强化需要%d银币，可以先通过港口贸易积累资金。" % cost}
	player.silver -= cost
	equipment_upgrades[item_id] = level + 1
	player.hp = min(int(player.hp), int(get_stats().max_hp))
	var quest_completed = _advance_quest("upgrade_equipment", str(slot))
	message_history.push_front("%s强化至+%d。" % [GameData.ITEMS[item_id].name, level + 1])
	_trim_history()
	save_game()
	return {"ok": true, "message": "%s强化成功：+%d（-%d银币）" % [GameData.ITEMS[item_id].name, level + 1, cost], "level": level + 1, "cost": cost, "quest_completed": quest_completed}

func trade_contract_progress():
	return clamp(max(0, int(trade_profit)), 0, 120)

func trade_contract_can_claim():
	return is_trade_unlocked() and not trade_contract_claimed and trade_contract_progress() >= 120

func claim_trade_contract():
	if trade_contract_claimed:
		return {"ok": false, "message": "本轮商会委托已经领取。"}
	if not trade_contract_can_claim():
		return {"ok": false, "message": "贸易净利润达到120银币后才能领取。"}
	trade_contract_claimed = true
	player.silver += 90
	_add_item("unknown_equipment", 1)
	message_history.push_front("完成威尼斯商会委托，获得90银币和未知道具。")
	_trim_history()
	save_game()
	return {"ok": true, "message": "商会奖励：90银币、未知道具×1"}

func cargo_used():
	var used = 0
	for good_id in cargo:
		if GameData.TRADE_GOODS.has(good_id):
			used += int(cargo[good_id]) * int(GameData.TRADE_GOODS[good_id].space)
	return used

func cargo_capacity():
	return int(ship.get("capacity", 12))

func trade_buy_price(good_id):
	return GameData.trade_market_price(str(player.location), good_id, trade_day)

func trade_sell_price(good_id):
	return int(floor(float(trade_buy_price(good_id)) * 0.90))

func buy_cargo(good_id):
	if not is_trade_unlocked():
		return {"ok": false, "message": "完成威尼斯四层试炼后才会获得贸易船。"}
	if not GameData.TRADE_PORTS.has(player.location) or not GameData.TRADE_GOODS.has(good_id):
		return {"ok": false, "message": "这里不能购买这种货物。"}
	var good = GameData.TRADE_GOODS[good_id]
	if cargo_used() + int(good.space) > cargo_capacity():
		return {"ok": false, "message": "货舱空间不足，需要%d格空位。" % int(good.space)}
	var price = trade_buy_price(good_id)
	if int(player.silver) < price:
		return {"ok": false, "message": "银币不足，购买需要%d银币。" % price}
	player.silver -= price
	cargo[good_id] = int(cargo.get(good_id, 0)) + 1
	trade_profit -= price
	trade_volume += 1
	var quest_completed = _advance_quest("trade_buy", str(good_id))
	message_history.push_front("在%s买入1%s%s。" % [GameData.TRADE_PORTS[player.location].name, good.unit, good.name])
	_trim_history()
	save_game()
	return {"ok": true, "message": "买入%s -%d银币" % [good.name, price], "price": price, "quest_completed": quest_completed}

func sell_cargo(good_id):
	if not is_trade_unlocked() or not GameData.TRADE_PORTS.has(player.location):
		return {"ok": false, "message": "当前不在可交易港口。"}
	if int(cargo.get(good_id, 0)) <= 0 or not GameData.TRADE_GOODS.has(good_id):
		return {"ok": false, "message": "货舱中没有这种货物。"}
	var good = GameData.TRADE_GOODS[good_id]
	var price = trade_sell_price(good_id)
	player.silver += price
	trade_profit += price
	var quest_completed = _advance_quest("trade_sell", str(good_id))
	var left = int(cargo[good_id]) - 1
	if left <= 0:
		cargo.erase(good_id)
	else:
		cargo[good_id] = left
	trade_volume += 1
	message_history.push_front("在%s卖出1%s%s。" % [GameData.TRADE_PORTS[player.location].name, good.unit, good.name])
	_trim_history()
	save_game()
	return {"ok": true, "message": "卖出%s +%d银币" % [good.name, price], "price": price, "quest_completed": quest_completed}

func sail_to(port_id):
	if not is_trade_unlocked():
		return {"ok": false, "message": "贸易航线尚未解锁。"}
	if not GameData.TRADE_PORTS.has(player.location) or not GameData.TRADE_PORTS.has(port_id):
		return {"ok": false, "message": "航线目的地不存在。"}
	var route = GameData.trade_route(player.location, port_id)
	if route.is_empty():
		return {"ok": false, "message": "两座港口之间没有直达航线。"}
	var fee = int(route.fee)
	if int(player.silver) < fee:
		return {"ok": false, "message": "至少需要%d银币支付航费。" % fee}
	var from_name = GameData.TRADE_PORTS[player.location].name
	var from_port = str(player.location)
	var days = max(1, int(route.days) - (int(ship.get("speed", 1)) - 1))
	player.silver -= fee
	trade_profit -= fee
	trade_day += days
	player.location = port_id
	var quest_completed = _advance_quest("visit", str(port_id))
	var risk = max(4, int(route.get("risk", 15)) - int(ship.get("armor", 0)) * 6)
	var event_message = "航程平安。"
	var event_roll = rng.randi_range(1, 100)
	if event_roll <= risk:
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
	return {"ok": true, "message": "抵达%s · 航费%d · 用时%d日\n%s" % [GameData.TRADE_PORTS[port_id].name, fee, days, event_message], "days": days, "fee": fee, "risk": risk, "event": event_message, "from": from_port, "quest_completed": quest_completed}

func _remove_item_from_cargo(good_id, count):
	var left = int(cargo.get(good_id, 0)) - int(count)
	if left <= 0:
		cargo.erase(good_id)
	else:
		cargo[good_id] = left

func upgrade_ship(kind):
	if not is_trade_unlocked():
		return {"ok": false, "message": "贸易船尚未解锁。"}
	var cost = 0
	var message = ""
	if kind == "hold":
		if cargo_capacity() >= 30:
			return {"ok": false, "message": "货舱已扩到最大容量。"}
		cost = 180 + (cargo_capacity() - 12) * 12
		message = "货舱扩充至%d格" % (cargo_capacity() + 6)
	elif kind == "speed":
		if int(ship.get("speed", 1)) >= 4:
			return {"ok": false, "message": "船帆速度已升到最高。"}
		cost = 220 + (int(ship.get("speed", 1)) - 1) * 100
		message = "船速提升至%d级" % (int(ship.get("speed", 1)) + 1)
	elif kind == "armor":
		if int(ship.get("armor", 0)) >= 3:
			return {"ok": false, "message": "船体护甲已升到最高。"}
		cost = 240 + int(ship.get("armor", 0)) * 130
		message = "船体护甲提升至%d级，航行风险降低" % (int(ship.get("armor", 0)) + 1)
	else:
		return {"ok": false, "message": "未知的船只改造。"}
	if int(player.silver) < cost:
		return {"ok": false, "message": "改造需要%d银币。" % cost}
	player.silver -= cost
	if kind == "hold":
		ship.capacity = cargo_capacity() + 6
	elif kind == "speed":
		ship.speed = int(ship.get("speed", 1)) + 1
	else:
		ship.armor = int(ship.get("armor", 0)) + 1
	var quest_completed = _advance_quest("upgrade_ship", str(kind))
	message_history.push_front("海燕号完成改造：%s。" % message)
	_trim_history()
	save_game()
	return {"ok": true, "message": "%s（-%d银币）" % [message, cost], "cost": cost, "quest_completed": quest_completed}

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

func save_game():
	var payload = {
		"save_version": SAVE_VERSION, "player": player, "inventory": inventory, "equipment": equipment,
		"quest_index": quest_index, "quest_progress": quest_progress, "defeated": defeated,
		"message_history": message_history, "active_battle": active_battle, "statuses": statuses,
		"party_members": party_members, "companion_unlocked": companion_unlocked, "pet": pet,
		"dungeon_cleared": dungeon_cleared, "cargo": cargo, "ship": ship,
		"trade_day": trade_day, "trade_profit": trade_profit, "trade_volume": trade_volume,
		"battle_stance": battle_stance, "auto_heal_threshold": auto_heal_threshold, "auto_cure_status": auto_cure_status,
		"equipment_upgrades": equipment_upgrades, "trade_contract_claimed": trade_contract_claimed
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
	ship = parsed.get("ship", {"name": "海燕号", "capacity": 12, "speed": 1, "armor": 0})
	trade_day = max(1, int(parsed.get("trade_day", 1)))
	trade_profit = int(parsed.get("trade_profit", 0))
	trade_volume = max(0, int(parsed.get("trade_volume", 0)))
	battle_stance = str(parsed.get("battle_stance", "balanced"))
	if not battle_stance in ["assault", "balanced", "guard", "plunder"]:
		battle_stance = "balanced"
	auto_heal_threshold = int(parsed.get("auto_heal_threshold", 35))
	if not auto_heal_threshold in [0, 35, 55]:
		auto_heal_threshold = 35
	auto_cure_status = bool(parsed.get("auto_cure_status", true))
	equipment_upgrades = parsed.get("equipment_upgrades", {})
	trade_contract_claimed = bool(parsed.get("trade_contract_claimed", false))
	if not ship.has("name"):
		ship.name = "海燕号"
	ship.capacity = clamp(int(ship.get("capacity", 12)), 12, 30)
	ship.speed = clamp(int(ship.get("speed", 1)), 1, 4)
	ship.armor = clamp(int(ship.get("armor", 0)), 0, 3)
	for good_id in cargo.keys():
		if not GameData.TRADE_GOODS.has(good_id) or int(cargo[good_id]) <= 0:
			cargo.erase(good_id)
	if not GameData.LOCATIONS.has(player.get("location", "")):
		player.location = "alisa_hut"
		active_battle = {}
	if not active_battle.is_empty() and not GameData.ENEMIES.has(active_battle.get("enemy_id", "")):
		active_battle = {}
	if int(player.level) >= GameData.MAX_LEVEL:
		player.level = GameData.MAX_LEVEL
		player.xp = 0
	player.hp = clamp(int(player.hp), 1, int(get_stats().max_hp))
	return true
