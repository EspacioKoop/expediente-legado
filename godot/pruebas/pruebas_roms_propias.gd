## RomsPropias en runtime: índice, tienda, consola y fuente de semilla (#244).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	if OS.get_environment("LEGADO_PRUEBAS_AISLADAS") != "1":
		printerr("Ejecuta esta prueba desde unittest con datos aislados.")
		quit(1)
		return
	var todas := RomsPropias.todas()
	_comprobar(todas.size() >= 3, "el índice carga")
	for id_rom in ["caza_pixeles_98", "paper_planes_98", "croc_riders_98"]:
		_comprobar(RomsPropias.por_id(id_rom).get("estado", "") == "jugable", "jugable " + id_rom)
	_comprobar(not RomsPropias.en_proyecto().is_empty(), "hay ROMs en proyecto")
	_comprobar(RomsPropias.por_id("no_existe").is_empty(), "id desconocido vacío")

	var venta := TiendaVideojuegos.catalogo()
	var ids_venta := venta.map(func(e): return e["id"])
	_comprobar(ids_venta.has("paper_planes_98"), "la tienda vende Paper Planes 98")
	_comprobar(ids_venta.has("croc_riders_98"), "la tienda vende Croc Riders 98")
	_comprobar(not ids_venta.has("caza_pixeles_98"), "la incluida no se vende")
	for rom in RomsPropias.en_proyecto():
		_comprobar(not ids_venta.has(rom["id"]), "no se vende lo que no existe: " + rom["id"])

	var sin_compras := RomsPropias.en_consola([]).map(func(e): return e["id"])
	_comprobar(not sin_compras.has("paper_planes_98"), "sin comprar no está en la consola")
	_comprobar(not sin_compras.has("sueno_98"), "sin conocimiento SUEÑO 98 no aparece")
	var con_compras := RomsPropias.en_consola(["paper_planes_98", "ariadna_labertinto_98"])
	var ids_consola := con_compras.map(func(e): return e["id"])
	_comprobar(not ids_consola.has("ariadna_labertinto_98"), "en proyecto nunca en consola")
	for rom in con_compras:
		_comprobar(FileAccess.file_exists(rom["rom"]), "la consola solo lista artefactos reales")
	if RomsPropias.disponible(RomsPropias.por_id("paper_planes_98")):
		_comprobar(ids_consola.has("paper_planes_98"), "comprada aparece en la consola")
		_comprobar(sin_compras.has("caza_pixeles_98"), "la incluida aparece sin comprar")
	if RomsPropias.disponible(RomsPropias.por_id("sueno_98")):
		var por_conocimiento := RomsPropias.en_consola([], ["sueno_98"]).map(
			func(e): return e["id"]
		)
		_comprobar(por_conocimiento.has("sueno_98"), "desbloqueada aparece sin compra")

	_comprobar(
		RomsPropias.fuente_semilla("ariadna_labertinto_98") == MinotauroVigilia.FUENTE,
		"el Minotauro usa la fuente del índice"
	)
	_comprobar(RomsPropias.fuente_semilla("no_existe").is_empty(), "sin id no hay fuente")
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO RomsPropias: " + nombre)
