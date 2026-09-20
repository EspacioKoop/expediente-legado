## El nombre de una figura va SOBRE su cabeza, y se entra lejos de quien está
## sentado (#275).
##
## Los dos salieron del mismo playtest y se miden igual: se construye el espacio
## de verdad con `Espacio3D` y se compara la altura del `Label3D` contra la caja
## envolvente real de la figura. No se inspecciona texto fuente ni se fija un
## número mágico: si mañana cambia `persona.fbx`, la prueba sigue diciendo lo
## mismo —el nombre está por encima de la cabeza— sin tener que reescribirse.
extends SceneTree

## Holgura mínima entre la entrada y un sitio de compañero. Por debajo de esto
## la primera pantalla jugable es la cara de alguien: no es una preferencia
## estética, es lo que el propio catálogo ya exige para el cuñado.
const HOLGURA_ENTRADA := 2.5

## Fracción máxima de la altura de una figura que puede ocupar su cabeza. Una
## cabeza humana ronda un séptimo del cuerpo; se deja holgura de sobra, porque
## lo que esto persigue es la cabeza de media persona, no un milímetro de más.
const MAXIMO_CABEZA := 0.25

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	await _probar_rotulo_sobre_la_cabeza()
	await _probar_cabeza_en_proporcion()
	_probar_entrada_despejada()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_rotulo_sobre_la_cabeza() -> void:
	var raiz := Node3D.new()
	root.add_child(raiz)
	(
		Espacio3D
		. construir(
			raiz,
			{
				"suelo": Vector2(10, 10),
				"entrada": Vector3.ZERO,
				"figuras":
				[
					{
						"pos": Vector3(0, 0, 0),
						"color": Color(0.34, 0.33, 0.31),
						"rotulo": "CON CUERPO",
						"modelo": "persona",
					},
					{
						"pos": Vector3(-3, 0, 0),
						"color": Color(0.32, 0.31, 0.34),
						"rotulo": "CON CARA",
						"modelo": "persona",
						# Con retrato la cabeza procedural sube la coronilla por
						# encima de ALTO_PERSONA: es el caso que de verdad aprieta.
						"retrato": "becario",
					},
					{
						"pos": Vector3(3, 0, 0),
						"color": Color(0.30, 0.28, 0.34),
						"rotulo": "SILUETA",
					},
				],
			}
		)
	)
	for i in 8:
		await process_frame

	var rotulos := _rotulos(raiz)
	_comprobar(rotulos.size(), 3, "se montan los tres nombres")
	for nombre in rotulos:
		var figura := nombre.get_parent() as Node3D
		var caja := _envolvente(figura, nombre)
		if caja.size == Vector3.ZERO:
			_comprobar(false, true, "la figura de %s tiene geometría medible" % nombre.text)
			continue
		var coronilla := caja.position.y + caja.size.y
		_comprobar(
			nombre.global_position.y > coronilla,
			true,
			(
				"el nombre de %s va sobre la cabeza (rótulo %.2f, coronilla %.2f)"
				% [nombre.text, nombre.global_position.y, coronilla]
			)
		)

	raiz.queue_free()


## La cabeza de una figura con retrato no puede medir media persona. El pase de
## corrección la reduce al ratio declarado, y antes lo intentaba escalando el
## `BoneAttachment3D`: ese nodo reescribe su transformación desde el hueso en
## cada fotograma, así que la reducción se perdía y solo las caras genéricas
## salían en proporción.
func _probar_cabeza_en_proporcion() -> void:
	var raiz := Node3D.new()
	root.add_child(raiz)
	(
		Espacio3D
		. construir(
			raiz,
			{
				"suelo": Vector2(10, 10),
				"entrada": Vector3.ZERO,
				"figuras":
				[
					{
						"pos": Vector3.ZERO,
						"color": Color(0.33, 0.32, 0.29),
						"modelo": "persona",
						"retrato": "riegos",
					},
				],
			}
		)
	)
	for i in 12:
		await process_frame

	var esqueleto := _esqueleto(raiz)
	_comprobar(esqueleto != null, "la figura con retrato conserva Skeleton3D")
	if esqueleto == null:
		raiz.queue_free()
		return
	var hueso := esqueleto.find_bone("Head")
	_comprobar(hueso >= 0, "el rig declara el hueso Head")
	if hueso < 0:
		raiz.queue_free()
		return

	var completa := _envolvente(esqueleto, null)
	var cabeza := AABB()
	for enganche in esqueleto.get_children():
		if enganche is BoneAttachment3D and (enganche as BoneAttachment3D).bone_idx == hueso:
			var caja := _envolvente(enganche, null)
			if caja.size.y > cabeza.size.y:
				cabeza = caja
	var fraccion := cabeza.size.y / maxf(completa.size.y, 0.001)
	_comprobar(
		fraccion > 0.0 and fraccion < MAXIMO_CABEZA,
		true,
		(
			"la cabeza con retrato queda en proporción (fracción %.3f, tope %.2f)"
			% [fraccion, MAXIMO_CABEZA]
		)
	)
	raiz.queue_free()


func _esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null


func _probar_entrada_despejada() -> void:
	var pegados := []
	for fase in EspaciosCatalogo.POR_FASE:
		var espacio: Dictionary = EspaciosCatalogo.POR_FASE[fase]
		var entrada: Vector3 = espacio["entrada"]
		for sitio in espacio.get("sitios_companeros", []):
			if Vector3(sitio).distance_to(entrada) < HOLGURA_ENTRADA:
				pegados.append("%s %s" % [fase, sitio])
	_comprobar(pegados, [], "no se entra encima de un compañero")


## La caja envolvente del cuerpo, dejando fuera el propio rótulo: un `Label3D`
## también es geometría, y contarlo haría que el nombre estuviera siempre
## «por debajo» de sí mismo.
func _envolvente(figura: Node3D, rotulo) -> AABB:
	var total := AABB()
	var primera := true
	for malla in _mallas(figura, rotulo):
		var caja := malla.global_transform * malla.get_aabb()
		total = caja if primera else total.merge(caja)
		primera = false
	return total


func _mallas(nodo: Node, rotulo) -> Array[VisualInstance3D]:
	var salida: Array[VisualInstance3D] = []
	if nodo == rotulo:
		return salida
	if nodo is MeshInstance3D:
		salida.append(nodo)
	for hijo in nodo.get_children():
		salida.append_array(_mallas(hijo, rotulo))
	return salida


func _rotulos(nodo: Node) -> Array[Label3D]:
	var salida: Array[Label3D] = []
	if nodo is Label3D:
		salida.append(nodo)
	for hijo in nodo.get_children():
		salida.append_array(_rotulos(hijo))
	return salida


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO rótulos #275: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
