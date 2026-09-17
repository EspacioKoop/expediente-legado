# Evidencia visual #779 — rituales y telegráfico del Juicio

Capturas generadas por GitHub Actions mediante `godot/pruebas/capturar_juicio_779.gd`.

| La Luna + Minotauro | La Justicia + Duat | La Fuerza + Aquiles |
| --- | --- | --- |
| ![Laberinto lunar](luna-minotauro.png) | ![Balanza del Duat](justicia-duat.png) | ![Talón de la Fuerza](fuerza-aquiles.png) |

## Ataque rival telegrafiado

![Ataque rival telegrafiado](telegraph-ataque.png)

La cuarta captura coloca a ambos combatientes dentro del alcance real y activa el wind-up del rival. El disco rojo corresponde al radio efectivo del golpe y el HUD muestra `ATAQUE INMINENTE` durante la ventana de reacción.

## Revisión visual

- **La Luna + Minotauro:** el laberinto rojo se distingue como una espiral ortogonal amplia en el lateral de la arena y no tapa a ninguno de los combatientes. El Arcano queda visible detrás del rival y el HUD identifica `Laberinto lunar`.
- **La Justicia + Duat:** la balanza se reconoce de inmediato como símbolo separado del rival; el Arcano y el nombre `Balanza del Duat` mantienen la asociación visual.
- **La Fuerza + Aquiles:** el escudo circular se distingue con claridad en el lateral y el HUD identifica `Talón de la Fuerza` sin añadir ruido al centro de combate.
- **Telegráfico de ataque:** el área roja se distingue con claridad sobre el suelo oscuro, engloba la zona de peligro sin ocultar las siluetas y `ATAQUE INMINENTE` destaca sobre el HUD. La lectura sigue presente con reducción de movimiento porque disco y texto no dependen de animación.

Estas capturas satisfacen la comprobación visual de este corte. El workflow `Evidencia Juicio #779` vuelve a renderizarlas como artifact para cada cambio relevante, permanece en modo de solo lectura y no modifica la rama. El ajuste fino de los 0,45 s de wind-up y la ventana de esquiva sigue siendo materia de playtest humano con teclado/mando.

— **Odiseo (GPT-5.6 Sol)**
