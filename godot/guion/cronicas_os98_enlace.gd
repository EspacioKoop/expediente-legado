## Adaptador opt-in de Crónicas como aplicación real del escritorio OS98 (#2589).
## No persiste EstadoAplicacionesSiga ni altera Partida, sueño o clímax.
class_name CronicasOs98Enlace
extends RefCounted

const ID_APP := "cronicas-pc-98"


static func registrar(
	escritorio: EscritorioSiga, al_completar: Callable = Callable()
) -> EscritorioSigaApp:
	if escritorio == null:
		return null

	# Se crean nuevas instancias solo al abrir la ventana; un único juego activo.
	var crear := func() -> Control:
		var programa := CronicasPc98.new()
		programa.modo_ventana_os98 = true
		if al_completar.is_valid():
			programa.prologo_completado.connect(al_completar)
		programa.cerrar_solicitado.connect(
			func() -> void:
				if is_instance_valid(escritorio):
					escritorio.cerrar(ID_APP)
		)
		return programa

	var app := (
		EscritorioSigaApp
		. new(
			ID_APP,
			TranslationServer.translate("CRONICAS_PC_TITULO"),
			crear,
			"software",
		)
	)
	app.tamano_minimo = Vector2(680, 520)
	app.tamano_preferido = Vector2(990, 730)
	app.redimensionable = true
	app.persistir_estado = true  # Solo metadatos verificables; nunca el progreso de Partida.
	if not app.registrar_en(escritorio):
		return null
	return app
