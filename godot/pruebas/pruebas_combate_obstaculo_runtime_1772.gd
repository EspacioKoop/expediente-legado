extends SceneTree

const MOVIMIENTO = preload("res://guion/juicio_combate_rival_movimiento_3d.gd")
const VOLCAR = preload("res://guion/juicio_combate_ambiental_volcar_1772.gd")

var _pasadas := 0
var _fallos := 0


class HostPrueba:
	extends Node3D

	var _volcar_1772: Dictionary = {}
	var _radio_arena := 5.0
	var _raiz := 2143


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_rodeo_desde_volumen_real()
	_probar_lado_estable()
	_probar_ruta_libre()
	_probar_objetivo_ocupado_espera()
	_probar_expiracion_devuelve_control()
	_probar_runtime_invalido_no_interfiere()
	print("combate_obstaculo_runtime_1772: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_rodeo_desde_volumen_real() -> void:
	var host := _host_con_volcar()
	var plan := (
		MOVIMIENTO
		. plan_volcar(
			host,
			Vector3(-4.0, 0.0, 0.0),
			Vector3(4.0, 0.0, 0.0),
		)
	)
	_comprobar(String(plan.get("intencion", "")) == "rodear", "VOLCAR activo fuerza rodeo")
	_comprobar(bool(plan.get("bloqueado_directo", false)), "el plan reconoce la ruta bloqueada")
	_comprobar(int(plan.get("lado", 0)) != 0, "el rodeo elige un lado explicito")
	_comprobar(
		not (plan.get("direccion", Vector3.ZERO) as Vector3).is_zero_approx(),
		"el rodeo entrega direccion util",
	)
	host.free()


func _probar_lado_estable() -> void:
	var host := _host_con_volcar()
	var origen := Vector3(-4.0, 0.0, 0.0)
	var objetivo := Vector3(4.0, 0.0, 0.0)
	var primero := MOVIMIENTO.plan_volcar(host, origen, objetivo)
	var direccion: Vector3 = primero.get("direccion", Vector3.ZERO)
	var segundo := MOVIMIENTO.plan_volcar(host, origen + direccion * 0.20, objetivo)
	_comprobar(String(primero.get("intencion", "")) == "rodear", "primer tick rodea")
	_comprobar(String(segundo.get("intencion", "")) == "rodear", "segundo tick sigue rodeando")
	_comprobar(
		int(primero.get("lado", 0)) == int(segundo.get("lado", 0)),
		"la raiz fija el mismo lado durante la vida del obstaculo",
	)
	host.free()


func _probar_ruta_libre() -> void:
	var host := _host_con_volcar()
	var plan := (
		MOVIMIENTO
		. plan_volcar(
			host,
			Vector3(-4.0, 0.0, 3.0),
			Vector3(4.0, 0.0, 3.0),
		)
	)
	_comprobar(String(plan.get("intencion", "")) == "directo", "VOLCAR no desvía una ruta libre")
	_comprobar(not bool(plan.get("bloqueado_directo", true)), "ruta libre conserva directo")
	host.free()


func _probar_objetivo_ocupado_espera() -> void:
	var host := _host_con_volcar()
	var plan := (
		MOVIMIENTO
		. plan_volcar(
			host,
			Vector3(-4.0, 0.0, 0.0),
			Vector3(-2.3, 0.0, 0.0),
		)
	)
	_comprobar(String(plan.get("intencion", "")) == "esperar", "no persigue dentro del mueble")
	_comprobar(
		(plan.get("direccion", Vector3.ZERO) as Vector3).is_zero_approx(),
		"esperar no inyecta movimiento",
	)
	host.free()


func _probar_expiracion_devuelve_control() -> void:
	var host := _host_con_volcar()
	var activo := (
		MOVIMIENTO
		. plan_volcar(
			host,
			Vector3(-4.0, 0.0, 0.0),
			Vector3(4.0, 0.0, 0.0),
		)
	)
	_comprobar(String(activo.get("intencion", "")) == "rodear", "antes de expirar evita el volumen")
	host._volcar_1772["restante"] = 0.0
	var expirado := (
		MOVIMIENTO
		. plan_volcar(
			host,
			Vector3(-4.0, 0.0, 0.0),
			Vector3(4.0, 0.0, 0.0),
		)
	)
	_comprobar(expirado.is_empty(), "al expirar no sustituye el plan normal")
	host.free()


func _probar_runtime_invalido_no_interfiere() -> void:
	var host := HostPrueba.new()
	get_root().add_child(host)
	_comprobar(
		MOVIMIENTO.plan_volcar(host, Vector3.ZERO, Vector3.ONE).is_empty(),
		"sin VOLCAR el movimiento queda intacto",
	)
	host._volcar_1772 = {"restante": 1.0}
	_comprobar(
		MOVIMIENTO.plan_volcar(host, Vector3.ZERO, Vector3.ONE).is_empty(),
		"sin prop valido aplica fallback directo",
	)
	host.free()


func _host_con_volcar() -> HostPrueba:
	var host := HostPrueba.new()
	get_root().add_child(host)
	host._volcar_1772 = VOLCAR.montar(host)
	host._volcar_1772["restante"] = 1.0
	var prop := host._volcar_1772.get("prop") as StaticBody3D
	prop.rotation_degrees.z = 90.0
	prop.collision_layer = VOLCAR.CAPA_OBSTACULO
	return host


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error("FALLO #2143: " + mensaje)
