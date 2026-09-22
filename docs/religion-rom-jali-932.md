# #932 — JALI 98: documentación y frontera de representación

## Alcance

Este primer vertical usa una pieza histórica concreta como punto de partida para una micro-ROM de exposición cultural. No intenta representar “el islam” como una estética única ni simular una práctica religiosa.

## Fuentes

### The Metropolitan Museum of Art — Pierced Window Screen (Jali), 1993.67.1

https://www.metmuseum.org/art/collection/search/453343

Datos que sí se trasladan al diseño:

- pieza fechada en la segunda mitad del siglo XVI;
- probablemente realizada en Agra, India;
- arenisca roja, tallada y perforada;
- adscrita al periodo mogol de Akbar;
- los jalis podían funcionar como ventanas, divisores y barandillas;
- la luz atravesaba el calado y proyectaba patrones sobre el espacio;
- la ficha y el audio curatorial describen estrellas, hexágonos y formas geométricas entrelazadas.

### The Metropolitan Museum of Art — Geometric Patterns in Islamic Art

https://www.metmuseum.org/essays/geometric-patterns-in-islamic-art

Se usa para evitar una simplificación importante: la geometría es una de varias familias de ornamentación documentadas en arte islámico y no debe confundirse con caligrafía o decoración vegetal ni presentarse como un código universal de todas las comunidades, épocas y regiones.

## Hecho documentado frente a diseño

### Documentado

El vertical conserva cuatro ideas comprobables en las fuentes:

1. existe una tradición de jalis perforados en arquitectura mogol;
2. el ejemplo de referencia pertenece a India y al siglo XVI;
3. el calado relaciona geometría, luz, aire y espacio arquitectónico;
4. estrellas, hexágonos y entrelazados aparecen en el ejemplo estudiado.

### Invención del juego

Son invención de Expediente Legado:

- el título JALI 98;
- las tres bandas móviles;
- las cuatro fases de cada banda;
- la combinación solución 1/3/2;
- los indicadores de luz/sombra;
- música, sonidos y pixel-art;
- la idea de “resolver” una composición.

No se reproduce el patrón del objeto 1993.67.1 ni se afirma que el puzzle reconstruya técnicas históricas de talla.

## Límites de representación

- No se usa texto coránico como contraseña, puzzle o recompensa.
- No se usa caligrafía religiosa como decoración intercambiable.
- No se incorporan nombres divinos.
- No se usan objetos rituales como pickups, vida, dinero o daño.
- No se presenta el jali como exclusivo de un único tipo de edificio.
- No se infiere que jugar equivalga a práctica religiosa.
- No se infiere creencia, adscripción o convicción.
- La etiqueta de tradición en ReligionEventos sirve como procedencia documental del contenido, no como identidad del jugador.

## Contrato técnico

Flujo:

    jugar JALI 98
        ↓
    manipular las tres bandas
        ↓
    completar composición
        ↓
    WRAM $C100 = $A5
        ↓
    Jali98Vigilia
        ↓
    ReligionEventos.CANAL_EXPOSICION
        ↓
    ReligionRecuerdoJali932

La ROM no conoce Partida, Jornada, ReligionEventos ni el consumidor posterior.

El consumidor posterior solo conserva motivos que el jugador ya ha visto: geometría, luz, sombra y calado. No introduce hechos nuevos de expedientes y no transforma la exposición en práctica o convicción.

### Consecuencia posterior visible

Durante una fase `sueño`, si la exposición a JALI 98 existe, `ReligionRecuerdoJali9323D` materializa una firma baja de suelo formada por tres rosetas geométricas de luz. Es geometría procedural propia, no reproduce el jali histórico ni añade símbolos o texto religioso. No tiene colisión, interacción ni efecto jugable: el sueño recuerda una relación visual ya experimentada en la ROM.

## Trabajo posterior

Antes de añadir una segunda ROM vinculada a una tradición viva concreta hay que repetir esta estructura documental: fuente, lugar/periodo, materialidad, frontera entre hecho e invención y revisión de símbolos/textos que no deben convertirse en mecánica.
