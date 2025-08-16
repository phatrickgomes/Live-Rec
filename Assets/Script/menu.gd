extends Control

@onready var play_button = $PlayButton
@onready var exit_button = $ExitButton

func _ready():
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.05, 0.05, 0.05)
	style_normal.border_color = Color(0.8, 0.0, 0.0)
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	play_button.add_theme_stylebox_override("normal", style_normal)
	exit_button.add_theme_stylebox_override("normal", style_normal)

	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.1, 0.0, 0.0)
	style_hover.border_color = Color(1.0, 0.0, 0.0)
	play_button.add_theme_stylebox_override("hover", style_hover)
	exit_button.add_theme_stylebox_override("hover", style_hover)

	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.03, 0.0, 0.0)
	style_pressed.border_color = Color(0.6, 0.0, 0.0)
	play_button.add_theme_stylebox_override("pressed", style_pressed)
	exit_button.add_theme_stylebox_override("pressed", style_pressed)


	play_button.add_theme_color_override("font_color", Color(1, 0, 0))
	exit_button.add_theme_color_override("font_color", Color(1, 0, 0)) 


func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/quarto.tscn")

func exit_on_exit_button_pressed():
	get_tree().quit()
