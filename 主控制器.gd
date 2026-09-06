extends Node2D


# 此脚本挂载于 Main 主场景根节点，负责分数显示、游戏结束遮罩与重开流程


const 常量_初始分数: int = 0


var 当前分数: int = 常量_初始分数
var _是否游戏结束: bool = false


@onready var 分数标签: Label = %分数标签
@onready var 游戏结束面板: Control = %游戏结束面板
@onready var 游戏结束标签: Label = %游戏结束标签
@onready var 蛇节点: Node2D = %蛇节点


# 连接信号并初始化 UI
func _ready() -> void:
	蛇节点.吃到食物.connect(_当吃到食物时)
	蛇节点.游戏结束.connect(_当游戏结束时)
	_刷新分数显示()
	游戏结束面板.visible = false


# 监听 R 键重开
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and _是否游戏结束:
			_重新开始游戏()


# 吃到食物时加分并刷新 UI
func _当吃到食物时() -> void:
	当前分数 += 1
	_刷新分数显示()


# 显示游戏结束遮罩
func _当游戏结束时() -> void:
	_是否游戏结束 = true
	游戏结束标签.text = "游戏结束！\n最终得分：%d\n按 R 键重开" % 当前分数
	游戏结束面板.visible = true


# 重置分数、隐藏遮罩并通知蛇节点重置
func _重新开始游戏() -> void:
	当前分数 = 常量_初始分数
	_是否游戏结束 = false
	游戏结束面板.visible = false
	_刷新分数显示()
	蛇节点.重置游戏()


# 将当前分数同步到标签
func _刷新分数显示() -> void:
	分数标签.text = "分数：%d" % 当前分数
