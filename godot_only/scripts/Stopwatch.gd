class_name Stopwatch extends RefCounted

var precise: bool
var name: String
var start_ticks: int

static func start(precise_to_microseconds := true, new_name := "Elapsed time") -> Stopwatch:
	var new_stopwatch := Stopwatch.new()
	new_stopwatch.precise = precise_to_microseconds
	new_stopwatch.name = new_name
	new_stopwatch.start_ticks = new_stopwatch.get_ticks()
	return new_stopwatch

func measure(reset := false) -> void:
	var elapsed := get_ticks() - start_ticks
	print_rich("[b]%s:[/b] %d%s" % [name, elapsed, "us" if precise else "ms"])
	if reset:
		start_ticks = get_ticks()

func get_ticks() -> int:
	return Time.get_ticks_usec() if precise else Time.get_ticks_msec()
