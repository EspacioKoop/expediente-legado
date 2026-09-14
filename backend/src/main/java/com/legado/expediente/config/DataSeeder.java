package com.legado.expediente.config;

import com.legado.expediente.model.Caso;
import com.legado.expediente.model.Concepto;
import com.legado.expediente.model.ConceptoTipo;
import com.legado.expediente.model.EstadoCaso;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.RegistroLegado;
import com.legado.expediente.model.Rol;
import com.legado.expediente.model.Sospechoso;
import com.legado.expediente.model.TipoRegistro;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.CasoRepository;
import com.legado.expediente.repository.ConceptoRepository;
import com.legado.expediente.repository.PistaRepository;
import com.legado.expediente.repository.RegistroLegadoRepository;
import com.legado.expediente.repository.SospechosoRepository;
import com.legado.expediente.repository.UsuarioRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.Month;
import java.util.Arrays;


/**
 * Siembra los datos de partida: usuarios, expedientes y el corcho de
 * investigación. Un método por expediente (en el mismo orden en que se
 * insertan) para que cada uno se pueda leer sin cargar con el resto, y unos
 * pequeños records para pasar de un método a otro solo las pistas que el
 * corcho de conceptos necesita citar más adelante.
 */
@Component
public class DataSeeder implements CommandLineRunner {

    private static final String CARCOSA_SERVICIOS_ESCENICOS = "Carcosa Servicios Escénicos";

    private final UsuarioRepository usuarioRepository;
    private final CasoRepository casoRepository;
    private final RegistroLegadoRepository registroLegadoRepository;
    private final PistaRepository pistaRepository;
    private final ConceptoRepository conceptoRepository;
    private final SospechosoRepository sospechosoRepository;
    private final PasswordEncoder passwordEncoder;

    public DataSeeder(UsuarioRepository usuarioRepository,
                       CasoRepository casoRepository,
                       RegistroLegadoRepository registroLegadoRepository,
                       PistaRepository pistaRepository,
                       ConceptoRepository conceptoRepository,
                       SospechosoRepository sospechosoRepository,
                       PasswordEncoder passwordEncoder) {
        this.usuarioRepository = usuarioRepository;
        this.casoRepository = casoRepository;
        this.registroLegadoRepository = registroLegadoRepository;
        this.pistaRepository = pistaRepository;
        this.conceptoRepository = conceptoRepository;
        this.sospechosoRepository = sospechosoRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        if (usuarioRepository.count() == 0) {
            seedUsuarios();
        }

        if (casoRepository.count() == 0) {
            Caso1Pistas caso1Pistas = seedCaso1();
            Caso2Pistas caso2Pistas = seedCaso2();
            Caso3Pistas caso3Pistas = seedCaso3();
            Caso4Pistas caso4Pistas = seedCaso4();
            Caso5Pistas caso5Pistas = seedCaso5();
            Caso6Pistas caso6Pistas = seedCaso6();
            Caso7Pistas caso7Pistas = seedCaso7();
            Caso8Pistas caso8Pistas = seedCaso8();
            seedCorchoPrincipal(caso1Pistas, caso2Pistas, caso3Pistas, caso4Pistas, caso5Pistas,
                    caso6Pistas, caso7Pistas, caso8Pistas);
        }
    }

    private static final class Caso1Pistas {
        private final Pista pista20;

        private Caso1Pistas(Pista pista20) {
            this.pista20 = pista20;
        }

        private Pista pista20() {
            return pista20;
        }
    }

    private static final class Caso2Pistas {
        private final Pista pista3;
        private final Pista pista22;

        private Caso2Pistas(Pista pista3, Pista pista22) {
            this.pista3 = pista3;
            this.pista22 = pista22;
        }

        private Pista pista3() {
            return pista3;
        }

        private Pista pista22() {
            return pista22;
        }
    }

    private static final class Caso3Pistas {
        private final Pista pista5;
        private final Pista pista6;

        private Caso3Pistas(Pista pista5, Pista pista6) {
            this.pista5 = pista5;
            this.pista6 = pista6;
        }

        private Pista pista5() {
            return pista5;
        }

        private Pista pista6() {
            return pista6;
        }
    }

    private static final class Caso4Pistas {
        private final Pista pista7;
        private final Pista pista8;

        private Caso4Pistas(Pista pista7, Pista pista8) {
            this.pista7 = pista7;
            this.pista8 = pista8;
        }

        private Pista pista7() {
            return pista7;
        }

        private Pista pista8() {
            return pista8;
        }
    }

    private static final class Caso5Pistas {
        private final Pista pista9;
        private final Pista pista10;

        private Caso5Pistas(Pista pista9, Pista pista10) {
            this.pista9 = pista9;
            this.pista10 = pista10;
        }

        private Pista pista9() {
            return pista9;
        }

        private Pista pista10() {
            return pista10;
        }
    }

    private static final class Caso6Pistas {
        private final Pista pista11;
        private final Pista pista12;
        private final Pista pista13;

        private Caso6Pistas(Pista pista11, Pista pista12, Pista pista13) {
            this.pista11 = pista11;
            this.pista12 = pista12;
            this.pista13 = pista13;
        }

        private Pista pista11() {
            return pista11;
        }

        private Pista pista12() {
            return pista12;
        }

        private Pista pista13() {
            return pista13;
        }
    }

    private static final class Caso7Pistas {
        private final Pista pista15;

        private Caso7Pistas(Pista pista15) {
            this.pista15 = pista15;
        }

        private Pista pista15() {
            return pista15;
        }
    }

    private static final class Caso8Pistas {
        private final Pista pista19;

        private Caso8Pistas(Pista pista19) {
            this.pista19 = pista19;
        }

        private Pista pista19() {
            return pista19;
        }
    }

    private void seedUsuarios() {
        Usuario auditor = new Usuario();
        auditor.setUsername("auditor01");
        auditor.setPassword(passwordEncoder.encode("auditor-local-123"));
        auditor.setNombreCompleto("Auditor Invitado");
        auditor.setRol(Rol.AUDITOR);
        usuarioRepository.save(auditor);

        // Cuenta oculta: sus credenciales solo se revelan en la carpeta del
        // jugador tras resolver los cinco expedientes base.
        Usuario enlace = new Usuario();
        enlace.setUsername("enlace13");
        enlace.setPassword(passwordEncoder.encode("hastur-local-13"));
        enlace.setNombreCompleto("Enlace Especial");
        enlace.setRol(Rol.ADMIN);
        usuarioRepository.save(enlace);
    }

    private Caso1Pistas seedCaso1() {
        Caso caso = new Caso();
        caso.setTitulo("El cierre de caja de 1999");
        caso.setDescripcion("Un descuadre nunca explicado en el cierre contable de fin de año quedó "
                + "enterrado en el sistema SIGA. La empresa quiere saber qué ocurrió realmente.");
        caso.setAnioSuceso(1999);
        caso.setEstado(EstadoCaso.ABIERTO);
        casoRepository.save(caso);

        RegistroLegado factura1 = new RegistroLegado();
        factura1.setCaso(caso);
        factura1.setTipo(TipoRegistro.FACTURA);
        factura1.setFolio("F-1999-00231");
        factura1.setContenido("Factura por 'servicios de consultoría' emitida el 30/12/1999. "
                + "Monto: $482,000. Proveedor sin RFC registrado.");
        factura1.setFecha(LocalDate.of(1999, Month.DECEMBER, 30));
        registroLegadoRepository.save(factura1);

        RegistroLegado memo1 = new RegistroLegado();
        memo1.setCaso(caso);
        memo1.setTipo(TipoRegistro.MEMORANDO);
        memo1.setFolio("MEMO-1999-088");
        memo1.setContenido("De: Dirección de Finanzas. Para: Contraloría. 'Autorizo el pago urgente "
                + "sin revisión previa, bajo mi responsabilidad.' Firmado: J. Ibarra.");
        memo1.setFecha(LocalDate.of(1999, Month.DECEMBER, 29));
        registroLegadoRepository.save(memo1);

        RegistroLegado empleado1 = new RegistroLegado();
        empleado1.setCaso(caso);
        empleado1.setTipo(TipoRegistro.EMPLEADO);
        empleado1.setFolio("EMP-0456");
        empleado1.setContenido("J. Ibarra. Director de Finanzas 1997-2000. Renunció el 03/01/2000, "
                + "cuatro días después del cierre de caja.");
        empleado1.setFecha(LocalDate.of(2000, Month.JANUARY, 3));
        registroLegadoRepository.save(empleado1);

        Pista pista1 = new Pista();
        pista1.setCaso(caso);
        pista1.setRegistroOrigen(memo1);
        pista1.setDescripcion("El memorándum de autorización se firmó un día antes del cierre, "
                + "saltándose el proceso normal de revisión.");
        pista1.setFraseGatillo("sin revisión previa");
        pistaRepository.save(pista1);

        Pista pista2 = new Pista();
        pista2.setCaso(caso);
        pista2.setRegistroOrigen(empleado1);
        pista2.setDescripcion("El Director de Finanzas renunció justo después del cierre de caja, "
                + "sin explicación registrada.");
        pista2.setFraseGatillo("cuatro días después del cierre de caja");
        pistaRepository.save(pista2);

        RegistroLegado actaContraloria1 = new RegistroLegado();
        actaContraloria1.setCaso(caso);
        actaContraloria1.setTipo(TipoRegistro.ACTA);
        actaContraloria1.setFolio("ACTA-1999-014");
        actaContraloria1.setContenido("Acta de revisión de Contraloría sobre el pago urgente: 'Se "
                + "revisó la documentación y no se encontraron observaciones.' Firmada el mismo día "
                + "del pago, cinco minutos después de la hora de registro de la factura.");
        actaContraloria1.setFecha(LocalDate.of(1999, Month.DECEMBER, 30));
        registroLegadoRepository.save(actaContraloria1);

        Pista pista20 = new Pista();
        pista20.setCaso(caso);
        pista20.setRegistroOrigen(factura1);
        pista20.setRegistroOrigen2(actaContraloria1);
        pista20.setDescripcion("La revisión de Contraloría se completó en cinco minutos, el mismo día "
                + "del pago, sin observar que el proveedor de la factura no tenía RFC registrado.");
        pistaRepository.save(pista20);

        Pista pista28 = new Pista();
        pista28.setCaso(caso);
        pista28.setRegistroOrigen(memo1);
        pista28.setRegistroOrigen2(empleado1);
        pista28.setDescripcion("El memo que autoriza el pago urgente y la renuncia de J. Ibarra están "
                + "firmados con la misma pluma, según el peritaje de tinta anexo al expediente — un "
                + "peritaje que nadie recuerda haber solicitado.");
        pistaRepository.save(pista28);

        Sospechoso sospechosoIbarra = new Sospechoso();
        sospechosoIbarra.setCaso(caso);
        sospechosoIbarra.setNombre("J. Ibarra");
        sospechosoIbarra.setDescripcion("Director de Finanzas. Firmó la autorización de pago urgente "
                + "y renunció días después.");
        sospechosoIbarra.setDesenlace("Se emite responsiva a nombre de J. Ibarra por el monto "
                + "completo. El caso se cierra. Nadie recupera el dinero: Ibarra nunca fue localizado "
                + "para notificarle.");
        sospechosoRepository.save(sospechosoIbarra);

        Sospechoso sospechosoProveedor = new Sospechoso();
        sospechosoProveedor.setCaso(caso);
        sospechosoProveedor.setNombre("El proveedor sin RFC");
        sospechosoProveedor.setDescripcion("La empresa que recibió el pago de 'servicios de "
                + "consultoría' no tiene registro fiscal ni existencia comprobable.");
        sospechosoProveedor.setDesenlace("Se cursa una orden de investigación contra un proveedor que, "
                + "según el registro mercantil, nunca existió legalmente. La orden se archiva por "
                + "'imposibilidad práctica de notificación'.");
        sospechosoRepository.save(sospechosoProveedor);

        Sospechoso sospechosoContraloria = new Sospechoso();
        sospechosoContraloria.setCaso(caso);
        sospechosoContraloria.setNombre("Contraloría");
        sospechosoContraloria.setDescripcion("El área responsable de revisar el pago antes de "
                + "autorizarlo lo aprobó sin observaciones en cinco minutos.");
        sospechosoContraloria.setDesenlace("Se turna el caso a Contraloría para que audite el proceder "
                + "de Contraloría. El resultado de dicha autoevaluación nunca se hizo público.");
        sospechosoRepository.save(sospechosoContraloria);

        return new Caso1Pistas(pista20);
    }

    private Caso2Pistas seedCaso2() {
        Caso caso2 = new Caso();
        caso2.setTitulo("El trámite de la silla 4-B");
        caso2.setDescripcion("En 1990, un empleado de Almacén solicitó una silla ergonómica tras una "
                + "lesión de espalda certificada por el médico de la empresa. La solicitud pasó por "
                + "catorce oficinas distintas a lo largo de seis años, cada una exigiendo un nuevo "
                + "formulario que citaba al anterior, hasta que el empleado se jubiló sin haber "
                + "recibido la silla ni una negativa por escrito. El expediente nunca se aprobó, "
                + "nunca se rechazó, y en sentido estricto tampoco llegó a cerrarse.");
        caso2.setAnioSuceso(1996);
        caso2.setEstado(EstadoCaso.CERRADO);
        casoRepository.save(caso2);

        RegistroLegado oficio2 = new RegistroLegado();
        oficio2.setCaso(caso2);
        oficio2.setTipo(TipoRegistro.OFICIO);
        oficio2.setFolio("OF-1990-114");
        oficio2.setContenido("Solicito silla ergonómica por prescripción médica adjunta. Se turna a "
                + "Comité de Bienestar Laboral conforme a la Circular 12, para su valoración y "
                + "trámite correspondiente.");
        oficio2.setFecha(LocalDate.of(1990, Month.MARCH, 14));
        registroLegadoRepository.save(oficio2);

        RegistroLegado circular2 = new RegistroLegado();
        circular2.setCaso(caso2);
        circular2.setTipo(TipoRegistro.CIRCULAR);
        circular2.setFolio("CIRC-1988-012");
        circular2.setContenido("Toda solicitud de mobiliario especial deberá ser dictaminada por el "
                + "Comité de Bienestar Laboral, el cual sesionará cuando exista quórum. El comité no "
                + "ha sesionado desde su fundación por falta de quórum.");
        circular2.setFecha(LocalDate.of(1988, Month.JUNE, 1));
        registroLegadoRepository.save(circular2);

        RegistroLegado empleado2 = new RegistroLegado();
        empleado2.setCaso(caso2);
        empleado2.setTipo(TipoRegistro.EMPLEADO);
        empleado2.setFolio("EMP-0112");
        empleado2.setContenido("R. Salcido. Almacén general 1979-1996. Se jubiló el 20/02/1996. "
                + "Última anotación en su expediente: 'sigo esperando respuesta sobre la silla.'");
        empleado2.setFecha(LocalDate.of(1996, Month.FEBRUARY, 20));
        registroLegadoRepository.save(empleado2);

        Pista pista3 = new Pista();
        pista3.setCaso(caso2);
        pista3.setRegistroOrigen(circular2);
        pista3.setDescripcion("El Comité de Bienestar Laboral, único con autoridad para aprobar la "
                + "solicitud, jamás ha alcanzado quórum desde que fue creado.");
        pista3.setFraseGatillo("no ha sesionado desde su fundación por falta de quórum");
        pistaRepository.save(pista3);

        Pista pista4 = new Pista();
        pista4.setCaso(caso2);
        pista4.setRegistroOrigen(empleado2);
        pista4.setDescripcion("El puesto con firma autorizante para este trámite fue eliminado en la "
                + "reestructuración de 1987, un año antes de que se emitiera la propia Circular 12.");
        pista4.setFraseGatillo("sigo esperando respuesta sobre la silla");
        pistaRepository.save(pista4);

        RegistroLegado oficioReestructura2 = new RegistroLegado();
        oficioReestructura2.setCaso(caso2);
        oficioReestructura2.setTipo(TipoRegistro.OFICIO);
        oficioReestructura2.setFolio("OF-1987-200");
        oficioReestructura2.setContenido("Se notifica la eliminación de la Jefatura de Bienestar "
                + "Laboral por reestructuración administrativa, efectiva a partir de esta fecha.");
        oficioReestructura2.setFecha(LocalDate.of(1987, Month.MAY, 4));
        registroLegadoRepository.save(oficioReestructura2);

        Pista pista22 = new Pista();
        pista22.setCaso(caso2);
        pista22.setRegistroOrigen(circular2);
        pista22.setRegistroOrigen2(oficioReestructura2);
        pista22.setDescripcion("La Circular 12 exige la firma de la Jefatura de Bienestar Laboral para "
                + "aprobar cualquier trámite de mobiliario especial, pero esa jefatura fue eliminada un "
                + "año antes de que la circular se emitiera.");
        pistaRepository.save(pista22);

        Pista pista29 = new Pista();
        pista29.setCaso(caso2);
        pista29.setRegistroOrigen(oficio2);
        pista29.setRegistroOrigen2(empleado2);
        pista29.setDescripcion("La solicitud original de 1990 nunca fue marcada como aprobada, rechazada "
                + "ni cancelada: sigue en trámite, catorce oficinas después, a nombre de un empleado que "
                + "ya se jubiló.");
        pistaRepository.save(pista29);

        Sospechoso sospechosoComite2 = new Sospechoso();
        sospechosoComite2.setCaso(caso2);
        sospechosoComite2.setNombre("El Comité de Bienestar Laboral");
        sospechosoComite2.setDescripcion("Único con autoridad para aprobar la solicitud. Nunca ha "
                + "alcanzado quórum desde su fundación.");
        sospechosoComite2.setDesenlace("Se notifica al Comité de Bienestar Laboral que se le atribuye "
                + "la responsabilidad del caso. El comité no puede acusar recibo porque nunca ha "
                + "sesionado.");
        sospechosoRepository.save(sospechosoComite2);

        Sospechoso sospechosoCircular2 = new Sospechoso();
        sospechosoCircular2.setCaso(caso2);
        sospechosoCircular2.setNombre("La Circular 12");
        sospechosoCircular2.setDescripcion("El propio documento que exige una firma imposible de "
                + "obtener desde antes de existir.");
        sospechosoCircular2.setDesenlace("Se abre un procedimiento para modificar la Circular 12. El "
                + "procedimiento para modificar circulares está regulado, a su vez, por la Circular "
                + "12.");
        sospechosoRepository.save(sospechosoCircular2);

        Sospechoso sospechosoSalcido = new Sospechoso();
        sospechosoSalcido.setCaso(caso2);
        sospechosoSalcido.setNombre("R. Salcido");
        sospechosoSalcido.setDescripcion("El propio solicitante. Esperó seis años sin escalar el "
                + "trámite por otra vía.");
        sospechosoSalcido.setDesenlace("Se determina que el solicitante debió dar seguimiento con "
                + "mayor insistencia. No se especifica ante quién, ya que el puesto correspondiente "
                + "fue eliminado en 1987.");
        sospechosoRepository.save(sospechosoSalcido);

        return new Caso2Pistas(pista3, pista22);
    }

    private Caso3Pistas seedCaso3() {
        Caso caso3 = new Caso();
        caso3.setTitulo("Traspaso de personal: expediente de E. Montalvo");
        caso3.setDescripcion("En 1993 se registró el traslado del empleado E. Montalvo al 'Departamento "
                + "de Enlace Especial', ubicado según el memo en el piso 13. El edificio, de acuerdo "
                + "con todos los planos y actas de mantenimiento, tiene solo doce pisos. A partir de "
                + "la fecha del traslado no existe ningún otro registro de Montalvo: ni recibos de "
                + "nómina, ni renuncia, ni baja. El memo de traslado, sin embargo, aparece debidamente "
                + "sellado de recibido.");
        caso3.setAnioSuceso(1993);
        caso3.setEstado(EstadoCaso.ABIERTO);
        casoRepository.save(caso3);

        RegistroLegado memo3 = new RegistroLegado();
        memo3.setCaso(caso3);
        memo3.setTipo(TipoRegistro.MEMORANDO);
        memo3.setFolio("MEMO-1993-201");
        memo3.setContenido("Se traslada a E. Montalvo al Departamento de Enlace Especial, piso 13, "
                + "por instrucción del Comité Ad Honorem. Preséntese el día 05/07/1993 sin excepción.");
        memo3.setFecha(LocalDate.of(1993, Month.JULY, 1));
        registroLegadoRepository.save(memo3);

        RegistroLegado oficio3 = new RegistroLegado();
        oficio3.setCaso(caso3);
        oficio3.setTipo(TipoRegistro.OFICIO);
        oficio3.setFolio("OF-1993-055");
        oficio3.setContenido("Administración de edificio informa que el inmueble consta de doce "
                + "niveles. No existe botón de piso 13 en ningún elevador ni escalera registrada en "
                + "los planos vigentes.");
        oficio3.setFecha(LocalDate.of(1993, Month.JULY, 10));
        registroLegadoRepository.save(oficio3);

        RegistroLegado acta3 = new RegistroLegado();
        acta3.setCaso(caso3);
        acta3.setTipo(TipoRegistro.ACTA);
        acta3.setFolio("ACTA-1993-009");
        acta3.setContenido("Acta de reunión del Comité Ad Honorem donde se autoriza el traslado. "
                + "Lista de asistentes: L. Pardo, R. Guzmán, [nombre ilegible en el original "
                + "digitalizado]. No se encontró este comité en ningún organigrama oficial de la "
                + "empresa.");
        acta3.setFecha(LocalDate.of(1993, Month.JUNE, 28));
        registroLegadoRepository.save(acta3);

        RegistroLegado empleado3 = new RegistroLegado();
        empleado3.setCaso(caso3);
        empleado3.setTipo(TipoRegistro.EMPLEADO);
        empleado3.setFolio("EMP-0233");
        empleado3.setContenido("E. Montalvo. Auxiliar administrativo 1988-1993. Último recibo de "
                + "nómina: junio de 1993. Sin renuncia ni baja registrada después del traslado.");
        empleado3.setFecha(LocalDate.of(1993, Month.JUNE, 30));
        registroLegadoRepository.save(empleado3);

        Pista pista5 = new Pista();
        pista5.setCaso(caso3);
        pista5.setRegistroOrigen(oficio3);
        pista5.setDescripcion("No existe un piso 13 en los planos del edificio, pero el memo de "
                + "traslado fue timbrado de recibido como si el destino fuera real.");
        pista5.setFraseGatillo("No existe botón de piso 13");
        pistaRepository.save(pista5);

        Pista pista6 = new Pista();
        pista6.setCaso(caso3);
        pista6.setRegistroOrigen(acta3);
        pista6.setDescripcion("El 'Comité Ad Honorem' que ordenó el traslado no figura en ningún "
                + "organigrama, presupuesto ni acta de constitución conocida de la empresa.");
        pista6.setFraseGatillo("No se encontró este comité en ningún organigrama oficial");
        pistaRepository.save(pista6);

        Pista pista23 = new Pista();
        pista23.setCaso(caso3);
        pista23.setRegistroOrigen(memo3);
        pista23.setRegistroOrigen2(oficio3);
        pista23.setDescripcion("La confirmación de que no existe un piso 13 llegó cinco días después "
                + "de la fecha en que, según el propio memo de traslado, Montalvo ya debía haberse "
                + "presentado ahí.");
        pistaRepository.save(pista23);

        Pista pista30 = new Pista();
        pista30.setCaso(caso3);
        pista30.setRegistroOrigen(acta3);
        pista30.setRegistroOrigen2(empleado3);
        pista30.setDescripcion("El nombre ilegible en la lista de asistentes del acta comparte la misma "
                + "clave de empleado que aparece en el expediente de E. Montalvo.");
        pistaRepository.save(pista30);

        Sospechoso sospechosoComite3 = new Sospechoso();
        sospechosoComite3.setCaso(caso3);
        sospechosoComite3.setNombre("Comité Ad Honorem");
        sospechosoComite3.setDescripcion("Ordenó el traslado a un piso que, según todos los planos, no "
                + "existe.");
        sospechosoComite3.setDesenlace("Se solicita al Comité Ad Honorem un informe sobre el traslado. "
                + "La solicitud se turna, por instrucción del propio comité, al Departamento de Enlace "
                + "Especial, piso 13.");
        sospechosoRepository.save(sospechosoComite3);

        Sospechoso sospechosoRecepcion3 = new Sospechoso();
        sospechosoRecepcion3.setCaso(caso3);
        sospechosoRecepcion3.setNombre("Recepción del edificio");
        sospechosoRecepcion3.setDescripcion("Selló de recibido un memorándum con un destino que el "
                + "propio edificio no tiene.");
        sospechosoRecepcion3.setDesenlace("Se amonesta al personal de recepción por sellar de recibido "
                + "un memorándum con un destino inexistente. El sello utilizado ese día ya no está en "
                + "el inventario de la empresa.");
        sospechosoRepository.save(sospechosoRecepcion3);

        Sospechoso sospechosoMontalvo = new Sospechoso();
        sospechosoMontalvo.setCaso(caso3);
        sospechosoMontalvo.setNombre("E. Montalvo");
        sospechosoMontalvo.setDescripcion("El propio empleado trasladado. Nunca reportó la "
                + "inconsistencia del piso 13 antes de presentarse.");
        sospechosoMontalvo.setDesenlace("Se determina que correspondía al propio empleado señalar la "
                + "inconsistencia del piso 13 antes de presentarse a su nuevo puesto. El expediente no "
                + "aclara cómo debía hacerlo, dado que ya no hay forma de contactarlo.");
        sospechosoRepository.save(sospechosoMontalvo);

        return new Caso3Pistas(pista5, pista6);
    }

    private Caso4Pistas seedCaso4() {
        Caso caso4 = new Caso();
        caso4.setTitulo("Contrato de fin de año con Carcosa Servicios Escénicos");
        caso4.setDescripcion("Para la fiesta de aniversario de 1996, Recursos Humanos contrató a "
                + "'Carcosa Servicios Escénicos' para montar una obra de teatro. Las facturas "
                + "detallan un cobro adicional específicamente por NO representar el segundo acto. "
                + "En la semana siguiente al evento, varios empleados que asistieron solicitaron "
                + "cambio de área o renunciaron, citando motivos que ninguno quiso poner por escrito.");
        caso4.setAnioSuceso(1996);
        caso4.setEstado(EstadoCaso.ABIERTO);
        casoRepository.save(caso4);

        RegistroLegado factura4 = new RegistroLegado();
        factura4.setCaso(caso4);
        factura4.setTipo(TipoRegistro.FACTURA);
        factura4.setFolio("F-1996-00187");
        factura4.setContenido("Carcosa Servicios Escénicos S. de R.L. Concepto: 'montaje escénico, "
                + "Acto I únicamente'. Recargo por omisión del Acto II, incluido a solicitud expresa "
                + "del cliente. Campo de RFC del proveedor: en blanco. Sello de recibido: no "
                + "corresponde al sello oficial de la empresa; es de color amarillo.");
        factura4.setFecha(LocalDate.of(1996, Month.DECEMBER, 18));
        registroLegadoRepository.save(factura4);

        RegistroLegado memo4 = new RegistroLegado();
        memo4.setCaso(caso4);
        memo4.setTipo(TipoRegistro.MEMORANDO);
        memo4.setFolio("MEMO-1996-233");
        memo4.setContenido("De: Recursos Humanos. Nota interna posterior al evento: cinco empleados "
                + "han solicitado cambio de área esta semana. Motivo consignado por todos ellos, de "
                + "forma idéntica: 'prefiero no decirlo por escrito'. Se recomienda no dar seguimiento "
                + "adicional al tema.");
        memo4.setFecha(LocalDate.of(1996, Month.DECEMBER, 23));
        registroLegadoRepository.save(memo4);

        RegistroLegado acta4 = new RegistroLegado();
        acta4.setCaso(caso4);
        acta4.setTipo(TipoRegistro.ACTA);
        acta4.setFolio("ACTA-1996-041");
        acta4.setContenido("Acta del comité organizador agradeciendo a Carcosa Servicios Escénicos por "
                + "un 'excelente Acto I'. Se decidió, por unanimidad y sin discusión, no proceder con "
                + "la lectura del segundo acto, conforme a la cláusula 4 del contrato.");
        acta4.setFecha(LocalDate.of(1996, Month.DECEMBER, 19));
        registroLegadoRepository.save(acta4);

        RegistroLegado empleado4 = new RegistroLegado();
        empleado4.setCaso(caso4);
        empleado4.setTipo(TipoRegistro.EMPLEADO);
        empleado4.setFolio("EMP-0378");
        empleado4.setContenido("Empleado solicitó cambio de área el 21/12/1996, tres días después del "
                + "evento de aniversario. Motivo consignado en el formulario oficial: 'prefiero no "
                + "decirlo por escrito.'");
        empleado4.setFecha(LocalDate.of(1996, Month.DECEMBER, 21));
        registroLegadoRepository.save(empleado4);

        Pista pista7 = new Pista();
        pista7.setCaso(caso4);
        pista7.setRegistroOrigen(acta4);
        pista7.setDescripcion("El contrato con Carcosa incluye una cláusula que prohíbe expresamente "
                + "representar el Acto II. Nadie en el comité recuerda quién la propuso ni por qué.");
        pista7.setFraseGatillo("no proceder con la lectura del segundo acto");
        pistaRepository.save(pista7);

        Pista pista8 = new Pista();
        pista8.setCaso(caso4);
        pista8.setRegistroOrigen(memo4);
        pista8.setDescripcion("Cinco empleados pidieron cambio de área la misma semana, con la misma "
                + "frase exacta como motivo. Recursos Humanos decidió no investigar más a fondo.");
        pista8.setFraseGatillo("prefiero no decirlo por escrito");
        pistaRepository.save(pista8);

        Pista pista24 = new Pista();
        pista24.setCaso(caso4);
        pista24.setRegistroOrigen(factura4);
        pista24.setRegistroOrigen2(acta4);
        pista24.setDescripcion("La cláusula 4 del contrato aparece redactada con la misma tinta y "
                + "sello amarillo de la factura, aunque ningún miembro del comité recuerda haberla "
                + "negociado ni firmado ese documento.");
        pistaRepository.save(pista24);

        Pista pista31 = new Pista();
        pista31.setCaso(caso4);
        pista31.setRegistroOrigen(memo4);
        pista31.setRegistroOrigen2(empleado4);
        pista31.setDescripcion("Este es el primero de los cinco empleados que reportó Recursos Humanos "
                + "esa semana; es también el único cuyo nombre no aparece tachado en la lista interna "
                + "adjunta al memo.");
        pistaRepository.save(pista31);

        Sospechoso sospechosoCarcosa = new Sospechoso();
        sospechosoCarcosa.setCaso(caso4);
        sospechosoCarcosa.setNombre(CARCOSA_SERVICIOS_ESCENICOS);
        sospechosoCarcosa.setDescripcion("El proveedor contratado para el evento. Cobró un recargo "
                + "específico por no representar el Acto II.");
        sospechosoCarcosa.setDesenlace("Se cancela el contrato con Carcosa Servicios Escénicos para "
                + "futuros eventos. La empresa no tiene manera de notificarles: el domicilio fiscal "
                + "registrado corresponde a un teatro clausurado en 1962.");
        sospechosoRepository.save(sospechosoCarcosa);

        Sospechoso sospechosoComiteOrganizador = new Sospechoso();
        sospechosoComiteOrganizador.setCaso(caso4);
        sospechosoComiteOrganizador.setNombre("El comité organizador del evento");
        sospechosoComiteOrganizador.setDescripcion("Aprobó la cláusula que prohíbe el Acto II sin "
                + "discusión ni registro de quién la propuso.");
        sospechosoComiteOrganizador.setDesenlace("Se solicita al comité organizador una explicación "
                + "por no cuestionar la cláusula del Acto II. Ningún integrante recuerda haber estado "
                + "en la reunión donde se aprobó.");
        sospechosoRepository.save(sospechosoComiteOrganizador);

        Sospechoso sospechosoRRHH4 = new Sospechoso();
        sospechosoRRHH4.setCaso(caso4);
        sospechosoRRHH4.setNombre("Recursos Humanos");
        sospechosoRRHH4.setDescripcion("Recibió los cinco reportes de cambio de área la misma semana "
                + "y decidió no darles seguimiento.");
        sospechosoRRHH4.setDesenlace("Se instruye a Recursos Humanos investigar los cambios de área "
                + "solicitados esa semana. Recursos Humanos responde que, siguiendo su propia "
                + "recomendación anterior, no le dará seguimiento.");
        sospechosoRepository.save(sospechosoRRHH4);

        return new Caso4Pistas(pista7, pista8);
    }

    private Caso5Pistas seedCaso5() {
        Caso caso5 = new Caso();
        caso5.setTitulo("El expediente MEMO-1978-014 (y 1993, y 2007)");
        caso5.setDescripcion("Un memorándum con el mismo folio, la misma fecha de redacción y el mismo "
                + "texto letra por letra —incluida una falta de ortografía— aparece archivado por "
                + "separado en 1978, 1993 y 2007. La copia de 2007 incluye además una nota manuscrita "
                + "que se dirige, literalmente, 'al auditor que lo esté leyendo ahora'. Determinar "
                + "cuál copia es la original, si alguna lo es.");
        caso5.setAnioSuceso(1978);
        caso5.setEstado(EstadoCaso.ABIERTO);
        casoRepository.save(caso5);

        RegistroLegado memo5 = new RegistroLegado();
        memo5.setCaso(caso5);
        memo5.setTipo(TipoRegistro.MEMORANDO);
        memo5.setFolio("MEMO-1978-014");
        memo5.setContenido("Texto idéntico en las tres copias archivadas (1978, 1993, 2007), incluida "
                + "la misma falta de ortografía en la tercera línea. La copia de 2007 trae, al margen "
                + "y a mano: 'esto es para el auditor que lo esté leyendo ahora, sin importar cuándo "
                + "sea ahora.'");
        memo5.setFecha(LocalDate.of(2007, Month.APRIL, 9));
        registroLegadoRepository.save(memo5);

        RegistroLegado acta5 = new RegistroLegado();
        acta5.setCaso(caso5);
        acta5.setTipo(TipoRegistro.ACTA);
        acta5.setFolio("ACTA-2007-002");
        acta5.setContenido("Acta del Archivo Muerto: se deja constancia de que este expediente debe "
                + "'revisarse' aproximadamente cada quince años, aunque no existe razón administrativa "
                + "registrada para dicha periodicidad, ni acuerdo que la haya establecido.");
        acta5.setFecha(LocalDate.of(2007, Month.APRIL, 9));
        registroLegadoRepository.save(acta5);

        RegistroLegado empleado5 = new RegistroLegado();
        empleado5.setCaso(caso5);
        empleado5.setTipo(TipoRegistro.EMPLEADO);
        empleado5.setFolio("EMP-AUD-1993");
        empleado5.setContenido("Auditor predecesor, comisión especial de 1993. Nota de cierre de su "
                + "propio informe sobre este expediente, palabra por palabra idéntica a la que "
                + "cualquier auditor posterior redactaría al llegar a la misma conclusión.");
        empleado5.setFecha(LocalDate.of(1993, Month.MAY, 2));
        registroLegadoRepository.save(empleado5);

        Pista pista9 = new Pista();
        pista9.setCaso(caso5);
        pista9.setRegistroOrigen(memo5);
        pista9.setDescripcion("Las tres copias comparten folio, fecha y hasta errores de mecanografía "
                + "idénticos: algo imposible si en verdad fueron redactadas por separado.");
        pista9.setFraseGatillo("incluida la misma falta de ortografía en la tercera línea");
        pistaRepository.save(pista9);

        Pista pista10 = new Pista();
        pista10.setCaso(caso5);
        pista10.setRegistroOrigen(empleado5);
        pista10.setDescripcion("El informe de cierre del auditor de 1993 coincide, palabra por "
                + "palabra, con lo que el auditor actual está a punto de escribir.");
        pista10.setFraseGatillo("palabra por palabra idéntica a la que cualquier auditor posterior redactaría");
        pistaRepository.save(pista10);

        Pista pista25 = new Pista();
        pista25.setCaso(caso5);
        pista25.setRegistroOrigen(memo5);
        pista25.setRegistroOrigen2(empleado5);
        pista25.setDescripcion("La nota manuscrita en el margen del memo de 2007 y el informe de "
                + "cierre del auditor de 1993 están escritos con la misma letra, aunque fueron "
                + "encontrados en cajas archivadas catorce años y miles de kilómetros aparte.");
        pistaRepository.save(pista25);

        Pista pista32 = new Pista();
        pista32.setCaso(caso5);
        pista32.setRegistroOrigen(acta5);
        pista32.setRegistroOrigen2(memo5);
        pista32.setDescripcion("La periodicidad de revisión que fija esta acta coincide, año con año, "
                + "con las fechas de las tres copias del memo — como si ya se supiera, en 2007, cuándo "
                + "iba a aparecer la siguiente.");
        pistaRepository.save(pista32);

        Sospechoso sospechosoArchivoMuerto5 = new Sospechoso();
        sospechosoArchivoMuerto5.setCaso(caso5);
        sospechosoArchivoMuerto5.setNombre("El Archivo Muerto");
        sospechosoArchivoMuerto5.setDescripcion("El lugar donde conviven, sin explicación, las tres "
                + "copias del mismo memo.");
        sospechosoArchivoMuerto5.setDesenlace("Se ordena una auditoría al Archivo Muerto. La orden se "
                + "archiva, correctamente, en el Archivo Muerto.");
        sospechosoRepository.save(sospechosoArchivoMuerto5);

        Sospechoso sospechosoAuditor1993 = new Sospechoso();
        sospechosoAuditor1993.setCaso(caso5);
        sospechosoAuditor1993.setNombre("El auditor de 1993");
        sospechosoAuditor1993.setDescripcion("Escribió, palabra por palabra, la misma conclusión que "
                + "cualquier auditor posterior llegaría a escribir.");
        sospechosoAuditor1993.setDesenlace("Se le atribuye responsabilidad al auditor de la comisión "
                + "especial de 1993. No hay forma de notificarle: su expediente de personal tampoco "
                + "puede localizarse.");
        sospechosoRepository.save(sospechosoAuditor1993);

        Sospechoso sospechosoUsted5 = new Sospechoso();
        sospechosoUsted5.setCaso(caso5);
        sospechosoUsted5.setNombre("Usted mismo");
        sospechosoUsted5.setDescripcion("Quien firma este cierre ahora, sin importar cuándo sea "
                + "'ahora'.");
        sospechosoUsted5.setDesenlace("Se le atribuye la responsabilidad a quien firma este cierre. "
                + "Dado que usted es quien lo firma, el expediente queda, por primera vez en su "
                + "historia, formalmente resuelto. No hay precedente de qué hacer con esa "
                + "información.");
        sospechosoRepository.save(sospechosoUsted5);

        return new Caso5Pistas(pista9, pista10);
    }

    private Caso6Pistas seedCaso6() {
        Caso caso6 = new Caso();
        caso6.setTitulo("Acta constitutiva de la empresa (versión no circulada)");
        caso6.setDescripcion("En el fondo del Archivo Muerto hay una versión del acta constitutiva de "
                + "la empresa que nunca se hizo pública. En ella, el órgano fundador no es un consejo "
                + "de accionistas sino un 'Comité Ad Honorem' cuyo único objeto declarado es 'la "
                + "administración perpetua del expediente'. No lleva sello notarial: lleva el mismo "
                + "sello amarillo visto en la factura de Carcosa Servicios Escénicos de 1996. La "
                + "última página lista firmantes autorizados vigentes, y entre ellos ya aparece, con "
                + "fecha muy anterior a su contratación, el usuario del auditor que revisa este "
                + "expediente.");
        caso6.setAnioSuceso(1958);
        caso6.setEstado(EstadoCaso.ABIERTO);
        caso6.setConfidencial(true);
        casoRepository.save(caso6);

        RegistroLegado acta6 = new RegistroLegado();
        acta6.setCaso(caso6);
        acta6.setTipo(TipoRegistro.ACTA);
        acta6.setFolio("ACTA-1958-001");
        acta6.setContenido("Acta constitutiva, versión no circulada. Órgano fundador: 'Comité Ad "
                + "Honorem'. Objeto social declarado: 'la administración perpetua del expediente'. "
                + "Sellada con sello amarillo, no notarial, idéntico al usado por Carcosa Servicios "
                + "Escénicos en 1996.");
        acta6.setFecha(LocalDate.of(1958, Month.MARCH, 3));
        registroLegadoRepository.save(acta6);

        RegistroLegado circular6 = new RegistroLegado();
        circular6.setCaso(caso6);
        circular6.setTipo(TipoRegistro.CIRCULAR);
        circular6.setFolio("CIRC-0000-001");
        circular6.setContenido("El proceso de auditoría continuará sin interrupción, conforme al acta "
                + "fundacional, hasta que el expediente decida cerrarse por sí mismo. No se "
                + "establece fecha límite porque no corresponde establecerla.");
        circular6.setFecha(null);
        registroLegadoRepository.save(circular6);

        RegistroLegado fax6 = new RegistroLegado();
        fax6.setCaso(caso6);
        fax6.setTipo(TipoRegistro.FAX);
        fax6.setFolio("FAX-1996-077");
        fax6.setContenido("Transmisión entrante, calidad deficiente. Encabezado y pie de página "
                + "legibles; el cuerpo del mensaje está compuesto por trazos que no corresponden a "
                + "ningún alfabeto reconocido. El número de origen coincide con el registrado para "
                + "Carcosa Servicios Escénicos.");
        fax6.setFecha(LocalDate.of(1996, Month.DECEMBER, 17));
        registroLegadoRepository.save(fax6);

        RegistroLegado empleado6 = new RegistroLegado();
        empleado6.setCaso(caso6);
        empleado6.setTipo(TipoRegistro.EMPLEADO);
        empleado6.setFolio("EMP-0001");
        empleado6.setContenido("Lista de firmantes autorizados del Comité Ad Honorem, vigente desde su "
                + "fundación. Incluye el usuario 'auditor01', con fecha de alta anterior a cualquier "
                + "contratación registrada para dicho usuario en el sistema de nómina.");
        empleado6.setFecha(LocalDate.of(1958, Month.MARCH, 3));
        registroLegadoRepository.save(empleado6);

        Pista pista11 = new Pista();
        pista11.setCaso(caso6);
        pista11.setRegistroOrigen(acta6);
        pista11.setDescripcion("El sello del Comité Ad Honorem es idéntico al sello amarillo usado por "
                + "Carcosa Servicios Escénicos en la factura de 1996.");
        pista11.setFraseGatillo("Sellada con sello amarillo, no notarial");
        pistaRepository.save(pista11);

        Pista pista12 = new Pista();
        pista12.setCaso(caso6);
        pista12.setRegistroOrigen(empleado6);
        pista12.setDescripcion("La lista de firmantes autorizados del comité ya incluye al usuario del "
                + "auditor actual, con una fecha de alta anterior a su propia contratación.");
        pista12.setFraseGatillo("con fecha de alta anterior a cualquier contratación registrada");
        pistaRepository.save(pista12);

        Pista pista13 = new Pista();
        pista13.setCaso(caso6);
        pista13.setRegistroOrigen(circular6);
        pista13.setDescripcion("La circular que rige la auditoría no tiene fecha de emisión ni de "
                + "cierre. Conforme al acta fundacional, el expediente se cerrará solo cuando decida "
                + "hacerlo.");
        pista13.setFraseGatillo("hasta que el expediente decida cerrarse por sí mismo");
        pistaRepository.save(pista13);

        Pista pista26 = new Pista();
        pista26.setCaso(caso6);
        pista26.setRegistroOrigen(acta6);
        pista26.setRegistroOrigen2(fax6);
        pista26.setDescripcion("El número de origen del fax coincide con el registrado en la factura "
                + "de Carcosa de 1996, pero la línea telefónica correspondiente fue dada de baja, "
                + "según los registros de la compañía telefónica, en 1962.");
        pistaRepository.save(pista26);

        Pista pista33 = new Pista();
        pista33.setCaso(caso6);
        pista33.setRegistroOrigen(circular6);
        pista33.setRegistroOrigen2(empleado6);
        pista33.setDescripcion("La circular sin fecha límite y la lista de firmantes de 1958 se "
                + "imprimieron, según los metadatos conservados, con la misma impresora — un modelo que "
                + "la empresa no adquirió sino hasta 1989.");
        pistaRepository.save(pista33);

        Sospechoso sospechosoComite6 = new Sospechoso();
        sospechosoComite6.setCaso(caso6);
        sospechosoComite6.setNombre("El Comité Ad Honorem");
        sospechosoComite6.setDescripcion("El órgano que ha autorizado todo desde 1958 sin figurar en "
                + "ningún organigrama.");
        sospechosoComite6.setDesenlace("Se presenta la acusación ante el Comité Ad Honorem. El comité "
                + "la recibe, la sella con el mismo sello amarillo de siempre, y la incorpora al acta "
                + "fundacional como el artículo que faltaba. El expediente queda, oficialmente, más "
                + "completo que antes.");
        sospechosoComite6.setAtaques(Arrays.asList(
                "El Comité solicita que la acusación se presente por triplicado, en el formato vigente en 1958.",
                "El Comité informa que ese formato fue derogado por un acuerdo del propio Comité, no localizado "
                        + "en el archivo.",
                "El Comité cita el artículo 4 del acta fundacional: toda objeción en su contra se considera, "
                        + "automáticamente, parte del acta."));
        sospechosoRepository.save(sospechosoComite6);

        Sospechoso sospechosoCarcosa6 = new Sospechoso();
        sospechosoCarcosa6.setCaso(caso6);
        sospechosoCarcosa6.setNombre(CARCOSA_SERVICIOS_ESCENICOS);
        sospechosoCarcosa6.setDescripcion("La compañía teatral cuyo sello amarillo es idéntico al del "
                + "comité fundador.");
        sospechosoCarcosa6.setDesenlace("Se presenta la acusación contra Carcosa Servicios Escénicos. "
                + "No hay a quién notificar: su domicilio fiscal es un teatro que, según el catastro, "
                + "jamás terminó de construirse.");
        sospechosoCarcosa6.setAtaques(Arrays.asList(
                "Carcosa contesta que la acusación corresponde, en realidad, a una reseña del Acto I, y la "
                        + "archiva como tal.",
                "Carcosa ofrece un descuento del 15% en la próxima puesta en escena si se retira el cargo.",
                "Carcosa advierte que insistir obliga a representar el Acto II completo, ante todos los "
                        + "presentes."));
        sospechosoRepository.save(sospechosoCarcosa6);

        Sospechoso sospechosoAuditor1958 = new Sospechoso();
        sospechosoAuditor1958.setCaso(caso6);
        sospechosoAuditor1958.setNombre("auditor01 (usted, desde 1958)");
        sospechosoAuditor1958.setDescripcion("El firmante que ya figuraba en la lista autorizada "
                + "décadas antes de existir.");
        sospechosoAuditor1958.setDesenlace("Se presenta la acusación contra el firmante registrado "
                + "desde 1958. Es usted. El sistema acepta la acusación sin objeción: en el fondo, "
                + "siempre fue lo único congruente que se podía escribir en este expediente.");
        sospechosoAuditor1958.setAtaques(Arrays.asList(
                "Usted intenta objetar. La objeción ya está redactada, con su letra, en un documento de 1958.",
                "Revisa la fecha de alta que consta a su nombre: es anterior a la de esta objeción.",
                "No hay forma de acusarse a uno mismo sin, con ello, ratificar la propia firma."));
        sospechosoRepository.save(sospechosoAuditor1958);

        Sospechoso sospechosoSiga6 = new Sospechoso();
        sospechosoSiga6.setCaso(caso6);
        sospechosoSiga6.setNombre("SIGA (el sistema mismo)");
        sospechosoSiga6.setDescripcion("El propio sistema que procesa esta acusación.");
        sospechosoSiga6.setDesenlace("Se presenta la acusación contra el sistema SIGA. No existe un "
                + "formulario diseñado para acusar al sistema que procesa las acusaciones. La pantalla "
                + "parpadea, marca las 11:34, y no vuelve a actualizarse durante el resto de su "
                + "turno.");
        sospechosoSiga6.setAtaques(Arrays.asList(
                "El sistema responde con el mismo formulario que usted acaba de enviar, sin cambios.",
                "El sistema marca la hora: 11:34. Sigue marcando las 11:34.",
                "El sistema le informa que su sesión, técnicamente, nunca ha comenzado."));
        sospechosoRepository.save(sospechosoSiga6);

        return new Caso6Pistas(pista11, pista12, pista13);
    }

    private void seedCorchoPrincipal(Caso1Pistas caso1Pistas, Caso2Pistas caso2Pistas,
                                      Caso3Pistas caso3Pistas, Caso4Pistas caso4Pistas,
                                      Caso5Pistas caso5Pistas, Caso6Pistas caso6Pistas,
                                      Caso7Pistas caso7Pistas, Caso8Pistas caso8Pistas) {
        Concepto conceptoComite = new Concepto();
        conceptoComite.setNombre("Comité Ad Honorem");
        conceptoComite.setTipo(ConceptoTipo.COMITE);
        conceptoComite.setResumen("Órgano que autoriza decisiones desde al menos 1958 sin figurar "
                + "jamás en un organigrama oficial. Ordenó el traslado de [[E. Montalvo]] a un piso "
                + "que no existe, y redactó una versión no circulada del acta constitutiva de la "
                + "empresa. Su sello es idéntico al de [[Carcosa Servicios Escénicos]]. El mismo patrón "
                + "de cierres sin preguntas reaparece en el expediente de [[P. Smerdiakov]], años antes "
                + "de que el Comité existiera oficialmente en ningún papel. La fórmula de su acta "
                + "fundacional reaparece, palabra por palabra, en la creación del "
                + "[[Comité de Bienestar Laboral]] de 1988.");
        conceptoComite.setPistas(Arrays.asList(caso2Pistas.pista3(), caso3Pistas.pista6(),
                caso6Pistas.pista11(), caso6Pistas.pista12(), caso6Pistas.pista13(),
                caso7Pistas.pista15()));
        conceptoRepository.save(conceptoComite);

        Concepto conceptoBienestar = new Concepto();
        conceptoBienestar.setNombre("Comité de Bienestar Laboral");
        conceptoBienestar.setTipo(ConceptoTipo.COMITE);
        conceptoBienestar.setResumen("Creado en 1988 para dictaminar solicitudes de mobiliario "
                + "especial. No ha alcanzado quórum ni una sola vez desde su fundación, lo que dejó "
                + "seis años en trámite la silla de R. Salcido. Su acta de creación reproduce, "
                + "palabra por palabra, la fórmula del acta fundacional del [[Comité Ad Honorem]] de "
                + "1958 — incluida la cláusula que define el quórum de un modo que ningún número de "
                + "asistentes puede satisfacer.");
        conceptoBienestar.setPistas(Arrays.asList(caso2Pistas.pista3(), caso2Pistas.pista22()));
        conceptoRepository.save(conceptoBienestar);

        Concepto conceptoCarcosa = new Concepto();
        conceptoCarcosa.setNombre("Carcosa Servicios Escénicos");
        conceptoCarcosa.setTipo(ConceptoTipo.EMPRESA);
        conceptoCarcosa.setResumen("Proveedor contratado en 1996 para el evento de aniversario. Cobró "
                + "un recargo específico por NO representar el segundo acto de su montaje, "
                + "[[El Rey de Amarillo (Acto II)]]. Selló su factura con un sello amarillo que no "
                + "corresponde a ningún notario ni al sello oficial de la empresa: el mismo que usa el "
                + "[[Comité Ad Honorem]]. La dirección fiscal de su contrato reaparece en 1999, "
                + "declarada por [[El proveedor sin RFC]] del cierre de caja.");
        conceptoCarcosa.setPistas(Arrays.asList(caso1Pistas.pista20(), caso4Pistas.pista7(),
                caso4Pistas.pista8(), caso6Pistas.pista11()));
        conceptoRepository.save(conceptoCarcosa);

        Concepto conceptoProveedor = new Concepto();
        conceptoProveedor.setNombre("El proveedor sin RFC");
        conceptoProveedor.setTipo(ConceptoTipo.EMPRESA);
        conceptoProveedor.setResumen("Cobró $482,000 por 'servicios de consultoría' el 30/12/1999, "
                + "autorizado sin revisión previa y aprobado por Contraloría en cinco minutos. El "
                + "registro mercantil no lo conoce. La dirección fiscal declarada en su factura "
                + "coincide con la que usó [[Carcosa Servicios Escénicos]] en su contrato de 1996 — "
                + "un local que, según el padrón municipal, lleva vacío desde 1994.");
        conceptoProveedor.setPistas(Arrays.asList(caso1Pistas.pista20()));
        conceptoRepository.save(conceptoProveedor);

        Concepto conceptoActoII = new Concepto();
        conceptoActoII.setNombre("El Rey de Amarillo (Acto II)");
        conceptoActoII.setTipo(ConceptoTipo.DOCUMENTO);
        conceptoActoII.setResumen("Segundo acto de la obra montada por [[Carcosa Servicios Escénicos]] "
                + "en la fiesta de aniversario de 1996. El contrato prohíbe expresamente "
                + "representarlo. Nadie en el comité organizador recuerda quién propuso esa cláusula, "
                + "ni por qué el Acto I bastó para que varios asistentes pidieran cambio de área la "
                + "misma semana.");
        conceptoActoII.setPistas(Arrays.asList(caso4Pistas.pista7()));
        conceptoRepository.save(conceptoActoII);

        Concepto conceptoPiso13 = new Concepto();
        conceptoPiso13.setNombre("El piso 13 / Enlace Especial");
        conceptoPiso13.setTipo(ConceptoTipo.LUGAR);
        conceptoPiso13.setResumen("Destino del traslado de [[E. Montalvo]] en 1993, según un "
                + "memorándum sellado de recibido. El edificio, de acuerdo con todos los planos "
                + "vigentes, tiene doce pisos. La orden de traslado la firmó el [[Comité Ad "
                + "Honorem]].");
        conceptoPiso13.setPistas(Arrays.asList(caso3Pistas.pista5(), caso3Pistas.pista6()));
        conceptoRepository.save(conceptoPiso13);

        Concepto conceptoMontalvo = new Concepto();
        conceptoMontalvo.setNombre("E. Montalvo");
        conceptoMontalvo.setTipo(ConceptoTipo.PERSONA);
        conceptoMontalvo.setResumen("Auxiliar administrativo 1988-1993. Trasladado a "
                + "[[El piso 13 / Enlace Especial]] por instrucción del [[Comité Ad Honorem]]. No hay "
                + "renuncia, baja ni recibo de nómina posterior a la fecha del traslado.");
        conceptoMontalvo.setPistas(Arrays.asList(caso3Pistas.pista5()));
        conceptoRepository.save(conceptoMontalvo);

        Concepto conceptoMemoRepetido = new Concepto();
        conceptoMemoRepetido.setNombre("El expediente que se repite (MEMO-1978-014)");
        conceptoMemoRepetido.setTipo(ConceptoTipo.DOCUMENTO);
        conceptoMemoRepetido.setResumen("Un memorándum con folio, fecha y errores de mecanografía "
                + "idénticos aparece archivado por separado en 1978, 1993 y 2007. La copia más "
                + "reciente incluye una nota dirigida, literalmente, a quien lo esté leyendo ahora. "
                + "Guardado en el [[Archivo Muerto]].");
        conceptoMemoRepetido.setPistas(Arrays.asList(caso5Pistas.pista9(), caso5Pistas.pista10()));
        conceptoRepository.save(conceptoMemoRepetido);

        Concepto conceptoArchivoMuerto = new Concepto();
        conceptoArchivoMuerto.setNombre("Archivo Muerto");
        conceptoArchivoMuerto.setTipo(ConceptoTipo.LUGAR);
        conceptoArchivoMuerto.setResumen("Depósito de expedientes que, según un acta de 2007, deben "
                + "'revisarse' cada quince años sin que exista razón administrativa registrada para "
                + "ello. Ahí apareció también la versión no circulada del acta fundacional del "
                + "[[Comité Ad Honorem]], de 1958. Ahí, tarde o temprano, terminan también los "
                + "expedientes sin remitente ni destino claro, como el de [[Empleado #427]].");
        conceptoArchivoMuerto.setPistas(Arrays.asList(caso5Pistas.pista9(), caso8Pistas.pista19()));
        conceptoRepository.save(conceptoArchivoMuerto);

        Concepto conceptoAuditor = new Concepto();
        conceptoAuditor.setNombre("auditor01 (usted)");
        conceptoAuditor.setTipo(ConceptoTipo.PERSONA);
        conceptoAuditor.setResumen("Su propio usuario figura en la lista de firmantes autorizados del "
                + "[[Comité Ad Honorem]] desde 1958, con una fecha de alta muy anterior a su "
                + "contratación real. No hay una explicación administrativa registrada para ello. "
                + "Tampoco se ha solicitado una.");
        conceptoAuditor.setPistas(Arrays.asList(caso6Pistas.pista12()));
        conceptoRepository.save(conceptoAuditor);

        Concepto conceptoEpilogo = new Concepto();
        conceptoEpilogo.setNombre("Memorándum de acreditación especial");
        conceptoEpilogo.setTipo(ConceptoTipo.DOCUMENTO);
        conceptoEpilogo.setResumen("Para: auditor en turno. Habiendo dado cierre a los cinco "
                + "expedientes bajo su cargo, se le concede acceso temporal a los archivos del "
                + "[[Comité Ad Honorem]], en los términos del acta fundacional. Usuario: enlace13. "
                + "Clave de acceso: hastur-local-13. Esta acreditación no requiere renovación ni caduca: "
                + "simplemente, no se ha previsto ese caso.");
        conceptoEpilogo.setEpilogo(true);
        conceptoRepository.save(conceptoEpilogo);
    }

    private Caso7Pistas seedCaso7() {
        Caso caso7 = new Caso();
        caso7.setTitulo("El expediente de la herencia Karamázov");
        caso7.setDescripcion("Tras la muerte repentina de F. P. Karamázov, fundador y accionista "
                + "mayoritario, sus tres hijos reclamaron una herencia de $3,000,000 en acciones que "
                + "nunca se formalizó en ningún testamento. Uno de ellos fue despedido y señalado por "
                + "Recursos Humanos como responsable de la desaparición de los fondos; el expediente "
                + "de su defensa nunca llegó a revisarse.");
        caso7.setAnioSuceso(1998);
        caso7.setEstado(EstadoCaso.CERRADO);
        caso7.setPrincipal(false);
        casoRepository.save(caso7);

        RegistroLegado empleadoD = new RegistroLegado();
        empleadoD.setCaso(caso7);
        empleadoD.setTipo(TipoRegistro.EMPLEADO);
        empleadoD.setFolio("EMP-0512");
        empleadoD.setContenido("D. Karamázov. Gerente de Ventas 1990-1998. Reclamó por escrito, en al "
                + "menos tres juntas, el dinero que su padre le adeudaba. Despedido el 14/09/1998 por "
                + "'conducta impropia', cuatro días después de la desaparición de los fondos.");
        empleadoD.setFecha(LocalDate.of(1998, Month.SEPTEMBER, 14));
        registroLegadoRepository.save(empleadoD);

        RegistroLegado memoI = new RegistroLegado();
        memoI.setCaso(caso7);
        memoI.setTipo(TipoRegistro.MEMORANDO);
        memoI.setFolio("MEMO-1998-091");
        memoI.setContenido("De: I. Karamázov, Departamento de Planeación. Circular interna sin "
                + "destinatario claro: 'Si ningún superior revisa jamás un expediente, entonces todo "
                + "lo que hagamos con él está permitido.' Distribuida por correo interno una semana "
                + "antes del cierre de caja.");
        memoI.setFecha(LocalDate.of(1998, Month.SEPTEMBER, 6));
        registroLegadoRepository.save(memoI);

        RegistroLegado empleadoSmerdiakov = new RegistroLegado();
        empleadoSmerdiakov.setCaso(caso7);
        empleadoSmerdiakov.setTipo(TipoRegistro.EMPLEADO);
        empleadoSmerdiakov.setFolio("EMP-0533");
        empleadoSmerdiakov.setContenido("P. Smerdiakov. Asistente personal de F. P. Karamázov, único "
                + "empleado con llave de la caja fuerte. Falleció el 20/09/1998, seis días después de "
                + "la desaparición de los fondos. Recursos Humanos cerró su expediente sin abrir "
                + "investigación.");
        empleadoSmerdiakov.setFecha(LocalDate.of(1998, Month.SEPTEMBER, 20));
        registroLegadoRepository.save(empleadoSmerdiakov);

        RegistroLegado oficioA = new RegistroLegado();
        oficioA.setCaso(caso7);
        oficioA.setTipo(TipoRegistro.OFICIO);
        oficioA.setFolio("OF-1998-077");
        oficioA.setContenido("A. Karamázov solicita la reapertura del caso de su hermano D. Karamázov, "
                + "argumentando que la acusación se basó solo en reclamos verbales, no en evidencia de "
                + "acceso a la caja fuerte. Respuesta de Contraloría: 'Procedimiento cerrado, no ha "
                + "lugar.'");
        oficioA.setFecha(LocalDate.of(1998, Month.OCTOBER, 2));
        registroLegadoRepository.save(oficioA);

        Pista pista14 = new Pista();
        pista14.setCaso(caso7);
        pista14.setRegistroOrigen(memoI);
        pista14.setDescripcion("El memorándum de I. Karamázov circuló apenas una semana antes de la "
                + "desaparición de los fondos, y llegó por correo interno a todo el personal con "
                + "llave de la caja fuerte.");
        pista14.setFraseGatillo("una semana antes del cierre de caja");
        pistaRepository.save(pista14);

        Pista pista15 = new Pista();
        pista15.setCaso(caso7);
        pista15.setRegistroOrigen(empleadoSmerdiakov);
        pista15.setDescripcion("El único empleado con acceso a la caja fuerte falleció seis días "
                + "después de los hechos, sin que Recursos Humanos abriera investigación alguna sobre "
                + "su fallecimiento.");
        pista15.setFraseGatillo("sin abrir investigación");
        pistaRepository.save(pista15);

        Pista pista16 = new Pista();
        pista16.setCaso(caso7);
        pista16.setRegistroOrigen(empleadoD);
        pista16.setDescripcion("La acusación contra D. Karamázov se basó únicamente en sus reclamos "
                + "públicos por escrito; nadie verificó si tuvo acceso real a la caja fuerte.");
        pista16.setFraseGatillo("cuatro días después de la desaparición de los fondos");
        pistaRepository.save(pista16);

        Concepto conceptoDKaramazov = new Concepto();
        conceptoDKaramazov.setNombre("D. Karamázov");
        conceptoDKaramazov.setTipo(ConceptoTipo.PERSONA);
        conceptoDKaramazov.setResumen("Gerente de Ventas despedido por 'conducta impropia' cuatro días "
                + "después de la desaparición de los fondos de su padre. La acusación en su contra se "
                + "basó solo en sus reclamos por escrito, nunca en evidencia de acceso a la caja "
                + "fuerte, que sí tenía [[P. Smerdiakov]].");
        conceptoDKaramazov.setPistas(Arrays.asList(pista16));
        conceptoRepository.save(conceptoDKaramazov);

        Concepto conceptoIKaramazov = new Concepto();
        conceptoIKaramazov.setNombre("I. Karamázov");
        conceptoIKaramazov.setTipo(ConceptoTipo.PERSONA);
        conceptoIKaramazov.setResumen("Del Departamento de Planeación. Distribuyó una circular interna "
                + "una semana antes de la desaparición de los fondos, argumentando que sin revisión "
                + "todo está permitido. La leyó, entre otros, [[P. Smerdiakov]].");
        conceptoIKaramazov.setPistas(Arrays.asList(pista14));
        conceptoRepository.save(conceptoIKaramazov);

        Concepto conceptoSmerdiakov = new Concepto();
        conceptoSmerdiakov.setNombre("P. Smerdiakov");
        conceptoSmerdiakov.setTipo(ConceptoTipo.PERSONA);
        conceptoSmerdiakov.setResumen("Único empleado con llave de la caja fuerte. Falleció seis días "
                + "después de la desaparición de los fondos; Recursos Humanos cerró su expediente sin "
                + "preguntar por qué, poco después de que circulara el memorándum de [[I. "
                + "Karamázov]]. El mismo silencio administrativo, el mismo cierre sin explicación, "
                + "reaparece décadas después en los expedientes que ya autoriza el [[Comité Ad "
                + "Honorem]].");
        conceptoSmerdiakov.setPistas(Arrays.asList(pista15));
        conceptoRepository.save(conceptoSmerdiakov);

        Pista pista21 = new Pista();
        pista21.setCaso(caso7);
        pista21.setRegistroOrigen(memoI);
        pista21.setRegistroOrigen2(empleadoSmerdiakov);
        pista21.setDescripcion("El memo de I. Karamázov fue sellado de recibido por P. Smerdiakov el "
                + "mismo día en que este retiró la llave de la caja fuerte de su cajón habitual.");
        pistaRepository.save(pista21);

        Pista pista34 = new Pista();
        pista34.setCaso(caso7);
        pista34.setRegistroOrigen(empleadoD);
        pista34.setRegistroOrigen2(oficioA);
        pista34.setDescripcion("La solicitud de reapertura de A. Karamázov está fechada el mismo día en "
                + "que, según el expediente de su hermano, Contraloría ya había archivado el caso como "
                + "'sin elementos adicionales' — antes de recibir la solicitud.");
        pistaRepository.save(pista34);

        Sospechoso sospechosoD = new Sospechoso();
        sospechosoD.setCaso(caso7);
        sospechosoD.setNombre("D. Karamázov");
        sospechosoD.setDescripcion("Reclamó públicamente el dinero que su padre le debía. Fue "
                + "despedido cuatro días después de la desaparición de los fondos.");
        sospechosoD.setDesenlace("Se ratifica el despido de D. Karamázov. Nadie investiga si tuvo "
                + "acceso real a los fondos. Expediente cerrado por segunda vez, con el mismo error "
                + "que la primera.");
        sospechosoRepository.save(sospechosoD);

        Sospechoso sospechosoI = new Sospechoso();
        sospechosoI.setCaso(caso7);
        sospechosoI.setNombre("I. Karamázov");
        sospechosoI.setDescripcion("Distribuyó una circular argumentando que, sin revisión, todo está "
                + "permitido, justo antes de la desaparición de los fondos.");
        sospechosoI.setDesenlace("Se le cita a comparecer por 'responsabilidad intelectual' sobre la "
                + "circular. La empresa no cuenta con ningún procedimiento para sancionar una idea, "
                + "así que el citatorio se archiva sin trámite posterior.");
        sospechosoRepository.save(sospechosoI);

        Sospechoso sospechosoSmerdiakovAcusado = new Sospechoso();
        sospechosoSmerdiakovAcusado.setCaso(caso7);
        sospechosoSmerdiakovAcusado.setNombre("P. Smerdiakov");
        sospechosoSmerdiakovAcusado.setDescripcion("Único empleado con llave de la caja fuerte. "
                + "Falleció seis días después de los hechos.");
        sospechosoSmerdiakovAcusado.setDesenlace("Se emite responsiva en contra de un empleado "
                + "fallecido. Recursos Humanos confirma que, en efecto, no hay impedimento normativo "
                + "para ello.");
        sospechosoRepository.save(sospechosoSmerdiakovAcusado);

        Sospechoso sospechosoA = new Sospechoso();
        sospechosoA.setCaso(caso7);
        sospechosoA.setNombre("A. Karamázov");
        sospechosoA.setDescripcion("El único hermano que pidió reabrir el caso, argumentando que la "
                + "acusación original no tenía sustento.");
        sospechosoA.setDesenlace("Se le atribuye responsabilidad por 'exceso de insistencia en la "
                + "reapertura del caso'. Es la primera vez que solicitar una revisión se documenta "
                + "como falta administrativa.");
        sospechosoRepository.save(sospechosoA);

        return new Caso7Pistas(pista15);
    }

    private Caso8Pistas seedCaso8() {
        Caso caso8 = new Caso();
        caso8.setTitulo("El expediente del empleado #427");
        caso8.setDescripcion("El registro de nómina identifica a este empleado únicamente como '#427'. "
                + "Su descripción de funciones, íntegra, dice: 'Presionar el botón cuando el sistema "
                + "lo requiera.' Existen al menos tres actas de cierre para este expediente, cada una "
                + "con un desenlace distinto e incompatible con las demás, las tres fechadas el mismo "
                + "día.");
        // El suceso son las tres actas de cierre incompatibles, las tres del
        // 05/11/1998. El registro de empleado es de 1983, pero eso es cuando
        // entro, no cuando paso lo que se investiga.
        caso8.setAnioSuceso(1998);
        caso8.setEstado(EstadoCaso.ABIERTO);
        caso8.setPrincipal(false);
        casoRepository.save(caso8);

        RegistroLegado empleado427 = new RegistroLegado();
        empleado427.setCaso(caso8);
        empleado427.setTipo(TipoRegistro.EMPLEADO);
        empleado427.setFolio("EMP-0427");
        empleado427.setContenido("#427. Puesto: Operador de terminal, función C. Descripción de "
                + "funciones íntegra: 'Presionar el botón cuando el sistema lo requiera.' Quince años "
                + "de antigüedad. Sin evaluaciones de desempeño registradas. Sin nombre en el campo "
                + "correspondiente.");
        empleado427.setFecha(LocalDate.of(1983, Month.JANUARY, 10));
        registroLegadoRepository.save(empleado427);

        RegistroLegado actaA = new RegistroLegado();
        actaA.setCaso(caso8);
        actaA.setTipo(TipoRegistro.ACTA);
        actaA.setFolio("ACTA-1998-427A");
        actaA.setContenido("Se determinó que el empleado #427 fue reasignado a labores de "
                + "conserjería en el sótano, donde permanece. Cierre definitivo del expediente.");
        actaA.setFecha(LocalDate.of(1998, Month.NOVEMBER, 5));
        registroLegadoRepository.save(actaA);

        RegistroLegado actaB = new RegistroLegado();
        actaB.setCaso(caso8);
        actaB.setTipo(TipoRegistro.ACTA);
        actaB.setFolio("ACTA-1998-427B");
        actaB.setContenido("Se determinó que el empleado #427 abandonó el inmueble por una ventana "
                + "del cuarto piso. No hubo testigos. Cierre definitivo del expediente.");
        actaB.setFecha(LocalDate.of(1998, Month.NOVEMBER, 5));
        registroLegadoRepository.save(actaB);

        RegistroLegado actaC = new RegistroLegado();
        actaC.setCaso(caso8);
        actaC.setTipo(TipoRegistro.ACTA);
        actaC.setFolio("ACTA-1998-427C");
        actaC.setContenido("Se determinó que las instalaciones fueron desmanteladas por completo "
                + "cuarenta y ocho horas después de iniciada esta investigación, incluido el "
                + "expediente mismo, que sin embargo usted sigue leyendo. Cierre definitivo del "
                + "expediente.");
        actaC.setFecha(LocalDate.of(1998, Month.NOVEMBER, 5));
        registroLegadoRepository.save(actaC);

        RegistroLegado fax427 = new RegistroLegado();
        fax427.setCaso(caso8);
        fax427.setTipo(TipoRegistro.FAX);
        fax427.setFolio("FAX-1998-427");
        fax427.setContenido("Transmisión sin remitente identificado, sin registro de envío ni de "
                + "recepción. El texto dice, en su totalidad: 'Muy bien. Ha llegado hasta aquí.'");
        fax427.setFecha(LocalDate.of(1998, Month.NOVEMBER, 5));
        registroLegadoRepository.save(fax427);

        Pista pista17 = new Pista();
        pista17.setCaso(caso8);
        pista17.setRegistroOrigen(actaA);
        pista17.setDescripcion("Las tres actas de cierre están fechadas el mismo día y a la misma "
                + "hora, y ninguna hace referencia a las otras dos.");
        pista17.setFraseGatillo("reasignado a labores de conserjería en el sótano");
        pistaRepository.save(pista17);

        Pista pista18 = new Pista();
        pista18.setCaso(caso8);
        pista18.setRegistroOrigen(empleado427);
        pista18.setDescripcion("La descripción de funciones de #427 nunca fue cuestionada en quince "
                + "años: presionar un botón, sin más contexto administrativo ni evaluación alguna.");
        pista18.setFraseGatillo("Sin evaluaciones de desempeño registradas");
        pistaRepository.save(pista18);

        Pista pista19 = new Pista();
        pista19.setCaso(caso8);
        pista19.setRegistroOrigen(fax427);
        pista19.setDescripcion("La transmisión sin remitente se dirige directamente a quien consulta "
                + "el expediente, sin importar cuál de las tres actas haya leído primero.");
        pista19.setFraseGatillo("Ha llegado hasta aquí");
        pistaRepository.save(pista19);

        Concepto concepto427 = new Concepto();
        concepto427.setNombre("Empleado #427");
        concepto427.setTipo(ConceptoTipo.PERSONA);
        concepto427.setResumen("Quince años presionando un botón sin que nadie preguntara para qué. "
                + "Su expediente tiene tres actas de cierre incompatibles entre sí, y después llegó "
                + "[[La transmisión sin remitente]].");
        concepto427.setPistas(Arrays.asList(pista18));
        conceptoRepository.save(concepto427);

        Concepto conceptoTransmision = new Concepto();
        conceptoTransmision.setNombre("La transmisión sin remitente");
        conceptoTransmision.setTipo(ConceptoTipo.DOCUMENTO);
        conceptoTransmision.setResumen("Un fax sin origen registrado, llegado el mismo día de las tres "
                + "actas de cierre de [[Empleado #427]]. No dice a quién va dirigido, y aun así parece "
                + "saber exactamente quién lo está leyendo. Expedientes así, sin remitente ni destino "
                + "claro, suelen terminar en el [[Archivo Muerto]].");
        conceptoTransmision.setPistas(Arrays.asList(pista19));
        conceptoRepository.save(conceptoTransmision);

        Pista pista27 = new Pista();
        pista27.setCaso(caso8);
        pista27.setRegistroOrigen(empleado427);
        pista27.setRegistroOrigen2(fax427);
        pista27.setDescripcion("El campo de nombre en el expediente de #427 nunca estuvo lleno. Nadie "
                + "había notado, hasta ahora, que el campo de remitente del fax tampoco lo está: los "
                + "dos huecos coinciden en formato, como si fueran el mismo campo repetido dos veces.");
        pistaRepository.save(pista27);

        Pista pista35 = new Pista();
        pista35.setCaso(caso8);
        pista35.setRegistroOrigen(actaB);
        pista35.setRegistroOrigen2(actaC);
        pista35.setDescripcion("El Acta B dice que #427 salió por una ventana del cuarto piso; el Acta C "
                + "dice que las instalaciones fueron desmanteladas cuarenta y ocho horas después de "
                + "iniciar la investigación. Ninguna de las dos actas fue escrita después de la otra: "
                + "comparten la misma hora de firma.");
        pistaRepository.save(pista35);

        Sospechoso sospechosoConserjeria = new Sospechoso();
        sospechosoConserjeria.setCaso(caso8);
        sospechosoConserjeria.setNombre("Conserjería del sótano");
        sospechosoConserjeria.setDescripcion("Según el Acta A, ahí fue reasignado el empleado #427.");
        sospechosoConserjeria.setDesenlace("Se presenta la acusación ante Conserjería. Confirman que "
                + "#427 nunca se ha presentado a laborar ahí, aunque su gafete sigue registrado en la "
                + "lista de asistencia diaria.");
        sospechosoRepository.save(sospechosoConserjeria);

        Sospechoso sospechosoMantenimiento = new Sospechoso();
        sospechosoMantenimiento.setCaso(caso8);
        sospechosoMantenimiento.setNombre("Mantenimiento de la cuarta planta");
        sospechosoMantenimiento.setDescripcion("Según el Acta B, por su ventana salió el empleado "
                + "#427.");
        sospechosoMantenimiento.setDesenlace("Se presenta la acusación ante Mantenimiento. Confirman "
                + "que la ventana en cuestión no puede abrirse: está sellada desde la construcción del "
                + "edificio.");
        sospechosoRepository.save(sospechosoMantenimiento);

        Sospechoso sospechosoEmpresaDesmantelada = new Sospechoso();
        sospechosoEmpresaDesmantelada.setCaso(caso8);
        sospechosoEmpresaDesmantelada.setNombre("La empresa que ya no existe");
        sospechosoEmpresaDesmantelada.setDescripcion("Según el Acta C, desmantelada por completo "
                + "cuarenta y ocho horas después de iniciada la investigación.");
        sospechosoEmpresaDesmantelada.setDesenlace("Se presenta la acusación contra una empresa que, "
                + "según las actas, fue desmantelada hace décadas. La acusación se procesa con "
                + "normalidad. Aparentemente, alguien sigue ahí para recibirla.");
        sospechosoRepository.save(sospechosoEmpresaDesmantelada);

        Sospechoso sospechosoUsted8 = new Sospechoso();
        sospechosoUsted8.setCaso(caso8);
        sospechosoUsted8.setNombre("Usted");
        sospechosoUsted8.setDescripcion("Quien está leyendo el expediente ahora mismo, a quien se "
                + "dirige la transmisión sin remitente.");
        sospechosoUsted8.setDesenlace("Se presenta la acusación contra quien está leyendo el "
                + "expediente. No hay una casilla pensada para esta respuesta, así que el sistema la "
                + "registra igual, en blanco, bajo el nombre '#427'.");
        sospechosoRepository.save(sospechosoUsted8);

        return new Caso8Pistas(pista19);
    }
}
