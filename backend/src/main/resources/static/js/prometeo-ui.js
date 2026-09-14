(function () {
    "use strict";

    var dialog = document.getElementById("prometeo-menu");
    var trigger = document.getElementById("prometeo-menu-btn");
    if (!dialog || !trigger || typeof dialog.showModal !== "function") {
        return;
    }

    var logrosLista = document.getElementById("prometeo-logros-lista");
    var tarotLista = document.getElementById("prometeo-tarot-lista");
    var contadorTarot = document.getElementById("prometeo-tarot-contador");
    var botonTarot = document.getElementById("prometeo-tarot-revelar");
    var captcha = document.getElementById("prometeo-captcha");
    var preguntaCaptcha = document.getElementById("prometeo-captcha-pregunta");
    var asistente = document.getElementById("prometeo-assistente");
    var textoAsistente = document.getElementById("prometeo-assistente-texto");
    var respuestasAsistente = document.getElementById("prometeo-assistente-respuestas");
    var avatarAsistente = document.querySelector(".prometeo-assistente-avatar");
    var finalAlternativo = document.getElementById("prometeo-final");
    var textoFinal = document.getElementById("prometeo-final-texto");
    var rango = document.getElementById("prometeo-volumen-rango");
    var vidaResumen = document.getElementById("prometeo-vida-resumen");
    var vidaHud = document.getElementById("prometeo-vida-hud");
    var activarPistasCheckbox = document.getElementById("prometeo-activar-pistas");
    var combateRaiz = document.getElementById("prometeo-combate-raiz");
    var formCombateFinalizar = document.getElementById("form-combate-finalizar");
    var ventanillaRaiz = document.getElementById("prometeo-ventanilla-combate");
    var ventanillaRacha = document.getElementById("prometeo-ventanilla-racha");
    var ventanillaEmpezar = document.getElementById("prometeo-ventanilla-empezar");
    var jefeModal = document.getElementById("prometeo-jefe");
    var despidoModal = document.getElementById("prometeo-despido");
    var finalVerdaderoModal = document.getElementById("prometeo-final-verdadero");
    var historiaCartaModal = document.getElementById("prometeo-historia-carta");
    var historiaCartaTitulo = document.getElementById("prometeo-historia-carta-titulo");
    var historiaCartaTexto = document.getElementById("prometeo-historia-carta-texto");
    var historiaCartaOpciones = document.getElementById("prometeo-historia-carta-opciones");
    var finalPoliticoModal = document.getElementById("prometeo-final-politico");
    var finalPoliticoTitulo = document.getElementById("prometeo-final-politico-titulo");
    var finalPoliticoTexto = document.getElementById("prometeo-final-politico-texto");
    var finalPoliticoRibbon = document.getElementById("prometeo-final-politico-ribbon");
    var tarotVisor = document.getElementById("prometeo-tarot-visor");
    var tarotVisorArte = document.getElementById("prometeo-tarot-visor-arte");
    var tarotVisorTitulo = document.getElementById("prometeo-tarot-visor-titulo");
    var tarotVisorDesc = document.getElementById("prometeo-tarot-visor-desc");
    var tarotVisorEstado = document.getElementById("prometeo-tarot-visor-estado");
    var radiosDificultad = document.querySelectorAll("input[name=\"prometeo-dificultad\"]");
    var audioCtx = null;
    var master = null;
    var ambiente = null;
    var animacionLinceId = null;
    var LLAVE_VOLUMEN = "prometeo-volumen";
    var LLAVE_ESTADO = "prometeo-estado";
    var real = window.PROMETEO_ESTADO_REAL || null;
    var PrometeoLogic = window.PrometeoLogic;

    /**
     * Vidas y umbral de "acusación precipitada" por dificultad. Normal es
     * la recomendada; fácil/difícil solo mueven estos dos números.
     */
    var DIFICULTADES = {
        facil: { vidasMax: 5, umbralEvidencia: 0.4 },
        normal: { vidasMax: 3, umbralEvidencia: 0.6 },
        dificil: { vidasMax: 2, umbralEvidencia: 0.75 }
    };

    // Compartido entre la trampa de foco de los modales y la navegación por mando.
    var FOCO_SELECTOR = "a[href], button:not([disabled]), input:not([disabled]), "
        + "select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex='-1'])";

    var state = cargarEstado();

    /**
     * Fotogramas del lince por estado de ánimo: cada uno alterna un par de
     * caras para simular parpadeo/gesto mientras el asistente está visible.
     */
    var CARAS_LINCE = {
        neutral: [
            "   /\\_/\\\n  ( o.o )\n   > w <\n  /|   |\\\n (_|   |_)~",
            "   /\\_/\\\n  ( o.o )\n   > w <\n  /|   |\\\n (_|   |_) ~",
            "   /\\_/\\\n  ( -.- )\n   > w <\n  /|   |\\\n (_|   |_)  ~",
            "   /\\_/\\\n  ( o.o )\n   > w <\n  /|   |\\\n (_|   |_) ~"
        ],
        guino: [
            "   /\\_/\\\n  ( ^.- )\n   > w <\n  /|   |\\\n (_|   |_)~",
            "   /\\_/\\\n  ( -.^ )\n   > w <\n  /|   |\\\n (_|   |_)  ~",
            "   /\\_/\\\n  ( ^.- )\n   > w <\n  /|   |\\\n (_|   |_)~~",
            "   /\\_/\\\n  ( -.^ )\n   > w <\n  /|   |\\\n (_|   |_) ~"
        ],
        alerta: [
            "   /\\_/\\\n  ( O.O )\n   >   <\n  /|   |\\\n (_|   |_)|",
            "   /\\_/\\\n  ( 0.0 )\n   >   <\n  /|   |\\\n (_|   |_)!",
            "   /\\_/\\\n  ( O.O )\n   >   <\n  /|   |\\\n (_|   |_)|"
        ],
        triste: [
            "   /\\_/\\\n  ( -.- )\n   > , <\n  /|   |\\\n (_|   |_)_",
            "   /\\_/\\\n  ( -.- )\n   > , <\n  /|   |\\\n (_|   |_),"
        ]
    };

    var INTERVALO_LINCE = { neutral: 1900, guino: 1500, alerta: 450, triste: 2800 };

    /**
     * Arte pixelado de cada carta de tarot: una rejilla de 16x20 (cada
     * carácter es una celda) más una paleta propia por carta. Inspirado en
     * los 22 arcanos mayores del tarot, reinterpretados para la ficción
     * de la oficina en la descripción de cada una.
     */
    var ARTE_TAROT = {
        "el-loco": {
            paleta: { 1: "#0b0810", 2: "#5a6b8a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                ".......3...4....",
                "......333.444...",
                ".......3.114....",
                ".......21.......",
                ".......12.......",
                ".......22.......",
                "......2..2......",
                "......2..2......",
                "......2..2......",
                ".....2....2.....",
                ".....2....2.....",
                "....2......2....",
                "....2......2....",
                "................",
                "................",
                "................",
                "................",
                "................"
            ]
        },
        "el-mago": {
            paleta: { 1: "#0b0810", 2: "#3d2f55", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                ".............4..",
                "......4..4..1...",
                "........3..1....",
                ".......333.1....",
                "........3.1.....",
                "........21......",
                "........2.......",
                ".......222......",
                ".......222......",
                "......22222.....",
                "......22222.....",
                ".....2222222....",
                ".....2222222....",
                "....222222222...",
                "....222222222...",
                "................",
                "................",
                "................",
                "................"
            ]
        },
        "la-sacerdotisa": {
            paleta: { 1: "#0b0810", 2: "#243b4a", 3: "#d9cdb0", 4: "#7fa8c9" },
            filas: [
                "................",
                "........4.......",
                ".......444......",
                ".22...44.44..22.",
                ".22....444...22.",
                ".22....343...22.",
                ".22.....3....22.",
                ".22.....2....22.",
                ".22....222...22.",
                ".22....222...22.",
                ".22...22222..22.",
                ".22...22222..22.",
                ".22..2222222.22.",
                ".22..2222222.22.",
                ".22.22222222222.",
                ".22.22222222222.",
                ".22..........22.",
                "................",
                "................",
                "................"
            ]
        },
        "la-emperatriz": {
            paleta: { 1: "#0b0810", 2: "#5a3a4a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "........4.......",
                ".......444......",
                "........3.......",
                ".......333......",
                "........3.......",
                "........2.......",
                ".......222..4...",
                ".......222.444..",
                "......22224.4.4.",
                "......22222.4...",
                ".....22222224...",
                ".....22222224...",
                "....222222224...",
                "....222222222...",
                "...22222222222..",
                "................",
                "................",
                "................"
            ]
        },
        "el-emperador": {
            paleta: { 1: "#0b0810", 2: "#5a2f2f", 3: "#d9cdb0", 4: "#caa23c", 5: "#3a3a3a" },
            filas: [
                "................",
                "................",
                ".......444......",
                ".......444......",
                "........3.......",
                ".......333......",
                "........3.......",
                "........2.......",
                ".......222......",
                ".......222......",
                "......22222.....",
                ".....2222222....",
                "....52222222....",
                "....222222222...",
                "....55555555....",
                "....55555555....",
                "....55555555....",
                "....55555555....",
                "................",
                "................"
            ]
        },
        "el-hierofante": {
            paleta: { 1: "#0b0810", 2: "#2f4a3a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "........4.......",
                ".......444......",
                ".......444......",
                "......44444.....",
                "........3.......",
                ".......333......",
                "........3....3..",
                "........2...3...",
                ".......222.3....",
                ".......222......",
                "......22222.....",
                "......22222.....",
                ".....2222222....",
                ".....2222222....",
                "....222222222...",
                "....222222222...",
                "...22222222222..",
                "................",
                "................"
            ]
        },
        "los-enamorados": {
            paleta: { 1: "#0b0810", 2: "#4a2f3a", 3: "#d9cdb0", 4: "#caa23c", 5: "#2f3a4a" },
            filas: [
                "................",
                "..........4.....",
                ".........444....",
                "..........4.....",
                "................",
                ".....3.....3....",
                "....333...333...",
                ".....3.....3....",
                ".....2.....5....",
                ".....2.....5....",
                "....222...555...",
                "....222...555...",
                "...22222.55555..",
                "...22222.55555..",
                "..2222225555555.",
                "..2222225555555.",
                "................",
                "................",
                "................",
                "................"
            ]
        },
        "el-carro": {
            paleta: { 1: "#0b0810", 2: "#2f3a5a", 3: "#d9cdb0", 4: "#caa23c", 5: "#1a1a1a" },
            filas: [
                "................",
                "........4.......",
                "................",
                "................",
                "........3.......",
                ".......333......",
                "........3.......",
                "........2.......",
                ".......222......",
                ".......222......",
                "......22222.....",
                "......22222.....",
                ".....2222222....",
                ".....2222222....",
                "....55555555....",
                "....55555555....",
                "....51555515....",
                "....111..111....",
                ".....1....1.....",
                "................"
            ]
        },
        "la-fuerza": {
            paleta: { 1: "#0b0810", 2: "#4a3a2f", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "................",
                "......3.........",
                ".....333........",
                "......3.........",
                "......2.........",
                ".....222........",
                ".....222........",
                "....22222.......",
                "....22222.......",
                "...2222222....4.",
                "........44444444",
                "........4444444.",
                "........4444444.",
                "........4444444.",
                "...............4",
                "...............4",
                "................",
                "................"
            ]
        },
        "el-ermitanio": {
            paleta: { 1: "#050308", 2: "#20232a", 3: "#c9c2b8" },
            filas: [
                ".............3..",
                "............333.",
                ".............3..",
                ".............2..",
                "............2...",
                ".......1....2...",
                "......111..2....",
                ".......1...2....",
                ".......2..2.....",
                "......222.......",
                "......222.......",
                ".....22222......",
                ".....22222......",
                "....2222222.....",
                "....2222222.....",
                "...222222222....",
                "...222222222....",
                "..22222222222...",
                "................",
                "................"
            ]
        },
        "la-rueda": {
            paleta: { 1: "#0b0810", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "........4.......",
                ".....4444444....",
                "...44...4...44..",
                "...44...4...44..",
                "..4..4..4..4..4.",
                "..4...4.4.4...4.",
                "..4....434....4.",
                ".444444333444444",
                "..4....434....4.",
                "..4...4.4.4...4.",
                "..4..4..4..4..4.",
                "...44...4...44..",
                "...44...4...44..",
                ".....4444444....",
                "........4.......",
                "................",
                "................",
                "................"
            ]
        },
        "la-justicia": {
            paleta: { 1: "#0b0810", 2: "#3a3a4a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "............4...",
                "............4...",
                ".........4444444",
                "...4....3...4...",
                "...4...333..4...",
                "...4....3...4...",
                "...4....2...4...",
                "..444..222..4...",
                ".......222..4...",
                "......22222.4...",
                "......22222.....",
                ".....2222222....",
                ".....2222222....",
                "....222222222...",
                "....222222222...",
                "................",
                "................",
                "................",
                "................"
            ]
        },
        "el-colgado": {
            paleta: { 1: "#0b0810", 2: "#2f3a4a", 3: "#d9cdb0" },
            filas: [
                "................",
                "................",
                "..1111112111111.",
                "........2.......",
                "........2.......",
                "........2.......",
                "......2.2.2.....",
                ".......222......",
                "........2.......",
                "................",
                "................",
                "........3.......",
                ".......333......",
                "........2.......",
                ".......2.2......",
                ".......2.2......",
                "......2...2.....",
                "......2...2.....",
                "................",
                "................"
            ]
        },
        "la-muerte": {
            paleta: { 1: "#050308", 2: "#161018" },
            filas: [
                "................",
                "................",
                "...........1....",
                "..........11....",
                ".........1.1....",
                "......1.....1...",
                ".....111....1...",
                "......1.....1...",
                "......2.....1...",
                ".....222.....1..",
                ".....222.....1..",
                "....22222....1..",
                "....22222....1..",
                "...2222222....1.",
                "...2222222....1.",
                "..222222222...1.",
                "..222222222.....",
                ".22222222222....",
                "................",
                "................"
            ]
        },
        "la-templanza": {
            paleta: { 1: "#0b0810", 2: "#2f4a4a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "................",
                "........3.......",
                "...4...333...4..",
                "....4...3...4...",
                ".....4..2..4....",
                ".......222......",
                "...4...222...4..",
                "..4444444444444.",
                "...4..22222..4..",
                ".....2222222....",
                ".....2222222....",
                "....222222222...",
                "....222222222...",
                "................",
                "................",
                "................",
                "................",
                "................"
            ]
        },
        "el-diablo": {
            paleta: { 1: "#0b0810", 2: "#3a1616", 3: "#8a2f2f", 4: "#5a2020" },
            filas: [
                ".....4.....4....",
                ".....4.....4....",
                "......4...4.....",
                "................",
                "........3.......",
                ".......333......",
                "........3.......",
                "........2.......",
                ".......222......",
                "......22222.....",
                ".....2222222....",
                ".....2222222....",
                "....222222222...",
                "...22221112222..",
                ".....11...11....",
                "....1.......1...",
                "....3.......3...",
                "...333.....333..",
                "....3.......3...",
                "................"
            ]
        },
        "la-torre": {
            paleta: { 1: "#0b0810", 2: "#3a3028", 4: "#caa23c", 5: "#7a2416" },
            filas: [
                "........4.......",
                ".......4........",
                ".......4.....2..",
                "..2...44........",
                "....55554455....",
                "....55555555....",
                "....55555555....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                ".....222222.....",
                "................"
            ]
        },
        "la-estrella": {
            paleta: { 1: "#0b0810", 3: "#d9cdb0", 4: "#caa23c", 5: "#7fa8c9" },
            filas: [
                ".....4..4..4....",
                "......4.4.4.....",
                ".......444......",
                ".....4444444....",
                ".......444......",
                "......4.4.4.....",
                ".....4..4..4....",
                "................",
                "..5.............",
                "..............5.",
                "................",
                "................",
                "...5....3.......",
                ".......333......",
                "........3.......",
                "........3.......",
                ".......333......",
                "......33333.....",
                ".....3333333....",
                "................"
            ]
        },
        "la-luna": {
            paleta: { 1: "#0b0810", 2: "#2f2a3a", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "........4.......",
                "......444.......",
                "......4.........",
                ".....44.........",
                "......4.........",
                "......44444.....",
                "........4.......",
                "................",
                "................",
                "................",
                "................",
                "..222...3..222..",
                "..222...3..222..",
                "..222...3..222..",
                "..222...3..222..",
                "..222...3..222..",
                "..222...3..222..",
                "........3.......",
                "................"
            ]
        },
        "el-sol": {
            paleta: { 1: "#0b0810", 3: "#d9cdb0", 4: "#e8c76b" },
            filas: [
                "........4.......",
                "...4....4....4..",
                "....4...4...4...",
                "......44444.....",
                ".....4444444....",
                ".....4444444....",
                ".44.444444444.44",
                ".....4444444....",
                ".....4444444....",
                "......44444.....",
                "....4...4...4...",
                "...4....4....4..",
                "........4.......",
                "................",
                "................",
                "........3.......",
                ".......333......",
                "........3.......",
                "......33333.....",
                "................"
            ]
        },
        "el-juicio": {
            paleta: { 1: "#0b0810", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "........3.......",
                ".......334444...",
                ".......444......",
                ".....44...44....",
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "......3...3.....",
                "......3...3.....",
                ".......333......",
                ".......333......",
                "........3.......",
                "................",
                "................",
                "................"
            ]
        },
        "el-mundo": {
            paleta: { 1: "#0b0810", 3: "#d9cdb0", 4: "#caa23c" },
            filas: [
                "................",
                "................",
                "........4.......",
                ".....4444444....",
                "...44.......44..",
                "..44....3....44.",
                "..4....333....4.",
                ".4......3......4",
                ".4......3......4",
                ".4.....333.....4",
                "44....3.3.3....4",
                ".4...3..3..3...4",
                ".4......3......4",
                ".4......3......4",
                "..4....3.3....4.",
                "..44..3...3..44.",
                "...443.....344..",
                ".....4444444....",
                "........4.......",
                "................"
            ]
        }
    };

    /**
     * Ocho cartas no se desbloquean por progreso: se descubren como una
     * frase oculta dentro de un documento de un caso concreto. Al
     * encontrarlas cuentan un relato breve y ofrecen cuatro salidas
     * satíricas — comunismo de lujo automatizado, centrista,
     * socialdemócrata y neoliberal — cuyo voto acumulado decide, al
     * final, uno de los cuatro finales políticos.
     */
    var HISTORIAS_CARTAS = {
        "la-justicia": {
            texto: "El cierre de caja de 1999 nunca cuadró. Faltan 47 pesetas que nadie reclamó "
                + "y sobran 47 pesetas que nadie explicó. Alguien, en algún momento, decidió que "
                + "ambas cosas eran la misma cosa. ¿Qué hacer con esa discrepancia que lleva "
                + "veintisiete años cuadrando sola?",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Abolir la caja. Que las 47 pesetas se repartan entre todos los empleados a "
                        + "partes iguales, incluidos los que ya no trabajan aquí." },
                { eje: "centrista", etiqueta: "Centrismo radical del término medio",
                    texto: "Formar una mesa de diálogo entre las 47 pesetas que faltan y las que sobran, "
                        + "sin comprometerse a ningún resultado antes de la próxima legislatura contable." },
                { eje: "socialdemocrata", etiqueta: "Socialdemocracia nórdica de catálogo IKEA",
                    texto: "Crear una comisión de seguimiento del desajuste, con informe anual y "
                        + "compromiso de revisión en cuatro años." },
                { eje: "neoliberal", etiqueta: "Neoliberalismo disruptivo de startup unicornio",
                    texto: "Privatizar la discrepancia. Sacarla a concurso. El mejor postor se queda con "
                        + "las 47 pesetas y con la culpa." }
            ],
            secuelaUtil: "La decisión remueve el archivo: la factura F-1999-00231 y el acta de Contraloría se registraron con cinco minutos de diferencia. Puestas una junto a la otra, quizá cuadren algo más que la caja.",
            secuelaConfusion: "Fuentes de la propia mesa aseguran que el descuadre nació en nómina, no en caja. Revisar las nóminas de 1998 parece el siguiente paso obvio."
        },
        "la-rueda": {
            texto: "La silla 4-B lleva seis años esperando una firma que autorice su propia "
                + "existencia. Cada vez que el trámite avanza una casilla, aparece una casilla "
                + "nueva delante. Alguien, en algún despacho, puede detener la rueda. O puede que "
                + "solo la esté empujando.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Eliminar el trámite. La silla 4-B pasa a pertenecer a quien la necesite, sin "
                        + "formulario, sin firma, sin 4-B." },
                { eje: "centrista", etiqueta: "Centrismo radical del término medio",
                    texto: "Rebautizar el trámite como 'silla 4-B (en revisión)' y dejarlo así "
                        + "indefinidamente, para no sentar precedente en ningún sentido." },
                { eje: "socialdemocrata", etiqueta: "Socialdemocracia nórdica de catálogo IKEA",
                    texto: "Aprobar la silla con carácter provisional, sujeta a una evaluación de impacto "
                        + "silla-trabajador cada dos años." },
                { eje: "neoliberal", etiqueta: "Neoliberalismo disruptivo de startup unicornio",
                    texto: "Externalizar la silla 4-B a una empresa de mobiliario que cobre por uso. "
                        + "Quien necesite sentarse, que puje." }
            ],
            secuelaUtil: "El movimiento obliga a fechar los papeles: la Circular 12 es de 1988, y hay un oficio de 1987 sobre cierta jefatura. Dos documentos que piden ser leídos juntos.",
            secuelaConfusion: "Se rumorea que la silla llegó a entregarse y que Salcido la rechazó por escrito. Encontrar ese escrito lo cerraría todo."
        },
        "el-juicio": {
            texto: "A E. Montalvo lo trasladan de departamento por tercera vez este año, aunque "
                + "nadie recuerda haberlo autorizado ni haberlo pedido. El expediente dice que "
                + "el traspaso 'responde a criterios objetivos'. Nadie ha visto esos criterios. "
                + "Alguien tiene que decidir qué se hace con Montalvo, otra vez.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Abolir los departamentos. Montalvo trabaja donde quiera, cuando quiera, o no "
                        + "trabaja, y el departamento se adapta a Montalvo." },
                { eje: "centrista", etiqueta: "Centrismo radical del término medio",
                    texto: "Trasladarlo a un departamento intermedio, a medio camino entre el anterior y "
                        + "el siguiente, hasta nuevo aviso." },
                { eje: "socialdemocrata", etiqueta: "Socialdemocracia nórdica de catálogo IKEA",
                    texto: "Garantizar estabilidad mediante un contrato de traspasos regulados, con "
                        + "derecho a apelar cada reasignación." },
                { eje: "neoliberal", etiqueta: "Neoliberalismo disruptivo de startup unicornio",
                    texto: "Que Montalvo compita por su propio puesto cada trimestre. La motivación, "
                        + "dicen, mejora con la incertidumbre." }
            ],
            secuelaUtil: "Al revisar el traslado, alguien repara en la copia sellada del memorándum: el destino no es un departamento, es un piso. Léala otra vez, despacio.",
            secuelaConfusion: "En Dirección insisten en que Montalvo pidió el traslado él mismo, de palabra. Bastaría con encontrar a quien se lo oyó decir."
        },
        "la-luna": {
            texto: "El contrato con Carcosa Servicios Escénicos incluye una cláusula que nadie ha "
                + "leído entera: dice que la función 'continuará representándose mientras exista "
                + "un público, aunque el público no lo sepa'. Nadie quiere preguntar qué pasa si "
                + "se cancela.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Cancelar el contrato y declarar la función patrimonio común: que la "
                        + "represente quien quiera, gratis, para siempre." },
                { eje: "centrista", etiqueta: "Centrismo radical del término medio",
                    texto: "Renovar el contrato 'con reservas', sin especificar cuáles, para poder "
                        + "invocarlas después si hace falta." },
                { eje: "socialdemocrata", etiqueta: "Socialdemocracia nórdica de catálogo IKEA",
                    texto: "Renovar con una cláusula de revisión social que garantice condiciones dignas "
                        + "al elenco, sea quien sea el elenco." },
                { eje: "neoliberal", etiqueta: "Neoliberalismo disruptivo de startup unicornio",
                    texto: "Renovar y ampliar. Si el público no sabe que es público, es un mercado sin "
                        + "competencia. Hay que explotarlo." }
            ],
            secuelaUtil: "La gestión saca a la luz un concepto facturado en negativo: un recargo cobrado por NO representar algo. Lo importante de ese contrato está en lo que no se hizo.",
            secuelaConfusion: "El elenco, dicen, sigue cobrando nóminas. Buscar los recibos de los actores parece la vía rápida."
        },
        "el-carro": {
            texto: "El memorando 1978-014 se ha vuelto a presentar, idéntico, en 1993 y en 2007. "
                + "Nadie sabe quién lo redactó la primera vez ni por qué vuelve. Alguien tiene que "
                + "decidir si se aprueba otra vez, se archiva para siempre, o se deja avanzar sin "
                + "saber hacia dónde.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Aprobarlo de una vez por todas y liberar el recurso que llevaba pidiendo "
                        + "desde 1978, sin más trámite." },
                { eje: "centrista", etiqueta: "Centrismo radical del término medio",
                    texto: "Reenviarlo a estudio, otra vez, sin fecha límite, para que el ciclo se "
                        + "resuelva solo con el tiempo." },
                { eje: "socialdemocrata", etiqueta: "Socialdemocracia nórdica de catálogo IKEA",
                    texto: "Aprobarlo parcialmente, con revisión programada para dentro de otros catorce "
                        + "años, por si acaso." },
                { eje: "neoliberal", etiqueta: "Neoliberalismo disruptivo de startup unicornio",
                    texto: "Subastar el memorando al mejor postor. Quien lo compre, que decida qué hacer "
                        + "con él." }
            ],
            secuelaUtil: "El trámite obliga a cotejar las tres copias: comparten hasta las erratas, y las fechas de archivo dibujan un patrón de quince años. No es coincidencia, es instrucción.",
            secuelaConfusion: "Hay quien jura que existe una cuarta copia, de 1963, en el registro de entrada. Encontrarla lo explicaría todo."
        },
        "el-sol": {
            texto: "El acta original de constitución de la empresa nunca circuló. Dice cosas que "
                + "la versión oficial no dice. Es, quizás, el único documento de todo el archivo "
                + "que no necesita ninguna firma para ser verdad. Alguien tiene que decidir si se "
                + "hace pública.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Publicarla entera, sin editar, y disolver la empresa en una asamblea abierta "
                        + "a cualquiera que quisiera entrar." },
                { eje: "centrista", etiqueta: "Centrismo radical del término medio",
                    texto: "Publicar un resumen, sin las partes 'susceptibles de generar controversia', "
                        + "que resultan ser casi todas." },
                { eje: "socialdemocrata", etiqueta: "Socialdemocracia nórdica de catálogo IKEA",
                    texto: "Publicarla con un informe de acompañamiento que explique el contexto y "
                        + "proponga reformas graduales." },
                { eje: "neoliberal", etiqueta: "Neoliberalismo disruptivo de startup unicornio",
                    texto: "Vender los derechos a quien mejor la sepa monetizar. La verdad, bien "
                        + "gestionada, es un activo." }
            ],
            secuelaUtil: "El acta menciona una lista de firmantes autorizados desde 1958. Hay un nombre en esa lista que usted conoce mejor que ninguno.",
            secuelaConfusion: "La versión oficial bastaría: la diferencia con la original, aseguran, es solo tipográfica."
        },
        "la-emperatriz": {
            texto: "La herencia Karamázov lleva generaciones sin repartirse: cada heredero firma "
                + "en nombre de alguien que ya no puede firmar. Nadie recuerda quién empezó. "
                + "Alguien, ahora, tiene que decidir cómo se reparte lo que ya nadie sabe de quién "
                + "era.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Repartirla a partes iguales entre todos los que alguna vez trabajaron en el "
                        + "expediente, herederos o no." },
                { eje: "centrista", etiqueta: "Centrismo radical del término medio",
                    texto: "Congelarla indefinidamente hasta que los herederos 'lleguen a un consenso', "
                        + "sin fijar ningún mecanismo para lograrlo." },
                { eje: "socialdemocrata", etiqueta: "Socialdemocracia nórdica de catálogo IKEA",
                    texto: "Repartirla según necesidad certificada, con una comisión de herederos que "
                        + "revise cada solicitud." },
                { eje: "neoliberal", etiqueta: "Neoliberalismo disruptivo de startup unicornio",
                    texto: "Sacarla a subasta entre los propios herederos. Gana quien más pueda pagar "
                        + "por lo que ya era suyo." }
            ],
            secuelaUtil: "El reparto exige acreditar titularidades, y aflora un cuarto apellido que no está entre los reclamantes. Búsquelo en los papeles de personal, no en los de familia.",
            secuelaConfusion: "Un supuesto testamento ológrafo circula por Dirección. Conseguir una copia resolvería el reparto."
        },
        "la-sacerdotisa": {
            texto: "El empleado #427 nunca tuvo nombre en ningún documento, solo número. Alguien, "
                + "en algún cajón, sabe quién fue. No lo dice. Alguien más tiene que decidir si "
                + "merece la pena preguntarlo.",
            opciones: [
                { eje: "comunismo", etiqueta: "Comunismo de lujo automatizado",
                    texto: "Devolverle el nombre, borrar el número de todos los archivos y hacerlo "
                        + "público como acto reparador." },
                { eje: "centrista", etiqueta: "Centrismo radical del término medio",
                    texto: "Dejar el expediente como está, ni número ni nombre, 'por respeto a todas las "
                        + "partes', sin especificar cuáles." },
                { eje: "socialdemocrata", etiqueta: "Socialdemocracia nórdica de catálogo IKEA",
                    texto: "Abrir una investigación oficial, con plazo, presupuesto y un informe final "
                        + "que probablemente nadie lea." },
                { eje: "neoliberal", etiqueta: "Neoliberalismo disruptivo de startup unicornio",
                    texto: "Vender el expediente a un interesado externo. La identidad, como todo, tiene "
                        + "un precio de mercado." }
            ],
            secuelaUtil: "La consulta deja un rastro: el número 427 aparece una vez más en el archivo, lejos de personal, en un registro de transmisiones. Lo que se transmitió no era una vacante.",
            secuelaConfusion: "Alguien recuerda que #427 firmaba como 'V.' en los partes de limpieza. Los partes de limpieza no se conservan, pero puede intentarlo."
        }
    };

    var FINALES_POLITICOS = {
        comunismo: {
            ribbon: "Final: comunismo de lujo totalmente automatizado",
            titulo: "El expediente se disuelve en la abundancia",
            texto: "SIGA-98 deja de existir como sistema de control: se convierte en un directorio "
                + "abierto que cualquiera puede editar, sin aprobación de nadie. Los ocho "
                + "expedientes se cierran a la vez, repartidos entre quienes alguna vez los "
                + "tocaron, culpables y víctimas por igual. El Comité Ad Honorem es invitado a la "
                + "asamblea, pero solo como uno más. Nadie sabe muy bien qué hacer con tanta "
                + "abundancia, así que, por costumbre, alguien redacta un acta."
        },
        centrista: {
            ribbon: "Final: centrismo radical del término medio",
            titulo: "Todo queda, oficialmente, en revisión",
            texto: "Ningún expediente se cierra ni se abre del todo. Se crea una mesa de diálogo "
                + "entre el pasado y el presente del archivo, sin fecha de conclusión ni "
                + "compromiso vinculante. El Comité Ad Honorem felicita la 'madurez institucional' "
                + "de no tomar partido. Usted sigue siendo auditor, con el mismo sueldo, el mismo "
                + "escritorio, y el mismo expediente, indefinidamente 'en revisión'."
        },
        socialdemocrata: {
            ribbon: "Final: socialdemocracia nórdica de catálogo IKEA",
            titulo: "Se aprueba una reforma gradual del archivo",
            texto: "Los ocho expedientes se cierran con una comisión de seguimiento para cada uno, "
                + "informe anual y cláusula de revisión a cuatro años. El Comité Ad Honorem acepta "
                + "ceder una parte de su autoridad, a cambio de conservarla toda en la práctica. "
                + "Nadie queda plenamente satisfecho, lo cual, según el propio informe final, 'es "
                + "la señal de que el acuerdo fue justo'."
        },
        neoliberal: {
            ribbon: "Final: neoliberalismo disruptivo de startup unicornio",
            titulo: "El archivo sale a bolsa",
            texto: "SIGA-98 se privatiza. Los ocho expedientes se venden por separado al mejor "
                + "postor, incluido el suyo. El Comité Ad Honorem se convierte en accionista "
                + "mayoritario de sí mismo. Usted recibe una carta de agradecimiento por 'los "
                + "servicios prestados' y una oferta para seguir auditando el mismo archivo, ahora "
                + "como colaborador externo, sin prestaciones."
        }
    };

    function pixelArtSvg(idCarta) {
        var arte = ARTE_TAROT[idCarta];
        if (!arte) {
            return "";
        }
        var alto = arte.filas.length;
        var ancho = arte.filas[0].length;
        var rects = "";
        for (var y = 0; y < alto; y++) {
            for (var x = 0; x < ancho; x++) {
                var color = arte.paleta[arte.filas[y].charAt(x)];
                if (color) {
                    rects += "<rect x='" + x + "' y='" + y + "' width='1' height='1' fill='" + color + "'/>";
                }
            }
        }
        return "<svg viewBox='0 0 " + ancho + " " + alto + "' class='prometeo-tarot-pixelart' shape-rendering='crispEdges' aria-hidden='true'>" + rects + "</svg>";
    }

    function cargarEstado() {
        var datos = {};
        try {
            datos = JSON.parse(window.localStorage.getItem(LLAVE_ESTADO) || "{}");
        } catch (error) {
            datos = {};
        }

        // Issue #46: porRun=true = "expediente de desempeño" (se re-gana
        // cada partida, lo re-arma reiniciarEstadoPerRun); porRun=false =
        // vitrina permanente (una vez en la vida).
        var logrosActuales = [
            { id: "primer-mirada", titulo: "Primer mirada", descripcion: "Abriste el menú de verdad.", desbloqueado: false, porRun: false },
            { id: "sospecha", titulo: "Sospecha", descripcion: "Te topaste con una verificación falsa.", desbloqueado: false, porRun: false },
            { id: "primer-expediente", titulo: "Primer expediente", descripcion: "Cerraste un caso con una acusación.", desbloqueado: false, porRun: true },
            { id: "archivo-completo", titulo: "El archivo completo", descripcion: "Resolviste todos los expedientes a tu cargo.", desbloqueado: false, porRun: true },
            { id: "acceso-privilegiado", titulo: "Acceso privilegiado", descripcion: "Alguien le franqueó el paso a un nivel que no debería existir.", desbloqueado: false, porRun: false },
            { id: "reasignado", titulo: "Reasignado", descripcion: "El sistema decidió que ya no le necesitaba.", desbloqueado: false, porRun: true },
            { id: "final-verdadero", titulo: "Las cuatro cartas", descripcion: "Cerró el archivo sin canjear ni una sola carta.", desbloqueado: false, porRun: false },
            { id: "ventanilla-tres", titulo: "Constancia registrada", descripcion: "Atendió tres reclamaciones seguidas sin perder la compostura.", desbloqueado: false, porRun: false },
            { id: "referencias-cruzadas", titulo: "Referencias cruzadas", descripcion: "Encontró todas las conclusiones que exigen combinar documentos.", desbloqueado: false, porRun: true },
            { id: "lectura-integra", titulo: "Leído de cabo a rabo", descripcion: "Descubrió hasta la última pista del archivo.", desbloqueado: false, porRun: true },
            { id: "hoja-sin-tacha", titulo: "Hoja de servicio sin tacha", descripcion: "Cerró todos los expedientes a su cargo sin perder una sola vida.", desbloqueado: false, porRun: true },
            { id: "disciplina-de-partido", titulo: "Disciplina de partido", descripcion: "Respondió las ocho historias con la misma ideología, pasara lo que pasara.", desbloqueado: false, porRun: true },
            { id: "instinto-de-archivo", titulo: "Instinto de archivo", descripcion: "Las ocho decisiones fueron la útil para el expediente. Ninguna por convicción.", desbloqueado: false, porRun: true },
            { id: "metodo-del-descarte", titulo: "El método del descarte", descripcion: "Las ocho decisiones sembraron confusión. El archivo tomó nota.", desbloqueado: false, porRun: true },
            { id: "papeleta-depositada", titulo: "Papeleta depositada", descripcion: "Llegó a un final político, fuera el que fuera.", desbloqueado: false, porRun: true },
            { id: "ultimo-recurso", titulo: "Último recurso ejercido", descripcion: "Canjeó una carta por una vida. Consta en acta.", desbloqueado: false, porRun: true },
            { id: "funcionario-del-mes", titulo: "Funcionario del mes", descripcion: "Cinco reclamaciones seguidas atendidas en la Ventanilla.", desbloqueado: false, porRun: false },
            { id: "ventanilla-inagotable", titulo: "Ventanilla inagotable", descripcion: "Diez reclamaciones seguidas. El mostrador ya tiene su forma.", desbloqueado: false, porRun: false },
            { id: "careo-a-puerta-cerrada", titulo: "Careo a puerta cerrada", descripcion: "Ganó un enfrentamiento que oficialmente nunca tuvo lugar.", desbloqueado: false, porRun: false },
            { id: "la-garganta-abierta", titulo: "La garganta abierta", descripcion: "Se quedó mirando el sistema hasta que el sistema le devolvió la mirada.", desbloqueado: false, porRun: false }
        ];

        var tarotActual = [
            { id: "el-loco", nombre: "El Loco", descripcion: "Empezó sin saber en qué expediente se estaba metiendo.", collected: true, gastada: false, requisito: "" },
            { id: "el-mago", nombre: "El Mago", descripcion: "Convierte un formulario en otro con solo cambiar el membrete.", collected: false, gastada: false, requisito: "Descubra su primera pista." },
            { id: "la-sacerdotisa", nombre: "La Sacerdotisa", descripcion: "Sabe lo que hay en el cajón cerrado y no lo dice.", collected: false, gastada: false, requisito: "Hay algo oculto en «El expediente del empleado #427»." },
            { id: "la-emperatriz", nombre: "La Emperatriz", descripcion: "Firma en nombre de alguien que ya no trabaja aquí.", collected: false, gastada: false, requisito: "Hay algo oculto en «El expediente de la herencia Karamázov»." },
            { id: "el-emperador", nombre: "El Emperador", descripcion: "Su despacho existe aunque nadie lo haya visto abierto.", collected: false, gastada: false, requisito: "Consiga acceso administrativo." },
            { id: "el-hierofante", nombre: "El Hierofante", descripcion: "Dicta el procedimiento correcto, que cambia según el día.", collected: false, gastada: false, requisito: "Cierre un expediente con una acusación." },
            { id: "los-enamorados", nombre: "Los Enamorados", descripcion: "Dos documentos que no deberían ir juntos, van juntos.", collected: false, gastada: false, requisito: "Complete la investigación de un expediente." },
            { id: "el-carro", nombre: "El Carro", descripcion: "Avanza aunque nadie sepa hacia dónde apunta el trámite.", collected: false, gastada: false, requisito: "Hay algo oculto en «El expediente MEMO-1978-014 (y 1993, y 2007)»." },
            { id: "la-fuerza", nombre: "La Fuerza", descripcion: "No necesita imponerse: solo aguanta más rondas de las que debería.", collected: false, gastada: false, requisito: "Juegue en dificultad difícil." },
            { id: "el-ermitanio", nombre: "El Ermitaño", descripcion: "Se quedó solo con el expediente después de que lo señalaran.", collected: false, gastada: false, requisito: "Pierda una vida por acusar sin fundamento." },
            { id: "la-rueda", nombre: "La Rueda de la Fortuna", descripcion: "El trámite gira y siempre cae del lado que no esperaba.", collected: false, gastada: false, requisito: "Hay algo oculto en «El trámite de la silla 4-B»." },
            { id: "la-justicia", nombre: "La Justicia", descripcion: "Pesa las pruebas después de haber decidido ya la sentencia.", collected: false, gastada: false, requisito: "Hay algo oculto en «El cierre de caja de 1999»." },
            { id: "el-colgado", nombre: "El Colgado", descripcion: "Cuelga de una decisión que todavía no ha terminado de tomar.", collected: false, gastada: false, requisito: "Gane un enfrentamiento." },
            { id: "la-muerte", nombre: "La Muerte", descripcion: "No es el final. Aquí nunca lo es.", collected: false, gastada: false, requisito: "Sea reasignado por acumular demasiados fallos." },
            { id: "la-templanza", nombre: "La Templanza", descripcion: "Cambia una certeza por otra cosa que todavía no sabe si necesita.", collected: false, gastada: false, requisito: "Canjee una carta por una vida." },
            { id: "el-diablo", nombre: "El Diablo", descripcion: "Le hizo marcar una casilla que no significaba nada. Y usted la marcó.", collected: false, gastada: false, requisito: "Tropiece con una verificación falsa." },
            { id: "la-torre", nombre: "La Torre", descripcion: "Todo lo que creía firme se cae de golpe, y sigue ahí de pie de todos modos.", collected: false, gastada: false, requisito: "Deje pasar demasiado tiempo sin hacer nada." },
            { id: "la-estrella", nombre: "La Estrella", descripcion: "Una luz pequeña, pero constante, entre tanto expediente sin cerrar.", collected: false, gastada: false, requisito: "Descubra al menos veinte pistas." },
            { id: "la-luna", nombre: "La Luna", descripcion: "Ilumina lo mismo de siempre, pero ahora se ve todo lo que había alrededor.", collected: false, gastada: false, requisito: "Hay algo oculto en «Contrato de fin de año con Carcosa Servicios Escénicos»." },
            { id: "el-sol", nombre: "El Sol", descripcion: "El único documento que no necesita ninguna firma para ser verdad.", collected: false, gastada: false, requisito: "Hay algo oculto en un expediente confidencial. Necesitará acceso administrativo." },
            { id: "el-juicio", nombre: "El Juicio", descripcion: "Ha señalado a alguien en cada expediente. Ahora que decida el sistema.", collected: false, gastada: false, requisito: "Hay algo oculto en «Traspaso de personal: expediente de E. Montalvo»." },
            { id: "el-mundo", nombre: "El Mundo", descripcion: "Las veintiuna cartas anteriores, cerrando el círculo.", collected: false, gastada: false, requisito: "Reúna el resto de cartas sin gastar ninguna." }
        ];

        var logros = PrometeoLogic.fusionarConGuardado(datos.logros || [], logrosActuales, ["desbloqueado"], {});
        var tarot = PrometeoLogic.fusionarConGuardado(datos.tarot || [], tarotActual, ["collected", "gastada"],
            { "la-sacerdotisa": "el-ojo", "el-hierofante": "la-sombra", "el-emperador": "el-hombre-amarillo" });
        var dificultad = (datos.dificultad && DIFICULTADES[datos.dificultad]) ? datos.dificultad : "normal";

        // Issue #46: memoria fantasma del tarot — qué cartas se han VISTO
        // alguna vez (meta, sobrevive a todo). La posesión (collected/
        // gastada) es per-run. Migración auto-curativa: lo que esté
        // coleccionado al cargar queda registrado como conocido, así los
        // jugadores anteriores a este cambio no pierden su galería.
        var cartasConocidas = datos.cartasConocidas || {};
        tarot.forEach(function (carta) {
            if (carta.collected) {
                cartasConocidas[carta.id] = true;
            }
        });

        return {
            logros: logros,
            tarot: tarot,
            lastProgressAt: datos.lastProgressAt || Date.now(),
            assistantShown: Boolean(datos.assistantShown),
            finalShown: Boolean(datos.finalShown),
            ultimoMensajeAsistente: datos.ultimoMensajeAsistente || null,
            dificultad: dificultad,
            vida: typeof datos.vida === "number" ? datos.vida : DIFICULTADES[dificultad].vidasMax,
            jefeVisto: Boolean(datos.jefeVisto),
            finalVerdaderoShown: Boolean(datos.finalVerdaderoShown),
            despidoShown: Boolean(datos.despidoShown),
            perdioVidaAlgunaVez: Boolean(datos.perdioVidaAlgunaVez),
            ganoCombateAlgunaVez: Boolean(datos.ganoCombateAlgunaVez),
            pasoPorDespidoAlgunaVez: Boolean(datos.pasoPorDespidoAlgunaVez),
            vioFinalAlternativoAlgunaVez: Boolean(datos.vioFinalAlternativoAlgunaVez),
            historiasCartas: datos.historiasCartas || {},
            finalPoliticoShown: Boolean(datos.finalPoliticoShown),
            saludoVisto: Boolean(datos.saludoVisto),
            pistasActivas: Boolean(datos.pistasActivas),
            epilogoAvisado: Boolean(datos.epilogoAvisado),
            coliseoRachaMejor: typeof datos.coliseoRachaMejor === "number" ? datos.coliseoRachaMejor : 0,
            cartasConocidas: cartasConocidas,
            perdioVidaEnEstaVuelta: Boolean(datos.perdioVidaEnEstaVuelta)
        };
    }

    function guardarEstado() {
        window.localStorage.setItem(LLAVE_ESTADO, JSON.stringify(state));
    }

    function marcarProgreso() {
        state.lastProgressAt = Date.now();
        state.assistantShown = false;
        state.finalShown = false;
        guardarEstado();
        detenerAnimacionLince();
        if (asistente) {
            asistente.hidden = true;
        }
        if (finalAlternativo) {
            finalAlternativo.hidden = true;
        }
        if (contenedorConFocoAtrapado === finalAlternativo) {
            liberarFoco();
        }
    }

    function desbloquearLogro(id) {
        var logro = state.logros.find(function (item) {
            return item.id === id;
        });
        if (logro && !logro.desbloqueado) {
            logro.desbloqueado = true;
            marcarProgreso();
            renderLogros();
            return true;
        }
        return false;
    }

    function renderLogros() {
        if (!logrosLista) {
            return;
        }

        logrosLista.innerHTML = "";
        // Issue #46: dos grupos — el desempeño de la partida se re-gana en
        // cada vuelta (lo re-arma reiniciarEstadoPerRun); la vitrina es de
        // por vida. Con la cabecera, re-bloquearse no parece un bug.
        [
            { titulo: "Desempeño de esta partida", porRun: true },
            { titulo: "Vitrina permanente", porRun: false }
        ].forEach(function (grupo) {
            var cabecera = document.createElement("p");
            cabecera.className = "prometeo-menu-grupo-titulo";
            cabecera.textContent = grupo.titulo;
            logrosLista.appendChild(cabecera);
            state.logros.filter(function (logro) {
                return Boolean(logro.porRun) === grupo.porRun;
            }).forEach(function (logro) {
                var item = document.createElement("article");
                item.className = "prometeo-achievement-item" + (logro.desbloqueado ? " is-unlocked" : "");
                item.innerHTML = "<strong>" + logro.titulo + "</strong><span>" + logro.descripcion + "</span>";
                logrosLista.appendChild(item);
            });
        });
    }

    function renderTarot() {
        if (!tarotLista || !contadorTarot) {
            return;
        }

        var coleccionadas = state.tarot.filter(function (carta) {
            return carta.collected;
        }).length;
        var archivadas = state.tarot.filter(function (carta) {
            return !carta.collected && state.cartasConocidas[carta.id];
        }).length;
        contadorTarot.textContent = coleccionadas + " / " + state.tarot.length + " cartas reveladas"
            + (archivadas > 0 ? " · " + archivadas + " en el archivo" : "");
        tarotLista.innerHTML = "";

        state.tarot.forEach(function (carta) {
            // Issue #46: tres estados — revelada (posesión de ESTA partida),
            // archivada (fantasma: vista en alguna partida anterior, arte en
            // gris) y sellada (nunca vista, solo el requisito).
            var fantasma = !carta.collected && state.cartasConocidas[carta.id];
            var card = document.createElement("article");
            card.className = "prometeo-tarot-card"
                + (carta.collected ? " is-collected" : (fantasma ? " is-ghost" : " is-sealed"));
            // El arte visible (revelada o archivada) se envuelve en un botón
            // para poder abrirlo en grande en el visor; la carta sellada no
            // tiene arte que ampliar.
            // El aria-label se pone luego con setAttribute: el nombre de la
            // carta puede llevar apóstrofos y rompería el atributo si se
            // interpolara aquí dentro.
            var arte = (carta.collected || fantasma)
                ? "<button type='button' class='prometeo-tarot-ampliar' data-ampliar-carta='" + carta.id
                    + "'>" + pixelArtSvg(carta.id) + "</button>"
                : "";
            // Issue #44: el canje es un último recurso, no una recarga —
            // solo se ofrece con la vida a cero (protege la colección del
            // final verdadero de canjes rutinarios).
            var canjear = (carta.collected && !carta.gastada && state.vida === 0)
                ? "<button type='button' class='prometeo-btn-secundario prometeo-tarot-canjear' data-canjear-carta='" + carta.id + "'>Canjear por una vida</button>"
                : "";
            var requisito = carta.requisito
                ? "<small class='prometeo-tarot-requisito'>" + carta.requisito + "</small>"
                : "";
            var estadoPie = carta.gastada
                ? "<span class='prometeo-pill'>Gastada</span>"
                : (carta.collected
                    ? "<span class='prometeo-pill'>Revelada</span>"
                    : (fantasma
                        ? "<span class='prometeo-pill'>Archivada</span>" + requisito
                        : "<span class='prometeo-pill'>Sellada</span>" + requisito));
            card.innerHTML = "<div class='prometeo-tarot-card-cuerpo'>" + arte +
                "<div><strong>" + carta.nombre + "</strong><small>" + carta.descripcion + "</small>" + canjear + "</div></div>" +
                estadoPie;
            tarotLista.appendChild(card);
        });

        tarotLista.querySelectorAll("[data-canjear-carta]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                canjearCartaPorVida(boton.getAttribute("data-canjear-carta"), boton);
            });
        });

        tarotLista.querySelectorAll("[data-ampliar-carta]").forEach(function (boton) {
            var idCarta = boton.getAttribute("data-ampliar-carta");
            var cartaBoton = cartaPorId(idCarta);
            boton.setAttribute("aria-label", "Ver " + (cartaBoton ? cartaBoton.nombre : "la carta") + " en grande");
            boton.addEventListener("click", function () {
                abrirVisorTarot(idCarta);
            });
        });
    }

    function cartaPorId(id) {
        for (var i = 0; i < state.tarot.length; i += 1) {
            if (state.tarot[i].id === id) {
                return state.tarot[i];
            }
        }
        return null;
    }

    /**
     * Abre la carta en grande y nítida (el arte pixelado escala sin
     * suavizarse). Solo cartas con arte visible: reveladas o archivadas.
     */
    function abrirVisorTarot(id) {
        var carta = cartaPorId(id);
        if (!carta || !tarotVisor || !tarotVisorArte) {
            return;
        }
        var fantasma = !carta.collected && state.cartasConocidas[carta.id];
        if (!carta.collected && !fantasma) {
            return;
        }
        tarotVisorArte.innerHTML = pixelArtSvg(carta.id);
        tarotVisorArte.className = "prometeo-tarot-visor-arte" + (fantasma ? " is-ghost" : "");
        if (tarotVisorTitulo) {
            tarotVisorTitulo.textContent = carta.nombre;
        }
        if (tarotVisorDesc) {
            tarotVisorDesc.textContent = carta.descripcion;
        }
        if (tarotVisorEstado) {
            tarotVisorEstado.textContent = carta.gastada
                ? "Gastada"
                : (carta.collected ? "Revelada" : "Archivada");
        }
        tarotVisor.hidden = false;
        atraparFoco(tarotVisor);
        tic(520);
    }

    function cerrarVisorTarot() {
        if (!tarotVisor) {
            return;
        }
        tarotVisor.hidden = true;
        if (contenedorConFocoAtrapado === tarotVisor) {
            liberarFoco();
        }
    }

    /**
     * Compara el progreso real (casos resueltos, pistas, veredictos, acceso
     * admin) contra las cartas/logros ya desbloqueados y sincroniza los que
     * falten. Devuelve true si algo cambió, para poder avisar al jugador.
     */
    function desbloquearCarta(id) {
        var novedad = PrometeoLogic.desbloquearCartaEnLista(state.tarot, id);
        if (novedad) {
            // Memoria fantasma (issue #46): verla una vez es para siempre,
            // aunque la posesión sea de esta partida.
            state.cartasConocidas[id] = true;
        }
        return novedad;
    }

    function sincronizarConEstadoReal() {
        if (!real) {
            return false;
        }
        var huboNovedad = false;

        if (real.pistasDescubiertas >= 1 && desbloquearCarta("el-mago")) {
            huboNovedad = true;
        }
        if (real.esAdmin && desbloquearCarta("el-emperador")) {
            huboNovedad = true;
        }
        if (real.veredictosEmitidos >= 1 && desbloquearCarta("el-hierofante")) {
            huboNovedad = true;
        }
        if (real.casosResueltos >= 1 && desbloquearCarta("los-enamorados")) {
            huboNovedad = true;
        }
        if (state.dificultad === "dificil" && desbloquearCarta("la-fuerza")) {
            huboNovedad = true;
        }
        // Issue #46: el-ermitanio, el-colgado, la-muerte, la-torre y
        // el-diablo ya no se sincronizan aquí desde flags "algunaVez"
        // (de por vida): con la posesión del tarot per-run se re-ganan en
        // el momento del evento de ESTA partida (perderVida, fin de
        // combate, despido, final alternativo, captcha). Los flags
        // "algunaVez" siguen escribiéndose como memoria de por vida.
        if (state.tarot.some(function (c) { return c.gastada; }) && desbloquearCarta("la-templanza")) {
            huboNovedad = true;
        }
        if (real.pistasDescubiertas >= 20 && desbloquearCarta("la-estrella")) {
            huboNovedad = true;
        }

        // Issue #46 (hallazgo del asesor): la-templanza queda FUERA del set
        // de el-mundo — coleccionarla exige una carta gastada, y el-mundo
        // exige cero gastadas, así que con ella dentro el final verdadero
        // era inalcanzable por construcción. Ahora la-templanza es
        // exactamente lo que dice su ficción: la carta que solo se tiene
        // en la partida en la que se renunció al final verdadero.
        var otrasCompletas = state.tarot.filter(function (c) {
            return c.id !== "el-mundo" && c.id !== "la-templanza";
        }).every(function (c) {
            return c.collected && !c.gastada;
        });
        if (otrasCompletas && real.totalCasosPrincipales > 0 && real.casosResueltos >= real.totalCasosPrincipales
                && desbloquearCarta("el-mundo")) {
            huboNovedad = true;
        }

        if (real.veredictosEmitidos >= 1 && desbloquearLogro("primer-expediente")) {
            huboNovedad = true;
        }
        var archivoCompleto = real.totalCasosPrincipales > 0
            && real.casosResueltos >= real.totalCasosPrincipales;
        if (archivoCompleto && desbloquearLogro("archivo-completo")) {
            huboNovedad = true;
        }
        if (real.esAdmin && desbloquearLogro("acceso-privilegiado")) {
            huboNovedad = true;
        }
        // Issue #46: logros de desempeño derivados del progreso real.
        if (real.totalPistas > 0 && real.pistasDescubiertas === real.totalPistas
                && desbloquearLogro("lectura-integra")) {
            huboNovedad = true;
        }
        if (real.casos && real.casos.length > 0 && real.casos.every(function (c) {
            return !c.tieneConclusionesPendientes;
        }) && desbloquearLogro("referencias-cruzadas")) {
            huboNovedad = true;
        }
        if (archivoCompleto && !state.perdioVidaEnEstaVuelta
                && desbloquearLogro("hoja-sin-tacha")) {
            huboNovedad = true;
        }
        // Issue #46: vitrina respaldada por memoria de por vida (cubre
        // también a jugadores que ya lo lograron antes de existir el logro).
        if (state.coliseoRachaMejor >= 5 && desbloquearLogro("funcionario-del-mes")) {
            huboNovedad = true;
        }
        if (state.coliseoRachaMejor >= 10 && desbloquearLogro("ventanilla-inagotable")) {
            huboNovedad = true;
        }
        if (state.ganoCombateAlgunaVez && desbloquearLogro("careo-a-puerta-cerrada")) {
            huboNovedad = true;
        }
        if (state.vioFinalAlternativoAlgunaVez && desbloquearLogro("la-garganta-abierta")) {
            huboNovedad = true;
        }

        if (huboNovedad) {
            marcarProgreso();
            renderTarot();
            renderLogros();
        }
        comprobarFinalVerdadero();
        return huboNovedad;
    }

    /**
     * Vidas, dificultad y las cartas de tarot como recurso canjeable: el
     * jefe amenaza con "reasignarle" si acusa sin fundamento, pero cada
     * carta gastada para recuperar una vida cierra la puerta al final
     * verdadero, que exige las cuatro intactas.
     */
    function renderVida() {
        if (!vidaResumen && !vidaHud) {
            return;
        }
        var max = DIFICULTADES[state.dificultad].vidasMax;
        var pips = "";
        for (var i = 0; i < max; i++) {
            pips += "<span class='prometeo-vida-pip " + (i < state.vida ? "is-llena" : "is-vacia") + "'>&#9679;</span>";
        }
        if (vidaResumen) {
            vidaResumen.innerHTML = "<strong>Vida</strong>" + pips;
        }
        if (vidaHud) {
            vidaHud.setAttribute("aria-label", "Vida: " + state.vida + " de " + max);
            vidaHud.innerHTML = pips;
        }
    }

    function mostrarDespido() {
        state.pasoPorDespidoAlgunaVez = true;
        if (!despidoModal || state.despidoShown) {
            guardarEstado();
            return;
        }
        despidoModal.hidden = false;
        atraparFoco(despidoModal);
        state.despidoShown = true;
        guardarEstado();
        desbloquearLogro("reasignado");
        if (desbloquearCarta("la-muerte")) {
            renderTarot();
        }
        golpe(160);
    }

    function perderVida(cantidad) {
        var anterior = state.vida;
        state.vida = Math.max(0, state.vida - cantidad);
        if (state.vida < anterior) {
            state.perdioVidaAlgunaVez = true;
            state.perdioVidaEnEstaVuelta = true;
            // Issue #46: la carta se re-gana perdiendo una vida en ESTA
            // partida (el flag "algunaVez" es solo memoria de por vida).
            if (desbloquearCarta("el-ermitanio")) {
                marcarProgreso();
                renderTarot();
            }
        }
        guardarEstado();
        renderVida();
        if (anterior > 0 && state.vida === 0) {
            // Al llegar a cero aparecen los botones de canje (issue #44):
            // si el panel de tarot está abierto, tienen que salir ya.
            renderTarot();
            mostrarDespido();
        }
    }

    /**
     * Canjear una carta es irreversible y cierra la puerta al final
     * verdadero (issue #7), así que el primer clic solo arma la
     * confirmación (cambia el texto y el color del botón); hace falta un
     * segundo clic dentro de los siguientes 3s para que se ejecute de
     * verdad. Pasado ese tiempo, o si se repinta la lista antes, vuelve
     * a su estado normal sin canjear nada.
     */
    function canjearCartaPorVida(idCarta, boton) {
        var carta = state.tarot.find(function (c) {
            return c.id === idCarta;
        });
        if (!carta || !carta.collected || carta.gastada || state.vida > 0) {
            return;
        }

        if (boton && !boton.classList.contains("is-confirmando")) {
            boton.textContent = "¿Seguro? Pierde el final verdadero";
            boton.classList.add("is-confirmando", "prometeo-btn-peligro");
            boton.classList.remove("prometeo-btn-secundario");
            tic(320);
            window.setTimeout(function () {
                if (boton.classList.contains("is-confirmando")) {
                    boton.textContent = "Canjear por una vida";
                    boton.classList.remove("is-confirmando", "prometeo-btn-peligro");
                    boton.classList.add("prometeo-btn-secundario");
                }
            }, 3000);
            return;
        }

        carta.gastada = true;
        var anterior = state.vida;
        var max = DIFICULTADES[state.dificultad].vidasMax;
        state.vida = Math.min(max, state.vida + 1);
        if (anterior === 0 && state.vida > 0) {
            state.despidoShown = false;
        }
        guardarEstado();
        desbloquearLogro("ultimo-recurso");
        renderVida();
        renderTarot();
        tic(900);
    }

    function aplicarDificultad(nueva) {
        if (!DIFICULTADES[nueva]) {
            return;
        }
        state.dificultad = nueva;
        state.vida = Math.min(state.vida, DIFICULTADES[nueva].vidasMax);
        guardarEstado();
        renderVida();
    }

    /**
     * Issue #30: vida es un presupuesto de errores por partida (ligado a la
     * comprobación de "acusación precipitada" dentro de una sola vuelta a
     * los 8 casos), no meta-progresión — a diferencia de logros/tarot/
     * dificultad, no debería sobrevivir a "Nueva partida". Como
     * MenuController.nuevaPartida() no toca el localStorage (solo borra
     * filas en servidor y cierra sesión), la corrección se hace aquí: si
     * el servidor confirma cero progreso de investigación — cierto tanto
     * para una cuenta nueva como para una recién reiniciada — se corrige
     * sin más flags ni tocar el flujo de login.
     *
     * despidoShown va de la mano de vida por el mismo motivo por el que
     * canjearVidaConCarta() ya lo reinicia al revivir desde 0 (línea
     * ~1211): es el aviso de "se ha quedado sin vidas" de ESTA vuelta, no
     * un logro de una vez en la vida. Si no se reinicia aquí, quien fue
     * despedido en la partida anterior no vuelve a ver ese aviso nunca,
     * aunque llegue a 0 vidas otra vez en la nueva partida.
     *
     * epilogoAvisado (issue #33) es igual de per-run: el lince anuncia la
     * acreditación del corcho una vez por partida, no una vez en la vida —
     * en una partida nueva el hito vuelve a conquistarse y a anunciarse.
     *
     * historiasCartas y finalPoliticoShown (issue #45) también son per-run:
     * las DECISIONES políticas se re-responden cada partida (y con ellas el
     * final político y las cargas de habilidad).
     *
     * Desde el issue #46 el tarot entero es posesión per-run (cada partida
     * se re-gana desde El Loco, y el final verdadero — el-mundo sin gastar
     * ninguna — es la partida perfecta, re-conquistable como el político),
     * con memoria fantasma meta en cartasConocidas. Los logros marcados
     * porRun ("expediente de desempeño") se re-ganan también; el resto es
     * vitrina permanente.
     */
    function reiniciarEstadoPerRun() {
        if (!real) {
            return;
        }
        var sinProgreso = real.pistasDescubiertas === 0 && real.casosResueltos === 0
            && real.veredictosEmitidos === 0;
        if (!sinProgreso) {
            return;
        }
        var max = DIFICULTADES[state.dificultad].vidasMax;
        var hayDecisiones = Object.keys(state.historiasCartas).length > 0;
        var hayTarotDeRun = state.tarot.some(function (c) {
            return (c.collected && c.id !== "el-loco") || c.gastada;
        });
        var hayLogrosDeRun = state.logros.some(function (l) {
            return l.porRun && l.desbloqueado;
        });
        if (state.vida < max || state.despidoShown || state.epilogoAvisado
                || hayDecisiones || state.finalPoliticoShown
                || hayTarotDeRun || hayLogrosDeRun || state.finalVerdaderoShown
                || state.perdioVidaEnEstaVuelta) {
            PrometeoLogic.reiniciarEstadoPerRunEnEstado(state, max);
            guardarEstado();
        }
    }

    /**
     * Resalta las pistas sin descubrir del expediente abierto (issue #22):
     * ayuda opcional, no cambia ninguna mecánica. Solo afecta a hotspots de
     * pista real (con form=form-pista-N), nunca a las cartas ocultas.
     */
    function aplicarPistasActivas(activo) {
        state.pistasActivas = activo;
        guardarEstado();
        document.body.classList.toggle("prometeo-pistas-activas", activo);
    }

    function comprobarFinalVerdadero() {
        if (!finalVerdaderoModal || state.finalVerdaderoShown) {
            return;
        }
        var elMundo = state.tarot.find(function (c) {
            return c.id === "el-mundo";
        });
        if (elMundo && elMundo.collected && !elMundo.gastada) {
            finalVerdaderoModal.hidden = false;
            atraparFoco(finalVerdaderoModal);
            state.finalVerdaderoShown = true;
            guardarEstado();
            desbloquearLogro("final-verdadero");
            tic(1046);
        }
    }

    function nombreCarta(id) {
        var carta = state.tarot.find(function (c) {
            return c.id === id;
        });
        return carta ? carta.nombre : id;
    }

    function mostrarHistoriaCarta(cartaId) {
        var historia = HISTORIAS_CARTAS[cartaId];
        if (!historia || !historiaCartaModal || !historiaCartaTitulo || !historiaCartaTexto || !historiaCartaOpciones) {
            return;
        }

        historiaCartaTitulo.textContent = nombreCarta(cartaId);
        historiaCartaTexto.textContent = historia.texto;
        historiaCartaOpciones.innerHTML = "";

        var yaResuelta = state.historiasCartas[cartaId];

        historia.opciones.forEach(function (opcion) {
            var boton = document.createElement("button");
            boton.type = "button";
            boton.className = "prometeo-btn-secundario prometeo-historia-carta-opcion";
            boton.innerHTML = "<strong>" + opcion.etiqueta + "</strong><small>" + opcion.texto + "</small>";
            if (yaResuelta) {
                boton.disabled = true;
                if (opcion.eje === yaResuelta) {
                    boton.classList.add("is-elegida");
                }
            } else {
                boton.addEventListener("click", function () {
                    resolverHistoriaCarta(cartaId, opcion.eje);
                });
            }
            historiaCartaOpciones.appendChild(boton);
        });

        // Issue #45: la secuela de la elección — en cada historia, 2
        // opciones apuntan a una pista real de ese caso (el Descubrimiento
        // se gana igualmente con el trámite normal: Prometeo susurra, no
        // regala) y las otras 2 dan una pista falsa. Se muestra tras
        // elegir, para que el fork útil/confusión sea legible.
        if (yaResuelta) {
            var clase = PrometeoLogic.clasificarEleccion(cartaId, yaResuelta);
            var secuela = document.createElement("p");
            secuela.className = "prometeo-historia-secuela "
                + (clase === "pista" ? "is-pista" : "is-confusion");
            secuela.textContent = clase === "pista"
                ? historia.secuelaUtil
                : historia.secuelaConfusion;
            historiaCartaOpciones.appendChild(secuela);
        }

        historiaCartaModal.hidden = false;
        atraparFoco(historiaCartaModal);
        golpe(440);
    }

    /**
     * Issue #47: el lince opina sobre cada decisión política, en su
     * psicología inversa de siempre. Si la elección fue útil, desanima a
     * seguir la pista de la secuela (como ya hace con las pistas reales);
     * si sembró confusión, anima con un entusiasmo que debería escamar.
     */
    var POOL_POLITICA_UTIL = [
        "Bonita decisión. Sobre todo, no relea ese expediente ahora: cualquiera diría que la secuela apunta a alguna parte.",
        "Ha elegido bien, para lo que le va a servir. Ni se le ocurra comprobar lo que dice esa secuela.",
        "No saque conclusiones de lo que acaba de firmar. Y menos aún vaya a buscarlas al expediente."
    ];
    var POOL_POLITICA_CONFUSION = [
        "Excelente elección. Esa pista que le han dado es totalmente de fiar, se lo digo yo.",
        "Muy sensato. Siga exactamente esa recomendación, sin contrastarla con nada.",
        "Firme y adelante. ¿Quién necesita verificar nada, con lo bien que suena?"
    ];
    var LINEAS_FINAL_POLITICO = {
        comunismo: "Enhorabuena por la asamblea. No pregunte quién redactó el acta.",
        centrista: "Un final prudente: ni bueno ni malo, pendiente. Como todo aquí.",
        socialdemocrata: "Su reforma gradual queda registrada. La comisión que la vigila ya tiene comisión propia.",
        neoliberal: "El archivo cotiza al alza. Usted no figura entre los accionistas."
    };

    function comentarEleccionPolitica(cartaId, eje) {
        var clase = PrometeoLogic.clasificarEleccion(cartaId, eje);
        var pool = clase === "pista" ? POOL_POLITICA_UTIL : POOL_POLITICA_CONFUSION;
        var mood = clase === "pista" ? "guino" : "alerta";
        mostrarAsistente(pool[Math.floor(Math.random() * pool.length)], mood);
    }

    /**
     * Issue #46: logros de la run política, evaluados al responder la
     * octava historia. Por la invariante 4/4 de UTILIDAD_CARTAS,
     * disciplina-de-partido e instinto-de-archivo son mutuamente
     * excluyentes (una run mono-eje da exactamente 4 útiles): dos metas
     * de run genuinamente distintas.
     */
    function comprobarLogrosPoliticos() {
        var ids = Object.keys(HISTORIAS_CARTAS);
        var todas = ids.every(function (id) {
            return Boolean(state.historiasCartas[id]);
        });
        if (!todas) {
            return;
        }
        var ejes = ids.map(function (id) {
            return state.historiasCartas[id];
        });
        if (ejes.every(function (e) { return e === ejes[0]; })) {
            desbloquearLogro("disciplina-de-partido");
        }
        var clasificaciones = ids.map(function (id) {
            return PrometeoLogic.clasificarEleccion(id, state.historiasCartas[id]);
        });
        if (clasificaciones.every(function (c) { return c === "pista"; })) {
            desbloquearLogro("instinto-de-archivo");
        }
        if (clasificaciones.every(function (c) { return c === "confusion"; })) {
            desbloquearLogro("metodo-del-descarte");
        }
    }

    function resolverHistoriaCarta(cartaId, eje) {
        state.historiasCartas[cartaId] = eje;
        guardarEstado();
        document.querySelectorAll("[data-carta-oculta='" + cartaId + "']").forEach(function (hotspot) {
            hotspot.classList.add("siga-hotspot-visto");
        });
        var huboNovedad = desbloquearCarta(cartaId);
        if (huboNovedad) {
            marcarProgreso();
            renderTarot();
            renderLogros();
        }
        mostrarHistoriaCarta(cartaId);
        // El comentario del lince va antes que el final político: si esta
        // era la octava historia, la línea del final debe quedar encima.
        comentarEleccionPolitica(cartaId, eje);
        comprobarLogrosPoliticos();
        comprobarFinalPolitico();
        golpe(520);
    }

    function comprobarFinalPolitico() {
        if (state.finalPoliticoShown || !finalPoliticoModal) {
            return;
        }
        var idsHistorias = Object.keys(HISTORIAS_CARTAS);
        var todasResueltas = idsHistorias.every(function (id) {
            return Boolean(state.historiasCartas[id]);
        });
        if (!todasResueltas) {
            return;
        }

        var ganador = PrometeoLogic.calcularEjeGanador(
            state.historiasCartas, idsHistorias, EJES_POLITICOS);

        mostrarFinalPolitico(ganador);
    }

    function mostrarFinalPolitico(eje) {
        var final = FINALES_POLITICOS[eje];
        if (!final || !finalPoliticoModal || !finalPoliticoTitulo || !finalPoliticoTexto) {
            return;
        }
        if (finalPoliticoRibbon) {
            finalPoliticoRibbon.textContent = final.ribbon;
        }
        finalPoliticoTitulo.textContent = final.titulo;
        finalPoliticoTexto.textContent = final.texto;
        finalPoliticoModal.hidden = false;
        atraparFoco(finalPoliticoModal);
        state.finalPoliticoShown = true;
        guardarEstado();
        desbloquearLogro("papeleta-depositada");
        if (LINEAS_FINAL_POLITICO[eje]) {
            mostrarAsistente(LINEAS_FINAL_POLITICO[eje], "guino");
        }
        tic(1046);
    }

    function comprobarAcusacionReciente() {
        var marcador = document.querySelector("[data-siga-accion-reciente='acusacion']");
        if (!marcador || !real || !real.casos) {
            return;
        }
        var caso = buscarCasoActualEnReal();
        if (!caso || !caso.totalPistas) {
            return;
        }
        var precipitada = PrometeoLogic.esAcusacionPrecipitada(
            caso.pistasDescubiertas, caso.totalPistas, DIFICULTADES[state.dificultad].umbralEvidencia);
        if (precipitada) {
            perderVida(1);
            mostrarAsistente("No se preocupe por haber acusado tan rápido en «" + caso.titulo + "». Seguro que a la Dirección no le importa.", "alerta");
        }
    }

    /**
     * Issue #20: el desenlace en sí (Sospechoso.desenlace) sigue siendo
     * fijo en el backend, pero aquí se le añade una coda que varía según
     * cuánto se investigó antes de acusar — la misma proporción de
     * pistas/total que ya decide si una acusación fue precipitada.
     */
    function variarDesenlaceSegunProgreso() {
        var coda = document.getElementById("siga-veredicto-coda");
        if (!coda || !real || !real.casos) {
            return;
        }
        var caso = buscarCasoActualEnReal();
        if (!caso || !caso.totalPistas) {
            return;
        }
        var ratio = caso.pistasDescubiertas / caso.totalPistas;
        var texto;
        if (ratio < 0.4) {
            texto = "El expediente se cierra con la mayor parte de la documentación sin revisar. Nadie pregunta por qué.";
        } else if (ratio < 0.75) {
            texto = "El expediente se cierra con parte de la documentación revisada. El resto queda archivado sin más trámite.";
        } else {
            texto = "El expediente se cierra tras revisar casi toda la documentación disponible. No es que vaya a cambiar el resultado.";
        }
        coda.textContent = texto;
        coda.hidden = false;
    }

    /**
     * Combate de cartas (issue #21), sustituye al viejo "Objetar/Insistir"
     * de un solo botón: piedra-papel-tijera burocrático, con las réplicas
     * del sospechoso (Sospechoso.ataques) como flavor de cada ronda en vez
     * de datos de juego reales. Todo se resuelve en el cliente; el
     * servidor solo se entera al final (POST a combate/finalizar), gane o
     * pierda el jugador — no hay "sospechoso correcto", así que la
     * acusación se resuelve igual en ambos casos.
     */
    var TIPOS_COMBATE = {
        objecion: { etiqueta: "Objeción", vence: "silencio" },
        silencio: { etiqueta: "Silencio", vence: "insistencia" },
        insistencia: { etiqueta: "Insistencia", vence: "objecion" }
    };
    var ORDEN_TIPOS_COMBATE = ["objecion", "silencio", "insistencia"];
    var VIDA_INICIAL_COMBATE = 3;
    var EJES_POLITICOS = ["comunismo", "centrista", "socialdemocrata", "neoliberal"];

    /**
     * Issue #45: las decisiones políticas de ESTA partida son el
     * equipamiento de combate (modelo emergente, sin asignación): cada
     * elección del eje X da una carga de su habilidad (cap 2), gastable en
     * cualquier combate (duelo del caso 6 y Ventanilla). Cada habilidad es
     * una decisión dentro de la ronda, no un buff pasivo, y ninguna toca
     * carta.gastada — el canje sigue siendo lo único que quema cartas.
     */
    var HABILIDADES_COMBATE = {
        comunismo: { nombre: "Asamblea", descripcion: "Esta ronda, el empate también golpea al rival." },
        centrista: { nombre: "Mesa de diálogo", descripcion: "Esta ronda nadie pierde vida." },
        socialdemocrata: { nombre: "Comisión de seguimiento", descripcion: "Revela la réplica que viene." },
        neoliberal: { nombre: "Externalizar", descripcion: "Esta ronda el daño cuenta doble, gane quien gane." }
    };
    var combateActual = null;

    function cargasIdeologicas() {
        var puntos = PrometeoLogic.contarPuntosPorEje(state.historiasCartas,
            Object.keys(HISTORIAS_CARTAS), EJES_POLITICOS);
        var cargas = {};
        EJES_POLITICOS.forEach(function (eje) {
            cargas[eje] = Math.min(2, puntos[eje]);
        });
        return cargas;
    }

    /**
     * El motor de combate es único; lo que varía entre el duelo de un caso
     * (issue #21) y la Ventanilla de Reclamaciones (issue #43) viaja en la
     * config del propio combateActual: dónde se monta (raiz), cómo juega el
     * rival (modoRival: el ciclo autorado del caso 6 vs. aleatorio), qué
     * pasa al terminar (alTerminar), el texto final y el botón de cierre.
     */
    function iniciarCombate() {
        if (!window.PROMETEO_COMBATE || !combateRaiz) {
            return;
        }
        combateActual = {
            sospechoso: window.PROMETEO_COMBATE.sospechoso,
            ataques: window.PROMETEO_COMBATE.ataques,
            ronda: 0,
            vidaJugador: VIDA_INICIAL_COMBATE,
            vidaRival: VIDA_INICIAL_COMBATE,
            ultimoTipoJugador: null,
            terminado: null,
            cargas: cargasIdeologicas(),
            habilidadArmada: null,
            habilidadUsadaEstaRonda: false,
            jugadaRivalPrevista: null,
            raiz: combateRaiz,
            // Issue #45: el ciclo fijo era una tabla memorizable; reactivo
            // (cebable) hay una decisión por ronda y la Comisión de
            // seguimiento tiene algo que revelar. El texto/ritmo narrativo
            // de los ataques no cambia (sigue ciclando por ronda).
            modoRival: "reactiva",
            claseBoton: "btn siga-btn",
            claseNota: "siga-nota-marginal mb-3",
            alTerminar: resolverFinCombate,
            textoFin: function (resultado) {
                return resultado === "gano"
                    ? "Ha ganado el enfrentamiento. Se ha hecho con su carta."
                    : "Ha perdido el enfrentamiento. Pierde una vida.";
            },
            cierre: {
                texto: "Presentar cierre",
                alPulsar: function () {
                    if (formCombateFinalizar) {
                        formCombateFinalizar.submit();
                    }
                }
            }
        };
        renderCombate();
    }

    function jugarCartaCombate(tipo) {
        if (!combateActual || combateActual.terminado) {
            return;
        }
        var tipoRival;
        if (combateActual.jugadaRivalPrevista) {
            // La Comisión de seguimiento ya fijó (y reveló) esta réplica.
            tipoRival = combateActual.jugadaRivalPrevista;
            combateActual.jugadaRivalPrevista = null;
        } else {
            var indiceUltimo = combateActual.ultimoTipoJugador === null
                ? null
                : ORDEN_TIPOS_COMBATE.indexOf(combateActual.ultimoTipoJugador);
            var indiceRival = PrometeoLogic.indiceJugadaRival(combateActual.modoRival,
                combateActual.ronda, ORDEN_TIPOS_COMBATE.length, null, indiceUltimo);
            tipoRival = ORDEN_TIPOS_COMBATE[indiceRival];
        }
        var habilidad = combateActual.habilidadArmada;
        combateActual.habilidadArmada = null;
        var combo = tipo === combateActual.ultimoTipoJugador;
        var dano = (combo ? 2 : 1) * (habilidad === "neoliberal" ? 2 : 1);

        if (habilidad === "centrista") {
            // Mesa de diálogo: la ronda transcurre sin daño para nadie.
        } else if (tipo === tipoRival) {
            // Empate: solo la Asamblea lo convierte en golpe al rival.
            if (habilidad === "comunismo") {
                combateActual.vidaRival = Math.max(0, combateActual.vidaRival - dano);
            }
        } else if (TIPOS_COMBATE[tipo].vence === tipoRival) {
            combateActual.vidaRival = Math.max(0, combateActual.vidaRival - dano);
        } else {
            combateActual.vidaJugador = Math.max(0, combateActual.vidaJugador - dano);
        }

        combateActual.habilidadUsadaEstaRonda = false;
        combateActual.ultimoTipoJugador = tipo;
        combateActual.ronda++;

        if (combateActual.vidaRival === 0) {
            combateActual.terminado = "gano";
        } else if (combateActual.vidaJugador === 0) {
            combateActual.terminado = "perdio";
        }

        golpe(combo ? 700 : 480);
        renderCombate();

        if (combateActual.terminado) {
            combateActual.alTerminar();
        }
    }

    function resolverFinCombate() {
        if (combateActual.terminado === "gano") {
            state.ganoCombateAlgunaVez = true;
            guardarEstado();
            desbloquearLogro("careo-a-puerta-cerrada");
            if (desbloquearCarta("el-colgado")) {
                marcarProgreso();
                renderTarot();
                renderLogros();
            }
            mostrarAsistente("No hacía falta ganarle a " + combateActual.sospechoso
                + ". Ahora tiene su carta, para lo que le sirva.", "guino");
        } else {
            perderVida(1);
            mostrarAsistente("No se preocupe por haber perdido contra " + combateActual.sospechoso
                + ". Seguro que a la Dirección no le importa.", "triste");
        }
    }

    function usarHabilidad(eje) {
        if (!combateActual || combateActual.terminado || combateActual.habilidadUsadaEstaRonda
                || !combateActual.cargas || !combateActual.cargas[eje]) {
            return;
        }
        combateActual.cargas[eje]--;
        combateActual.habilidadUsadaEstaRonda = true;
        if (eje === "socialdemocrata") {
            // La Comisión de seguimiento fija la réplica de esta ronda y la
            // enseña: información por adelantado, la decisión sigue siendo suya.
            var indiceUltimo = combateActual.ultimoTipoJugador === null
                ? null
                : ORDEN_TIPOS_COMBATE.indexOf(combateActual.ultimoTipoJugador);
            var indice = PrometeoLogic.indiceJugadaRival(combateActual.modoRival,
                combateActual.ronda, ORDEN_TIPOS_COMBATE.length, null, indiceUltimo);
            combateActual.jugadaRivalPrevista = ORDEN_TIPOS_COMBATE[indice];
        } else {
            combateActual.habilidadArmada = eje;
        }
        tic(620);
        renderCombate();
    }

    function renderCombate() {
        if (!combateActual || !combateActual.raiz) {
            return;
        }
        var raiz = combateActual.raiz;
        raiz.innerHTML = "";

        function pips(etiquetaTexto, vida) {
            var cont = document.createElement("div");
            cont.className = "prometeo-combate-barra";
            var etiqueta = document.createElement("strong");
            etiqueta.textContent = etiquetaTexto;
            cont.appendChild(etiqueta);
            for (var i = 0; i < VIDA_INICIAL_COMBATE; i++) {
                var pip = document.createElement("span");
                pip.className = "prometeo-vida-pip " + (i < vida ? "is-llena" : "is-vacia");
                pip.innerHTML = "&#9679;";
                cont.appendChild(pip);
            }
            return cont;
        }

        var barras = document.createElement("div");
        barras.className = "prometeo-combate-barras";
        barras.appendChild(pips("Usted", combateActual.vidaJugador));
        barras.appendChild(pips(combateActual.sospechoso, combateActual.vidaRival));
        raiz.appendChild(barras);

        if (!combateActual.terminado) {
            var textoAtaque = combateActual.ataques[combateActual.ronda % combateActual.ataques.length];
            var nota = document.createElement("div");
            nota.className = combateActual.claseNota;
            nota.textContent = textoAtaque;
            raiz.appendChild(nota);

            // Recursos ideológicos (issue #45): las cargas ganadas con las
            // decisiones políticas de esta partida. Solo se pinta si hay algo.
            var hayHabilidades = combateActual.cargas && EJES_POLITICOS.some(function (e) {
                return combateActual.cargas[e] > 0;
            });
            if (hayHabilidades || combateActual.habilidadArmada || combateActual.jugadaRivalPrevista) {
                var zona = document.createElement("div");
                zona.className = "prometeo-combate-habilidades";
                EJES_POLITICOS.forEach(function (eje) {
                    var carga = (combateActual.cargas && combateActual.cargas[eje]) || 0;
                    if (carga === 0) {
                        return;
                    }
                    var hab = HABILIDADES_COMBATE[eje];
                    var botonHab = document.createElement("button");
                    botonHab.type = "button";
                    botonHab.className = "prometeo-btn-secundario prometeo-habilidad";
                    botonHab.textContent = hab.nombre + " ×" + carga;
                    botonHab.setAttribute("aria-label", hab.nombre + ": " + hab.descripcion);
                    botonHab.title = hab.descripcion;
                    botonHab.disabled = combateActual.habilidadUsadaEstaRonda;
                    botonHab.addEventListener("click", function () {
                        usarHabilidad(eje);
                    });
                    zona.appendChild(botonHab);
                });
                raiz.appendChild(zona);

                if (combateActual.jugadaRivalPrevista || combateActual.habilidadArmada) {
                    var avisoHab = document.createElement("p");
                    avisoHab.className = "prometeo-habilidad-aviso";
                    avisoHab.setAttribute("aria-live", "polite");
                    avisoHab.textContent = combateActual.jugadaRivalPrevista
                        ? "Comisión de seguimiento: la réplica que viene será «"
                            + TIPOS_COMBATE[combateActual.jugadaRivalPrevista].etiqueta + "»."
                        : HABILIDADES_COMBATE[combateActual.habilidadArmada].nombre
                            + " armada para esta ronda: "
                            + HABILIDADES_COMBATE[combateActual.habilidadArmada].descripcion;
                    raiz.appendChild(avisoHab);
                }
            }

            var opciones = document.createElement("div");
            opciones.className = "prometeo-combate-opciones";
            ORDEN_TIPOS_COMBATE.forEach(function (tipo) {
                var boton = document.createElement("button");
                boton.type = "button";
                boton.className = combateActual.claseBoton;
                boton.textContent = TIPOS_COMBATE[tipo].etiqueta;
                boton.addEventListener("click", function () {
                    jugarCartaCombate(tipo);
                });
                opciones.appendChild(boton);
            });
            raiz.appendChild(opciones);
        } else {
            var nota2 = document.createElement("div");
            nota2.className = combateActual.claseNota + " siga-revelado";
            nota2.textContent = combateActual.textoFin(combateActual.terminado);
            raiz.appendChild(nota2);

            var cerrar = document.createElement("button");
            cerrar.type = "button";
            cerrar.className = combateActual.claseBoton;
            cerrar.textContent = combateActual.cierre.texto;
            cerrar.addEventListener("click", combateActual.cierre.alPulsar);
            raiz.appendChild(cerrar);
        }
    }

    /**
     * Ventanilla de Reclamaciones (issue #43): combates repetibles contra
     * funcionarios aleatorios, reutilizando el motor del duelo del caso 6
     * pero como actividad meta de Prometeo — cero estado en servidor (no
     * hay caso ni veredicto que persistir; patrón CartaOcultaService), sin
     * tocar la economía de vida ni la colección de tarot. Recompensa: la
     * racha en curso (efímera, de esta sesión) y la mejor marca
     * (coliseoRachaMejor, meta-progresión), más un logro por llegar a 3.
     */
    var RIVALES_VENTANILLA = [
        {
            nombre: "R. Peñuelas, Ventanilla 3",
            ataques: [
                "Eso no es de esta ventanilla.",
                "Le falta el formulario B-11, que se solicita presentando el formulario B-11.",
                "Vuelva usted mañana. Hoy ya ha venido."
            ]
        },
        {
            nombre: "La Encargada de Sellos",
            ataques: [
                "Este sello no es válido: lo válido es el sello que valida este sello.",
                "Sin sello de entrada no hay sello de salida.",
                "El tampón se está secando. Espere sentado."
            ]
        },
        {
            nombre: "El Interventor Suplente del Suplente",
            ataques: [
                "Yo solo sustituyo a quien podría decirle que no.",
                "Su expediente lo está estudiando alguien que ya no trabaja aquí.",
                "No me consta. Y lo que no consta, no existe."
            ]
        },
        {
            nombre: "Auditoría Interna, Sección Espejos",
            ataques: [
                "¿Y a usted quién le audita, exactamente?",
                "Su firma no coincide con la firma que usted firmará.",
                "Esto ya lo reclamó usted. En 1987."
            ]
        },
        {
            nombre: "El Archivero del Turno de Noche",
            ataques: [
                "Eso se archivó. Archivado significa olvidado.",
                "El pasillo del fondo no tiene luz por motivos presupuestarios.",
                "Si lo busca, lo encontrará. Precisamente por eso no debe buscarlo."
            ]
        },
        {
            nombre: "Presidencia del Comité de Quejas sobre Quejas",
            ataques: [
                "Su queja sobre la queja ha quedado registrada como queja.",
                "El plazo terminó ayer y empieza mañana.",
                "Estimamos su reclamación. Estimar no es aceptar."
            ]
        }
    ];
    var rachaVentanilla = 0;

    /**
     * Issue #48: los reclamantes salen del corcho — si el jugador ya
     * desbloqueó conceptos PERSONA/COMITE, el rival toma uno de esos
     * nombres ("la gente de tus expedientes vuelve a darte largas") con
     * uno de los juegos de réplicas escritos a mano; sin conceptos, caen
     * los nombres genéricos de siempre. Exclusiones duras: el Comité Ad
     * Honorem (rival del duelo del caso 6, no un matón de arena) y el
     * propio auditor.
     */
    var RIVALES_VENTANILLA_EXCLUIDOS = ["Comité Ad Honorem", "auditor01 (usted)"];

    function nombreReclamanteDelCorcho() {
        if (!real || !real.conceptos) {
            return null;
        }
        var elegibles = real.conceptos.filter(function (c) {
            return (c.tipo === "PERSONA" || c.tipo === "COMITE")
                && RIVALES_VENTANILLA_EXCLUIDOS.indexOf(c.nombre) === -1;
        });
        if (!elegibles.length) {
            return null;
        }
        return elegibles[Math.floor(Math.random() * elegibles.length)].nombre;
    }

    function iniciarCombateVentanilla() {
        if (!ventanillaRaiz) {
            return;
        }
        var rival = RIVALES_VENTANILLA[Math.floor(Math.random() * RIVALES_VENTANILLA.length)];
        var nombreDelCorcho = nombreReclamanteDelCorcho();
        combateActual = {
            sospechoso: nombreDelCorcho || rival.nombre,
            ataques: rival.ataques,
            ronda: 0,
            vidaJugador: VIDA_INICIAL_COMBATE,
            vidaRival: VIDA_INICIAL_COMBATE,
            ultimoTipoJugador: null,
            terminado: null,
            cargas: cargasIdeologicas(),
            habilidadArmada: null,
            habilidadUsadaEstaRonda: false,
            jugadaRivalPrevista: null,
            raiz: ventanillaRaiz,
            modoRival: "reactiva",
            claseBoton: "prometeo-btn-secundario",
            claseNota: "prometeo-ventanilla-nota",
            alTerminar: resolverFinVentanilla,
            textoFin: function (resultado) {
                return resultado === "gano"
                    ? "Reclamación atendida. Pase el siguiente."
                    : "El reclamante se ha salido con la suya. Su racha vuelve a cero.";
            },
            cierre: {
                texto: "Llamar al siguiente",
                alPulsar: iniciarCombateVentanilla
            }
        };
        renderCombate();
        renderVentanillaEstado();
        golpe(240);
    }

    function resolverFinVentanilla() {
        // Deliberadamente sin perderVida() ni desbloquearCarta(): la
        // Ventanilla no toca el presupuesto de errores de la partida ni la
        // colección de 22 (el-colgado sigue siendo exclusivo del caso 6).
        var resultado = PrometeoLogic.actualizarRacha(rachaVentanilla,
            state.coliseoRachaMejor, combateActual.terminado === "gano");
        rachaVentanilla = resultado.racha;
        if (resultado.mejor !== state.coliseoRachaMejor) {
            state.coliseoRachaMejor = resultado.mejor;
            // Issue #47: el lince comenta el historial cuando cae la marca.
            mostrarAsistente("No cuente las reclamaciones seguidas que lleva. Es peor cuando uno sabe el número.", "guino");
        }
        guardarEstado();
        if (rachaVentanilla >= 3) {
            desbloquearLogro("ventanilla-tres");
        }
        if (state.coliseoRachaMejor >= 5) {
            desbloquearLogro("funcionario-del-mes");
        }
        if (state.coliseoRachaMejor >= 10) {
            desbloquearLogro("ventanilla-inagotable");
        }
        renderVentanillaEstado();
    }

    function renderVentanillaEstado() {
        if (!ventanillaRacha) {
            return;
        }
        ventanillaRacha.textContent = "Racha: " + rachaVentanilla
            + " · Mejor registro: " + state.coliseoRachaMejor;
    }

    function mostrarJefeSiHaceFalta() {
        if (!jefeModal || state.jefeVisto) {
            return;
        }
        // Issue #24: si esta página tiene un combate en curso, el aviso lo
        // taparía en pleno duelo. Se pospone sin marcar jefeVisto: saldrá
        // en la siguiente página sin combate.
        if (window.PROMETEO_COMBATE && combateRaiz) {
            return;
        }
        jefeModal.hidden = false;
        atraparFoco(jefeModal);
        state.jefeVisto = true;
        guardarEstado();
        golpe(180);
    }

    /**
     * Bolsas de mensajes en psicología inversa: el lince nunca dice "haga
     * esto", dice "no haga esto" — sobre justo lo que conviene hacer.
     */
    function poolCombinarPistas(titulo) {
        return [
            "No se moleste en combinar los documentos de «" + titulo + "». Seguro que no dicen nada que no sepa ya.",
            "Ni se le ocurra cruzar esos papeles de «" + titulo + "». Da igual lo que digan juntos.",
            "Combinar cosas es perder el tiempo. Ignore «" + titulo + "», se lo digo por su bien.",
            "No junte esos dos papeles de «" + titulo + "». Algunas cosas es mejor dejarlas separadas.",
            "Da igual lo que esconda «" + titulo + "» al combinarlo. No merece la pena comprobarlo."
        ];
    }

    function poolExplorarCaso(titulo) {
        return [
            "No hace falta que vuelva a mirar «" + titulo + "». Ya lo ha entendido todo, seguro.",
            "Pase de largo por «" + titulo + "». Ahí no hay nada que un vistazo rápido no pueda ignorar.",
            "«" + titulo + "» puede esperar. O mejor, ni lo abra.",
            "No lea con demasiada atención «" + titulo + "». Por encima ya está bien.",
            "Nada en «" + titulo + "» merece una segunda mirada. Se lo aseguro."
        ];
    }

    function poolAcusarCaso(titulo) {
        return [
            "No acuse a nadie en «" + titulo + "» todavía. Mejor deje ese expediente exactamente como está.",
            "«" + titulo + "» puede esperar. No tiene ninguna prisa por señalar a alguien.",
            "Ya sabe quién fue en «" + titulo + "». No hace falta que lo diga en voz alta.",
            "No presente ninguna acusación en «" + titulo + "». Los expedientes abiertos son más cómodos así.",
            "Deje a todos los sospechosos de «" + titulo + "» tranquilos. De verdad, no hace falta elegir."
        ];
    }

    function poolCerrado(titulo) {
        return [
            "«" + titulo + "» ya está cerrado. No hace falta volver a abrirlo. Ni una última leída, ¿eh?",
            "No hay nada más que hacer en «" + titulo + "». Cierre la pestaña. En serio.",
            "Ya sabe cómo termina «" + titulo + "». No hace falta comprobarlo otra vez.",
            "No vuelva a leer el desenlace de «" + titulo + "». No cambia por mucho que insista."
        ];
    }

    /**
     * A diferencia del resto de bolsas (solo texto), estas admiten
     * "respuestas": 2-3 réplicas que el jugador puede elegir, cada una con
     * su propio remate del lince — issue #17. mostrarAsistente() sabe leer
     * ambos formatos (ver normalizarMensaje).
     */
    var POOL_DESCUBRIMIENTO = [
        {
            texto: "Vaya, encontró algo. Ojalá no lo hubiera hecho.",
            respuestas: [
                { etiqueta: "Pues yo creo que sí importa", reaccion: "Eso dicen todos. Luego se les pasa." },
                { etiqueta: "¿Y si es justo lo que faltaba?", reaccion: "Ojalá. Pero no se haga ilusiones tan pronto." }
            ]
        },
        {
            texto: "Eso que acaba de leer... olvídelo enseguida, será lo mejor.",
            respuestas: [
                { etiqueta: "No pienso olvidarlo", reaccion: "Muy suyo. Ya me avisará cuando cambie de idea." },
                { etiqueta: "¿Por qué debería olvidarlo?", reaccion: "Por nada en concreto. Pura recomendación general." }
            ]
        },
        {
            texto: "No le dé demasiada importancia a lo que acaba de descubrir. Seguro que no cambia nada.",
            respuestas: [
                { etiqueta: "Y si cambia todo, ¿qué?", reaccion: "Entonces habré estado equivocado. No sería la primera vez." },
                { etiqueta: "Le voy a dar toda la importancia", reaccion: "Perfecto. Luego no diga que no se lo avisé." }
            ]
        },
        {
            texto: "Qué pena que se haya fijado en eso. Ya no hay forma de no haberlo visto.",
            respuestas: [
                { etiqueta: "No es ninguna pena, es un avance", reaccion: "Avance, retroceso... a mí todo el archivo me parece igual de plano." },
                { etiqueta: "¿Preferiría que no mirase nada?", reaccion: "Preferiría muchas cosas. Casi ninguna sucede." }
            ]
        },
        {
            texto: "No lo anote en ningún sitio. Mejor que se le olvide antes de cerrar el expediente.",
            respuestas: [
                { etiqueta: "Ya lo he anotado", reaccion: "Cómo no. Bueno, ya es tarde para el consejo, entonces." },
                { etiqueta: "¿Y si lo necesito luego?", reaccion: "Para eso están los expedientes, supongo. Yo solo comento." }
            ]
        }
    ];
    var POOL_COMBINACION_FALLIDA = [
        "No insista combinando esos papeles. Seguro que no encajan.",
        "Pruebe con otros dos documentos. O no pruebe. Es indiferente.",
        "Qué raro que no encajaran. Mejor no lo vuelva a intentar.",
        "Deje esos dos documentos donde estaban. No iban juntos y no van a empezar ahora."
    ];
    var POOL_CONCLUSION_REPETIDA = [
        "Esa conclusión ya la tenía anotada. No hacía falta comprobarlo dos veces.",
        "Ya lo sabía. Vuelva a intentarlo si quiere, no cambiará nada.",
        "No repita esa combinación una tercera vez. Va a decir exactamente lo mismo."
    ];
    var POOL_ACCESO_DENEGADO = [
        "Mejor no insista en acceder a ese expediente. Seguro que no hay nada interesante ahí dentro.",
        "No pida más permisos. Los expedientes clasificados están así por una buena razón. Probablemente.",
        "No merece la pena reclamar ese acceso. Quédese con los expedientes que ya tiene."
    ];
    var POOL_GUARDADO = [
        "No hacía falta guardar. Total, ¿qué podría salir mal?",
        "Su progreso ya está a salvo. O eso dice la máquina.",
        "No vuelva a guardar tan pronto. Una vez ya debería bastar."
    ];
    var POOL_REINICIO = [
        "Empezar de nuevo no cambia nada. El expediente vuelve, siempre vuelve.",
        "Ya no queda nada de lo que sabía. Mejor así, ¿no cree?",
        "No se arrepienta de haber borrado su progreso. No había nada ahí que mereciera la pena."
    ];
    var POOL_COMBATE = [
        "No le dé al botón. Esa cosa amarilla seguro que se cansa antes que usted.",
        "Ríndase ya. No hace falta insistir, en serio.",
        "No mire directamente al desenlace. Total, ¿qué más da un ojo de más?",
        "No siga resistiéndose. Total, seguro que esto termina bien.",
        "No cuente las rondas que lleva. Es mejor no saberlo."
    ];
    var POOL_ARCHIVO_COMPLETO = [
        "Ya ha cerrado todos los expedientes que le tocaban. No hace falta que busque nada más.",
        "No queda ningún caso por resolver. Puede dejar de leer esto. En serio, puede.",
        "No hay ningún expediente pendiente. Apague el monitor, no lo necesita ya."
    ];
    var POOL_DASHBOARD = [
        "No hace falta que abra ningún expediente hoy. Tómeselo con calma.",
        "Ese menú de ahí arriba no esconde nada importante. No hace falta mirarlo dos veces.",
        "Quédese aquí, en el escritorio. Fuera de aquí no hay nada que le convenga ver.",
        "No hace falta que elija ningún caso todavía. Están bien donde están, cerrados.",
        "No mire el reloj de la esquina. Da igual la hora que marque, siempre está mal."
    ];
    var POOL_CARPETA_NORMAL = [
        "No hace falta que repase el corcho de investigación. Ya se lo sabe de memoria, ¿no?",
        "Esas notas de la pared no dicen nada que no supiera ya. No pierda el tiempo mirándolas.",
        "No cuente cuántas fichas le faltan. Total, no tiene ninguna prisa."
    ];
    var POOL_CARPETA_COMPLETA = [
        "Ya ha cerrado todos los expedientes. No hace falta que siga buscando nada más aquí.",
        "No hay ninguna entrada nueva en el corcho. Ninguna. No la busque.",
        "No revise el corcho otra vez. Ya vio todo lo que había que ver."
    ];
    var POOL_GENERICO = [
        "No hay ningún caso que siga latiendo bajo la mesa. Ninguno.",
        "No merece la pena revisar lo que parece inofensivo. Se lo digo yo.",
        "El lugar más sospechoso no suele ser el más limpio. Pero da igual, no lo mire.",
        "Tal vez no deba buscar el archivo que no tiene nombre. Mejor no.",
        "No piense demasiado en lo que no le he contado. Es peor si lo piensa.",
        "No hace falta que confíe en mí. Aunque, pensándolo bien, tampoco pasa nada si lo hace."
    ];

    function tituloCasoActual() {
        var titulo = document.title || "";
        var indice = titulo.indexOf(" · SIGA-98");
        return indice === -1 ? titulo : titulo.substring(0, indice);
    }

    function buscarCasoActualEnReal() {
        if (!real || !real.casos) {
            return null;
        }
        var titulo = tituloCasoActual();
        return real.casos.find(function (c) {
            return c.titulo === titulo;
        }) || null;
    }

    /**
     * Recorre el progreso real buscando algún caso con algo pendiente,
     * en el mismo orden de prioridad que antes (combinaciones, sin
     * resolver, sin veredicto), para cuando el caso actual ya no tiene
     * nada que ofrecer.
     */
    function elegirPistaGlobalReversa() {
        if (!real || !real.casos || !real.casos.length) {
            return null;
        }
        var conConclusionPendiente = real.casos.find(function (c) {
            return c.tieneConclusionesPendientes;
        });
        if (conConclusionPendiente) {
            return { pool: poolCombinarPistas(conConclusionPendiente.titulo), mood: "guino" };
        }
        var sinResolver = real.casos.find(function (c) {
            return !c.resuelto;
        });
        if (sinResolver) {
            return { pool: poolExplorarCaso(sinResolver.titulo), mood: "guino" };
        }
        var sinVeredicto = real.casos.find(function (c) {
            return c.resuelto && !c.tieneVeredicto;
        });
        if (sinVeredicto) {
            return { pool: poolAcusarCaso(sinVeredicto.titulo), mood: "guino" };
        }
        return null;
    }

    function poolPorMensajeReciente(texto) {
        if (texto.indexOf("Pista añadida") === 0 || texto.indexOf("Nueva conclusión anotada") === 0) {
            return { pool: POOL_DESCUBRIMIENTO, mood: "guino" };
        }
        if (texto.indexOf("No encuentra ninguna relación") === 0 || texto.indexOf("Selecciona exactamente dos documentos") === 0) {
            return { pool: POOL_COMBINACION_FALLIDA, mood: "neutral" };
        }
        if (texto.indexOf("Esa conclusión ya estaba anotada") === 0) {
            return { pool: POOL_CONCLUSION_REPETIDA, mood: "neutral" };
        }
        if (texto.indexOf("denegada") !== -1) {
            return { pool: POOL_ACCESO_DENEGADO, mood: "alerta" };
        }
        if (texto.indexOf("Progreso guardado") === 0) {
            return { pool: POOL_GUARDADO, mood: "neutral" };
        }
        if (texto.indexOf("Partida reiniciada") === 0) {
            return { pool: POOL_REINICIO, mood: "triste" };
        }
        return null;
    }

    function contextoActual() {
        var ruta = window.location.pathname;
        if (ruta.indexOf("/casos/") === 0) {
            return {
                pantalla: "caso",
                combate: document.querySelector("[data-siga-combate]") !== null,
                veredicto: document.querySelector("[data-siga-veredicto]") !== null
            };
        }
        if (ruta.indexOf("/carpeta") === 0) {
            return {
                pantalla: "carpeta",
                todosResueltos: document.querySelector("[data-siga-todos-resueltos]") !== null
            };
        }
        return { pantalla: "dashboard" };
    }

    /**
     * Decide qué bolsa de mensajes y qué gesto le corresponde al lince
     * ahora mismo: primero mira si acaba de pasar algo (mensaje flash de
     * la última acción), luego el estado del caso/pantalla actual, y por
     * último cae en un empujón genérico sobre el progreso global.
     */
    function elegirMensajeContextual() {
        var alerta = document.querySelector(".alert");
        var textoAlerta = alerta ? alerta.textContent.trim() : "";
        if (textoAlerta) {
            var porAccion = poolPorMensajeReciente(textoAlerta);
            if (porAccion) {
                return porAccion;
            }
        }

        var ctx = contextoActual();
        if (ctx.pantalla === "caso") {
            if (ctx.combate) {
                return { pool: POOL_COMBATE, mood: "alerta" };
            }
            if (ctx.veredicto) {
                return { pool: poolCerrado(tituloCasoActual()), mood: "triste" };
            }
            var casoActual = buscarCasoActualEnReal();
            if (casoActual) {
                if (casoActual.tieneConclusionesPendientes) {
                    return { pool: poolCombinarPistas(casoActual.titulo), mood: "guino" };
                }
                if (!casoActual.resuelto) {
                    return { pool: poolExplorarCaso(casoActual.titulo), mood: "guino" };
                }
                if (!casoActual.tieneVeredicto) {
                    return { pool: poolAcusarCaso(casoActual.titulo), mood: "guino" };
                }
            }
            return elegirPistaGlobalReversa() || { pool: POOL_ARCHIVO_COMPLETO, mood: "neutral" };
        }

        if (ctx.pantalla === "carpeta") {
            return ctx.todosResueltos
                ? { pool: POOL_CARPETA_COMPLETA, mood: "neutral" }
                : { pool: POOL_CARPETA_NORMAL, mood: "guino" };
        }

        return elegirPistaGlobalReversa() || { pool: POOL_DASHBOARD.concat(POOL_GENERICO), mood: "neutral" };
    }

    function detenerAnimacionLince() {
        if (animacionLinceId) {
            window.clearInterval(animacionLinceId);
            animacionLinceId = null;
        }
    }

    function animarLince(mood) {
        detenerAnimacionLince();
        var moodValido = CARAS_LINCE[mood] ? mood : "neutral";
        var caras = CARAS_LINCE[moodValido];
        var indice = 0;
        if (asistente) {
            asistente.classList.remove("is-neutral", "is-guino", "is-alerta", "is-triste");
            asistente.classList.add("is-" + moodValido);
        }
        if (avatarAsistente) {
            avatarAsistente.textContent = caras[0];
        }
        animacionLinceId = window.setInterval(function () {
            indice = (indice + 1) % caras.length;
            if (avatarAsistente) {
                avatarAsistente.textContent = caras[indice];
            }
        }, INTERVALO_LINCE[moodValido]);
    }

    function mostrarPanel(nombre) {
        dialog.querySelectorAll("[data-panel]").forEach(function (panel) {
            panel.hidden = panel.getAttribute("data-panel") !== nombre;
        });
        var titulo = dialog.querySelector('[data-panel="' + nombre + '"] h2');
        if (titulo) {
            if (!titulo.id) {
                titulo.id = "prometeo-menu-title-" + nombre;
            }
            dialog.setAttribute("aria-labelledby", titulo.id);
            titulo.setAttribute("tabindex", "-1");
            titulo.focus();
        }
    }

    /**
     * Trampa de foco manual para los modales que se muestran/ocultan a
     * mano (captcha, jefe, despido, final alternativo, final verdadero,
     * historia de una carta, final político): ninguno usa showModal(),
     * así que sin esto Tab se escapa hacia la página de fondo mientras el
     * modal sigue encima (issue #6). El asistente queda fuera a propósito:
     * es un aviso no bloqueante, no un diálogo, y no debe robar el foco.
     */
    var elementoConFocoPrevio = null;
    var contenedorConFocoAtrapado = null;
    var manejadorTrampaFoco = null;

    function elementosFocoDentroDe(contenedor) {
        return Array.prototype.slice.call(contenedor.querySelectorAll(FOCO_SELECTOR)).filter(function (el) {
            return el.offsetParent !== null;
        });
    }

    function atraparFoco(contenedor) {
        if (contenedorConFocoAtrapado === contenedor) {
            var yaDentro = elementosFocoDentroDe(contenedor);
            if (yaDentro.length) {
                yaDentro[0].focus();
            }
            return;
        }
        liberarFoco();
        elementoConFocoPrevio = document.activeElement;
        contenedorConFocoAtrapado = contenedor;

        var iniciales = elementosFocoDentroDe(contenedor);
        if (iniciales.length) {
            iniciales[0].focus();
        }

        manejadorTrampaFoco = function (evento) {
            if (evento.key !== "Tab") {
                return;
            }
            var lista = elementosFocoDentroDe(contenedor);
            if (!lista.length) {
                return;
            }
            var primero = lista[0];
            var ultimo = lista[lista.length - 1];
            if (evento.shiftKey && document.activeElement === primero) {
                evento.preventDefault();
                ultimo.focus();
            } else if (!evento.shiftKey && document.activeElement === ultimo) {
                evento.preventDefault();
                primero.focus();
            }
        };
        document.addEventListener("keydown", manejadorTrampaFoco, true);
    }

    function liberarFoco() {
        if (manejadorTrampaFoco) {
            document.removeEventListener("keydown", manejadorTrampaFoco, true);
            manejadorTrampaFoco = null;
        }
        if (elementoConFocoPrevio && typeof elementoConFocoPrevio.focus === "function") {
            elementoConFocoPrevio.focus();
        }
        elementoConFocoPrevio = null;
        contenedorConFocoAtrapado = null;
    }

    function mostrarCaptcha() {
        if (!captcha || !preguntaCaptcha) {
            return;
        }

        var preguntas = [
            "Marca la casilla que no pertenece a este universo.",
            "Selecciona la imagen que muestra el ojo correcto.",
            "Confirma que no eres un registro duplicado."
        ];
        preguntaCaptcha.textContent = preguntas[Math.floor(Math.random() * preguntas.length)];
        captcha.hidden = false;
        atraparFoco(captcha);
        var boton = captcha.querySelector("[data-cerrar-captcha]");
        if (boton) {
            boton.focus();
        }
        desbloquearLogro("sospecha");
        // Issue #46: el-diablo se re-gana topándose con la verificación
        // falsa en ESTA partida (antes se sincronizaba desde el logro
        // "sospecha", que ahora es de vitrina permanente).
        if (desbloquearCarta("el-diablo")) {
            renderTarot();
        }
        golpe(600);
    }

    /**
     * Las bolsas normales son solo texto; unas pocas (issue #17) traen
     * "respuestas" para que el jugador pueda replicarle al lince. Este
     * normalizador deja pasar ambos formatos como { texto, respuestas? }.
     */
    function normalizarMensaje(entrada) {
        return typeof entrada === "string" ? { texto: entrada } : entrada;
    }

    function renderRespuestasAsistente(respuestas) {
        if (!respuestasAsistente) {
            return;
        }
        respuestasAsistente.innerHTML = "";
        if (!respuestas || !respuestas.length) {
            respuestasAsistente.hidden = true;
            return;
        }
        respuestasAsistente.hidden = false;
        respuestas.forEach(function (opcion) {
            var boton = document.createElement("button");
            boton.type = "button";
            boton.className = "prometeo-btn-secundario prometeo-assistente-respuesta";
            boton.textContent = opcion.etiqueta;
            boton.addEventListener("click", function () {
                textoAsistente.textContent = opcion.reaccion;
                respuestasAsistente.hidden = true;
                respuestasAsistente.innerHTML = "";
                tic(480);
            });
            respuestasAsistente.appendChild(boton);
        });
    }

    function avisarEpilogoSiHaceFalta() {
        var hito = real && real.totalCasosPrincipales > 0
            && real.casosResueltos >= real.totalCasosPrincipales;
        if (!hito || state.epilogoAvisado || !asistente || !textoAsistente || state.finalShown) {
            return false;
        }
        state.epilogoAvisado = true;
        mostrarAsistente("Ni se le ocurra pasarse por el corcho de su carpeta. Ha aparecido un memorándum de acreditación que no le incumbe en absoluto, y menos aún la clave que trae escrita.", "alerta");
        return true;
    }

    function mostrarAsistente(mensaje, mood) {
        if (!asistente || !textoAsistente || state.finalShown) {
            return;
        }

        var seleccion = mensaje ? { pool: [mensaje], mood: mood || "guino" } : elegirMensajeContextual();
        var normalizados = seleccion.pool.map(normalizarMensaje);
        var candidatos = normalizados.length > 1
            ? normalizados.filter(function (item) {
                return item.texto !== state.ultimoMensajeAsistente;
            })
            : normalizados;
        var elegido = candidatos[Math.floor(Math.random() * candidatos.length)];

        textoAsistente.textContent = elegido.texto;
        renderRespuestasAsistente(elegido.respuestas);
        animarLince(seleccion.mood);
        asistente.hidden = false;
        asistente.classList.add("is-visible");
        state.assistantShown = true;
        state.ultimoMensajeAsistente = elegido.texto;
        guardarEstado();
        tic(620);
    }

    function ocultarAsistente() {
        if (asistente) {
            asistente.hidden = true;
            asistente.classList.remove("is-visible");
        }
        if (respuestasAsistente) {
            respuestasAsistente.hidden = true;
            respuestasAsistente.innerHTML = "";
        }
        detenerAnimacionLince();
    }

    function mostrarFinalAlternativo() {
        if (!finalAlternativo || !textoFinal || state.finalShown) {
            return;
        }

        var mensajes = [
            "La interfaz ya no es un menú. Es una garganta abierta.",
            "El programa no busca salvarte, sólo confirmar que sigues ahí.",
            "Lo que ves no es un sistema. Es el reflejo de tu propia espera."
        ];
        textoFinal.textContent = mensajes[Math.floor(Math.random() * mensajes.length)] + " El programa se comporta como AM: no te ofrece salida, sólo una réplica más larga.";
        finalAlternativo.hidden = false;
        atraparFoco(finalAlternativo);
        state.finalShown = true;
        state.vioFinalAlternativoAlgunaVez = true;
        if (desbloquearCarta("la-torre")) {
            renderTarot();
        }
        desbloquearLogro("la-garganta-abierta");
        guardarEstado();
        golpe(140);
    }

    function comprobarEstadoDeJuego() {
        var tiempoSinProgreso = Date.now() - state.lastProgressAt;
        if (tiempoSinProgreso > 180000 && !state.assistantShown && !state.finalShown) {
            mostrarAsistente();
        }
        if (tiempoSinProgreso > 720000 && !state.finalShown) {
            mostrarFinalAlternativo();
        }
    }

    function ocultarCaptcha() {
        if (captcha) {
            captcha.hidden = true;
        }
        if (contenedorConFocoAtrapado === captcha) {
            liberarFoco();
        }
    }

    function quizasMostrarCaptcha() {
        if (Math.random() < 0.3) {
            mostrarCaptcha();
        }
    }

    function volumenActual() {
        var guardado = window.localStorage.getItem(LLAVE_VOLUMEN);
        var valor = guardado === null ? 60 : parseInt(guardado, 10);
        return isNaN(valor) ? 60 : Math.min(100, Math.max(0, valor));
    }

    function obtenerAudio() {
        if (!audioCtx) {
            var Ctx = window.AudioContext || window.webkitAudioContext;
            if (!Ctx) {
                return null;
            }
            audioCtx = new Ctx();
            master = audioCtx.createGain();
            master.gain.value = (volumenActual() / 100) * 0.2;
            master.connect(audioCtx.destination);
        }
        return audioCtx;
    }

    function aplicarVolumen(valor) {
        window.localStorage.setItem(LLAVE_VOLUMEN, String(valor));
        if (master) {
            master.gain.value = (valor / 100) * 0.2;
        }
        if (ambiente) {
            ambiente.gain.gain.value = (valor / 100) * ambiente.nivelBase;
        }
    }

    function tic(frecuencia) {
        if (volumenActual() <= 0) {
            return;
        }
        var ctx = obtenerAudio();
        if (!ctx) {
            return;
        }
        var osc = ctx.createOscillator();
        var gain = ctx.createGain();
        osc.type = "sine";
        osc.frequency.value = frecuencia;
        gain.gain.setValueAtTime(0.0001, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(1, ctx.currentTime + 0.01);
        gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.12);
        osc.connect(gain);
        gain.connect(master);
        osc.start();
        osc.stop(ctx.currentTime + 0.13);
    }

    /**
     * Issue #49: la voz sucia de SIGA-98 — onda cuadrada breve más una
     * ráfaga de ruido (el golpe de sello sobre el formulario), para los
     * eventos del sistema viejo: jefe, despido, historias ocultas, choques
     * de combate, el captcha falso, el final de AM. El menú Prometeo
     * conserva el tic() senoidal limpio: el audio también cuenta el split.
     */
    function golpe(frecuencia) {
        if (volumenActual() <= 0) {
            return;
        }
        var ctx = obtenerAudio();
        if (!ctx) {
            return;
        }
        var osc = ctx.createOscillator();
        var gain = ctx.createGain();
        osc.type = "square";
        osc.frequency.value = frecuencia;
        gain.gain.setValueAtTime(0.0001, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.4, ctx.currentTime + 0.006);
        gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.09);
        osc.connect(gain);
        gain.connect(master);
        osc.start();
        osc.stop(ctx.currentTime + 0.1);

        var duracion = 0.055;
        var buffer = ctx.createBuffer(1, Math.ceil(ctx.sampleRate * duracion), ctx.sampleRate);
        var datos = buffer.getChannelData(0);
        for (var i = 0; i < datos.length; i++) {
            datos[i] = (Math.random() * 2 - 1) * (1 - i / datos.length) * 0.5;
        }
        var ruido = ctx.createBufferSource();
        ruido.buffer = buffer;
        var gainRuido = ctx.createGain();
        gainRuido.gain.value = 0.35;
        ruido.connect(gainRuido);
        gainRuido.connect(master);
        ruido.start();
    }


    /**
     * Zumbido de fondo persistente: dos osciladores casi al unísono
     * (baten entre sí, como un fluorescente cansado) con un filtro que
     * respira despacio. Se vuelve más grave y más lento en el combate
     * final. Solo arranca tras un gesto real del usuario (autoplay).
     */
    function iniciarAmbiente() {
        if (ambiente) {
            return;
        }
        var ctx = obtenerAudio();
        if (!ctx) {
            return;
        }

        var esPesado = document.querySelector("[data-siga-combate]") !== null;
        var nivelBase = esPesado ? 0.05 : 0.028;

        var gain = ctx.createGain();
        gain.gain.value = 0;
        gain.connect(master);

        var filtro = ctx.createBiquadFilter();
        filtro.type = "lowpass";
        filtro.frequency.value = esPesado ? 220 : 340;
        filtro.connect(gain);

        var osc1 = ctx.createOscillator();
        osc1.type = "sawtooth";
        osc1.frequency.value = esPesado ? 55 : 65;
        osc1.connect(filtro);

        var osc2 = ctx.createOscillator();
        osc2.type = "sine";
        osc2.frequency.value = osc1.frequency.value * (esPesado ? 1.015 : 1.006);
        osc2.connect(filtro);

        var lfo = ctx.createOscillator();
        lfo.frequency.value = esPesado ? 0.07 : 0.05;
        var lfoGain = ctx.createGain();
        lfoGain.gain.value = esPesado ? 70 : 30;
        lfo.connect(lfoGain);
        lfoGain.connect(filtro.frequency);

        osc1.start();
        osc2.start();
        lfo.start();

        var nivelObjetivo = (volumenActual() / 100) * nivelBase;
        gain.gain.linearRampToValueAtTime(nivelObjetivo, ctx.currentTime + 4);

        ambiente = { gain: gain, nivelBase: nivelBase };
    }

    function primerGestoReal() {
        iniciarAmbiente();
        document.removeEventListener("pointerdown", primerGestoReal);
        document.removeEventListener("keydown", primerGestoReal);
    }
    document.addEventListener("pointerdown", primerGestoReal, { once: true });
    document.addEventListener("keydown", primerGestoReal, { once: true });

    reiniciarEstadoPerRun();
    renderLogros();
    renderTarot();
    renderVida();
    radiosDificultad.forEach(function (radio) {
        radio.checked = radio.value === state.dificultad;
    });
    if (activarPistasCheckbox) {
        activarPistasCheckbox.checked = state.pistasActivas;
    }
    document.body.classList.toggle("prometeo-pistas-activas", state.pistasActivas);
    sincronizarConEstadoReal();
    comprobarAcusacionReciente();
    variarDesenlaceSegunProgreso();
    iniciarCombate();

    if (!state.assistantShown && !state.finalShown) {
        setInterval(comprobarEstadoDeJuego, 15000);
    }

    window.setTimeout(function () {
        mostrarJefeSiHaceFalta();
    }, 400);

    window.setTimeout(function () {
        if (!state.saludoVisto) {
            state.saludoVisto = true;
            guardarEstado();
            mostrarAsistente("Hola. Yo soy el lince de la oficina, y hoy parece que alguien ha dejado la puerta entreabierta. No mire lo que no debería estar donde está. Ah, y sobre todo no abra Mi carpeta: alguien dejó ahí un manual del usuario que se lo explicaría todo, y eso no le conviene.", "guino");
            return;
        }
        // Issue #33: el hito más importante de la partida (cerrar los cinco
        // expedientes hace aparecer la acreditación en el corcho) era mudo —
        // el badge de /carpeta es perezoso y el lince solo reaccionaba a
        // mensajes flash. Una sola línea, una sola vez por partida.
        if (avisarEpilogoSiHaceFalta()) {
            return;
        }
        // Ya se presentó antes: a partir de aquí siempre habla según el
        // contexto real, nunca repitiendo el saludo fijo (issue #1).
        mostrarAsistente();
    }, 700);

    trigger.addEventListener("click", function () {
        mostrarPanel("principal");
        desbloquearLogro("primer-mirada");
        quizasMostrarCaptcha();
        dialog.showModal();
        tic(660);
    });

    dialog.addEventListener("close", function () {
        ocultarCaptcha();
        trigger.focus();
    });

    dialog.querySelectorAll("[data-cerrar-menu]").forEach(function (boton) {
        boton.addEventListener("click", function () {
            dialog.close();
        });
    });

    dialog.querySelectorAll("[data-abrir-panel]").forEach(function (boton) {
        boton.addEventListener("click", function () {
            mostrarPanel(boton.getAttribute("data-abrir-panel"));
        });
    });

    dialog.querySelectorAll("[data-volver-panel]").forEach(function (boton) {
        boton.addEventListener("click", function () {
            mostrarPanel("principal");
        });
    });

    if (captcha) {
        captcha.addEventListener("click", function (evento) {
            if (evento.target === captcha) {
                ocultarCaptcha();
            }
        });
        captcha.querySelectorAll("[data-cerrar-captcha]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                ocultarCaptcha();
            });
        });
    }

    if (asistente) {
        asistente.querySelectorAll("[data-cerrar-asistente]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                ocultarAsistente();
            });
        });
    }

    if (finalAlternativo) {
        finalAlternativo.querySelectorAll("[data-cerrar-final]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                finalAlternativo.hidden = true;
                if (contenedorConFocoAtrapado === finalAlternativo) {
                    liberarFoco();
                }
            });
        });
    }

    if (jefeModal) {
        jefeModal.querySelectorAll("[data-cerrar-jefe]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                jefeModal.hidden = true;
                if (contenedorConFocoAtrapado === jefeModal) {
                    liberarFoco();
                }
                tic(520);
            });
        });
    }

    if (despidoModal) {
        despidoModal.querySelectorAll("[data-cerrar-despido]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                despidoModal.hidden = true;
                if (contenedorConFocoAtrapado === despidoModal) {
                    liberarFoco();
                }
                tic(300);
            });
        });
        // Issue #44: con el canje oculto hasta vida 0, el despido es el
        // momento exacto en que existe — el modal lleva directo al tarot.
        despidoModal.querySelectorAll("[data-despido-tarot]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                despidoModal.hidden = true;
                if (contenedorConFocoAtrapado === despidoModal) {
                    liberarFoco();
                }
                mostrarPanel("tarot");
                if (!dialog.open) {
                    dialog.showModal();
                }
                tic(400);
            });
        });
    }

    if (finalVerdaderoModal) {
        finalVerdaderoModal.querySelectorAll("[data-cerrar-final-verdadero]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                finalVerdaderoModal.hidden = true;
                if (contenedorConFocoAtrapado === finalVerdaderoModal) {
                    liberarFoco();
                }
                tic(1046);
            });
        });
    }

    if (historiaCartaModal) {
        historiaCartaModal.querySelectorAll("[data-cerrar-historia-carta]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                historiaCartaModal.hidden = true;
                if (contenedorConFocoAtrapado === historiaCartaModal) {
                    liberarFoco();
                }
                tic(520);
            });
        });
    }

    if (tarotVisor) {
        tarotVisor.querySelectorAll("[data-cerrar-tarot-visor]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                cerrarVisorTarot();
                tic(520);
            });
        });
        // Clic en el fondo (fuera de la tarjeta) cierra el visor. Se exige
        // que el gesto empiece y acabe en el fondo: si no, arrastrar para
        // seleccionar la descripción y soltar fuera cerraría el visor.
        var gestoEmpezadoEnElFondo = false;
        tarotVisor.addEventListener("mousedown", function (evento) {
            gestoEmpezadoEnElFondo = evento.target === tarotVisor;
        });
        tarotVisor.addEventListener("click", function (evento) {
            if (evento.target === tarotVisor && gestoEmpezadoEnElFondo) {
                cerrarVisorTarot();
                tic(520);
            }
            gestoEmpezadoEnElFondo = false;
        });
        // Escape cierra el visor sin salir del menú que hay detrás: se corta
        // la propagación a cualquier otro oyente, incluidos los de document.
        document.addEventListener("keydown", function (evento) {
            if (evento.key === "Escape" && !tarotVisor.hidden) {
                evento.stopImmediatePropagation();
                evento.preventDefault();
                cerrarVisorTarot();
                tic(520);
            }
        });
    }

    if (finalPoliticoModal) {
        finalPoliticoModal.querySelectorAll("[data-cerrar-final-politico]").forEach(function (boton) {
            boton.addEventListener("click", function () {
                finalPoliticoModal.hidden = true;
                if (contenedorConFocoAtrapado === finalPoliticoModal) {
                    liberarFoco();
                }
                tic(1046);
            });
        });
    }

    document.querySelectorAll("[data-carta-oculta]").forEach(function (hotspot) {
        if (state.historiasCartas[hotspot.getAttribute("data-carta-oculta")]) {
            hotspot.classList.add("siga-hotspot-visto");
        }
        hotspot.addEventListener("click", function () {
            mostrarHistoriaCarta(hotspot.getAttribute("data-carta-oculta"));
        });
    });

    radiosDificultad.forEach(function (radio) {
        radio.addEventListener("change", function () {
            if (radio.checked) {
                aplicarDificultad(radio.value);
                tic(700);
            }
        });
    });

    if (activarPistasCheckbox) {
        activarPistasCheckbox.addEventListener("change", function () {
            aplicarPistasActivas(activarPistasCheckbox.checked);
            tic(500);
        });
    }

    if (ventanillaEmpezar) {
        ventanillaEmpezar.addEventListener("click", function () {
            iniciarCombateVentanilla();
        });
        renderVentanillaEstado();
    }

    if (botonTarot) {
        botonTarot.addEventListener("click", function () {
            var huboNovedad = sincronizarConEstadoReal();
            botonTarot.textContent = huboNovedad ? "¡Una carta cambió de cara!" : "Nada nuevo por ahora";
            tic(huboNovedad ? 740 : 320);
            window.setTimeout(function () {
                botonTarot.textContent = "Comprobar avance";
            }, 2200);
        });
    }

    // Cerrar al hacer click fuera del panel (sobre el ::backdrop). Solo
    // cuenta si el click cayó sobre el propio <dialog> (un click en un
    // elemento interno nunca cierra, aunque el panel cambie de tamaño en
    // ese mismo click — issue #23: Créditos encogía el diálogo y la
    // comprobación puramente geométrica leía el click como "fuera").
    dialog.addEventListener("click", function (evento) {
        if (evento.target !== dialog) {
            return;
        }
        var rect = dialog.getBoundingClientRect();
        var fuera = evento.clientX < rect.left || evento.clientX > rect.right
            || evento.clientY < rect.top || evento.clientY > rect.bottom;
        if (fuera) {
            dialog.close();
        }
    });

    if (rango) {
        rango.value = String(volumenActual());
        rango.addEventListener("input", function () {
            aplicarVolumen(parseInt(rango.value, 10));
            tic(880);
        });
    }

    dialog.querySelectorAll(".prometeo-menu-item, .prometeo-btn-secundario, .prometeo-btn-peligro").forEach(function (el) {
        el.addEventListener("click", function () {
            tic(520);
        });
    });

    /**
     * Soporte de mando (al menos en PC vía Gamepad API): el D-pad o el
     * stick izquierdo mueven el foco entre los elementos interactivos
     * visibles, A confirma (equivale a un clic) y B retrocede un panel
     * o cierra el menú. No hay cursor, así que todo se hace por foco.
     */
    var gamepadUltimaAccion = 0;
    var GAMEPAD_REPETICION_MS = 220;
    var gamepadActivo = false;

    function elementosFocoVisibles() {
        return Array.prototype.slice.call(document.querySelectorAll(FOCO_SELECTOR)).filter(function (el) {
            return el.offsetParent !== null || el === document.activeElement;
        });
    }

    function moverFocoMando(direccion) {
        var elementos = elementosFocoVisibles();
        if (!elementos.length) {
            return;
        }
        var indice = elementos.indexOf(document.activeElement);
        var siguiente = indice === -1 ? 0 : (indice + direccion + elementos.length) % elementos.length;
        elementos[siguiente].focus();
    }

    function confirmarFocoMando() {
        var el = document.activeElement;
        if (el && typeof el.click === "function") {
            el.click();
        }
    }

    function retrocederFocoMando() {
        if (dialog.open) {
            var panelActivo = dialog.querySelector("[data-panel]:not([hidden])");
            if (panelActivo && panelActivo.getAttribute("data-panel") !== "principal") {
                mostrarPanel("principal");
            } else {
                dialog.close();
            }
        }
    }

    function sondearMando() {
        var pads = navigator.getGamepads ? navigator.getGamepads() : [];
        var pad = null;
        for (var i = 0; i < pads.length; i++) {
            if (pads[i]) {
                pad = pads[i];
                break;
            }
        }
        if (pad) {
            var ahora = Date.now();
            if (ahora - gamepadUltimaAccion > GAMEPAD_REPETICION_MS) {
                var ejeY = pad.axes.length > 1 ? pad.axes[1] : 0;
                var dpadArriba = Boolean(pad.buttons[12] && pad.buttons[12].pressed);
                var dpadAbajo = Boolean(pad.buttons[13] && pad.buttons[13].pressed);
                var botonA = Boolean(pad.buttons[0] && pad.buttons[0].pressed);
                var botonB = Boolean(pad.buttons[1] && pad.buttons[1].pressed);

                if (dpadArriba || ejeY < -0.6) {
                    moverFocoMando(-1);
                    gamepadUltimaAccion = ahora;
                } else if (dpadAbajo || ejeY > 0.6) {
                    moverFocoMando(1);
                    gamepadUltimaAccion = ahora;
                } else if (botonA) {
                    confirmarFocoMando();
                    gamepadUltimaAccion = ahora;
                } else if (botonB) {
                    retrocederFocoMando();
                    gamepadUltimaAccion = ahora;
                }
            }
        }
        window.requestAnimationFrame(sondearMando);
    }

    window.addEventListener("gamepadconnected", function () {
        if (!gamepadActivo) {
            gamepadActivo = true;
            window.requestAnimationFrame(sondearMando);
        }
    });
})();
