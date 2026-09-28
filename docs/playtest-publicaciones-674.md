# Playtest #674 · publicaciones físicas de 1998

La implementación de #674 ya cubre siete publicaciones ficticias, compra reutilizando la economía existente, ejemplares encontrables, almacenamiento doméstico, representación física común, lectura de cuatro piezas por publicación y dos handshakes culturales explícitos con #442.

El pendiente real es perceptivo y de input: comprobar en una build que los objetos se reconocen a escala de mundo, que el visor sigue siendo legible y que teclado/mando recorren el flujo completo sin que las publicaciones se conviertan en una obligación.

## Preparación

1. Usar una build identificable por SHA.
2. Ejecutar con el viewport canónico del proyecto: `1920×1080`.
3. Probar teclado real y mando físico real.
4. Guardar una captura o referencia de evidencia para cada escenario.
5. No usar consola para mover publicaciones ni activar semillas.

## Recorrido mínimo

### 1. Compra en quiosco

- Comprar `revista_umbral_98` o `libro_popol_wuj_98`.
- Confirmar que la portada/cabecera se distingue antes de abrir el visor.
- Confirmar que la compra usa el flujo normal del quiosco y que el foco no se pierde.

### 2. Ejemplar encontrable

- Recoger uno de los cuatro ejemplares no comprables en su ubicación real.
- Confirmar escala física, identidad frente a props cercanos y que el verbo de recogida resulta comprensible.
- Guardar/cargar no debe duplicar el mismo ejemplar.

### 3. Publicación almacenada en casa

- Llevar una publicación a `home_storage`.
- Confirmar que aparece físicamente en la acumulación doméstica sin clipping grave.
- Interactuar con `LEER` y verificar que abre el contenido del ejemplar correcto.

### 4. Visor

- Recorrer al menos cuatro piezas.
- Comprobar scroll y tamaños de texto en `1920×1080`.
- Probar PageUp/PageDown y foco con teclado.
- Repetir navegación/cambio de pieza/cierre con mando físico.

### 5. Opcionalidad

En una vuelta separada, ignorar las publicaciones y comprobar que se puede continuar el ciclo normal. El gate no debe considerar correcto un estado en el que una revista/libro se haya convertido accidentalmente en requisito de campaña.

## Registro asistido

```bash
python3 scripts/registrar_playtest_674.py \
  --salida docs/playtests/playtest-674.md
```

El registrador conserva build, plataforma, viewport, dispositivos, checks por escenario, evidencia y observaciones. El resumen solo marca **SÍ** cuando todos los checks humanos están completos, existe evidencia para los cuatro escenarios, se ha probado teclado+mando y la opcionalidad sigue intacta.

## Criterio de salida

Si el registro queda en **SÍ** y no hay incidencias nuevas, #674 puede valorarse para cierre. Un FAIL debe transformarse en un defecto reproducible concreto (pantalla/objeto, build SHA, dispositivo, pasos y evidencia), no en más contenido editorial por inercia.
