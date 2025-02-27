-- Parte II
--- Consulta D
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
    /*(DATEDIFF(day, CONVERT(DATE, e.fechaContrato), CONVERT(DATE, GETDATE())) / 7): Esto es la cantidad de semanas que llevo trabajando desde que se inicio el contrato. 
     Se multiplica por la cantidad de dias trabajados por semana y este resultado por la cantidad de horas trabajadas por dia, 
     asi obtenemos el total de su sueldo base ganado por horas trabajadas desde que empezo el contrato.*/
    /*(COALESCE(e.bonoFijoMensual, 0) * (DATEDIFF(year, e.fechaContrato, GETDATE()) * 12 + (DATEDIFF(month, e.fechaContrato, GETDATE()) % 12))): 
     Con esto obtenemos la cantidad total de bonos mensuales obtenidos desde que empezo el contrato.
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
    /*Consideramos que no tiene sentido que hayan varias PromoEspecializada con la misma tupla (PromoId, ProductoId). Ya que esto indica que la promo se aplica aun producto en especifico,
     si se repite consideramos que habria un problema de redundancia*/
    LEFT JOIN PromoEspecializada pe2 ON pe2.promoId = Temp.promoId
    AND pe2.productoId = Temp.productoId -- Parte III
    --- Consulta G
SELECT
    c.*,
    Temp.totalOrdenes,
    Temp.totalDineroGastado
FROM
    (
        -- Tabla temporal donde se calculan los datos indicados por cliente
        SELECT
            oo.clienteId,
            COUNT(oo.id) as totalOrdenes,
            SUM(f.montoTotal) as totalDineroGastado
        FROM
            (
                -- Clientes que satisfacen las 3 restricciones
                -- Condición 1
                -- Consulta clientes que realizado compras en al menos 3 órdenes distintas en los últimos 6 meses.
                SELECT
                    c1.id as clienteId
                FROM
                    Cliente c1
                    JOIN OrdenOnline oo1 ON oo1.clienteId = c1.id
                WHERE
                    -- Filtra ordenes hechas en los ultimos 6 meses
                    oo1.fechaCreacion >= CONVERT(DATE, DATEADD (MONTH, -6, GETDATE ()))
                GROUP BY
                    c1.id
                HAVING
                    -- Filtra los clientess que han realizado al menos 3 compras distintas
                    COUNT(DISTINCT (oo1.id)) >= 3
                INTERSECT
                --- Condicion 2
                -- Consulta clientes que han comprado al menos un producto de la categoría "Electrónica" y otro de "Hogar".
                SELECT
                    c2.id as clienteId
                FROM
                    Cliente c2
                    JOIN OrdenOnline oo2 ON oo2.clienteId = c2.id
                WHERE
                    -- Filtro clientes que han comprado al menos un producto de categoria 'Electrónica' y "Hogar" en una misma orden
                    oo2.id in (
                        --- Consulto ordenes donde se hayan comprado al menos un producto de categoria 'Electrónica'
                        SELECT
                            oo3.id
                        FROM
                            OrdenOnline oo3
                            JOIN OrdenDetalle od ON od.ordenId = oo3.id
                            JOIN Producto p ON p.id = od.productoId
                            JOIN Marca m ON m.id = p.categoriaId
                        WHERE
                            m.nombre = 'Electrónica'
                        GROUP BY
                            oo3.id
                        INTERSECT
                        -- Solo se quedaran las ordenes donde se hayan comparado al menos un producto de categoria 'Electrónica' y "Hogar"
                        --- Consulto ordenes donde se hayan comprado al menos un producto de categoria 'Hogar'
                        SELECT
                            oo4.id
                        FROM
                            OrdenOnline oo4
                            JOIN OrdenDetalle od1 ON od1.ordenId = oo4.id
                            JOIN Producto p1 ON p1.id = od1.productoId
                            JOIN Marca m1 ON m1.id = p1.categoriaId
                        WHERE
                            m1.nombre = 'Hogar'
                        GROUP BY
                            oo4.id
                    )
                GROUP BY
                    c2.id
                INTERSECT
                -- Condicion 3
                -- Consulta clientes que han utilizado el método de pago "Tarjeta de Crédito" en al menos una de sus órdenes.
                SELECT
                    c3.id as clienteId
                FROM
                    Cliente c3
                    JOIN OrdenOnline oo5 ON oo5.clienteId = c3.id
                    JOIN Factura f2 ON f2.id = oo5.facturaId
                    JOIN Pago pg ON pg.facturaId = f2.id
                    JOIN FormaPago fp ON fp.id = pg.metodoPagoId
                WHERE
                    -- Filtra las ordenes que se han pagado con el metodo de pago 'Tarjeta de Crédito'
                    fp.nombre = 'Tarjeta de Crédito'
                GROUP BY
                    c3.id
            ) as ClienteCondicion
            JOIN Factura f ON f.clienteId = ClienteCondicion.clienteId
            JOIN OrdenOnline oo ON oo.facturaId = f.id
        GROUP BY
            oo.clienteId
    ) as Temp
    JOIN Cliente c ON c.id = Temp.clienteId;

--- Consulta H
SELECT
    (
        -- Cantidad de clientes que han realizado una segunda comprar detro de los 30 dias posteriores a la 1er compra
        COUNT(f2.clienteId) / (
            --- Cantidad de clientes que han realizado compras
            SELECT
                COUNT(c2.id)
            FROM
                Cliente c2
                JOIN Factura f3 ON f3.clienteId = c2.id
            GROUP BY
                c2.id
        )
    ) as porcentajeClientes
FROM
    (
        -- Tabla temporal donde esta la fecha de la 1er compra de cada cliente
        SELECT
            f.clienteId as clienteId,
            MIN(f.fechaEmision) as fecha
        FROM
            Factura f
            JOIN Cliente c ON c.id = f.clienteId
        GROUP BY
            f.clienteId
    ) as PrimeraCompara
    JOIN Factura f2 ON f2.clienteId = PrimeraCompara.clienteId -- Filtra los registros donde la fecha de la 2da compra esta entre 1 y 30 dias despues de la 1er compra
WHERE
    f2.fechaEmision > PrimeraCompara.fecha
    AND f2.fechaEmision <= DATEADD (DAY, 30, PrimeraCompara.fecha)
GROUP BY
    f2.clienteId;

--- Consulta I
SELECT
    p2.*,
    ContribucionProcentaje
FROM
    (
        -- Los 10 productos mas vendidos
        SELECT
            TOP 10 ProductoPorPrecio.productoId as productoId,
            (
                -- Ingreso total por porducto
                SUM(ProductoPorPrecio.ingresoPor) / (
                    -- total de ingresos en general
                    SELECT
                        SUM(f2.montoTotal)
                    FROM
                        Factura f2
                )
            ) as ContribucionProcentaje
        FROM
            (
                SELECT
                    fd.id as productoId,
                    -- total de ingresos de ese producto agrupados por producto y el precio de ese momento
                    (SUM(fd.cantidad) * fd.precioPor) as ingresoPor,
                    SUM(fd.cantidad) as cantidad
                FROM
                    Producto p
                    JOIN FacturaDetalle fd ON fd.productoId = p.id
                GROUP BY
                    fd.id,
                    fd.precioPor
            ) as ProductoPorPrecio
        GROUP BY
            ProductoPorPrecio.productoId
        ORDER BY
            SUM(ProductoPorPrecio.cantidad) DESC
    ) as ProductosMasVendidos
    JOIN Producto p2 ON p2.id = ProductosMasVendidos.productoId;

--- Consulta J
SELECT
    p.nombre,
    p.precioPor,
    (p.precioPor - (p.precioPor * 0.1)) as precioConDescuento,
    CASE
        WHEN i.cantidad < 10 THEN 'Últimos disponibles'
        WHEN i.cantidad < 20 THEN 'Pocos disponibles'
        ELSE 'Disponible'
    END as stock
FROM
    Producto p -- El productoId en Inventario es una FK, pero no se repetira porque la relación se maneja de forma global para saber el stock de cada producto
    JOIN Inventario i ON i.productoId = p.id
    JOIN Categoria c ON c.id = i.productoId
WHERE
    c.nombre = 'Chucherias';