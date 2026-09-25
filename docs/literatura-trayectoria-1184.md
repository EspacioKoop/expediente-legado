# Literatura · trayectoria y epílogo · #1184

Este corte convierte el registro de #1176 en historial persistente de campaña y en una capa de epílogo derivada. No añade nivel cultural, clase, alignment ni eje ganador.

## Persistencia y reset

El registro vive en `Partida` bajo `LiteraturaEventos.CLAVE_ESTADO == "literatura"`.

- una **partida nueva** crea los cuatro canales vacíos;
- cambiar de jornada o sufrir una **reasignación** conserva los hechos;
- guardar/cargar conserva conocimiento, posesión, insight y ritual;
- borrar la partida vuelve a crear el registro vacío;
- partidas antiguas migran de forma aditiva mediante `asegurar_en_estado()`.

`GestorLiteratura` se vincula al diccionario de la partida activa; no mantiene una segunda fuente de verdad durante el recorrido normal.

## Derivación de epílogo

`LiteraturaTrayectoria.derivar_epilogo(final_base, registro)` recibe un final ya resuelto. Literatura **no bloquea** ni sustituye ese final: adjunta una variación descriptiva con obras, canales y procedencia interna de cada hecho.

La procedencia conserva id del evento, canal, fuente, contexto y jornada. Por tanto el epílogo puede distinguir, por ejemplo, una obra leída de una referencia obtenida en diálogo o de un ritual ejecutado, sin inventar una identidad del personaje.

## Pluralidad

No hay suma de puntos ni desempate. Cada obra/canal produce una firma factual ordenada. Cero firmas es `ausente`, una es `singular` y varias son `plural`.

El resultado se ordena por ids, así que invertir el orden de los arrays persistidos produce el mismo resumen. Contradicciones, empates y trayectorias mixtas son estados válidos: se muestran como colección de hechos, nunca como un ganador implícito.

Dos trayectorias distintas pueden producir variaciones literarias distintas manteniendo exactamente el mismo `final_base`.

Refs #1175 #1176 #1184.
