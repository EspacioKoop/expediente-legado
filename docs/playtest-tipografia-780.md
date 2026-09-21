# Playtest #780 · tipografía de SIGA-98

La implementación de #780 ya cubre fuentes empaquetadas y reproducibles, roles separados de interfaz/título/documento/mono y su aplicación a los principales programas OS98. El gate restante es humano: confirmar en una build real que la mejora se lee bien y que no ha degradado foco o navegación con los dispositivos usados por el juego.

Este documento convierte ese último pase en evidencia trazable. No sustituye la revisión visual humana y no permite declarar el gate superado por CI headless.

## Preparación

1. Usar una build identificable por SHA.
2. Ejecutar con el viewport canónico del proyecto: `1920×1080`.
3. Probar la misma build con teclado real y con mando físico real.
4. No cambiar fuentes del sistema para “arreglar” la sesión: #780 debe ser reproducible con las fuentes empaquetadas.
5. Guardar una captura de cada una de las cuatro pantallas del recorrido.

## Recorrido

### 1. Creador de personaje

- Comprobar que el texto pequeño es legible y no presenta el dentado que originó #780.
- Comprobar que labels, botones y campos mantienen una apariencia tipográfica coherente.
- Confirmar que no aparecen recortes, solapes o desbordes causados por las métricas de la fuente.

### 2. Visor de expedientes

- Confirmar que la barra de título queda jerarquizada frente al contenido.
- Confirmar que el cuerpo se lee como documento y no como terminal/mono.
- Recorrer un documento largo hasta el final y comprobar que scroll y layout no recortan texto.

### 3. Reconstrucción

- Confirmar que la barra de título usa la jerarquía visual esperada.
- Recorrer el foco con teclado.
- Repetir el recorrido con mando físico y comprobar que el cambio tipográfico no ha alterado navegación ni selección.

### 4. Ventanilla

- Confirmar que la barra de título está claramente jerarquizada.
- Confirmar que la réplica mecanografiada conserva el rol mono y sigue siendo legible.
- Recorrer foco y navegación con teclado y mando físico.

## Registro asistido

Durante el pase puede generarse un informe homogéneo con:

```bash
python3 scripts/registrar_playtest_780.py \
  --salida docs/playtests/playtest-780.md
```

El registrador conserva:

- fecha, plataforma y SHA de la build;
- viewport utilizado;
- confirmación separada de teclado real y mando físico, incluido el modelo del mando;
- checks específicos para las cuatro pantallas;
- una ruta o URL de evidencia por pantalla;
- incidencias y observaciones literales del tester.

El resumen `listo para valorar cierre de #780` solo queda en **SÍ** cuando el viewport es `1920×1080`, ambos dispositivos fueron probados, todos los checks están marcados como cumplidos y existe evidencia para las cuatro pantallas.

## Criterio de salida

#780 puede valorarse para cierre cuando el registro de una build concreta queda en **SÍ** y la revisión humana no detecta una regresión adicional.

Si falla un check, mantener #780 abierto o abrir una incidencia específica enlazada desde #780 con build SHA, pantalla, dispositivo, pasos de reproducción y captura. No debe “arreglarse” el registro para que el gate pase: el objetivo es conservar evidencia del resultado real.
