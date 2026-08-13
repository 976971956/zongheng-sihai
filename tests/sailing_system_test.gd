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
	var state = TestState.new()
	state.quest_index = GameData.QUESTS.size()
	state.player.level = 8
	state.player.location = "venice_dock"
	state.player.silver = 300
	var initial_silver = int(state.player.silver)
	var initial_day = int(state.trade_day)
	var departure = state.begin_voyage("ragusa_dock")
	_check(bool(departure.get("ok", false)), "正常出航必须能创建进行中的航程")
	_check(str(state.player.location) == "venice_dock" and int(state.player.silver) == initial_silver, "出航后、靠港前必须保留启航港且不收传送费")
	_check(str(state.active_voyage.get("region", "")) == "mediterranean" and state.voyage_position() == Vector2(540, 1580), "威尼斯至拉古萨必须进入地中海并保存船位")
	state.update_voyage_position(Vector2(610, 1240))
	_check(state.voyage_position() == Vector2(610, 1240), "进行中的船位必须可以写入存档状态")
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
