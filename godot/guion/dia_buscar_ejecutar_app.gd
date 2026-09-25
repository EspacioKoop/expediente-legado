## Integra Buscar/Ejecutar de #538 como extensiones del escritorio OS98 existente.
extends Node

var _escritorio_id := 0
var _escritorio: EscritorioSiga
var _buscar_app: EscritorioSigaApp
var _ejecutar_app: EscritorioSigaApp
var _reconstruccion_app: EscritorioSigaApp
var _reconstruccion_pendiente: Dictionary = {}


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var pantalla: Variant = dia.get("_pantalla")
	if pantalla == null or not is_instance_valid(pantalla):
		_escritorio_id = 0
		_escritorio = null
		return
	var escritorio := (pantalla as Node).get_node_or_null("EscritorioSiga")
	if escritorio == null or not escritorio is EscritorioSiga:
		return
	var id := escritorio.get_instance_id()
	if id == _escritorio_id:
		return
	_escritorio_id = id
	_escritorio = escritorio as EscritorioSiga
	_registrar_superficies()


func _registrar_superficies() -> void:
	_buscar_app = EscritorioSigaApp.new(
		"buscar", "Buscar", Callable(self, "_crear_buscar"), "buscar"
	)
	_buscar_app.tamano_minimo = Vector2(500, 330)
	_buscar_app.tamano_preferido = Vector2(660, 460)
	_buscar_app.redimensionable = true
	_buscar_app.registrar_en(_escritorio)

	_ejecutar_app = EscritorioSigaApp.new(
		"ejecutar", "Ejecutar…", Callable(self, "_crear_ejecutar"), "ejecutar"
	)
	_ejecutar_app.tamano_minimo = Vector2(500, 240)
	_ejecutar_app.tamano_preferido = Vector2(620, 300)
	_ejecutar_app.registrar_en(_escritorio)

	_reconstruccion_app = EscritorioSigaApp.new(
		"reconstruccion-documental",
		tr("VISOR_RECONSTRUIR"),
		Callable(self, "_crear_reconstruccion"),
		"siga",
	)
	_reconstruccion_app.tamano_minimo = Vector2(560, 420)
	_reconstruccion_app.tamano_preferido = Vector2(760, 620)
	_reconstruccion_app.redimensionable = true
	_reconstruccion_app.registrar_en(_escritorio)


func _crear_buscar() -> Control:
	var superficie := BuscarEjecutarSiga.new()
	superficie.configurar(
		"buscar", _catalogo_apps(), _contexto_actual(), _documentos_reconstruibles()
	)
	_conectar_superficie(superficie)
	return superficie


func _crear_ejecutar() -> Control:
	var superficie := BuscarEjecutarSiga.new()
	superficie.configurar("ejecutar", _catalogo_apps(), _contexto_actual())
	_conectar_superficie(superficie)
	return superficie


func _crear_reconstruccion() -> Control:
	var superficie := ReconstruccionDocumentalSiga.new()
	superficie.configurar(
		_reconstruccion_pendiente,
		bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false)),
	)
	return superficie


func _conectar_superficie(superficie: BuscarEjecutarSiga) -> void:
	superficie.abrir_aplicacion.connect(_abrir_aplicacion_lanzador)
	superficie.abrir_ruta.connect(_abrir_ruta_lanzador)
	superficie.abrir_url.connect(_abrir_url_lanzador)
	superficie.abrir_ayuda.connect(_abrir_ayuda_lanzador)
	superficie.abrir_reconstruccion.connect(_abrir_reconstruccion_lanzador)


func _catalogo_apps() -> Array[Dictionary]:
	return [
		{"id": "siga-98", "titulo": "SIGA-98", "aliases": ["siga", "siga98"]},
		{"id": "explorador", "titulo": "Explorador", "aliases": ["equipo", "archivos"]},
		{
			"id": "navegador-web98",
			"titulo": "Navegador Web98",
			"aliases": ["web", "web98", "navegador"],
		},
		{
			"id": "software-98",
			"titulo": "Archivo de programas",
			"aliases": ["software", "programas"],
		},
		{"id": "correo", "titulo": "Correo corporativo", "aliases": ["correo", "mail"]},
		{"id": "bloc-notas", "titulo": "Bloc de notas", "aliases": ["notas", "bloc"]},
		{"id": "calculadora", "titulo": "Calculadora", "aliases": ["calc"]},
		{
			"id": "catalogo-anomalias",
			"titulo": "Catálogo de anomalías",
			"aliases": ["anomalias", "catalogo"],
		},
		{"id": "buscar", "titulo": "Buscar", "aliases": ["buscar", "find"]},
		{"id": "ejecutar", "titulo": "Ejecutar…", "aliases": ["ejecutar", "run"]},
	]


func _documentos_reconstruibles() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var dia := get_parent()
	if dia == null:
		return resultado
	var jornada: Variant = dia.get("jornada")
	var contenido: Variant = dia.get("contenido")
	if not jornada is Dictionary or not contenido is Contenido:
		return resultado
	var leidos: Array = (jornada as Dictionary).get("leido_hoy", [])
	for caso in (contenido as Contenido).casos:
		var caso_id := String(caso.get("id", ""))
		var caso_titulo := tr(String(caso.get("titulo", "")))
		for registro in caso.get("registros", []):
			var folio := String(registro.get("folio", ""))
			if folio.is_empty() or not leidos.has(folio):
				continue
			var registro_id := String(registro.get("id", ""))
			var reconstrucciones := ReconstruccionDocumental3D.para_registros(
				caso_id, [registro_id]
			)
			for reconstruccion in reconstrucciones:
				resultado.append(
					{
						"caso": caso_id,
						"caso_titulo": caso_titulo,
						"registro": registro_id,
						"folio": folio,
						"tipo": String(registro.get("tipo", "")),
						"contenido": tr(String(registro.get("contenido", ""))),
						"reconstruccion": reconstruccion.duplicate(true),
					}
				)
	return resultado


func _buscar_reconstruccion(caso_id: String, registro_id: String) -> Dictionary:
	for documento in _documentos_reconstruibles():
		if (
			String(documento.get("caso", "")) == caso_id
			and String(documento.get("registro", "")) == registro_id
		):
			var reconstruccion: Dictionary = documento.get("reconstruccion", {})
			return reconstruccion.duplicate(true)
	return {}


func _contexto_actual() -> Dictionary:
	var dia := get_parent()
	if dia == null:
		return _contexto_minimo(1)
	var integrador := dia.get_node_or_null("EscritorioSigaController")
	if integrador != null and integrador.has_method("_contexto_os98"):
		var contexto: Variant = integrador.call("_contexto_os98", dia)
		if contexto is Dictionary:
			return (contexto as Dictionary).duplicate(true)
	var jornada: Variant = dia.get("jornada")
	var numero := 1
	if jornada is Dictionary:
		numero = int((jornada as Dictionary).get("dia", 1))
	return _contexto_minimo(numero)


func _contexto_minimo(dia: int) -> Dictionary:
	return {
		"jornada": dia,
		"dia": dia,
		"credenciales": [],
		"conocimiento": [],
		"urls_caidas": [],
		"memorandum_disponible": false,
		"habilitar_enlace13": false,
		"fase_contaminacion": 0,
	}


func _abrir_reconstruccion_lanzador(caso_id: String, registro_id: String) -> void:
	if _escritorio == null or _reconstruccion_app == null:
		return
	var reconstruccion := _buscar_reconstruccion(caso_id, registro_id)
	if reconstruccion.is_empty():
		return
	_reconstruccion_pendiente = reconstruccion
	_reconstruccion_app.cerrar(_escritorio)
	_reconstruccion_app.abrir(_escritorio)


func _abrir_aplicacion_lanzador(id: String) -> void:
	if _escritorio == null or id.is_empty():
		return
	_escritorio.abrir_aplicacion(id)


func _abrir_ruta_lanzador(ruta: String) -> void:
	if _escritorio == null or ruta.is_empty():
		return
	_escritorio.abrir_aplicacion("explorador")
	call_deferred("_navegar_ruta_diferida", ruta)


func _navegar_ruta_diferida(ruta: String) -> void:
	if _escritorio == null:
		return
	var explorador := _buscar_explorador(_escritorio)
	if explorador != null:
		explorador.call("_navegar_a", ruta, true)


func _abrir_url_lanzador(url: String) -> void:
	if _escritorio == null or url.is_empty():
		return
	_escritorio.abrir_aplicacion("navegador-web98")
	call_deferred("_navegar_url_diferida", url)


func _navegar_url_diferida(url: String) -> void:
	if _escritorio == null:
		return
	var navegador := _buscar_navegador(_escritorio)
	if navegador != null:
		navegador.navegar(url)


func _abrir_ayuda_lanzador() -> void:
	if _escritorio != null:
		_escritorio.abrir_aplicacion("ayuda-sistema")


func _buscar_explorador(nodo: Node) -> ExploradorSiga:
	if nodo is ExploradorSiga:
		return nodo as ExploradorSiga
	for hijo in nodo.get_children():
		if hijo is Node:
			var encontrado := _buscar_explorador(hijo as Node)
			if encontrado != null:
				return encontrado
	return null


func _buscar_navegador(nodo: Node) -> NavegadorSiga:
	if nodo is NavegadorSiga:
		return nodo as NavegadorSiga
	for hijo in nodo.get_children():
		if hijo is Node:
			var encontrado := _buscar_navegador(hijo as Node)
			if encontrado != null:
				return encontrado
	return null
