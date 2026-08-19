class_name NorthStarIntegrationShell
extends Control

@onready var presenter: Node = $NorthStarPresenter
@onready var host: Node = $MockNorthStarHost
@onready var expedition: Control = %ExpeditionScene

var _title: Label
var _summary: Label
var _primary: Button
var _secondary: Button
var _shell_panel: PanelContainer


func _ready() -> void:
	_build_shell_view()
	presenter.presentation_state_changed.connect(_apply_state)
	host.snapshot_received.connect(presenter.accept_host_snapshot)
	var source := expedition.get_node("MockTelemetrySource") as MockTelemetrySource
	source.interval_seconds = 0.05
	(expedition.get_node("Margin/RootColumn/DecisionUI/Return") as Button).pressed.connect(host.show_result)
	host.show_workshop()


func _build_shell_view() -> void:
	_shell_panel = PanelContainer.new()
	_shell_panel.name = "ShellPanel"
	_shell_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	add_child(_shell_panel)
	var column := VBoxContainer.new()
	column.name = "Content"
	column.add_theme_constant_override("separation", 18)
	_shell_panel.add_child(column)
	_title = Label.new()
	_title.name = "ScreenTitle"
	_title.add_theme_font_size_override("font_size", 30)
	column.add_child(_title)
	_summary = Label.new()
	_summary.name = "StateSummary"
	_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_summary)
	var actions := HBoxContainer.new()
	actions.name = "Actions"
	actions.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(actions)
	_secondary = Button.new()
	_secondary.name = "SecondaryAction"
	actions.add_child(_secondary)
	_primary = Button.new()
	_primary.name = "PrimaryAction"
	actions.add_child(_primary)


func _apply_state(state: RefCounted) -> void:
	_shell_panel.visible = state.screen != &"EXPEDITION"
	expedition.visible = state.screen == &"EXPEDITION"
	_disconnect_actions()
	_secondary.visible = false
	match state.screen:
		&"WORKSHOP":
			_title.text = "WORKSHOP / FOUNDRY"
			_summary.text = "Station: %s\nAvailable design records: %s\nBlueprint knowledge retained: %d" % [state.workshop.get("station", "—"), state.workshop.get("available_designs", "—"), state.blueprint.get("saved_blueprints", []).size()]
			_primary.text = "OPEN DESIGN / BLUEPRINT"
			_primary.pressed.connect(host.show_blueprint)
		&"BLUEPRINT":
			_title.text = "DESIGN / BLUEPRINT LIBRARY"
			_summary.text = "Selected: %s\nSaved records: %d\nPresentation only — host owns save and fabrication rules." % [state.blueprint.get("selected_design", "—"), state.blueprint.get("saved_blueprints", []).size()]
			_primary.text = "REQUEST FABRICATION"
			_primary.pressed.connect(host.confirm_fabrication)
		&"FABRICATION_CONFIRMED":
			_title.text = "FABRICATION CONFIRMED"
			_summary.text = "Unit: %s\nSource: %s\nHost result accepted. No fabrication rule is evaluated here." % [state.fabrication.get("unit_label", "—"), state.fabrication.get("source", "—")]
			_primary.text = "DEPLOY"
			_primary.pressed.connect(host.show_expedition)
		&"EXPEDITION":
			expedition.start_presentation()
		&"RESULT":
			_title.text = "EXPEDITION RESULT / RETURN"
			_summary.text = "Outcome: %s\nCargo: %s\nDurability: %s\nBlueprint records retained: %d" % [state.result.get("outcome", "—"), state.result.get("cargo", "—"), state.result.get("durability", "—"), state.blueprint.get("saved_blueprints", []).size()]
			_primary.text = "RETURN TO WORKSHOP"
			_primary.pressed.connect(host.show_workshop)


func _disconnect_actions() -> void:
	for connection in _primary.pressed.get_connections():
		_primary.pressed.disconnect(connection.callable)
	for connection in _secondary.pressed.get_connections():
		_secondary.pressed.disconnect(connection.callable)
