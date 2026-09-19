## Regresión de progreso Tarot no oculto (#1029).
##
## Las cartas de progreso nacen de eventos de juego, no de abrir una pantalla.
## Este corte fija la transición de completar la investigación de un expediente.
extends RefCounted


static func todo(comprobar: Callable) -> void:
	var caso := {"id": "caso-tarot", "pistas": [{"id": "p1"}, {"id": "p2"}]}
	var estado := Partida.nueva()
	estado["pistas_descubiertas"] = ["p1"]

	var parcial := Prometeo.sincronizar_tarot_por_caso_resuelto(estado, caso)
	comprobar.call("caso incompleto no concede Enamorados", parcial, [])

	estado["pistas_descubiertas"].append("p2")
	var completas := Prometeo.sincronizar_tarot_por_caso_resuelto(estado, caso)
	comprobar.call("última pista concede Enamorados", completas, ["los-enamorados"])
	comprobar.call(
		"Enamorados queda recogida",
		bool(_carta(estado, "los-enamorados").get("recogida", false)),
		true
	)
	comprobar.call(
		"Enamorados entra en memoria fantasma",
		estado.get("cartas_conocidas", []).has("los-enamorados"),
		true
	)

	var repetida := Prometeo.sincronizar_tarot_por_caso_resuelto(estado, caso)
	comprobar.call("resolver otra vez no reemite Enamorados", repetida, [])

	var recargado: Dictionary = JSON.parse_string(JSON.stringify(estado))
	var tras_recarga := Prometeo.sincronizar_tarot_por_caso_resuelto(recargado, caso)
	comprobar.call("estado ya adquirido sigue siendo idempotente", tras_recarga, [])
	comprobar.call(
		"recarga conserva Enamorados",
		bool(_carta(recargado, "los-enamorados").get("recogida", false)),
		true
	)

	var vacio := Partida.nueva()
	var sin_pistas := {"id": "sin-pistas", "pistas": []}
	var imposible := Prometeo.sincronizar_tarot_por_caso_resuelto(vacio, sin_pistas)
	comprobar.call("caso sin pistas no cuenta como resuelto", imposible, [])


static func _carta(estado: Dictionary, carta_id: String) -> Dictionary:
	var encontrada := {}
	for carta in estado.get("tarot", []):
		if carta.get("id", "") == carta_id:
			encontrada = carta
			break
	return encontrada
