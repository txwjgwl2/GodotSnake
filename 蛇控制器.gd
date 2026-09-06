extends Node2D


# 此脚本挂载于 Snake 节点，负责蛇身数据管理、方向输入、移动 tick、碰撞判定与身体渲染


signal 游戏结束
signal 吃到食物


enum 方向 { 上, 下, 左, 右 }


const 常量_网格大小: int = 24
const 常量_单元格尺寸: int = 20
const 常量_移动间隔: float = 0.12


var 蛇身数据: Array[Vector2i] = []
var 当前方向: int = 方向.右
var _待切换方向: int = 方向.右
var _身体节点列表: Array[ColorRect] = []


@onready var 食物节点: ColorRect = $食物节点
@onready var 移动计时器: Timer = $移动计时器


# 初始化蛇身、启动计时器并布置初始食物
func _ready() -> void:
	移动计时器.wait_time = 常量_移动间隔
	重置游戏()
	移动计时器.timeout.connect(_当移动计时器触发)


# 捕获方向键输入，禁止 180° 反向切换
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_W, KEY_UP:
				if 当前方向 != 方向.下:
					_待切换方向 = 方向.上
			KEY_S, KEY_DOWN:
				if 当前方向 != 方向.上:
					_待切换方向 = 方向.下
			KEY_A, KEY_LEFT:
				if 当前方向 != 方向.右:
					_待切换方向 = 方向.左
			KEY_D, KEY_RIGHT:
				if 当前方向 != 方向.左:
					_待切换方向 = 方向.右


# 重置蛇身到初始三格、朝右状态，并生成食物
func 重置游戏() -> void:
	for 节点 in _身体节点列表:
		节点.queue_free()
	_身体节点列表.clear()

	蛇身数据.clear()
	var 起始中心: Vector2i = Vector2i(常量_网格大小 / 2, 常量_网格大小 / 2)
	for i in range(3):
		蛇身数据.append(起始中心 - Vector2i(i, 0))

	当前方向 = 方向.右
	_待切换方向 = 方向.右

	_重建身体节点()
	_生成食物()

	if not 移动计时器.is_stopped():
		移动计时器.stop()
	移动计时器.start()


# 根据最新蛇身数据重建所有身体矩形节点
func _重建身体节点() -> void:
	for 坐标 in 蛇身数据:
		var 方块: ColorRect = ColorRect.new()
		方块.size = Vector2(常量_单元格尺寸 - 2, 常量_单元格尺寸 - 2)
		方块.position = Vector2(坐标.x * 常量_单元格尺寸 + 1, 坐标.y * 常量_单元格尺寸 + 1)
		var 是否头部: bool = 坐标 == 蛇身数据[0]
		方块.color = Color(0.3, 0.9 if 是否头部 else 0.7, 0.3)
		add_child(方块)
		_身体节点列表.append(方块)


# 每次 tick 执行一次移动：计算新头部坐标、检测碰撞、更新身体
func _当移动计时器触发() -> void:
	当前方向 = _待切换方向
	var 头部坐标: Vector2i = 蛇身数据[0]
	var 偏移: Vector2i = _获取方向偏移(当前方向)
	var 新头部: Vector2i = 头部坐标 + 偏移

	if _是否撞墙(新头部) or _是否撞到自己(新头部):
		移动计时器.stop()
		游戏结束.emit()
		return

	蛇身数据.insert(0, 新头部)

	if 新头部 == _获取食物网格坐标():
		吃到食物.emit()
		_生成食物()
	else:
		蛇身数据.pop_back()

	_刷新身体节点()


# 根据当前蛇身数据同步更新已存在节点的位置与颜色
func _刷新身体节点() -> void:
	var 差异数量: int = 蛇身数据.size() - _身体节点列表.size()
	if 差异数量 > 0:
		for i in range(差异数量):
			var 方块: ColorRect = ColorRect.new()
			方块.size = Vector2(常量_单元格尺寸 - 2, 常量_单元格尺寸 - 2)
			add_child(方块)
			_身体节点列表.append(方块)
	elif 差异数量 < 0:
		for i in range(-差异数量):
			var 尾部节点: ColorRect = _身体节点列表.pop_back()
			尾部节点.queue_free()

	for i in range(蛇身数据.size()):
		var 坐标: Vector2i = 蛇身数据[i]
		var 节点: ColorRect = _身体节点列表[i]
		节点.position = Vector2(坐标.x * 常量_单元格尺寸 + 1, 坐标.y * 常量_单元格尺寸 + 1)
		节点.color = Color(0.3, 0.9 if i == 0 else 0.7, 0.3)


# 生成食物到不与蛇身重叠的随机格子
func _生成食物() -> void:
	var 已占用: Dictionary = {}
	for 坐标 in 蛇身数据:
		已占用[坐标] = true

	var 候选列表: Array[Vector2i] = []
	for x in range(常量_网格大小):
		for y in range(常量_网格大小):
			var 格子: Vector2i = Vector2i(x, y)
			if not 已占用.has(格子):
				候选列表.append(格子)

	if 候选列表.is_empty():
		return

	var 选中: Vector2i = 候选列表.pick_random()
	食物节点.position = Vector2(选中.x * 常量_单元格尺寸 + 1, 选中.y * 常量_单元格尺寸 + 1)


# 将方向枚举转换为对应的网格偏移量
func _获取方向偏移(目标方向: int) -> Vector2i:
	match 目标方向:
		方向.上:
			return Vector2i(0, -1)
		方向.下:
			return Vector2i(0, 1)
		方向.左:
			return Vector2i(-1, 0)
		方向.右:
			return Vector2i(1, 0)
	return Vector2i.ZERO


# 检查坐标是否越出网格边界
func _是否撞墙(坐标: Vector2i) -> bool:
	return 坐标.x < 0 or 坐标.x >= 常量_网格大小 or 坐标.y < 0 or 坐标.y >= 常量_网格大小


# 检查坐标是否与蛇身（不含尾部，因为尾部即将移动）重叠
func _是否撞到自己(坐标: Vector2i) -> bool:
	for i in range(蛇身数据.size() - 1):
		if 蛇身数据[i] == 坐标:
			return true
	return false


# 获取食物当前所在的网格坐标
func _获取食物网格坐标() -> Vector2i:
	var 像素坐标: Vector2 = 食物节点.position
	return Vector2i(int(像素坐标.x / 常量_单元格尺寸), int(像素坐标.y / 常量_单元格尺寸))