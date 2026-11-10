extends GdUnitTestSuite

const SIGNALS: Array[String] = [
	"world_shift_started",
	"world_shifted",
	"shift_denied",
	"arena_bounds_changed",
	"player_spawned",
	"stats_changed",
	"settings_changed",
]


func test_events_has_signals() -> void:
	for signal_name: String in SIGNALS:
		assert_bool(Events.has_signal(signal_name)).is_true()
