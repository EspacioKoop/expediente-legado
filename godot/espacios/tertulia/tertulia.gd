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
			"texto":
			(
				"En el cruce de lecturas se sugiere una hipótesis: la Sombra y el Ánima no se"
				+ " repelen, sino que articulan la tensión del relato."
			),
			"requisito": {"arquetipos": ["sombra", "anima"]},
			"ramas": []
		},
		{
			"texto":
			(
				"Las páginas de Cervantes proponen que la fricción entre la ficción y la"
				+ " costumbre reordena la visión del viaje."
			),
			"requisito": {"autor": "cervantes"},
			"ramas":
			[
				{
					"enfoque": "analitico",
					"opcion": "Analizar la estructura del viaje e ideales",
					"respuesta":
					(
						"«El idealismo no se desmorona por ingenuidad, sino por ignorar la"
						+ " resistencia del entorno; al contrastar el libro con el polvo del"
						+ " camino, la ficción pierde su rigidez dogmática y obliga a"
						+ " reinterpretar cada conflicto.»"
					)
				},
				{
					"enfoque": "personal",
					"opcion": "Reflexionar sobre los caminos recorridos",
					"respuesta":
					(
						"«Revisitar una lectura no borra los tropiezos pasados; al admitir el"
						+ " desacierto como parte del itinerario, el lector deja de"
						+ " justificarse y descubre un horizonte menos artificioso.»"
					)
				},
				{
					"enfoque": "pragmatico",
					"opcion": "Preguntar qué cambia en la siguiente decisión",
					"respuesta":
					(
						"«Saber qué espera el terreno no exige renunciar al impulso; medir la"
						+ " distancia antes del impacto reduce el daño sin desactivar la"
						+ " voluntad de avanzar.»"
					)
				}
			]
		},
		{
			"texto":
			(
				"La lectura de La metamorfosis abre la sospecha de que la norma burocrática"
				+ " proyecta una Sombra ineludible."
			),
			"requisito": {"obra": "metamorfosis", "arquetipo": "sombra"},
			"ramas":
			[
				{
					"enfoque": "analitico",
					"opcion": "Examinar la tensión de la transformación",
					"respuesta":
					(
						"«La metamorfosis no representa un castigo fantástico, sino la"
						+ " respuesta del cuerpo a una norma asfixiante; cuando la estructura"
						+ " niega la individualidad, la parálisis externa precipita el"
						+ " colapso del sistema entero.»"
					)
				},
				{
					"enfoque": "personal",
					"opcion": "Relacionar la sombra con la metamorfosis personal",
					"respuesta":
					(
						"«Reconocer la Sombra no absuelve la culpa acumulada; sin embargo,"
						+ " examinar ese enclaustramiento frena la inercia de complacer"
						+ " mandatos ajenos.»"
					)
				},
				{
					"enfoque": "pragmatico",
					"opcion": "Determinar cómo canalizar esa energía en la acción",
					"respuesta":
					(
						"«Resistir la angustia con obstinación pura solo acelera el desgaste;"
						+ " encauzar esa fricción hacia una grieta concreta rompe el"
						+ " encierro y reabre el margen de maniobra.»"
					)
				}
			]
		},
		{
			"texto":
			(
				"En Rayuela surge la hipótesis de que la búsqueda del Self requiere abandonar"
				+ " la ilusión de un itinerario fijo."
			),
			"requisito": {"obra": "rayuela", "arquetipo": "self"},
			"ramas":
			[
				{
					"enfoque": "analitico",
					"opcion": "Descomponer la lectura no lineal de Rayuela",
					"respuesta":
					(
						"«Saltar entre capítulos no produce caos arbitrario, sino la quiebra"
						+ " del sentido prefijado; al desmantelar la secuencia lineal, la"
						+ " responsabilidad del texto se traslada por entero a la decisión"
						+ " del lector.»"
					)
				},
				{
					"enfoque": "personal",
					"opcion": "Conectar la búsqueda del centro con el Self",
					"respuesta":
					(
						"«El centro de la rayuela no aguarda en una casilla fija; el equilibrio"
						+ " exige asumir la incertidumbre de cada brinco sin aferrarse a un"
						+ " destino inmutable.»"
					)
				},
				{
					"enfoque": "pragmatico",
					"opcion": "Aplicar la flexibilidad de elecciones al siguiente paso",
					"respuesta":
					(
						"«Alterar el orden habitual no equivale a improvisar a ciegas; explorar"
						+ " combinaciones imprevistas permite esquivar el bloqueo frontal y"
						+ " descubrir atajos inaccesibles para la rutina.»"
					)
				}
			]
		},
		{
			"texto":
			(
				"El poema homérico sugiere que el ritmo de la épica sostiene la determinación"
				+ " ante el caos del trayecto."
			),
			"requisito": {"momentum": 50, "obra": "odisea"},
			"ramas":
			[
				{
					"enfoque": "analitico",
					"opcion": "Estudiar la métrica y el ritmo de la épica",
					"respuesta":
					(
						"«El verso medido no actúa como mero adorno retórico; al pautar el"
						+ " relato con cadencia constante, la memoria retiene el rumbo donde"
						+ " el estruendo del combate dispersaría la atención.»"
					)
				},
				{
					"enfoque": "personal",
					"opcion": "Sentir el impulso del viaje y el retorno",
					"respuesta":
					(
						"«Evocar Ítaca no debe convertirse en un refugio melancólico; recordar el"
						+ " origen preserva la templanza ante las distracciones del trayecto sin"
						+ " negar la dureza del mar.»"
					)
				},
				{
					"enfoque": "pragmatico",
					"opcion": "Aprovechar la tensión para el siguiente movimiento",
					"respuesta":
					(
						"«Acumular impulso no sirve si la embestida carece de temple;"
						+ " canalizar la cadencia en el instante exacto concentra la fuerza y"
						+ " evita desperdiciar la inercia en un ademán fallido.»"
					)
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
