# Rebote Postal 98

Segundo arcade original opcional de la consola de sobremesa (#2187, #95).
Desde casa: usar consola → **Rebote Postal 98** en el selector de Turno Serpiente.
**Volver a consola** regresa al mismo selector, donde siguen disponibles Snake
y **Otros cartuchos**. No requiere ROM ni cambia dinero, pistas o acciones.
Escena standalone para F6: `res://escenas/rebote_postal_98.tscn`.

## Partida

Pala y pelota para despachar todos los paquetes. Tres rutas con patrones
distintos (18, 20 y 24 paquetes), tres pelotas compartidas por toda la partida,
100 puntos por entrega y 6200 al completar los tres niveles. Puntuación y
pelotas restantes se conservan entre niveles; los paquetes ya entregados se
conservan al perder una pelota. No hay temporizador ni recompensas de campaña.

Cada pelota espera un **Sacar** explícito. El lugar donde la pelota toca la pala
dirige el rebote; el centro conserva una pequeña componente lateral para evitar
un bucle vertical. La velocidad aumenta en cada ruta. **Ritmo tranquilo** reduce
velocidad un 25 % y se puede elegir antes de cada saque.

Controles de caminar izquierda/derecha para la pala (teclado, cruceta y stick
remapeados por `PreferenciasSiga`). También hay botones mantenidos en pantalla
y arrastre con ratón pulsado o dedo sobre el tablero. Durante el vuelo,
**interactuar** pausa; en pausa y resultados se usa la navegación normal del
menú para continuar, reintentar o volver a consola. **Cancelar** sale al mundo.

El mundo se pausa mientras está abierto el arcade. Salir, cambiar al selector
o retirar el nodo restaura pausa y ratón anteriores. Perder foco pausa el vuelo
y suelta controles táctiles. Abrir/reintentar no escribe datos persistentes.

## Presentación y verificación

Paquetes, cinta de embalaje, pala y pelota se dibujan por código propio. Audio
chip sintetizado en memoria, sin grabaciones; utiliza el bus común `Efectos`.
Texto ES/EN en `godot/datos/rebote_postal_textos.json`. No hay flashes,
movimiento de cámara, assets externos ni red.

Núcleo determinista a 120 Hz, avance por frame limitado a 100 ms y velocidad
máxima de 450 px/s. El paso máximo de 3,75 px queda por debajo del radio de
pelota y del grosor de los colliders, para evitar atravesarlos entre ticks.

`python3 -m unittest scripts.test_rebote_postal_2187` ejecuta reglas y UI reales
en un proyecto aislado sin extensión GB/GBC. El piloto de prueba mueve la pala
con las mismas reglas y completa los tres niveles sin eliminar bloques por API.
Se comprueban rebotes, puntuación, pérdidas, pausa, agrupación de pasos,
revancha, selector y restauración del host. La regresión del Snake se mantiene.

Gate humano pendiente: flujo desde casa en Forward+, tacto de los ángulos,
legibilidad 1080p, mando físico/remapeado, modo tranquilo, retorno al selector
y apertura de las ROMs existentes. Las pruebas no acreditan ese pase humano.
