## Efecto textual narrativo determinista para contaminación Prometeo/Hastur (#806).
##
## No usa RNG global ni decide progreso. Recibe texto, intensidad y una semilla
## narrativa estable; la misma entrada produce siempre el mismo fotograma.
class_name TextoCorruptoNarrativo
extends RefCounted

const GLIFOS := ["!", "?", "/", "\\", "|", "X", "I", "9", "0", "#"]


static func progreso_para_tiempo(segundos: float, duracion: float, invertir := false) -> float:
	if duracion <= 0.0:
		return 0.0 if invertir else 1.0
	var progreso := clampf(segundos / duracion, 0.0, 1.0)
	return 1.0 - progreso if invertir else progreso


static func resolver_texto(
	texto: String,
	intensidad: float,
	semilla: String,
	reducir_movimiento := false,
	critico := false,
) -> String:
	if texto.is_empty() or reducir_movimiento or critico:
		return texto
	var nivel := clampf(intensidad, 0.0, 1.0)
	if nivel <= 0.0:
		return texto

	var salida := ""
	for indice in texto.length():
		var caracter := texto.substr(indice, 1)
		if caracter == "\n" or caracter == "\t" or caracter == " ":
			salida += caracter
			continue

		var firma := absi(hash("%s:%d" % [semilla, indice]))
		var umbral := float(posmod(firma, 1000)) / 999.0
		if umbral > nivel:
			salida += caracter
			continue

		var modo := posmod(firma / 1000, 3)
		match modo:
			0:
				var repeticiones := 2 + posmod(firma / 3000, 3)
				salida += caracter.repeat(repeticiones)
			1:
				salida += GLIFOS[posmod(firma / 7000, GLIFOS.size())]
			_:
				var siguiente := texto.substr((indice + 1) % texto.length(), 1)
				salida += caracter + siguiente
	return salida


static func resolver_presentacion(
	texto: String,
	progreso: float,
	configuracion: Dictionary,
	reducir_movimiento := false,
	critico := false,
) -> Dictionary:
	var intensidad_maxima := clampf(float(configuracion.get("intensidad", 1.0)), 0.0, 1.0)
	var intensidad := clampf(progreso, 0.0, 1.0) * intensidad_maxima
	var semilla := String(configuracion.get("semilla", "texto-corrupto"))
	return {
		"texto_visual": resolver_texto(texto, intensidad, semilla, reducir_movimiento, critico),
		"texto_legible": texto,
		"animar": not reducir_movimiento and not critico and intensidad_maxima > 0.0,
		"intensidad": intensidad,
	}


static func aplicar(
	nodo: Node,
	texto: String,
	progreso: float,
	configuracion: Dictionary,
	reducir_movimiento := false,
	critico := false,
) -> Dictionary:
	var presentacion := resolver_presentacion(
		texto, progreso, configuracion, reducir_movimiento, critico
	)
	if nodo is Label:
		(nodo as Label).text = String(presentacion["texto_visual"])
	elif nodo is RichTextLabel:
		(nodo as RichTextLabel).text = String(presentacion["texto_visual"])
	elif nodo is Label3D:
		(nodo as Label3D).text = String(presentacion["texto_visual"])
	return presentacion
