class_name NPCMentorLiterario
extends CharacterBody3D

@export var autor_asociado: String = "cervantes"
@export var dialogos: Array = []

var jugador_en_rango: bool = false
var dialogo_actual: int = 0
var rama_seleccionada: int = -1

var _capa_ui: CanvasLayer = null

@onready var area_dialogo = $AreaDialogo


func _ready() -> void:
	_cargar_dialogos()
	area_dialogo.area_entered.connect(_on_jugador_entra)
	area_dialogo.area_exited.connect(_on_jugador_sale)


func _cargar_dialogos() -> void:
	dialogos = [
		{
			"texto": "Bienvenido a la tertulia. ¿Buscas sabiduría en las páginas?",
			"requisito": {},
			"ramas": []
		},
		{
			"texto": "He leído tu camino. La Sombra y la Anima bailan en ti.",
			"requisito": {"arquetipos": ["sombra", "anima"]},
			"ramas": []
		},
		{
			"texto": "Cervantes me susurró sobre la experiencia y los caminos.",
			"requisito": {"autor": "cervantes"},
			"ramas":
			[
				{
					"enfoque": "analitico",
					"opcion": "Analizar la estructura del viaje e ideales",
					"respuesta": "«Cervantes contrasta el idealismo con la realidad cotidiana.»"
				},
				{
					"enfoque": "personal",
					"opcion": "Reflexionar sobre los caminos recorridos",
					"respuesta": "«Cada paso en tu travesía transforma las lecturas pasadas.»"
				},
				{
					"enfoque": "pragmatico",
					"opcion": "Preguntar qué cambia en la siguiente decisión",
					"respuesta": "«Saber más te permite anticipar las curvas del camino.»"
				}
			]
		},
		{
			"texto":
			"Kafka guardó el secreto de la Metamorfosis para quienes transforman su momentum.",
			"requisito": {"obra": "metamorfosis", "arquetipo": "sombra"},
			"ramas":
			[
				{
					"enfoque": "analitico",
					"opcion": "Examinar la tensión de la transformación",
					"respuesta": "«La metamorfosis muestra cómo la estructura externa asfixia.»"
				},
				{
					"enfoque": "personal",
					"opcion": "Relacionar la sombra con la metamorfosis personal",
					"respuesta":
					"«Aceptar la propia sombra evita quedar atrapado en formas ajenas.»"
				},
				{
					"enfoque": "pragmatico",
					"opcion": "Determinar cómo canalizar esa energía en la acción",
					"respuesta": "«Canalizar esa tensión convierte la parálisis en impulso.»"
				}
			]
		},
		{
			"texto": "El Self se revela en la no-linealidad. Cortázar lo sabía.",
			"requisito": {"obra": "rayuela", "arquetipo": "self"},
			"ramas":
			[
				{
					"enfoque": "analitico",
					"opcion": "Descomponer la lectura no lineal de Rayuela",
					"respuesta": "«La estructura en saltos desmonta la ilusión de un sentido fijo.»"
				},
				{
					"enfoque": "personal",
					"opcion": "Conectar la búsqueda del centro con el Self",
					"respuesta": "«El mapa se descubre al saltar libremente entre casillas.»"
				},
				{
					"enfoque": "pragmatico",
					"opcion": "Aplicar la flexibilidad de elecciones al siguiente paso",
					"respuesta": "«Alterar el orden de tus acciones abre atajos insospechados.»"
				}
			]
		},
		{
			"texto": "Tu momentum es fuerte. ¿Has probado a citar a Homero en medio del combate?",
			"requisito": {"momentum": 50, "obra": "odisea"},
			"ramas":
			[
				{
					"enfoque": "analitico",
					"opcion": "Estudiar la métrica y el ritmo de la épica",
					"respuesta": "«El ritmo épico sostiene la atención y marca la cadencia.»"
				},
				{
					"enfoque": "personal",
					"opcion": "Sentir el impulso del viaje y el retorno",
					"respuesta": "«Recordar el origen mantiene el rumbo firme ante tempestades.»"
				},
				{
					"enfoque": "pragmatico",
					"opcion": "Aprovechar la tensión para el siguiente movimiento",
					"respuesta": "«Proyectar esa cadencia en el momento justo maximiza tu empuje.»"
				}
			]
		},
	]


func _on_jugador_entra(area: Area3D) -> void:
	if area.is_in_group("jugador"):
		jugador_en_rango = true
		_mostrar_dialogo_disponible()


func _on_jugador_sale(area: Area3D) -> void:
	if area.is_in_group("jugador"):
		jugador_en_rango = false
		_limpiar_ui()


func _limpiar_ui() -> void:
	if _capa_ui != null and is_instance_valid(_capa_ui):
		_capa_ui.queue_free()
		_capa_ui = null


func _mostrar_dialogo_disponible() -> void:
	_limpiar_ui()
	for indice in range(dialogos.size()):
		var dialogo: Dictionary = dialogos[indice]
		var requisito: Dictionary = dialogo.get("requisito", {})
		if _cumple_requisitos(requisito):
			dialogo_actual = indice
			var texto_base: String = dialogo.get("texto", "")
			print("Tertulia: %s" % texto_base)

			var ramas: Array = dialogo.get("ramas", [])
			if ramas.is_empty():
				_aplicar_recompensa_dialogo(requisito)
			else:
				_construir_ui_eleccion(dialogo)
			break


func _construir_ui_eleccion(dialogo: Dictionary) -> void:
	_limpiar_ui()
	_capa_ui = CanvasLayer.new()

	var contenedor_fondo := PanelContainer.new()
	contenedor_fondo.anchors_preset = Control.PRESET_BOTTOM_WIDE
	contenedor_fondo.offset_top = -180.0
	contenedor_fondo.offset_left = 40.0
	contenedor_fondo.offset_right = -40.0
	contenedor_fondo.offset_bottom = -20.0

	var vbox := VBoxContainer.new()

	var etiqueta := Label.new()
	etiqueta.text = dialogo.get("texto", "")
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(etiqueta)

	var ramas: Array = dialogo.get("ramas", [])
	for i in range(ramas.size()):
		var rama: Dictionary = ramas[i]
		var boton := Button.new()
		var opcion_texto: String = rama.get("opcion", "Opción %d" % (i + 1))
		boton.text = "[%s] %s" % [rama.get("enfoque", ""), opcion_texto]
		boton.pressed.connect(seleccionar_rama.bind(i))
		vbox.add_child(boton)

	contenedor_fondo.add_child(vbox)
	_capa_ui.add_child(contenedor_fondo)
	add_child(_capa_ui)


func seleccionar_rama(indice_rama: int) -> String:
	if dialogo_actual < 0 or dialogo_actual >= dialogos.size():
		return ""
	var dialogo: Dictionary = dialogos[dialogo_actual]
	var ramas: Array = dialogo.get("ramas", [])
	if indice_rama < 0 or indice_rama >= ramas.size():
		return ""

	rama_seleccionada = indice_rama
	var rama: Dictionary = ramas[indice_rama]
	var respuesta: String = rama.get("respuesta", "")
	print("Tertulia (%s): %s" % [rama.get("enfoque", "rama"), respuesta])

	var requisito: Dictionary = dialogo.get("requisito", {})
	_aplicar_recompensa_dialogo(requisito)
	_limpiar_ui()
	return respuesta


func _arquetipo_desbloqueado(id: String):
	var arquetipo = GestorArquetipos.obtener_arquetipo(id)
	if arquetipo == null or not bool(arquetipo.desbloqueado):
		return null
	return arquetipo


func _cumple_requisitos(req: Dictionary) -> bool:
	var cumple := true
	if req.has("arquetipos"):
		for id in req.get("arquetipos", []):
			if _arquetipo_desbloqueado(String(id)) == null:
				cumple = false
				break
	cumple = (
		cumple
		and not (req.has("autor") and req.get("autor") not in GestorLiteratura.autores_conocidos)
	)
	cumple = (
		cumple and not (req.has("obra") and req.get("obra") not in GestorLiteratura.obras_conocidas)
	)
	cumple = (
		cumple
		and not (
			req.has("arquetipo")
			and _arquetipo_desbloqueado(String(req.get("arquetipo", ""))) == null
		)
	)
	cumple = (
		cumple
		and not (req.has("momentum") and GestorMomentum.momentum_actual < req.get("momentum", 0))
	)
	return cumple


func _aplicar_recompensa_dialogo(req: Dictionary) -> void:
	if req.get("autor") == "cervantes":
		GestorArquetipos.ganar_insight(25)
	if req.get("obra") == "metamorfosis":
		var sombra = _arquetipo_desbloqueado("sombra")
		if sombra != null:
			sombra.efecto_combate["bonus_crit"] = (
				float(sombra.efecto_combate.get("bonus_crit", 0.0)) + 0.05
			)
	if req.get("obra") == "rayuela" and _arquetipo_desbloqueado("self") != null:
		GestorArquetipos.ganar_insight(20)
	if req.get("momentum") == 50:
		GestorMomentum.momentum_actual = min(
			GestorMomentum.momentum_max, GestorMomentum.momentum_actual + 20
		)
