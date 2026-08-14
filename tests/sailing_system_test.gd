extends SceneTree

class TestState extends GameState:
	func has_save():
		return false

	func save_game():
		pass

var failures = []

func _init():
	call_deferred("_run")

func _run():
	for route_key in GameData.TRADE_ROUTES:
		var route_data = GameData.TRADE_ROUTES[route_key]
		_check(int(route_data.get("distance_nm", 0)) > 0, "每条直达航线都必须配置可展示和计算的海里数：%s" % route_key)
	var state = TestState.new()
	state.quest_index = GameData.QUESTS.size()
	state.player.level = 8
	state.player.location = "venice_dock"
	state.player.silver = 300
	var coastal_plan = state.voyage_plan("ragusa_dock")
	var regional_plan = state.voyage_plan("alexandria_dock")
	var oceanic_plan = state.voyage_plan("cape_town_dock")
	_check(int(coastal_plan.distance_nm) == 420 and str(coastal_plan.tier) == "coastal" and int(coastal_plan.threat_count) == 1, "威尼斯至拉古萨必须是420海里的单威胁近海航程")
	_check(str(regional_plan.tier) == "regional" and int(regional_plan.threat_count) == 2 and "reef_serpent" in regional_plan.enemy_ids, "跨海航线必须同时规划海盗与礁海怪物")
	_check(str(oceanic_plan.tier) == "oceanic" and int(oceanic_plan.threat_count) == 3 and "black_flag_privateer" in oceanic_plan.enemy_ids, "高风险远洋航线必须规划三段分级威胁")
	state.ship.armor = 3
	state.voyage_protection = 1
	var protected_oceanic_plan = state.voyage_plan("cape_town_dock")
	_check(int(protected_oceanic_plan.threat_count) == 2 and int(protected_oceanic_plan.risk) < int(oceanic_plan.risk), "船体护甲和护航物资必须降低远洋风险与遭遇数量")
	state.ship.armor = 0
	state.voyage_protection = 0
	var initial_silver = int(state.player.silver)
	var initial_day = int(state.trade_day)
	var departure = state.begin_voyage("ragusa_dock")
	_check(bool(departure.get("ok", false)), "正常出航必须能创建进行中的航程")
	_check(str(state.player.location) == "venice_dock" and int(state.player.silver) == initial_silver, "出航后、靠港前必须保留启航港且不收传送费")
	_check(str(state.active_voyage.get("region", "")) == "mediterranean" and state.voyage_position() == Vector2(540, 1580), "威尼斯至拉古萨必须进入地中海并保存船位")
	state.update_voyage_position(Vector2(610, 1240))
	_check(state.voyage_position() == Vector2(610, 1240), "进行中的船位必须可以写入存档状态")
	state.update_voyage_position(Vector2(540, 972.5))
	_check(is_equal_approx(state.voyage_progress(), 0.5) and state.voyage_remaining_distance() == 210, "船位必须换算为真实航程进度与剩余海里")
	var treasure = state.claim_sea_treasure()
	_check(bool(treasure.get("ok", false)) and int(state.player.silver) > initial_silver and not bool(state.claim_sea_treasure().get("ok", true)), "每段航程的漂流货箱只能领取一次")
	state.cargo["venetian_glass"] = 2
	state.cargo_costs["venetian_glass"] = 48
	var storm = state.resolve_sea_storm()
	_check(bool(storm.get("ok", false)) and int(state.cargo.get("venetian_glass", 0)) == 1, "未携带护航物资穿越风暴时必须在海域内即时损失货物")
	state.mark_sea_pirate_defeated()
	_check(bool(state.active_voyage.get("pirate_defeated", false)), "击败海盗必须记录在当前航程，防止重复拦截")
	var arrival = state.complete_voyage()
	_check(bool(arrival.get("ok", false)) and str(state.player.location) == "ragusa_dock" and state.active_voyage.is_empty() and int(state.trade_day) > initial_day, "抵港后才应修改港口、推进日期并清空航程")

	state.player.location = "ragusa_dock"
	var transfer_silver = int(state.player.silver)
	var transfer = state.transfer_to("venice_dock")
	_check(bool(transfer.get("ok", false)) and str(state.player.location) == "venice_dock" and int(state.player.silver) < transfer_silver and state.active_voyage.is_empty(), "付费传送必须直接抵港、扣费且不进入海域")

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
	var protected_storm = state.resolve_sea_storm()
	_check(bool(protected_storm.get("protected", false)) and state.voyage_protection == 0, "护航物资必须在真实穿越风暴时消耗并免除损失")
	var origin = str(state.active_voyage.origin)
	var abort = state.abort_voyage()
	_check(bool(abort.get("ok", false)) and str(state.player.location) == origin and state.active_voyage.is_empty(), "玩家必须能放弃航程并返回启航港")

	var long_state = TestState.new()
	long_state.quest_index = GameData.QUESTS.size()
	long_state.player.location = "venice_dock"
	long_state.player.level = 55
	long_state.begin_voyage("cape_town_dock")
	_check(Array(long_state.active_voyage.encounters).size() == 3 and long_state.sea_encounters_remaining() == 3, "远洋航程必须生成并保存三处独立遭遇")
	var first_encounter = Dictionary(long_state.active_voyage.encounters[0])
	long_state.mark_sea_encounter_defeated(str(first_encounter.id))
	_check(long_state.sea_encounters_remaining() == 2 and not bool(long_state.active_voyage.pirate_defeated), "击败一处远洋威胁不能错误清空其余敌人")
	var second_enemy = long_state.sea_enemy_id()
	_check(second_enemy == "abyss_kraken", "击败远洋掠夺者后必须继续面对深海巨章")
	long_state.cargo["venetian_glass"] = 3
	var ocean_storm = long_state.resolve_sea_storm()
	_check(int(ocean_storm.get("lost_count", 0)) == 2 and int(long_state.cargo.get("venetian_glass", 0)) == 1, "未防护的远洋风暴必须损失两单位货物")

	var legacy_state = TestState.new()
	legacy_state.quest_index = GameData.QUESTS.size()
	legacy_state.player.location = "venice_dock"
	legacy_state.active_voyage = {"origin": "venice_dock", "destination": "ragusa_dock", "days": 2, "risk": 14, "x": 540.0, "y": 1200.0, "pirate_defeated": false}
	legacy_state._normalize_active_voyage()
	_check(int(legacy_state.active_voyage.get("distance_nm", 0)) == 420 and Array(legacy_state.active_voyage.get("encounters", [])).size() == 1, "旧版进行中航程必须自动补齐距离、分级和遭遇清单")

	if failures.is_empty():
		print("SAILING_OK: 出航、海域状态、风暴、打捞、靠港、返航与付费传送全部通过")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition, message):
	if not condition:
		failures.append(message)
