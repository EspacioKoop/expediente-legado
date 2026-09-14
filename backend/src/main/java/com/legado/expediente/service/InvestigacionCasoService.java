package com.legado.expediente.service;

import com.legado.expediente.model.Descubrimiento;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.RegistroLegado;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.DescubrimientoRepository;
import com.legado.expediente.repository.PistaRepository;
import com.legado.expediente.repository.RegistroLegadoRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/** Prepara la investigación del expediente y registra sus descubrimientos. */
@Service
public class InvestigacionCasoService {
    private final RegistroLegadoRepository registroLegadoRepository;
    private final PistaRepository pistaRepository;
    private final DescubrimientoRepository descubrimientoRepository;
    private final ProgresoService progresoService;
    private final HotspotService hotspotService;
    private final CartaOcultaService cartaOcultaService;

    public InvestigacionCasoService(RegistroLegadoRepository registroLegadoRepository,
            PistaRepository pistaRepository,
            DescubrimientoRepository descubrimientoRepository,
            ProgresoService progresoService,
            HotspotService hotspotService,
            CartaOcultaService cartaOcultaService) {
        this.registroLegadoRepository = registroLegadoRepository;
        this.pistaRepository = pistaRepository;
        this.descubrimientoRepository = descubrimientoRepository;
        this.progresoService = progresoService;
        this.hotspotService = hotspotService;
        this.cartaOcultaService = cartaOcultaService;
    }

    public record PistaVista(Long id, String descripcion, boolean descubierta) {
    }

    public record RegistroVista(RegistroLegado registro, PistaVista pista, String contenidoHtml) {
    }

    public record InvestigacionVista(List<RegistroVista> registros, List<PistaVista> conclusiones,
                                     int totalConclusiones, int conclusionesEncontradas,
                                     int totalPistas, int pistasEncontradas) {
    }

    public InvestigacionVista preparar(Long id, Usuario usuario) {
        Set<Long> descubiertas = progresoService.pistasDescubiertas(usuario);
        List<Pista> pistas = pistaRepository.findByCasoId(id);
        Map<Long, Pista> pistaPorRegistro = pistas.stream()
                .filter(p -> p.getRegistroOrigen() != null && p.getRegistroOrigen2() == null)
                .collect(Collectors.toMap(p -> p.getRegistroOrigen().getId(), p -> p, (a, b) -> a));

        List<RegistroVista> registrosVista = registroLegadoRepository.findByCasoId(id).stream()
                .map(r -> {
                    Pista p = pistaPorRegistro.get(r.getId());
                    boolean descubierta = p != null && descubiertas.contains(p.getId());
                    PistaVista pv = p == null ? null : new PistaVista(p.getId(), p.getDescripcion(), descubierta);
                    String fraseGatillo = p == null ? null : p.getFraseGatillo();
                    Long pistaId = p == null ? null : p.getId();
                    String html = hotspotService.render(r.getContenido(), fraseGatillo, pistaId, descubierta);
                    html = cartaOcultaService.aplicar(html, r.getFolio());
                    return new RegistroVista(r, pv, html);
                })
                .toList();

        List<Pista> conclusionesPistas = pistas.stream()
                .filter(p -> p.getRegistroOrigen2() != null)
                .toList();
        List<PistaVista> conclusiones = conclusionesPistas.stream()
                .map(p -> new PistaVista(p.getId(), p.getDescripcion(), descubiertas.contains(p.getId())))
                .toList();
        long conclusionesEncontradas = conclusionesPistas.stream().filter(p -> descubiertas.contains(p.getId())).count();

        long encontradas = pistas.stream().filter(p -> descubiertas.contains(p.getId())).count();

        return new InvestigacionVista(registrosVista, conclusiones, conclusionesPistas.size(),
                (int) conclusionesEncontradas, pistas.size(), (int) encontradas);
    }

    public Pista buscarPista(Long pistaId) {
        return pistaRepository.findById(pistaId).orElseThrow();
    }

    public Pista buscarCombinacion(Long casoId, List<Long> registroIds) {
        return pistaRepository.findCombinacion(casoId, registroIds.get(0), registroIds.get(1)).orElse(null);
    }

    public boolean descubrir(Usuario usuario, Pista pista) {
        if (descubrimientoRepository.existsByUsuarioIdAndPistaId(usuario.getId(), pista.getId())) {
            return false;
        }
        Descubrimiento descubrimiento = new Descubrimiento();
        descubrimiento.setUsuario(usuario);
        descubrimiento.setPista(pista);
        descubrimientoRepository.save(descubrimiento);
        return true;
    }
}
