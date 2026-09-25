## Regresión standalone del estado temporal extraído en #1191.
##
##     godot4 --headless --path godot --script pruebas/pruebas_juicio_estado_temporal_1191.gd
extends SceneTree

const ESTADO = preload("res://guion/juicio_combate_estado_temporal.gd")
const JUICIO = preload("res://guion/juicio_combate_3d.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_descuento_y_expiraciones()
	_probar_compatibilidad_del_controlador()
	print("estado_temporal_1191: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_descuento_y_expiraciones() -> void:
	var estado := ESTADO.new()
	estado.recarga_jugador = 1.0
	estado.recarga_rival = 1.0
	estado.esquiva = 1.0
	estado.enredo = 1.0
	estado.invulnerabilidad_jungiana = 1.0
	estado.sacudida_camara = 1.0
	estado.aviso_jungiano = 1.0
	estado.doctrina = 1.0

	var expirados := estado.descontar(0.25)
	_comprobar(expirados.is_empty(), "un paso parcial no inventa expiraciones")
	_comprobar(is_equal_approx(estado.recarga_jugador, 0.75), "descuenta recarga del jugador")
	_comprobar(is_equal_approx(estado.enredo, 0.75), "descuenta enredo")
	_comprobar(is_equal_approx(estado.doctrina, 0.75), "descuenta doctrina")

	estado.aviso_jungiano = 0.1
	estado.doctrina = 0.0
	expirados = estado.descontar(0.2)
	_comprobar(expirados.has("aviso_jungiano"), "avisa cuando un contador activo expira")
	_comprobar(not expirados.has("doctrina"), "un contador parado no vuelve a expirar")
	_comprobar(is_zero_approx(estado.aviso_jungiano), "los contadores no bajan de cero")


func _probar_compatibilidad_del_controlador() -> void:
	var juicio := JUICIO.new()
	juicio._recarga_jugador = 0.5
	juicio._esquiva = 0.4
	juicio.set("_enredo", 0.3)

	_comprobar(
		is_equal_approx(juicio._estado_temporal.recarga_jugador, 0.5),
		"la escritura histórica delega la recarga al estado",
	)
	_comprobar(
		is_equal_approx(float(juicio.get("_esquiva")), 0.4),
		"Object.get conserva la propiedad histórica de esquiva",
	)
	_comprobar(
		is_equal_approx(float(juicio.get("_enredo")), 0.3),
		"JuicioFeedbackRitual puede seguir leyendo enredo por nombre",
	)

	juicio._descontar_temporizadores(0.1)
	_comprobar(
		is_equal_approx(juicio._recarga_jugador, 0.4),
		"el controlador delega el descuento sin cambiar el contrato",
	)
	_comprobar(is_equal_approx(juicio._esquiva, 0.3), "la esquiva conserva su cuenta atrás")
	_comprobar(is_equal_approx(float(juicio.get("_enredo")), 0.2), "enredo sigue sincronizado")
	juicio.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO #1191: %s" % nombre)
