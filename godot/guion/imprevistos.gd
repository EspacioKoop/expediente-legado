## Imprevistos de cada vida laboral (#93).
##
## Se planifican una sola vez desde semilla + vuelta. No usan el azar global:
## guardar/cargar conserva exactamente los mismos sucesos y una nueva vuelta
## recibe otro plan. La capa no toca dinero; Jornada aplica el gasto para que
## siga existiendo una sola puerta económica.
class_name Imprevistos
extends RefCounted

const CLAVE_ESTADO := "imprevistos"
const VERSION := 1
const MIN_POR_VUELTA := 2
const MAX_POR_VUELTA := 4
const MAX_FUERTES := 1
const UNO_DE_CADA_SIN_IMPREVISTOS := 5
const INDICE_PLAN := 93

## Días separados por al menos una jornada completa. El día 1 queda limpio para
## no convertir el arranque de cada vida laboral en una multa de bienvenida.
const DIAS_CANDIDATOS := [2, 4, 6, 8, 10, 12]

## Costes calibrados contra #83: un imprevisto normal queda por debajo del coste
## diario (26) y el fuerte ronda un día de sueldo base (40). Nunca crean deuda.
const CATALOGO := [
	{
		"id": "bombilla_fundida",
		"nombre": "IMPREVISTO_BOMBILLA",
		"coste": 12,
		"consecuencia": "casa_luz_reducida",
		"fuerte": false,
	},
	{
		"id": "grifo_goteando",
		"nombre": "IMPREVISTO_GRIFO",
		"coste": 16,
		"consecuencia": "casa_grifo_averiado",
		"fuerte": false,
	},
	{
		"id": "persiana_atascada",
		"nombre": "IMPREVISTO_PERSIANA",
		"coste": 18,
		"consecuencia": "casa_persiana_atascada",
		"fuerte": false,
	},
	{
		"id": "recibo_inesperado",
		"nombre": "IMPREVISTO_RECIBO",
		"coste": 20,
		"consecuencia": "casa_recibo_pendiente",
		"fuerte": false,
	},
	{
		"id": "multa_transporte",
		"nombre": "IMPREVISTO_MULTA",
		"coste": 24,
		"consecuencia": "casa_multa_pendiente",
		"fuerte": false,
	},
	{
		"id": "calentador_averiado",
		"nombre": "IMPREVISTO_CALENTADOR",
		"coste": 38,
		"consecuencia": "casa_sin_agua_caliente",
		"fuerte": true,
	},
	{
		"id": "electrodomestico_roto",
		"nombre": "IMPREVISTO_ELECTRODOMESTICO",
		"coste": 36,
		"consecuencia": "casa_electrodomestico_roto",
		"fuerte": true,
	},
]


static func planificar(raiz: int, vuelta: int) -> Dictionary:
	var estado := {
		"version": VERSION,
		"raiz_plan": raiz,
		"vuelta_plan": vuelta,
		"plan": [],
		"resueltos": [],
		"consecuencias": [],
	}
	if raiz <= 0:
		return estado

	# Algunas vidas no traen ninguno, tal como pide #93. La ausencia también es
	# reproducible: no depende del orden en que otros sistemas hayan tirado.
	var tirada_vuelta := Azar.derivar(raiz, "vida", [vuelta, INDICE_PLAN])
	if tirada_vuelta % UNO_DE_CADA_SIN_IMPREVISTOS == 0:
		return estado

	var rng := Azar.generador(raiz, "vida", [vuelta, INDICE_PLAN])
	var cantidad := rng.randi_range(MIN_POR_VUELTA, MAX_POR_VUELTA)
	var candidatas: Array = CATALOGO.duplicate(true)
	var elegidas: Array[Dictionary] = []
	var fuertes := 0
	while elegidas.size() < cantidad and not candidatas.is_empty():
		var indice := rng.randi_range(0, candidatas.size() - 1)
		var evento: Dictionary = candidatas[indice]
		candidatas.remove_at(indice)
		if bool(evento.get("fuerte", false)) and fuertes >= MAX_FUERTES:
			continue
		if bool(evento.get("fuerte", false)):
			fuertes += 1
		elegidas.append({"id": String(evento["id"])})

	var dias: Array = DIAS_CANDIDATOS.duplicate()
	var dias_elegidos: Array[int] = []
	for _i in elegidas.size():
		var indice := rng.randi_range(0, dias.size() - 1)
		dias_elegidos.append(int(dias[indice]))
		dias.remove_at(indice)
	dias_elegidos.sort()

	for i in elegidas.size():
		elegidas[i]["dia"] = dias_elegidos[i]
	estado["plan"] = elegidas
	return estado


## Completa guardados antiguos y corrige el plan inicial creado antes de que
## Partida inyecte su semilla real en Jornada.
static func completar(jornada: Dictionary) -> Dictionary:
	var raiz := int(jornada.get("raiz", 0))
	var vuelta := int(jornada.get("vuelta", 1))
	var bruto = jornada.get(CLAVE_ESTADO, {})
	var estado: Dictionary = bruto if typeof(bruto) == TYPE_DICTIONARY else {}

	if (
		not estado.has("plan")
		or typeof(estado.get("plan", null)) != TYPE_ARRAY
		or int(estado.get("raiz_plan", -1)) != raiz
		or int(estado.get("vuelta_plan", -1)) != vuelta
	):
		estado = planificar(raiz, vuelta)
	else:
		estado["version"] = VERSION
		if typeof(estado.get("resueltos", null)) != TYPE_ARRAY:
			estado["resueltos"] = []
		if typeof(estado.get("consecuencias", null)) != TYPE_ARRAY:
			estado["consecuencias"] = []

	jornada[CLAVE_ESTADO] = estado
	return estado


static func pendiente(jornada: Dictionary) -> Dictionary:
	var estado := completar(jornada)
	var dia := int(jornada.get("dia", 1))
	var resueltos: Array = estado.get("resueltos", [])
	for programado in estado.get("plan", []):
		if typeof(programado) != TYPE_DICTIONARY or int(programado.get("dia", -1)) != dia:
			continue
		var id_evento := String(programado.get("id", ""))
		if id_evento.is_empty() or resueltos.has(id_evento):
			continue
		var evento := detalle(id_evento)
		if evento.is_empty():
			continue
		evento["dia"] = dia
		return evento
	return {}


## Marca el evento del día una sola vez. Si no pudo pagarse, la consecuencia
## queda como dato ambiental para #96; no se genera deuda ni saldo negativo.
static func resolver(jornada: Dictionary, pagado: bool) -> Dictionary:
	var evento := pendiente(jornada)
	if evento.is_empty():
		return {}

	var estado := completar(jornada)
	var id_evento := String(evento["id"])
	if not estado["resueltos"].has(id_evento):
		estado["resueltos"].append(id_evento)

	var consecuencia := ""
	if not pagado:
		consecuencia = String(evento.get("consecuencia", ""))
		if not consecuencia.is_empty() and not estado["consecuencias"].has(consecuencia):
			estado["consecuencias"].append(consecuencia)

	return {
		"id": id_evento,
		"nombre": String(evento.get("nombre", "")),
		"importe": int(evento.get("coste", 0)) if pagado else 0,
		"coste": int(evento.get("coste", 0)),
		"pagado": pagado,
		"consecuencia": consecuencia,
	}


static func consecuencias(jornada: Dictionary) -> Array[String]:
	var estado := completar(jornada)
	var salida: Array[String] = []
	for valor in estado.get("consecuencias", []):
		var consecuencia := String(valor)
		if not consecuencia.is_empty() and not salida.has(consecuencia):
			salida.append(consecuencia)
	return salida


static func detalle(id_evento: String) -> Dictionary:
	for evento in CATALOGO:
		if String(evento.get("id", "")) == id_evento:
			return evento.duplicate(true)
	return {}
