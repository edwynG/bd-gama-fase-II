-- Consultas
-- Parte III
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
    JOIN Factura f2 ON f2.clienteId = PrimeraCompara.clienteId
    -- Filtra los registros donde la fecha de la 2da compra esta entre 1 y 30 dias despues de la 1er compra
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