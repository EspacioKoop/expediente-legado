extends Node2D

# nodo que sirve como punto de partida y conexión para las habitaciones seleccionadas
# garantiza que el corredor nunca se deforme y permite abandonar el hotel en cualquier momento

# Signal emitted when the player chooses to leave the hotel
signal hotel_exited

# Array of NodePaths to the selected rooms. The rooms must connect to this hub when added
@export var rooms: Array[NodePath] = []

# If true, corridors connected to the hub will not deform (static geometry)
@export var corridor_stable: bool = true


func _ready() -> void:
	# Conecta cada habitación a esta instancia
	for room_path in rooms:
		var room = get_node_or_null(room_path)
		if room == null:
			print("HubHotel: ruta de habitación no válida ", room_path)
			continue
		# Si la habitación tiene un método de conexión, lo invoquemos
		if room.has_method("connect_to_hub"):
			room.connect_to_hub(self)
		# Si la habitación expone un nodo de corredor, fijamos su estado
		if corridor_stable and room.has_method("set_static"):
			room.set_static(true)  # evita deformaciones


# Llamada pública para abandonar el hotel
func exit_hotel() -> void:
	emit_signal("hotel_exited")
