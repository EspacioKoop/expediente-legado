# Playtest transversal de reactividad · #400

Este pase convierte el último gate de #400 en una comprobación humana reproducible.
No mide sólo cuántos props existen: comprueba si **oficina, calle, casa y sueño
reaccionan al jugador desde cámara jugable** y si los objetos relevantes prometen
lo que realmente hacen.

La evidencia visual de #282 sigue siendo el gate de densidad/lectura estática. Este
pase la complementa con interacción real sobre **el mismo SHA de build**.

## Preparación

1. Usar una build identificable mediante `BUILD-INFO.txt`.
2. Obtener el artifact **Evidencia densidad 282** generado para ese mismo SHA.
3. Usar un participante que no conozca el layout ni qué objetos están cableados.
4. No señalar interactuables concretos ni explicar de antemano qué debería reaccionar.
5. Recorrer las cuatro fases en orden normal: oficina → calle → casa → sueño.
6. Mantener HUD/prompts normales del juego: el objetivo es juzgar el contrato real,
   no una escena de prueba.

El registrador asociado conserva las respuestas literales y sólo resume checks
explícitos del facilitador:

```bash
python3 scripts/registrar_playtest_400.py \
  --salida docs/playtests/playtest-400.md
```

## Qué observar

### Oficina / archivo

Sin dirigir al participante, dejarle explorar el puesto y su entorno. El corte pasa
esta fase si descubre y usa **al menos dos interacciones ambientales distintas** que
respondan de forma observable —por ejemplo archivador/cajón, café, lámpara/equipo,
teléfono, documentos u otra utilería vigente— y entiende el cambio de estado.

No cuenta como segunda interacción repetir el mismo toggle varias veces.

### Calle / trayecto

Debe quedar claro qué elemento lleva a casa y existir al menos **otra respuesta
contextual** en el entorno —persiana, escaparate, señal/luz, puerta u otra pieza
vigente—. El umbral del registrador es **dos respuestas distintas** contando el
portal/transición sólo si el participante lo reconoce y usa sin que se lo señalen.

No se exige que todo mobiliario urbano sea interactivo.

### Casa

La casa debe ofrecer **al menos tres microinteracciones distintas** con respuesta
física, visual o sonora comprensible. Pueden incluir almacenamiento, luces,
TV/portátil/consola, ventana/persiana, comida/café, teléfono, cama, objetos del gato
u otras superficies vigentes.

El criterio no exige una barra de necesidades ni convierte estas acciones en
obligatorias para progresar.

### Sueño

El participante debe encontrar **al menos dos respuestas distintas** del entorno
onírico —anomalías/objetos reconocibles que cambian, luz/sonido, proximidad,
transformación o inspección vigente— sin que el facilitador le revele dónde están.

#281 sigue siendo dueño del progreso de la noche. Este pase sólo juzga reactividad y
lectura ambiental.

## Affordances y feedback

Durante todo el recorrido:

- una acción que parece válida debe producir feedback visible, sonoro o de estado sin
  demora confusa;
- un objeto puramente decorativo no debe anunciar una interacción inexistente;
- el participante no debería necesitar que el facilitador le señale dónde están las
  oportunidades mínimas del gate;
- repetir una acción debe mantener un verbo/estado coherente (abrir/cerrar,
  encender/apagar, usar/recoger, etc.);
- reducción de movimiento puede simplificar animación, pero no debe ocultar el
  resultado final de la interacción.

## Criterio del registrador

El pase queda **listo para valorar cierre** sólo si:

- build y artifact visual #282 corresponden al mismo SHA;
- el participante no conocía previamente el layout/interactuables;
- oficina registra ≥2 respuestas distintas;
- calle registra ≥2 respuestas distintas;
- casa registra ≥3 respuestas distintas;
- sueño registra ≥2 respuestas distintas;
- el feedback se percibe inmediato y comprensible;
- no se detectan affordances engañosas reproducibles;
- el facilitador no tuvo que señalar interactuables concretos para alcanzar mínimos;
- no queda una incidencia reproducible que invalide la lectura/reactividad.

El script **no interpreta por IA** las respuestas abiertas. Los números y checks los
introduce el facilitador después de observar el pase.

## Si falla una fase

No abrir otro lote horizontal de props por defecto. Registrar:

1. fase;
2. objeto/situación concreta;
3. qué esperaba el participante;
4. qué ocurrió realmente;
5. si el problema es visual (#282/#398/#399), de interacción (#283/#400), controles
   (#396/#113) o contenido de la vertical concreta.

El siguiente PR debe atacar esa observación reproducible y mantener #400 como
paraguas hasta que el pase transversal sea satisfactorio.

Refs #126 #133 #277 #281 #282 #283 #284 #398 #399 #407 #423 #424 #433 #1281 #1285 #1290.

— Odiseo (GPT-5.6 Sol)
