-- Enable foreign key enforcement for this database

PRAGMA foreign_keys = ON;


-- Catalog of maintenance services that can be requested
DROP TABLE IF EXISTS servicios;
CREATE TABLE servicios (
    id              INTEGER PRIMARY KEY,
    servicio        TEXT NOT NULL UNIQUE,
    descripcion     TEXT
);


-- Professionals (companies or individuals) that provide maintenance services
DROP TABLE IF EXISTS profesionales;
CREATE TABLE profesionales(
    id              INTEGER PRIMARY KEY,
    nombre          TEXT NOT NULL,
    apellidos       TEXT NOT NULL,
    empresa         TEXT NOT NULL,
    telefono        TEXT NOT NULL,
    email           TEXT NOT NULL
                        CHECK(email LIKE '%@%'),
    zona            TEXT NOT NULL,
    activo          TEXT NOT NULL
                    CHECK (activo IN ('ACTIVO','INACTIVO'))
);


-- Many-to-many relationship between professionals and services, with rating and hourly cost
DROP TABLE IF EXISTS profesionales_servicios;
CREATE TABLE profesionales_servicios (
profesional_id  INTEGER NOT NULL,
servicio_id     INTEGER NOT NULL,
prioridad       TEXT NOT NULL,
rating          TEXT NOT NULL
CHECK (rating BETWEEN 1 AND 5),
  coste_hora      INTEGER
CHECK (coste_hora >=0),

PRIMARY KEY (profesional_id,servicio_id),
FOREIGN KEY (profesional_id) REFERENCES profesionales(id),
FOREIGN KEY (servicio_id) REFERENCES servicios(id)
);





-- Assignments of a professional to a specific maintenance incident

DROP TABLE IF EXISTS asignaciones;
CREATE TABLE asignaciones (
    id              INTEGER PRIMARY KEY,
    profesional_id  INTEGER,
    incidencia_id   INTEGER,
    asignado_en     TEXT NOT NULL
                        CHECK (date(asignado_en) IS NOT NULL),
    programado_para TEXT,
    estado          TEXT NOT NULL
                        CHECK (estado IN ('En proceso', 'finalizado')),
    coste_estimado  TEXT,
    coste_final     TEXT NOT NULL,

    FOREIGN KEY (profesional_id) REFERENCES profesionales(id) ON DELETE CASCADE,
    FOREIGN KEY (incidencia_id)   REFERENCES incidencias(id) ON DELETE CASCADE
);


-- Maintenance incidents linked to apartments, contracts, and services

DROP TABLE IF EXISTS incidencias;
CREATE TABLE incidencias (
    id            INTEGER PRIMARY KEY,
    piso_id       INTEGER NOT NULL,
    contrato_id   INTEGER,
    servicio_id   INTEGER NOT NULL,
    estado        TEXT NOT NULL
                     CHECK (estado IN ('abierta', 'asignada', 'en_progreso', 'resuelta', 'cancelada')),
    gravedad      TEXT,
    origen        TEXT,
    descripcion   TEXT,
    creado_en     TEXT NOT NULL,
    cerrado_en    TEXT,

    FOREIGN KEY (piso_id)     REFERENCES pisos(id),
    FOREIGN KEY (contrato_id) REFERENCES contratos(id),
    FOREIGN KEY (servicio_id) REFERENCES servicios(id)
);




-- File attachments related to incidents (paths to external documents)

DROP TABLE IF EXISTS adjuntos;
CREATE TABLE adjuntos (
    id            INTEGER PRIMARY KEY,
    incidencia_id INTEGER,
    tipo          TEXT,
    subido_en     TEXT,
    ruta          TEXT NOT NULL,

    FOREIGN KEY (incidencia_id) REFERENCES incidencias(id) ON DELETE CASCADE
);
-- Apartments (pisos) in the rental portfolio

DROP TABLE IF EXISTS pisos;
CREATE TABLE pisos (
    id             INTEGER PRIMARY KEY,
    direccion      TEXT,
    ciudad         TEXT,
    provincia      TEXT,
    cp             TEXT,
    superficie_m2  TEXT,
    zona           TEXT
);

  -- Financial transactions related to contracts, apartments, or incidents

DROP TABLE IF EXISTS transacciones;
CREATE TABLE transacciones (
    id             INTEGER PRIMARY KEY,
    contrato_id    INTEGER,
    fecha          TEXT NOT NULL
                       CHECK (date(fecha) >= '1960-01-01'),
    importe        INTEGER NOT NULL,
    explicacion    TEXT,
    concepto       TEXT NOT NULL,
    banco          TEXT NOT NULL,
    tipo           TEXT,
    piso_id        INTEGER,
    incidencia_id  INTEGER,

    CHECK (
        (contrato_id   IS NOT NULL) +
        (piso_id       IS NOT NULL) +
        (incidencia_id IS NOT NULL) = 1
    

    FOREIGN KEY (contrato_id)    REFERENCES contratos(id),
    FOREIGN KEY (piso_id)        REFERENCES pisos(id),
    FOREIGN KEY (incidencia_id)  REFERENCES incidencias(id)
);
                                                                                                                                                                                                                                                                                                                                                                            );
-- Rental contracts for a given apartment

DROP TABLE IF EXISTS contratos;
CREATE TABLE contratos (
    id             INTEGER NOT NULL PRIMARY KEY,
    piso_id        INTEGER NOT NULL,
    renta          INTEGER NOT NULL,
    fecha_inicio   TEXT
                      CHECK (date(fecha_inicio) >= '1960-01-01'),
    fecha_fin      TEXT
                      CHECK (fecha_fin IS NULL OR date(fecha_fin) > date(fecha_inicio)),
    fianza         INTEGER,
    periodicidad   TEXT NOT NULL,
    estado         TEXT NOT NULL
                      CHECK (estado IN ('ACTIVO','INACTIVO')),

    FOREIGN KEY (piso_id) REFERENCES pisos(id)
);
-- Link table between contracts and tenants (one contract can have multiple tenants)

DROP TABLE IF EXISTS contratos_inquilinos;
CREATE TABLE contratos_inquilinos (
    contrato_id   INTEGER NOT NULL,
    inquilino_id  INTEGER NOT NULL,
    rol           TEXT,

    PRIMARY KEY (contrato_id, inquilino_id),

    FOREIGN KEY (contrato_id)  REFERENCES contratos(id)   ON DELETE CASCADE,
    FOREIGN KEY (inquilino_id) REFERENCES inquilinos(id) ON DELETE CASCADE
);
-- Tenants (inquilinos) with their identification and contact information

DROP TABLE IF EXISTS inquilinos;
CREATE TABLE inquilinos (
    id             INTEGER NOT NULL PRIMARY KEY,
    nombre         TEXT NOT NULL,
    apellidos      TEXT NOT NULL,
    identificacion TEXT NOT NULL,
    telefono       TEXT NOT NULL,
    email          TEXT NOT NULL
                      CHECK (email LIKE '%@%'),
    fecha_alta     TEXT NOT NULL,
    estado         TEXT NOT NULL
                      CHECK (estado IN ('ACTIVO','INACTIVO'))
);

CREATE VIEW consulta_incidencias AS
SELECT
    i.id,
    i.estado,
    i.gravedad,
    i.origen,
    s.servicio,
    COALESCE(SUM(t.importe), 0) AS importe_total
FROM incidencias i
JOIN servicios s ON i.servicio_id = s.id
LEFT JOIN transacciones t ON i.id = t.incidencia_id
GROUP BY
    i.id,
    i.estado,
    i.gravedad,
    i.origen,
    s.servicio;

CREATE INDEX transacciones_idx ON transacciones (incidencia_id);


CREATE VIEW rentabilidad_piso AS
SELECT
    c.piso_id,
    SUM(t.importe) AS importe_total
FROM contratos c
JOIN transacciones t ON c.id = t.contrato_id
GROUP BY
    c.piso_id;


CREATE VIEW inquilinos_info AS
SELECT
    inq.id,
    inq.nombre,
    inq.apellidos,
    ci.contrato_id,
    SUM(t.importe) AS importe_total
FROM inquilinos inq
JOIN contratos_inquilinos ci ON ci.inquilino_id = inq.id
JOIN transacciones t ON ci.contrato_id = t.contrato_id
GROUP BY
    inq.id,
    inq.nombre,
    inq.apellidos,
    ci.contrato_id;

CREATE INDEX inquilinos_ci_idx ON contratos_inquilinos (inquilino_id);
CREATE INDEX inquilinos_t_idx ON transacciones (contrato_id);


CREATE VIEW balance_piso AS
SELECT
    COALESCE(c.piso_id, i.piso_id) AS piso_id,

    SUM(
        CASE
            WHEN t.contrato_id IS NOT NULL
                 AND UPPER(t.concepto) = 'ALQUILER'
            THEN t.importe
            ELSE 0
        END
    ) AS total_alquiler,

    SUM(
        CASE
            WHEN t.incidencia_id IS NOT NULL
            THEN t.importe
            ELSE 0
        END
    ) AS total_incidencias,

    SUM(
        CASE
            WHEN t.contrato_id IS NOT NULL
                 AND UPPER(t.concepto) = 'ALQUILER'
            THEN t.importe
            ELSE 0
        END
    )
    -
    SUM(
        CASE
            WHEN t.incidencia_id IS NOT NULL
            THEN t.importe
            ELSE 0
        END
    ) AS balance

FROM transacciones t
LEFT JOIN contratos c ON c.id = t.contrato_id
LEFT JOIN incidencias i ON i.id = t.incidencia_id
GROUP BY
    COALESCE(c.piso_id, i.piso_id);
