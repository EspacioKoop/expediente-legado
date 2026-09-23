## Las sombras de un sitio: quién las proyecta y quién no (#275).
##
## Desde que el proyecto usa Forward+ las luces proyectan sombra, y eso
## convierte en error lo que antes era inocuo: una lámpara metida dentro de
## geometría que proyecta se tapa a sí misma y apaga la sala. La prueba
## construye el espacio real con `Espacio3D` y mide sobre el árbol resultante,
## sin depender del nombre de ningún nodo.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var raiz := Node3D.new()
	root.add_child(raiz)
	Espacio3D.construir(raiz, EspaciosCatalogo.OFICINA.duplicate(true))
	await process_frame
	await process_frame

	var todas := _luces(raiz)
	var luces: Array[OmniLight3D] = []
	for luz in todas:
		if String(luz.name).begins_with(Espacio3D.NOMBRE_LUZ_SALA):
			luces.append(luz)
	_comprobar(not luces.is_empty(), true, "la oficina declara lámparas de sala")

	# La oficina se ilumina por píxel desde #789, y ahí el modo de sombra dejó de
	# ser una preferencia de coste: medido en GPU, en paraboloide dual estas
	# lámparas dan una imagen idéntica píxel a píxel con la sombra encendida y
	# apagada —Forward+ no dibuja ese modo—, así que la sala se quedaba sin una
	# sola sombra de contacto. Donde la sombra se ve, se exige cubo.
	for luz in luces:
		_comprobar(luz.shadow_enabled, true, "cada lámpara proyecta sombra")
		_comprobar(
			luz.omni_shadow_mode,
			OmniLight3D.SHADOW_CUBE,
			"la sombra de un sitio con luz por píxel va en cubo, que es el modo que dibuja",
		)

	# El contrato que importa: una lámpara no puede quedar encerrada en algo que
	# proyecte sombra. Se mide por geometría, así que vale para cualquier sitio
	# y para cualquier carcasa que se añada después.
	# Se exige a TODA luz que proyecte sombra, sea de sala o no: es la que puede
	# quedarse encerrada. Una brasa de cigarro no proyecta y por eso no entra.
	var encerradas := []
	for luz in todas:
		if not luz.shadow_enabled:
			continue
		for malla in _mallas(raiz):
			if malla.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				continue
			if (malla.global_transform * malla.get_aabb()).has_point(luz.global_position):
				encerradas.append("%s dentro de %s" % [luz.global_position, malla.name])
	_comprobar(encerradas, [], "ninguna lámpara queda dentro de algo que proyecta sombra")

	# Suelo y techo son las dos superficies más grandes y su sombra no describe
	# nada: el techo, además, taparía sus propias lámparas.
	var horizontales := _mayores_horizontales(raiz)
	_comprobar(horizontales.size(), 2, "se localizan suelo y techo por tamaño")
	for malla in horizontales:
		_comprobar(
			malla.cast_shadow,
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			"la superficie horizontal grande en y=%.2f no proyecta" % malla.global_position.y,
		)

	# Y lo que sí tiene que seguir proyectando: los muebles, que son lo que el
	# jugador necesita ver apoyado en el suelo.
	var proyectan := 0
	for malla in _mallas(raiz):
		if malla.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			proyectan += 1
	_comprobar(proyectan > 10, true, "el mobiliario sigue proyectando (%d mallas)" % proyectan)

	raiz.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


## Las dos mallas horizontales de mayor superficie: en una sala rectangular son
## el suelo y el techo, sin necesidad de que nadie les ponga nombre.
func _mayores_horizontales(raiz: Node) -> Array[MeshInstance3D]:
	var candidatas: Array[MeshInstance3D] = []
	for malla in _mallas(raiz):
		var caja := malla.get_aabb().size
		if caja.y < caja.x * 0.2 and caja.y < caja.z * 0.2:
			candidatas.append(malla)
	candidatas.sort_custom(
		func(a, b):
			return (
				a.get_aabb().size.x * a.get_aabb().size.z
				> (b.get_aabb().size.x * b.get_aabb().size.z)
			)
	)
	return candidatas.slice(0, 2)


func _luces(n: Node) -> Array[OmniLight3D]:
	var salida: Array[OmniLight3D] = []
	if n is OmniLight3D:
		salida.append(n)
	for h in n.get_children():
		salida.append_array(_luces(h))
	return salida


func _mallas(n: Node) -> Array[MeshInstance3D]:
	var salida: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		salida.append(n)
	for h in n.get_children():
		salida.append_array(_mallas(h))
	return salida


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO sombras #275: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
