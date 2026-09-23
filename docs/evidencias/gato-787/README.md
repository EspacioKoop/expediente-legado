# Evidencia visual del gato sistémico · #787

Este gate cubre el último criterio que no puede resolverse solo con pruebas:
**mirar al mismo gato en casa y en sueño**.

El workflow **Evidencia gato 787** arranca la escena jugable real
`res://escenas/dia.tscn`, fuerza un estado válido con el gato presente y
publica dos capturas sin HUD tomadas con la cámara del jugador:

- `casa.png`: gato doméstico real (`dia._gato`) desde la entrada de la casa;
- `sueno.png`: guía onírica real (`dia._gato_guia`) en la escena `crucero`.

El encuadre no usa una cámara de debug. Coloca al caminante en la entrada de la
fase y hace que su propia `Camera3D` mire al centro de la silueta del gato.

Junto a las PNG se publica `manifest.json` con señales objetivas para evitar
capturas falsas o rotas: fase, hash, distancia a cámara, escala global del gato
y si la guía del sueño está en modo `top_level`. Esas señales pueden detectar
un montaje incorrecto, pero **no autoaprueban** el resultado visual.

## Revisión humana obligatoria

Abrir las dos imágenes del mismo artefacto y registrar **PASS/FAIL** para estos
puntos:

1. **Identidad:** `casa.png` y `sueno.png` deben mostrar la misma silueta
   felina reconocible; el sueño no debe convertirla en otra criatura.
2. **Proporciones:** cabeza, cuerpo, patas y cola deben conservar una lectura
   comparable; no debe aparecer estirado o aplastado por el decorado onírico.
3. **Escala:** el gato debe mantener un tamaño plausible respecto al jugador en
   ambos contextos. El sueño puede deformar arquitectura y utilería, no al gato.
4. **Legibilidad:** la pose debe distinguirse del fondo y seguir comunicando que
   es el gato, sin depender del HUD ni de un texto explicativo.

Un ejemplo de resultado válido en el PR es:

```text
Validación visual #787
- Identidad casa ↔ sueño: PASS
- Proporciones: PASS
- Escala estable: PASS
- Legibilidad sin HUD: PASS
```

Si cualquiera falla, anotar qué imagen y qué rasgo concreto falla antes de
modificar arte, cámara o iluminación.

El workflow solo garantiza que ambas capturas existen, son distintas, usan la
cámara jugable y que la raíz onírica conserva escala 1:1:1. **No sustituye la
revisión humana** y, por sí solo, no cierra #787.
