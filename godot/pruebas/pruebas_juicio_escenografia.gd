class_name PruebasJuicioEscenografia
extends RefCounted


## La escenografía del Juicio viste la arena sin tocar lo que el combate usa:
## mismas referencias, suelo ritual, archivo con cajones, foco cenital y halo
## del rival, y nada flotando con reducción de movimiento.
static func todo(comprobar: Callable) -> void:
	var anfitrion := Node3D.new()
	var refs := JuicioCombateArena3D.montar(
		anfitrion, {"id": "x"}, {}, "duat", {"id": "laberinto_lunar"}, 4.4, 4.0
	)
	for clave in ["jugador", "rival", "figura_jugador", "figura_rival", "aviso_ataque", "camara"]:
		comprobar.call("escenografía: conserva %s" % clave, refs.get(clave) != null, true)

	var suelo_ritual := false
	for malla in anfitrion.find_children("*", "MeshInstance3D", false, false):
		var material := (malla as MeshInstance3D).material_override
		if (
			material is ShaderMaterial
			and material.shader.resource_path == JuicioCombateEscenografia3D.SHADER_SUELO
		):
			suelo_ritual = true
	comprobar.call("escenografía: suelo con círculo ritual", suelo_ritual, true)

	var archivadores := anfitrion.find_children("Archivador*", "Node3D", false, false)
	comprobar.call("escenografía: ocho archivadores", archivadores.size(), 8)
	comprobar.call("escenografía: con cajones", archivadores[0].get_child_count() >= 9, true)

	var foco := anfitrion.get_node_or_null("FocoInterrogatorio") as SpotLight3D
	comprobar.call(
		"escenografía: foco cenital con sombra", foco != null and foco.shadow_enabled, true
	)
	var color := JuicioCombateEscenografia3D.color_mito("duat")
	var contraluz := anfitrion.get_node_or_null("ContraluzIzq") as OmniLight3D
	comprobar.call(
		"escenografía: contraluz del color del mito",
		contraluz != null and contraluz.light_color == color,
		true
	)

	var rival := refs["figura_rival"] as Node3D
	comprobar.call("escenografía: el rival es un cuerpo humano", rival.name, "RivalSinCara")
	var con_halo := 0
	var con_cara := 0
	for nodo in rival.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		for superficie in malla.mesh.get_surface_count():
			var material := malla.get_surface_override_material(superficie) as StandardMaterial3D
			if material == null:
				continue
			if material.next_pass is ShaderMaterial:
				con_halo += 1
			# Sin cara: ninguna superficie opaca conserva textura (solo el
			# recorte del pelo, que es negro igualmente).
			if material.albedo_color.v > 0.05:
				con_cara += 1
	comprobar.call("escenografía: el rival lleva halo", con_halo > 0, true)
	comprobar.call("escenografía: el rival sigue sin cara", con_cara, 0)
	comprobar.call(
		"escenografía: el jugador es su cuerpo", refs["figura_jugador"] is CuerpoJugador3D, true
	)
	anfitrion.free()

	var quieto := Node3D.new()
	JuicioCombateEscenografia3D.montar_aire(quieto, true)
	comprobar.call("escenografía: nada flota con reducción", quieto.get_child_count(), 0)
	JuicioCombateEscenografia3D.montar_aire(quieto, false)
	comprobar.call("escenografía: papeles y polvo", quieto.get_child_count(), 2)
	quieto.free()
