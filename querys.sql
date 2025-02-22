-- Consultas
--- Consulta I
SELECT
	p2.*,
	ContribucionProcentaje
FROM
	( -- Los 10 productos mas vendidos
		SELECT
			TOP 10 ProductoPorPrecio.productoId as productoId,
			( -- Ingreso total por porducto
				SUM(ingresoPor) / (
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
					-- total de ingresos de ese producto por el precio
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