## Regresion headless de lectura visual del Ciclope sobre EMBESTIDOR (#2147 / #2091).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const CICLOPE = preload("res://guion/juicio_combate_ciclope_3d.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_montaje_y_telegraph()
	_probar_carga_conserva_rumbo()
	_probar_recuperacion_legible()
	_probar_reduccion_movimiento()
	_probar_presentacion_sin_autoridad_de_gameplay()
	print("ciclope_combate_2091: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _nueva_presentacion() -> Dictionary:
	var rival := Node3D.new()
	get_root().add_child(rival)
	return CICLOPE.montar(rival)


func _probar_montaje_y_telegraph() -> void:
	var presentacion := _nueva_presentacion()
	_comprobar(not presentacion.is_empty(), "monta presentacion")
	var raiz := presentacion.get("raiz") as Node3D
	var cabeza := presentacion.get("cabeza") as MeshInstance3D
	var ojo := presentacion.get("ojo") as MeshInstance3D
	var estela := presentacion.get("estela") as MeshInstance3D
	_comprobar(
		raiz != null and cabeza != null and ojo != null and estela != null,
		"expone piezas canonicas"
	)
	if raiz == null or cabeza == null or ojo == null or estela == null:
		return

	CICLOPE.pintar(presentacion, ARQUETIPOS.TELEGRAFIAR, false)
	_comprobar(raiz.rotation.x < 0.0, "telegraph inclina masa hacia delante")
	_comprobar(cabeza.position.y < 2.08, "telegraph baja la cabeza")
	_comprobar(cabeza.rotation.x < 0.0, "telegraph orienta cabeza al frente")
	_comprobar(not estela.visible, "telegraph no finge que la carga ya empezo")
	var material := ojo.material_override as StandardMaterial3D
	_comprobar(
		material != null and material.emission_energy_multiplier > 1.0,
		"telegraph refuerza el ojo como señal estatica",
	)
	raiz.get_parent().free()


func _probar_carga_conserva_rumbo() -> void:
	var presentacion := _nueva_presentacion()
	var raiz := presentacion.get("raiz") as Node3D
	var cabeza := presentacion.get("cabeza") as MeshInstance3D
	var estela := presentacion.get("estela") as MeshInstance3D
	if raiz == null or cabeza == null or estela == null:
		_comprobar(false, "carga tiene piezas validas")
		return

	raiz.rotation.y = 0.73
	CICLOPE.pintar(presentacion, ARQUETIPOS.CARGAR, false)
	_comprobar(is_equal_approx(raiz.rotation.y, 0.73), "CARGAR no corrige el rumbo fijado")
	_comprobar(raiz.rotation.x < deg_to_rad(-10.0), "carga conserva pose pesada frontal")
	_comprobar(cabeza.position.y < 2.0, "carga comprime silueta")
	_comprobar(estela.visible, "carga animada muestra estela")
	raiz.get_parent().free()


func _probar_recuperacion_legible() -> void:
	var presentacion := _nueva_presentacion()
	var raiz := presentacion.get("raiz") as Node3D
	var cabeza := presentacion.get("cabeza") as MeshInstance3D
	var ojo := presentacion.get("ojo") as MeshInstance3D
	var estela := presentacion.get("estela") as MeshInstance3D
	if raiz == null or cabeza == null or ojo == null or estela == null:
		_comprobar(false, "recuperacion tiene piezas validas")
		return

	CICLOPE.pintar(presentacion, ARQUETIPOS.RECUPERAR, false)
	_comprobar(raiz.rotation.x > 0.0, "recuperacion abre la masa hacia atras")
	_comprobar(cabeza.position.y < 1.9, "recuperacion baja cabeza de forma distinta")
	_comprobar(cabeza.rotation.x > 0.0, "recuperacion invierte la pose del telegraph")
	_comprobar(not estela.visible, "recuperacion apaga estela")
	var material := ojo.material_override as StandardMaterial3D
	_comprobar(
		material != null and material.emission_energy_multiplier < 0.8,
		"recuperacion baja la intensidad del ojo",
	)
	raiz.get_parent().free()


func _probar_reduccion_movimiento() -> void:
	var animada := _nueva_presentacion()
	var raiz_animada := animada.get("raiz") as Node3D
	var cabeza_animada := animada.get("cabeza") as MeshInstance3D
	var estela_animada := animada.get("estela") as MeshInstance3D
	CICLOPE.pintar(animada, ARQUETIPOS.CARGAR, false)

	var reducida := _nueva_presentacion()
	var raiz_reducida := reducida.get("raiz") as Node3D
	var cabeza_reducida := reducida.get("cabeza") as MeshInstance3D
	var estela_reducida := reducida.get("estela") as MeshInstance3D
	CICLOPE.pintar(reducida, ARQUETIPOS.CARGAR, true)

	if (
		raiz_animada == null
		or cabeza_animada == null
		or estela_animada == null
		or raiz_reducida == null
		or cabeza_reducida == null
		or estela_reducida == null
	):
		_comprobar(false, "reduccion tiene piezas validas")
		return

	_comprobar(
		is_equal_approx(raiz_animada.rotation.x, raiz_reducida.rotation.x),
		"reduccion conserva pose/timing de CARGAR",
	)
	_comprobar(
		is_equal_approx(cabeza_animada.position.y, cabeza_reducida.position.y),
		"reduccion conserva lectura corporal",
	)
	_comprobar(estela_animada.visible, "modo normal conserva estela decorativa")
	_comprobar(not estela_reducida.visible, "reduccion elimina solo estela decorativa")
	raiz_animada.get_parent().free()
	raiz_reducida.get_parent().free()


func _probar_presentacion_sin_autoridad_de_gameplay() -> void:
	var fuente := FileAccess.get_file_as_string("res://guion/juicio_combate_ciclope_3d.gd")
	for prohibido in [
		"_aplicar_impacto",
		"resultado_ataque_rival",
		"Partida.",
		"Jornada.",
		"loot",
		"XP",
		"ReligionEventos",
		"CombateContextual",
	]:
		_comprobar(
			not fuente.contains(prohibido), "presentacion no contiene autoridad: " + prohibido
		)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #2147 CICLOPE: " + nombre)
