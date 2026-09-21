# #932 — SARNATH 98: documentación y frontera de representación

## Alcance

Tercer cartucho de la línea cultural/religiosa de #932. Cambia deliberadamente de gramática jugable: no es un puzzle de luz/composición, sino memoria y orientación espacial.

## Fuentes

### UNESCO World Heritage — Ancient Buddhist Site of Sarnath

https://whc.unesco.org/en/list/927/

UNESCO inscribió el sitio en 2026. La propiedad serial conserva restos arquitectónicos y arqueológicos de Sarnath y continúa siendo un lugar importante de memoria, turismo y peregrinación budista.

### UNESCO Decision 48 COM 8B.17

https://whc.unesco.org/en/decisions/9171

Datos usados:

- la propiedad tiene dos componentes: **Chaukhandi Stupa** y **Archaeological Remains of Sarnath**;
- el desarrollo del sitio abarca muchos siglos y distintos periodos;
- se conservan stupas, templos y viharas de diferentes momentos históricos;
- el lugar mantiene importancia para comunidades budistas actuales;
- la geografía sagrada histórica más amplia ha sido alterada y no puede tratarse como un plano intacto.

### UNESCO — Maps

https://whc.unesco.org/en/list/927/maps/

Los mapas oficiales confirman la condición serial y la separación espacial de los dos componentes inscritos.

## Decisión de diseño

SARNATH 98 no reproduce el trazado de Sarnath.

La mecánica abstrae una sola idea no doctrinal: **observar una secuencia de orientación y recordarla después**.

Cada ronda muestra direcciones; al pulsar A desaparecen y el jugador debe reproducirlas con la cruceta. Las tres secuencias son invención del juego.

## Qué es documentado

- Sarnath está en Varanasi, Uttar Pradesh, India;
- es un sitio arqueológico y un lugar vivo de memoria/peregrinación budista;
- la propiedad UNESCO de 2026 es serial;
- Chaukhandi Stupa y los restos arqueológicos son sus dos componentes;
- el paisaje histórico completo no se conserva intacto.

## Qué es invención

- el título SARNATH 98;
- las tres rutas de flechas;
- sus longitudes y direcciones;
- la interfaz;
- la idea de memorizar el recorrido;
- audio y pixel-art;
- la relación visual entre nodo de salida y nodo de llegada.

Las secuencias **no son itinerarios históricos ni instrucciones de peregrinación**.

## Límites de representación

- no hay puntos de karma, mérito o iluminación;
- no se gamifica meditación o recitación;
- no se usan imágenes del Buda ni objetos devocionales como pickups;
- no se afirma que completar la ROM equivalga a peregrinar;
- no se asigna identidad o convicción al jugador;
- el observer registra únicamente exposición cultural;
- la ROM no concede dinero, pistas o progreso laboral.

## Contrato técnico

    estudiar secuencia
        ↓
    ocultarla
        ↓
    repetirla con cruceta
        ↓
    completar tres rondas
        ↓
    WRAM $C100 = $A5
        ↓
    Sarnath98Vigilia
        ↓
    ReligionEventos.CANAL_EXPOSICION

El tercer vertical vuelve a reutilizar el mismo `ReligionRomVigilia` compartido por JALI 98 y VITRAL 98.
