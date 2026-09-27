# Evidencia de VFX ambientales ligeros · #1473

Este gate cubre los dos criterios que seguían pendientes tras #1476:
comparación de rendimiento con la capa ambiental activa/inactiva y revisión
visual desde cámara jugable.

El workflow **Evidencia VFX 1473** arranca `res://escenas/dia.tscn` con el
renderer canónico **Forward+** y recorre oficina, calle, casa y sueño. Para cada
fase produce dos imágenes sin HUD:

- `*_activo.png`: estado normal con `EfectosLigeros` y sus efectos
  contextuales montados;
- `*_inactivo.png`: el mismo encuadre después de desmontar únicamente esa capa
  de VFX, incluidos vapor y gotas que viven fuera de la raíz común.

El artifact contiene por tanto **8 capturas** y un `manifest.json`.

## Métricas

En la misma ejecución se miden 45 frames con la capa activa y otros 45 después
de desmontarla. El manifiesto registra:

- tiempo medio de frame en milisegundos para ambos estados;
- delta activo - inactivo;
- número de emisores y partículas atribuibles a la capa;
- superficies ligeras asociadas, como charcos/gotas;
- SHA-256 de cada captura;
- renderer, locale, tamaño, FOV y fase.

La comparación útil es **activo frente a inactivo dentro de la misma ejecución**.
No es un benchmark absoluto: un runner compartido, llvmpipe, un portátil o una
GPU dedicada producen tiempos distintos. Tampoco se fija un umbral automático
de milisegundos porque eso convertiría ruido de infraestructura en una decisión
de rendimiento del juego.

## Revisión humana

El workflow **no autoaprueba** el criterio visual. Abrir cada par A/B y registrar
PASS/FAIL para:

1. el efecto añade profundidad o contexto sin tapar objetos, rostros, documentos
   ni rutas;
2. no aparece una masa de partículas que compita con el espacio;
3. oficina, calle y casa conservan una lectura cotidiana;
4. el sueño deforma un vocabulario conocido de vigilia, no introduce humo de
   terror genérico;
5. si el delta de frame es llamativo, repetir el pase en hardware objetivo antes
   de ajustar presupuestos.

Un resultado puede anotarse así:

```text
Validación visual/rendimiento #1473 · SHA <sha>
- oficina: PASS · delta <x> ms/frame
- calle: PASS · delta <x> ms/frame
- casa: PASS · delta <x> ms/frame
- sueño: PASS · delta <x> ms/frame
- observaciones: ...
```

Si una fase falla, el siguiente cambio debe señalar el efecto concreto
(cantidad, alpha, área, frecuencia o shader) en vez de añadir otra capa visual.
