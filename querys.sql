-- Parte II
--- Consulta D
SELECT DISTINCT
    e.CI,
    e.nombre + ' ' + e.apellido AS nombreCompleto,
    e.sexo,
    c.nombre AS nombreCargo,
    c.salarioBasePorHora AS salarioBasePorHora,
    COALESCE(e.bonoFijoMensual, 0) AS bonoFijoMensual,
    (
        -- Asumimos que un mes tiene 4 semanas
        c.salarioBasePorHora * e.cantidadDiasTrabajoPorSemana * 4 * (e.horaFin - e.horaInicio)
    ) + COALESCE(e.bonoFijoMensual, 0) AS totalMensual,
    (
        c.salarioBasePorHora * (e.horaFin - e.horaInicio) * e.cantidadDiasTrabajoPorSemana * (
            ROUND(
                DATEDIFF (
                    DAY,
                    CONVERT(DATE, e.fechaContrato),
                    CONVERT(DATE, GETDATE ())
                ) / 7,
                0,
                1
            )
        )
    ) + (
        COALESCE(e.bonoFijoMensual, 0) * DATEDIFF (MONTH, e.fechaContrato, GETDATE ())
    ) AS montoTotalRecibido --Se suma el SalarioHora * Dias trabajados * 4 para tener el mes * cantidad de Horas todo eso + el bono fijo mensual nos daria el monto total ganado durante el mes
    /*(DATEDIFF(day, CONVERT(DATE, e.fechaContrato), CONVERT(DATE, GETDATE())) / 7): Esto es la cantidad de semanas que llevo trabajando desde que se inicio el contrato. se multiplica por la cantidad de dias trabajados por semana y este resultado por la cantidad de horas trabajadas por dia, asi obtenemos el total de su sueldo base ganado por horas trabajadas desde que empezo el contrato.*/
    /*(COALESCE(e.bonoFijoMensual, 0) * (DATEDIFF(year, e.fechaContrato, GETDATE()) * 12 + (DATEDIFF(month, e.fechaContrato, GETDATE()) % 12))): Con esto obtenemos la cantidad total de bonos mensuales obtenidos desde que empezo el contrato.
     */
FROM
    Empleado e
    JOIN Cargo c ON e.cargoId = c.id -- Obtenemos la lista de empleados y una columna con un count del total de sucursales en las que han tenido ventas
    JOIN (
        SELECT
            empleadoId,
            COUNT(DISTINCT sucursalId) AS sucursalesDistintas
        FROM
            VentaFisica
        GROUP BY
            empleadoId
    ) sv ON e.id = sv.empleadoId
WHERE
    -- Verificamos si el total de sucursales donde haya vendido sea mayor que 1, con el COALESCE verificamos que los valores no sean nulos, osea empleados que no hayan tenido ventas todavia.
    sv.sucursalesDistintas > 1 -- Verificamos si el empleado esta en una lista de empleados cuyos supervisores trabajan en la misma sucursal que el.
    OR e.id IN (
        SELECT
            e1.id
        FROM
            Empleado e1
            JOIN (
                -- Se extrae el Id y la sucursal de los supervisores
                SELECT
                    e2.id,
                    e2.sucursalId
                FROM
                    (
                        -- Obtiene una tabla temporal que contienen el id de los supervisores
                        SELECT
                            e3.empleadoSupervisorId as id
                        FROM
                            Empleado e3
                        GROUP BY
                            e3.empleadoSupervisorId
                    ) as temp
                    JOIN Empleado e2 ON e2.id = temp.id
            ) supervisor ON supervisor.id = e1.empleadoSupervisorId
        WHERE
            -- Se filtran los empleados que tienen a su supervisor en su misma sucursal
            e1.sucursalId = supervisor.sucursalId
    ) -- Obtenemos una lista de los 5 mejores salarios por cargo y verificamos que el Id Cargo de nuestro empleado este dentro de dicha lista.
    OR e.cargoId IN (
        SELECT
            TOP 5 id
        FROM
            Cargo
        ORDER BY
            salarioBasePorHora DESC
    );

--- Consulta F
SELECT
    p2.*,
    pr2.*,
    pe2.*
FROM
    (
        -- Tabla donde se obtinen los productos vendidos en los meses de rebaja(junio y agosto), seguido de su promo 'verano en gamma' si es que la tiene
        SELECT
            p.id as productoId,
            pe.promoId as PromoId
        FROM
            Producto p
            JOIN Marca m ON m.id = p.marcaId
            JOIN HistorialClienteProducto hcp ON hcp.productoId = p.id
            LEFT JOIN PromoEspecializada pe ON pe.productoId = p.id
            LEFT JOIN Promo pr ON pr.id = pe.promoId
        WHERE
            hcp.tipoAccion = 'Compra'
            AND DATEPART (MONTH, hcp.fecha) IN (6, 8)
            AND m.nombre = 'Gama'
            AND (
                pr.id IS NULL
                OR LOWER(pr.nombre) = LOWER('Verano EN GaMa')
            )
        GROUP BY
            p.id,
            pe.promoId
    ) as Temp
    JOIN Producto p2 ON p2.id = Temp.productoId
    LEFT JOIN Promo pr2 ON pr2.id = Temp.promoId
    -- Consideramos que no tiene sentido que hayan varias PromoEspecializada con la misma tupla (PromoId, ProductoId). Ya que esto indica que la promo se aplica aun producto en especifico, si se repite consideramos que habria un problema de redundancia
    LEFT JOIN PromoEspecializada pe2 ON pe2.promoId = Temp.promoId
    AND pe2.productoId = Temp.productoId