## La luz de la oficina, medida sobre el árbol real (#789).
##
## El hallazgo del playtest era «techo y paredes quemados, sin sombras de
## muebles ni personas». La causa no estaba en las lámparas —que llevan
## encendidas desde #1121— sino en que el material las tiraba: con
## `vertex_lighting` la sombra no se aplica, llegue como llegue.
##
## Por eso lo que se exige aquí es la cadena entera y no una preferencia: el
## sitio pide luz por píxel, la envolvente se pinta con el shader que la admite,
## la lámpara usa el modo de sombra que Forward+ dibuja de verdad y el techo deja
## de taparlo todo con su propia emisión. Y se exige también lo contrario, que es
## lo que mantiene pequeño el cambio: un sitio que no lo pide sigue exactamente
## como estaba.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var oficina := Node3D.new()
	root.add_child(oficina)
	Espacio3D.construir(oficina, EspaciosCatalogo.OFICINA.duplicate(true))
	await process_frame

	var calle := Node3D.new()
	root.add_child(calle)
	Espacio3D.construir(calle, EspaciosCatalogo.CALLE.duplicate(true))
	await process_frame

	_shader_del_sitio(oficina, Espacio3D.SHADER_PSX_LUZ_PIXEL, "la oficina")
	# La calle se construye DESPUÉS de la oficina a propósito: el shader del
	# sitio es estado del módulo, así que esto es lo que impide que entrar en la
	# oficina deje contagiado todo lo que se monte después.
	_shader_del_sitio(calle, Espacio3D.SHADER_PSX, "la calle, construida después")

	_modo_de_sombra(oficina, OmniLight3D.SHADOW_CUBE, "la oficina")
	_modo_de_sombra(calle, OmniLight3D.SHADOW_DUAL_PARABOLOID, "la calle")

	_techo_no_quemado(oficina)
	_pantallas_encendidas(oficina)
	_la_variante_es_por_pixel()

	oficina.queue_free()
	calle.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


## Con qué se pinta la ENVOLVENTE de un sitio: suelo, techo, muros y los bultos
## que siguen siendo una caja. Se mide sobre todas ellas y no sobre una de
## muestra, porque basta una superficie grande mal iluminada para que la sala
## entera se lea mal.
##
## Deliberadamente NO entra lo que trae malla propia. Un mueble CC0 y una persona
## reciben su material de `modelos.gd` y `vestuario_humano_3d.gd`, que en este
## corte no se tocan: están reservados por #275/#701. Siguen con luz por vértice,
## así que no reciben sombra aunque la proyecten. Es el segundo corte de #789.
func _shader_del_sitio(raiz: Node3D, esperado: String, quien: String) -> void:
	var rutas := {}
	var cajas := 0
	for malla in _mallas(raiz):
		if not (malla.mesh is BoxMesh):
			continue
		var material: Material = malla.material_override
		if material is ShaderMaterial:
			var shader: Shader = (material as ShaderMaterial).shader
			if shader != null:
				cajas += 1
				rutas[shader.resource_path] = true
	_comprobar(cajas > 10, true, "%s tiene envolvente que medir (%d cajas)" % [quien, cajas])
	_comprobar(
		rutas.keys(), [esperado], "la envolvente de %s se pinta solo con %s" % [quien, esperado]
	)


func _modo_de_sombra(raiz: Node3D, esperado: int, quien: String) -> void:
	var lamparas := 0
	for luz in _luces(raiz):
		if not String(luz.name).begins_with(Espacio3D.NOMBRE_LUZ_SALA):
			continue
		lamparas += 1
		_comprobar(luz.shadow_enabled, true, "cada lámpara de %s proyecta sombra" % quien)
		_comprobar(luz.omni_shadow_mode, esperado, "el modo de sombra de %s" % quien)
	_comprobar(lamparas > 0, true, "%s declara lámparas de sala" % quien)


## El techo sigue pintándose a sí mismo —su cara de abajo no recibe casi luz—,
## pero ya no a plena fuerza: al 0,9 de un sitio sin sombras lo que salía era una
## caja de luz que borraba el volumen de la sala entera.
func _techo_no_quemado(raiz: Node3D) -> void:
	var techo := _mas_alta_horizontal(raiz)
	_comprobar(techo != null, true, "se localiza el techo por geometría")
	if techo == null:
		return
	var material: ShaderMaterial = techo.material_override
	var fuerza := float(material.get_shader_parameter("emision_fuerza"))
	_comprobar(fuerza > 0.0, true, "el techo sigue emitiendo algo (%.2f)" % fuerza)
	_comprobar(
		fuerza < Espacio3D.EMISION_PLENA,
		true,
		"el techo de la oficina ya no emite a plena fuerza (%.2f)" % fuerza
	)


## Una sala donde todo el mundo trabaja no puede tener un solo terminal
## encendido. Se cuentan superficies que se pintan a sí mismas y no son el techo.
func _pantallas_encendidas(raiz: Node3D) -> void:
	var techo := _mas_alta_horizontal(raiz)
	var encendidas := 0
	for malla in _mallas(raiz):
		if malla == techo:
			continue
		var material: Material = malla.material_override
		if not (material is ShaderMaterial):
			continue
		var fuerza: Variant = (material as ShaderMaterial).get_shader_parameter("emision_fuerza")
		var caja := malla.get_aabb().size
		# Una pantalla es una superficie fina y a la altura de una mesa; la
		# carcasa de un fluorescente también emite y está en el techo.
		if (
			fuerza != null
			and float(fuerza) > 0.0
			and caja.y < 0.5
			and malla.global_position.y < 1.6
		):
			encendidas += 1
	_comprobar(encendidas >= 2, true, "hay más de un terminal encendido (%d)" % encendidas)


## Que la variante exista no basta: tiene que ser por píxel. Se lee del código
## del shader cargado, que es lo que el motor compila de verdad.
func _la_variante_es_por_pixel() -> void:
	var canonico: Shader = load(Espacio3D.SHADER_PSX)
	var variante: Shader = load(Espacio3D.SHADER_PSX_LUZ_PIXEL)
	_comprobar(
		canonico.code.contains("render_mode vertex_lighting"),
		true,
		"el shader canónico conserva su luz por vértice"
	)
	# Se mira el `render_mode` y no el fichero entero: el cuerpo de la variante es
	# copia byte a byte del canónico, comentarios incluidos, y alguno de ellos
	# nombra la luz por vértice al describir el tratamiento original.
	_comprobar(
		variante.code.contains("render_mode diffuse_lambert, specular_disabled;"),
		true,
		"la variante de la oficina declara su luz por píxel"
	)
	_comprobar(
		variante.code.contains("render_mode vertex_lighting"),
		false,
		"la variante de la oficina no calcula la luz por vértice"
	)
	_comprobar(
		variante.code.contains("bayer_4x4(FRAGCOORD.xy)"),
		true,
		"la variante conserva el dithering de la máquina que se imita"
	)


func _mas_alta_horizontal(raiz: Node) -> MeshInstance3D:
	var techo: MeshInstance3D = null
	for malla in _mallas(raiz):
		var caja := malla.get_aabb().size
		if caja.y > caja.x * 0.2 or caja.y > caja.z * 0.2:
			continue
		if techo == null or malla.global_position.y > techo.global_position.y:
			techo = malla
	return techo


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
	push_error("FALLO iluminación #789: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
