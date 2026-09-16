## Materialización 3D de las rutinas domésticas opcionales de #675.
##
## Reutiliza exactamente los anclajes físicos ya montados por #133: ventana,
## nevera, fregadero y sofá. No crea una segunda casa ni decide necesidades.
## El estado inicial llega por CasaEstadoAmbiental (#96) y cada interacción
## escribe únicamente el booleano correspondiente en CasaRutinas.
class_name CasaRutinas3D
extends RefCounted

const NOMBRE_RAIZ := "RutinasCasa"
const TOTAL_MICROINTERACCIONES := 5


static func montar(
	raiz: Node3D,
	jornada: Dictionary,
	estado_ambiental: Dictionary,
	reduccion_movimiento: bool = false,
) -> Node3D:
	var anterior := raiz.get_node_or_null(NOMBRE_RAIZ)
	if anterior != null:
		raiz.remove_child(anterior)
		anterior.queue_free()

	var rutinas := Node3D.new()
	rutinas.name = NOMBRE_RAIZ
	rutinas.set_meta("microinteracciones", TOTAL_MICROINTERACCIONES)
	raiz.add_child(rutinas)

	var estado = estado_ambiental.get("rutinas_casa", {})
	if typeof(estado) != TYPE_DICTIONARY:
		estado = CasaRutinas.estado(jornada)

	var ventana := raiz.find_child("VentanaCasa", true, false) as Node3D
	var nevera := raiz.find_child("NeveraCasa", true, false) as Node3D
	var fregadero := raiz.find_child("FregaderoCasa", true, false) as Node3D
	var sofa := raiz.find_child("SofaCasa", true, false) as Node3D

	if ventana != null:
		_montar_persiana(ventana, jornada, estado, reduccion_movimiento)
		_montar_ventana(ventana, jornada, estado, reduccion_movimiento)
	if nevera != null:
		_montar_nevera(nevera, jornada, estado, reduccion_movimiento)
	if fregadero != null:
		_montar_platos(fregadero, jornada, estado, reduccion_movimiento)
	if sofa != null and ventana != null:
		_montar_toalla(raiz, sofa, ventana, jornada, estado, reduccion_movimiento)
	return rutinas


static func _montar_persiana(
	ventana: Node3D,
	jornada: Dictionary,
	estado: Dictionary,
	reduccion: bool,
) -> void:
	var visual := Node3D.new()
	visual.name = "PersianaVisualRutina"
	ventana.add_child(visual)
	_caja(visual, Vector3.ZERO, Vector3(1.72, 0.96, 0.045), Color(0.42, 0.34, 0.27))
	for y in [-0.36, -0.18, 0.0, 0.18, 0.36]:
		_caja(visual, Vector3(0, y, -0.026), Vector3(1.70, 0.025, 0.018), Color(0.28, 0.23, 0.19))

	var accion := CasaRutinaInteractiva3D.new()
	accion.name = "PersianaCasaInteractuable"
	accion.position = Vector3(-0.74, -0.46, 0.18)
	ventana.add_child(accion)
	(
		accion
		. configurar(
			jornada,
			CasaRutinas.PERSIANA_ABIERTA,
			visual,
			Vector3(0, 0.0, 0.10),
			Vector3(0, 0.78, 0.10),
			Vector3.ZERO,
			Vector3.ZERO,
			Vector3(0.30, 0.32, 0.30),
			"Abrir persiana",
			"Cerrar persiana",
			"abrir",
			"cerrar",
			bool(estado.get(CasaRutinas.PERSIANA_ABIERTA, false)),
			Interactuable3D.Verbo.ABRIR,
			Interactuable3D.Verbo.CERRAR,
			reduccion,
		)
	)


static func _montar_ventana(
	ventana: Node3D,
	jornada: Dictionary,
	estado: Dictionary,
	reduccion: bool,
) -> void:
	var hoja := Node3D.new()
	hoja.name = "HojaVentanaRutina"
	ventana.add_child(hoja)
	_caja(hoja, Vector3(-0.42, 0, 0), Vector3(0.82, 1.02, 0.035), Color(0.12, 0.16, 0.20))
	_caja(hoja, Vector3(-0.42, 0.50, 0), Vector3(0.86, 0.055, 0.06), Color(0.31, 0.27, 0.23))
	_caja(hoja, Vector3(-0.42, -0.50, 0), Vector3(0.86, 0.055, 0.06), Color(0.31, 0.27, 0.23))
	_caja(hoja, Vector3(-0.82, 0, 0), Vector3(0.055, 1.05, 0.06), Color(0.31, 0.27, 0.23))
	_caja(hoja, Vector3(-0.02, 0, 0), Vector3(0.055, 1.05, 0.06), Color(0.31, 0.27, 0.23))

	var accion := CasaRutinaInteractiva3D.new()
	accion.name = "VentanaCasaInteractuable"
	accion.position = Vector3(0.70, -0.05, 0.18)
	ventana.add_child(accion)
	(
		accion
		. configurar(
			jornada,
			CasaRutinas.VENTANA_ABIERTA,
			hoja,
			Vector3(0.88, 0, 0.10),
			Vector3(0.88, 0, 0.10),
			Vector3.ZERO,
			Vector3(0, -58.0, 0),
			Vector3(0.28, 0.34, 0.30),
			"Abrir ventana",
			"Cerrar ventana",
			"abrir",
			"cerrar",
			bool(estado.get(CasaRutinas.VENTANA_ABIERTA, false)),
			Interactuable3D.Verbo.ABRIR,
			Interactuable3D.Verbo.CERRAR,
			reduccion,
		)
	)


static func _montar_nevera(
	nevera: Node3D,
	jornada: Dictionary,
	estado: Dictionary,
	reduccion: bool,
) -> void:
	var puerta := Node3D.new()
	puerta.name = "PuertaNeveraRutina"
	nevera.add_child(puerta)
	_caja(puerta, Vector3(0, 0, -0.33), Vector3(0.045, 1.70, 0.66), Color(0.61, 0.60, 0.56))
	_caja(
		puerta, Vector3(-0.035, 0.22, -0.54), Vector3(0.055, 0.48, 0.055), Color(0.35, 0.36, 0.35)
	)

	var accion := CasaRutinaInteractiva3D.new()
	accion.name = "NeveraCasaInteractuable"
	accion.position = Vector3(-0.50, 0.92, 0)
	nevera.add_child(accion)
	(
		accion
		. configurar(
			jornada,
			CasaRutinas.NEVERA_ABIERTA,
			puerta,
			Vector3(-0.39, 0.92, 0.34),
			Vector3(-0.39, 0.92, 0.34),
			Vector3.ZERO,
			Vector3(0, 68.0, 0),
			Vector3(0.30, 1.30, 0.56),
			"Abrir nevera",
			"Cerrar nevera",
			"abrir",
			"cerrar",
			bool(estado.get(CasaRutinas.NEVERA_ABIERTA, false)),
			Interactuable3D.Verbo.ABRIR,
			Interactuable3D.Verbo.CERRAR,
			reduccion,
		)
	)


static func _montar_platos(
	fregadero: Node3D,
	jornada: Dictionary,
	estado: Dictionary,
	reduccion: bool,
) -> void:
	var accion := CasaRutinaInteractiva3D.new()
	accion.name = "PlatosCasaInteractuables"
	fregadero.add_child(accion)
	for i in range(3):
		_cilindro(
			accion,
			Vector3(0, float(i) * 0.025, 0),
			0.13,
			0.018,
			Color(0.63, 0.60, 0.50),
		)
	(
		accion
		. configurar(
			jornada,
			CasaRutinas.PLATOS_RECOGIDOS,
			accion,
			Vector3(0, 0.12, 0.05),
			Vector3(0, 0.18, -0.52),
			Vector3.ZERO,
			Vector3.ZERO,
			Vector3(0.38, 0.24, 0.38),
			"Fregar y recoger platos",
			"Sacar platos",
			"coger",
			"coger",
			bool(estado.get(CasaRutinas.PLATOS_RECOGIDOS, false)),
			Interactuable3D.Verbo.USAR,
			Interactuable3D.Verbo.USAR,
			reduccion,
		)
	)


static func _montar_toalla(
	raiz: Node3D,
	sofa: Node3D,
	ventana: Node3D,
	jornada: Dictionary,
	estado: Dictionary,
	reduccion: bool,
) -> void:
	var accion := CasaRutinaInteractiva3D.new()
	accion.name = "ToallaCasaInteractuable"
	raiz.add_child(accion)
	_caja(accion, Vector3.ZERO, Vector3(0.46, 0.05, 0.62), Color(0.48, 0.42, 0.37))
	var pos_sofa := raiz.to_local(sofa.to_global(Vector3(0.54, 0.72, 0.10)))
	var pos_ventana := raiz.to_local(ventana.to_global(Vector3(-0.60, -0.24, 0.22)))
	(
		accion
		. configurar(
			jornada,
			CasaRutinas.TOALLA_TENDIDA,
			accion,
			pos_sofa,
			pos_ventana,
			Vector3(0, 0, 8.0),
			Vector3(0, 0, 90.0),
			Vector3(0.50, 0.18, 0.66),
			"Tender toalla",
			"Recoger toalla",
			"coger",
			"coger",
			bool(estado.get(CasaRutinas.TOALLA_TENDIDA, false)),
			Interactuable3D.Verbo.USAR,
			Interactuable3D.Verbo.COGER,
			reduccion,
		)
	)


static func _caja(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)


static func _cilindro(
	raiz: Node3D,
	pos: Vector3,
	radio: float,
	alto: float,
	color: Color,
) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	malla.mesh = cilindro
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)
