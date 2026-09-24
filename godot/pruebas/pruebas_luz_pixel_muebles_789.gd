## Lo que hay DENTRO de la oficina también se ilumina por píxel (#789).
##
## #1243 pasó la envolvente a luz por píxel, pero muebles, assets, personas y su
## ropa fijaban el shader canónico: proyectaban sombra y no la recibían, y las
## figuras seguían leyéndose como siluetas. Aquí se monta la oficina con las
## mismas capas que el gate visual #126 y se exige que no quede ni una
## superficie en luz por vértice; y, a la vez, que el trayecto real y la casa,
## construidos después, sigan exactamente con el canónico.
extends SceneTree

const DiaCalle := preload("res://guion/dia_calle_app.gd")
const DRESSING := "res://guion/dia_dressing_cc0_app.gd"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var oficina := Node3D.new()
	root.add_child(oficina)
	var espacio := EspaciosCatalogo.OFICINA.duplicate(true)
	espacio["figuras"] = _plantilla()
	Espacio3D.construir(oficina, espacio)
	_comprobar(
		Espacio3D.shader_del_sitio() == Espacio3D.SHADER_PSX_LUZ_PIXEL,
		"la oficina declara su shader al construirse"
	)
	var dressing = load(DRESSING).new()
	dressing.call("_vestir_archivo_cc0", oficina)
	dressing.free()
	OficinaUtileria.montar(oficina)
	OficinaAssetsCc0.montar(oficina)
	# La ropa llega diferida: se espera a que esté puesta antes de contar.
	for _i in range(6):
		await process_frame

	var en_oficina := _materiales_psx(oficina)
	_comprobar(
		int(en_oficina.get(Espacio3D.SHADER_PSX_LUZ_PIXEL, 0)) > 100,
		"la oficina montada tiene sus muebles, assets y personas pintados por píxel"
	)
	_comprobar(
		int(en_oficina.get(Espacio3D.SHADER_PSX, 0)) == 0,
		"ni una superficie de la oficina se queda en luz por vértice"
	)
	_comprobar(_hay_persona_por_pixel(oficina), "las personas de la oficina reciben sombra")

	var dia_calle = DiaCalle.new()
	var trayecto: Dictionary = dia_calle.call("_espacio_de", "trayecto")
	dia_calle.free()
	var calle := Node3D.new()
	root.add_child(calle)
	Espacio3D.construir(calle, trayecto)
	_persona_suelta(calle)
	var casa := Node3D.new()
	root.add_child(casa)
	Espacio3D.construir(casa, EspaciosCatalogo.CASA.duplicate(true))
	_persona_suelta(casa)
	for _i in range(6):
		await process_frame

	for sitio in [calle, casa]:
		var materiales := _materiales_psx(sitio)
		_comprobar(
			int(materiales.get(Espacio3D.SHADER_PSX, 0)) > 0,
			"%s sigue pintándose con el shader canónico" % sitio.name
		)
		_comprobar(
			int(materiales.get(Espacio3D.SHADER_PSX_LUZ_PIXEL, 0)) == 0,
			"%s no hereda la luz por píxel de la oficina" % sitio.name
		)

	oficina.queue_free()
	calle.queue_free()
	casa.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


## Los compañeros del gate #126, en sus sitios, con cuerpo y cara.
func _plantilla() -> Array:
	var figuras := []
	var quienes := Companeros.plantilla(126)
	var sitios: Array = EspaciosCatalogo.OFICINA.get("sitios_companeros", [])
	for i in mini(quienes.size(), sitios.size()):
		var quien: Dictionary = quienes[i]
		var figura := {
			"pos": sitios[i],
			"color": quien.get("color", Color(0.3, 0.3, 0.3)),
			"modelo": Companeros.cuerpo_de(quien),
			"retrato": quien.get("retrato", ""),
			"rotulo": "",
			"frase": "",
		}
		figuras.append(figura)
	return figuras


## Una persona montada fuera de la oficina, para que el contrato cubra también
## `Modelos.persona` y su ropa en un sitio que no pide luz por píxel.
func _persona_suelta(sitio: Node3D) -> void:
	var quien: Dictionary = Companeros.plantilla(126)[0]
	var cuerpo := Node3D.new()
	sitio.add_child(cuerpo)
	Modelos.persona(cuerpo, Companeros.cuerpo_de(quien), quien.get("color", Color.GRAY))


## Cuántas superficies usa cada variante del shader PSX bajo [param sitio].
func _materiales_psx(sitio: Node) -> Dictionary:
	var cuenta := {}
	for nodo in sitio.find_children("*", "MeshInstance3D", true, false):
		var malla: MeshInstance3D = nodo
		for material in _materiales_de(malla):
			if not (material is ShaderMaterial and material.shader != null):
				continue
			var ruta: String = material.shader.resource_path
			cuenta[ruta] = int(cuenta.get(ruta, 0)) + 1
	return cuenta


func _materiales_de(malla: MeshInstance3D) -> Array:
	if malla.material_override != null:
		return [malla.material_override]
	var materiales := []
	if malla.mesh == null:
		return materiales
	for superficie in malla.mesh.get_surface_count():
		var material := malla.get_active_material(superficie)
		if material != null:
			materiales.append(material)
	return materiales


## Los avatares con mapa de normales (#275) van a `psx_pbr`, que también
## ilumina por píxel: lo que se exige es recibir sombra, no un fichero concreto.
func _hay_persona_por_pixel(sitio: Node) -> bool:
	var por_pixel := [Espacio3D.SHADER_PSX_LUZ_PIXEL, TexturasPBR.SHADER_PBR]
	for nodo in sitio.find_children("*", "Skeleton3D", true, false):
		for hijo in nodo.find_children("*", "MeshInstance3D", true, false):
			for material in _materiales_de(hijo):
				if material is ShaderMaterial and material.shader.resource_path in por_pixel:
					return true
	return false


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO luz por píxel del mobiliario #789: " + nombre)
