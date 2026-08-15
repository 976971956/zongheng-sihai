class_name GameState
extends RefCounted

const SAVE_VERSION = 2
const SAVE_PATH = "user://tides_save.json"
const ENEMY_RESPAWN_SECONDS = 20.0
const VOYAGE_ORIGIN_Y = 1580.0
const VOYAGE_DESTINATION_Y = 365.0
const SEA_ENCOUNTER_POSITIONS = {
	1: [Vector2(540, 1030)],
	2: [Vector2(680, 1160), Vector2(390, 690)],
	3: [Vector2(620, 1280), Vector2(350, 980), Vector2(560, 560)]
}

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

func _init():
	rng.randomize()
	new_game()

func new_game():
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
	ship = {"name": "海燕号", "capacity": 12, "speed": 1, "armor": 0}
	trade_day = 1
	trade_profit = 0
	trade_volume = 0
	trade_lifetime_profit = 0
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

func equipment_score_delta(item_id):
	if not GameData.ITEMS.has(item_id):
		return 0
	var slot = str(GameData.ITEMS[item_id].get("slot", ""))
	var current_id = str(equipment.get(slot, ""))
	return equipment_item_score(item_id) - equipment_item_score(current_id)

func equip_recommended():
	var choices = {}
	for slot in GameData.SLOT_NAMES:
		var current_id = str(equipment.get(slot, ""))
		choices[slot] = current_id
	for item_id in inventory:
		if int(inventory[item_id]) <= 0 or not GameData.ITEMS.has(item_id):
			continue
		var item = GameData.ITEMS[item_id]
		if str(item.get("type", "")) != "equipment":
			continue
		var slot = str(item.get("slot", ""))
		if equipment_item_score(item_id) > equipment_item_score(str(choices.get(slot, ""))):
			choices[slot] = str(item_id)
	var equipped_names = []
	for slot in GameData.SLOT_NAMES:
		var chosen_id = str(choices.get(slot, ""))
		if chosen_id != "" and chosen_id != str(equipment.get(slot, "")):
			var result = equip_item(chosen_id)
			if bool(result.get("ok", false)):
				equipped_names.append(str(GameData.ITEMS[chosen_id].name))
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
	var enemy = GameData.ENEMIES[enemy_id]
	active_battle = {
		"enemy_id": enemy_id, "enemy_hp": int(enemy.hp), "enemy_max_hp": int(enemy.hp),
		"round": 1, "focus": 0, "skill_prepared": false, "log": [enemy.intro]
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
		"auto_heal_threshold": auto_heal_threshold, "auto_cure_status": auto_cure_status,
		"focus": battle_focus(), "focus_max": 3
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
			logs.append("潮势已满｜可发动破浪斩，若敌人正在蓄力可削弱其技能。")

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
	if rng.randf() <= 0.72:
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
	if result.miss and uses_skill:
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
	var enemy_attack = int(enemy.attack)
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
		logs.append("第%d回合｜破浪斩打乱了%s的%s，你的体力仅-%d。" % [round_number, enemy.name, str(special.get("name", "强力攻击")), result.damage])
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
	var enemy = GameData.ENEMIES[enemy_id]
	var finishing_stance = battle_stance
	player.victories += 1
	player.hp = max(1, int(player.hp))
	var silver = rng.randi_range(int(enemy.silver[0]), int(enemy.silver[1]))
	player.silver += silver
	var leveled = _add_xp(int(enemy.exp))
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
	_consume_meal_battle()
	save_game()
	return {
		"ok": true, "battle_over": true, "won": true, "fled": false,
		"enemy_id": enemy_id, "enemy_name": enemy.name, "enemy_rank": enemy.rank, "enemy_level": int(enemy.level),
		"enemy_hp": 0, "enemy_max_hp": int(enemy.hp), "player_level": int(player.level), "player_hp": int(player.hp), "player_max_hp": int(get_stats().max_hp),
		"round": 0, "statuses": {}, "logs": round_logs,
		"exp": int(enemy.exp), "silver": silver, "drop": drop_id, "leveled": leveled, "new_level": int(player.level),
		"quest_completed": quest_completed, "bounty_completed": bounty_completed, "battle_stance": finishing_stance
	}

func _finish_battle_loss(enemy_id, round_logs):
	var enemy = GameData.ENEMIES[enemy_id]
	var voyage_origin = str(active_voyage.get("origin", ""))
	var lost_at_sea = voyage_origin in GameData.TRADE_PORTS
	var remaining_enemy_hp = int(active_battle.get("enemy_hp", enemy.hp))
	var defeated_player_hp = int(player.hp)
	player.hp = max(1, int(get_stats().max_hp * 0.35))
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
		"enemy_hp": remaining_enemy_hp, "enemy_max_hp": int(enemy.hp), "player_level": int(player.level),
		"player_hp": defeated_player_hp, "player_max_hp": int(get_stats().max_hp), "recovered_hp": recovered_hp, "round": 0, "statuses": {},
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
	if objective.type == action_type and objective.target == target:
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
	if not GameData.TRADE_PORTS.has(player.location):
		return {}
	var best = {}
	var specialty_good = str(GameData.TRADE_PORTS[str(player.location)].get("specialty_good", ""))
	var recommendation_goods = [specialty_good] if GameData.TRADE_GOODS.has(specialty_good) else GameData.port_stock(str(player.location))
	for destination in GameData.TRADE_PORTS:
		if str(destination) == str(player.location):
			continue
		var route = GameData.trade_route(str(player.location), str(destination))
		if route.is_empty():
			continue
		var days = max(1, int(route.days) - (int(ship.get("speed", 1)) - 1))
		for good_id in recommendation_goods:
			var good = GameData.TRADE_GOODS[good_id]
			var buy_price = trade_buy_price(good_id)
			var sell_price = trade_sell_price_at(str(destination), str(good_id), trade_day + days)
			var units = max(1, int(floor(float(cargo_capacity()) / float(good.space))))
			# 商会默认推荐正常出航；只有主动选择快捷传送时才扣传送费。
			var total_profit = (sell_price - buy_price) * units
			if best.is_empty() or total_profit > int(best.total_profit):
				best = {"good_id": str(good_id), "destination": str(destination), "days": days, "units": units, "buy": buy_price, "sell": sell_price, "total_profit": total_profit}
	return best

func cargo_used():
	var used = 0
	for good_id in cargo:
		if GameData.TRADE_GOODS.has(good_id):
			used += int(cargo[good_id]) * int(GameData.TRADE_GOODS[good_id].space)
	return used

func cargo_capacity():
	return int(ship.get("capacity", 12))

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
	return max(0, min(by_space, by_silver))

func trade_buy_price(good_id):
	return trade_buy_price_at(str(player.location), good_id, trade_day)

func trade_sell_price(good_id):
	return trade_sell_price_at(str(player.location), good_id, trade_day)

func trade_buy_price_at(port_id, good_id, day):
	var market_price = GameData.trade_market_price(str(port_id), str(good_id), int(day))
	var discount = min(0.10, float(port_reputation_value(str(port_id))) * 0.005)
	return max(1, int(round(float(market_price) * (1.0 - discount))))

func trade_sell_price_at(port_id, good_id, day):
	var market_price = GameData.trade_market_price(str(port_id), str(good_id), int(day))
	var sell_rate = 0.90 + min(0.05, float(port_reputation_value(str(port_id))) * 0.0025)
	return max(1, int(floor(float(market_price) * sell_rate)))

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
	var price = trade_sell_price(good_id)
	var old_count = int(cargo[good_id])
	var actual_amount = min(max(1, int(amount)), old_count)
	var total = price * actual_amount
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
	if realized_profit > 0:
		quest_completed = _add_port_reputation(str(player.location), max(1, int(floor(float(actual_amount) / 3.0)))) or quest_completed
	message_history.push_front("在%s卖出%d%s%s。" % [GameData.TRADE_PORTS[player.location].name, actual_amount, good.unit, good.name])
	_trim_history()
	save_game()
	return {"ok": true, "message": "卖出%s×%d，收入%d银币｜实际盈亏%+d" % [good.name, actual_amount, total, realized_profit], "price": price, "amount": actual_amount, "total": total, "realized_profit": realized_profit, "quest_completed": quest_completed}

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
	return max(4, int(route.get("risk", 15)) - int(ship.get("armor", 0)) * 6 - card_risk_bonus - protection_bonus)

func voyage_plan(port_id, origin_override = ""):
	var origin = str(origin_override) if str(origin_override) != "" else str(player.location)
	var destination = str(port_id)
	var route = GameData.trade_route(origin, destination)
	if route.is_empty():
		return {}
	var distance_nm = max(1, int(route.get("distance_nm", int(route.get("days", 1)) * 420)))
	var tier_id = GameData.sea_voyage_tier(distance_nm)
	var tier = GameData.SEA_VOYAGE_TIERS[tier_id]
	var risk = _voyage_risk_for_route(route)
	var threat_count = int(tier.minimum_threats)
	if tier_id == "regional" and risk >= 22:
		threat_count = 2
	elif tier_id == "oceanic" and risk >= 36 and int(player.level) >= 45:
		threat_count = 3
	var roster = ["coastal_pirate"]
	if tier_id == "regional":
		roster = ["coastal_pirate", "reef_serpent"]
	elif tier_id == "oceanic":
		roster = ["ocean_raider", "abyss_kraken", "black_flag_privateer"]
	var enemy_ids = roster.slice(0, min(threat_count, roster.size()))
	var recommended_level = 1
	for enemy_id in enemy_ids:
		recommended_level = max(recommended_level, int(GameData.ENEMIES[str(enemy_id)].level))
	return {
		"origin": origin, "destination": destination,
		"distance_nm": distance_nm, "tier": tier_id, "tier_name": str(tier.name),
		"days": max(1, int(route.days) - (int(ship.get("speed", 1)) - 1)),
		"risk": risk, "threat_count": enemy_ids.size(), "enemy_ids": enemy_ids,
		"recommended_level": recommended_level, "description": str(tier.description)
	}

func _build_sea_encounters(plan):
	var encounters = []
	var enemy_ids = Array(plan.get("enemy_ids", []))
	var count = clamp(enemy_ids.size(), 1, 3)
	var positions = Array(SEA_ENCOUNTER_POSITIONS[count])
	for index in range(enemy_ids.size()):
		var enemy_id = str(enemy_ids[index])
		var position = Vector2(positions[index])
		encounters.append({
			"id": "sea_%d" % (index + 1), "enemy_id": enemy_id,
			"kind": "monster" if enemy_id in ["reef_serpent", "abyss_kraken"] else "pirate",
			"x": position.x, "y": position.y, "defeated": false
		})
	return encounters

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
		return {"ok": false, "message": "两座港口之间没有直达航线，需要中转。"}
	var escorted = voyage_protection > 0
	active_voyage = {
		"origin": str(player.location), "destination": destination,
		"region": GameData.sea_region_for_route(str(player.location), destination),
		"days": int(plan.days), "risk": int(plan.risk),
		"distance_nm": int(plan.distance_nm), "tier": str(plan.tier), "tier_name": str(plan.tier_name),
		"recommended_level": int(plan.recommended_level),
		"x": 540.0, "y": 1580.0, "pirate_defeated": false,
		"treasure_claimed": false, "storm_resolved": false,
		"encounters": _build_sea_encounters(plan), "current_encounter_id": "",
		"escorted": escorted
	}
	if escorted:
		voyage_protection = 0
	message_history.push_front("海燕号从%s正常出航，驶入%s：%d海里，预计%d日。" % [GameData.TRADE_PORTS[str(player.location)].name, GameData.SEA_REGIONS[str(active_voyage.region)].name, int(active_voyage.distance_nm), int(active_voyage.days)])
	_trim_history()
	save_game()
	return {"ok": true, "message": "已驶入%s：%s，共%d海里，侦测到%d处威胁。驾驶海燕号抵达%s。" % [GameData.SEA_REGIONS[str(active_voyage.region)].name, str(plan.tier_name), int(plan.distance_nm), int(plan.threat_count), GameData.TRADE_PORTS[destination].name], "voyage": active_voyage.duplicate(true)}

func update_voyage_position(position, persist = false):
	if active_voyage.is_empty():
		return
	var point = Vector2(position)
	active_voyage.x = float(point.x)
	active_voyage.y = float(point.y)
	if persist:
		save_game()

func voyage_position():
	if active_voyage.is_empty():
		return Vector2.ZERO
	return Vector2(float(active_voyage.get("x", 540.0)), float(active_voyage.get("y", 1580.0)))

func voyage_progress():
	if active_voyage.is_empty():
		return 0.0
	return clamp((VOYAGE_ORIGIN_Y - float(active_voyage.get("y", VOYAGE_ORIGIN_Y))) / (VOYAGE_ORIGIN_Y - VOYAGE_DESTINATION_Y), 0.0, 1.0)

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

func claim_sea_treasure():
	if active_voyage.is_empty():
		return {"ok": false, "message": "这里没有正在进行的航程。"}
	if bool(active_voyage.get("treasure_claimed", false)):
		return {"ok": false, "message": "漂流货箱已经打捞过了。"}
	var silver = 18 + int(active_voyage.get("days", 1)) * 5 + int(active_voyage.get("distance_nm", 0)) / 240
	active_voyage.treasure_claimed = true
	player.silver += silver
	message_history.push_front("航途中打捞漂流货箱，获得%d银币。" % silver)
	_trim_history()
	save_game()
	return {"ok": true, "message": "水手从漂流货箱里找到%d银币。" % silver, "silver": silver}

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

func complete_voyage():
	if active_voyage.is_empty():
		return {"ok": false, "message": "没有可以结算的航程。"}
	var voyage = active_voyage.duplicate(true)
	var destination = str(voyage.destination)
	var origin = str(voyage.origin)
	trade_day += int(voyage.days)
	player.location = destination
	active_voyage = {}
	var quest_completed = _advance_quest("visit", destination)
	message_history.push_front("海燕号从%s航行%d日，抵达%s。" % [GameData.TRADE_PORTS[origin].name, int(voyage.days), GameData.TRADE_PORTS[destination].name])
	_trim_history()
	save_game()
	return {"ok": true, "message": "抵达%s · 完成%d海里航程 · 用时%d日\n海盗、海怪、风暴和打捞均已在海域中即时结算。" % [GameData.TRADE_PORTS[destination].name, int(voyage.get("distance_nm", 0)), int(voyage.days)], "days": int(voyage.days), "distance_nm": int(voyage.get("distance_nm", 0)), "from": origin, "destination": destination, "quest_completed": quest_completed}

func abort_voyage():
	if active_voyage.is_empty():
		return {"ok": false, "message": "当前没有航程。"}
	var origin = str(active_voyage.origin)
	active_voyage = {}
	player.location = origin
	save_game()
	return {"ok": true, "origin": origin, "message": "海燕号返航至%s。" % GameData.TRADE_PORTS[origin].name}

func transfer_to(port_id):
	var destination = str(port_id)
	if not is_trade_unlocked() or not GameData.TRADE_PORTS.has(str(player.location)) or not GameData.TRADE_PORTS.has(destination):
		return {"ok": false, "message": "现在无法使用港口传送。"}
	if not is_port_unlocked(destination):
		return {"ok": false, "message": "该港口尚未发现。"}
	var route = GameData.trade_route(str(player.location), destination)
	if route.is_empty():
		return {"ok": false, "message": "两座港口之间没有直达传送船。"}
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
	var protected_voyage = voyage_protection > 0
	var risk = max(4, int(route.get("risk", 15)) - int(ship.get("armor", 0)) * 6 - (4 if active_card == "corsair_card" else 0) - (8 if protected_voyage else 0))
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
	if not active_voyage.has("recommended_level"):
		active_voyage.recommended_level = int(plan.recommended_level)
	var saved_encounters = active_voyage.get("encounters", [])
	if typeof(saved_encounters) != TYPE_ARRAY or Array(saved_encounters).is_empty():
		active_voyage.encounters = _build_sea_encounters(plan)
		if bool(active_voyage.get("pirate_defeated", false)):
			var cleared = []
			for encounter in Array(active_voyage.encounters):
				var migrated = Dictionary(encounter)
				migrated.defeated = true
				cleared.append(migrated)
			active_voyage.encounters = cleared
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
		"trade_lifetime_profit": trade_lifetime_profit, "port_reputation": port_reputation,
		"trade_order_cycles": trade_order_cycles, "completed_trade_orders": completed_trade_orders,
		"voyage_protection": voyage_protection, "active_voyage": active_voyage,
		"battle_stance": battle_stance, "auto_heal_threshold": auto_heal_threshold, "auto_cure_status": auto_cure_status,
		"equipment_upgrades": equipment_upgrades, "trade_contract_claimed": trade_contract_claimed,
		"trade_contract_count": trade_contract_count, "active_card": active_card, "discoveries": discoveries,
		"bounty_index": bounty_index, "bounty_progress": bounty_progress, "bounty_cycles": bounty_cycles,
		"enemy_respawns": enemy_respawns, "meal_buff_battles": meal_buff_battles
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
	ship = parsed.get("ship", {"name": "海燕号", "capacity": 12, "speed": 1, "armor": 0})
	trade_day = max(1, int(parsed.get("trade_day", 1)))
	trade_profit = int(parsed.get("trade_profit", 0))
	trade_volume = max(0, int(parsed.get("trade_volume", 0)))
	trade_lifetime_profit = int(parsed.get("trade_lifetime_profit", 0))
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
	ship.capacity = clamp(int(ship.get("capacity", 12)), 12, 30)
	ship.speed = clamp(int(ship.get("speed", 1)), 1, 4)
	ship.armor = clamp(int(ship.get("armor", 0)), 0, 3)
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
	if int(player.level) >= GameData.MAX_LEVEL:
		player.level = GameData.MAX_LEVEL
		player.xp = 0
	quest_index = clamp(quest_index, 0, GameData.QUESTS.size())
	_sync_current_quest_progress()
	player.hp = clamp(int(player.hp), 1, int(get_stats().max_hp))
	return true
