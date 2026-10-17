## Adaptador del gestor literario opt-in de #1182, extraído de DiaApp (#1761).
##
## Un gate que instancia DiaApp fuera del SceneTree no registra autoloads;
## conservar el fallback vacío evita alterar la selección nocturna base.
extends RefCounted


static func vincular_partida(host: Node, estado: Dictionary) -> void:
	if not host.is_inside_tree():
		return
	var gestor := host.get_node_or_null("/root/GestorLiteratura")
	if gestor != null and gestor.has_method("vincular_a_estado"):
		gestor.call("vincular_a_estado", estado)


static func registro_para_sueno(host: Node) -> Dictionary:
	if not host.is_inside_tree():
		return {}
	var gestor := host.get_node_or_null("/root/GestorLiteratura")
	if gestor == null or not gestor.has_method("obtener_registro_literario"):
		return {}
	var registro = gestor.call("obtener_registro_literario")
	return registro if typeof(registro) == TYPE_DICTIONARY else {}
