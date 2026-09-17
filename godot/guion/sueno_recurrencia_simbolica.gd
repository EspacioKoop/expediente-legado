## Recurrencia visual entre las salas consecutivas de una misma noche (#888).
##
## Recibe únicamente anomalías ya legitimadas por SuenoUtileria. Extrae de ellas
## un motivo ancla estable y lo repite como una firma baja de suelo, girada según
## el índice de escena. No conoce la topología ni los datos de composición, no
## crea colisión ni UI y no escribe estado: la misma noche solo parece recordar
## una forma que ya conocía.
class_name SuenoRecurrenciaSimbolica
extends RefCounted

const COLOR_FIRMA := Color(0.24, 0.23, 0.30)
const ALTURA := 0.055
const PRIORIDAD := ["ciclo-centro", "laberinto", "doble", "umbral"]


static func montar(
	mundo: Node3D,
	anomalias: Array,
	indice_escena: int,
	total_escenas: int,
	raiz_azar: int,
	dia: int,
) -> Node3D:
	if total_escenas < 2 or indice_escena < 0 or indice_escena >= total_escenas:
		return null
	var motivo := _motivo_ancla(anomalias)
	if motivo.is_empty():
		return null
	var ancla := _anomalia_del_motivo(anomalias, motivo)
	if ancla == null:
		return null

	var firma := Node3D.new()
	firma.name = "RecurrenciaSimbolica"
	firma.position = Vector3(ancla.position.x, 0.0, ancla.position.z)
	var semilla := Azar.derivar_texto(raiz_azar, "sueno", "recurrencia:%s" % motivo, [dia])
	var giro_base := float(posmod(semilla, 360))
	firma.rotation_degrees.y = giro_base + (360.0 * float(indice_escena) / float(total_escenas))
	firma.set_meta("motivo_simbolico", motivo)
	firma.set_meta("firma_simbolica", "retorno:%s" % motivo)
	firma.set_meta("indice_escena", indice_escena)
	firma.set_meta("total_escenas", total_escenas)
	mundo.add_child(firma)
	_montar_motivo(firma, motivo)
	return firma


static func _motivo_ancla(anomalias: Array) -> String:
	var presentes := []
	for valor in anomalias:
		if not valor is AnomaliaSueno3D:
			continue
		var motivo := String(valor.get_meta("motivo_simbolico", ""))
		if motivo in PRIORIDAD and not presentes.has(motivo):
			presentes.append(motivo)
	for motivo in PRIORIDAD:
		if presentes.has(motivo):
			return motivo
	return ""


static func _anomalia_del_motivo(anomalias: Array, motivo: String) -> AnomaliaSueno3D:
	for valor in anomalias:
		if not valor is AnomaliaSueno3D:
			continue
		var anomalia: AnomaliaSueno3D = valor
		if String(anomalia.get_meta("motivo_simbolico", "")) == motivo:
			return anomalia
	return null


static func _montar_motivo(raiz: Node3D, motivo: String) -> void:
	match motivo:
		"umbral":
			_caja(
				raiz,
				"HuellaIzquierda",
				Vector3(-0.72, ALTURA, 0.0),
				Vector3(0.12, ALTURA * 2.0, 1.45)
			)
			_caja(
				raiz, "HuellaDerecha", Vector3(0.72, ALTURA, 0.0), Vector3(0.12, ALTURA * 2.0, 1.45)
			)
			_caja(
				raiz, "HuellaDintel", Vector3(0.0, ALTURA, -0.68), Vector3(1.56, ALTURA * 2.0, 0.12)
			)
		"doble":
			_caja(raiz, "ParA1", Vector3(-0.62, ALTURA, -0.42), Vector3(0.18, ALTURA * 2.0, 0.82))
			_caja(raiz, "ParA2", Vector3(-0.62, ALTURA, 0.42), Vector3(0.18, ALTURA * 2.0, 0.82))
			_caja(raiz, "ParB1", Vector3(0.62, ALTURA, -0.42), Vector3(0.18, ALTURA * 2.0, 0.82))
			_caja(raiz, "ParB2", Vector3(0.62, ALTURA, 0.42), Vector3(0.18, ALTURA * 2.0, 0.82))
		"laberinto":
			_caja(raiz, "Tramo1", Vector3(-0.72, ALTURA, -0.54), Vector3(1.45, ALTURA * 2.0, 0.12))
			_caja(raiz, "Tramo2", Vector3(-0.05, ALTURA, -0.08), Vector3(0.12, ALTURA * 2.0, 0.92))
			_caja(raiz, "Tramo3", Vector3(0.42, ALTURA, 0.32), Vector3(0.94, ALTURA * 2.0, 0.12))
			_caja(raiz, "Tramo4", Vector3(0.84, ALTURA, 0.66), Vector3(0.12, ALTURA * 2.0, 0.68))
			_caja(raiz, "Tramo5", Vector3(0.48, ALTURA, 0.94), Vector3(0.72, ALTURA * 2.0, 0.12))
		"ciclo-centro":
			for i in range(6):
				var angulo := TAU * float(i) / 6.0
				var marca := _caja(
					raiz,
					"Retorno%02d" % (i + 1),
					Vector3(cos(angulo) * 0.86, ALTURA, sin(angulo) * 0.86),
					Vector3(0.16, ALTURA * 2.0, 0.48),
				)
				marca.rotation_degrees.y = -rad_to_deg(angulo)


static func _caja(raiz: Node3D, nombre: String, pos: Vector3, tam: Vector3) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	malla.position = pos
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.material_override = _material()
	raiz.add_child(malla)
	return malla


static func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_FIRMA
	material.roughness = 1.0
	return material
