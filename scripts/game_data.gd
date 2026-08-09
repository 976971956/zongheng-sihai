class_name GameData
extends RefCounted

# The world is deliberately data-driven: each WAP-style page is a location,
# and the cardinal links form a graph. No location-specific scene is needed.
const LOCATIONS = {
	"alisa_hut": {
		"name": "海边小屋",
		"tag": "剧情地点",
		"chapter": "序章 · 失去的名字",
		"description": "潮声从木窗外传来。你在一张陌生的床上醒来，脑海里只剩翻船前的巨浪，以及水中一片发光的鳞。",
		"flavor": "少女艾丽莎把鳞片放回你的手心。她说，是父亲在海边救了你。",
		"exits": [
			{"to": "venice_tavern", "direction": "东", "label": "沿海路前往威尼斯酒馆", "hint": "主线目的地"}
		],
		"npcs": ["alisa"], "enemies": [], "services": []
	},
	"venice_tavern": {
		"name": "威尼斯 · 老海鸥酒馆",
		"tag": "安全区",
		"chapter": "序章 · 失去的名字",
		"description": "来自各地的水手围在木桌旁，谈论希腊海妖、北海女巫与非洲巨兽。酒馆老板正擦拭一只刻有翼狮的银杯。",
		"flavor": "这里既是消息集散地，也是新冒险者第一次复命的地方。",
		"exits": [
			{"to": "alisa_hut", "direction": "西", "label": "返回海边小屋", "hint": "艾丽莎的家"},
			{"to": "venice_square", "direction": "东", "label": "前往威尼斯广场", "hint": "城内枢纽"}
		],
		"npcs": ["tavern_keeper"], "enemies": [], "services": ["rest", "party"]
	},
	"venice_square": {
		"name": "威尼斯 · 城市广场",
		"tag": "城内地图",
		"chapter": "第一章 · 威尼斯的委托",
		"description": "钟楼的影子落在石板路上。这里连接着酒馆、码头、市场与北城门，公告牌上贴满了委托和通缉令。",
		"flavor": "可以从这里快速查看城内各处，也可以按东南西北逐步行走。",
		"exits": [
			{"to": "venice_tavern", "direction": "西", "label": "老海鸥酒馆", "hint": "休息、组队"},
			{"to": "venice_market", "direction": "东", "label": "海风市场", "hint": "药品与装备"},
			{"to": "venice_dock", "direction": "南", "label": "威尼斯码头", "hint": "船只与航行"},
			{"to": "venice_north_gate", "direction": "北", "label": "北城门", "hint": "城外练级区"}
		],
		"npcs": ["guard_captain"], "enemies": [], "services": ["city_map"]
	},
	"venice_market": {
		"name": "威尼斯 · 海风市场",
		"tag": "商业区",
		"chapter": "第一章 · 威尼斯的委托",
		"description": "狭窄的店铺里堆着奶瓶、万能药、潜水镜与远洋补给。珠宝匠把颜色各异的小宝石铺在深蓝绒布上。",
		"flavor": "原版中，不同城市的商店、珠宝店和市场承担了大部分资源循环。",
		"exits": [
			{"to": "venice_square", "direction": "西", "label": "返回城市广场", "hint": "城内地图"}
		],
		"npcs": ["jeweler"], "enemies": [], "services": ["shop", "identify"]
	},
	"venice_dock": {
		"name": "威尼斯 · 码头",
		"tag": "港口",
		"chapter": "第一章 · 威尼斯的委托",
		"description": "货船沿着栈桥排开，搬运工把玻璃器皿、葡萄酒和布匹装进货舱。船老板正在招呼准备前往北海的旅人。",
		"flavor": "远洋贸易将在完成威尼斯章节后开放；船只速度和货舱会影响航行。",
		"exits": [
			{"to": "venice_square", "direction": "北", "label": "返回城市广场", "hint": "城内地图"}
		],
		"npcs": ["ship_owner"], "enemies": [], "services": ["harbor"]
	},
	"venice_north_gate": {
		"name": "威尼斯 · 北城门",
		"tag": "低危区域",
		"chapter": "第一章 · 威尼斯的委托",
		"description": "城门外的道路被酒桶和破车堵住。几个喝醉的水手拦住过路人索要铜贝，守卫却抽不开身。",
		"flavor": "你看到：喝醉的水手。战斗中每点一次攻击，只推进一个回合。",
		"exits": [
			{"to": "venice_square", "direction": "南", "label": "返回城市广场", "hint": "安全区"},
			{"to": "residential_quarter", "direction": "北", "label": "前往住宅区", "hint": "Lv.1–2"},
			{"to": "training_dungeon_1", "direction": "东", "label": "威尼斯经验副本", "hint": "四层 · Lv.3", "level": 3}
		],
		"npcs": [], "enemies": ["drunk_sailor"], "services": []
	},
	"residential_quarter": {
		"name": "威尼斯 · 住宅区",
		"tag": "低危区域",
		"chapter": "第二章 · 城外迷踪",
		"description": "晾衣绳横过屋顶，废弃水渠通向城墙外。居民抱怨巨鼠出没，矿山运来的工具也接连失窃。",
		"flavor": "你看到：灰毛巨鼠。附近还有通往后山、矿山和荒树林的小路。",
		"exits": [
			{"to": "venice_north_gate", "direction": "南", "label": "返回北城门", "hint": "威尼斯"},
			{"to": "venice_mine", "direction": "东", "label": "前往废矿山", "hint": "Lv.2", "level": 2},
			{"to": "venice_back_hill", "direction": "西", "label": "前往后山", "hint": "首领 · Lv.2", "level": 2},
			{"to": "venice_wildwood", "direction": "北", "label": "前往荒树林", "hint": "状态怪 · Lv.3", "level": 3}
		],
		"npcs": [], "enemies": ["sewer_rat"], "services": []
	},
	"venice_mine": {
		"name": "威尼斯 · 废矿山",
		"tag": "危险区域",
		"chapter": "第二章 · 城外迷踪",
		"description": "矿洞里的轨道被人拆走了一段，火把旁散着沾泥的靴印。偷矿者正把矿石装进没有标记的木箱。",
		"flavor": "偷矿者有概率掉落未知道具，需要回海风市场鉴定。",
		"exits": [
			{"to": "residential_quarter", "direction": "西", "label": "返回住宅区", "hint": "Lv.1–2"}
		],
		"npcs": [], "enemies": ["mine_thief"], "services": []
	},
	"venice_back_hill": {
		"name": "威尼斯 · 后山",
		"tag": "首领区域",
		"chapter": "第二章 · 城外迷踪",
		"description": "林间散落着被拍断的树枝，地面留下巨大的熊掌印。空气中弥漫着令人提不起力气的甜腥气味。",
		"flavor": "巨熊会施加虚弱，降低你的攻击。万能药可以解除不良状态。",
		"exits": [
			{"to": "residential_quarter", "direction": "东", "label": "返回住宅区", "hint": "安全路线"}
		],
		"npcs": [], "enemies": ["giant_bear"], "services": []
	},
	"venice_wildwood": {
		"name": "威尼斯 · 荒树林",
		"tag": "状态区域",
		"chapter": "第二章 · 城外迷踪",
		"description": "枯树上系着褪色的祈祷布，林间的雾气让方向变得模糊。传说这里的幽灵会诅咒来往旅人。",
		"flavor": "幽灵卡片是原版可收集的怪物卡之一，能够提供抗诅咒属性。",
		"exits": [
			{"to": "residential_quarter", "direction": "南", "label": "返回住宅区", "hint": "威尼斯"}
		],
		"npcs": [], "enemies": ["wildwood_ghost"], "services": []
	},
	"training_dungeon_1": {
		"name": "威尼斯经验副本 · 一层",
		"tag": "限时副本",
		"chapter": "第三章 · 四层试炼",
		"description": "翼狮石门在身后闭合。经验副本共有四层，每层都必须击败守卫才能继续深入。",
		"flavor": "副本剩余时间：90分钟（试玩版不做离线倒计时）。",
		"exits": [
			{"to": "venice_north_gate", "direction": "西", "label": "离开副本", "hint": "返回北城门"},
			{"to": "training_dungeon_2", "direction": "北", "label": "前往二层", "hint": "击败一层训练卫兵后开放", "level": 3, "requires_defeat": "dungeon_guard"}
		],
		"npcs": [], "enemies": ["dungeon_guard"], "services": []
	},
	"training_dungeon_2": {
		"name": "威尼斯经验副本 · 二层", "tag": "限时副本", "chapter": "第三章 · 四层试炼",
		"description": "潮湿的石阶向上延伸，旧时代的训练傀儡守在拐角。", "flavor": "副本内仍然通过方向链接逐层前进。",
		"exits": [
			{"to": "training_dungeon_1", "direction": "南", "label": "返回一层", "hint": "副本入口"},
			{"to": "training_dungeon_3", "direction": "北", "label": "前往三层", "hint": "击败二层石傀儡后开放", "level": 3, "requires_defeat": "stone_puppet"}
		], "npcs": [], "enemies": ["stone_puppet"], "services": []
	},
	"training_dungeon_3": {
		"name": "威尼斯经验副本 · 三层", "tag": "限时副本", "chapter": "第三章 · 四层试炼",
		"description": "第三层的墙面布满爪痕，守卫兽伏在石柱后等待闯入者。", "flavor": "这里是当前版本最适合重复练级的地点。",
		"exits": [
			{"to": "training_dungeon_2", "direction": "南", "label": "返回二层", "hint": "副本"},
			{"to": "training_dungeon_4", "direction": "北", "label": "前往四层", "hint": "击败潮汐兽后开放 · Boss · 建议装备主线武士套", "level": 4, "requires_defeat": "tide_beast"}
		], "npcs": [], "enemies": ["tide_beast"], "services": []
	},
	"training_dungeon_4": {
		"name": "威尼斯经验副本 · 四层", "tag": "Boss层", "chapter": "第三章 · 四层试炼",
		"description": "红色火光照亮圆形大厅。朱雀的幻影展开双翼，等待完成试炼的冒险者。", "flavor": "击败朱雀可获得大量经验，并必定得到武士套部件。",
		"exits": [
			{"to": "training_dungeon_3", "direction": "南", "label": "返回三层", "hint": "副本"},
			{"to": "venice_north_gate", "direction": "西", "label": "离开副本", "hint": "返回北城门"}
		], "npcs": [], "enemies": ["vermilion_phantom"], "services": []
	},
	"ragusa_dock": {
		"name": "拉古萨 · 石墙港",
		"tag": "贸易港",
		"chapter": "远洋篇 · 亚得里亚航线",
		"description": "高耸的石墙守着天然深港。来自巴尔干内陆的羊毛与橄榄油在仓栈中堆成小山。",
		"flavor": "拉古萨盛产羊毛布与橄榄油，威尼斯玻璃在这里很受欢迎。通过港口柜台可返回其他城市。",
		"exits": [],
		"npcs": ["ragusa_broker"], "enemies": [], "services": ["harbor"]
	},
	"alexandria_dock": {
		"name": "亚历山大 · 灯塔港",
		"tag": "贸易港",
		"chapter": "远洋篇 · 地中海航线",
		"description": "沙色仓库沿海岸铺开，香料、油料和玻璃器皿在不同语言的叫卖声中成交。",
		"flavor": "亚历山大香料价格低，但返航路程更长。留足航费，别让满舱货物困在异乡。",
		"exits": [],
		"npcs": ["alexandria_merchant"], "enemies": [], "services": ["harbor"]
	},
	"malta_dock": {
		"name": "马耳他 · 蜂蜜石港", "tag": "贸易港", "chapter": "第七章 · 白鲸残影",
		"description": "金色石墙围住深蓝海湾，渔船与商船挤满港池。白鲸号的旧船钟被悬在仓栈门口，每逢退潮便会自己响起。",
		"flavor": "马耳他盛产柑橘，也保留着白鲸号最后一批船员的名册。港口厨房可把贸易货物烹制成远航补给。",
		"exits": [], "npcs": ["malta_keeper"], "enemies": [], "services": ["harbor", "cook"]
	},
	"cape_town_dock": {
		"name": "开普敦 · 风暴角港", "tag": "远征港", "chapter": "第十章 · 北河迷踪",
		"description": "桌山压在云层之下，两股洋流在港外交锋。来自贝河的金砂让所有人的眼睛都亮了起来。", "flavor": "这里是聚宝盆传说与北河远征的起点。",
		"exits": [], "npcs": ["cape_keeper"], "enemies": [], "services": ["harbor"]
	},
	"quanzhou_dock": {
		"name": "泉州 · 刺桐港", "tag": "远征港", "chapter": "第十三章 · 妖气东来",
		"description": "蕃坊钟声与海船号子交叠。沈砚正在核对一批从长安逃出的封妖文书。", "flavor": "丝绸和茶叶从这里进入全球商路。",
		"exits": [], "npcs": ["quanzhou_scholar"], "enemies": [], "services": ["harbor"]
	},
	"athens_dock": {
		"name": "雅典 · 银帆港", "tag": "远征港", "chapter": "第十六章 · 地魔宝藏",
		"description": "古老石柱俯瞰海湾，祭司卡珊德拉把潮汐星盘嵌进一块裂开的地脉石。", "flavor": "葡萄酒与古卷是这里最受欢迎的货物。",
		"exits": [], "npcs": ["athens_oracle"], "enemies": [], "services": ["harbor"]
	},
	"yangzhou_dock": {
		"name": "扬州 · 运河月港", "tag": "远征港", "chapter": "第二十二章 · 天魔传奇",
		"description": "月光沿运河铺成银路，织师苏绫守着一架能把记忆织进绢纱的古机。", "flavor": "玉纱与瓷器把东方故事带往远海。",
		"exits": [], "npcs": ["yangzhou_weaver"], "enemies": [], "services": ["harbor"]
	},
	"amsterdam_dock": {
		"name": "阿姆斯特丹 · 风车港", "tag": "远征港", "chapter": "第二十五章 · 玉历宝纱",
		"description": "运河仓库里堆着来自七海的拍卖品，制图师范德海正在寻找基德船长缺失的藏宝图角。", "flavor": "精密仪器与羊毛布在这里形成稳定商路。",
		"exits": [], "npcs": ["amsterdam_cartographer"], "enemies": [], "services": ["harbor"]
	},
	"black_sail_1": {
		"name": "黑帆据点 · 外围码头", "tag": "远洋副本", "chapter": "第二章 · 黑帆密令",
		"description": "被遗弃的海蚀洞里搭起了走私码头，黑帆水手正在搬运从商船上劫来的货箱。", "flavor": "击败外围守卫后才能深入据点。",
		"exits": [{"to": "black_sail_2", "direction": "北", "label": "进入火药仓", "requires_defeat": "corsair_deckhand"}], "npcs": [], "enemies": ["corsair_deckhand"], "services": []
	},
	"black_sail_2": {
		"name": "黑帆据点 · 火药仓", "tag": "远洋副本", "chapter": "第二章 · 黑帆密令",
		"description": "岩壁间堆满受潮的火药桶，一名黑帆袭击者守住狭窄栈桥。", "flavor": "猛攻可以快速解决敌人，但火药仓里更适合谨慎作战。",
		"exits": [{"to": "black_sail_3", "direction": "北", "label": "前往炮台", "requires_defeat": "corsair_raider"}], "npcs": [], "enemies": ["corsair_raider"], "services": []
	},
	"black_sail_3": {
		"name": "黑帆据点 · 洞窟炮台", "tag": "远洋副本", "chapter": "第二章 · 黑帆密令",
		"description": "一门旧舰炮对准洞口，黑帆重卫披着从各国掠来的混制甲胄。", "flavor": "重卫每三回合会发动破阵冲锋。",
		"exits": [{"to": "black_sail_4", "direction": "北", "label": "登上船长厅", "requires_defeat": "corsair_guard"}], "npcs": [], "enemies": ["corsair_guard"], "services": []
	},
	"black_sail_4": {
		"name": "黑帆据点 · 船长厅", "tag": "Boss区域", "chapter": "第二章 · 黑帆密令",
		"description": "洞窟尽头停着一艘没有桅杆的黑船。船长雷蒙正等待追踪而来的航者。", "flavor": "击败雷蒙，夺回记载神秘鳞片航线的黑帆海图。",
		"exits": [], "npcs": [], "enemies": ["corsair_captain"], "services": []
	},
	"white_whale_1": {
		"name": "白鲸残骸 · 礁岸", "tag": "远洋副本", "chapter": "第七章 · 白鲸残影",
		"description": "白色龙骨横卧在礁石间，破碎船壳随浪起伏。甲板蟹盘踞在唯一还能落脚的登船板上。", "flavor": "击败礁岸守卫后才能进入残骸。",
		"exits": [{"to": "white_whale_2", "direction": "北", "label": "登上倾斜甲板", "requires_defeat": "wreck_crab"}], "npcs": [], "enemies": ["wreck_crab"], "services": []
	},
	"white_whale_2": {
		"name": "白鲸残骸 · 沉水甲板", "tag": "远洋副本", "chapter": "第八章 · 马耳他盛宴",
		"description": "海水漫过半截船舱，旧日水手的影子仍在重复最后一次值夜。", "flavor": "潮水会拖慢脚步，餐食补给能让长战更稳定。",
		"exits": [{"to": "white_whale_1", "direction": "南", "label": "返回礁岸"}, {"to": "white_whale_3", "direction": "北", "label": "进入雾锁货舱", "requires_defeat": "drowned_sailor"}], "npcs": [], "enemies": ["drowned_sailor"], "services": []
	},
	"white_whale_3": {
		"name": "白鲸残骸 · 雾锁货舱", "tag": "远洋副本", "chapter": "第九章 · 寻裔之路",
		"description": "来自各港的货箱被白雾封住，歌声从龙骨深处传来，诱人忘记归路。", "flavor": "雾歌海妖会施加诅咒，万能药可以解除异常状态。",
		"exits": [{"to": "white_whale_2", "direction": "南", "label": "返回沉水甲板"}, {"to": "white_whale_4", "direction": "北", "label": "前往鲸心船舱", "requires_defeat": "fog_siren"}], "npcs": [], "enemies": ["fog_siren"], "services": []
	},
	"white_whale_4": {
		"name": "白鲸残骸 · 鲸心船舱", "tag": "Boss区域", "chapter": "第九章 · 寻裔之路",
		"description": "船钟、星图与发光鳞片同时共鸣。深渊海妖守着一封未能送达马耳他的家书。", "flavor": "击败深渊海妖，找回白鲸号失踪者留下的证词。",
		"exits": [{"to": "white_whale_3", "direction": "南", "label": "返回雾锁货舱"}], "npcs": [], "enemies": ["abyss_siren"], "services": []
	},
	"legacy_basin": {"name": "北河遗迹 · 聚宝盆", "tag": "终局远征", "chapter": "第十一章 · 聚宝盆", "description": "贝河在石窟中央倒流，金砂围绕一只吞吐潮光的巨兽旋转。", "flavor": "击败北河吞金兽，夺回被欲望吞没的航海日志。", "exits": [], "npcs": [], "enemies": ["basin_leviathan"], "services": []},
	"legacy_changan": {"name": "长安幻城 · 镇妖台", "tag": "终局远征", "chapter": "第十四章 · 妖气长安", "description": "海市蜃楼在沙海上重现长安夜市，九尾妖狐以失踪者的记忆点亮灯笼。", "flavor": "守住自己的名字，才能看破幻城。", "exits": [], "npcs": [], "enemies": ["nine_tail_fox"], "services": []},
	"legacy_earth": {"name": "地脉王陵 · 藏金殿", "tag": "终局远征", "chapter": "第十七章 · 地魔宝藏", "description": "裂开的地脉深处埋着一座倒悬王陵，地魔王把每一件宝物都变成锁链。", "flavor": "真正的宝藏是让航路重见天日。", "exits": [], "npcs": [], "enemies": ["earth_demon_king"], "services": []},
	"legacy_tira": {"name": "潮刃圣所 · 蒂拉剑冢", "tag": "终局远征", "chapter": "第二十章 · 蒂拉之剑", "description": "万柄断剑插在退潮后的海床，守剑人只认可不被力量支配的航者。", "flavor": "在海潮合拢前赢得蒂拉之剑。", "exits": [], "npcs": [], "enemies": ["tira_guardian"], "services": []},
	"legacy_demon_legend": {"name": "天外裂隙 · 魔星门", "tag": "终局远征", "chapter": "第二十三章 · 天魔传奇", "description": "玉纱上映出的星图撕开天空，第一位天魔将军从裂隙中踏出。", "flavor": "天魔不是传说，而是追逐潮门而来的远古舰队。", "exits": [], "npcs": [], "enemies": ["celestial_demon_general"], "services": []},
	"legacy_jade": {"name": "月织秘境 · 玉历纱庭", "tag": "终局远征", "chapter": "第二十六章 · 玉历宝纱", "description": "每根玉丝都记录一段被修改的历史，织梦妖后藏在最美的一幅假象里。", "flavor": "找回真实年历，才能定位天魔回航的日期。", "exits": [], "npcs": [], "enemies": ["jade_dream_queen"], "services": []},
	"legacy_fire": {"name": "黑炉海堡 · 炉心", "tag": "终局远征", "chapter": "第二十九章 · 釜底抽薪", "description": "天魔舰队的黑炉以掠夺来的潮能为燃料，整座海堡都在像心脏一样搏动。", "flavor": "摧毁炉心，切断天魔舰队的补给。", "exits": [], "npcs": [], "enemies": ["black_furnace_lord"], "services": []},
	"legacy_return": {"name": "归潮天门 · 风暴眼", "tag": "终局远征", "chapter": "第三十二章 · 天魔归来", "description": "被切断补给的天魔王仍强行穿越潮门，九座港口的灯火同时黯淡。", "flavor": "这场战斗决定七海是否还有明天。", "exits": [], "npcs": [], "enemies": ["returned_demon_king"], "services": []},
	"legacy_shears": {"name": "天工坊 · 命线台", "tag": "终局远征", "chapter": "第三十五章 · 天工神剪", "description": "命运之线缠住破碎潮门，傀儡天工师试图剪去所有曾经反抗天魔的人。", "flavor": "夺回神剪，修补而非删去这段历史。", "exits": [], "npcs": [], "enemies": ["clockwork_tailor"], "services": []},
	"legacy_seal": {"name": "封印迷阵 · 潮汐之心", "tag": "最终远征", "chapter": "第三十八章 · 封印迷阵", "description": "十三卷航海日志在阵心展开。卡西安必须决定：永远封死潮门，还是让七海共同守护它。", "flavor": "最终战将检验一路建立的信任、装备与航海意志。", "exits": [], "npcs": [], "enemies": ["tide_void_emperor"], "services": []}
}

const NPCS = {
	"alisa": {"name": "艾丽莎", "role": "救命恩人", "dialogue": "父亲在沙滩上发现了你。你什么都不记得了吗？拿好这片鳞，去威尼斯酒馆问问老板吧。"},
	"tavern_keeper": {"name": "酒馆老板", "role": "主线复命人", "dialogue": "这片鳞来自很深的海域。想知道自己是谁，先证明你能在这片大陆活下去——北门正缺人手。"},
	"guard_captain": {"name": "守卫队长", "role": "城市守卫", "dialogue": "城内地图能带你快速去往各处。出了北门，可就要留意自己的体力和状态了。"},
	"jeweler": {"name": "珠宝匠贝里昂", "role": "鉴定与宝石", "dialogue": "怪物身上掉下来的未知道具，只有鉴定后才知道属性。真正的宝石系统要到后面才会开放。"},
	"ship_owner": {"name": "船老板", "role": "船只与航行", "dialogue": "完成威尼斯试炼后，我会把海燕号交给你。比较各港价格、控制货舱，再决定把银币压在哪批货上。"},
	"ragusa_broker": {"name": "拉古萨经纪人", "role": "港口商人", "dialogue": "这里的羊毛和橄榄油便宜。若你从威尼斯带来玻璃，我能给出不错的价钱。"},
	"alexandria_merchant": {"name": "香料商萨米尔", "role": "港口商人", "dialogue": "季风改变的不只是航期，也会改变香料的价格。低买高卖，但别忘了返航的费用。"},
	"malta_keeper": {"name": "伊莎贝拉", "role": "白鲸号守钟人", "dialogue": "我守着这口船钟，也守着一份二十年没人敢读完的名册。若你真要寻找白鲸号，就先学会让同行的人平安吃上一顿饭。"},
	"cape_keeper": {"name": "阿曼达", "role": "北河向导", "dialogue": "风暴角不相信传说，只相信能从北河活着回来的人。"},
	"quanzhou_scholar": {"name": "沈砚", "role": "封妖录守卷人", "dialogue": "海上的妖气与长安旧案来自同一道裂隙，我一直在等星盘的持有者。"},
	"athens_oracle": {"name": "卡珊德拉", "role": "地脉祭司", "dialogue": "石柱记得海水尚未到来之前的战争，蒂拉之剑也仍在等待主人。"},
	"yangzhou_weaver": {"name": "苏绫", "role": "玉纱织师", "dialogue": "丝线会说谎，但断口不会。让我看看你从潮门带回的历史。"},
	"amsterdam_cartographer": {"name": "范德海", "role": "七海制图师", "dialogue": "基德的藏宝图从来不是指向黄金，而是指向天魔舰队的补给航线。"}
}

const TRADE_PORTS = {
	"venice_dock": {"name": "威尼斯", "specialty": "玻璃器皿", "note": "玻璃便宜，香料昂贵"},
	"ragusa_dock": {"name": "拉古萨", "specialty": "羊毛布", "note": "羊毛与橄榄油价格较低"},
	"alexandria_dock": {"name": "亚历山大", "specialty": "东方香料", "note": "香料便宜，玻璃需求旺盛"},
	"malta_dock": {"name": "马耳他", "specialty": "金岛柑橘", "note": "柑橘便宜，可在港口厨房制作远航餐食"},
	"cape_town_dock": {"name": "开普敦", "specialty": "橄榄油", "note": "远洋补给需求旺盛", "npc": "cape_keeper"},
	"quanzhou_dock": {"name": "泉州", "specialty": "东方香料", "note": "香料与柑橘适合向西远销", "npc": "quanzhou_scholar"},
	"athens_dock": {"name": "雅典", "specialty": "橄榄油", "note": "玻璃和羊毛价格稳定", "npc": "athens_oracle"},
	"yangzhou_dock": {"name": "扬州", "specialty": "羊毛布", "note": "远海货物在运河口溢价明显", "npc": "yangzhou_weaver"},
	"amsterdam_dock": {"name": "阿姆斯特丹", "specialty": "威尼斯玻璃", "note": "北海商会大量收购香料", "npc": "amsterdam_cartographer"}
}

const TRADE_GOODS = {
	"venetian_glass": {"name": "威尼斯玻璃", "unit": "箱", "space": 2, "prices": {"venice_dock": 24, "ragusa_dock": 46, "alexandria_dock": 61, "malta_dock": 52, "cape_town_dock": 74, "quanzhou_dock": 66, "athens_dock": 48, "yangzhou_dock": 71, "amsterdam_dock": 39}},
	"wool_cloth": {"name": "羊毛布", "unit": "捆", "space": 1, "prices": {"venice_dock": 43, "ragusa_dock": 25, "alexandria_dock": 47, "malta_dock": 42, "cape_town_dock": 58, "quanzhou_dock": 55, "athens_dock": 38, "yangzhou_dock": 62, "amsterdam_dock": 28}},
	"olive_oil": {"name": "橄榄油", "unit": "桶", "space": 2, "prices": {"venice_dock": 48, "ragusa_dock": 30, "alexandria_dock": 24, "malta_dock": 28, "cape_town_dock": 34, "quanzhou_dock": 63, "athens_dock": 22, "yangzhou_dock": 68, "amsterdam_dock": 54}},
	"spices": {"name": "东方香料", "unit": "袋", "space": 1, "prices": {"venice_dock": 82, "ragusa_dock": 61, "alexandria_dock": 35, "malta_dock": 57, "cape_town_dock": 76, "quanzhou_dock": 31, "athens_dock": 69, "yangzhou_dock": 39, "amsterdam_dock": 91}},
	"citrus": {"name": "金岛柑橘", "unit": "筐", "space": 1, "prices": {"venice_dock": 42, "ragusa_dock": 38, "alexandria_dock": 45, "malta_dock": 20, "cape_town_dock": 52, "quanzhou_dock": 37, "athens_dock": 44, "yangzhou_dock": 49, "amsterdam_dock": 58}}
}

const TRADE_ROUTES = {
	"ragusa_dock|venice_dock": {"days": 2, "fee": 14, "risk": 14},
	"alexandria_dock|venice_dock": {"days": 5, "fee": 30, "risk": 30},
	"alexandria_dock|ragusa_dock": {"days": 4, "fee": 24, "risk": 24},
	"malta_dock|venice_dock": {"days": 4, "fee": 26, "risk": 24},
	"malta_dock|ragusa_dock": {"days": 3, "fee": 20, "risk": 20},
	"alexandria_dock|malta_dock": {"days": 3, "fee": 22, "risk": 22}
	,"cape_town_dock|malta_dock": {"days": 8, "fee": 52, "risk": 38}
	,"cape_town_dock|quanzhou_dock": {"days": 10, "fee": 66, "risk": 42}
	,"athens_dock|quanzhou_dock": {"days": 7, "fee": 44, "risk": 32}
	,"athens_dock|venice_dock": {"days": 3, "fee": 20, "risk": 18}
	,"venice_dock|yangzhou_dock": {"days": 9, "fee": 58, "risk": 38}
	,"amsterdam_dock|yangzhou_dock": {"days": 8, "fee": 50, "risk": 34}
	,"amsterdam_dock|venice_dock": {"days": 4, "fee": 28, "risk": 22}
	,"quanzhou_dock|venice_dock": {"days": 8, "fee": 50, "risk": 36}
	,"athens_dock|yangzhou_dock": {"days": 7, "fee": 46, "risk": 32}
	,"cape_town_dock|venice_dock": {"days": 9, "fee": 60, "risk": 40}
	,"amsterdam_dock|quanzhou_dock": {"days": 9, "fee": 58, "risk": 38}
	,"quanzhou_dock|yangzhou_dock": {"days": 3, "fee": 18, "risk": 16}
}

const TRADE_EVENTS = [
	{"name": "风平浪静", "description": "各港行情保持稳定。", "port": "", "good": "", "multiplier": 1.0},
	{"name": "威尼斯庆典", "description": "威尼斯庆典大量收购东方香料。", "port": "venice_dock", "good": "spices", "multiplier": 1.30},
	{"name": "拉古萨纺织季", "description": "拉古萨羊毛集中上市，采购价下降。", "port": "ragusa_dock", "good": "wool_cloth", "multiplier": 0.78},
	{"name": "亚历山大宫廷订单", "description": "亚历山大贵族高价征集威尼斯玻璃。", "port": "alexandria_dock", "good": "venetian_glass", "multiplier": 1.28},
	{"name": "橄榄丰收", "description": "拉古萨橄榄油丰收，市场供应充足。", "port": "ragusa_dock", "good": "olive_oil", "multiplier": 0.76},
	{"name": "金岛丰收祭", "description": "马耳他柑橘集中上市，适合采购远销。", "port": "malta_dock", "good": "citrus", "multiplier": 0.74}
]

const RECIPES = {
	"maltese_stew": {"name": "马耳他海风炖汤", "port": "malta_dock", "cargo": {"olive_oil": 1, "spices": 1, "citrus": 2}, "silver": 5, "result": "maltese_stew", "description": "恢复体力，并在接下来3场战斗中获得攻击、防御和体力加成。"}
}

const EXPEDITIONS = {
	"basin": {"name": "聚宝盆·北河远征", "port": "cape_town_dock", "location": "legacy_basin", "enemy": "basin_leviathan", "min_level": 30, "quest_start": 38},
	"changan": {"name": "妖气长安", "port": "quanzhou_dock", "location": "legacy_changan", "enemy": "nine_tail_fox", "min_level": 37, "quest_start": 44},
	"earth": {"name": "地魔宝藏", "port": "athens_dock", "location": "legacy_earth", "enemy": "earth_demon_king", "min_level": 44, "quest_start": 50},
	"tira": {"name": "蒂拉之剑", "port": "venice_dock", "location": "legacy_tira", "enemy": "tira_guardian", "min_level": 51, "quest_start": 56},
	"demon_legend": {"name": "天魔传奇", "port": "yangzhou_dock", "location": "legacy_demon_legend", "enemy": "celestial_demon_general", "min_level": 58, "quest_start": 62},
	"jade": {"name": "玉历宝纱", "port": "amsterdam_dock", "location": "legacy_jade", "enemy": "jade_dream_queen", "min_level": 65, "quest_start": 68},
	"fire": {"name": "釜底抽薪", "port": "venice_dock", "location": "legacy_fire", "enemy": "black_furnace_lord", "min_level": 72, "quest_start": 74},
	"return": {"name": "天魔归来", "port": "quanzhou_dock", "location": "legacy_return", "enemy": "returned_demon_king", "min_level": 79, "quest_start": 80},
	"shears": {"name": "天工神剪", "port": "athens_dock", "location": "legacy_shears", "enemy": "clockwork_tailor", "min_level": 86, "quest_start": 86},
	"seal": {"name": "封印迷阵", "port": "yangzhou_dock", "location": "legacy_seal", "enemy": "tide_void_emperor", "min_level": 93, "quest_start": 92}
}

# 港口订单兼顾剧情委托与可重复跑商。剧情订单优先显示，完成后各港会继续轮换日常委托。
const TRADE_ORDERS = {
	"alexandria_lighthouse_glass": {"title": "灯塔修缮急单", "port": "alexandria_dock", "good": "venetian_glass", "amount": 3, "bonus": 150, "reputation": 2, "description": "灯塔镜室急需耐高温的威尼斯玻璃。"},
	"ragusa_lamp_oil": {"title": "石墙港灯油", "port": "ragusa_dock", "good": "olive_oil", "amount": 4, "bonus": 125, "reputation": 2, "description": "城墙守夜人要在风季前补足灯油。"},
	"venice_tide_medicine": {"title": "潮汐药引", "port": "venice_dock", "good": "spices", "amount": 4, "bonus": 180, "reputation": 2, "description": "酒馆医师要用东方香料配制唤醒旧记忆的药剂。"},
	"venice_spice_feast": {"title": "翼狮庆典香料", "port": "venice_dock", "good": "spices", "amount": 3, "bonus": 90, "reputation": 2, "description": "庆典厨房高价收购三袋东方香料。"},
	"venice_wool_uniforms": {"title": "卫队冬装", "port": "venice_dock", "good": "wool_cloth", "amount": 4, "bonus": 80, "reputation": 2, "description": "城防队为冬季巡逻订购羊毛布。"},
	"ragusa_glass_banquet": {"title": "总督玻璃宴具", "port": "ragusa_dock", "good": "venetian_glass", "amount": 2, "bonus": 85, "reputation": 2, "description": "总督府宴会需要一批威尼斯玻璃器皿。"},
	"ragusa_spice_fair": {"title": "商队香料会", "port": "ragusa_dock", "good": "spices", "amount": 3, "bonus": 100, "reputation": 2, "description": "陆路商队正在收购便于转运的香料。"},
	"alexandria_wool_sails": {"title": "红海船队帆布", "port": "alexandria_dock", "good": "wool_cloth", "amount": 4, "bonus": 120, "reputation": 2, "description": "远航船队需要结实的羊毛帆布。"},
	"alexandria_palace_glass": {"title": "宫廷彩窗", "port": "alexandria_dock", "good": "venetian_glass", "amount": 2, "bonus": 135, "reputation": 2, "description": "宫廷工匠正在修补一组彩色玻璃窗。"},
	"malta_citrus_fleet": {"title": "舰队防坏血病补给", "port": "malta_dock", "good": "citrus", "amount": 5, "bonus": 115, "reputation": 2, "description": "巡航舰队需要新鲜柑橘补充远航餐食。"},
	"malta_glass_lanterns": {"title": "守钟塔风灯", "port": "malta_dock", "good": "venetian_glass", "amount": 2, "bonus": 125, "reputation": 2, "description": "守钟塔需要经得住海风的新玻璃灯罩。"}
	,"basin_supplies": {"title": "北河驱兽香", "port": "cape_town_dock", "good": "spices", "amount": 4, "bonus": 420, "reputation": 3, "description": "向导队需要香料驱散北河洞窟中的毒虫。"}
	,"changan_seals": {"title": "镇妖镜片", "port": "quanzhou_dock", "good": "venetian_glass", "amount": 3, "bonus": 520, "reputation": 3, "description": "沈砚要用纯净玻璃重制照破妖气的古镜。"}
	,"earth_lamps": {"title": "地脉长明油", "port": "athens_dock", "good": "olive_oil", "amount": 4, "bonus": 620, "reputation": 3, "description": "王陵远征需要不会被地气吹灭的祭灯。"}
	,"tira_forge": {"title": "剑冢裹刃布", "port": "venice_dock", "good": "wool_cloth", "amount": 4, "bonus": 720, "reputation": 3, "description": "旧锻炉需要厚布包裹刚出潮火的剑刃。"}
	,"demon_sails": {"title": "裂隙观测镜", "port": "yangzhou_dock", "good": "venetian_glass", "amount": 3, "bonus": 820, "reputation": 3, "description": "玉纱织师需要镜片观测天魔舰队穿越裂隙的轨迹。"}
	,"jade_calendar": {"title": "玉历醒梦香", "port": "amsterdam_dock", "good": "spices", "amount": 4, "bonus": 920, "reputation": 3, "description": "制图师用不同香气标记被篡改的年份。"}
	,"furnace_decoy": {"title": "黑炉冷却果", "port": "venice_dock", "good": "citrus", "amount": 5, "bonus": 1020, "reputation": 3, "description": "柑橘酸液能暂时冷却黑炉的潮能管线。"}
	,"return_wards": {"title": "九港结界帆", "port": "quanzhou_dock", "good": "wool_cloth", "amount": 5, "bonus": 1120, "reputation": 3, "description": "九港共同缝制抵御天魔风暴的结界帆。"}
	,"shears_alloy": {"title": "神剪淬光镜", "port": "athens_dock", "good": "venetian_glass", "amount": 4, "bonus": 1220, "reputation": 3, "description": "祭司要把潮光折入天工神剪的断刃。"}
	,"seal_threads": {"title": "封印定神香", "port": "yangzhou_dock", "good": "spices", "amount": 5, "bonus": 1400, "reputation": 4, "description": "最终迷阵需要九港香火同时点燃，稳定所有守阵者的记忆。"}
}

const PORT_ORDER_ROTATION = {
	"venice_dock": ["venice_spice_feast", "venice_wool_uniforms"],
	"ragusa_dock": ["ragusa_glass_banquet", "ragusa_spice_fair"],
	"alexandria_dock": ["alexandria_wool_sails", "alexandria_palace_glass"],
	"malta_dock": ["malta_citrus_fleet", "malta_glass_lanterns"]
	,"cape_town_dock": ["basin_supplies"]
	,"quanzhou_dock": ["changan_seals", "return_wards"]
	,"athens_dock": ["earth_lamps", "shears_alloy"]
	,"yangzhou_dock": ["demon_sails", "seal_threads"]
	,"amsterdam_dock": ["jade_calendar"]
}

const ENEMIES = {
	"drunk_sailor": {"name": "喝醉的水手", "level": 1, "rank": "普通", "hp": 42, "attack": 8, "defense": 2, "speed": 4, "exp": 22, "silver": [6, 11], "drops": ["unknown_equipment", "small_milk"], "intro": "醉醺醺的水手举起酒瓶，摇晃着向你冲来。"},
	"sewer_rat": {"name": "灰毛巨鼠", "level": 1, "rank": "普通", "hp": 34, "attack": 7, "defense": 1, "speed": 7, "exp": 18, "silver": [4, 8], "drops": ["unknown_equipment", "sea_salt_bread"], "effect": {"name": "中毒", "chance": 0.12, "rounds": 3}, "intro": "巨鼠从废水渠里钻出，牙齿上泛着绿色液光。"},
	"mine_thief": {"name": "偷矿者", "level": 2, "rank": "普通", "hp": 66, "attack": 12, "defense": 4, "speed": 7, "exp": 34, "silver": [10, 17], "drops": ["unknown_equipment", "spider_knife", "small_milk"], "effect": {"name": "缓慢", "chance": 0.14, "rounds": 2}, "intro": "偷矿者丢下矿袋，挥舞铁镐挡住去路。"},
	"giant_bear": {"name": "后山巨熊", "level": 3, "rank": "首领", "hp": 128, "attack": 17, "defense": 7, "speed": 5, "exp": 72, "silver": [28, 41], "drops": ["warrior_blade", "warrior_coat", "warrior_belt", "bear_card"], "effect": {"name": "虚弱", "chance": 0.28, "rounds": 3}, "special": {"name": "裂地重击", "every": 3, "damage_multiplier": 1.45}, "intro": "巨熊人立而起，沉重的吼声让你感到四肢发软。"},
	"wildwood_ghost": {"name": "荒林幽灵", "level": 3, "rank": "精英", "hp": 104, "attack": 16, "defense": 6, "speed": 11, "exp": 58, "silver": [20, 32], "drops": ["ghost_card", "unknown_equipment", "universal_medicine"], "effect": {"name": "诅咒", "chance": 0.22, "rounds": 3}, "intro": "雾气凝成人影，冰冷的低语直接钻进你的脑海。"},
	"dungeon_guard": {"name": "一层训练卫兵", "level": 3, "rank": "副本", "hp": 92, "attack": 14, "defense": 6, "speed": 7, "exp": 48, "silver": [16, 24], "drops": ["unknown_equipment", "small_milk"], "intro": "卫兵幻影举起长矛，试炼开始。"},
	"stone_puppet": {"name": "二层石傀儡", "level": 3, "rank": "副本", "hp": 126, "attack": 15, "defense": 10, "speed": 3, "exp": 61, "silver": [19, 28], "drops": ["warrior_belt", "unknown_equipment"], "intro": "石傀儡胸前的符文依次亮起。"},
	"tide_beast": {"name": "三层潮汐兽", "level": 4, "rank": "副本精英", "hp": 158, "attack": 20, "defense": 9, "speed": 10, "exp": 82, "silver": [27, 39], "drops": ["warrior_circlet", "warrior_boots", "stamina_tonic", "tide_card"], "effect": {"name": "缓慢", "chance": 0.20, "rounds": 2}, "special": {"name": "潮汐突袭", "every": 3, "damage_multiplier": 1.35}, "intro": "潮汐兽跃出积水，鳞片像刀刃般张开。"},
	"vermilion_phantom": {"name": "朱雀幻影", "level": 4, "rank": "副本 Boss", "hp": 218, "attack": 22, "defense": 11, "speed": 12, "exp": 150, "silver": [58, 82], "drops": ["warrior_blade", "warrior_coat", "warrior_circlet", "warrior_belt", "warrior_boots"], "effect": {"name": "中毒", "chance": 0.18, "rounds": 3}, "special": {"name": "赤焰风暴", "every": 3, "damage_multiplier": 1.55}, "intro": "赤色双翼遮住穹顶，朱雀幻影发出清越长鸣。"}
	,"corsair_deckhand": {"name": "黑帆水手", "level": 6, "rank": "副本", "hp": 190, "attack": 25, "defense": 12, "speed": 11, "exp": 150, "silver": [42, 58], "drops": ["unknown_equipment", "small_milk", "corsair_cutlass"], "intro": "黑帆水手踢开货箱，拔出弯刀封住码头。"}
	,"corsair_raider": {"name": "黑帆袭击者", "level": 8, "rank": "副本精英", "hp": 260, "attack": 31, "defense": 16, "speed": 16, "exp": 230, "silver": [58, 78], "drops": ["corsair_cutlass", "gunner_coat", "universal_medicine", "corsair_card"], "effect": {"name": "中毒", "chance": 0.16, "rounds": 3}, "intro": "袭击者在火药桶之间疾行，淬毒短刃闪着冷光。"}
	,"corsair_guard": {"name": "黑帆重卫", "level": 10, "rank": "副本精英", "hp": 380, "attack": 38, "defense": 24, "speed": 12, "exp": 340, "silver": [78, 108], "drops": ["gunner_coat", "captain_hat", "stamina_tonic"], "special": {"name": "破阵冲锋", "every": 3, "damage_multiplier": 1.40}, "intro": "重卫架起盾牌，沉重脚步震落洞顶的细沙。"}
	,"corsair_captain": {"name": "黑帆船长雷蒙", "level": 12, "rank": "副本 Boss", "hp": 620, "attack": 48, "defense": 29, "speed": 18, "exp": 620, "silver": [150, 210], "drops": ["corsair_cutlass", "gunner_coat", "captain_hat", "black_sail_charm"], "effect": {"name": "诅咒", "chance": 0.20, "rounds": 3}, "special": {"name": "黑潮连斩", "every": 3, "damage_multiplier": 1.60}, "intro": "雷蒙展开黑帆海图，拔剑宣告这里将是你的终点。"}
	,"wreck_crab": {"name": "覆甲礁蟹", "level": 21, "rank": "副本", "hp": 640, "attack": 48, "defense": 32, "speed": 16, "exp": 1100, "silver": [120, 170], "drops": ["stamina_tonic", "whale_bone_sabre"], "intro": "覆满船钉的巨蟹从白鲸号龙骨下爬出，铁螯砸向礁石。"}
	,"drowned_sailor": {"name": "溺潮水手", "level": 24, "rank": "副本精英", "hp": 760, "attack": 54, "defense": 36, "speed": 23, "exp": 1500, "silver": [150, 210], "drops": ["survivor_coat", "universal_medicine"], "effect": {"name": "缓慢", "chance": 0.20, "rounds": 2}, "intro": "水手幻影攥着腐朽缆绳，仍在执行二十年前没有完成的封舱命令。"}
	,"fog_siren": {"name": "雾歌海妖", "level": 27, "rank": "副本精英", "hp": 900, "attack": 60, "defense": 40, "speed": 31, "exp": 2100, "silver": [190, 260], "drops": ["siren_charm", "stamina_tonic"], "effect": {"name": "诅咒", "chance": 0.24, "rounds": 3}, "intro": "白雾凝成披着船帆的身影，歌声正一点点抹去你的名字。"}
	,"abyss_siren": {"name": "深渊海妖·涅瑞娅", "level": 29, "rank": "副本 Boss", "hp": 1120, "attack": 68, "defense": 45, "speed": 36, "exp": 3500, "silver": [320, 430], "drops": ["whale_bone_sabre", "survivor_coat", "siren_charm"], "effect": {"name": "诅咒", "chance": 0.28, "rounds": 3}, "special": {"name": "鲸落挽歌", "every": 3, "damage_multiplier": 1.48}, "intro": "涅瑞娅从鲸心船舱升起。她身后的潮水里，映出白鲸号沉没的最后一夜。"}
	,"basin_leviathan": {"name": "北河吞金兽", "level": 36, "rank": "副本 Boss", "hp": 1500, "attack": 78, "defense": 55, "speed": 39, "exp": 9000, "silver": [520, 680], "drops": ["basin_charm"], "effect": {"name": "中毒", "chance": 0.20, "rounds": 3}, "special": {"name": "金砂洪流", "every": 3, "damage_multiplier": 1.42}, "intro": "吞金兽卷起整条北河的金砂，聚宝盆在它胸口像第二颗心脏般搏动。"}
	,"nine_tail_fox": {"name": "九尾灯妖·妲罗", "level": 43, "rank": "副本 Boss", "hp": 1800, "attack": 90, "defense": 65, "speed": 48, "exp": 12000, "silver": [680, 860], "drops": ["demon_mask"], "effect": {"name": "诅咒", "chance": 0.24, "rounds": 3}, "special": {"name": "长安幻夜", "every": 3, "damage_multiplier": 1.44}, "intro": "九盏妖灯同时亮起，妲罗用你最珍惜的记忆编织出第十条尾巴。"}
	,"earth_demon_king": {"name": "地魔王·摩罗", "level": 50, "rank": "副本 Boss", "hp": 2200, "attack": 103, "defense": 76, "speed": 51, "exp": 15000, "silver": [850, 1050], "drops": ["earth_armor"], "effect": {"name": "缓慢", "chance": 0.25, "rounds": 2}, "special": {"name": "王陵崩塌", "every": 3, "damage_multiplier": 1.46}, "intro": "倒悬王陵落下碎石，摩罗拖着由黄金与誓言熔成的锁链走出黑暗。"}
	,"tira_guardian": {"name": "蒂拉守剑人", "level": 57, "rank": "副本 Boss", "hp": 2600, "attack": 116, "defense": 88, "speed": 60, "exp": 18000, "silver": [1020, 1250], "drops": ["tira_sword"], "special": {"name": "万刃归潮", "every": 3, "damage_multiplier": 1.48}, "intro": "守剑人拔起唯一完整的剑。潮水中的万柄断刃随之指向你。"}
	,"celestial_demon_general": {"name": "天魔将·破军", "level": 64, "rank": "副本 Boss", "hp": 3000, "attack": 130, "defense": 100, "speed": 68, "exp": 21000, "silver": [1220, 1480], "drops": ["celestial_belt"], "effect": {"name": "虚弱", "chance": 0.25, "rounds": 3}, "special": {"name": "魔星坠海", "every": 3, "damage_multiplier": 1.50}, "intro": "破军的铠甲映出陌生星空。他宣告七海只是天魔舰队下一处停泊地。"}
	,"jade_dream_queen": {"name": "织梦妖后", "level": 71, "rank": "副本 Boss", "hp": 3450, "attack": 144, "defense": 112, "speed": 77, "exp": 24000, "silver": [1450, 1720], "drops": ["jade_boots"], "effect": {"name": "诅咒", "chance": 0.27, "rounds": 3}, "special": {"name": "玉历倒转", "every": 3, "damage_multiplier": 1.50}, "intro": "妖后拨动玉丝，试图把你所有胜利改写成从未发生。"}
	,"black_furnace_lord": {"name": "黑炉领主", "level": 78, "rank": "副本 Boss", "hp": 3900, "attack": 158, "defense": 125, "speed": 83, "exp": 27000, "silver": [1700, 1980], "drops": ["furnace_core"], "effect": {"name": "中毒", "chance": 0.27, "rounds": 3}, "special": {"name": "炉心爆燃", "every": 3, "damage_multiplier": 1.52}, "intro": "黑炉领主扯断冷却管线，滚烫潮能把海堡的阴影烧成赤红。"}
	,"returned_demon_king": {"name": "归来天魔王", "level": 85, "rank": "副本 Boss", "hp": 4400, "attack": 172, "defense": 138, "speed": 92, "exp": 30000, "silver": [1950, 2260], "drops": ["demon_crown"], "effect": {"name": "虚弱", "chance": 0.28, "rounds": 3}, "special": {"name": "九港寂灭", "every": 3, "damage_multiplier": 1.54}, "intro": "天魔王强行挤过破碎潮门，九港灯火在他举手时一盏接一盏熄灭。"}
	,"clockwork_tailor": {"name": "傀儡天工师", "level": 92, "rank": "副本 Boss", "hp": 4950, "attack": 187, "defense": 152, "speed": 101, "exp": 34000, "silver": [2250, 2580], "drops": ["divine_shears"], "effect": {"name": "缓慢", "chance": 0.28, "rounds": 2}, "special": {"name": "剪断命线", "every": 3, "damage_multiplier": 1.55}, "intro": "天工师张开六条机关臂，每一柄剪刀都夹着一个同伴逐渐消失的名字。"}
	,"tide_void_emperor": {"name": "潮虚帝", "level": 99, "rank": "副本 Boss", "hp": 5600, "attack": 202, "defense": 168, "speed": 110, "exp": 40000, "silver": [2800, 3300], "drops": ["tidekeeper_regalia"], "effect": {"name": "诅咒", "chance": 0.30, "rounds": 3}, "special": {"name": "终潮归零", "every": 3, "damage_multiplier": 1.58}, "intro": "所有潮门的阴影汇成一位无面帝王。它要抹去海洋、陆地以及你一路找回的名字。"}
}

const ITEMS = {
	"rusty_sabre": {"name": "旧海军弯刀", "type": "equipment", "slot": "weapon", "rarity": "普通", "description": "失事后仅剩的防身武器。", "stats": {"attack": 3}, "price": 0},
	"linen_cap": {"name": "亚麻水手帽", "type": "equipment", "slot": "head", "rarity": "普通", "description": "威尼斯常见的水手帽。", "stats": {"max_hp": 8, "defense": 1}, "price": 24},
	"traveler_boots": {"name": "远行者短靴", "type": "equipment", "slot": "boots", "rarity": "优秀", "description": "鞋底缝着防滑铜钉。", "stats": {"defense": 2, "speed": 2}, "price": 48},
	"bronze_charm": {"name": "旧港铜符", "type": "equipment", "slot": "charm", "rarity": "优秀", "description": "刻着威尼斯翼狮纹章。", "stats": {"max_hp": 14, "attack": 1}, "price": 70},
	"guard_belt": {"name": "教官腰带", "type": "equipment", "slot": "waist", "rarity": "优秀", "description": "旧训练场教官使用的腰带。", "stats": {"defense": 2}, "drop_bonus": 0.03, "price": 55},
	"spider_knife": {"name": "蜘蛛毒刀", "type": "equipment", "slot": "weapon", "rarity": "优秀", "description": "前期常用的掉落装备。", "stats": {"attack": 6}, "drop_bonus": 0.04, "price": 75},
	"warrior_blade": {"name": "武士刃", "type": "equipment", "slot": "weapon", "rarity": "珍稀", "set": "warrior", "description": "武士套装之一，提高攻击与物品掉落。", "stats": {"attack": 10, "speed": 2}, "drop_bonus": 0.04, "price": 180},
	"warrior_coat": {"name": "武士战衣", "type": "equipment", "slot": "body", "rarity": "珍稀", "set": "warrior", "description": "武士套装防具。", "stats": {"max_hp": 30, "defense": 7}, "drop_bonus": 0.04, "price": 180},
	"warrior_circlet": {"name": "武士额冠", "type": "equipment", "slot": "head", "rarity": "珍稀", "set": "warrior", "description": "嵌着淡蓝玻璃珠。", "stats": {"max_hp": 18, "defense": 4}, "drop_bonus": 0.04, "price": 150},
	"warrior_belt": {"name": "武士绑腿", "type": "equipment", "slot": "waist", "rarity": "珍稀", "set": "warrior", "description": "便于长途跋涉的轻便护具。", "stats": {"max_hp": 12, "defense": 3}, "drop_bonus": 0.04, "price": 150},
	"warrior_boots": {"name": "武士战靴", "type": "equipment", "slot": "boots", "rarity": "珍稀", "set": "warrior", "description": "落步几乎无声。", "stats": {"defense": 3, "speed": 5}, "drop_bonus": 0.04, "price": 150},
	"lion_charm": {"name": "翼狮之誓", "type": "equipment", "slot": "charm", "rarity": "史诗", "description": "完成威尼斯试炼的证明。", "stats": {"max_hp": 28, "attack": 5, "defense": 3}, "price": 320},
	"ghost_card": {"name": "普通·幽灵卡片", "type": "card", "rarity": "珍稀", "description": "启用后抗诅咒几率提高50%，并提高3点防御。", "card_effect": "ghost", "price": 120},
	"bear_card": {"name": "精英·巨熊卡片", "type": "card", "rarity": "史诗", "description": "启用后最大体力提高8%，适合坚守与Boss战。", "card_effect": "bear", "price": 220},
	"tide_card": {"name": "精英·潮汐兽卡片", "type": "card", "rarity": "史诗", "description": "启用后速度+4，抗缓慢几率提高50%。", "card_effect": "tide", "price": 260},
	"corsair_card": {"name": "精英·黑帆卡片", "type": "card", "rarity": "史诗", "description": "启用后攻击+4，航行风险降低4%。", "card_effect": "corsair", "price": 320},
	"unknown_equipment": {"name": "未知道具", "type": "mystery", "rarity": "未知", "description": "回海风市场花费 5 银币鉴定，可能发现一件装备。", "price": 0},
	"small_milk": {"name": "小奶瓶", "type": "consumable", "rarity": "补给", "description": "恢复 45 点体力，可在战斗中使用。", "heal": 45, "price": 18},
	"sea_salt_bread": {"name": "肉夹馍", "type": "consumable", "rarity": "补给", "description": "恢复 24 点体力。", "heal": 24, "price": 9},
	"stamina_tonic": {"name": "体力宝", "type": "consumable", "rarity": "稀有补给", "description": "恢复 160 点体力。", "heal": 160, "price": 200},
	"universal_medicine": {"name": "万能药", "type": "consumable", "rarity": "补给", "description": "解除中毒、虚弱、缓慢和诅咒。", "heal": 0, "cure_status": true, "price": 16}
	,"corsair_cutlass": {"name": "黑帆弯刀", "type": "equipment", "slot": "weapon", "rarity": "史诗", "description": "从远洋海盗手中缴获的弯刀。", "stats": {"attack": 18, "speed": 3}, "price": 360}
	,"gunner_coat": {"name": "炮手皮甲", "type": "equipment", "slot": "body", "rarity": "史诗", "description": "内衬缝有防止火星灼伤的厚皮。", "stats": {"max_hp": 48, "defense": 12}, "price": 390}
	,"captain_hat": {"name": "黑帆船长帽", "type": "equipment", "slot": "head", "rarity": "史诗", "description": "帽檐下藏着一枚被刮去图案的徽章。", "stats": {"max_hp": 26, "defense": 7, "speed": 4}, "price": 420}
	,"black_sail_charm": {"name": "黑帆航路仪", "type": "equipment", "slot": "charm", "rarity": "传说", "description": "记录神秘鳞片航路的精密仪器。", "stats": {"max_hp": 55, "attack": 9, "defense": 7, "speed": 5}, "price": 680}
	,"tide_seal": {"name": "潮纹银章", "type": "equipment", "slot": "charm", "rarity": "传说", "description": "艾丽莎父亲留下的银章，背面刻着你失去的名字。", "stats": {"max_hp": 70, "attack": 12, "defense": 8, "speed": 6}, "price": 880}
	,"lighthouse_compass": {"name": "灯塔星盘", "type": "equipment", "slot": "charm", "rarity": "传说", "description": "萨米尔从灯塔密室取出的星盘，指针会追随发光鳞片的潮汐。", "stats": {"max_hp": 92, "attack": 16, "defense": 11, "speed": 9}, "price": 1280}
	,"maltese_stew": {"name": "马耳他海风炖汤", "type": "consumable", "rarity": "远航餐食", "description": "恢复160点体力；接下来3场战斗最大体力+45、攻击+6、防御+3。", "heal": 160, "meal_battles": 3, "price": 120}
	,"whale_bone_sabre": {"name": "白鲸骨刃", "type": "equipment", "slot": "weapon", "rarity": "传说", "description": "以白鲸号断裂龙骨与潮纹钢重铸的长刃。", "stats": {"attack": 26, "speed": 5}, "price": 1450}
	,"survivor_coat": {"name": "遗航者外套", "type": "equipment", "slot": "body", "rarity": "传说", "description": "衣袋里仍缝着白鲸号船员名册的一角。", "stats": {"max_hp": 78, "defense": 18, "speed": 3}, "price": 1520}
	,"siren_charm": {"name": "雾歌耳坠", "type": "equipment", "slot": "charm", "rarity": "传说", "description": "雾歌海妖凝成的水晶，使持有者不再迷失于海雾。", "stats": {"max_hp": 105, "attack": 19, "defense": 14, "speed": 11}, "price": 1780}
	,"white_whale_coat": {"name": "白鲸守望衣", "type": "equipment", "slot": "body", "rarity": "神话", "description": "伊莎贝拉依照先祖遗图缝制的航海衣，内衬记录着下一段北河航路。", "stats": {"max_hp": 120, "attack": 7, "defense": 24, "speed": 5}, "price": 2280}
	,"basin_charm": {"name": "聚宝潮盆", "type": "equipment", "slot": "charm", "rarity": "神话", "description": "不再吞噬欲望的聚宝盆，会把远征者的勇气化为潮光。", "stats": {"max_hp": 150, "attack": 28, "defense": 22, "speed": 12}, "price": 3200}
	,"demon_mask": {"name": "镇妖明光冠", "type": "equipment", "slot": "head", "rarity": "神话", "description": "由照妖镜片重铸，能让佩戴者看穿幻城。", "stats": {"max_hp": 115, "attack": 16, "defense": 28, "speed": 15}, "price": 3900}
	,"earth_armor": {"name": "地魔镇岳甲", "type": "equipment", "slot": "body", "rarity": "神话", "description": "卸去黄金锁链后留下的地脉重甲。", "stats": {"max_hp": 230, "attack": 12, "defense": 42, "speed": 6}, "price": 4700}
	,"tira_sword": {"name": "蒂拉之剑", "type": "equipment", "slot": "weapon", "rarity": "神话", "description": "只服从不被力量支配之人的潮刃。", "stats": {"attack": 54, "defense": 10, "speed": 17}, "price": 5600}
	,"celestial_belt": {"name": "破军星环", "type": "equipment", "slot": "waist", "rarity": "神话", "description": "天魔将坠落后留下的星轨腰环。", "stats": {"max_hp": 140, "attack": 24, "defense": 30, "speed": 19}, "price": 6600}
	,"jade_boots": {"name": "玉历踏月靴", "type": "equipment", "slot": "boots", "rarity": "神话", "description": "每一步都踏在真实发生过的历史上。", "stats": {"max_hp": 125, "attack": 15, "defense": 26, "speed": 34}, "price": 7700}
	,"furnace_core": {"name": "熄火炉心", "type": "equipment", "slot": "charm", "rarity": "神话", "description": "黑炉熄灭后凝成的冷核，蕴含被释放的潮能。", "stats": {"max_hp": 260, "attack": 45, "defense": 38, "speed": 22}, "price": 8900}
	,"demon_crown": {"name": "九港守夜冠", "type": "equipment", "slot": "head", "rarity": "神话", "description": "九港居民共同重铸的王冠，不属于任何一位国王。", "stats": {"max_hp": 210, "attack": 32, "defense": 48, "speed": 25}, "price": 10200}
	,"divine_shears": {"name": "天工神剪", "type": "equipment", "slot": "weapon", "rarity": "神话", "description": "能剪断谎言，也能把破裂的命运重新裁合。", "stats": {"max_hp": 160, "attack": 78, "defense": 20, "speed": 29}, "price": 11800}
	,"tidekeeper_regalia": {"name": "四海守潮圣装", "type": "equipment", "slot": "body", "rarity": "唯一", "description": "十三卷航海日志与九港誓言共同织成的最终圣装。", "stats": {"max_hp": 420, "attack": 42, "defense": 72, "speed": 32}, "price": 15000}
}

const IDENTIFY_POOL = ["linen_cap", "traveler_boots", "bronze_charm", "guard_belt", "spider_knife"]

const PETS = {
	"moon_tiger": {"name": "月虎", "level": 1, "description": "攻防均衡的原始宠物。每回合会在主人攻击后自动协战。"}
}

const QUEST_DIALOGUES = {
	"scale_memory|alisa": "你终于醒了。父亲在沙滩上发现你时，你手里紧紧攅着这片发光的鳞。去问问老海鸥酒馆的老板吧，他见过的船比我们见过的人还多。",
	"tavern_clue|tavern_keeper": "这不是普通的鱼鳞。二十年前，一支没有旗帜的船队带着同样的光经过威尼斯。想追上它，先证明你能在北门活下来。",
	"return_chart|tavern_keeper": "雷蒙只是替人守着这张图。你看，黑帆航线的终点不在走私洞，而在亚历山大灯塔之下。先回去见艾丽莎。她一直有件事没告诉你。",
	"alisa_truth|alisa": "对不起。父亲救起你后就带着另一片鳞出海，再也没有回来。他留下这枚银章，说只有拿回黑帆海图的人才能看见背面的字。现在它亮了——卡西安。那是你的名字。",
	"lighthouse_letter|tavern_keeper": "卡西安，亚历山大的萨米尔托船带来一封密信。灯塔昨夜亮起了和你鳞片一样的蓝光。别只带剑去——准备三箱威尼斯玻璃，商人更愿意对能解决问题的人开口。",
	"samir_testimony|alexandria_merchant": "艾丽莎的父亲来过这里。他让人封住灯塔地下的潮门，又把开启它的星图拆成三份，交给三港最可信的商会。先帮我修好灯塔镜室，我才敢把第一份交给你。",
	"keeper_return|tavern_keeper": "三港印记已经在星盘上合为一体。艾丽莎的父亲并非葬身海上——最后一封账簿写着，他搭乘‘白鲸号’去了马耳他。卡西安，你找回名字只是开始，下一次潮门开启时，我们就去找他。"
	,"white_whale_news|alisa": "父亲临行前一直在修一口旧船钟。他说白鲸号不是一艘船，而是一群彼此承诺要回家的人。带上星盘去马耳他，找到守钟人伊莎贝拉。"
	,"meet_isabella|malta_keeper": "星盘认出了你。可是白鲸号残骸被海妖的雾困住了，空着肚子进去只会成为下一道影子。把柑橘、香料和橄榄油带来，我教你做船员们最后那顿炖汤。"
	,"heir_testimony|malta_keeper": "这封家书证明父亲救下了最后一名白鲸后裔。那个人就是我的祖母。你父亲随后向南追查北河潮门——卡西安，我们都不是孤身的遗民。穿上这件守望衣，下一程去开普敦。"
	,"meet_amanda|cape_keeper": "你父亲没有拿走北河一粒金砂。他说聚宝盆最危险的不是怪物，而是让人相信一切都能标价。先把远征队平安送进石窟。"
	,"basin_return|cape_keeper": "日志写着：‘东方的妖气开始模仿长安灯火。若我回不来，把星盘送往泉州沈家。’去吧，季风已经转向。"
	,"meet_shenyan|quanzhou_scholar": "封妖录里没有海妖，却记着一座会漂洋过海的长安。妖气在寻找潮门，而你父亲一直在它前面封路。"
	,"changan_return|quanzhou_scholar": "妲罗只是地脉裂隙投下的影子。镇妖镜指向雅典——那里埋着给天魔打造第一批武器的王陵。"
	,"meet_oracle_earth|athens_oracle": "石头说，你已经拒绝过一次黄金。地魔王会让宝藏变成锁链，唯有点亮长明灯的人能看见出口。"
	,"earth_return|athens_oracle": "壁画中的潮刃叫蒂拉。它不属于英雄，只属于愿意在胜利后把剑放下的人。下一次大退潮，它会在威尼斯露出剑冢。"
	,"meet_keeper_tira|tavern_keeper": "守剑人会用力量试探你，也会用恐惧试探你。别证明你比他强，证明你仍记得为何拔剑。"
	,"tira_return|tavern_keeper": "所谓天魔不是神话。他们是第一批发现潮门、也第一批想独占潮门的人。无旗船队正是为了阻止他们才消失。"
	,"meet_suling_demon|yangzhou_weaver": "把剑放在玉纱上。看，裂隙不是伤口，是一条被刻意隐藏的航路；有人还从年历里剪掉了舰队回来的那一天。"
	,"demon_legend_return|yangzhou_weaver": "星环上的日期和玉纱对不上。缺失的年份被卖进了阿姆斯特丹拍卖行，基德船长曾试图把它偷回来。"
	,"meet_vander_jade|amsterdam_cartographer": "基德把黄金留给传说，把真正的图藏在账簿边角。拼上星环后，它指向的不是宝库，是被改写的历史。"
	,"jade_return|amsterdam_cartographer": "玉历恢复了：天魔舰队靠威尼斯外海的黑炉跨越潮门。正面迎战只会无穷无尽，熄掉炉心才是答案。"
	,"meet_keeper_fire|tavern_keeper": "九港已经答应同时断航。你潜入炉心，我们守住海面。卡西安，这一次没有哪座港口让你独自出发。"
	,"fire_return|tavern_keeper": "炉心熄灭了，但天魔王抛下整支舰队强闯潮门。九港灯火正在变暗——去泉州，沈砚能把它们连成结界。"
	,"meet_shenyan_return|quanzhou_scholar": "九盏灯不是九道防线，是九个人彼此看得见的证明。结界帆升起后，你只管走进风暴眼，背后交给四海。"
	,"return_home|quanzhou_scholar": "封妖录最后一页刚刚出现：天魔王不是封印的主人，只是从裂缝漏出的影子。我们需要能修补命线的天工神剪。"
	,"meet_oracle_shears|athens_oracle": "神剪不该剪掉历史，它应该裁去谎言，再把断裂的部分缝回去。天工师忘了这一点，所以成了自己的傀儡。"
	,"shears_return|athens_oracle": "神剪完整了。十三卷日志也终于承认彼此属于同一段故事。带它们去扬州，苏绫会织出迷阵的入口。"
	,"meet_suling_seal|yangzhou_weaver": "你一路找回的不是一把钥匙，而是愿意共同守门的人。九港誓言已在纱上，迷阵不会再只压在一个名字上。"
	,"seal_epilogue|yangzhou_weaver": "听，九港钟声同时响了。潮门没有被永远封死，也不再被任何王者独占。卡西安，从今天起，你终于可以为自己选择下一次出航。"
}

const BOUNTIES = [
	{"id": "rat_cleanup", "title": "水渠清理", "target": "sewer_rat", "need": 3, "silver": 55, "exp": 45, "description": "威尼斯居民请你清理住宅区水渠的巨鼠。"},
	{"id": "mine_patrol", "title": "矿山巡查", "target": "mine_thief", "need": 2, "silver": 78, "exp": 70, "description": "商会希望废矿山的运输线保持畅通。"},
	{"id": "bear_hunt", "title": "巨熊踪迹", "target": "giant_bear", "need": 1, "silver": 105, "exp": 95, "description": "后山再次出现巨大熊掌印，酒馆发出紧急悬赏。"},
	{"id": "ghost_watch", "title": "荒林守夜", "target": "wildwood_ghost", "need": 1, "silver": 118, "exp": 110, "description": "守夜人听到荒树林中再次传来诅咒低语。"}
]

const DISCOVERIES = {
	"alisa_shell": {"name": "潮声贝壳", "region": "city", "location": "alisa_hut", "silver": 18, "item": "sea_salt_bread", "lore": "贝壳里传出一段断续歌声：‘潮来时忘记名字，潮退时寻回航路。’"},
	"field_cache": {"name": "废弃补给箱", "region": "field", "location": "residential_quarter", "silver": 32, "item": "small_milk", "lore": "箱底压着黑色帆布的一角，上面绘着被刀痕划掉的灯塔。"},
	"trial_relic": {"name": "翼狮训练徽章", "region": "dungeon", "location": "training_dungeon_2", "silver": 45, "item": "universal_medicine", "lore": "徽章背面刻着：‘真正的试炼不是胜利，而是知道何时坚守。’"},
	"corsair_manifest": {"name": "黑帆货运清单", "region": "black_sail", "location": "black_sail_3", "silver": 90, "item": "unknown_equipment", "lore": "清单上的真正雇主被写成‘灯塔下的人’，雷蒙似乎也只是棋子。"}
}

const EARLY_QUESTS = [
	{"id": "scale_memory", "title": "发光的鳞", "story": "先向救起你的艾丽莎询问经过。", "objective": {"type": "talk", "target": "alisa", "need": 1}, "reward": {"exp": 12, "silver": 8, "item": "small_milk"}},
	{"id": "to_tavern", "title": "前往威尼斯", "story": "按照艾丽莎的建议，沿海路前往威尼斯酒馆。", "objective": {"type": "visit", "target": "venice_tavern", "need": 1}, "reward": {"exp": 15, "silver": 12, "item": "sea_salt_bread"}},
	{"id": "tavern_clue", "title": "酒馆老板的线索", "story": "把发光的鳞交给酒馆老板，请他辨认来历。", "objective": {"type": "talk", "target": "tavern_keeper", "need": 1}, "reward": {"exp": 18, "silver": 18, "item": "universal_medicine"}},
	{"id": "north_gate", "title": "北门的麻烦", "story": "击退拦路的喝醉水手，替守卫恢复道路秩序。", "objective": {"type": "kill", "target": "drunk_sailor", "need": 3}, "reward": {"exp": 42, "silver": 36, "item": "linen_cap"}},
	{"id": "stolen_ore", "title": "失窃的矿石", "story": "前往住宅区东面的废矿山，击败偷矿者。", "objective": {"type": "kill", "target": "mine_thief", "need": 3}, "reward": {"exp": 68, "silver": 55, "item": "warrior_blade", "companion": true}},
	{"id": "back_hill_bear", "title": "后山巨熊", "story": "居民需要一条安全的山路。击败会施加虚弱的后山巨熊。", "objective": {"type": "kill", "target": "giant_bear", "need": 1}, "reward": {"exp": 92, "silver": 80, "item": "warrior_coat", "pet": "moon_tiger"}},
	{"id": "four_floor_trial", "title": "四层试炼", "story": "进入北城门的经验副本，登上第四层并击败朱雀幻影。", "objective": {"type": "kill", "target": "vermilion_phantom", "need": 1}, "reward": {"exp": 180, "silver": 160, "item": "lion_charm"}}
	,{"id": "first_cargo", "title": "第一批货物", "story": "前往威尼斯码头，在市场买入两箱威尼斯玻璃。", "objective": {"type": "trade_buy", "target": "venetian_glass", "need": 2}, "reward": {"exp": 300, "silver": 80, "item": "small_milk"}}
	,{"id": "sail_ragusa", "title": "扬帆拉古萨", "story": "驾驶海燕号抵达拉古萨，熟悉第一条跨港航线。", "objective": {"type": "visit", "target": "ragusa_dock", "need": 1}, "reward": {"exp": 400, "silver": 100}}
	,{"id": "sell_glass", "title": "玻璃商路", "story": "在拉古萨出售两箱威尼斯玻璃，完成第一笔远洋生意。", "objective": {"type": "trade_sell", "target": "venetian_glass", "need": 2}, "reward": {"exp": 600, "silver": 140, "item": "unknown_equipment"}}
	,{"id": "forge_for_sea", "title": "远洋武装", "story": "使用贸易赚得的银币，将手持武器强化一次。", "objective": {"type": "upgrade_equipment", "target": "weapon", "need": 1}, "reward": {"exp": 800, "silver": 180, "item": "universal_medicine"}}
	,{"id": "armor_the_swallow", "title": "加固海燕号", "story": "升级一次船体护甲，为危险航线做好准备。", "objective": {"type": "upgrade_ship", "target": "armor", "need": 1}, "reward": {"exp": 1000, "silver": 220}}
	,{"id": "black_sail_clue", "title": "黑帆密令", "story": "根据商会提供的线索，进入黑帆据点外围码头。", "objective": {"type": "visit", "target": "black_sail_1", "need": 1}, "reward": {"exp": 1200, "silver": 160, "item": "small_milk"}}
	,{"id": "clear_deckhands", "title": "夺回货箱", "story": "击败看守货箱的黑帆水手长，夺回被劫的商会货物。", "objective": {"type": "kill", "target": "corsair_deckhand", "need": 1}, "reward": {"exp": 1600, "silver": 240, "item": "corsair_cutlass"}}
	,{"id": "powder_store", "title": "潜入火药仓", "story": "深入据点并击败黑帆袭击者。", "objective": {"type": "kill", "target": "corsair_raider", "need": 1}, "reward": {"exp": 2100, "silver": 300, "item": "gunner_coat"}}
	,{"id": "cave_battery", "title": "夺取洞窟炮台", "story": "击败守卫炮台的黑帆重卫。", "objective": {"type": "kill", "target": "corsair_guard", "need": 1}, "reward": {"exp": 2800, "silver": 380, "item": "captain_hat"}}
	,{"id": "captain_ledger", "title": "黑帆船长雷蒙", "story": "登上船长厅，击败雷蒙并夺取记录发光鳞片航线的海图。", "objective": {"type": "kill", "target": "corsair_captain", "need": 1}, "reward": {"exp": 5200, "silver": 600, "item": "black_sail_charm"}}
	,{"id": "return_chart", "title": "黑帆海图", "story": "将从雷蒙手中夺回的黑帆海图带给老海鸥酒馆老板。", "objective": {"type": "talk", "target": "tavern_keeper", "need": 1}, "reward": {"exp": 0, "silver": 260, "item": "stamina_tonic"}}
	,{"id": "alisa_truth", "title": "潮汐中的名字", "story": "回到海边小屋见艾丽莎，听她说出一直隐瞒的真相。", "objective": {"type": "talk", "target": "alisa", "need": 1}, "reward": {"exp": 0, "silver": 320, "item": "tide_seal", "title": "潮汐追迹者"}}
	,{"id": "lighthouse_letter", "title": "灯塔来信", "story": "第一卷之后，酒馆老板收到萨米尔的密信。回酒馆确认灯塔异象。", "objective": {"type": "talk", "target": "tavern_keeper", "need": 1}, "reward": {"exp": 1800, "silver": 260}}
	,{"id": "sail_lighthouse", "title": "驶向灯塔港", "story": "备好三箱威尼斯玻璃，驾驶海燕号抵达亚历山大。", "objective": {"type": "visit", "target": "alexandria_dock", "need": 1}, "reward": {"exp": 2200, "silver": 300}}
	,{"id": "samir_testimony", "title": "香料商的证词", "story": "在亚历山大港寻找萨米尔，询问艾丽莎父亲与潮门的秘密。", "objective": {"type": "talk", "target": "alexandria_merchant", "need": 1}, "reward": {"exp": 2600, "silver": 340}}
	,{"id": "lighthouse_repairs", "title": "修缮灯塔镜室", "story": "向亚历山大商会交付三箱威尼斯玻璃，换取第一枚商会印记。", "objective": {"type": "trade_order", "target": "alexandria_lighthouse_glass", "need": 1}, "reward": {"exp": 3000, "silver": 380}}
	,{"id": "ragusa_nightwatch", "title": "石墙港的灯火", "story": "把四桶橄榄油送到拉古萨，为守夜人补足灯油。", "objective": {"type": "trade_order", "target": "ragusa_lamp_oil", "need": 1}, "reward": {"exp": 3400, "silver": 420}}
	,{"id": "three_port_trust", "title": "三港信任", "story": "继续完成港口订单，将三港总声望提升到6，取得商会星图。", "objective": {"type": "trade_reputation", "target": "total", "need": 6}, "reward": {"exp": 3800, "silver": 480}}
	,{"id": "guarded_passage", "title": "穿越季风", "story": "在任意港口购买一次护航物资，为长航程免除一次风暴损失。", "objective": {"type": "prepare_voyage", "target": "storm_kit", "need": 1}, "reward": {"exp": 4200, "silver": 520}}
	,{"id": "tide_medicine", "title": "潮汐药引", "story": "把四袋东方香料送回威尼斯，完成唤醒旧航海日志的药剂。", "objective": {"type": "trade_order", "target": "venice_tide_medicine", "need": 1}, "reward": {"exp": 4600, "silver": 620}}
	,{"id": "keeper_return", "title": "灯塔下的回声", "story": "回到老海鸥酒馆，让老板解读三港星图与旧航海日志。", "objective": {"type": "talk", "target": "tavern_keeper", "need": 1}, "reward": {"exp": 6000, "silver": 900, "item": "lighthouse_compass", "title": "灯塔守望者"}}
	,{"id": "white_whale_news", "title": "白鲸号的消息", "story": "回海边小屋告诉艾丽莎：她的父亲最后搭乘白鲸号去了马耳他。", "objective": {"type": "talk", "target": "alisa", "need": 1}, "reward": {"exp": 7000, "silver": 700, "item": "stamina_tonic"}}
	,{"id": "sail_malta", "title": "驶向马耳他", "story": "驾驶海燕号抵达马耳他蜂蜜石港，寻找白鲸号守钟人。", "objective": {"type": "visit", "target": "malta_dock", "need": 1}, "reward": {"exp": 7500, "silver": 760}}
	,{"id": "meet_isabella", "title": "守钟人伊莎贝拉", "story": "在马耳他港与伊莎贝拉交谈，查阅白鲸号最后的船员名册。", "objective": {"type": "talk", "target": "malta_keeper", "need": 1}, "reward": {"exp": 8000, "silver": 820}}
	,{"id": "island_feast", "title": "美味任务·海风炖汤", "story": "购齐两筐柑橘、一桶橄榄油和一袋香料，在马耳他厨房烹制海风炖汤。", "objective": {"type": "cook", "target": "maltese_stew", "need": 1}, "reward": {"exp": 8500, "silver": 880, "item": "maltese_stew"}}
	,{"id": "wreck_entry", "title": "白鲸残骸", "story": "带着远航餐食前往马耳他外海，登上白鲸号残骸的礁岸。", "objective": {"type": "visit", "target": "white_whale_1", "need": 1}, "reward": {"exp": 9000, "silver": 940}}
	,{"id": "clear_reef", "title": "清理礁岸", "story": "击败盘踞登船板的覆甲礁蟹，打开通往沉水甲板的道路。", "objective": {"type": "kill", "target": "wreck_crab", "need": 1}, "reward": {"exp": 10000, "silver": 1000, "item": "whale_bone_sabre"}}
	,{"id": "drowned_deck", "title": "未完成的值夜", "story": "击败沉水甲板上的溺潮水手，让他的灵魂结束最后一次值夜。", "objective": {"type": "kill", "target": "drowned_sailor", "need": 1}, "reward": {"exp": 11000, "silver": 1100, "item": "survivor_coat"}}
	,{"id": "fog_hold", "title": "寻裔之路·雾锁货舱", "story": "穿过货舱白雾，击败试图抹去船员姓名的雾歌海妖。", "objective": {"type": "kill", "target": "fog_siren", "need": 1}, "reward": {"exp": 13000, "silver": 1250, "item": "siren_charm"}}
	,{"id": "white_whale_heart", "title": "鲸落挽歌", "story": "进入鲸心船舱，击败深渊海妖涅瑞娅，夺回未能寄出的家书。", "objective": {"type": "kill", "target": "abyss_siren", "need": 1}, "reward": {"exp": 18000, "silver": 1500}}
	,{"id": "heir_testimony", "title": "白鲸继航者", "story": "带着家书回到马耳他港，让伊莎贝拉说出白鲸后裔与下一段航路的真相。", "objective": {"type": "talk", "target": "malta_keeper", "need": 1}, "reward": {"exp": 22000, "silver": 2000, "item": "white_whale_coat", "title": "白鲸继航者"}}
]

const LATE_QUESTS = [
	{"id": "sail_cape", "title": "驶向风暴角", "story": "从马耳他沿白鲸号旧航线南下，抵达开普敦风暴角港。", "objective": {"type": "visit", "target": "cape_town_dock", "need": 1}, "reward": {"exp": 25000, "silver": 1000}},
	{"id": "meet_amanda", "title": "北河向导", "story": "与向导阿曼达交谈，确认艾丽莎父亲曾进入贝河北岸石窟。", "objective": {"type": "talk", "target": "cape_keeper", "need": 1}, "reward": {"exp": 25000, "silver": 1050}},
	{"id": "basin_order", "title": "北河远征补给", "story": "交付四袋驱兽香料，为北河远征队开辟安全营地。", "objective": {"type": "trade_order", "target": "basin_supplies", "need": 1}, "reward": {"exp": 25000, "silver": 1100}},
	{"id": "enter_basin", "title": "聚宝盆石窟", "story": "从风暴角港步行进入北河遗迹，找到令金砂倒流的聚宝盆。", "objective": {"type": "visit", "target": "legacy_basin", "need": 1}, "reward": {"exp": 25000, "silver": 1150}},
	{"id": "defeat_basin", "title": "吞金之欲", "story": "击败被聚宝盆欲望侵蚀的北河吞金兽。", "objective": {"type": "kill", "target": "basin_leviathan", "need": 1}, "reward": {"exp": 25000, "silver": 1300, "item": "basin_charm"}},
	{"id": "basin_return", "title": "父亲的南方日志", "story": "带着被吞金兽守护的日志回到开普敦，让阿曼达解读下一条东方航线。", "objective": {"type": "talk", "target": "cape_keeper", "need": 1}, "reward": {"exp": 50000, "silver": 1600, "title": "北河寻金者"}},

	{"id": "sail_quanzhou", "title": "刺桐港来函", "story": "沿父亲日志中的季风线抵达泉州刺桐港。", "objective": {"type": "visit", "target": "quanzhou_dock", "need": 1}, "reward": {"exp": 38000, "silver": 1500}},
	{"id": "meet_shenyan", "title": "封妖录守卷人", "story": "与沈砚交谈，查明长安幻城为何会出现在海上。", "objective": {"type": "talk", "target": "quanzhou_scholar", "need": 1}, "reward": {"exp": 38000, "silver": 1550}},
	{"id": "changan_order", "title": "重铸镇妖镜", "story": "交付三箱威尼斯玻璃，让沈砚重制照破妖气的镇妖镜。", "objective": {"type": "trade_order", "target": "changan_seals", "need": 1}, "reward": {"exp": 38000, "silver": 1650}},
	{"id": "enter_changan", "title": "妖气长安", "story": "从泉州港进入沙海上的长安幻城，登上镇妖台。", "objective": {"type": "visit", "target": "legacy_changan", "need": 1}, "reward": {"exp": 38000, "silver": 1700}},
	{"id": "defeat_changan", "title": "九尾幻夜", "story": "击败九尾灯妖妲罗，守住自己与同伴的真实记忆。", "objective": {"type": "kill", "target": "nine_tail_fox", "need": 1}, "reward": {"exp": 38000, "silver": 1900, "item": "demon_mask"}},
	{"id": "changan_return", "title": "东来的妖气", "story": "回泉州交还封妖录，确认妖气来自雅典地下的同一条地脉裂隙。", "objective": {"type": "talk", "target": "quanzhou_scholar", "need": 1}, "reward": {"exp": 76000, "silver": 2200, "title": "长安破幻者"}},

	{"id": "sail_athens_earth", "title": "银帆港的地震", "story": "驶向雅典银帆港，调查与长安妖气同时出现的地脉震动。", "objective": {"type": "visit", "target": "athens_dock", "need": 1}, "reward": {"exp": 51000, "silver": 2000}},
	{"id": "meet_oracle_earth", "title": "裂开的地脉石", "story": "请祭司卡珊德拉辨认镇妖镜中浮现的王陵印记。", "objective": {"type": "talk", "target": "athens_oracle", "need": 1}, "reward": {"exp": 51000, "silver": 2100}},
	{"id": "earth_order", "title": "王陵长明灯", "story": "交付四桶橄榄油，点亮通往倒悬王陵的地脉灯。", "objective": {"type": "trade_order", "target": "earth_lamps", "need": 1}, "reward": {"exp": 51000, "silver": 2200}},
	{"id": "enter_earth", "title": "地魔宝藏", "story": "进入地脉王陵，抵达被黄金锁链包围的藏金殿。", "objective": {"type": "visit", "target": "legacy_earth", "need": 1}, "reward": {"exp": 51000, "silver": 2300}},
	{"id": "defeat_earth", "title": "镇岳之战", "story": "击败地魔王摩罗，释放被宝藏奴役的历代守陵人。", "objective": {"type": "kill", "target": "earth_demon_king", "need": 1}, "reward": {"exp": 51000, "silver": 2600, "item": "earth_armor"}},
	{"id": "earth_return", "title": "海床下的剑冢", "story": "回雅典解读王陵壁画，确认蒂拉之剑将在威尼斯下一次大退潮时出现。", "objective": {"type": "talk", "target": "athens_oracle", "need": 1}, "reward": {"exp": 102000, "silver": 3000, "title": "地脉解放者"}},

	{"id": "sail_venice_tira", "title": "归航威尼斯", "story": "在大退潮前赶回威尼斯，寻找海床下显露的潮刃圣所。", "objective": {"type": "visit", "target": "venice_dock", "need": 1}, "reward": {"exp": 64000, "silver": 2500}},
	{"id": "meet_keeper_tira", "title": "老船长的剑谱", "story": "向老海鸥酒馆老板询问蒂拉守剑人的挑战规则。", "objective": {"type": "talk", "target": "tavern_keeper", "need": 1}, "reward": {"exp": 64000, "silver": 2600}},
	{"id": "tira_order", "title": "潮火裹刃", "story": "向威尼斯商会交付四捆羊毛布，准备承受潮火的裹刃材料。", "objective": {"type": "trade_order", "target": "tira_forge", "need": 1}, "reward": {"exp": 64000, "silver": 2700}},
	{"id": "enter_tira", "title": "万刃剑冢", "story": "从威尼斯港进入退潮后的剑冢，接受守剑人的最终考验。", "objective": {"type": "visit", "target": "legacy_tira", "need": 1}, "reward": {"exp": 64000, "silver": 2800}},
	{"id": "defeat_tira", "title": "蒂拉之剑", "story": "击败蒂拉守剑人，证明你能驾驭力量而不被力量驾驭。", "objective": {"type": "kill", "target": "tira_guardian", "need": 1}, "reward": {"exp": 64000, "silver": 3200, "item": "tira_sword"}},
	{"id": "tira_return", "title": "裂隙中的舰队", "story": "带蒂拉之剑回酒馆，听老板说出天魔舰队与无旗船队的真正关系。", "objective": {"type": "talk", "target": "tavern_keeper", "need": 1}, "reward": {"exp": 128000, "silver": 3600, "title": "蒂拉执剑者"}},

	{"id": "sail_yangzhou_demon", "title": "玉纱传来的星图", "story": "驶往扬州运河月港，寻找能把裂隙轨迹织成图案的苏绫。", "objective": {"type": "visit", "target": "yangzhou_dock", "need": 1}, "reward": {"exp": 77000, "silver": 3000}},
	{"id": "meet_suling_demon", "title": "织进星光的历史", "story": "与苏绫交谈，把蒂拉之剑映出的天魔星图交给她。", "objective": {"type": "talk", "target": "yangzhou_weaver", "need": 1}, "reward": {"exp": 77000, "silver": 3100}},
	{"id": "demon_order", "title": "裂隙观测镜", "story": "交付三箱威尼斯玻璃，为玉纱织机安装观测裂隙的镜组。", "objective": {"type": "trade_order", "target": "demon_sails", "need": 1}, "reward": {"exp": 77000, "silver": 3200}},
	{"id": "enter_demon_legend", "title": "天魔传奇", "story": "沿玉纱星图进入魔星门，直面第一位穿越潮门的天魔将。", "objective": {"type": "visit", "target": "legacy_demon_legend", "need": 1}, "reward": {"exp": 77000, "silver": 3300}},
	{"id": "defeat_demon_legend", "title": "破军坠海", "story": "击败天魔将破军，夺取标有整支舰队回航日的星环。", "objective": {"type": "kill", "target": "celestial_demon_general", "need": 1}, "reward": {"exp": 77000, "silver": 3700, "item": "celestial_belt"}},
	{"id": "demon_legend_return", "title": "被修改的年历", "story": "回扬州比对星环和玉纱，发现天魔回航日期被人从历史中抹去。", "objective": {"type": "talk", "target": "yangzhou_weaver", "need": 1}, "reward": {"exp": 154000, "silver": 4200, "title": "魔星见证者"}},

	{"id": "sail_amsterdam_jade", "title": "北海拍卖目录", "story": "驶往阿姆斯特丹，寻找拍卖目录中出现的玉历残纱。", "objective": {"type": "visit", "target": "amsterdam_dock", "need": 1}, "reward": {"exp": 90000, "silver": 3500}},
	{"id": "meet_vander_jade", "title": "基德的图角", "story": "与范德海交谈，把星环与基德藏宝图缺角拼合。", "objective": {"type": "talk", "target": "amsterdam_cartographer", "need": 1}, "reward": {"exp": 90000, "silver": 3600}},
	{"id": "jade_order", "title": "醒梦香标", "story": "交付四袋东方香料，用不同香气标记玉历中被篡改的年份。", "objective": {"type": "trade_order", "target": "jade_calendar", "need": 1}, "reward": {"exp": 90000, "silver": 3700}},
	{"id": "enter_jade", "title": "玉历宝纱", "story": "进入月织秘境，找到记录七海真实历史的玉历纱庭。", "objective": {"type": "visit", "target": "legacy_jade", "need": 1}, "reward": {"exp": 90000, "silver": 3800}},
	{"id": "defeat_jade", "title": "织梦妖后", "story": "击败改写历史的织梦妖后，让所有被删去的航者重新留下姓名。", "objective": {"type": "kill", "target": "jade_dream_queen", "need": 1}, "reward": {"exp": 90000, "silver": 4300, "item": "jade_boots"}},
	{"id": "jade_return", "title": "黑炉补给线", "story": "回阿姆斯特丹展开完整玉历，找出天魔舰队隐藏在威尼斯外海的黑炉补给线。", "objective": {"type": "talk", "target": "amsterdam_cartographer", "need": 1}, "reward": {"exp": 180000, "silver": 4800, "title": "玉历守真者"}},

	{"id": "sail_venice_fire", "title": "九港熄灯令", "story": "返回威尼斯，组织九港同时切断黑炉海堡的补给航线。", "objective": {"type": "visit", "target": "venice_dock", "need": 1}, "reward": {"exp": 103000, "silver": 4000}},
	{"id": "meet_keeper_fire", "title": "釜底抽薪", "story": "向酒馆老板确认海堡结构，制定摧毁炉心而非强攻舰队的计划。", "objective": {"type": "talk", "target": "tavern_keeper", "need": 1}, "reward": {"exp": 103000, "silver": 4100}},
	{"id": "fire_order", "title": "冷却黑炉", "story": "交付五筐柑橘，以酸液暂时冻结潮能管线。", "objective": {"type": "trade_order", "target": "furnace_decoy", "need": 1}, "reward": {"exp": 103000, "silver": 4200}},
	{"id": "enter_fire", "title": "潜入黑炉海堡", "story": "从威尼斯港潜入黑炉海堡，抵达不断搏动的炉心。", "objective": {"type": "visit", "target": "legacy_fire", "need": 1}, "reward": {"exp": 103000, "silver": 4300}},
	{"id": "defeat_fire", "title": "熄灭炉心", "story": "击败黑炉领主，切断天魔舰队跨越潮门所需的全部能源。", "objective": {"type": "kill", "target": "black_furnace_lord", "need": 1}, "reward": {"exp": 103000, "silver": 4900, "item": "furnace_core"}},
	{"id": "fire_return", "title": "风暴眼重开", "story": "回酒馆复命，却发现天魔王舍弃舰队，独自强行穿越了归潮天门。", "objective": {"type": "talk", "target": "tavern_keeper", "need": 1}, "reward": {"exp": 206000, "silver": 5500, "title": "黑炉终结者"}},

	{"id": "sail_quanzhou_return", "title": "九港结界", "story": "赶往泉州，与沈砚汇合并启动连接九港灯塔的结界。", "objective": {"type": "visit", "target": "quanzhou_dock", "need": 1}, "reward": {"exp": 116000, "silver": 4500}},
	{"id": "meet_shenyan_return", "title": "天魔归来", "story": "与沈砚校准封妖录，锁定天魔王藏身的归潮风暴眼。", "objective": {"type": "talk", "target": "quanzhou_scholar", "need": 1}, "reward": {"exp": 116000, "silver": 4600}},
	{"id": "return_order", "title": "结界帆", "story": "交付五捆羊毛布，缝成连接九港灯火的结界帆。", "objective": {"type": "trade_order", "target": "return_wards", "need": 1}, "reward": {"exp": 116000, "silver": 4700}},
	{"id": "enter_return", "title": "归潮风暴眼", "story": "穿越归潮天门，在九港灯火完全熄灭前拦住天魔王。", "objective": {"type": "visit", "target": "legacy_return", "need": 1}, "reward": {"exp": 116000, "silver": 4800}},
	{"id": "defeat_return", "title": "九港守夜", "story": "击败归来天魔王，让九座港口的灯塔重新亮起。", "objective": {"type": "kill", "target": "returned_demon_king", "need": 1}, "reward": {"exp": 116000, "silver": 5500, "item": "demon_crown"}},
	{"id": "return_home", "title": "未完成的封印", "story": "回泉州查看封妖录，发现天魔王只是封印迷阵泄露出的第一道影子。", "objective": {"type": "talk", "target": "quanzhou_scholar", "need": 1}, "reward": {"exp": 232000, "silver": 6200, "title": "九港守夜人"}},

	{"id": "sail_athens_shears", "title": "断裂的命线", "story": "驶向雅典，请卡珊德拉寻找能够修补封印迷阵的天工神剪。", "objective": {"type": "visit", "target": "athens_dock", "need": 1}, "reward": {"exp": 129000, "silver": 5000}},
	{"id": "meet_oracle_shears", "title": "天工坊遗址", "story": "与卡珊德拉交谈，从地脉石中唤醒天工坊的入口。", "objective": {"type": "talk", "target": "athens_oracle", "need": 1}, "reward": {"exp": 129000, "silver": 5100}},
	{"id": "shears_order", "title": "神剪淬光", "story": "交付四箱威尼斯玻璃，将潮光折入天工神剪的断刃。", "objective": {"type": "trade_order", "target": "shears_alloy", "need": 1}, "reward": {"exp": 129000, "silver": 5200}},
	{"id": "enter_shears", "title": "天工神剪", "story": "进入命线台，阻止傀儡天工师剪去所有反抗天魔者的姓名。", "objective": {"type": "visit", "target": "legacy_shears", "need": 1}, "reward": {"exp": 129000, "silver": 5300}},
	{"id": "defeat_shears", "title": "剪断谎言", "story": "击败傀儡天工师，夺回能够修补历史与潮门的天工神剪。", "objective": {"type": "kill", "target": "clockwork_tailor", "need": 1}, "reward": {"exp": 129000, "silver": 6100, "item": "divine_shears"}},
	{"id": "shears_return", "title": "十三卷归一", "story": "回雅典修复神剪，十三卷航海日志同时显出最终封印迷阵。", "objective": {"type": "talk", "target": "athens_oracle", "need": 1}, "reward": {"exp": 258000, "silver": 6900, "title": "天工继承者"}},

	{"id": "sail_yangzhou_seal", "title": "最后的月港", "story": "带天工神剪抵达扬州，与苏绫完成进入封印迷阵前的最后准备。", "objective": {"type": "visit", "target": "yangzhou_dock", "need": 1}, "reward": {"exp": 142000, "silver": 6000}},
	{"id": "meet_suling_seal", "title": "四海同盟", "story": "与苏绫展开十三卷日志，让九港誓言汇入最终玉纱。", "objective": {"type": "talk", "target": "yangzhou_weaver", "need": 1}, "reward": {"exp": 142000, "silver": 6200}},
	{"id": "seal_order", "title": "九港定神香", "story": "交付五袋东方香料，点燃九港共同守护的定神香火。", "objective": {"type": "trade_order", "target": "seal_threads", "need": 1}, "reward": {"exp": 142000, "silver": 6400}},
	{"id": "enter_seal", "title": "封印迷阵", "story": "进入潮汐之心，以天工神剪修补不断崩裂的最终迷阵。", "objective": {"type": "visit", "target": "legacy_seal", "need": 1}, "reward": {"exp": 142000, "silver": 6600}},
	{"id": "defeat_seal", "title": "终潮归零", "story": "击败由所有潮门阴影汇成的潮虚帝，保住七海与一路找回的名字。", "objective": {"type": "kill", "target": "tide_void_emperor", "need": 1}, "reward": {"exp": 142000, "silver": 7600, "item": "tidekeeper_regalia"}},
	{"id": "seal_epilogue", "title": "纵横四海", "story": "回扬州听九港钟声同时响起，并决定由所有港口共同守护潮门。", "objective": {"type": "talk", "target": "yangzhou_weaver", "need": 1}, "reward": {"exp": 284000, "silver": 10000, "title": "四海守潮人"}}
]

static var QUESTS = EARLY_QUESTS + LATE_QUESTS

const STORY_CHAPTERS = [
	{"title": "序章·失去的名字", "start": 0, "end": 2, "summary": "你被艾丽莎一家从海难中救起，发光鳞片把线索引向威尼斯酒馆。"},
	{"title": "第一章·威尼斯试炼", "start": 3, "end": 6, "summary": "你替城市清理危机、集结伙伴，并在四层副本中证明了自己。"},
	{"title": "第二章·海燕号商路", "start": 7, "end": 11, "summary": "海燕号启航。贸易、强化与船只改造让你获得追查黑帆的力量。"},
	{"title": "第三章·黑帆之谜", "start": 12, "end": 18, "summary": "你潜入黑帆据点夺回海图，并循着潮声找回被隐藏的名字。"},
	{"title": "第四章·灯塔来信", "start": 19, "end": 22, "summary": "亚历山大灯塔发出蓝光。你以货物修复镜室，从萨米尔处取得第一枚商会印记。"},
	{"title": "第五章·三港星图", "start": 23, "end": 25, "summary": "你用真实的贸易帮助三港，在季风到来前赢得商会信任并备妥护航物资。"},
	{"title": "第六章·灯塔回声", "start": 26, "end": 27, "summary": "潮汐药剂唤醒旧日志，星盘指出艾丽莎父亲最后驶向了马耳他。"}
	,{"title": "第七章·白鲸残影", "start": 28, "end": 30, "summary": "你循着白鲸号的消息抵达马耳他，与守钟人伊莎贝拉相认。"}
	,{"title": "第八章·马耳他盛宴", "start": 31, "end": 34, "summary": "一份古老食谱把贸易货物变成远航补给，你由礁岸踏入白鲸号残骸。"}
	,{"title": "第九章·寻裔之路", "start": 35, "end": 37, "summary": "你穿过沉船迷雾夺回家书，确认白鲸后裔仍在，并得到通向北河的线索。"}
	,{"title": "第十章·北河迷踪", "start": 38, "end": 39, "summary": "白鲸号旧航线穿过风暴角，你与向导阿曼达找到父亲留下的北河足迹。"}
	,{"title": "第十一章·聚宝盆", "start": 40, "end": 41, "summary": "远征队备妥驱兽香，进入令金砂倒流的聚宝盆石窟。"}
	,{"title": "第十二章·南方日志", "start": 42, "end": 43, "summary": "吞金兽倒下后，父亲的日志把航线引向泉州与海上的长安幻城。"}
	,{"title": "第十三章·妖气东来", "start": 44, "end": 45, "summary": "泉州守卷人沈砚确认长安妖气正沿海路蔓延。"}
	,{"title": "第十四章·妖气长安", "start": 46, "end": 47, "summary": "镇妖镜照开幻城入口，你在九尾妖灯间守住真实记忆。"}
	,{"title": "第十五章·地脉裂隙", "start": 48, "end": 49, "summary": "封妖录揭示雅典地下还埋着更古老的地魔王陵。"}
	,{"title": "第十六章·银帆地震", "start": 50, "end": 51, "summary": "雅典地脉石裂开，卡珊德拉点亮通往倒悬王陵的道路。"}
	,{"title": "第十七章·地魔宝藏", "start": 52, "end": 53, "summary": "你拒绝黄金诱惑，在藏金殿直面地魔王摩罗。"}
	,{"title": "第十八章·海床剑冢", "start": 54, "end": 55, "summary": "王陵壁画预言蒂拉之剑将在威尼斯大退潮时重现。"}
	,{"title": "第十九章·大退潮", "start": 56, "end": 57, "summary": "你赶回威尼斯，从老船长剑谱中读懂守剑人的规则。"}
	,{"title": "第二十章·蒂拉之剑", "start": 58, "end": 59, "summary": "万刃归潮，你证明自己能够驾驭力量而不被力量驾驭。"}
	,{"title": "第二十一章·裂隙舰队", "start": 60, "end": 61, "summary": "蒂拉之剑映出天魔舰队，旧日传说终于显露真实轮廓。"}
	,{"title": "第二十二章·星图玉纱", "start": 62, "end": 63, "summary": "扬州织师苏绫把天魔星轨织进玉纱。"}
	,{"title": "第二十三章·天魔传奇", "start": 64, "end": 65, "summary": "魔星门开启，天魔将破军宣布七海将成为舰队新港。"}
	,{"title": "第二十四章·失落年历", "start": 66, "end": 67, "summary": "星环证明回航日期被篡改，真相藏在北海拍卖的玉历残纱中。"}
	,{"title": "第二十五章·基德图角", "start": 68, "end": 69, "summary": "范德海用基德藏宝图补全玉历宝纱的入口。"}
	,{"title": "第二十六章·玉历宝纱", "start": 70, "end": 71, "summary": "你击败织梦妖后，让被删去的航者重新留下姓名。"}
	,{"title": "第二十七章·黑炉航线", "start": 72, "end": 73, "summary": "完整玉历指出天魔舰队的真正弱点是威尼斯外海黑炉。"}
	,{"title": "第二十八章·九港熄灯", "start": 74, "end": 75, "summary": "九港同步截断补给，准备从根源熄灭天魔战争。"}
	,{"title": "第二十九章·釜底抽薪", "start": 76, "end": 77, "summary": "你潜入黑炉海堡，让吞噬潮能的炉心永久熄灭。"}
	,{"title": "第三十章·风暴眼", "start": 78, "end": 79, "summary": "失去舰队的天魔王独自穿过潮门，归潮风暴眼重新开启。"}
	,{"title": "第三十一章·九港结界", "start": 80, "end": 81, "summary": "泉州封妖录连接九港灯塔，最后的守夜开始。"}
	,{"title": "第三十二章·天魔归来", "start": 82, "end": 83, "summary": "你在风暴眼击败归来天魔王，让九港灯火重燃。"}
	,{"title": "第三十三章·封印裂痕", "start": 84, "end": 85, "summary": "天魔只是迷阵泄出的影子，真正的潮虚仍在封印深处。"}
	,{"title": "第三十四章·断裂命线", "start": 86, "end": 87, "summary": "卡珊德拉从地脉石中唤醒早已失落的天工坊。"}
	,{"title": "第三十五章·天工神剪", "start": 88, "end": 89, "summary": "你从傀儡天工师手中夺回能修补历史的神剪。"}
	,{"title": "第三十六章·十三卷归一", "start": 90, "end": 91, "summary": "十三卷日志同时发光，最终封印迷阵完整显现。"}
	,{"title": "第三十七章·四海同盟", "start": 92, "end": 93, "summary": "九港誓言汇入玉纱，所有相遇过的人都成为守阵者。"}
	,{"title": "第三十八章·封印迷阵", "start": 94, "end": 95, "summary": "天工神剪修补潮门，你在潮汐之心迎战潮虚帝。"}
	,{"title": "第三十九章·纵横四海", "start": 96, "end": 97, "summary": "九港钟声同响，潮门不再属于一人，而由四海共同守护。"}
]

const STORY_VOLUMES = [
	{"title": "第一卷·潮汐纪事", "start": 0, "end": 18},
	{"title": "第二卷·灯塔下的回声", "start": 19, "end": 27},
	{"title": "第三卷·白鲸遗航", "start": 28, "end": 37}
	,{"title": "第四卷·聚宝盆", "start": 38, "end": 43}
	,{"title": "第五卷·妖气长安", "start": 44, "end": 49}
	,{"title": "第六卷·地魔宝藏", "start": 50, "end": 55}
	,{"title": "第七卷·蒂拉之剑", "start": 56, "end": 61}
	,{"title": "第八卷·天魔传奇", "start": 62, "end": 67}
	,{"title": "第九卷·玉历宝纱", "start": 68, "end": 73}
	,{"title": "第十卷·釜底抽薪", "start": 74, "end": 79}
	,{"title": "第十一卷·天魔归来", "start": 80, "end": 85}
	,{"title": "第十二卷·天工神剪", "start": 86, "end": 91}
	,{"title": "第十三卷·封印迷阵", "start": 92, "end": 97}
]

const SLOT_NAMES = {"weapon": "手持", "head": "头戴", "body": "身穿", "waist": "腰部", "boots": "脚穿", "charm": "配饰"}

const MAX_LEVEL = 100

static func xp_needed(level):
	var curve = [0, 70, 115, 175, 255, 360, 500, 680, 900, 1160, 1460, 1800, 2180, 2600, 3060, 3560, 4080, 4660, 5300, 6000, 6780, 7640, 8580, 9600, 10700, 11880, 13140, 14480, 15900, 17400, 19000]
	if level < curve.size():
		return curve[level]
	return 19000 + (level - 30) * 1800

static func objective_name(objective):
	match objective.type:
		"kill": return ENEMIES[objective.target].name
		"talk": return NPCS[objective.target].name
		"visit": return LOCATIONS[objective.target].name
		"trade_buy": return "买入%s" % TRADE_GOODS[objective.target].name
		"trade_sell": return "卖出%s" % TRADE_GOODS[objective.target].name
		"upgrade_equipment": return "强化%s" % SLOT_NAMES[objective.target]
		"upgrade_ship": return "升级船体护甲"
		"trade_order": return "交付%s" % TRADE_ORDERS.get(str(objective.target), {"title": "港口订单"}).title
		"trade_reputation": return "三港总声望" if int(objective.get("need", 0)) <= 6 else "九港总声望"
		"prepare_voyage": return "购买护航物资"
		"cook": return "烹制%s" % RECIPES.get(str(objective.target), {"name": "远航餐食"}).name
		_: return str(objective.target)

static func quest_dialogue(quest_id, npc_id):
	var key = "%s|%s" % [str(quest_id), str(npc_id)]
	if QUEST_DIALOGUES.has(key):
		return str(QUEST_DIALOGUES[key])
	return str(NPCS.get(str(npc_id), {}).get("dialogue", "没有更多消息。"))

static func trade_route(from_port, to_port):
	var ports = [str(from_port), str(to_port)]
	ports.sort()
	return TRADE_ROUTES.get("%s|%s" % ports, {})

static func trade_market_price(port_id, good_id, day):
	if not TRADE_GOODS.has(good_id) or not TRADE_PORTS.has(port_id):
		return 0
	var base = float(TRADE_GOODS[good_id].prices[port_id])
	var market_event = trade_event(day)
	if str(market_event.port) == str(port_id) and str(market_event.good) == str(good_id):
		base *= float(market_event.multiplier)
	var seed = 0
	var key = "%s:%s" % [port_id, good_id]
	for index in range(key.length()):
		seed = (seed + key.unicode_at(index) * (index + 3)) % 997
	var swing = ((seed + int(day) * 7 + int(day) * int(day) * 3) % 19) - 9
	return max(1, int(round(base * float(100 + swing) / 100.0)))

static func trade_event(day):
	return TRADE_EVENTS[(max(1, int(day)) - 1) % TRADE_EVENTS.size()]
