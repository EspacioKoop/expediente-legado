## Presentacion 3D ligera de vecinos y portal (#673).
##
## Consume exclusivamente VecinosEdificio: no inventa calendario, afinidad,
## economia ni progreso. La calle sigue perteneciendo a Jornada/trayecto.
class_name VecinosEdificio3D
extends RefCounted

const NOMBRE_RAIZ := "VecinosEdificio3D"

const COLOR_FELPUDO := Color(0.24, 0.16, 0.10)
const COLOR_FELPUDO_HUMEDO := Color(0.16, 0.13, 0.11)
const COLOR_TABLON := Color(0.33, 0.21, 0.12)
const COLOR_PAPEL := Color(0.78, 0.73, 0.60)
const COLOR_LUZ := Color(0.86, 0.74, 0.46)
const COLOR_LUZ_DEBIL := Color(0.43, 0.37, 0.28)
const COLOR_PUERTA := Color(0.29, 0.22, 0.16)
const COLOR_PAQUETE := Color(0.47, 0.32, 0.18)


static func montar(
	mundo: Node3D, jornada: Dictionary, reduccion_movimiento: bool = false
) -> Node3D:
	if mundo == null:
		return null

	var anterior := mundo.get_node_or_null(NOMBRE_RAIZ)
	if anterior != null:
		anterior.free()

	var raiz := Node3D.new()
	raiz.name = NOMBRE_RAIZ
	mundo.add_child(raiz)

	var ambiente := VecinosEdificio.estado_portal(jornada, reduccion_movimiento)
	raiz.set_meta("estado_portal", ambiente.duplicate(true))
	_montar_portal(raiz, ambiente)

	var ids: Array[String] = []
	for presencia in VecinosEdificio.presencias(jornada, reduccion_movimiento):
		ids.append(String(presencia.get("id", "")))
		_montar_presencia(raiz, presencia)
	raiz.set_meta("presencias_ids", ids)

	var interacciones := VecinosEdificio.interacciones(jornada)
	for interaccion in interacciones:
		if String(interaccion.get("id", "")) == VecinosEdificio.ID_PAQUETE_EQUIVOCADO:
			_montar_paquete_interactivo(raiz, interaccion)

	if _paquete_resuelto_hoy(jornada):
		_montar_paquete_colocado(raiz)

	return raiz


static func marcar_paquete_resuelto(raiz: Node3D) -> void:
	if raiz == null:
		return
	var paquete := raiz.get_node_or_null("PaqueteEquivocado")
	if paquete != null:
		paquete.free()
	_montar_paquete_colocado(raiz)


static func _montar_portal(raiz: Node3D, ambiente: Dictionary) -> void:
	var estado_felpudo := String(ambiente.get("felpudo", "centrado"))
	var color_felpudo := (
		COLOR_FELPUDO_HUMEDO if estado_felpudo == "humedo" else COLOR_FELPUDO
	)
	var felpudo := _caja(
		raiz,
		"FelpudoPortal",
		Vector3(1.15, 0.035, 0.55),
		Vector3(0.0, 0.08, 15.05),
		color_felpudo
	)
	felpudo.set_meta("estado", estado_felpudo)
	if estado_felpudo == "torcido":
		felpudo.rotation.y = deg_to_rad(-7.0)

	var tablon := _caja(
		raiz,
		"TablonComunidad",
		Vector3(1.05, 0.72, 0.06),
		Vector3(-1.58, 1.58, 15.42),
		COLOR_TABLON
	)
	tablon.set_meta("aviso_id", String(ambiente.get("tablon_id", "")))
	for indice in range(3):
		_caja(
			tablon,
			"Papel%d" % indice,
			Vector3(0.23, 0.16, 0.02),
			Vector3(-0.27 + float(indice) * 0.27, 0.06 - float(indice % 2) * 0.12, -0.045),
			COLOR_PAPEL
		)

	var estado_luz := String(ambiente.get("luz_portal", "estable"))
	var plafon := _caja(
		raiz,
		"LuzPortal",
		Vector3(0.55, 0.12, 0.22),
		Vector3(0.0, 2.55, 15.16),
		COLOR_LUZ_DEBIL if estado_luz == "parpadeo" else COLOR_LUZ
	)
	plafon.set_meta("estado", estado_luz)

	var estado_puerta := String(ambiente.get("puerta_2a", "cerrada"))
	var puerta := _caja(
		raiz,
		"Puerta2A",
		Vector3(0.88, 1.85, 0.10),
		Vector3(-2.05, 1.02, 15.48),
		COLOR_PUERTA
	)
	puerta.set_meta("estado", estado_puerta)
	if estado_puerta == "entornada":
		puerta.rotation.y = deg_to_rad(-9.0)


static func _montar_presencia(raiz: Node3D, presencia: Dictionary) -> void:
	var id := String(presencia.get("id", ""))
	var nodo: Node3D
	match id:
		"manuela_3b":
			nodo = _figura(
				raiz,
				"Manuela3B",
				Vector3(-0.72, 0.08, 14.35),
				Color(0.42, 0.31, 0.24),
				Color(0.57, 0.48, 0.35)
			)
		"televisor_2a":
			var estado_tv := String(presencia.get("estado", ""))
			nodo = Node3D.new()
			nodo.name = "PresenciaTelevisor2A"
			raiz.add_child(nodo)
			_caja(
				nodo,
				"BrilloVentana",
				Vector3(0.10, 0.62, 0.92),
				Vector3(5.43, 1.55, 6.20),
				Color(0.31, 0.40, 0.29)
				if estado_tv == "partido_lejano"
				else Color(0.42, 0.34, 0.24)
			)
		"pasos_4a":
			nodo = Node3D.new()
			nodo.name = "PresenciaPasos4A"
			raiz.add_child(nodo)
			_caja(
				nodo,
				"HuellaA",
				Vector3(0.16, 0.025, 0.34),
				Vector3(0.32, 0.055, 14.15),
				Color(0.17, 0.16, 0.15)
			)
			_caja(
				nodo,
				"HuellaB",
				Vector3(0.16, 0.025, 0.34),
				Vector3(-0.02, 0.055, 14.48),
				Color(0.17, 0.16, 0.15)
			)
		"repartidor_confundido":
			nodo = _figura(
				raiz,
				"RepartidorConfundido",
				Vector3(0.95, 0.08, 14.28),
				Color(0.18, 0.24, 0.31),
				Color(0.48, 0.44, 0.34)
			)
		_:
			nodo = Node3D.new()
			nodo.name = "Presencia_" + id
			raiz.add_child(nodo)

	nodo.set_meta("presencia_id", id)
	nodo.set_meta("estado", String(presencia.get("estado", "")))
	nodo.set_meta("modo", String(presencia.get("modo", "")))
	nodo.set_meta("movimiento", String(presencia.get("movimiento", "")))
	nodo.set_meta("sonido_id", String(presencia.get("sonido_id", "")))


static func _montar_paquete_interactivo(raiz: Node3D, interaccion: Dictionary) -> void:
	if raiz.get_node_or_null("PaqueteEquivocado") != null:
		return
	var paquete := Interactuable3D.new()
	paquete.name = "PaqueteEquivocado"
	paquete.verbo = Interactuable3D.Verbo.COGER
	paquete.nombre_objeto = "paquete del 4º A"
	paquete.position = Vector3(1.08, 0.05, 14.82)
	paquete.set_meta("interaccion_id", String(interaccion.get("id", "")))
	paquete.set_meta("destino", String(interaccion.get("destino", "")))
	paquete.set_meta("correo_postal", String(interaccion.get("correo_postal", "")))
	raiz.add_child(paquete)

	_caja(
		paquete,
		"Caja",
		Vector3(0.46, 0.28, 0.34),
		Vector3(0.0, 0.16, 0.0),
		COLOR_PAQUETE
	)
	var colision := CollisionShape3D.new()
	colision.name = "VolumenInteraccion"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.64, 0.56, 0.62)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.22, 0.0)
	paquete.add_child(colision)


static func _montar_paquete_colocado(raiz: Node3D) -> void:
	if raiz.get_node_or_null("Paquete4AColocado") != null:
		return
	var colocado := _caja(
		raiz,
		"Paquete4AColocado",
		Vector3(0.30, 0.18, 0.24),
		Vector3(1.55, 0.62, 15.18),
		COLOR_PAQUETE
	)
	colocado.set_meta("destino", "buzon_4a")


static func _figura(
	raiz: Node3D, nombre: String, posicion: Vector3, ropa: Color, detalle: Color
) -> Node3D:
	var figura := Node3D.new()
	figura.name = nombre
	figura.position = posicion
	raiz.add_child(figura)
	_caja(
		figura,
		"Cuerpo",
		Vector3(0.42, 1.12, 0.30),
		Vector3(0.0, 0.78, 0.0),
		ropa
	)
	var cabeza := MeshInstance3D.new()
	cabeza.name = "Cabeza"
	var esfera := SphereMesh.new()
	esfera.radius = 0.18
	esfera.height = 0.36
	cabeza.mesh = esfera
	cabeza.position = Vector3(0.0, 1.48, 0.0)
	cabeza.material_override = _material(detalle)
	figura.add_child(cabeza)
	return figura


static func _caja(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = posicion
	malla.material_override = _material(color)
	padre.add_child(malla)
	return malla


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material


static func _paquete_resuelto_hoy(jornada: Dictionary) -> bool:
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var clave := "%d:%s" % [dia, VecinosEdificio.ID_PAQUETE_EQUIVOCADO]
	var bruto = jornada.get(VecinosEdificio.CLAVE_RESUELTOS, [])
	if typeof(bruto) != TYPE_ARRAY:
		return false
	return bruto.has(clave)
