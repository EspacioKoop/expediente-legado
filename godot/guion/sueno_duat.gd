## Primer vertical standalone del Duat egipcio noventero (#441).
##
## Este módulo no decide qué noche aparece una familia ni modifica el generador
## común. Reutiliza el contrato de semillas de #442/#472 y una familia espacial
## ya caminable de #279 para preparar un pesaje burocrático reproducible.
##
## El contenido de vigilia es propio: un microdocumental ficticio de 1998. No
## copia personajes, diseños, logos ni escenas de franquicias contemporáneas.
class_name SuenoDuat
extends RefCounted

const ID := "duat"
const FUENTE_TV := "tv:microdocumental_excavaciones_98"
const MAX_OBJETOS := 5
const TOLERANCIA := 0.01

const COLOR_PIEDRA := Color(0.36, 0.27, 0.17)
const COLOR_ORO_APAGADO := Color(0.58, 0.43, 0.18)
const COLOR_BANDEJA := Color(0.22, 0.19, 0.17)
const COLOR_PESO := Color(0.46, 0.38, 0.26)
const POS_PIRAMIDE_INFERIOR := Vector3(0.0, -2.6, -8.0)
const POS_PIRAMIDE_INVERTIDA := Vector3(0.0, 8.8, -8.0)
const POS_PIRAMIDE_INFERIOR_EQUILIBRIO := Vector3(0.0, -0.8, -8.0)
const POS_PIRAMIDE_INVERTIDA_EQUILIBRIO := Vector3(0.0, 6.8, -8.0)


## Punto de integración previsto para la TV de casa. Ver el canal de fondo no
## basta: solo completar el fragmento registra la semilla cultural del día.
static func registrar_documental(jornada: Dictionary, fragmento_completado: bool) -> bool:
	if not fragmento_completado:
		return false
	return SemillasOniricas.activar_semilla_onirica(jornada, ID, FUENTE_TV, 1)


## La escena Duat solo puede vestirse cuando #442 confirma que la familia fue
## activada deliberadamente durante esta jornada.
static func habilitado(jornada: Dictionary) -> bool:
	return SemillasOniricas.familias_activas(jornada).has(ID)


## Construye un reto de balanza a partir de objetos realmente manipulados hoy.
##
## Cada objeto compatible declara:
## - `id`: identificador estable;
## - `peso`: propiedad física observable;
## - `manipulado_hoy`: evita introducir recuerdos que el jugador no tocó;
## - `peso_sellado` opcional: variante observable tras sellar/archivar.
##
## La selección se ordena antes de rotarse con `semilla`, de modo que la misma
## entrada produce siempre el mismo reto aunque el llamador entregue los objetos
## en otro orden. El peso objetivo se construye con una combinación que existe
## realmente entre los objetos seleccionados: nunca exige adivinar moralidad.
static func preparar_pesaje(objetos_conocidos: Array, semilla: int = 0) -> Dictionary:
	var validos := _objetos_validos(objetos_conocidos)
	if validos.is_empty():
		return {}

	var limite := mini(MAX_OBJETOS, validos.size())
	var inicio := posmod(semilla, validos.size())
	var objetos: Array = []
	for desplazamiento in limite:
		objetos.append(validos[(inicio + desplazamiento) % validos.size()].duplicate(true))

	# Con un único objeto el reto sigue siendo físico: el objetivo usa una de sus
	# dos variantes observables. Con varios, alternar posiciones mantiene una
	# combinación reproducible sin convertir el puzzle en inventario completo.
	var paridad := posmod(semilla, 2)
	var peso_objetivo := 0.0
	if objetos.size() == 1:
		var unico: Dictionary = objetos[0]
		peso_objetivo = float(unico.get("peso", 0.0))
		if paridad == 1:
			peso_objetivo = float(unico.get("peso_sellado", peso_objetivo))
	else:
		for indice in objetos.size():
			if indice % 2 == paridad:
				peso_objetivo += float(objetos[indice].get("peso", 0.0))

	return {
		"objetos": objetos,
		"peso_objetivo": peso_objetivo,
		"tolerancia": TOLERANCIA,
		"regla": "peso_observable",
	}


## Evalúa una colocación sin efectos laterales. `seleccion` usa `id -> bool`,
## donde el bool indica si ese objeto se pesa en su variante sellada. IDs que no
## pertenecen al reto se ignoran y un mismo objeto solo puede sumar una vez.
static func evaluar_pesaje(estado: Dictionary, seleccion: Dictionary) -> Dictionary:
	var objetivo := float(estado.get("peso_objetivo", 0.0))
	var tolerancia := float(estado.get("tolerancia", TOLERANCIA))
	var total := 0.0
	var usados: Array[String] = []

	for bruto in estado.get("objetos", []):
		if typeof(bruto) != TYPE_DICTIONARY:
			continue
		var objeto: Dictionary = bruto
		var id := String(objeto.get("id", ""))
		if id.is_empty() or not seleccion.has(id) or usados.has(id):
			continue
		usados.append(id)
		var sellado := bool(seleccion[id])
		var peso := float(objeto.get("peso", 0.0))
		if sellado:
			peso = float(objeto.get("peso_sellado", peso))
		total += peso

	var diferencia := total - objetivo
	return {
		"peso": total,
		"objetivo": objetivo,
		"diferencia": diferencia,
		"equilibrado": objetivo > 0.0 and absf(diferencia) <= tolerancia,
	}


## La accesibilidad altera solo cómo se presenta la transformación. No toca la
## semilla cultural, el conjunto de objetos, el objetivo ni la solución física.
static func presentacion(reduccion_movimiento: bool) -> Dictionary:
	if reduccion_movimiento:
		return {
			"movimiento_arquitectura": "corte_fundido",
			"parpadeo_crt": 0.0,
			"oscilacion_balanza": 0.15,
			"transicion_piramide": "estado_discreto",
		}
	return {
		"movimiento_arquitectura": "desplazamiento_continuo",
		"parpadeo_crt": 0.12,
		"oscilacion_balanza": 1.0,
		"transicion_piramide": "ascenso_descenso",
	}


## Viste un espacio ya construido sin duplicar geometría, progreso o selección
## nocturna. Hasta que se libere el wiring central de #279, esta función permite
## probar el contrato Duat de forma aislada y conectarlo después con una llamada.
static func adaptar_espacio(
	espacio_base: Dictionary,
	jornada: Dictionary,
	objetos_conocidos: Array,
	semilla: int = 0,
	reduccion_movimiento: bool = false
) -> Dictionary:
	if espacio_base.is_empty():
		return {}
	var resultado := espacio_base.duplicate(true)
	if not habilitado(jornada):
		return resultado

	var familia := SuenoFamilias.de(SuenoFamilias.CONVERGENTE)
	if familia.is_empty():
		return resultado

	resultado["identidad_onirica"] = ID
	resultado["contorno"] = familia.get("contorno", PackedVector2Array())
	resultado["altura_contorno"] = float(familia.get("altura", 3.2))
	resultado["entrada"] = familia.get("entrada", Vector3.ZERO)
	resultado["duat_pesaje"] = preparar_pesaje(objetos_conocidos, semilla)
	resultado["presentacion_duat"] = presentacion(reduccion_movimiento)
	resultado["anomalias_oniricas"] = {
		"peso_arquitectura": true,
		"piramide_invertida": true,
		"balanza_monumental": not resultado["duat_pesaje"].is_empty(),
	}
	return resultado


static func malla_base() -> ArrayMesh:
	return SuenoFamilias.malla(SuenoFamilias.CONVERGENTE)


static func valida() -> bool:
	return (
		SemillasOniricas.clave(ID) == "semilla_onirica_duat"
		and SuenoFamilias.valida(SuenoFamilias.CONVERGENTE)
		and FUENTE_TV.begins_with("tv:")
	)


static func _objetos_validos(objetos_conocidos: Array) -> Array:
	var por_id := {}
	for bruto in objetos_conocidos:
		if typeof(bruto) != TYPE_DICTIONARY:
			continue
		var objeto: Dictionary = bruto
		var id := String(objeto.get("id", "")).strip_edges()
		var peso := float(objeto.get("peso", 0.0))
		if id.is_empty() or peso <= 0.0 or not bool(objeto.get("manipulado_hoy", false)):
			continue

		var copia := objeto.duplicate(true)
		copia["id"] = id
		copia["peso"] = peso
		if copia.has("peso_sellado"):
			copia["peso_sellado"] = maxf(0.0, float(copia["peso_sellado"]))
		por_id[id] = copia

	var ids: Array = por_id.keys()
	ids.sort()
	var resultado: Array = []
	for id in ids:
		resultado.append(por_id[id])
	return resultado


## Materializa el corte 3D sin crear un renderer paralelo ni decidir cuándo se
## entra al Duat. El llamador puede añadir esta raíz a una escena de prueba o a
## la arquitectura común cuando el wiring nocturno lo permita.
static func crear_prototipo_3d(
	estado_pesaje: Dictionary, reduccion_movimiento: bool = false
) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "DuatPrototipo"
	raiz.set_meta("duat_estado_pesaje", estado_pesaje.duplicate(true))
	raiz.set_meta("duat_presentacion", presentacion(reduccion_movimiento))

	var arquitectura := Node3D.new()
	arquitectura.name = "ArquitecturaPesable"
	raiz.add_child(arquitectura)
	_crear_piramide(
		arquitectura,
		"PiramideInferior",
		POS_PIRAMIDE_INFERIOR,
		false,
	)
	_crear_piramide(
		arquitectura,
		"PiramideInvertida",
		POS_PIRAMIDE_INVERTIDA,
		true,
	)

	_montar_balanza(raiz)
	_montar_pesos(raiz, estado_pesaje)
	return raiz


## Aplica una selección real al prototipo. La balanza refleja el error de peso y
## solo al equilibrarse transforma las dos pirámides. La opción de accesibilidad
## cambia tween por estado discreto, nunca el cálculo ni la condición de éxito.
static func aplicar_pesaje_3d(
	raiz: Node3D,
	estado_pesaje: Dictionary,
	seleccion: Dictionary,
	reduccion_movimiento: bool = false,
) -> Dictionary:
	var resultado := evaluar_pesaje(estado_pesaje, seleccion)
	if raiz == null:
		return resultado

	raiz.set_meta("duat_ultimo_pesaje", resultado.duplicate(true))
	var brazo := raiz.get_node_or_null("Balanza/Brazo") as MeshInstance3D
	if brazo != null:
		var diferencia := clampf(float(resultado.get("diferencia", 0.0)), -3.0, 3.0)
		var inclinacion := 0.0 if bool(resultado["equilibrado"]) else diferencia * 4.0
		brazo.rotation_degrees = Vector3(0.0, 0.0, 90.0 + inclinacion)

	_transformar_arquitectura(
		raiz,
		bool(resultado["equilibrado"]),
		reduccion_movimiento,
	)
	return resultado


## Cada peso expone un `Area3D` y metadatos mínimos para que la capa de
## interacción común pueda recogerlo sin que este vertical invente teclas o HUD.
static func _montar_pesos(raiz: Node3D, estado_pesaje: Dictionary) -> void:
	var pesos := Node3D.new()
	pesos.name = "PesosInteractivos"
	raiz.add_child(pesos)
	var objetos: Array = estado_pesaje.get("objetos", [])
	for indice in objetos.size():
		if typeof(objetos[indice]) != TYPE_DICTIONARY:
			continue
		var objeto: Dictionary = objetos[indice]
		var area := Area3D.new()
		area.name = "Peso_%02d" % indice
		area.position = Vector3(-3.2 + indice * 1.6, 0.55, 2.8)
		area.set_meta("duat_interaccion", "pesar")
		area.set_meta("duat_objeto_id", String(objeto.get("id", "")))
		area.set_meta("duat_peso", float(objeto.get("peso", 0.0)))
		area.set_meta(
			"duat_peso_sellado", float(objeto.get("peso_sellado", objeto.get("peso", 0.0)))
		)
		pesos.add_child(area)

		var radio := clampf(0.26 + sqrt(float(objeto.get("peso", 1.0))) * 0.08, 0.30, 0.62)
		var visual := MeshInstance3D.new()
		visual.name = "Visual"
		var esfera := SphereMesh.new()
		esfera.radius = radio
		esfera.height = radio * 2.0
		visual.mesh = esfera
		visual.material_override = _material(COLOR_PESO)
		area.add_child(visual)

		var colision := CollisionShape3D.new()
		colision.name = "Colision"
		var forma := SphereShape3D.new()
		forma.radius = radio
		colision.shape = forma
		area.add_child(colision)


static func _montar_balanza(raiz: Node3D) -> void:
	var balanza := Node3D.new()
	balanza.name = "Balanza"
	raiz.add_child(balanza)
	_crear_cilindro(
		balanza,
		"Base",
		1.35,
		1.55,
		0.42,
		Vector3.ZERO,
		COLOR_PIEDRA,
		16,
	)
	_crear_cilindro(
		balanza,
		"Columna",
		0.18,
		0.24,
		3.1,
		Vector3(0.0, 1.65, 0.0),
		COLOR_ORO_APAGADO,
		12,
	)
	var brazo := _crear_cilindro(
		balanza,
		"Brazo",
		0.10,
		0.10,
		5.4,
		Vector3(0.0, 3.15, 0.0),
		COLOR_ORO_APAGADO,
		12,
	)
	brazo.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	_crear_bandeja(balanza, "BandejaRegistro", Vector3(-2.15, 2.45, 0.0))
	_crear_bandeja(balanza, "BandejaMemoria", Vector3(2.15, 2.45, 0.0))


static func _crear_bandeja(padre: Node3D, nombre: String, posicion: Vector3) -> void:
	_crear_cilindro(
		padre,
		nombre,
		0.92,
		1.06,
		0.12,
		posicion,
		COLOR_BANDEJA,
		20,
	)
	_crear_cilindro(
		padre,
		"Cadena_%s" % nombre,
		0.035,
		0.035,
		1.20,
		posicion + Vector3(0.0, 0.66, 0.0),
		COLOR_ORO_APAGADO,
		8,
	)


static func _crear_piramide(
	padre: Node3D,
	nombre: String,
	posicion: Vector3,
	invertida: bool,
) -> MeshInstance3D:
	var pieza := _crear_cilindro(
		padre,
		nombre,
		0.0,
		4.2,
		5.6,
		posicion,
		COLOR_PIEDRA,
		4,
	)
	if invertida:
		pieza.rotation_degrees = Vector3(180.0, 0.0, 45.0)
	else:
		pieza.rotation_degrees = Vector3(0.0, 0.0, 45.0)
	return pieza


static func _crear_cilindro(
	padre: Node3D,
	nombre: String,
	radio_superior: float,
	radio_inferior: float,
	altura: float,
	posicion: Vector3,
	color: Color,
	segmentos: int,
) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.name = nombre
	pieza.position = posicion
	var malla := CylinderMesh.new()
	malla.top_radius = radio_superior
	malla.bottom_radius = radio_inferior
	malla.height = altura
	malla.radial_segments = segmentos
	pieza.mesh = malla
	pieza.material_override = _material(color)
	padre.add_child(pieza)
	return pieza


static func _transformar_arquitectura(
	raiz: Node3D,
	equilibrado: bool,
	reduccion_movimiento: bool,
) -> void:
	var arquitectura := raiz.get_node_or_null("ArquitecturaPesable") as Node3D
	var inferior := raiz.get_node_or_null("ArquitecturaPesable/PiramideInferior") as MeshInstance3D
	var invertida := (
		raiz.get_node_or_null("ArquitecturaPesable/PiramideInvertida") as MeshInstance3D
	)
	if arquitectura == null or inferior == null or invertida == null:
		return

	var destino_inferior := (
		POS_PIRAMIDE_INFERIOR_EQUILIBRIO if equilibrado else POS_PIRAMIDE_INFERIOR
	)
	var destino_invertida := (
		POS_PIRAMIDE_INVERTIDA_EQUILIBRIO if equilibrado else POS_PIRAMIDE_INVERTIDA
	)
	var giro := Vector3(0.0, 32.0, 0.0) if equilibrado else Vector3.ZERO
	if reduccion_movimiento:
		inferior.position = destino_inferior
		invertida.position = destino_invertida
		arquitectura.rotation_degrees = giro
		return

	var tween := raiz.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(inferior, "position", destino_inferior, 0.75)
	tween.tween_property(invertida, "position", destino_invertida, 0.75)
	tween.tween_property(arquitectura, "rotation_degrees", giro, 0.75)


static func _material(color: Color) -> StandardMaterial3D:
	if color == COLOR_PIEDRA:
		return Mitologias435Materiales.crear("caliza_duat", color)
	if color == COLOR_ORO_APAGADO or color == COLOR_BANDEJA:
		return Mitologias435Materiales.crear("bronce_votivo", color)
	if color == COLOR_PESO:
		return Mitologias435Materiales.crear("arcilla_uruk", color)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
