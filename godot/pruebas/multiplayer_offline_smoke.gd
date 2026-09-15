extends SceneTree

## Smoke standalone de #375.
## Uso: godot4 --headless --path godot --script res://pruebas/multiplayer_offline_smoke.gd

const EventoOnline = preload("res://guion/red/evento_online.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")
const AHORA := 2_000_000_000


func _init() -> void:
	_probar_transporte_nulo()
	_probar_fixture_y_deduplicacion()
	_probar_descartes_seguros()
	_probar_timeout_no_bloqueante()
	print("Multiplayer offline-first smoke: OK")
	quit(0)


func _evento(overrides: Dictionary = {}) -> Dictionary:
	var evento := {
		"protocol_version": EventoOnline.PROTOCOL_VERSION,
		"kind": "signal",
		"game_build": "test-375",
		"scene_key": "oficina/archivo",
		"created_at": AHORA - 10,
		"expires_at": AHORA + 100,
		"actor_public_id": "anon-test-01",
		"event_id": "evt-001",
		"payload": {"code": "luz_verde", "value": 1},
	}
	for clave in overrides:
		evento[clave] = overrides[clave]
	return evento


func _probar_transporte_nulo() -> void:
	var transporte := TransporteNulo.new()
	var consulta := transporte.consultar_eventos("oficina/archivo", "signal", AHORA)
	_assert(consulta["ok"] and consulta["events"].is_empty(), "NullTransport debe devolver []")
	var publicacion := transporte.publicar_evento(_evento(), AHORA)
	_assert(publicacion["ok"], "NullTransport debe aceptar una publicación válida sin bloquear")
	_assert(publicacion["status"] == "discarded_offline", "el descarte offline debe ser explícito")
	_assert(not publicacion["delivered"], "NullTransport nunca debe afirmar entrega remota")


func _probar_fixture_y_deduplicacion() -> void:
	var original := _evento()
	var con_campo_desconocido := original.duplicate(true)
	con_campo_desconocido["campo_futuro"] = "se ignora"
	var fixture := TransporteFixture.new([original, con_campo_desconocido])
	var consulta := fixture.consultar_eventos("oficina/archivo", "signal", AHORA)
	_assert(consulta["ok"], "fixture debe consultar sin servidor")
	_assert(consulta["events"].size() == 1, "eventos duplicados deben colapsarse")
	_assert(
		not consulta["events"][0].has("campo_futuro"),
		"campos desconocidos no deben entrar al contrato normalizado"
	)
	var publicacion := fixture.publicar_evento(_evento({"event_id": "evt-out"}), AHORA)
	_assert(
		publicacion["ok"] and fixture.publicados().size() == 1, "fixture debe capturar salientes"
	)


func _probar_descartes_seguros() -> void:
	var casos := [
		_evento({"protocol_version": EventoOnline.PROTOCOL_VERSION + 1}),
		_evento({"kind": "tipo_desconocido"}),
		_evento({"expires_at": AHORA - 1}),
		_evento({"expires_at": AHORA + 5000}),
		_evento({"payload": {"objeto": RefCounted.new()}}),
		_evento({"payload": {"texto": "x".repeat(2000)}}),
		{"protocol_version": EventoOnline.PROTOCOL_VERSION, "kind": "signal"},
	]
	var fixture := TransporteFixture.new(casos)
	var consulta := fixture.consultar_eventos("oficina/archivo", "signal", AHORA)
	_assert(consulta["ok"], "datos inválidos no deben romper una consulta")
	_assert(consulta["events"].is_empty(), "datos inválidos/futuros deben ignorarse")


func _probar_timeout_no_bloqueante() -> void:
	var fixture := TransporteFixture.new([_evento()])
	fixture.simular_timeout(true)
	var consulta := fixture.consultar_eventos("oficina/archivo", "signal", AHORA)
	_assert(not consulta["ok"], "timeout debe quedar observable")
	_assert(consulta["status"] == "timeout", "timeout debe tener estado estable")
	_assert(consulta["events"].is_empty(), "timeout debe degradar a una lista vacía")
	var health := fixture.health()
	_assert(not health["ok"] and not health["online"], "health debe reflejar timeout sin excepción")


func _assert(condicion: bool, mensaje: String) -> void:
	if condicion:
		return
	push_error("Multiplayer offline-first smoke: %s" % mensaje)
	quit(1)
