package com.legado.expediente.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "puntuaciones_golf")
@Getter
@NoArgsConstructor
public class PuntuacionGolf {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 24)
    private String alias;

    @Column(nullable = false)
    private int golpes;

    @Column(nullable = false)
    private int hoyos;

    @Column(nullable = false)
    private LocalDateTime creadoEn;

    public PuntuacionGolf(String alias, int golpes, int hoyos) {
        this.alias = alias;
        this.golpes = golpes;
        this.hoyos = hoyos;
        this.creadoEn = LocalDateTime.now();
    }
}
