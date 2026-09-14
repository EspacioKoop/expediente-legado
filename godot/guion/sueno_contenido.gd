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
##   firmaste, pero firmarlo se nota. Y con el que firmaste **se puede pelear**
##   (#88, `SuenoCombate`), así que la figura se lleva su id y sus réplicas
##   puestas: quien monta la sala no tiene que volver al archivo a buscar
##   contra quién está peleando.
##
## Todo esto es PURO: entran diccionarios de contenido y salen listas de qué
## poner. Dónde cae cada cosa lo decide quien monta la sala, que es el único
## que sabe la forma que tiene.
class_name SuenoContenido
extends RefCounted


## Lo que el día de hoy deja para deformar esta noche.
##
## [param leido_hoy] son folios; [param descubiertas], ids de pista;
## [param veredictos], el `caso_id -> sospechoso_id` que guarda `Acusacion`;
## [param vencidos], los que ya te peleaste y ganaste (#88), que **dejan de
## aparecer**. Es la consecuencia que se ve sin texto que la explique: la sala
## donde estaba está vacía la próxima vez.
static func fuentes(
	leido_hoy: Array,
	casos: Array,
	descubiertas: Array,
	veredictos: Dictionary,
	vencidos: Array = []
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
			var id: String = sospechoso.get("id", "")
			if vencidos.has(id):
				continue
			(
				figuras
				. append(
					{
						"id": id,
						"nombre": sospechoso.get("nombre", ""),
						"acusado": id == acusado,
						# Sus réplicas viajan con él porque el duelo es dentro del
						# sueño: un rival sin nada escrito pelea igual y no dice nada,
						# que es mejor que decir algo genérico.
						"ataques": sospechoso.get("ataques", []),
					}
				)
			)

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
