## Smoke headless del contrato de publicaciones físicas de 1998 (#674).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var catalogo := Publicaciones98.catalogo()
	_comprobar(catalogo.size() == 7, "siete publicaciones diferenciadas")
	var ids: Array[String] = []
	for entrada in catalogo:
		var item_id := String(entrada.get("id", ""))
		_comprobar(not item_id.is_empty(), "id estable")
		_comprobar(not ids.has(item_id), "id no repetido")
		ids.append(item_id)
		_comprobar(not String(entrada.get("titulo", "")).is_empty(), "título original")
		_comprobar(not String(entrada.get("categoria", "")).is_empty(), "categoría cultural")
		_comprobar(bool(entrada.get("permite_casa", false)), "puede guardarse en casa")

	_comprobar(Publicaciones98.comprables().size() == 3, "tres publicaciones usan quiosco")
	var umbral := Publicaciones98.por_id("revista_umbral_98")
	var popol := Publicaciones98.por_id("libro_popol_wuj_98")
	var tarde := Publicaciones98.por_id("periodico_tarde_98")
	_comprobar(Array(umbral.get("piezas", [])).size() >= 3, "Umbral tiene contenido hojeable")
	_comprobar(Array(popol.get("piezas", [])).size() >= 3, "Popol Wuj tiene contenido hojeable")
	_comprobar(Array(tarde.get("piezas", [])).size() >= 3, "La Tarde tiene contenido hojeable")

	var jornada := Jornada.nueva(674, 1)
	jornada["dia"] = 2
	jornada["fase"] = "trayecto"
	jornada["dinero"] = 20
	var inventario := {}
	var compra := Publicaciones98.comprar(jornada, inventario, "revista_umbral_98")
	_comprobar(bool(compra.get("ok", false)), "compra delegada al comercio existente")
	_comprobar(int(jornada["dinero"]) == 12, "usa precio y saldo existentes")
	_comprobar(Inventario.contiene(inventario, "revista_umbral_98"), "compra entra en inventario")
	_comprobar(SemillasOniricas.familias_activas(jornada).is_empty(), "comprar no activa semilla")
	var recompra := Publicaciones98.comprar(jornada, inventario, "revista_umbral_98")
	_comprobar(bool(recompra.get("ok", false)), "recompra idempotente")
	_comprobar(int(jornada["dinero"]) == 12, "recompra no cobra dos veces")
	var no_comprable := Publicaciones98.comprar(jornada, inventario, "byte_domestico_42")
	_comprobar(not bool(no_comprable.get("ok", true)), "encontrable no crea otra compra")

	var primera := Publicaciones98.hojear(jornada, "revista_umbral_98", "portada")
	_comprobar(bool(primera.get("ok", false)), "primera pieza legible")
	_comprobar(bool(primera.get("nueva", false)), "primera lectura cuenta")
	_comprobar(
		not Publicaciones98.puede_sembrar(jornada, "revista_umbral_98"), "una pieza no basta"
	)
	_comprobar(SemillasOniricas.familias_activas(jornada).is_empty(), "hojear una pieza no activa")
	var repetida := Publicaciones98.hojear(jornada, "revista_umbral_98", "portada")
	_comprobar(not bool(repetida.get("nueva", true)), "releer no infla progreso")
	_comprobar(
		Publicaciones98.contenido_visto(jornada, "revista_umbral_98").size() == 1,
		"visto idempotente"
	)
	var cierre_pronto := Publicaciones98.cerrar_tras_lectura(jornada, "revista_umbral_98")
	_comprobar(not bool(cierre_pronto.get("semilla_activada", true)), "cierre temprano no siembra")

	Publicaciones98.hojear(jornada, "revista_umbral_98", "dossier")
	_comprobar(
		Publicaciones98.puede_sembrar(jornada, "revista_umbral_98"), "dos piezas preparan semilla"
	)
	_comprobar(
		SemillasOniricas.familias_activas(jornada).is_empty(),
		"lectura suficiente aún requiere cierre"
	)
	var cierre := Publicaciones98.cerrar_tras_lectura(jornada, "revista_umbral_98")
	_comprobar(bool(cierre.get("semilla_activada", false)), "cierre deliberado activa semilla")
	_comprobar(
		SemillasOniricas.familias_activas(jornada) == ["minotauro"], "activa familia declarada"
	)
	var semillas := SemillasOniricas.obtener_semillas(jornada)
	var entrada_semilla: Dictionary = semillas[SemillasOniricas.clave("minotauro")]
	_comprobar(
		Array(entrada_semilla.get("fuentes", [])).has("publicacion:revista_umbral_98"),
		"fuente cultural estable",
	)
	var cierre_repetido := Publicaciones98.cerrar_tras_lectura(jornada, "revista_umbral_98")
	_comprobar(
		bool(cierre_repetido.get("semilla_activada", false)), "cierre repetido es idempotente"
	)
	_comprobar(int(entrada_semilla.get("intensidad", 0)) == 1, "misma fuente no suma intensidad")

	var jornada_popol := Jornada.nueva(655, 1)
	jornada_popol["dia"] = 2
	jornada_popol["fase"] = "trayecto"
	jornada_popol["dinero"] = 20
	var inventario_popol := {}
	var compra_popol := Publicaciones98.comprar(
		jornada_popol, inventario_popol, "libro_popol_wuj_98"
	)
	_comprobar(bool(compra_popol.get("ok", false)), "cuaderno Popol Wuj se compra en trayecto")
	_comprobar(int(jornada_popol["dinero"]) == 10, "cuaderno usa economía del quiosco")
	_comprobar(
		Inventario.contiene(inventario_popol, "libro_popol_wuj_98"),
		"cuaderno cultural entra en inventario",
	)
	_comprobar(
		SemillasOniricas.familias_activas(jornada_popol).is_empty(),
		"comprar cuaderno Popol Wuj no activa sueño",
	)
	var fuente_popol := ComercioBarrio.fuente_cultural("libro_popol_wuj_98")
	_comprobar(
		String(fuente_popol.get("id_semilla", "")) == "popol_wuj",
		"quiosco expone familia Popol Wuj sin activarla",
	)
	_comprobar(
		String(fuente_popol.get("fuente", "")) == "libro:popol_wuj_98",
		"quiosco reutiliza fuente cultural estable",
	)

	Publicaciones98.hojear(jornada_popol, "libro_popol_wuj_98", "portada")
	var cierre_popol_pronto := Publicaciones98.cerrar_tras_lectura(
		jornada_popol, "libro_popol_wuj_98"
	)
	_comprobar(
		not bool(cierre_popol_pronto.get("semilla_activada", true)),
		"una sola pieza Popol Wuj no siembra",
	)
	Publicaciones98.hojear(jornada_popol, "libro_popol_wuj_98", "gemelos")
	_comprobar(
		Publicaciones98.puede_sembrar(jornada_popol, "libro_popol_wuj_98"),
		"dos piezas Popol Wuj preparan la semilla",
	)
	_comprobar(
		SemillasOniricas.familias_activas(jornada_popol).is_empty(),
		"leer dos piezas Popol Wuj aún exige cierre",
	)
	var cierre_popol := Publicaciones98.cerrar_tras_lectura(
		jornada_popol, "libro_popol_wuj_98"
	)
	_comprobar(bool(cierre_popol.get("semilla_activada", false)), "cierre activa Popol Wuj")
	_comprobar(
		SemillasOniricas.familias_activas(jornada_popol) == ["popol_wuj"],
		"el cuaderno activa solo la familia declarada",
	)
	var semillas_popol := SemillasOniricas.obtener_semillas(jornada_popol)
	var entrada_popol: Dictionary = semillas_popol[SemillasOniricas.clave("popol_wuj")]
	_comprobar(
		Array(entrada_popol.get("fuentes", [])).has("libro:popol_wuj_98"),
		"cuaderno comparte fuente con la vigilia standalone",
	)
	Publicaciones98.cerrar_tras_lectura(jornada_popol, "libro_popol_wuj_98")
	_comprobar(
		int(entrada_popol.get("intensidad", 0)) == 1,
		"repetir cierre Popol Wuj no duplica intensidad",
	)

	var lectura_prensa := Publicaciones98.hojear(jornada, "periodico_tarde_98", "local")
	_comprobar(bool(lectura_prensa.get("ok", false)), "segunda publicación se hojea")
	var cierre_prensa := Publicaciones98.cerrar_tras_lectura(jornada, "periodico_tarde_98")
	_comprobar(bool(cierre_prensa.get("ok", false)), "publicación sin semilla cierra normal")
	_comprobar(
		not bool(cierre_prensa.get("semilla_activada", true)), "prensa normal no contamina sueño"
	)

	var desconocida := Publicaciones98.hojear(jornada, "no_existe", "portada")
	_comprobar(not bool(desconocida.get("ok", true)), "rechaza publicación inexistente")
	var pieza_desconocida := Publicaciones98.hojear(jornada, "periodico_tarde_98", "no_existe")
	_comprobar(not bool(pieza_desconocida.get("ok", true)), "rechaza pieza inexistente")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
