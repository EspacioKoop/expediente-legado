# Religión en el mundo físico — primer corte de #934

Este corte prueba el contrato de **cultura material + práctica contextual** sin fijar todavía una tradición viva concreta. La decisión es deliberada: #934 exige documentación antes de convertir símbolos, calendarios o gestos de una comunidad real en contenido del juego.

## Qué materializa

ReligionMundo9343D construye dos superficies procedurales, sin assets externos:

1. **tablón de calendario comunitario** — corcho, papel y madera; al examinarlo registra exposición;
2. **mesa de recuerdo** — mesa y libro físico; durante el acto correspondiente permite una práctica presencial.

No hay iconografía sagrada genérica, símbolos mezclados ni decoración presentada como representación de una religión concreta. La geometría es original y procedural, así que este corte no incorpora licencias ni procedencias de terceros.

## Calendario y procedencia interna

El piloto usa una única actividad ficticia de prueba:

- ID: acto_memoria_vecinal;
- jornada: 3;
- fuente interna: calendario:tablon_comunitario_98.

La fuente viaja como etiqueta del evento registrado. El calendario no se deriva de azar ni de una identidad del jugador. Este acto no pretende reproducir una festividad religiosa real: sirve para validar el wiring de calendario antes de documentar tradiciones concretas.

## Canales

Examinar el tablón registra exposición con fuente mundo:tablon_calendario_98. Participar en el silencio de memoria registra práctica con fuente mundo:mesa_recuerdo_98 y contexto sala_comunitaria:acto_memoria.

En ambos casos la tradición queda vacía. **No se escribe convicción declarada, identidad religiosa, barra de fe ni reputación religiosa.** El mismo gesto puede tener motivos religiosos, familiares, sociales o de respeto; el sistema conserva únicamente el hecho observable.

## Interacción y accesibilidad

La práctica ocurre mediante Interactuable3D en el mundo 3D. No abre menú ni consume una acción de campaña. Si el jugador la ignora, este corte no cambia el recorrido principal.

La preferencia de reducción de movimiento llega al componente, pero el gesto piloto no depende de animación: con o sin reducción se registra el mismo evento. Así la preferencia no altera significado ni reglas.

## Qué queda fuera

Este PR no monta todavía el componente en dia.tscn ni dia_calle_app.gd, porque esas rutas mantienen verticales recientes o activos y #934 no necesita colisionar con ellos para fijar el contrato. Un segundo corte puede cablear el componente cuando quede libre una superficie de runtime.

También queda pendiente documentar al menos una tradición viva concreta antes de añadir iconografía, fechas o prácticas específicas; decidir el espacio final del recorrido; persistir el registro común cuando #931 fije su dueño definitivo en Partida/Jornada; y probar teclado, mando y lectura visual en una build real.

Refs #916 #931 #934.
