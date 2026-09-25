## Capa de interacción para el televisor real ya declarado en la casa (#283).
##
## No crea otro televisor: CasaUtileria coloca este Area3D en el bulto
## `televisionVintage` del catálogo y conserva ese modelo como representación.
## El encendido es feedback local. Desde #442, una atención deliberada y
## completada al microdocumental ficticio de #441 puede registrar la semilla
## Duat del día; encender la TV o usar el mando como ruido de fondo no basta.
class_name TelevisionInteractiva3D
extends Interactuable3D

const OFFSET_MANDO_MESA := Vector3(1.43, -0.58, -0.11)
const OFFSET_PORTATIL_MESA := Vector3(1.15, -0.56, 0.07)
const OBJETO_ONIRICO_ID := "televisor_casa"
const RUTA_CATALOGO_TV := "res://datos/tv_domestica_98.json"

var _encendida := false
var _brillo: OmniLight3D
var _cristal_pantalla: MeshInstance3D
var _emision_pantalla: Node3D
var _rotulo_boletin: Label3D
var _paso_documental := 0
var _documental_completado := false
var _catalogo_tv: Dictionary = {}


func configurar(tam: Vector3) -> void:
	verbo = Verbo.ENCENDER
	_cargar_catalogo_tv()
	nombre_objeto = "televisor"

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam + Vector3(0.12, 0.12, 0.12)
	colision.shape = forma
	add_child(colision)

	_montar_superficie_pantalla(tam)

	_brillo = OmniLight3D.new()
	_brillo.name = "BrilloTelevisor"
	# El modelo se gira 90° para mirar al sofá: la pantalla queda hacia +X.
	# La luz debe salir del tubo, no del lateral original -Z del asset.
	_brillo.position = Vector3(tam.z * 0.42, tam.y * 0.08, 0.0)
	_brillo.omni_range = 2.6
	_brillo.light_energy = 0.75
	_brillo.light_color = Color(0.58, 0.70, 0.82)
	_brillo.visible = false
	add_child(_brillo)

	_orientar_modelo_hacia_sofa()
	activado.connect(_interactuar_directo)
	_montar_mando_domestico()


func esta_encendida() -> bool:
	return _encendida


func texto_accion() -> String:
	if not _encendida:
		return super.texto_accion()
	if _documental_completado:
		return "Apagar televisor"
	if _paso_documental == 0:
		return "Buscar canal"
	return "Seguir viendo documental"


## El mismo botón no representa siempre el mismo gesto. Potencia usa el switch
## físico; navegar por el contenido usa el clic corto de pulsación. Se resuelve
## antes de emitir `activado`, por el contrato común de Interactuable3D.
func nombre_sonido() -> String:
	if not sonido.is_empty():
		return super.nombre_sonido()
	if not _encendida or _documental_completado:
		return "marcar"
	return "pulsar"


## Punto público mínimo para accesorios domésticos como el mando IR.
## El mando conserva una única fuente de verdad para el estado visual, pero no
## avanza contenido: dejar la TV encendida de fondo no activa semillas.
func alternar_desde_mando() -> void:
	_alternar(null)


## La interacción directa exige tres pasos observables: encender, elegir el
## fragmento y terminarlo. Solo el último consulta la jornada real y registra la
## semilla; salir o apagar antes reinicia el progreso incompleto.
func _interactuar_directo(_actor: Node) -> void:
	if not _encendida:
		_alternar(_actor)
		return
	if _documental_completado:
		_alternar(_actor)
		return
	if _paso_documental == 0:
		_paso_documental = 1
		_mostrar_boletin_tv()
		return

	var jornada_actual := _jornada_en_escena()
	if jornada_actual.is_empty():
		return
	_documental_completado = SuenoDuat.registrar_documental(jornada_actual, true)
	if _documental_completado:
		_ocultar_boletin_tv()
		_activar_exposicion_tv(jornada_actual)
		ObjetosOniricos.registrar(jornada_actual, OBJETO_ONIRICO_ID)


func _mostrar_boletin_tv() -> void:
	if _rotulo_boletin == null:
		return
	var bloque := _bloque_tv_actual(_jornada_en_escena())
	var boletin = bloque.get("boletin", {})
	if typeof(boletin) != TYPE_DICTIONARY:
		return
	var tratamiento = boletin.get("tratamiento", {})
	if typeof(tratamiento) != TYPE_DICTIONARY:
		return
	_rotulo_boletin.text = String(tratamiento.get("rotulo", ""))
	_rotulo_boletin.visible = not _rotulo_boletin.text.is_empty()


func _ocultar_boletin_tv() -> void:
	if _rotulo_boletin != null:
		_rotulo_boletin.visible = false


## El boletín previo al microdocumental comparte hecho base con prensa/radio,
## pero conserva su tratamiento editorial en un catálogo TV separado. Solo se
## registra al completar deliberadamente el bloque, nunca por encender el CRT.
static func registrar_exposicion_de_bloque(
	estado: Dictionary, bloque: Dictionary, jornada: int
) -> bool:
	var boletin = bloque.get("boletin", {})
	if typeof(boletin) != TYPE_DICTIONARY or boletin.is_empty():
		return false
	var exposicion = boletin.get("exposicion_ideologica", {})
	if typeof(exposicion) != TYPE_DICTIONARY or exposicion.is_empty():
		return false
	var etiquetas: Array = []
	var etiquetas_brutas = exposicion.get("etiquetas", [])
	if typeof(etiquetas_brutas) == TYPE_ARRAY:
		etiquetas = (etiquetas_brutas as Array).duplicate()
	return (
		Prometeo
		. registrar_exposicion_ideologica(
			estado,
			String(exposicion.get("id", "")),
			String(exposicion.get("fuente", "tv")),
			String(exposicion.get("eje", "")),
			jornada,
			etiquetas,
		)
	)


func _activar_exposicion_tv(jornada_actual: Dictionary) -> bool:
	var estado := _estado_partida_actual()
	if estado.is_empty():
		return false
	var bloque := _bloque_tv_actual(jornada_actual)
	if bloque.is_empty():
		return false
	var dia := maxi(1, int(jornada_actual.get("dia", 1)))
	return registrar_exposicion_de_bloque(estado, bloque, dia)


func _bloque_tv_actual(jornada_actual: Dictionary) -> Dictionary:
	var bloques = _catalogo_tv.get("bloques", [])
	if typeof(bloques) != TYPE_ARRAY:
		return {}
	var dia := maxi(1, int(jornada_actual.get("dia", 1)))
	for valor in bloques:
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		var bloque: Dictionary = valor
		var dias = bloque.get("dias", [])
		if typeof(dias) == TYPE_ARRAY and not dias.is_empty() and not dias.has(dia):
			continue
		return bloque.duplicate(true)
	return {}


func _estado_partida_actual() -> Dictionary:
	if not is_inside_tree():
		return {}
	var escena := get_tree().current_scene
	if escena == null:
		return {}
	var partida_actual: Variant = escena.get("partida")
	if partida_actual is Partida:
		return (partida_actual as Partida).estado
	return {}


func _cargar_catalogo_tv() -> void:
	if not _catalogo_tv.is_empty():
		return
	var archivo := FileAccess.open(RUTA_CATALOGO_TV, FileAccess.READ)
	if archivo == null:
		push_error("No se pudo abrir %s" % RUTA_CATALOGO_TV)
		return
	var valor = JSON.parse_string(archivo.get_as_text())
	if typeof(valor) != TYPE_DICTIONARY:
		push_error("Catálogo TV doméstica inválido")
		return
	_catalogo_tv = valor


func _alternar(_actor: Node) -> void:
	_encendida = not _encendida
	_brillo.visible = _encendida
	if _cristal_pantalla != null:
		_cristal_pantalla.visible = not _encendida
	if _emision_pantalla != null:
		_emision_pantalla.visible = _encendida
	if not _encendida and not _documental_completado:
		_paso_documental = 0
		_ocultar_boletin_tv()


## El modelo CC0 aporta la carcasa, pero el shader doméstico unifica demasiado
## marco y tubo. Esta superficie devuelve al CRT una pantalla legible sin añadir
## programa, texto ni UI: apagada es cristal oscuro; encendida muestra la nieve
## procedural que ya usa `Pantalla` como fallback neutro.
func _montar_superficie_pantalla(tam: Vector3) -> void:
	var pos_frente := Vector3(tam.z * 0.5 + 0.012, tam.y * 0.03, 0.0)
	var tam_pantalla := Vector2(tam.x * 0.66, tam.y * 0.56)

	_cristal_pantalla = MeshInstance3D.new()
	_cristal_pantalla.name = "CristalPantallaTV"
	var plano := QuadMesh.new()
	plano.size = tam_pantalla
	_cristal_pantalla.mesh = plano
	_cristal_pantalla.position = pos_frente
	_cristal_pantalla.rotation_degrees.y = 90.0
	Modelos._pintar(_cristal_pantalla, Color(0.045, 0.060, 0.070), "cristal_urbano")
	add_child(_cristal_pantalla)

	_emision_pantalla = (
		Pantalla
		. montar(
			self,
			{
				"pos": pos_frente + Vector3(0.004, 0.0, 0.0),
				"tam": tam_pantalla,
				"giro": 90.0,
				"contenido": "",
				"semilla": 133.0,
			},
		)
	)
	_emision_pantalla.name = "EmisionPantallaTV"
	_emision_pantalla.visible = false

	_rotulo_boletin = Label3D.new()
	_rotulo_boletin.name = "RotuloBoletinTV"
	_rotulo_boletin.position = pos_frente + Vector3(0.012, 0.0, 0.0)
	_rotulo_boletin.rotation_degrees.y = 90.0
	_rotulo_boletin.font_size = 24
	_rotulo_boletin.pixel_size = 0.00125
	_rotulo_boletin.outline_size = 4
	_rotulo_boletin.modulate = Color(0.90, 0.93, 0.86)
	_rotulo_boletin.visible = false
	add_child(_rotulo_boletin)


## `TelevisionInteractiva3D` vive bajo `_mundo`, que se recrea al entrar en casa.
## Buscar la propiedad `jornada` en ancestros evita acoplar la utilería al estado
## global y mantiene el montaje de CasaUtileria ajeno a persistencia.
func _jornada_en_escena() -> Dictionary:
	var nodo: Node = self
	while nodo != null:
		for propiedad in nodo.get_property_list():
			if String(propiedad.get("name", "")) != "jornada":
				continue
			var valor: Variant = nodo.get("jornada")
			if typeof(valor) == TYPE_DICTIONARY:
				return valor
			return {}
		nodo = nodo.get_parent()
	return {}


## El bulto y esta capa interactiva son hermanos en `_mundo` y comparten la
## posición exacta del catálogo. El sofá queda a +X: el giro corrige la TV que
## se veía de canto en el playtest y deja la pantalla orientada hacia el asiento.
func _orientar_modelo_hacia_sofa() -> void:
	var contenedor := get_parent()
	if contenedor == null:
		return
	for hijo in contenedor.get_children():
		if hijo == self or not (hijo is Node3D):
			continue
		var pieza := hijo as Node3D
		if not pieza.position.is_equal_approx(position):
			continue
		pieza.rotation_degrees.y = 90.0
		return


func _montar_mando_domestico() -> void:
	var contenedor := get_parent()
	if contenedor == null:
		return
	var mando := MandoTelevision98.new()
	mando.name = "MandoTelevision98"
	# Mesa baja: y=0,30 m. El mando queda apoyado y no flotando contra la pared.
	mando.position = position + OFFSET_MANDO_MESA
	mando.rotation_degrees = Vector3(0.0, 14.0, 0.0)
	contenedor.add_child(mando)
	mando.configurar(self)

	# La Color 98 comparte la mesa baja: es visible al entrar en el salón y su
	# pantalla queda hacia arriba, sin perder el nodo que observa RYU FLOW.
	var portatil := contenedor.get_node_or_null("ConsolaPortatil98") as Node3D
	if portatil != null:
		portatil.position = position + OFFSET_PORTATIL_MESA
		portatil.rotation_degrees = Vector3(90.0, 0.0, 0.0)
