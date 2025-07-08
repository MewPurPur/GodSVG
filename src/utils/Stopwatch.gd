class_name Stopwatch extends RefCounted


enum TimeUnit {
	MICROSECONDS = 1,
	MILLISECONDS = 1000,
	SECONDS = 1000000,
}


const _UNIT_LABELS := {
	TimeUnit.MICROSECONDS: "us",
	TimeUnit.MILLISECONDS: "ms",
	TimeUnit.SECONDS: "s",
}


var timer_name: String
var unit := TimeUnit.MILLISECONDS
var stop_on_disposal: bool
var _start_ticks: int


func _init(auto_start: bool = true, _unit: TimeUnit = TimeUnit.MILLISECONDS, _timer_name: String = "Elapsed time: ", _stop_on_disposal: bool = true) -> void:
	self.unit = _unit
	self.timer_name = _timer_name
	self.stop_on_disposal = _stop_on_disposal
	if auto_start:
		start()


func start() -> void:
	_start_ticks = Time.get_ticks_usec()


func stop(name_override: Variant = null) -> void:
	if name_override != null:
		assert(typeof(name_override) == TYPE_STRING)
	print(_default(name_override, timer_name), float(Time.get_ticks_usec() - _start_ticks) / unit, _UNIT_LABELS[unit])


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if stop_on_disposal:
				print(timer_name, float(Time.get_ticks_usec() - _start_ticks) / unit, _UNIT_LABELS[unit])


static func _default(value, default_value):
	if value:
		return value
	return default_value
