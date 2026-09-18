# #284 · Contrato transversal de identidades oníricas

Este documento fija el estado integrado de las cuatro familias de #284 y el criterio que debe sobrevivir a futuros pases de arte.

| Familia | Base física | Identidad | Anomalía espacial | Sonido | Objeto/figura | Interacción |
| --- | --- | --- | --- | --- | --- | --- |
| Castillo | ANULAR | arquitectura medieval modular | retorno/alas imposibles | campanas sin fuente | códice desplazado / arquitectura pulsante | lectura de códice conocido |
| Montaña | CONVERGENTE | cima nevada + cabaña | cabaña cambia de distancia al no mirarla | viento + crujidos | huellas anticipadas / documento congelado | lectura del documento conocido |
| Desierto | FRAGMENTADA | extensión mineral abierta | horizonte que conserva distancia | viento, tono y silencio local | sombra sin objeto / papel enterrado | teléfono con frase conocida |
| Escuela | crucero existente | pasillos/aulas reconocibles | aulas y puertas se reordenan | timbre + voces vacías | pupitres, reloj y dibujo mutante | dibujo derivado de contenido conocido |

## Invariantes

- La identidad se decide antes de aplicar capas de degradación/horror genéricas.
- La presentación no crea una segunda navegación ni una segunda colisión.
- El sonido específico es procedural y no introduce binarios externos.
- Las interacciones reutilizan contenido que el sueño ya podía mostrar; no fabrican hechos del expediente.
- Cada familia conserva una firma propia. No se acepta resolver todas con el mismo truco renombrado.
- La forma física puede reutilizar infraestructura de #279; la lectura visual final no puede volver a greybox genérico.

## Regresión automática

`scripts/test_sueno_identidades_284.py` verifica conjuntamente las cuatro verticales: IDs distintos, montaje nocturno, firma de anomalías no solapada, audio procedural, ausencia de física paralela y orden identidad → degradación.

Las pruebas específicas de cada familia siguen siendo la autoridad de detalle. Esta regresión transversal existe para detectar pérdidas de identidad entre subsistemas que por separado podrían seguir pasando CI.

## Gate humano pendiente

El cierre visual sigue perteneciendo a #398: comparar las cuatro familias sin HUD desde cámara de juego y comprobar que se identifican por silueta, luz, sonido y objetos sin depender del nombre de la sala. La evidencia automática reduce regresiones, pero no sustituye esa validación.
