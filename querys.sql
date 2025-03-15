-- Parte I
--Consulta A
SELECT
    te.*,
    Temp.CantidadUsos,
    Temp.IngresosPorTipoEnvio,
    Temp.ProporcionCantidadEnvios,
    Temp.ProporcionIngresosTotal
FROM
    TipoEnvio te
    JOIN (
        SELECT
            te.id,
            COUNT(oo.tipoEnvioId) AS CantidadUsos,
            SUM(f.montoTotal) AS IngresosPorTipoEnvio,
            (
                COUNT(oo.tipoEnvioId) * 1.0 / (
                    SELECT
                        COUNT(oo.id)
                    FROM
                        OrdenOnline oo
                )
            ) * 100 AS ProporcionCantidadEnvios,
            (
                SUM(f.montoTotal) * 1.0 / (
                    SELECT
                        SUM(f.montoTotal)
                    FROM
                        OrdenOnline oo
                        JOIN Factura AS f ON oo.facturaId = f.id
                )
            ) * 100 AS ProporcionIngresosTotal
        FROM
            TipoEnvio te
            JOIN OrdenOnline AS oo ON te.id = oo.tipoEnvioId
            JOIN Factura AS f ON oo.facturaId = f.id
        GROUP BY
            te.id
    ) AS Temp ON te.id = Temp.id;

-- 	Consulta B
SELECT
    c.nombre AS NombreCliente,
    ClienteTotalFisico.MontoTotalFisico AS TotalGastadoComprasFisicas,
    ClienteTotalOnline.MontoTotalOnline AS TotalGastadoComprasOnline,
    MetodoPagoPredilecto.nombre AS MetodoPagoPredilecto
FROM
    Cliente c
    JOIN (
        -- Obtengo el monto gastado en compras fisicas del cliente en la fecha actual
        SELECT
            c1.id,
            SUM(f.montoTotal) AS MontoTotalFisico
        FROM
            VentaFisica vf
            JOIN Factura AS f ON vf.facturaId = f.id
            JOIN Cliente AS c1 ON f.clienteId = c1.id
        WHERE
            YEAR (f.fechaEmision) = YEAR (GETDATE ())
        GROUP BY
            c1.id
    ) AS ClienteTotalFisico ON c.id = ClienteTotalFisico.id
    JOIN (
        -- Obtengo el monto gastado en compras online del cliente en la fecha actual
        SELECT
            c1.id,
            SUM(f.montoTotal) AS MontoTotalOnline
        FROM
            OrdenOnline oo
            JOIN Factura AS f ON oo.facturaId = f.id
            JOIN Cliente AS c1 ON f.clienteId = c1.id
        WHERE
            YEAR (f.fechaEmision) = YEAR (GETDATE ())
        GROUP BY
            c1.id
    ) AS ClienteTotalOnline ON c.id = ClienteTotalOnline.id
    JOIN (
        SELECT
            fp.nombre,
            NombreFP.id
        FROM
            FormaPago AS fp
            -- Join para obtener el nombre del metodo de pago
            JOIN (
                SELECT
                    -- Id del cliente, Id del metodo de pago mas usado
                    CantUsosMetodoPago.id,
                    CantUsosMetodoPago.metodoPagoId AS IdMetodoMasUsado,
                    MAX(CantUsosMetodoPago.UsosMetodoPago) AS maximo
                FROM
                    (
                        SELECT
                            -- Id del cliente, junto a cuantas veces ha usado sus metodos de pago
                            c1.id,
                            p.metodoPagoId,
                            COUNT(p.metodoPagoId) AS UsosMetodoPago
                        FROM
                            Cliente c1
                            JOIN Factura AS f ON c1.id = f.clienteId
                            JOIN Pago AS p ON f.id = p.facturaId
                            JOIN FormaPago AS fp ON p.metodoPagoId = fp.id
                        GROUP BY
                            c1.id,
                            p.metodoPagoId
                    ) AS CantUsosMetodoPago
                GROUP BY
                    CantUsosMetodoPago.id,
                    CantUsosMetodoPago.metodoPagoId
            ) AS NombreFP ON fp.id = NombreFP.IdMetodoMasUsado
    ) AS MetodoPagoPredilecto ON c.id = MetodoPagoPredilecto.id
    -- Consulta C
SELECT
    p.nombre AS NombreProducto,
    c2.nombre AS Categoria,
    m.nombre AS Marca
FROM
    Producto p
    JOIN ProductoRecomendadoParaCliente AS prpc ON p.id = prpc.productoRecomendadoId
    JOIN Cliente AS c ON prpc.clienteId = c.id
    JOIN Categoria AS c2 ON p.categoriaId = c2.id
    JOIN Marca AS m ON p.marcaId = m.id
WHERE
    c.id IN (
        SELECT
            --Clientes que han comprado los productos en la fecha solicitada
            c.id
        FROM
            Cliente AS c
            JOIN Factura AS f ON c.id = f.clienteId
        WHERE
            YEAR (f.fechaEmision) = YEAR (GETDATE ())
            AND MONTH (f.fechaEmision) = MONTH (GETDATE ())
    )
    AND p.id IN (
        SELECT
            -- Se verifica que el producto este en el carrito de algun cliente
            p.id
        FROM
            Producto AS p
            JOIN Carrito AS c ON p.id = c.productoId
    )
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
            AND LOWER(m.nombre) = LOWER('Gama')
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
    -- Parte III
    --- Consulta G
SELECT
    c.*,
    Temp.totalOrdenes,
    Temp.totalDineroGastado
FROM
    ( -- Tabla temporal donde se calculan los datos indicados por cliente
        SELECT
            oo.clienteId,
            COUNT(oo.id) as totalOrdenes,
            SUM(f.montoTotal) as totalDineroGastado
        FROM
            ( -- Clientes que satisfacen las 3 restricciones
                -- Condición 1
                -- Consulta clientes que realizado compras en al menos 3 órdenes distintas en los últimos 6 meses.
                SELECT
                    c1.id as clienteId
                FROM
                    Cliente c1
                    JOIN OrdenOnline oo1 ON oo1.clienteId = c1.id
                WHERE -- Filtra ordenes hechas en los ultimos 6 meses
                    oo1.fechaCreacion >= CONVERT(DATE, DATEADD (MONTH, -6, GETDATE ()))
                GROUP BY
                    c1.id
                HAVING -- Filtra los clientess que han realizado al menos 3 compras distintas
                    COUNT(DISTINCT (oo1.id)) >= 3
                INTERSECT
                --- Condicion 2
                -- Consulta clientes que han comprado al menos un producto de la categoría "Electrónica" y otro de "Hogar".
                SELECT
                    c2.id as clienteId
                FROM
                    Cliente c2
                    JOIN OrdenOnline oo2 ON oo2.clienteId = c2.id
                WHERE -- Filtro clientes que han comprado al menos un producto de categoria 'Electrónica' y "Hogar" en una misma orden
                    oo2.id in (
                        --- Consulto ordenes donde se hayan comprado al menos un producto de categoria 'Electrónica'
                        SELECT
                            oo3.id
                        FROM
                            OrdenOnline oo3
                            JOIN OrdenDetalle od ON od.ordenId = oo3.id
                            JOIN Producto p ON p.id = od.productoId
                            JOIN Categoria m ON m.id = p.categoriaId
                        WHERE
                            LOWER(m.nombre) = LOWER('Electronica')
                        GROUP BY
                            oo3.id
                        INTERSECT -- Solo se quedaran las ordenes donde se hayan comparado al menos un producto de categoria 'Electrónica' y "Hogar"
                        --- Consulto ordenes donde se hayan comprado al menos un producto de categoria 'Hogar'
                        SELECT
                            oo4.id
                        FROM
                            OrdenOnline oo4
                            JOIN OrdenDetalle od1 ON od1.ordenId = oo4.id
                            JOIN Producto p1 ON p1.id = od1.productoId
                            JOIN Categoria m1 ON m1.id = p1.categoriaId
                        WHERE
                            LOWER(m1.nombre) = LOWER('Hogar')
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
                WHERE -- Filtra las ordenes que se han pagado con el metodo de pago 'Tarjeta de Crédito'
                    LOWER(fp.nombre) = LOWER('Tarjeta de credito')
                GROUP BY
                    c3.id
                INTERSECT
                -- Condicion 4
                -- El monto total gastado en esas órdenes es superior al promedio de gasto de todos los clientes en el mismo período (6 meses)
                SELECT
                    f3.clienteId as clienteId
                FROM
                    OrdenOnline oo6
                    JOIN Factura f3 ON f3.id = oo6.facturaId
                WHERE -- Filtra las ordenes que se han pagado con el metodo de pago 'Tarjeta de Crédito'
                    f3.montoTotal > (
                        SELECT
                            AVG(t.montoTotal)
                        FROM
                            ( --- Promedio gastado de todos los clientes(cliente que compran online) en el mismo periodo
                                SELECT
                                    f4.clienteId,
                                    SUM(f4.montoTotal) as montoTotal
                                FROM
                                    Factura f4
                                    JOIN OrdenOnline oo7 ON oo7.facturaId = f4.id
                                WHERE
                                    oo7.fechaCreacion >= CONVERT(DATE, DATEADD (MONTH, -6, GETDATE ()))
                                GROUP BY
                                    f4.clienteId
                            ) t
                    )
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
        CAST(
            CAST(COUNT(clientesCondition.clienteId) AS FLOAT) / (
                SELECT
                    COUNT(*)
                FROM
                    ( --- Cantidad de clientes que han realizado compras
                        SELECT
                            c2.id
                        FROM
                            Cliente c2
                            JOIN Factura f3 ON f3.clienteId = c2.id
                        GROUP BY
                            c2.id
                    ) as temp
            ) AS FLOAT
        ) * 100
    ) as porcentajeClientes
FROM
    (
        SELECT
            f2.clienteId
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
            JOIN Factura f2 ON f2.clienteId = PrimeraCompara.clienteId
            -- Filtra los registros donde la fecha de la 2da compra esta entre 1 y 30 dias despues de la 1er compra
        WHERE
            f2.fechaEmision > PrimeraCompara.fecha
            AND f2.fechaEmision <= DATEADD (DAY, 30, PrimeraCompara.fecha)
        GROUP BY
            f2.clienteId
    ) clientesCondition
    --- Consulta I
SELECT
    p2.*,
    ContribucionProcentaje
FROM
    ( -- Los 10 productos mas vendidos
        SELECT
            TOP 10 ProductoPorPrecio.productoId as productoId,
            ( -- Ingreso total por porducto
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
    Producto p
    -- El productoId en Inventario es una FK, pero no se repetira porque la relación se maneja de forma global para saber el stock de cada producto
    JOIN Inventario i ON i.productoId = p.id
    JOIN Categoria c ON c.id = i.productoId
WHERE
    LOWER(c.nombre) = LOWER('Chucherias');

-- CONSULTA E LISTA DE PRODUCTOS RECOMENDADOS Y NO RECOMENDADOS ANTES Y DESPUES DE SU COMPRA
SELECT
    c.CI,
    c.nombre,
    c.sexo,
    COALESCE(recomendados.productos_recomendados, 0) AS productos_recomendados,
    COALESCE(no_recomendados.productos_no_recomendados, 0) AS productos_no_recomendados,
    COALESCE(recomendados.porcentaje_recomendados, 0) AS ComprasDespuesDeRecomendacion,
    COALESCE(no_recomendados.porcentaje_no_recomendados, 0) AS ComprasAntesDeRecomendacion
    -- Se utiliza COALESCE porque puede que no haya referencia en historial cliente o en alguna de las tablas y asi se evitan errores
FROM
    Cliente c
    -- LISTA DE CLIENTES Y TOTAL DE PRODUCTOS QUE COMPRARON LUEGO DE UNA RECOMENDACION
    LEFT JOIN (
        SELECT
            h.clienteId,
            COUNT(DISTINCT h.productoId) AS productos_recomendados,
            CAST(COUNT(DISTINCT h.productoId) AS FLOAT) / NULLIF(COUNT(DISTINCT h.productoId), 0) * 100 AS porcentaje_recomendados
            /* NULLIF es una función que devuelve NULL si el primer argumento es igual al segundo. En este caso, si el conteo de productos únicos es 0, NULLIF devolverá NULL.
            esto es importante para evitar la división por cero. Si no hay productos, en lugar de intentar dividir por 0 (lo que causaría un error), se devolverá NULL.
            La función CAST convierte el resultado de COUNT(DISTINCT h.productoId) a un tipo de dato FLOAT.
             */
        FROM
            HistorialClienteProducto h
            JOIN ProductoRecomendadoParaCliente pr ON h.productoId = pr.productoRecomendadoId
        WHERE
            h.fecha > pr.fechaRecomendacion
            AND h.tipoAccion = 'Compra'
        GROUP BY
            h.clienteId
    ) AS recomendados ON c.id = recomendados.clienteId
    -- LISTA DE CLIENTES Y TOTAL DE PRODUCTOS QUE COMPRARON ANTES DE UNA RECOMENDACION
    LEFT JOIN (
        SELECT
            h.clienteId,
            COUNT(DISTINCT h.productoId) AS productos_no_recomendados,
            CAST(COUNT(DISTINCT h.productoId) AS FLOAT) / NULLIF(COUNT(DISTINCT h.productoId), 0) * 100 AS porcentaje_no_recomendados
            -- SE UTILIZA LA MISMA LOGICA QUE EN EL SELECT DEL LEFT JOIN ANTERIOR PERO ESTA VEZ ES PARA OBTENER LOS QUE FUERON COMPRADOS SIN RECOMENDACION.
        FROM
            HistorialClienteProducto h
            LEFT JOIN ProductoRecomendadoParaCliente pr ON h.productoId = pr.productoRecomendadoId
        WHERE
            h.fecha <= pr.fechaRecomendacion
            OR pr.fechaRecomendacion IS NULL
            AND h.tipoAccion = 'Compra'
        GROUP BY
            h.clienteId
    ) AS no_recomendados ON c.id = no_recomendados.clienteId
ORDER BY
    c.CI;