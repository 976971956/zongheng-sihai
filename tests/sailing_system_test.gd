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
	_check(state.owned_ship_ids() == ["sea_swallow"] and state.owns_ship("sea_swallow") and state.ship_role() == "轻帆船", "新角色必须永久拥有海燕号，并能读取明确船型定位")
	var coastal_plan = state.voyage_plan("ragusa_dock")
	var regional_plan = state.voyage_plan("alexandria_dock")
	var oceanic_plan = state.voyage_plan("cape_town_dock")
	_check(int(coastal_plan.distance_nm) == 420 and str(coastal_plan.tier) == "coastal" and int(coastal_plan.threat_count) == 4 and "coastal_pirate" in coastal_plan.enemy_ids, "威尼斯至拉古萨必须是420海里并生成四处含海盗的近海威胁")
	_check(Array(coastal_plan.enemy_levels).size() == int(coastal_plan.threat_count) and int(coastal_plan.recommended_level) <= int(state.player.level) + 6, "航程必须为每处威胁保存动态等级，并限制在玩家可应对范围内")
	_check(str(regional_plan.tier) == "regional" and int(regional_plan.threat_count) == 7 and "reef_serpent" in regional_plan.enemy_ids, "跨海航线必须提高到七处威胁并同时规划海盗与礁海怪物")
	_check(str(oceanic_plan.tier) == "oceanic" and int(oceanic_plan.threat_count) == 12 and not ("black_flag_privateer" in oceanic_plan.enemy_ids), "中低等级玩家的超长远洋航线必须有十二处威胁且不能过早出现Lv.52私掠舰")
	_check(int(coastal_plan.distance_nm) < int(regional_plan.distance_nm) and int(regional_plan.distance_nm) < int(oceanic_plan.distance_nm), "近海、跨海与远洋距离必须按真实港口跨度递增")
	_check(GameData.sea_port_position("venice_dock").distance_to(GameData.sea_port_position("ragusa_dock")) < GameData.sea_port_position("venice_dock").distance_to(GameData.sea_port_position("alexandria_dock")) and GameData.SEA_GLOBAL_WORLD_SIZE == Vector2(5200, 4300), "九港必须分布在扩展后的同一张大地图中，近港的物理距离应更短")
	var minimum_port_gap = INF
	for first_index in range(port_ids.size()):
		for second_index in range(first_index + 1, port_ids.size()):
			minimum_port_gap = min(minimum_port_gap, GameData.sea_port_position(str(port_ids[first_index])).distance_to(GameData.sea_port_position(str(port_ids[second_index]))))
	_check(minimum_port_gap >= 500.0, "任意两港的驾驶距离必须至少500像素，避免刚离港就到达下一港")
	var navigation_map = SeaWorldMapScript.new()
	root.add_child(navigation_map)
	navigation_map.configure({"origin": "venice_dock", "destination": "ragusa_dock", "unlocked_ports": port_ids, "world_width": 5200.0, "world_height": 4300.0})
	for departure_port_id in port_ids:
		var harbor_position = GameData.sea_port_position(str(departure_port_id))
		_check(navigation_map.is_navigable(harbor_position), "%s的海上出生点必须可航行" % GameData.TRADE_PORTS[str(departure_port_id)].name)
		for departure_direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			_check(navigation_map.is_navigable(harbor_position + departure_direction * 24.0), "%s出港后必须能立即向任意方向驾驶，不能被礁区锁在出生点" % GameData.TRADE_PORTS[str(departure_port_id)].name)
	navigation_map.queue_free()
	var level_one_days = int(oceanic_plan.days)
	state.ship.speed = 4
	var fast_oceanic_plan = state.voyage_plan("cape_town_dock")
	_check(is_equal_approx(float(fast_oceanic_plan.speed_knots), 12.5) and int(fast_oceanic_plan.nm_per_day) == 300 and float(fast_oceanic_plan.world_speed) > float(oceanic_plan.world_speed) and int(fast_oceanic_plan.days) < level_one_days, "船型基础速度与帆装等级必须共同缩短贸易日历并提高地图驾驶速度")
	state.ship.speed = 1
	_check(int(coastal_plan.stamina_cost) < int(oceanic_plan.stamina_cost) and int(coastal_plan.dive_chance) < int(oceanic_plan.dive_chance), "远洋必须消耗更多出航体力，同时提供更高的潜水寻宝概率")
	var fleet_state = TestState.new()
	fleet_state.quest_index = GameData.QUESTS.size()
	fleet_state.player.level = 12
	fleet_state.player.location = "alexandria_dock"
	fleet_state.player.silver = 1800
	var old_ship_price = int(fleet_state.player.silver)
	var fleet_purchase = fleet_state.buy_ship("alex_caravel")
	_check(bool(fleet_purchase.get("ok", false)) and fleet_state.owns_ship("alex_caravel") and fleet_state.owned_ship_ids().size() == 2 and int(fleet_state.player.silver) == old_ship_price - int(GameData.SHIP_HULLS.alex_caravel.price), "购买船体必须只扣一次银币并永久加入个人船队")
	var explorer_dive = int(fleet_state.voyage_plan("venice_dock").dive_chance)
	fleet_state.player.location = "venice_dock"
	var switch_back = fleet_state.switch_ship("sea_swallow")
	var silver_before_switch = int(fleet_state.player.silver)
	var switch_explorer = fleet_state.switch_ship("alex_caravel")
	_check(bool(switch_back.get("ok", false)) and bool(switch_explorer.get("ok", false)) and int(fleet_state.player.silver) == silver_before_switch and str(fleet_state.ship.hull_id) == "alex_caravel", "已经拥有的船必须能在任一船坞免费换乘，不能重复收费")
	var starter_dive = int(fleet_state.voyage_plan("ragusa_dock").dive_chance) - fleet_state.ship_dive_bonus()
	_check(explorer_dive >= starter_dive + 6 and fleet_state.ship_dive_bonus() == 6, "探险船专长必须真实提高潜水寻宝概率")
	var cannon_before = fleet_state.ship_cannon_power()
	var cannon_upgrade = fleet_state.upgrade_ship("cannon")
	_check(bool(cannon_upgrade.get("ok", false)) and fleet_state.ship_cannon_power() == cannon_before + 4 and int(fleet_state.ship.cannon_level) == 1, "舰炮改造必须提高海战攻击并记录强化等级")
	fleet_state.begin_voyage("ragusa_dock")
	var fleet_battle = fleet_state.start_battle(fleet_state.sea_enemy_id())
	_check(bool(fleet_battle.get("sea_battle", false)) and str(fleet_battle.get("combatant_name", "")) == "灯塔卡拉维尔" and int(fleet_battle.player_attack) == int(fleet_state.get_stats().attack) + fleet_state.ship_cannon_power() and int(fleet_battle.player_defense) > int(fleet_state.get_stats().defense), "海战必须使用当前座舰、舰炮与船甲加成，不能继续只套用人物攻防")
	var tired_state = TestState.new()
	tired_state.quest_index = GameData.QUESTS.size()
	tired_state.player.location = "venice_dock"
	tired_state.player.hp = int(tired_state.voyage_plan("ragusa_dock").stamina_cost)
	_check(not bool(tired_state.begin_voyage("ragusa_dock").get("ok", true)) and tired_state.active_voyage.is_empty(), "体力不足时不能以0体力离港，必须先休息或使用补给")
	state.player.level = 55
	var veteran_oceanic_plan = state.voyage_plan("cape_town_dock")
	_check(int(veteran_oceanic_plan.threat_count) == 12 and "black_flag_privateer" in veteran_oceanic_plan.enemy_ids, "高等级玩家进入高风险远洋时必须出现十二处巡游威胁并包含私掠舰")
	_check(int(veteran_oceanic_plan.recommended_level) >= 60 and int(veteran_oceanic_plan.recommended_level) <= 64, "高等级远洋威胁必须受大西洋等级段约束，不能与地中海怪物收敛到同一级别")
	var north_sea_plan = state.voyage_plan("venice_dock", "amsterdam_dock")
	var east_asia_plan = state.voyage_plan("yangzhou_dock", "quanzhou_dock")
	var intercontinental_plan = state.voyage_plan("quanzhou_dock", "venice_dock")
	_check("fog_siren" in north_sea_plan.enemy_ids or "drowned_sailor" in north_sea_plan.enemy_ids, "北海航程必须出现雾歌海妖或溺潮水手，不能复用地中海固定敌群：%s" % north_sea_plan)
	_check(Array(east_asia_plan.enemy_ids).size() == 4 and "reef_serpent" in east_asia_plan.enemy_ids, "泉州至扬州近海必须生成四处含礁海长蛇的东亚威胁")
	_check(intercontinental_plan.zone_ids == ["mediterranean", "indian_ocean", "east_asia"] and "印度洋" in str(intercontinental_plan.waters_text), "威尼斯至泉州必须记录完整跨海域航迹")
	var progression_state = TestState.new()
	progression_state.player.level = 40
	progression_state.quest_index = 7
	var early_story_level = progression_state.sea_encounter_level("reef_serpent", "indian_ocean")
	progression_state.quest_index = 68
	var late_story_level = progression_state.sea_encounter_level("reef_serpent", "indian_ocean")
	var zone_levels = []
	for zone_id in ["mediterranean", "africa", "atlantic", "indian_ocean", "east_asia", "north_sea"]:
		zone_levels.append(progression_state.sea_encounter_level("reef_serpent", zone_id))
	_check(late_story_level > early_story_level and zone_levels == [24, 41, 45, 48, 51, 55], "怪物等级必须以海域等级段为主，并只在同一海域内受任务阶段修正：%s" % [zone_levels])
	_check(GameData.sea_level_band_text(["mediterranean", "indian_ocean", "east_asia"]) == "地中海 Lv.5–24 → 印度洋 Lv.38–80 → 东亚海域 Lv.42–96", "航线预览必须明确列出每段海域的等级范围")
	var high_sea_tier = GameData.sea_equipment_tier(60)
	var high_sea_pool = GameData.sea_equipment_pool("indian_ocean", 60)
	_check(str(high_sea_tier.name) == "七海入门装备" and high_sea_pool.has("stormsteel_cutlass") and not high_sea_pool.has("monsoon_boots") and not high_sea_pool.has("seven_seas_compass"), "普通高等级海怪只能掉落套装入门件，不能绕过海域Boss拿到关键缺件")
	for zone_id in GameData.SEA_SET_BOSSES:
		var boss_definition = GameData.sea_set_boss(str(zone_id))
		var set_id = str(boss_definition.set_id)
		var full_pool = GameData.sea_set_drop_pool(str(zone_id), str(boss_definition.enemy_id))
		_check(full_pool.size() == int(GameData.EQUIPMENT_SETS[set_id].total) and full_pool.size() == 6, "%s套装Boss必须覆盖六个可穿戴部位" % GameData.EQUIPMENT_SETS[set_id].name)
		for key_item in Array(GameData.EQUIPMENT_SETS[set_id].boss_only):
			_check(str(key_item) in full_pool, "%s的关键缺件必须只进入对应海域Boss整套池" % GameData.ITEMS[str(key_item)].name)
	var set_boss_state = TestState.new()
	set_boss_state.quest_index = GameData.QUESTS.size()
	set_boss_state.player.level = 10
	set_boss_state.player.location = "venice_dock"
	set_boss_state.begin_voyage("ragusa_dock")
	var set_boss_encounter = {}
	for encounter in Array(set_boss_state.active_voyage.encounters):
		if bool(encounter.get("set_boss", false)):
			set_boss_encounter = Dictionary(encounter)
			break
	_check(not set_boss_encounter.is_empty() and str(set_boss_encounter.get("set_id", "")) == "warrior", "达到解锁等级后，地中海航线必须随机布置可见的武士套装Boss")
	if not set_boss_encounter.is_empty():
		var boss_battle = set_boss_state.start_sea_encounter(str(set_boss_encounter.id))
		_check(str(boss_battle.get("enemy_rank", "")) == "海域 Boss" and str(boss_battle.get("enemy_name", "")) == "赤潮礁王·阿刻隆" and str(boss_battle.get("sea_set_id", "")) == "warrior" and "随机掉落" in str(boss_battle.get("loot_tier_name", "")), "套装Boss战斗必须显示专属名字、海域Boss等级、整套名称与随机掉率")
		set_boss_state.inventory["warrior_blade"] = 1
		var weighted_pool = set_boss_state.sea_set_weighted_drop_pool("warrior")
		_check(weighted_pool.count("warrior_talisman") == 3 and weighted_pool.count("warrior_blade") == 1, "套装Boss掉落池必须让未拥有部件获得三倍权重，同时保留重复装备")
	state.ship.armor = 3
	state.voyage_protection = 1
	var protected_oceanic_plan = state.voyage_plan("cape_town_dock")
	_check(int(protected_oceanic_plan.threat_count) == 11 and int(protected_oceanic_plan.risk) < int(veteran_oceanic_plan.risk), "船体护甲和护航物资必须降低远洋风险与遭遇数量")
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
	var moving_encounter_id = str(Dictionary(state.active_voyage.encounters[0]).id)
	state.update_sea_encounter_position(moving_encounter_id, Vector2(900, 1300))
	_check(Vector2(float(state.sea_encounter(moving_encounter_id).x), float(state.sea_encounter(moving_encounter_id).y)) == Vector2(900, 1300), "主动追击后的敌人位置必须写回航程状态")
	state.update_voyage_position(GameData.sea_port_position("venice_dock").lerp(GameData.sea_port_position("ragusa_dock"), 0.5))
	_check(is_equal_approx(state.voyage_progress(), 0.5) and state.voyage_remaining_distance() == 210, "船位必须换算为真实航程进度与剩余海里")
	var treasure = state.claim_sea_treasure()
	_check(bool(treasure.get("ok", false)) and str(treasure.get("mode", "")) == "salvage" and int(state.player.silver) > initial_silver and not bool(state.claim_sea_treasure().get("ok", true)), "每段航程可选择稳妥打捞，且漂流货箱只能领取一次")
	state.cargo["venetian_glass"] = 2
	state.cargo_costs["venetian_glass"] = 48
	var storm = state.resolve_sea_storm()
	_check(bool(storm.get("ok", false)) and int(state.cargo.get("venetian_glass", 0)) == 1, "未携带护航物资穿越风暴时必须在海域内即时损失货物")
	state.mark_sea_pirate_defeated()
	_check(state.sea_encounters_remaining() == 3 and not bool(state.active_voyage.get("pirate_defeated", true)), "击败一支巡游海盗后必须保留同航线上的其他威胁")
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
	_check(bool(sea_battle.get("ok", false)) and bool(sea_battle.get("dynamic_threat", false)) and str(sea_battle.get("sea_zone_name", "")) == "地中海" and str(sea_battle.get("loot_tier_name", "")) != "", "海域中的可见海盗必须进入动态战斗，并显示海域与装备掉落阶位")
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
		{"origin": "malta_dock", "destination": "cape_town_dock", "level": 30, "quest": 38},
		{"origin": "cape_town_dock", "destination": "quanzhou_dock", "level": 37, "quest": 44},
		{"origin": "quanzhou_dock", "destination": "athens_dock", "level": 44, "quest": 50},
		{"origin": "athens_dock", "destination": "venice_dock", "level": 51, "quest": 56},
		{"origin": "venice_dock", "destination": "yangzhou_dock", "level": 58, "quest": 62},
		{"origin": "yangzhou_dock", "destination": "amsterdam_dock", "level": 65, "quest": 68}
	]:
		var story_state = TestState.new()
		story_state.quest_index = int(milestone.quest)
		story_state.player.location = str(milestone.origin)
		story_state.player.level = int(milestone.level)
		story_state.ship.armor = 1
		var story_plan = story_state.voyage_plan(str(milestone.destination))
		_check(not story_plan.is_empty() and int(story_plan.recommended_level) <= int(milestone.level) + 12, "主线航程%s→%s的高危海域不能生成跨度过大的必经敌人" % [milestone.origin, milestone.destination])
		_check(not ("black_flag_privateer" in Array(story_plan.enemy_ids)) or int(milestone.level) >= 45, "Lv.45前的主线航程不能出现黑旗私掠舰")

	var long_state = TestState.new()
	long_state.quest_index = GameData.QUESTS.size()
	long_state.player.location = "venice_dock"
	long_state.player.level = 55
	long_state.begin_voyage("cape_town_dock")
	_check(Array(long_state.active_voyage.encounters).size() == 12 and long_state.sea_encounters_remaining() == 12, "超长远洋航程必须生成并保存十二处独立遭遇")
	for encounter in Array(long_state.active_voyage.encounters):
		var encounter_data = Dictionary(encounter)
		var encounter_position = Vector2(float(encounter_data.x), float(encounter_data.y))
		_check(str(encounter_data.zone_id) in Array(long_state.active_voyage.zone_ids) and encounter_position.x > 100.0 and encounter_position.x < GameData.SEA_GLOBAL_WORLD_SIZE.x - 100.0 and encounter_position.y > 100.0 and encounter_position.y < GameData.SEA_GLOBAL_WORLD_SIZE.y - 100.0, "海盗与海怪必须分散在大地图航路及对应海域内")
		var encounter_band = GameData.sea_zone_level_band(str(encounter_data.zone_id))
		_check(int(encounter_data.get("threat_level", 0)) >= int(encounter_band.min) and int(encounter_data.get("threat_level", 999)) <= int(encounter_band.max) and str(encounter_data.get("loot_tier_name", "")) != "", "每处海上遭遇必须落在所属海域等级段内，并持久化装备阶位")
	var first_encounter = Dictionary(long_state.active_voyage.encounters[0])
	long_state.mark_sea_encounter_defeated(str(first_encounter.id))
	_check(long_state.sea_encounters_remaining() == 11 and not bool(long_state.active_voyage.pirate_defeated), "击败一处远洋威胁不能错误清空其余敌人")
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
	_check(int(legacy_state.active_voyage.get("distance_nm", 0)) == 420 and float(legacy_state.active_voyage.world_width) == GameData.SEA_GLOBAL_WORLD_SIZE.x and Array(legacy_state.active_voyage.get("encounters", [])).size() == 4 and Dictionary(legacy_state.active_voyage.encounters[0]).has("progress") and Dictionary(legacy_state.active_voyage.encounters[0]).has("threat_level") and int(legacy_state.active_voyage.get("sea_balance_version", 0)) == GameData.SEA_BALANCE_VERSION and bool(legacy_state.active_voyage.get("escorted", false)) and legacy_state.voyage_protection == 0, "旧版进行中航程必须迁移到海域等级段、动态威胁和已准备的护航物资")

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
