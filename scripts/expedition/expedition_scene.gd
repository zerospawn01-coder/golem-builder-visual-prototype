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
@onready var motion_controller: MotionController = %MotionController
@onready var environment_controller: EnvironmentController = %EnvironmentController


func _ready() -> void:
	presenter.presentation_state_changed.connect(_apply_presentation_state)
	presenter.presentation_state_changed.connect(motion_controller.apply_state)
	presenter.presentation_state_changed.connect(environment_controller.apply_state)
	presenter.transient_events_emitted.connect(_handle_transient_events)
	presenter.transient_events_emitted.connect(motion_controller.apply_transient_events)
	presenter.telemetry_rejected.connect(_on_rejected)
	source.telemetry_received.connect(presenter.accept)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	source.start()


func _apply_presentation_state(state: PresentationState) -> void:
	depth_label.text = str(state.telemetry_state["depth"])
	durability_label.text = "%d%%" % state.telemetry_state["durability"]
	cargo_label.text = "%d / %d" % [state.telemetry_state["cargo"], state.telemetry_state["cargo_capacity"]]
	status_label.text = state.golem_state["status"]
	decision_ui.visible = state.decision_state == "CONTINUE_RETURN"
	hazard_panel.visible = state.warning_state["active"]
	if state.warning_state["active"]:
		var hazard: Dictionary = state.warning_state["hazards"][0]
		hazard_label.text = "WARNING: %s / SEVERITY %s" % [hazard.get("type", "UNKNOWN"), hazard.get("severity", "?")]


func _handle_transient_events(batch: TransientEventBatch) -> void:
	for event in batch.events:
		diagnostic_log.append_text("[%03d] %-14s %s\n" % [batch.sequence, event.get("type", "EVENT"), event.get("message", "")])


func _on_rejected(sequence: int, reason: String) -> void:
	diagnostic_log.append_text("[---] REJECTED       sequence=%d (%s)\n" % [sequence, reason])


func _apply_responsive_layout() -> void:
	apply_responsive_layout_for_width(get_viewport_rect().size.x)


func apply_responsive_layout_for_width(viewport_width: float) -> void:
	var mobile := viewport_width < 720.0
	telemetry_row.add_theme_constant_override("separation", 8 if mobile else 28)
	%Title.text = "GBE / EXPEDITION" if mobile else "GOLEM BUILDER EXPEDITION / TELEMETRY MONITOR"
	%MainSplit.vertical = mobile
