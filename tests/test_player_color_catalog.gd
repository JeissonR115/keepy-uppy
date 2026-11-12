extends SceneTree


func _initialize() -> void:
	var player_one := PlayerActionCatalog.player_movement_colors("player_1")
	var player_two := PlayerActionCatalog.player_movement_colors("player_2")
	if not _expect_colors(
		player_one,
		Color(0.470588, 0.890196, 0.945098),
		Color(0.772549, 0.960784, 0.980392),
		Color(0.172549, 0.537255, 0.607843)
	):
		quit(1)
		return
	if not _expect_colors(
		player_two,
		Color(1.0, 0.780392, 0.466667),
		Color(1.0, 0.898039, 0.729412),
		Color(0.690196, 0.286275, 0.270588)
	):
		quit(1)
		return
	print("Player movement palette values match the original controller colors.")
	quit()


func _expect_colors(colors: Dictionary, run: Color, rise: Color, fall: Color) -> bool:
	return (
		is_equal_approx_color(colors.run, run)
		and is_equal_approx_color(colors.rise, rise)
		and is_equal_approx_color(colors.fall, fall)
	)


func is_equal_approx_color(left: Color, right: Color) -> bool:
	return (
		is_equal_approx(left.r, right.r)
		and is_equal_approx(left.g, right.g)
		and is_equal_approx(left.b, right.b)
		and is_equal_approx(left.a, right.a)
	)
