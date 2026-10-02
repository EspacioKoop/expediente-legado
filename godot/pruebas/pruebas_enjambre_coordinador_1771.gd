## Regresión del coordinador puro de ENJAMBRE (#2073).
##
##   godot4 --headless --path godot --script pruebas/pruebas_enjambre_coordinador_1771.gd
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const ARENA = preload("res://guion/juicio_combate_arena_3d.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_limites()
	_probar_determinismo_y_copia()
	_probar_presupuesto_compartido()
	_probar_hueco_liberado_en_mismo_tick()
	_probar_montaje_arena_3d()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_limites() -> void:
	_comprobar(HOST.tamano_enjambre(0) == 2, "cantidad baja se eleva a dos")
	_comprobar(HOST.tamano_enjambre(2) == 2, "dos unidades se conservan")
	_comprobar(HOST.tamano_enjambre(3) == 3, "tres unidades se conservan")
	_comprobar(HOST.tamano_enjambre(99) == 3, "cantidad alta se recorta a tres")
	_comprobar(HOST.presupuesto_enjambre(-5) == 1, "presupuesto negativo se eleva a uno")
	_comprobar(HOST.presupuesto_enjambre(0) == 1, "presupuesto cero se eleva a uno")
	_comprobar(HOST.presupuesto_enjambre(2) == 2, "presupuesto canónico se conserva")
	_comprobar(
		HOST.presupuesto_enjambre(999) == 2, "presupuesto alto se recorta al máximo canónico"
	)


func _probar_determinismo_y_copia() -> void:
	var a := HOST.nuevo_enjambre(1771, 3)
	var b := HOST.nuevo_enjambre(1771, 3)
	_comprobar(a == b, "misma raíz produce el mismo enjambre")
	_comprobar(a.size() == 3, "el host crea tres unidades cuando se solicitan")
	for unidad in a:
		unidad["cooldown"] = 0.0
	var original := a.duplicate(true)
	var paso := HOST.avanzar_enjambre(a, 0.01)
	_comprobar(a == original, "avanzar no muta el array ni sus diccionarios de entrada")
	_comprobar(paso["unidades"].size() == 3, "el resultado conserva todas las unidades")


func _probar_presupuesto_compartido() -> void:
	var unidades := HOST.nuevo_enjambre(1771, 3)
	for unidad in unidades:
		unidad["cooldown"] = 0.0
	var paso := HOST.avanzar_enjambre(unidades, 0.01, 999)
	var nuevas: Array = paso["unidades"]
	_comprobar(_contar_atacantes(nuevas) == 2, "ni un presupuesto inválido deja arrancar a tres")
	_comprobar(int(paso["atacantes_activos"]) == 2, "el contador final respeta el techo compartido")
	_comprobar(
		String(nuevas[2]["estado"]) == ARQUETIPOS.ESPERA,
		"la tercera unidad espera cuando los dos huecos están ocupados",
	)


func _probar_hueco_liberado_en_mismo_tick() -> void:
	var unidades := HOST.nuevo_enjambre(1771, 3)
	for unidad in unidades:
		unidad["cooldown"] = 0.0
	unidades[0]["estado"] = ARQUETIPOS.ATACAR
	unidades[0]["temporizador"] = 0.0
	var paso := HOST.avanzar_enjambre(unidades, 0.01)
	var nuevas: Array = paso["unidades"]
	_comprobar(
		String(nuevas[0]["estado"]) == ARQUETIPOS.RECUPERAR,
		"la unidad que termina ataque libera su hueco",
	)
	_comprobar(
		_contar_atacantes(nuevas) == 2, "dos unidades nuevas pueden ocupar los huecos disponibles"
	)
	_comprobar(
		int(paso["atacantes_activos"]) == 2, "el contador local refleja salidas y entradas del tick"
	)


func _probar_montaje_arena_3d() -> void:
	var estados := HOST.nuevo_enjambre(1771, 3)
	var estados_antes := estados.duplicate(true)
	var raiz_a := Node3D.new()
	get_root().add_child(raiz_a)
	var montado_a := ARENA.montar_enjambre(raiz_a, "enjambre-regresion", Color(0.58, 0.46, 0.22), 3)
	var actores_a: Array = montado_a["actores"]
	_comprobar(int(montado_a["cantidad"]) == 3, "la arena monta tres cuerpos si se solicitan")
	_comprobar(actores_a.size() == 3, "el montaje devuelve los tres actores")

	var posiciones_a: Array[Vector3] = []
	for indice in range(actores_a.size()):
		var actor: Dictionary = actores_a[indice]
		var cuerpo := actor["cuerpo"] as CharacterBody3D
		var figura := actor["figura"] as Node3D
		var aviso := actor["aviso"] as MeshInstance3D
		_comprobar(cuerpo != null, "cada actor usa CharacterBody3D")
		_comprobar(cuerpo.name == "EnjambreRival%d" % indice, "cada cuerpo tiene nombre estable")
		_comprobar(
			figura != null and figura.get_parent() == cuerpo, "la figura pertenece a su cuerpo"
		)
		_comprobar(aviso != null and aviso.get_parent() == cuerpo, "el aviso sigue a su cuerpo")
		_comprobar(not aviso.visible, "el aviso corto empieza oculto")
		posiciones_a.append(cuerpo.position)

	for i in range(posiciones_a.size()):
		for j in range(i + 1, posiciones_a.size()):
			_comprobar(
				posiciones_a[i].distance_to(posiciones_a[j]) > 2.0,
				"los cuerpos arrancan separados y legibles",
			)

	_comprobar(estados == estados_antes, "montar cuerpos no toca estados del coordinador")

	var raiz_b := Node3D.new()
	get_root().add_child(raiz_b)
	var montado_b := ARENA.montar_enjambre(raiz_b, "enjambre-regresion", Color(0.58, 0.46, 0.22), 3)
	var actores_b: Array = montado_b["actores"]
	var determinista := actores_b.size() == actores_a.size()
	if determinista:
		for indice in range(actores_a.size()):
			var cuerpo_a := actores_a[indice]["cuerpo"] as CharacterBody3D
			var cuerpo_b := actores_b[indice]["cuerpo"] as CharacterBody3D
			if cuerpo_a.position != cuerpo_b.position or cuerpo_a.name != cuerpo_b.name:
				determinista = false
				break
	_comprobar(determinista, "el mismo montaje conserva composición y posiciones")

	raiz_a.free()
	raiz_b.free()


func _contar_atacantes(unidades: Array) -> int:
	var total := 0
	for unidad in unidades:
		if String(unidad.get("estado", "")) in HOST.ESTADOS_ATACANTE:
			total += 1
	return total


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)
