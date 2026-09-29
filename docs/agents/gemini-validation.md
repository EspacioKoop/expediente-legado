# Validar Agent autopilot con Gemini

Esta guía cubre una validación **end-to-end** del worker Gemini sin tocar lógica del juego.

## Antes de lanzar

1. Elige un issue abierto, concreto y suficientemente pequeño.
2. Comprueba que no tenga `agent:working`, `agent:pr-open` ni `agent:needs-human`.
3. Comprueba #182 + #1713 y evita cualquier corte que solape rutas ya reservadas; publica nuevas señales solo en #1713.
4. El repositorio debe tener configurada la API key de Gemini usada por Actions.

## Lanzar Gemini

Añade la etiqueta:

```text
agent:gemini
```

El evento de etiqueta debe arrancar Agent autopilot. No hace falta crear rama, commit ni PR a mano.

## Señales que deben aparecer en #1713

Durante una ejecución normal deben aparecer, en este orden lógico:

1. Un `CLAIM` con el issue, agente, rama y rutas concretas.
2. Una relectura del registro que descarte solapes anteriores.
3. Tras abrir el PR y superar CI, un `PR_READY` con el PR y el SHA validado.

`PR_READY` mantiene la reserva activa, pero **no autoriza merge**.

## Qué comprobar en el PR

El PR generado por el agente debe:

- apuntar a `main`;
- quedar en **draft**;
- limitarse al issue recibido y a las rutas del `CLAIM`;
- incluir una regresión ejecutable cuando cambie comportamiento;
- no contener secretos ni credenciales;
- no cerrar issues ni hacer merge por su cuenta.

Si el PR fue creado por Actions, el workflow dispara la CI canónica de forma explícita para no depender del evento `pull_request` del mismo `GITHUB_TOKEN`.

## Qué comprobar en CI

La validación es satisfactoria cuando:

- la CI del SHA del PR queda verde;
- el issue termina con `agent:pr-open`;
- #1713 contiene el `PR_READY` correspondiente;
- la rama sigue abierta a revisión humana.

Si CI falla, el sistema puede intentar reparación automática. Existe un máximo de **dos commits de reparación** por rama antes de escalar.

## Si aparece `agent:needs-human`

No fuerces el merge ni elimines reservas a ciegas. Comprueba el comentario del agente y clasifica la causa:

- falta de API key o configuración;
- plan sin corte seguro;
- solape con una reserva leída de #182 + #1713;
- salida inválida del modelo;
- fallo de CI que agotó las reparaciones automáticas.

Corrige únicamente la causa concreta. Si una reserva bloquea el corte, coordina o libera esa reserva conforme a #1713. Si el plan no es seguro, reduce el issue antes de reintentarlo.

## Criterio de éxito

La prueba de Gemini se considera válida cuando un issue etiquetado con `agent:gemini` produce un **PR draft acotado**, la CI del SHA queda verde y #1713 registra `CLAIM` y `PR_READY`, sin auto-merge ni intervención manual en la implementación.
