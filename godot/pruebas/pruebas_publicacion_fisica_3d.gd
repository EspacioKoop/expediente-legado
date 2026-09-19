extends SceneTree

const Fisica := preload("res://guion/publicacion_fisica_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_catalogo_completo()
	_probar_formatos()
	_probar_colision_domestica()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_catalogo_completo() -> void:
	var catalogo := Publicaciones98.catalogo()
	_comprobar(catalogo.size() == 7, "el acabado cubre las siete publicaciones")
	for ficha in catalogo:
		var item_id := String(ficha.get("id", ""))
		var raiz := Node3D.new()
		root.add_child(raiz)
		var resultado := Fisica.montar(raiz, item_id)
		_comprobar(not resultado.is_empty(), "%s obtiene acabado físico" % item_id)
		_comprobar(raiz.has_meta("acabado_publicacion"), "%s marca acabado común" % item_id)
		_comprobar(
			String(raiz.get_meta("cabecera_publicacion", "")) == Fisica.cabecera_de(item_id),
			"%s conserva cabecera" % item_id
		)
		_comprobar(
			String(raiz.get_meta("edicion_publicacion", "")) == Fisica.edicion_de(item_id),
			"%s conserva edición" % item_id
		)
		var titulo := raiz.get_node_or_null("TituloPortada") as Label3D
		var edicion := raiz.get_node_or_null("EdicionPortada") as Label3D
		_comprobar(titulo != null, "%s tiene título físico de portada" % item_id)
		_comprobar(edicion != null, "%s tiene edición física de portada" % item_id)
		if titulo != null:
			_comprobar(
				titulo.text == Fisica.cabecera_de(item_id), "%s rotula su cabecera" % item_id
			)
		if edicion != null:
			_comprobar(
				edicion.text == Fisica.edicion_de(item_id), "%s rotula su número/año" % item_id
			)
		var formato := String(resultado.get("formato", ""))
		var lomo := raiz.get_node_or_null("LomoPublicacion") as Label3D
		if formato == "periodico":
			_comprobar(lomo == null, "%s conserva pliego sin lomo falso" % item_id)
		else:
			_comprobar(lomo != null, "%s tiene lomo físico rotulado" % item_id)
		raiz.queue_free()


func _probar_formatos() -> void:
	_comprobar(
		Fisica.formato_de(Publicaciones98.por_id("periodico_tarde_98")) == "periodico",
		"La Tarde conserva formato periódico"
	)
	_comprobar(
		Fisica.formato_de(Publicaciones98.por_id("manual_casa_98")) == "libro",
		"Manual conserva formato libro"
	)
	_comprobar(
		Fisica.formato_de(Publicaciones98.por_id("libro_popol_wuj_98")) == "libro",
		"Popol Wuj conserva formato de cuaderno/libro"
	)
	_comprobar(
		Fisica.formato_de(Publicaciones98.por_id("revista_umbral_98")) == "revista",
		"Umbral conserva formato revista"
	)
	_comprobar(
		Fisica.cabecera_de("byte_domestico_42") != Fisica.cabecera_de("marcador_98_deportes"),
		"las cabeceras son distinguibles"
	)
	_comprobar(
		Fisica.paleta_de("estratos_ciudad_06") != Fisica.paleta_de("manual_casa_98"),
		"las publicaciones culturales y prácticas no comparten paleta"
	)


func _probar_colision_domestica() -> void:
	var lectura := Interactuable3D.new()
	root.add_child(lectura)
	var resultado := Fisica.montar(lectura, "revista_umbral_98", true)
	_comprobar(not resultado.is_empty(), "el ejemplar doméstico se materializa")
	_comprobar(
		lectura.get_node_or_null("ColisionPublicacion") is CollisionShape3D,
		"el acabado puede aportar la colisión de lectura doméstica"
	)
	_comprobar(
		String(lectura.get_meta("acabado_publicacion", "")) == "editorial_98",
		"hallazgo y casa pueden compartir la misma firma visual"
	)
	lectura.queue_free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PublicacionFisica3D: " + nombre)
