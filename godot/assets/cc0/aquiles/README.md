# Aquiles — catálogo CC0 para #438

Este directorio reserva el destino de los assets externos del vertical de Aquiles. El primer corte no incluye binarios: el repositorio exige registrar binarios en `godot/assets/procedencia.json` y, cuando corresponda, subir también sus objetos Git LFS. Esa ruta está compartida/reservada por otros trabajos, así que aquí se documentan únicamente fuentes verificadas y rutas de importación previstas.

## 3D — figura principal

### Achilles Spartan Greek Warrior — OpenGameArt

- Autor publicado: `gamekorp`.
- Tipo: malla + textura; la ficha indica que **no incluye rig**.
- Licencia declarada por la ficha: **CC0**.
- Página: <https://opengameart.org/content/achilles-spartan-greek-warrior>
- Descarga publicada: `Spartan_Achilles.zip` (aprox. 3,6 MB).
- Uso previsto: silueta monumental de la escena onírica. `SuenoAquiles` intentará cargar `res://assets/cc0/aquiles/modelo/achilles_spartan_greek_warrior.glb` cuando exista; hasta entonces usa un fallback geométrico ejecutable.

Al vendorizarlo conviene conservar el original y generar/importar una copia GLB estable para Godot sin reinterpretar la licencia. La ausencia de rig no bloquea #438: la mecánica depende de escala, iluminación y punto vulnerable, no de combate o animación compleja.

## 2D — contraparte doméstica / pista visual

### The Baptism of Achilles — Cleveland Museum of Art

- Autor: Honoré Daumier.
- Fecha: 1842.
- Accession: `2009.587`.
- Política: el Cleveland Museum of Art publica sus imágenes Open Access bajo **CC0**.
- Ficha: <https://www.clevelandart.org/art/2009.587>
- Imagen Open Access: <https://openaccess-cdn.clevelandart.org/2009.587/2009.587_print.jpg>
- Uso previsto: póster o lámina en casa que el jugador debe examinar/manipular; funciona como pista temática sin texto tutorial.

### Thetis Dipping the Infant Achilles into the Waters of the Styx — The Met

- Autor: Donato Creti.
- Objeto: `338578`; accession `80.3.369`.
- Estado: Open Access / dominio público; la copia de Wikimedia Commons está marcada **CC0 1.0**.
- Met: <https://www.metmuseum.org/art/collection/search/338578>
- Commons: <https://commons.wikimedia.org/wiki/File:Thetis_Dipping_the_Infant_Achilles_into_the_Waters_of_the_Styx_MET_DP800245.jpg>
- Uso previsto: alternativa más explícita para una pista centrada en la inmersión y la pierna/talón.

### Thetis Plunges Achilles in River Styx — Smithsonian / Cooper Hewitt

- Autor: Felice Giani.
- Fecha: ca. 1790.
- La ficha Smithsonian declara `Restrictions & Rights: CC0`.
- Búsqueda/ficha Smithsonian: <https://www.si.edu/object/thetis-plunges-achilles-river-styx:chndm_1901-39-2713>
- Uso previsto: alternativa de póster doméstico o referencia compositiva para el reflejo imposible del sueño.

## Criterio de integración

1. No basta con que una obra sea antigua: solo se cataloga aquí cuando la fuente institucional o la ficha del asset declara CC0/Open Access compatible de forma explícita.
2. Los binarios se incorporarán en un corte posterior que pueda editar `godot/assets/procedencia.json` y subir el objeto LFS real si aplica.
3. La escena no depende del asset externo para ser ejecutable: el fallback geométrico conserva la mecánica y evita que una descarga rota bloquee CI.
4. La integración final debe mantener el punto vulnerable como lectura espacial (luz/reflejo), no como hitbox de combate.
