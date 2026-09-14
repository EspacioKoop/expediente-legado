## Lote de oficina de valsekamerplant: sustituye visuales y conserva el recorrido.
class_name OficinaAssetsCc0
extends RefCounted

const MODELOS := {
	"desk": "desk1",
	"bookcaseClosed": "file_cabinet_large",
	"chairDesk": "office_chair_black",
	"computerScreen": "computer_monitor",
}


static func montar(mundo: Node3D) -> void:
	if mundo.has_meta("oficina_assets_cc0"):
		return
	mundo.set_meta("oficina_assets_cc0", true)
	for bulto in EspaciosCatalogo.OFICINA.bultos:
		var tipo: String = bulto.get("modelo", "")
		if not MODELOS.has(tipo):
			continue
		var modelo: String = MODELOS[tipo]
		if tipo == "desk" and bulto.pos.x > 0:
			modelo = "desk2"
		if tipo == "bookcaseClosed" and bulto.pos.z > 0:
			modelo = "file_cabinet_smaller"
		for cuerpo in mundo.get_children():
			if cuerpo is StaticBody3D and cuerpo.position.is_equal_approx(bulto.pos):
				AssetCc0.sustituir(cuerpo, "oficina_psx/" + modelo, bulto.tam)
	for nombre in ["MonitorPuestoC", "MonitorPuestoD"]:
		var monitor := mundo.get_node_or_null(nombre) as Node3D
		if monitor != null:
			AssetCc0.sustituir(monitor, "oficina_psx/computer_monitor", Vector3(0.48, 0.42, 0.38))
	for indice in range(1, 5):
		var puesto := mundo.get_node("PuestoUtileria%d" % indice) as Node3D
		var teclado := puesto.get_node("Teclado") as Node3D
		AssetCc0.sustituir(teclado, "oficina_psx/computer_keyboard", Vector3(0.58, 0.055, 0.22))
		var telefono := puesto.get_node("TelefonoBase") as Node3D
		if AssetCc0.sustituir(telefono, "oficina_psx/desk_phone", Vector3(0.42, 0.20, 0.30)):
			puesto.get_node("Auricular").hide()
		# Luz de mesa como prop mate: no suma luces al presupuesto del local.
		var lampara := Node3D.new()
		lampara.name = "LamparaCc0"
		lampara.position = Vector3(0.70, 1.0, -0.28)
		puesto.add_child(lampara)
		AssetCc0.sustituir(lampara, "oficina_psx/square_desklamp", Vector3(0.28, 0.45, 0.30))
