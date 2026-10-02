class_name JuicioCombateEnjambreRuntime
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")


## Adaptador puro de tick para el enjambre.
## Delegue en JuicioCombateArquetipoHost.avanzar_enjambre() y expone índices
## de transición de estado para el host.
static func tick(unidades: Array, delta: float, presupuesto: int) -> Dictionary:
	var paso := JuicioCombateArquetipoHost.avanzar_enjambre(unidades, delta, presupuesto)

	var nuevas := paso.unidades
	var resultados := paso.resultados
	var atacantes_activos := paso.atacantes_activos

	var inicio_ataque := []
	var abrir_ventana := []

	for i in range(unidades.size()):
		var u_ant := unidades[i]
		var u_nue := nuevas[i]

		# Ignorar unidades derrotadas para nuevos ataques
		if u_nue.get("determinacion", 1) <= 0:
			continue

		var est_ant := String(u_ant.get("estado", ""))
		var est_nue := String(u_nue.get("estado", ""))

		# Entran en ATACAR: estado nuevo es ATACAR y el anterior no lo era
		if est_nue == ARQUETIPOS.ATACAR and est_ant != ARQUETIPOS.ATACAR:
			inicio_ataque.append(i)

		# Entran en RECUPERAR: estado nuevo es RECUPERAR y el anterior no lo era
		if est_nue == ARQUETIPOS.RECUPERAR and est_ant != ARQUETIPOS.RECUPERAR:
			abrir_ventana.append(i)

	return {
		"unidades": nuevas,
		"resultados": resultados,
		"atacantes_activos": atacantes_activos,
		"inicio_ataque": inicio_ataque,
		"abrir_ventana": abrir_ventana
	}
