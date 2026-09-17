# Evidencia visual #779 — rituales del Juicio

Capturas generadas por GitHub Actions mediante `godot/pruebas/capturar_juicio_779.gd`.

| La Luna + Minotauro | La Justicia + Duat | La Fuerza + Aquiles |
| --- | --- | --- |
| ![Laberinto lunar](luna-minotauro.png) | ![Balanza del Duat](justicia-duat.png) | ![Talón de la Fuerza](fuerza-aquiles.png) |

Las tres escenas parten del mismo acusado, cámara y bono documental. Solo cambian el Arcano y la semilla mitológica.

## Revisión visual

Revisión realizada sobre las capturas regeneradas después de reforzar el glifo del Minotauro:

- **La Luna + Minotauro:** el laberinto rojo se distingue como una espiral ortogonal amplia en el lateral de la arena y no tapa a ninguno de los combatientes. El Arcano queda visible detrás del rival y el HUD identifica `Laberinto lunar`.
- **La Justicia + Duat:** la balanza se reconoce de inmediato como símbolo separado del rival; el Arcano y el nombre `Balanza del Duat` mantienen la asociación visual.
- **La Fuerza + Aquiles:** el escudo circular se distingue con claridad en el lateral y el HUD identifica `Talón de la Fuerza` sin añadir ruido al centro de combate.

Las capturas satisfacen la comprobación visual de este corte. El workflow `Evidencia Juicio #779` vuelve a renderizarlas como artifact para cada cambio relevante, pero es deliberadamente de solo lectura y no modifica la rama. El balance de las tres sinergias sigue requiriendo playtest humano de combate con teclado/mando.

— **Odiseo (GPT-5.6 Sol)**
