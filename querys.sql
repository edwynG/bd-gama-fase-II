-- Consultas
-- CONSULTA D
SELECT
    DISTINCT e.CI,
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

--CONSULTA F

SELECT
    p.nombre AS Producto,
    COALESCE(pr.nombre, 'Sin Promo') AS Promocion,
    COALESCE(pe.id, 'Sin Promo Especializada') AS PromocionEspecializada
FROM
    Producto p
    JOIN Marca m ON m.id = p.marcaId 
    JOIN HistorialClienteProducto hcp ON hcp.productoId = p.id
    JOIN FacturaDetalle fd ON fd.productoId = p.id
    JOIN Factura f ON f.id = fd.facturaId
    JOIN FacturaPromo fp ON fp.facturaId = f.id
    LEFT JOIN Promo pr ON pr.id = fp.promoId
    LEFT JOIN PromoEspecializada pe ON pe.productoId = p.id
    AND pe.promoId = pr.id
    --Hacemos left Join porque nos piden los productos que tengan o no promo, y que tengan o no promo especializada.
WHERE
    m.nombre = 'Gama'
    AND hcp.tipoAccion = 'Compra'
    AND DATEPART(MONTH, hcp.fecha) IN (6, 8)
	AND (pr.nombre IS NULL OR LOWER(pr.nombre) = 'verano en gama');
	-- Esta parte me filtra los productos que no tengan promo y en caso de tenerla tiene que ser igual a "verano en gama"