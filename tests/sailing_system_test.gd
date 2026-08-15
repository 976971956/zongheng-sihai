extends SceneTree

const SeaWorldMapScript = preload("res://scripts/sea_world_2d.gd")

class TestState extends GameState:
	func has_save():
		return false

	func save_game():
		pass

var failures = []

func _init():
	call_deferred("_run")

func _run():
	var port_ids = GameData.TRADE_PORTS.keys()
	var route_pair_count = 0
	for origin_index in range(port_ids.size()):
		for destination_index in range(origin_index + 1, port_ids.size()):
			var origin_id = str(port_ids[origin_index])
			var destination_id = str(port_ids[destination_index])
			var route_data = GameData.trade_route(origin_id, destination_id)
			var reverse_route = GameData.trade_route(destination_id, origin_id)
			_check(not route_data.is_empty() and int(route_data.distance_nm) > 0 and int(route_data.days) >= 2, "%s与%s必须能动态生成直达航程" % [origin_id, destination_id])
			_check(int(route_data.distance_nm) == int(reverse_route.distance_nm) and int(route_data.fee) == int(reverse_route.fee), "港口距离与传送费必须双向一致：%s↔%s" % [origin_id, destination_id])
			_check(GameData.trade_route_path(origin_id, destination_id, port_ids) == [origin_id, destination_id], "任意两座已发现港口必须直接通航，不应强制中转")
			route_pair_count += 1
	_check(route_pair_count == 36, "九港必须形成36组全互通港口对")
	var state = TestState.new()
	state.quest_index = GameData.QUESTS.size()
	state.player.level = 8
	state.player.location = "venice_dock"
	state.player.silver = 300
	var coastal_plan = state.voyage_plan("ragusa_dock")
	var regional_plan = state.voyage_plan("alexandria_dock")
	var oceanic_plan = state.voyage_plan("cape_town_dock")
	_check(int(coastal_plan.distance_nm) == 420 and str(coastal_plan.tier) == "coastal" and int(coastal_plan.threat_count) == 2 and "coastal_pirate" in coastal_plan.enemy_ids, "威尼斯至拉古萨必须是420海里并生成两处含海盗的近海威胁")
	_check(str(regional_plan.tier) == "regional" and int(regional_plan.threat_count) == 4 and "reef_serpent" in regional_plan.enemy_ids, "跨海航线必须提高怪物密度并同时规划海盗与礁海怪物")
	_check(str(oceanic_plan.tier) == "oceanic" and int(oceanic_plan.threat_count) == 6 and not ("black_flag_privateer" in oceanic_plan.enemy_ids), "中低等级玩家的长途远洋航线必须有六处威胁且不能过早出现Lv.52私掠舰")
	_check(int(coastal_plan.distance_nm) < int(regional_plan.distance_nm) and int(regional_plan.distance_nm) < int(oceanic_plan.distance_nm), "近海、跨海与远洋距离必须按真实港口跨度递增")
	_check(GameData.sea_port_position("venice_dock").distance_to(GameData.sea_port_position("ragusa_dock")) < GameData.sea_port_position("venice_dock").distance_to(GameData.sea_port_position("alexandria_dock")) and GameData.SEA_GLOBAL_WORLD_SIZE == Vector2(3200, 2900), "九港必须投影在同一张大地图中，近港的物理距离应更短")
	var navigation_map = SeaWorldMapScript.new()
	root.add_child(navigation_map)
	navigation_map.configure({"origin": "venice_dock", "destination": "ragusa_dock", "unlocked_ports": port_ids, "world_width": 3200.0, "world_height": 2900.0})
	for departure_port_id in port_ids:
		var harbor_position = GameData.sea_port_position(str(departure_port_id))
		_check(navigation_map.is_navigable(harbor_position), "%s的海上出生点必须可航行" % GameData.TRADE_PORTS[str(departure_port_id)].name)
		for departure_direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			_check(navigation_map.is_navigable(harbor_position + departure_direction * 24.0), "%s出港后必须能立即向任意方向驾驶，不能被礁区锁在出生点" % GameData.TRADE_PORTS[str(departure_port_id)].name)
	navigation_map.queue_free()
	var level_one_days = int(oceanic_plan.days)
	state.ship.speed = 4
	var fast_oceanic_plan = state.voyage_plan("cape_town_dock")
	_check(is_equal_approx(float(fast_oceanic_plan.speed_knots), 12.5) and int(fast_oceanic_plan.nm_per_day) == 300 and float(fast_oceanic_plan.world_speed) > float(oceanic_plan.world_speed) and int(fast_oceanic_plan.days) < level_one_days, "船型基础速度与帆装等级必须共同缩短贸易日历并提高2D驾驶速度")
	state.ship.speed = 1
	_check(int(coastal_plan.stamina_cost) < int(oceanic_plan.stamina_cost) and int(coastal_plan.dive_chance) < int(oceanic_plan.dive_chance), "远洋必须消耗更多出航体力，同时提供更高的潜水寻宝概率")
	var tired_state = TestState.new()
	tired_state.quest_index = GameData.QUESTS.size()
	tired_state.player.location = "venice_dock"
	tired_state.player.hp = int(tired_state.voyage_plan("ragusa_dock").stamina_cost)
	_check(not bool(tired_state.begin_voyage("ragusa_dock").get("ok", true)) and tired_state.active_voyage.is_empty(), "体力不足时不能以0体力离港，必须先休息或使用补给")
	state.player.level = 55
	var veteran_oceanic_plan = state.voyage_plan("cape_town_dock")
	_check(int(veteran_oceanic_plan.threat_count) == 6 and "black_flag_privateer" in veteran_oceanic_plan.enemy_ids, "高等级玩家进入高风险远洋时必须出现六处巡游威胁并包含私掠舰")
	var north_sea_plan = state.voyage_plan("venice_dock", "amsterdam_dock")
	var east_asia_plan = state.voyage_plan("yangzhou_dock", "quanzhou_dock")
	var intercontinental_plan = state.voyage_plan("quanzhou_dock", "venice_dock")
	_check("fog_siren" in north_sea_plan.enemy_ids or "drowned_sailor" in north_sea_plan.enemy_ids, "北海航程必须出现雾歌海妖或溺潮水手，不能复用地中海固定敌群：%s" % north_sea_plan)
	_check(Array(east_asia_plan.enemy_ids).size() == 2 and "reef_serpent" in east_asia_plan.enemy_ids, "泉州至扬州近海必须生成两处含礁海长蛇的东亚威胁")
	_check(intercontinental_plan.zone_ids == ["mediterranean", "indian_ocean", "east_asia"] and "印度洋" in str(intercontinental_plan.waters_text), "威尼斯至泉州必须记录完整跨海域航迹")
	state.ship.armor = 3
	state.voyage_protection = 1
	var protected_oceanic_plan = state.voyage_plan("cape_town_dock")
	_check(int(protected_oceanic_plan.threat_count) == 5 and int(protected_oceanic_plan.risk) < int(veteran_oceanic_plan.risk), "船体护甲和护航物资必须降低远洋风险与遭遇数量")
	state.ship.armor = 0
	state.voyage_protection = 0
	state.player.level = 8
	var initial_silver = int(state.player.silver)
	var initial_day = int(state.trade_day)
	var initial_hp = int(state.player.hp)
	var departure = state.begin_voyage("ragusa_dock")
	_check(bool(departure.get("ok", false)), "正常出航必须能创建进行中的航程")
	_check(str(state.player.location) == "venice_dock" and int(state.player.silver) == initial_silver, "出航后、靠港前必须保留启航港且不收传送费")
	_check(int(state.player.hp) == initial_hp - int(coastal_plan.stamina_cost) and int(state.active_voyage.stamina_cost) == int(coastal_plan.stamina_cost), "正常出航必须按航程消耗体力并把消耗记录进航程")
	var coastal_origin = GameData.sea_port_position("venice_dock")
	_check(str(state.active_voyage.get("region", "")) == "mediterranean" and state.voyage_position() == coastal_origin and Vector2(float(state.active_voyage.world_width), float(state.active_voyage.world_height)) == GameData.SEA_GLOBAL_WORLD_SIZE and Array(state.active_voyage.unlocked_ports).size() == 9, "出航后必须进入九港共用大地图并在启航港保存船位")
	state.update_voyage_position(Vector2(610, 1240))
	_check(state.voyage_position() == Vector2(610, 1240), "进行中的船位必须可以写入存档状态")
	state.update_voyage_position(GameData.sea_port_position("venice_dock").lerp(GameData.sea_port_position("ragusa_dock"), 0.5))
	_check(is_equal_approx(state.voyage_progress(), 0.5) and state.voyage_remaining_distance() == 210, "船位必须换算为真实航程进度与剩余海里")
	var treasure = state.claim_sea_treasure()
	_check(bool(treasure.get("ok", false)) and str(treasure.get("mode", "")) == "salvage" and int(state.player.silver) > initial_silver and not bool(state.claim_sea_treasure().get("ok", true)), "每段航程可选择稳妥打捞，且漂流货箱只能领取一次")
	state.cargo["venetian_glass"] = 2
	state.cargo_costs["venetian_glass"] = 48
	var storm = state.resolve_sea_storm()
	_check(bool(storm.get("ok", false)) and int(state.cargo.get("venetian_glass", 0)) == 1, "未携带护航物资穿越风暴时必须在海域内即时损失货物")
	state.mark_sea_pirate_defeated()
	_check(state.sea_encounters_remaining() == 1 and not bool(state.active_voyage.get("pirate_defeated", true)), "击败一支巡游海盗后必须保留同航线上的其他威胁")
	var arrival = state.complete_voyage()
	_check(bool(arrival.get("ok", false)) and str(state.player.location) == "ragusa_dock" and state.active_voyage.is_empty() and int(state.trade_day) > initial_day, "抵港后才应修改港口、推进日期并清空航程")

	state.player.location = "ragusa_dock"
	var transfer_silver = int(state.player.silver)
	var transfer = state.transfer_to("venice_dock")
	_check(bool(transfer.get("ok", false)) and str(state.player.location) == "venice_dock" and int(state.player.silver) < transfer_silver and state.active_voyage.is_empty(), "付费传送必须直接抵港、扣费且不进入海域")

	var dive_state = TestState.new()
	dive_state.quest_index = GameData.QUESTS.size()
	dive_state.player.location = "venice_dock"
	dive_state.player.level = 30
	dive_state.rng.seed = 7
	dive_state.begin_voyage("alexandria_dock")
	var dive_result = dive_state.claim_sea_treasure("dive")
	_check(bool(dive_result.get("ok", false)) and str(dive_result.get("mode", "")) == "dive" and dive_result.has("found") and not bool(dive_state.claim_sea_treasure("salvage").get("ok", true)), "航海潜水必须结算成功率或安慰奖励，并与稳妥打捞共享每航程一次机会")

	var battle_state = TestState.new()
	battle_state.quest_index = GameData.QUESTS.size()
	battle_state.player.level = 1
	battle_state.player.location = "venice_dock"
	battle_state.begin_voyage("ragusa_dock")
	battle_state.player.hp = 1
	var sea_battle = battle_state.start_battle(battle_state.sea_enemy_id())
	_check(bool(sea_battle.get("ok", false)), "海域中的可见海盗必须能进入现有自动战斗系统")
	var defeat = {}
	for _round in range(10):
		defeat = battle_state.attack_once()
		if bool(defeat.get("battle_over", false)):
			break
	_check(bool(defeat.get("battle_over", false)) and not bool(defeat.get("won", true)) and bool(defeat.get("lost_at_sea", false)) and str(battle_state.player.location) == "venice_dock" and battle_state.active_voyage.is_empty(), "海战失败必须中止航程并返回启航港")

	state.player.location = "venice_dock"
	state.voyage_protection = 1
	state.begin_voyage("ragusa_dock")
	_check(state.voyage_protection == 0 and bool(state.active_voyage.get("escorted", false)), "护航物资必须在启航时绑定并消耗，不能绕开风暴后无限复用")
	var protected_storm = state.resolve_sea_storm()
	_check(bool(protected_storm.get("protected", false)) and not bool(state.active_voyage.get("escorted", true)), "本航程护航必须免除一次风暴损失且随后失效")
	var origin = str(state.active_voyage.origin)
	var abort = state.abort_voyage()
	_check(bool(abort.get("ok", false)) and str(state.player.location) == origin and state.active_voyage.is_empty(), "玩家必须能放弃航程并返回启航港")
	_check(int(state.voyage_plan("ragusa_dock").risk) > 4, "返航后的下一次航程不能继续沿用已经消耗的护航减险")

	for milestone in [
		{"origin": "malta_dock", "destination": "cape_town_dock", "level": 30},
		{"origin": "cape_town_dock", "destination": "quanzhou_dock", "level": 37},
		{"origin": "quanzhou_dock", "destination": "athens_dock", "level": 44},
		{"origin": "athens_dock", "destination": "venice_dock", "level": 51},
		{"origin": "venice_dock", "destination": "yangzhou_dock", "level": 58},
		{"origin": "yangzhou_dock", "destination": "amsterdam_dock", "level": 65}
	]:
		var story_state = TestState.new()
		story_state.quest_index = GameData.QUESTS.size()
		story_state.player.location = str(milestone.origin)
		story_state.player.level = int(milestone.level)
		story_state.ship.armor = 1
		var story_plan = story_state.voyage_plan(str(milestone.destination))
		_check(not story_plan.is_empty() and int(story_plan.recommended_level) <= int(milestone.level) + 8, "主线航程%s→%s不能生成跨度过大的必经敌人" % [milestone.origin, milestone.destination])
		_check(not ("black_flag_privateer" in Array(story_plan.enemy_ids)) or int(milestone.level) >= 45, "Lv.45前的主线航程不能出现黑旗私掠舰")

	var long_state = TestState.new()
	long_state.quest_index = GameData.QUESTS.size()
	long_state.player.location = "venice_dock"
	long_state.player.level = 55
	long_state.begin_voyage("cape_town_dock")
	_check(Array(long_state.active_voyage.encounters).size() == 6 and long_state.sea_encounters_remaining() == 6, "远洋航程必须生成并保存六处独立遭遇")
	for encounter in Array(long_state.active_voyage.encounters):
		var encounter_data = Dictionary(encounter)
		var encounter_position = Vector2(float(encounter_data.x), float(encounter_data.y))
		_check(str(encounter_data.zone_id) in Array(long_state.active_voyage.zone_ids) and encounter_position.x > 100.0 and encounter_position.x < GameData.SEA_GLOBAL_WORLD_SIZE.x - 100.0 and encounter_position.y > 100.0 and encounter_position.y < GameData.SEA_GLOBAL_WORLD_SIZE.y - 100.0, "海盗与海怪必须分散在大地图航路及对应海域内")
	var first_encounter = Dictionary(long_state.active_voyage.encounters[0])
	long_state.mark_sea_encounter_defeated(str(first_encounter.id))
	_check(long_state.sea_encounters_remaining() == 5 and not bool(long_state.active_voyage.pirate_defeated), "击败一处远洋威胁不能错误清空其余敌人")
	var second_enemy = long_state.sea_enemy_id()
	var expected_second_enemy = str(Dictionary(long_state.active_voyage.encounters[1]).enemy_id)
	_check(second_enemy == expected_second_enemy and second_enemy != "", "击败第一处海域威胁后必须继续面对航迹中下一处敌人")
	long_state.cargo["venetian_glass"] = 3
	var ocean_storm = long_state.resolve_sea_storm()
	_check(int(ocean_storm.get("lost_count", 0)) == 2 and int(long_state.cargo.get("venetian_glass", 0)) == 1, "未防护的远洋风暴必须损失两单位货物")

	var legacy_state = TestState.new()
	legacy_state.quest_index = GameData.QUESTS.size()
	legacy_state.player.location = "venice_dock"
	legacy_state.voyage_protection = 1
	legacy_state.active_voyage = {"origin": "venice_dock", "destination": "ragusa_dock", "days": 2, "risk": 14, "x": 540.0, "y": 1200.0, "pirate_defeated": false}
	legacy_state._normalize_active_voyage()
	_check(int(legacy_state.active_voyage.get("distance_nm", 0)) == 420 and float(legacy_state.active_voyage.world_width) == GameData.SEA_GLOBAL_WORLD_SIZE.x and Array(legacy_state.active_voyage.get("encounters", [])).size() == 2 and Dictionary(legacy_state.active_voyage.encounters[0]).has("progress") and bool(legacy_state.active_voyage.get("escorted", false)) and legacy_state.voyage_protection == 0, "旧版进行中航程必须迁移到九港共用大地图、密集遭遇和已准备的护航物资")

	if failures.is_empty():
		print("SAILING_OK: 体力出航、海域状态、风暴、打捞/潜水、靠港、返航与付费传送全部通过")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition, message):
	if not condition:
		failures.append(message)
