## De qué está hecho un sueño (#87).
##
## **El sueño no inventa contenido: lo deforma.** Todo lo que aparece dentro
## tiene un original en el archivo, y reconocerlo es la mitad del efecto — una
## sala con cosas sin original detrás es ruido con luz de sueño.
##
## La fuente es `jornada.leido_hoy`, que registra los documentos abiertos ESE
## día desde #61 precisamente para esto. De ahí salen dos deformaciones:
##
## - **Las frases gatillo, escritas en las paredes.** Solo las que SÍ notaste
##   (decisión de Eloy, 2026-09-10). El sueño es memoria y no un sistema de
##   pistas: escribir en la pared la frase que se te pasó sería decirte dónde
##   mirar, y entonces dormir pasaría a ser lo óptimo — que es justo el problema
##   que #79 tiene abierto y #89 tiene que resolver.
## - **Los sospechosos, como figuras.** Todos los de los expedientes que
##   tocaste, y **el que acusaste se ve distinto**: no te persigue solo quien
##   firmaste, pero firmarlo se nota.
##
## Todo esto es PURO: entran diccionarios de contenido y salen listas de qué
## poner. Dónde cae cada cosa lo decide quien monta la sala, que es el único
## que sabe la forma que tiene.
class_name SuenoContenido
extends RefCounted


## Lo que el día de hoy deja para deformar esta noche.
##
## [param leido_hoy] son folios; [param descubiertas], ids de pista;
## [param veredictos], el `caso_id -> sospechoso_id` que guarda `Acusacion`.
static func fuentes(
	leido_hoy: Array, casos: Array, descubiertas: Array, veredictos: Dictionary
) -> Dictionary:
	var frases := []
	var figuras := []
	var casos_tocados := {}

	for caso in casos:
		var registros: Array = caso.get("registros", [])
		var tocados := registros.filter(func(r): return leido_hoy.has(r.get("folio", "")))
		if tocados.is_empty():
			continue
		casos_tocados[caso["id"]] = true

		# Las frases: las de las pistas descubiertas cuyo origen es un
		# documento de HOY. Una pista descubierta hace tres días en otro
		# documento no está en el sueño de esta noche.
		var ids := tocados.map(func(r): return r.get("id", ""))
		for pista in caso.get("pistas", []):
			if not ids.has(pista.get("registroOrigen", "")):
				continue
			if not descubiertas.has(pista.get("id", "")):
				continue
			var frase: String = pista.get("fraseGatillo", "")
			if not frase.is_empty() and not frases.has(frase):
				frases.append(frase)

		var acusado: String = veredictos.get(caso["id"], "")
		for sospechoso in caso.get("sospechosos", []):
			(
				figuras
				. append(
					{
						"nombre": sospechoso.get("nombre", ""),
						"acusado": sospechoso.get("id", "") == acusado,
					}
				)
			)

	# Añadir contenido onírico de semillas activadas (interacciones fuera de la oficina)
	var contenido_onirico := SemillasOniricas.obtener_contenido_onirico()
	for frase in contenido_onirico.get("frases", []):
		if not frase.is_empty() and not frases.has(frase):
			frases.append(frase)
	for figura in contenido_onirico.get("figuras", []):
		# Evitar duplicados por nombre (simplificado)
		var ya_existe := false
		for f in figuras:
			if f.get("nombre") == figura["nombre"]:
				ya_existe = true
				break
		if not ya_existe:
			figuras.append(figura)

	return {"frases": frases, "figuras": figuras, "casos": casos_tocados.keys()}


## Reparte lo que hay entre las escenas de la noche.
##
## Una sala son VARIOS documentos (decisión de Eloy, 2026-09-10): las salas
## siguen siendo las cinco grandes y raras de #86 y lo leído las amuebla, en
## vez de haber una sala por documento.
##
## Un día sin leer nada da salas VACÍAS, y eso es lo correcto: no hay original
## que deformar. Un día de trabajo que no deja huella dice algo, y rellenarlo
## con cualquier cosa diría lo contrario.
static func repartir(fuentes: Dictionary, escenas: int, semilla: int) -> Array:
	var reparto := []
	for i in escenas:
		reparto.append({"frases": [], "figuras": []})
	if escenas <= 0:
		return reparto

	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	for clave in ["frases", "figuras"]:
		var cosas: Array = fuentes.get(clave, []).duplicate()
		_barajar(cosas, rng)
		# En rueda: con menos cosas que escenas, las primeras se quedan sin
		# nada antes que amontonarlo todo en la primera.
		for i in cosas.size():
			reparto[i % escenas][clave].append(cosas[i])
	return reparto


static func _barajar(lista: Array, rng: RandomNumberGenerator) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var guardado = lista[i]
		lista[i] = lista[j]
		lista[j] = guardado
