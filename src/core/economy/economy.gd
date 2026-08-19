extends Node

signal money_changed(current: int)

var money := 0


func reset() -> void:
	_set_money(0)


func add_money(amount: int) -> void:
	if amount <= 0:
		return
	_set_money(money + amount)


func spend_money(amount: int) -> bool:
	if amount < 0:
		return false
	if money < amount:
		return false
	_set_money(money - amount)
	return true


func can_afford(amount: int) -> bool:
	return money >= amount


func _set_money(value: int) -> void:
	money = value
	money_changed.emit(money)
