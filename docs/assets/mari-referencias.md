# Mari — referencias culturales para #651

Este corte documenta las fuentes **antes de cerrar arte o iconografía**. El prototipo usa únicamente geometría, materiales y señalética procedural propia: no copia ni empaqueta imágenes externas.

## Fuentes consultadas

### José Miguel de Barandiarán y fondos públicos

- **José Miguel de Barandiarán, _Obras completas_**, catálogo de Euskariana. El tomo I reúne el _Diccionario ilustrado de mitología vasca y algunas de sus fuentes_ y el tomo II _Eusko-Folklore_: https://www.euskariana.euskadi.eus/euskadibib/eu/bib/1127032.do
- **José Miguel de Barandiarán, _Mitología vasca_**, registro bibliográfico de Euskariana (edición moderna de Txertoa): https://www.euskariana.euskadi.eus/euskadibib/es/bib/1313939.do
- **_Mitología del pueblo vasco I_**, conjunto de datos difundido por Open Data Euskadi a partir de la enciclopedia Euskal Herria Emblematikoa: https://opendata.euskadi.eus/catalogo/-/euskal-herria-enblematikoa-enciclopedia-mitologia-del-pueblo-vasco-1/

Estas referencias se usan como punto de partida etnográfico/bibliográfico. El vertical no presupone que todos los relatos locales formen una versión única y homogénea.

### Síntesis institucionales y enciclopédicas

- **Gobierno Vasco — Mitología vasca**: resume a Mari como figura vinculada a montes y cuevas y a fuerzas de la naturaleza como lluvia y viento: https://www.euskadi.eus/gobierno-vasco/contenidos/informacion/01_cultura/es_def/mitologia.html
- **Auñamendi Eusko Entziklopedia — Mari**: recoge la diversidad de nombres y moradas atribuidas a Mari, su asociación con cuevas/simas, los cambios de residencia y relatos que conectan esos desplazamientos con el tiempo atmosférico: https://aunamendi.eusko-ikaskuntza.eus/es/mari/ar-77955/

Auñamendi remite expresamente a Barandiarán y otras recopilaciones etnográficas. Sus ejemplos muestran además que los detalles cambian por localidad: no deben amalgamarse en una sola «biografía canónica».

## Motivos que sí usa el prototipo

El corte se limita a motivos suficientemente recurrentes y útiles para la mecánica:

1. **cuevas y simas como moradas** asociadas a Mari;
2. **montaña y paisaje** como parte central del imaginario espacial;
3. **lluvia, viento, tormenta y otros fenómenos meteorológicos** asociados a la figura en recopilaciones y síntesis culturales;
4. **cambio de residencia entre lugares** como motivo narrativo, sin fijar una ruta, periodicidad o apariencia única;
5. la idea de que la presencia se puede percibir por **cambios del entorno** sin necesitar una representación humana literal.

El juego traduce estos motivos a una regla propia: el clima reconfigura la lectura del mapa. Esa regla es una invención jugable de SIGA-98, no una afirmación etnográfica.

## Qué se evita fijar como hecho

- no se presenta a Mari como una «diosa madre» universal ni se adopta una cosmología moderna cerrada como si fuera consenso histórico;
- no se fija un vestuario, color, rostro, símbolo, animal acompañante o arma como iconografía obligatoria;
- no se mezclan automáticamente relatos de Anboto, Aketegi, Txindoki, Murumendi u otras localidades como si describieran la misma escena concreta;
- no se usa una periodicidad específica para sus desplazamientos;
- no se convierten ofrendas, conjuros o prácticas locales en puzzle ni en sistema de «dominar» una tradición viva;
- no se copian diseños de ilustraciones, cine, videojuegos, cómic, turismo contemporáneo o recreaciones modernas.

## Traducción al vertical SIGA-98

- **cueva ↔ arquitectura cotidiana**: archivadores y tabiques terminan encajados en un volumen de roca demasiado grande para la habitación;
- **lluvia ↔ cauce legible**: el agua revela una conexión física que antes no se podía seguir;
- **viento ↔ hojas/papeles**: elementos ligeros señalan una cornisa o circulación de aire;
- **niebla ↔ pérdida de referencia lejana**: oculta una baliza distante, pero nunca la orientación inmediata ni la salida;
- **tormenta ↔ transformación máxima**: coinciden cauce, cornisa y boca de cueva, sin rayos ni flashes obligatorios;
- **presencia de Mari ↔ agencia del paisaje**: un volumen lateral y el frente atmosférico cambian; no existe boss, quest giver ni exposición textual.

## Decisiones de accesibilidad y seguridad espacial

- el retorno permanece transitable con cualquier clima;
- la niebla jamás oculta la referencia cercana;
- los cambios son discretos y deterministas: ninguna ruta depende de esperar una tirada aleatoria;
- `reduccion_movimiento` mantiene exactamente el mismo estado/rutas y sustituye la transición por corte/fundido sin partículas;
- no hay plataformas de precisión ni reacción rápida;
- el prototipo no contiene información nueva de expedientes.

## Estado del corte

La dirección artística final queda deliberadamente pendiente. Antes de incorporar una figura humana, nombres locales concretos, reproducciones históricas o assets externos deberá revisarse la procedencia y, si corresponde, registrarse en `godot/assets/procedencia.json` con URL, licencia/derechos y `sha256`.
