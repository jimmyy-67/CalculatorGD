class_name DoodleStyle
extends RefCounted

const LINE := Color("#101014")

const FILLS := {
	"body": Color("#46586e"),
	"display": Color("#14161c"),
	"digit": Color("#4f6178"),
	"util": Color("#3c4a61"),
	"op": Color("#c98a2e"),
	"equal": Color("#2e9e6b"),
}

const FONTS := {
	"digit": Color("#e8ecf2"),
	"util": Color("#e8ecf2"),
	"op": Color("#f4f6fa"),
	"equal": Color("#f4f6fa"),
}


static func body_style() -> StyleBoxTexture:
	return load("res://assets/doodle/body.tres") as StyleBoxTexture


static func display_style() -> StyleBoxTexture:
	return load("res://assets/doodle/display.tres") as StyleBoxTexture


static func btn(kind: String, state: String) -> StyleBoxTexture:
	var k: String = kind if FILLS.has(kind) else "digit"
	var s: String = state if state in ["normal", "hover", "pressed"] else "normal"
	return load("res://assets/doodle/btn_%s_%s.tres" % [k, s]) as StyleBoxTexture


static func font_col(kind: String) -> Color:
	return FONTS.get(kind, FONTS["digit"])
