extends SceneTree

const FONT_PATH = "res://assets/fonts/NotoSansCJKsc-GameSubset.otf"
const REQUIRED_TEXT = "纵横四海潮汐纪事人物地点任务背包战斗攻击撤退经验等级威尼斯艾丽莎装备宠物副本未知道具银币黑帆据点外围码头火药仓船长贸易合约舱容强化船甲拉古萨亚历山大猛攻坚守寻宝自动补给剧情回顾持有实际盈亏推荐均价买满全卖"

func _init():
	var font = load(FONT_PATH)
	if font == null:
		push_error("中文字体无法加载：%s" % FONT_PATH)
		quit(1)
		return

	var missing = []
	for character in REQUIRED_TEXT:
		if not font.has_char(character.unicode_at(0)):
			missing.append(character)

	if missing.is_empty():
		print("FONT_OK: iOS 关键中文字形全部可用")
		quit(0)
	else:
		push_error("中文字体缺少字形：%s" % "".join(missing))
		quit(1)
