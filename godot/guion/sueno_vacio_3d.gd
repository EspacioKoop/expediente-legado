## Presentación del sueño sin lecturas (#786).
##
## La ausencia sigue siendo ausencia: no aparecen documentos, personas ni
## frases. La identidad procede de una oficina recordada solo como estructura:
## niebla, fluorescentes desalineados, huellas de puestos vacíos y zumbido.
class_name SuenoVacio3D
extends Node3D

const DENSIDAD_NIEBLA := 0.055
const COLOR_NIEBLA := Color(0.11, 0.13, 0.135)
const COLOR_MURO := Color(0.055, 0.06, 0.065)
const COLOR_HUELLA := Color(0.19, 0.21, 0.21, 0.26)
const COLOR_PANEL := Color(0.34, 0.37, 0.36, 0.16)
const COLOR_FLUORESCENTE := Color(0.70, 0.78, 0.72)

var _audio: AudioStreamPlayer


static func montar(mundo: Node3D, espacio: Dictionary) -> Node3D:
	if mundo == null or String(espacio.get("identidad_onirica", "")) != SuenoVacio.ID:
		return null
	var presentacion := SuenoVacio3D.new()
	presentacion.name = "PresentacionSuenoVacio786"
	mundo.add_child(presentacion)
	presentacion._configurar()
	return presentacion


func _configurar() -> void:
	_configurar_niebla()
	_apagar_greybox()
	_montar_huellas_de_puestos()
	_montar_paneles_fantasma()
	_montar_ecos_modelados()
	_montar_fluorescentes()
	_montar_audio()


func _configurar_niebla() -> void:
	var mundo := get_parent()
	if mundo == null:
		return
	for hijo in mundo.get_children():
		if not hijo is WorldEnvironment:
			continue
		var world_environment := hijo as WorldEnvironment
		if world_environment.environment == null:
			continue
		var entorno := world_environment.environment
		entorno.fog_enabled = true
		entorno.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		entorno.fog_density = DENSIDAD_NIEBLA
		entorno.fog_light_color = COLOR_NIEBLA
		entorno.fog_light_energy = 1.05
		entorno.fog_sky_affect = 0.0
		entorno.background_color = Color(0.025, 0.03, 0.032)
		return


func _apagar_greybox() -> void:
	var mundo := get_parent()
	if mundo == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(COLOR_MURO, 0.72)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	for hijo in mundo.get_children():
		if not hijo is StaticBody3D:
			continue
		var visual := hijo.get_node_or_null("Malla")
		if visual is MeshInstance3D:
			(visual as MeshInstance3D).material_override = material


func _montar_huellas_de_puestos() -> void:
	var grupo := Node3D.new()
	grupo.name = "HuellasPuestosVacios"
	add_child(grupo)
	var datos := [
		[Vector3(-5.2, 0.035, -3.0), Vector2(2.9, 1.15), -18.0],
		[Vector3(-1.2, 0.036, 1.8), Vector2(3.2, 1.05), 11.0],
		[Vector3(3.7, 0.037, -1.4), Vector2(2.7, 1.2), -7.0],
		[Vector3(6.1, 0.038, 4.2), Vector2(3.0, 1.1), 24.0],
	]
	var material := _material_transparente(COLOR_HUELLA, false)
	for i in datos.size():
		var dato: Array = datos[i]
		var marca := MeshInstance3D.new()
		marca.name = "PuestoVacio%02d" % (i + 1)
		var forma := QuadMesh.new()
		forma.size = Vector2(dato[1])
		marca.mesh = forma
		marca.material_override = material
		marca.position = Vector3(dato[0])
		marca.rotation_degrees = Vector3(-90.0, float(dato[2]), 0.0)
		grupo.add_child(marca)


func _montar_paneles_fantasma() -> void:
	var grupo := Node3D.new()
	grupo.name = "EcosTabiquesOficina"
	add_child(grupo)
	var datos := [
		[Vector3(-4.6, 1.05, 1.0), Vector2(3.7, 1.75), -21.0],
		[Vector3(-0.7, 1.20, -3.8), Vector2(4.1, 2.0), 16.0],
		[Vector3(3.2, 0.95, 2.3), Vector2(3.4, 1.6), -34.0],
		[Vector3(6.5, 1.15, -1.2), Vector2(4.0, 1.9), 27.0],
	]
	var material := _material_transparente(COLOR_PANEL, true)
	for i in datos.size():
		var dato: Array = datos[i]
		var panel := MeshInstance3D.new()
		panel.name = "EcoPanel%02d" % (i + 1)
		var forma := QuadMesh.new()
		forma.size = Vector2(dato[1])
		panel.mesh = forma
		panel.material_override = material
		panel.position = Vector3(dato[0])
		panel.rotation_degrees.y = float(dato[2])
		grupo.add_child(panel)


func _montar_ecos_modelados() -> void:
	var grupo := Node3D.new()
	grupo.name = "EcosMobiliarioOficina"
	add_child(grupo)
	var puestos := [
		[Vector3(-4.4, 0.0, -1.8), 18.0, Vector3(1.0, 1.18, 0.86)],
		[Vector3(1.1, 0.0, 2.4), -31.0, Vector3(0.88, 1.32, 1.0)],
		[Vector3(5.2, 0.0, -2.6), 41.0, Vector3(1.08, 0.92, 0.82)],
	]
	for i in puestos.size():
		var dato: Array = puestos[i]
		var puesto := Node3D.new()
		puesto.name = "EcoPuestoModelado%02d" % (i + 1)
		puesto.position = Vector3(dato[0])
		puesto.rotation_degrees.y = float(dato[1])
		puesto.scale = Vector3(dato[2])
		grupo.add_child(puesto)

		var escritorio := Node3D.new()
		escritorio.name = "EscritorioEco"
		puesto.add_child(escritorio)
		AssetCc0.sustituir(
			escritorio,
			"oficina_psx/desk1" if i != 1 else "oficina_psx/desk2",
			Vector3(2.5, 0.95, 1.25),
		)

		var silla := Node3D.new()
		silla.name = "SillaEco"
		silla.position = Vector3(0.15, 0.0, 1.12)
		silla.rotation_degrees.y = 180.0
		puesto.add_child(silla)
		AssetCc0.sustituir(silla, "oficina_psx/office_chair_black", Vector3(0.72, 1.0, 0.72))

		var monitor := Node3D.new()
		monitor.name = "MonitorEco"
		monitor.position = Vector3(-0.35, 0.92, -0.10)
		monitor.rotation_degrees.y = -8.0 + float(i) * 9.0
		puesto.add_child(monitor)
		AssetCc0.sustituir(monitor, "oficina_psx/computer_monitor", Vector3(0.55, 0.46, 0.42))

	var archivador := Node3D.new()
	archivador.name = "ArchivadorEco"
	archivador.position = Vector3(-0.8, 0.0, -5.8)
	archivador.rotation_degrees.y = 23.0
	archivador.scale = Vector3(0.82, 1.55, 0.78)
	grupo.add_child(archivador)
	AssetCc0.sustituir(
		archivador, "oficina_psx/file_cabinet_large", Vector3(1.0, 2.2, 0.72)
	)


func _montar_fluorescentes() -> void:
	var grupo := Node3D.new()
	grupo.name = "FluorescentesDesalineados"
	add_child(grupo)
	var posiciones := [
		Vector3(-5.4, 2.45, -2.8),
		Vector3(-1.8, 2.58, 0.4),
		Vector3(1.9, 2.38, -2.0),
		Vector3(5.1, 2.62, 1.7),
	]
	for i in posiciones.size():
		var panel := MeshInstance3D.new()
		panel.name = "FluorescenteEco%02d" % (i + 1)
		var forma := QuadMesh.new()
		forma.size = Vector2(2.2, 0.16)
		panel.mesh = forma
		var material := StandardMaterial3D.new()
		material.albedo_color = COLOR_FLUORESCENTE
		material.emission_enabled = true
		material.emission = COLOR_FLUORESCENTE
		material.emission_energy_multiplier = 2.1
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		panel.material_override = material
		panel.position = posiciones[i]
		panel.rotation_degrees = Vector3(-90.0, -13.0 + 9.0 * float(i), 0.0)
		grupo.add_child(panel)

		var luz := OmniLight3D.new()
		luz.name = "HaloFluorescente%02d" % (i + 1)
		luz.light_color = COLOR_FLUORESCENTE
		luz.light_energy = 0.95
		luz.omni_range = 6.2
		luz.shadow_enabled = false
		luz.position = Vector3(0.0, -0.08, 0.0)
		panel.add_child(luz)


func _montar_audio() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.name = "ZumbidoOficinaVacia"
	_audio.stream = SuenoVacioAudio.ambiente_oficina_vacia()
	_audio.volume_db = -24.0
	add_child(_audio)
	_audio.play()


func _material_transparente(color: Color, sin_luz: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	if sin_luz:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
