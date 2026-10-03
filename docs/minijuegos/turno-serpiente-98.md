# Turno Serpiente 98

Arcade original opcional de la consola de sobremesa de casa (#2181, #95).
Usar la consola abre el arcade; **Otros cartuchos** mantiene el acceso al
catálogo y al emulador existentes. No hace falta instalar una ROM para jugar.

También puede abrirse `res://escenas/turno_serpiente_98.tscn` con F6.

## Partida completa

Recoger seis sellos amarillos por turno sin tocar bordes, archivadores ni cola.
Tres tableros de 20 × 14: despejado, archivadores centrales y pasillos cruzados.
Cada sello alarga la cola y suma 100 × número de turno. Victoria: 18 sellos,
3600 puntos. Entre turnos se conserva puntuación y se reinicia la cola.
No hay límite de tiempo, vidas de campaña ni penalización por abandonar.

Movimiento: acciones de caminar remapeables de `PreferenciasSiga` (teclado,
cruceta o stick). Durante la partida, **interactuar** pausa/reanuda y
**cancelar** sale. En menús se usa el foco normal de Godot. Los botones de
dirección también permiten jugar con ratón/pantalla táctil. **Ritmo tranquilo**
ralentiza todos los turnos; se puede elegir antes de cada uno.

Título, instrucciones, pausa, transición de turno, derrota, victoria y revancha
forman parte de la misma superficie. Récord únicamente de la sesión abierta;
no se escribe a disco ni se usa `Partida`. Perder foco pausa el arcade.
Salir o retirar el nodo restaura la pausa y el modo de ratón anteriores.

## Arte y textos

Tablero, archivadores, sellos y serpiente se dibujan por código propio, sin
assets externos, logos, flashes ni movimientos de cámara. Texto español/inglés
en `godot/datos/turno_serpiente_textos.json`, elegido por `TranslationServer`.
Efectos chip sintetizados en memoria, con el bus común `Efectos` y sin grabaciones.
No requiere cambios en el catálogo de semillas oníricas ni otorga progreso.

## Regresión y playtest

`python3 -m unittest scripts.test_turno_serpiente_2181` ejecuta el núcleo y UI
reales en un proyecto temporal sin GDExtension. Prueba una partida completa
mediante rutas BFS, puntuación, giros rápidos, cuerpo/bordes/obstáculos, pausa,
input semántico, revancha y restauración de host.

Gate humano pendiente: probar desde casa a 1920 × 1080, completar tres turnos,
derrota/revancha, ritmo tranquilo, cambio a otros cartuchos, salida y controles
remapeados con mando físico. Las pruebas automáticas no acreditan gamefeel.
