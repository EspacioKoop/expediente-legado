## Capa de #94 sobre casa y sueño.
##
## La mesa ofrece un trabajillo nocturno determinista entre transcripción,
## sobres y encuestas. Todos pagan lo mismo y solo una vez por noche: la variedad
## es tonal, no una vía de arbitraje económico. Encadenar noches empeora el sueño.
extends "res://guion/dia_alquiler_app.gd"

const DESTINO_TRABAJILLO := "trabajillo"


func _espacio_de(fase: String) -> Dictionary:
	var espacio: Dictionary = super._espacio_de(fase)
	# Sin vivienda no aparece mágicamente un segundo empleo en la oficina donde
	# se duerme: #84 sigue siendo la consecuencia dominante del impago.
	if fase != "casa" or _vivienda() != "casa":
		return espacio

	var oferta := Trabajillos.oferta_del_dia(jornada)
	# La mesa ya existe. Solo se deja encima un pequeño lote de papel y una zona
	# de interacción; no hace falta inventar otra pantalla para trabajos que deben
	# sentirse rutinarios, baratos e intercambiables.
	espacio["bultos"].append(
		{
			"pos": Vector3(2.45, 0.96, -2.4),
			"tam": Vector3(0.50, 0.08, 0.34),
			"color": Color(0.78, 0.76, 0.68)
		}
	)
	espacio["salidas"].append(
		{
			"pos": Vector3(2.6, 1.0, -2.4),
			"destino": DESTINO_TRABAJILLO,
			"rotulo": String(oferta["rotulo"]),
			"tam": Vector3(1.7, 1.6, 1.4)
		}
	)
	return espacio


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	if (
		cuerpo == _caminante
		and _pantalla == null
		and not partida.guardado_pendiente
		and String(salida.get_meta("destino", "")) == DESTINO_TRABAJILLO
	):
		_hacer_trabajillo()
		return
	super._al_pisar_salida(cuerpo, salida)


func _hacer_trabajillo() -> void:
	_hablando = false
	var resultado := Trabajillos.hacer(jornada)
	if resultado.is_empty():
		_sonar("error")
		_nomina.text = tr("TRABAJILLO_YA_HECHO")
		return

	_sonar("nomina")
	# Igual que alimentar al gato: el dinero ya cambió en memoria. Si falla el
	# guardado, la siguiente interacción reintenta escribir sin volver a cobrar.
	if not _guardar_o_avisar(""):
		return
	var mensaje := (
		tr(String(resultado["cobrado"])) % [resultado["importe"], resultado["dinero"]]
	)
	if int(resultado["racha"]) >= 2:
		mensaje += "\n" + tr("TRABAJILLO_RACHA")
	_nomina.text = mensaje


## Combina costes en vez de reemplazarlos. Una noche aislada reduce 3 -> 2;
## encadenar dos o más noches reduce 3 -> 1. Sin casa, la política de #84 ya da
## 1 y este trabajo nunca está disponible.
func _opciones_sueno() -> Dictionary:
	var opciones: Dictionary = super._opciones_sueno().duplicate(true)
	if not Trabajillos.hecho_hoy(jornada):
		return opciones
	var cantidad := int(opciones.get("cantidad", Sueno.ESCENAS_POR_NOCHE))
	opciones["cantidad"] = mini(
		cantidad, Trabajillos.escenas_de_sueno(jornada, Sueno.ESCENAS_POR_NOCHE)
	)
	return opciones
