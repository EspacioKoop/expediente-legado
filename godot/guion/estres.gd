## Estado canónico de estrés/paranoia para #952.
##
## Vive dentro del Dictionary de Jornada para atravesar escenas y guardados sin
## crear un singleton ni otra fuente de verdad. No concede ni retira progreso,
## no expone el valor numérico ni una barra y no decide efectos visuales, sonoros
## o narrativos: los consumidores reciben únicamente un nivel normalizado 0..1.
## La presentación puede traducirlo a estados gráficos discretos sin revelar la cifra.
class_name Estres
extends RefCounted

const CAMPO_JORNADA := "estres_dinamico"
const CAMPO_SONIDOS_INQUIETANTES := "sonidos_inquietantes_registrados"
const VALOR_MAXIMO := 100.0
const INTENSIDAD_MAXIMA := 2.0

## Cambios base pequeños y simétricos. La intensidad permite a un consumidor
## autorado modular el mismo tipo de hecho sin inventar eventos nuevos.
const EVENTOS := {
	"documento_sensible": 12.0,
	"oscuridad": 4.0,
	"fallo_critico": 8.0,
	"sonido_inquietante": 3.0,
	"zona_segura": -6.0,
	"autocuidado": -12.0,
	"resolucion": -8.0,
}


## Aplica un hecho conocido y devuelve el cambio real después de saturar 0..100.
## Una intensidad inválida o un evento desconocido no modifica la jornada.
static func aplicar(jornada: Dictionary, evento: String, intensidad: float = 1.0) -> float:
	var clave := evento.strip_edges()
	if not EVENTOS.has(clave) or not is_finite(intensidad) or intensidad <= 0.0:
		return 0.0

	var estado := _asegurar(jornada)
	var anterior := float(estado["valor"])
	var delta := float(EVENTOS[clave]) * clampf(intensidad, 0.0, INTENSIDAD_MAXIMA)
	var nuevo := clampf(anterior + delta, 0.0, VALOR_MAXIMO)
	estado["valor"] = nuevo
	jornada[CAMPO_JORNADA] = estado
	return nuevo - anterior


## Registra un sonido diegético concreto una sola vez por Jornada. El id vive
## dentro del mismo estado canónico de estrés para sobrevivir guardado/recarga
## sin crear flags paralelos en la escena que lo reproduce.
static func registrar_sonido_inquietante(
	jornada: Dictionary, sonido_id: String, intensidad: float = 1.0
) -> bool:
	var id := sonido_id.strip_edges()
	if id.is_empty():
		return false

	var estado := _asegurar(jornada)
	var crudo: Variant = estado.get(CAMPO_SONIDOS_INQUIETANTES, [])
	var registrados: Array = crudo if crudo is Array else []
	if registrados.has(id):
		return false
	registrados.append(id)
	estado[CAMPO_SONIDOS_INQUIETANTES] = registrados
	jornada[CAMPO_JORNADA] = estado
	aplicar(jornada, "sonido_inquietante", intensidad)
	return true


## Valor interno 0..100. Se conserva para autoría y depuración, pero no debe
## mostrarse como cifra, barra o estadística directa al jugador.
static func valor(jornada: Dictionary) -> float:
	return float(_asegurar(jornada)["valor"])


## Contrato público para presentación: 0.0 relajado, 1.0 saturado.
static func nivel(jornada: Dictionary) -> float:
	return valor(jornada) / VALOR_MAXIMO


static func _asegurar(jornada: Dictionary) -> Dictionary:
	var crudo: Variant = jornada.get(CAMPO_JORNADA, {})
	if not crudo is Dictionary:
		jornada[CAMPO_JORNADA] = {"valor": 0.0}
		return jornada[CAMPO_JORNADA]

	var estado := crudo as Dictionary
	var valor_crudo: Variant = estado.get("valor", 0.0)
	if typeof(valor_crudo) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(valor_crudo)):
		estado["valor"] = 0.0
	else:
		estado["valor"] = clampf(float(valor_crudo), 0.0, VALOR_MAXIMO)
	jornada[CAMPO_JORNADA] = estado
	return estado
