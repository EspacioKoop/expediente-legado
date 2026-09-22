class_name PruebasJuicioFeedback
extends RefCounted


static func todo(comprobar: Callable) -> void:
	var base := JuicioCombateFeedback3D.material(Color(0.2, 0.3, 0.4))
	comprobar.call("feedback: material conserva color", base.albedo_color, Color(0.2, 0.3, 0.4))
	comprobar.call(
		"feedback: material conserva rugosidad", is_equal_approx(base.roughness, 0.9), true
	)
	comprobar.call("feedback: material base no emite", base.emission_enabled, false)

	var emisivo := JuicioCombateFeedback3D.material(Color(0.8, 0.4, 0.2), true)
	comprobar.call("feedback: material emisivo se activa", emisivo.emission_enabled, true)
	comprobar.call("feedback: emisión conserva color", emisivo.emission, Color(0.8, 0.4, 0.2))
	(
		comprobar
		. call(
			"feedback: emisión conserva energía",
			is_equal_approx(emisivo.emission_energy_multiplier, 0.8),
			true,
		)
	)
