## Visor OS98 de una reconstrucción documental provisional (#1437).
##
## Consume exclusivamente el catálogo de ReconstruccionDocumental3D. La maqueta
## 3D no afirma qué ocurrió: materializa el plan de cámara de la fuente elegida
## y conserva sus fragmentos como procedencia visible.
class_name ReconstruccionDocumentalSiga
extends VBoxContainer

var _reconstruccion: Dictionary = {}
var _reduccion_movimiento := false
var _planos: Array = []
var _indice_plano := 0

var _camara: Camera3D
var _marcador: MeshInstance3D
var _estado: Label


func configurar(reconstruccion: Dictionary, reduccion_movimiento: bool = false) -> void:
	_reconstruccion = reconstruccion.duplicate(true)
	_reduccion_movimiento = reduccion_movimiento


func _ready() -> void:
	theme = EstiloSiga.tema()
	custom_minimum_size = Vector2(560, 420)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	_construir()


func _construir() -> void:
	var cabecera := Label.new()
	cabecera.name = "Cabecera"
	cabecera.text = (
		"%s · %s"
		% [
			tr("VISOR_RECONSTRUIR"),
			String(_reconstruccion.get("folio", "")),
		]
	)
	cabecera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(cabecera)

	var titulo := Label.new()
	titulo.name = "TituloFuente"
	titulo.text = String(_reconstruccion.get("titulo", ""))
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(titulo)

	var fuente := Label.new()
	fuente.name = "Fuente"
	fuente.text = _texto_fuente()
	fuente.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(fuente)

	var marco := SubViewportContainer.new()
	marco.name = "Plano3D"
	marco.custom_minimum_size = Vector2(560, 260)
	marco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	marco.stretch = true
	add_child(marco)

	var vista := SubViewport.new()
	vista.name = "Vista3D"
	vista.size = Vector2i(640, 300)
	vista.own_world_3d = true
	vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	marco.add_child(vista)

	_construir_maqueta(vista)
	_planos = ReconstruccionDocumental3D.planos_de(_reconstruccion, _reduccion_movimiento)

	var controles := HBoxContainer.new()
	controles.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(controles)

	var anterior := Button.new()
	anterior.name = "AnteriorPlano"
	anterior.text = "◀"
	anterior.pressed.connect(_anterior)
	controles.add_child(anterior)

	_estado = Label.new()
	_estado.name = "EstadoPlano"
	_estado.custom_minimum_size.x = 280
	_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controles.add_child(_estado)

	var siguiente := Button.new()
	siguiente.name = "SiguientePlano"
	siguiente.text = "▶"
	siguiente.pressed.connect(_siguiente)
	controles.add_child(siguiente)

	_aplicar_plano()


func _construir_maqueta(vista: SubViewport) -> void:
	var escena := Node3D.new()
	escena.name = "Maqueta"
	vista.add_child(escena)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	luz.light_energy = 1.15
	escena.add_child(luz)

	var relleno := OmniLight3D.new()
	relleno.position = Vector3(0.0, 3.4, 2.2)
	relleno.omni_range = 8.0
	relleno.light_energy = 1.4
	escena.add_child(relleno)

	var suelo := MeshInstance3D.new()
	var malla_suelo := PlaneMesh.new()
	malla_suelo.size = Vector2(8.0, 6.0)
	suelo.mesh = malla_suelo
	suelo.material_override = _material(Color(0.24, 0.25, 0.25))
	escena.add_child(suelo)

	var mesa := MeshInstance3D.new()
	var malla_mesa := BoxMesh.new()
	malla_mesa.size = Vector3(2.8, 0.16, 1.2)
	mesa.mesh = malla_mesa
	mesa.position = Vector3(0.0, 0.82, 0.0)
	mesa.material_override = _material(Color(0.43, 0.37, 0.28))
	escena.add_child(mesa)

	for posicion in [Vector3(-2.2, 0.55, -1.5), Vector3(2.2, 0.55, -1.5)]:
		var archivo := MeshInstance3D.new()
		var malla_archivo := BoxMesh.new()
		malla_archivo.size = Vector3(0.9, 1.1, 0.65)
		archivo.mesh = malla_archivo
		archivo.position = posicion
		archivo.material_override = _material(Color(0.31, 0.34, 0.35))
		escena.add_child(archivo)

	_marcador = MeshInstance3D.new()
	_marcador.name = "FocoEvidencia"
	var esfera := SphereMesh.new()
	esfera.radius = 0.22
	esfera.height = 0.44
	_marcador.mesh = esfera
	_marcador.material_override = _material(Color(0.88, 0.72, 0.24))
	escena.add_child(_marcador)

	_camara = Camera3D.new()
	_camara.name = "CamaraReconstruccion"
	_camara.current = true
	_camara.near = 0.05
	_camara.far = 50.0
	escena.add_child(_camara)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	return material


func _texto_fuente() -> String:
	var texto := ""
	for fragmento in _reconstruccion.get("fragmentos", []):
		if not texto.is_empty():
			texto += "\n"
		texto += "• " + String(fragmento)
	return texto


func _anterior() -> void:
	if _planos.is_empty():
		return
	_indice_plano = maxi(0, _indice_plano - 1)
	_aplicar_plano()


func _siguiente() -> void:
	if _planos.is_empty():
		return
	_indice_plano = mini(_planos.size() - 1, _indice_plano + 1)
	_aplicar_plano()


func _aplicar_plano() -> void:
	if _estado == null:
		return
	if _planos.is_empty():
		_estado.text = String(_reconstruccion.get("folio", ""))
		return
	_indice_plano = clampi(_indice_plano, 0, _planos.size() - 1)
	var plano: Dictionary = _planos[_indice_plano]
	var posicion: Vector3 = plano.get("camara", Vector3(0.0, 1.65, 4.2))
	var mira: Vector3 = plano.get("mira", Vector3(0.0, 1.2, 0.0))
	_camara.position = posicion
	_camara.look_at(mira, Vector3.UP)
	_marcador.position = mira + Vector3(0.0, 0.22, 0.0)
	_estado.text = (
		"%d/%d · %s"
		% [
			_indice_plano + 1,
			_planos.size(),
			_humanizar_motivo(String(plano.get("motivo", ""))),
		]
	)


func _humanizar_motivo(motivo: String) -> String:
	return motivo.replace("_", " ").capitalize()
