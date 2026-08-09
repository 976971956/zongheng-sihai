extends SceneTree

class TestState extends GameState:
	func save_game():
		pass

const RUNS = 30
var failures = []
var milestone_losses = {}

func _init():
	for seed_value in range(1001, 1001 + RUNS):
		_run_normal_player(seed_value)
	var total_losses = 0
	for count in milestone_losses.values():
		total_losses += int(count)
	_check(total_losses == 0, "标准成长路线在%d次随机压测中不应出现无法继续的必败节点：%s" % [RUNS, str(milestone_losses)])
	if failures.is_empty():
		print("PLAYABILITY_OK: %d次正常成长压测全部通过，四层试炼与黑帆连战无卡关" % RUNS)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run_normal_player(seed_value):
	var state = TestState.new()
	state.rng.seed = seed_value
	# 剧情交谈与旅行部分在 smoke_test 中已逐步验证；这里按正常顺序领取同样的奖励。
	for quest_id in ["scale_memory", "to_tavern", "tavern_clue"]:
		_complete_current_quest(state, quest_id)
	for _index in range(3):
		_prepare_rest(state)
		if not _fight(state, "drunk_sailor"):
			_record_loss("north_gate")
			return
	_complete_current_quest(state, "north_gate")
	for _index in range(3):
		_prepare_rest(state)
		if not _fight(state, "mine_thief"):
			_record_loss("stolen_ore")
			return
	_complete_current_quest(state, "stolen_ore")
	state.equip_item("warrior_blade")
	state.recruit_companion()
	_prepare_rest(state)
	if not _fight(state, "giant_bear"):
		_record_loss("back_hill_bear")
		return
	_complete_current_quest(state, "back_hill_bear")
	state.equip_item("warrior_coat")
	_prepare_rest(state)
	for enemy_id in ["dungeon_guard", "stone_puppet", "tide_beast", "vermilion_phantom"]:
		if not _fight(state, enemy_id):
			_record_loss("four_floor_trial/%s" % enemy_id)
			return
	_complete_current_quest(state, "four_floor_trial")
	state.equip_item("lion_charm")

	# 贸易章提供大量经验，并引导玩家强化主武器。
	for quest_id in ["first_cargo", "sail_ragusa", "sell_glass"]:
		_complete_current_quest(state, quest_id)
	state.player.silver += 400
	state.upgrade_equipped("weapon")
	_complete_current_quest(state, "forge_for_sea")
	_complete_current_quest(state, "armor_the_swallow")
	_complete_current_quest(state, "black_sail_clue")
	_prepare_rest(state)
	if not _fight(state, "corsair_deckhand"):
		_record_loss("black_sail/deckhand")
		return
	_complete_current_quest(state, "clear_deckhands")
	state.equip_item("corsair_cutlass")
	if not _fight(state, "corsair_raider"):
		_record_loss("black_sail/raider")
		return
	_complete_current_quest(state, "powder_store")
	state.equip_item("gunner_coat")
	if not _fight(state, "corsair_guard"):
		_record_loss("black_sail/guard")
		return
	_complete_current_quest(state, "cave_battery")
	state.equip_item("captain_hat")
	if not _fight(state, "corsair_captain"):
		_record_loss("black_sail/captain")
		return
	_complete_current_quest(state, "captain_ledger")
	_check(int(state.player.level) >= 15, "种子%d：黑帆章结束时应达到Lv.15，实际Lv.%d" % [seed_value, int(state.player.level)])

func _complete_current_quest(state, expected_id):
	var quest = state.get_current_quest()
	_check(not quest.is_empty() and str(quest.id) == expected_id, "压测任务顺序错误：期待%s" % expected_id)
	if quest.is_empty() or str(quest.id) != expected_id:
		return
	state.quest_progress = int(quest.objective.need)
	var result = state.claim_quest()
	_check(bool(result.get("ok", false)), "压测无法领取任务%s" % expected_id)

func _prepare_rest(state):
	state.active_battle = {}
	state.statuses = {}
	state.player.hp = state.get_stats().max_hp

func _fight(state, enemy_id):
	state.player.location = _enemy_location(enemy_id)
	# The stress test compresses an entire route into one frame, so model the
	# normal wait between repeated overworld encounters explicitly.
	state.enemy_respawns.erase(str(enemy_id))
	var start = state.start_battle(enemy_id)
	if not bool(start.get("ok", false)):
		return false
	for _round in range(60):
		state.auto_use_battle_supplies()
		var counter_special = state.battle_focus() >= 3 and str(state.get_enemy_intent()).begins_with("⚠")
		var result = state.skill_attack() if counter_special else state.attack_once()
		if bool(result.get("battle_over", false)):
			return bool(result.get("won", false))
	return false

func _enemy_location(enemy_id):
	for location_id in GameData.LOCATIONS:
		if enemy_id in GameData.LOCATIONS[location_id].enemies:
			return str(location_id)
	return "venice_square"

func _record_loss(milestone):
	milestone_losses[milestone] = int(milestone_losses.get(milestone, 0)) + 1

func _check(condition, message):
	if not condition:
		failures.append(message)
