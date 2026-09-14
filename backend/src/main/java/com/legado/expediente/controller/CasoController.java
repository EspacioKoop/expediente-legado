package com.legado.expediente.controller;

import com.legado.expediente.model.Caso;
import com.legado.expediente.model.CombateEnCurso;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.Rol;
import com.legado.expediente.model.Sospechoso;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.model.Veredicto;
import com.legado.expediente.repository.CasoRepository;
import com.legado.expediente.service.ResumenJuegoService;
import com.legado.expediente.service.InvestigacionCasoService;
import com.legado.expediente.service.ResolucionCasoService;
import com.legado.expediente.service.UsuarioContexto;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Optional;

@Controller
public class CasoController {

    private static final String ATRIBUTO_MENSAJE = "mensaje";
    private static final String RUTA_CASOS = "redirect:/casos/";
    private static final String RUTA_INICIO = "redirect:/";
    private static final String MENSAJE_ACCESO_DENEGADO =
            "Solicitud denegada. Nivel de acreditación insuficiente para este expediente.";

    private final CasoRepository casoRepository;
    private final InvestigacionCasoService investigacionCasoService;
    private final ResolucionCasoService resolucionCasoService;
    private final ResumenJuegoService resumenJuegoService;
    private final UsuarioContexto usuarioContexto;

    public CasoController(CasoRepository casoRepository,
            InvestigacionCasoService investigacionCasoService,
            ResolucionCasoService resolucionCasoService,
            ResumenJuegoService resumenJuegoService,
            UsuarioContexto usuarioContexto) {
        this.casoRepository = casoRepository;
        this.investigacionCasoService = investigacionCasoService;
        this.resolucionCasoService = resolucionCasoService;
        this.resumenJuegoService = resumenJuegoService;
        this.usuarioContexto = usuarioContexto;
    }

    public record CombateVista(String nombreSospechoso, List<String> ataques) {
    }

    @GetMapping("/casos/{id}")
    public String detalle(@PathVariable Long id, Authentication authentication,
                           RedirectAttributes redirectAttributes, Model model) {
        Usuario usuario = usuarioContexto.actual(authentication);
        Caso caso = casoRepository.findById(id).orElseThrow();

        if (sinAcceso(caso, usuario)) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, MENSAJE_ACCESO_DENEGADO);
            return RUTA_INICIO;
        }

        var investigacion = investigacionCasoService.preparar(id, usuario);

        Veredicto veredicto = resolucionCasoService.veredicto(usuario, id).orElse(null);
        CombateEnCurso combate = veredicto == null
                ? resolucionCasoService.combate(usuario, id).orElse(null)
                : null;

        model.addAttribute("caso", caso);
        model.addAttribute("registros", investigacion.registros());
        model.addAttribute("conclusiones", investigacion.conclusiones());
        model.addAttribute("totalConclusiones", investigacion.totalConclusiones());
        model.addAttribute("conclusionesEncontradas", investigacion.conclusionesEncontradas());
        model.addAttribute("totalPistas", investigacion.totalPistas());
        model.addAttribute("pistasEncontradas", investigacion.pistasEncontradas());
        model.addAttribute("sospechosos", resolucionCasoService.sospechosos(id));
        model.addAttribute("veredicto", veredicto);
        model.addAttribute("combate", combate == null ? null : construirCombateVista(combate));
        model.addAttribute("rutaActual", "/casos/" + id);
        model.addAttribute("ultimoGuardado", usuario.getUltimoGuardado());
        model.addAttribute("estadoJuego", resumenJuegoService.calcular(usuario));
        return "caso";
    }

    private CombateVista construirCombateVista(CombateEnCurso combate) {
        return new CombateVista(combate.getSospechoso().getNombre(), combate.getSospechoso().getAtaques());
    }

    @PostMapping("/casos/{casoId}/pistas/{pistaId}/descubrir")
    public String descubrirPista(@PathVariable Long casoId, @PathVariable Long pistaId,
                                  Authentication authentication, RedirectAttributes redirectAttributes) {
        Usuario usuario = usuarioContexto.actual(authentication);
        Pista pista = investigacionCasoService.buscarPista(pistaId);

        if (!pista.getCaso().getId().equals(casoId) || sinAcceso(pista.getCaso(), usuario)) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, MENSAJE_ACCESO_DENEGADO);
            return RUTA_INICIO;
        }

        investigacionCasoService.descubrir(usuario, pista);

        redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, "Pista añadida a tu carpeta.");
        redirectAttributes.addFlashAttribute("pistaDescubiertaId", pistaId);
        return RUTA_CASOS + casoId;
    }

    @PostMapping("/casos/{casoId}/combinar")
    public String combinar(@PathVariable Long casoId,
                            @RequestParam(required = false) List<Long> registroIds,
                            Authentication authentication, RedirectAttributes redirectAttributes) {
        Usuario usuario = usuarioContexto.actual(authentication);
        Caso caso = casoRepository.findById(casoId).orElseThrow();

        if (sinAcceso(caso, usuario)) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, MENSAJE_ACCESO_DENEGADO);
            return RUTA_INICIO;
        }

        if (registroIds == null || registroIds.size() != 2) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, "Selecciona exactamente dos documentos para combinarlos.");
            return RUTA_CASOS + casoId;
        }

        Pista pista = investigacionCasoService.buscarCombinacion(casoId, registroIds);
        if (pista == null) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, "No encuentra ninguna relación entre esos documentos.");
            return RUTA_CASOS + casoId;
        }

        if (investigacionCasoService.descubrir(usuario, pista)) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, "Nueva conclusión anotada al expediente.");
            redirectAttributes.addFlashAttribute("pistaDescubiertaId", pista.getId());
        } else {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, "Esa conclusión ya estaba anotada.");
        }
        return RUTA_CASOS + casoId;
    }

    @PostMapping("/casos/{casoId}/acusar")
    public String acusar(@PathVariable Long casoId, @RequestParam Long sospechosoId, Authentication authentication,
                          RedirectAttributes redirectAttributes) {
        Usuario usuario = usuarioContexto.actual(authentication);
        Caso caso = casoRepository.findById(casoId).orElseThrow();

        if (sinAcceso(caso, usuario)) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, MENSAJE_ACCESO_DENEGADO);
            return RUTA_INICIO;
        }

        Sospechoso sospechoso = resolucionCasoService.buscarSospechoso(sospechosoId);
        // El control de acceso se hizo sobre el caso de la ruta; hay que exigir
        // que el sospechoso pertenezca a ese mismo caso. Si no, un auditor
        // podría acusar (y abrir combate/veredicto contra) un sospechoso de un
        // caso confidencial pasando el casoId de un caso público en la ruta.
        if (!sospechoso.getCaso().getId().equals(casoId)) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, MENSAJE_ACCESO_DENEGADO);
            return RUTA_INICIO;
        }

        if (resolucionCasoService.acusar(usuario, sospechoso)) {
            redirectAttributes.addFlashAttribute("accionReciente", "acusacion");
        }

        return RUTA_CASOS + casoId;
    }

    /**
     * El combate de cartas en sí (issue #21) lo resuelve el cliente de
     * principio a fin con los ataques del sospechoso como cartas del
     * rival; este endpoint solo cierra el expediente cuando termina, gane
     * o pierda el jugador — no hay "sospechoso correcto" (ver
     * CLAUDE.md), así que la acusación se resuelve igual en ambos casos.
     */
    @PostMapping("/casos/{casoId}/combate/finalizar")
    public String finalizarCombate(@PathVariable Long casoId, Authentication authentication,
                                    RedirectAttributes redirectAttributes) {
        Usuario usuario = usuarioContexto.actual(authentication);
        // Un segundo POST (doble clic tras una respuesta lenta) llega cuando
        // el combate ya no existe: no-op, como guarda /acusar con
        // yaHayVeredicto/yaHayCombate — el veredicto ya quedó registrado.
        Optional<CombateEnCurso> pendiente =
                resolucionCasoService.combate(usuario, casoId);
        if (pendiente.isEmpty()) {
            return RUTA_CASOS + casoId;
        }
        CombateEnCurso combate = pendiente.get();

        if (sinAcceso(combate.getCaso(), usuario)) {
            redirectAttributes.addFlashAttribute(ATRIBUTO_MENSAJE, MENSAJE_ACCESO_DENEGADO);
            return RUTA_INICIO;
        }

        resolucionCasoService.finalizar(usuario, combate);
        // Misma marca que /acusar: la acusación se cierra aquí cuando el
        // sospechoso tenía cartas, así que la penalización por acusación
        // precipitada debe evaluarse igual que en el caso sin combate.
        redirectAttributes.addFlashAttribute("accionReciente", "acusacion");
        return RUTA_CASOS + casoId;
    }

    private boolean sinAcceso(Caso caso, Usuario usuario) {
        return caso.isConfidencial() && usuario.getRol() != Rol.ADMIN;
    }

}
