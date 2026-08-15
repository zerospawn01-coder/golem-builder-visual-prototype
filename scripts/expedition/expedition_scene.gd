extends Control

@onready var presenter: ExpeditionPresenter = $ExpeditionPresenter
@onready var source: MockTelemetrySource = $MockTelemetrySource
@onready var telemetry_row: HBoxContainer = %TelemetryRow
@onready var depth_label: Label = %DepthValue
@onready var durability_label: Label = %DurabilityValue
@onready var cargo_label: Label = %CargoValue
@onready var status_label: Label = %StatusValue
@onready var diagnostic_log: RichTextLabel = %DiagnosticLog
@onready var hazard_panel: PanelContainer = %HazardPanel
@onready var hazard_label: Label = %HazardLabel
@onready var decision_ui: HBoxContainer = %DecisionUI
@onready var golem_view: GolemView = %GolemView


func _ready() -> void:
	presenter.telemetry_presented.connect(_present)
	presenter.telemetry_rejected.connect(_on_rejected)
	source.telemetry_received.connect(presenter.accept)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	source.start()


func _present(telemetry: ExpeditionTelemetry) -> void:
	depth_label.text = str(telemetry.depth)
	durability_label.text = "%d%%" % telemetry.durability
	cargo_label.text = "%d / %d" % [telemetry.cargo, telemetry.cargo_capacity]
	status_label.text = telemetry.status
	golem_view.set_status(telemetry.status)
	decision_ui.visible = telemetry.decision_state == "CONTINUE_RETURN"
	hazard_panel.visible = not telemetry.hazards.is_empty()
	if not telemetry.hazards.is_empty():
		var hazard := telemetry.hazards[0]
		hazard_label.text = "WARNING: %s / SEVERITY %s" % [hazard.get("type", "UNKNOWN"), hazard.get("severity", "?")]
	for event in telemetry.log_events:
		diagnostic_log.append_text("[%03d] %-14s %s\n" % [telemetry.sequence, event.get("type", "EVENT"), event.get("message", "")])


func _on_rejected(sequence: int, reason: String) -> void:
	diagnostic_log.append_text("[---] REJECTED       sequence=%d (%s)\n" % [sequence, reason])


func _apply_responsive_layout() -> void:
	apply_responsive_layout_for_width(get_viewport_rect().size.x)


func apply_responsive_layout_for_width(viewport_width: float) -> void:
	var mobile := viewport_width < 720.0
	telemetry_row.add_theme_constant_override("separation", 8 if mobile else 28)
	%Title.text = "GBE / EXPEDITION" if mobile else "GOLEM BUILDER EXPEDITION / TELEMETRY MONITOR"
	%MainSplit.vertical = mobile
