--Pisos e incidencias en abierto
SELECT
    i.id AS incidencia_id,
        i.piso_id AS piso_id,
            s.servicio AS nombre_servicio,
                i.gravedad AS gravedad,
                    i.creado_en AS creado

                    FROM incidencias i
                    JOIN servicios s ON i.servicio_id = s.id
                    WHERE i.estado = 'abierta'
                    ORDER BY creado DESC;



                    --Coste total por incidencia
                    SELECT
                        i.id AS id,
                            s.servicio AS nombre,
                                SUM (CASE
                                            WHEN t.importe IS NOT NULL THEN importe
                                                        ELSE 0
                                                                    END) AS total

                                                                    FROM incidencias i
                                                                    JOIN servicios s ON i.servicio_id = s.id
                                                                    LEFT JOIN transacciones t ON t.incidencia_id = i.id
                                                                    GROUP BY i.id;


                                                                    --Rating profesionales
                                                                    SELECT
                                                                        p.nombre AS Nombre,
                                                                            p.empresa AS Empresa,
                                                                                s.servicio AS Servicio,
                                                                                    AVG(ps.rating) AS Rating,
                                                                                        AVG(coste_hora) AS coste_hora

                                                                                        FROM profesionales p
                                                                                        JOIN profesionales_servicios ps ON ps.profesional_id=p.id
                                                                                        JOIN servicios s ON s.id=ps.servicio_id

                                                                                        GROUP BY p.id
                                                                                        ORDER BY Rating DESC;


                                                                                        --Total pagado por inquilino
                                                                                        SELECT
                                                                                            inq.nombre AS nombre,
                                                                                                inq.apellidos AS apellidos,
                                                                                                    SUM (CASE
                                                                                                                WHEN t.contrato_id IS NOT NULL THEN t.importe ELSE 0 END)
                                                                                                                FROM inquilinos inq
                                                                                                                JOIN contratos_inquilinos ci ON inq.id =ci.inquilino_id
                                                                                                                JOIN transacciones t ON t.contrato_id= ci.contrato_id
                                                                                                                WHERE t.concepto = 'alquiler'

                                                                                                                GROUP BY inq.id;



                                                                                                                --Pisos sin incidencias abiertas
                                                                                                                SELECT
                                                                                                                    p.piso_id AS 'Piso ID',
                                                                                                                        p.direccion AS 'Dirección',
                                                                                                                            p.ciudad AS Ciudad,
                                                                                                                                p.zona
                                                                                                                                FROM pisos p
                                                                                                                                JOIN incidencias i ON p.id=piso_id
                                                                                                                                WHERE i.id NOT EXIST;





-- Insert a new tenant
INSERT INTO inquilinos (nombre, apellidos, identificacion, telefono, email, fecha_alta, estado)
VALUES ('David', 'Pruebainsert', '25548755H', '666111999', 'david@prueba1.com', '2025-11-25', 'ACTIVO');


-- Insert a new incident
INSERT INTO  incidencias (piso_id, contrato_id, servicio_id, estado, gravedad, origen, descripcion, creado_en)
VALUES ('2','3','1', 'abierta', 'ALTA', 'tormenta','debido al aire de la tormenta', '2025-11-10' );


-- Mark an incident as resolved
UPDATE incidencias
SET estado='resuelta',
    cerrado_en = date ('now')
    WHERE id = 1;



-- Logically deactivate a tenant
    UPDATE inquilinos
    SET estado = 'INACTIVO'
    WHERE id = '1';



-- Delete an attachment record
    DELETE FROM adjuntos
    WHERE id = '4';
