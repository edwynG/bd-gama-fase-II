-- Implementacion de procedimientos
-- Parte I
-- Procedimiento A
	/* Es necesario que se indique que tipo de envio se usara, asi como el metodo de pago */
CREATE PROCEDURE SimularCompraOnline (@ClienteId INT, @MetodoPagoId INT, @TipoEnvioId INT)
AS
BEGIN
	DECLARE @OrdenOnlineId INT;
	DECLARE @NroOrden INT;
	DECLARE @FacturaId INT;
	DECLARE @SubTotal DECIMAL(10,2);
	DECLARE @MontoDescuentoTotal DECIMAL(10,2);
	DECLARE @PorcentajeIVA DECIMAL(5,2);
	DECLARE @MontoIVA DECIMAL(10,2);
	DECLARE @MontoTotal DECIMAL(10,2);
	DECLARE @NroTransaccion INT;
	
	-- Datos Factura
	SELECT @FacturaId = ISNULL(MAX(id),0) + 1
	FROM Factura
	
	SET @SubTotal = dbo.subTotal(@FacturaId)
	SET @MontoDescuentoTotal = dbo.montoDescuentoTotal(@FacturaId)
	SET @PorcentajeIVA = 16
	SET @MontoIVA = dbo.montoIVA(@FacturaId)
	SET @MontoTotal = dbo.montoTotal(@FacturaId)
	
	-- Datos OrdenOnline
	SELECT @OrdenOnlineId = ISNULL(MAX(id),0) + 1,
		   @NroOrden = ISNULL(MAX(nroOrden),0) + 1  
	FROM ordenOnline
	
	-- Datos Pago
	
	SELECT @NroTransaccion = ISNULL(MAX(nroTransaccion),0) + 1
	FROM Pago
	
-- INSERTS
	
	INSERT INTO OrdenOnline (id,clienteId, nroOrden, fechaCreacion, tipoEnvioId, facturaId)
	VALUES (@OrdenOnlineId, @ClienteId, @NroOrden, GETDATE(), @TipoEnvioId, @FacturaId)
	
	INSERT INTO OrdenDetalle (ordenId, productoId, cantidad, precioPor)
	SELECT @OrdenOnlineId, productoId, cantidad, precioPor 
	FROM Carrito
	WHERE clienteId = @ClienteId
	
	INSERT INTO FacturaDetalle (facturaId, productoId, cantidad, precioPor)
	SELECT @FacturaId, productoId, cantidad, precioPor
	FROM Carrito
	WHERE clienteId = @ClienteId
	
	INSERT INTO Factura (id, fechaEmision, clienteId, subTotal, montoDescuentoTotal, porcentajeIVA, montoIVA, montoTotal )
	VALUES (@FacturaId, GETDATE(), @ClienteId, @SubTotal, @MontoDescuentoTotal, @PorcentajeIVA, @MontoIVA, @MontoTotal)
	
	INSERT INTO Pago (facturaId, nroTransaccion, metodoPagoId)
	VALUES (@FacturaId, @NroTransaccion, @MetodoPagoId)

	-- ACTUALIZAR EL INVENTARIO
	
	UPDATE Inventario
	SET Inventario.cantidad = Inventario.cantidad - c.cantidad
	FROM Inventario 
	JOIN Carrito AS c ON Inventario.productoId = c.productoId
	WHERE c.clienteId = @ClienteId 
	
END
GO

-- Procedimiento B
CREATE PROCEDURE CompraProveedor (@ProveedorId INT, @ProductoId INT, @PrecioProducto DECIMAL(10,2), @Cantidad INT)
AS
BEGIN

	DECLARE @IdProveedorProducto INT;
	DECLARE @ComprobarCantidad INT;
	DECLARE @IdInventario INT;
	
	SELECT @IdProveedorProducto = COALESCE(MAX(id),0) + 1
	FROM ProveedorProducto
	
INSERT INTO ProveedorProducto (id, proveedorId, productoId, fechaCompra, precioPor, cantidad)
VALUES (@IdProveedorProducto, @ProveedorId, @ProductoId, GETDATE(), @PrecioProducto, @Cantidad)
	
END
GO

-- Parte II
-- Procedimiento C Crear factura física dado un cliente y un empleado (esto creará también la relación VentaFisica).
CREATE PROCEDURE CrearFacturaFisica
    @clienteId INT,
    @empleadoId INT
AS
BEGIN

    IF NOT EXISTS (SELECT 1 FROM Empleado WHERE id = @empleadoId)
    BEGIN
        RAISERROR('Empleado no encontrado', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Cliente WHERE id = @clienteId)
    BEGIN
        RAISERROR('Cliente no encontrado', 16, 1);
        RETURN;
    END
    -- Variables para almacenar los totales
    DECLARE @subTotal DECIMAL (10,2) = 0,
            @montoIVA DECIMAL (10,2) = 0,
            @montoTotal DECIMAL (10,2) = 0,
            @fechaEmision DATETIME = GETDATE(),
            @sucursalId INT,
            @facturaId INT;

    -- Obtener la sucursal del empleado
    SELECT @sucursalId = sucursalId
    FROM Empleado
    WHERE id = @empleadoId;

    -- Calcular el subtotal y el IVA a partir del carrito del cliente
    SELECT @subTotal = SUM(c.cantidad * c.precioPor),
           @montoIVA = SUM(CASE WHEN p.esExentoIVA = 0 THEN (c.cantidad * c.precioPor) * 0.16 ELSE 0 END)
    FROM Carrito c
    JOIN Producto p ON c.productoId = p.id
    WHERE c.clienteId = @clienteId;

    -- Calcular el monto total
    SET @montoTotal = @subTotal + @montoIVA;

    -- Obtener el siguiente ID
    SELECT @facturaId = ISNULL(MAX(id), 0) + 1 FROM Factura;

    -- Insertar la nueva factura
    INSERT INTO Factura (id, fechaEmision, clienteId, subTotal, montoDescuentoTotal, porcentajeIVA, montoIVA, montoTotal)
    VALUES (@facturaId, @fechaEmision, @clienteId, @subTotal, 0, 18, @montoIVA, @montoTotal);

    -- Crear la relación en VentaFisica
    INSERT INTO VentaFisica (facturaId, sucursalId, empleadoId)
    VALUES (@facturaId, @sucursalId, @empleadoId);

    PRINT 'Factura y VentaFisica Creados correctamente.';

END
GO

-- PROCEDIMIENTO D Agregar producto a factura física dada una factura, producto, cantidad y precio.

CREATE PROCEDURE AgregarProductoAFacturaFisica
    @facturaId INT,      -- ID de la factura a la que se agregará el producto
    @productoId INT,     -- ID del producto a agregar
    @cantidad INT,       -- Cantidad del producto
    @precioPor DECIMAL (10,2)     -- Precio por unidad del producto
AS
BEGIN
    DECLARE @nuevoId INT;

    -- Verificar si la factura pertenece a una venta física
    IF EXISTS (SELECT 1 FROM VentaFisica WHERE facturaId = @facturaId)
    BEGIN
        -- Insertar el producto en FacturaDetalle
        INSERT INTO FacturaDetalle (facturaId, productoId, cantidad, precioPor)
        VALUES (@facturaId, @productoId, @cantidad, @precioPor);

        PRINT 'Producto agregado correctamente a la factura fisica.';
    END
    ELSE
    BEGIN
        -- Si la factura no pertenece a una venta física, generar un error
        RAISERROR('La factura no corresponde a una venta física.', 16, 1);
    END
END;
GO

-- Parte III 
--- Procedure E
CREATE PROCEDURE PromoEffectivenessReport
    @id INT
AS
BEGIN
    DECLARE @fechaInicio DATETIME;
    DECLARE @fechaFin DATETIME;
    DECLARE @mediaAntes DECIMAL(10, 2);
    DECLARE @mediaDurante DECIMAL(10, 2);
    DECLARE @porcentaje DECIMAL(10, 2);
	DECLARE @ingresoTotalAntes DECIMAL(10, 2);
	DECLARE @ingresoTotalDurante DECIMAL(10, 2);
    -- Fechas de la promoción
    SELECT @fechaInicio = p.fechaInicio, @fechaFin = p.fechaFin 
    FROM Promo p 
    WHERE p.id = @id;

    -- Calcular la media de la cantidad de ventas y monto total desde 3 meses antes de la promoción
    SELECT 
        @mediaAntes = 
        (  SELECT SUM(Temp.cantidad)
            FROM (
                SELECT SUM(fd.cantidad) AS cantidad
                FROM Factura f2
                JOIN FacturaDetalle fd ON fd.facturaId = f2.id
                WHERE f2.fechaEmision BETWEEN DATEADD(MONTH, -3, @fechaInicio) AND DATEADD(DAY, -1, @fechaInicio)
                GROUP BY f2.id
            ) AS Temp
        ) / COUNT(*), 
        @ingresoTotalAntes = SUM(f.montoTotal) 
    FROM Factura f 
    WHERE f.fechaEmision BETWEEN DATEADD(MONTH, -3, @fechaInicio) AND DATEADD(DAY, -1, @fechaInicio);

    -- Calcular la media de cantidad de ventas y monto total durante la promoción
    SELECT 
        @mediaDurante = 
        (  SELECT SUM(Temp.cantidad)
            FROM (
                    SELECT SUM(fd.cantidad) AS cantidad
                    FROM Factura f3
                    JOIN FacturaDetalle fd ON fd.facturaId = f3.id
                    WHERE (f3.fechaEmision BETWEEN @fechaInicio AND @fechaFin) AND 
                                f3.id IN
                                ( 
                                    SELECT fp2.facturaId 
                                    FROM Promo p2
                                    JOIN FacturaPromo fp2 ON fp2.promoId = p2.id
                                    JOIN Factura f4 ON f4.id = fp2.facturaId
                                    WHERE p2.id = @id
                                    GROUP BY fp2.facturaId
                                ) 
                    GROUP BY f3.id
            ) AS Temp
        ) / COUNT(*), 
        @ingresoTotalDurante = SUM(f.montoTotal) 
    FROM Factura f 
    WHERE (f.fechaEmision BETWEEN @fechaInicio AND @fechaFin) AND 
            f.id IN
            ( 
                SELECT fp.facturaId 
                FROM Promo p
                JOIN FacturaPromo fp ON fp.promoId = p.id
                JOIN Factura f2 ON f2.id = fp.facturaId
                WHERE p.id = @id
                GROUP BY fp.facturaId
            ) ;

    -- Calcular el porcentaje de cambio
    IF @mediaAntes IS NULL AND @mediaDurante IS NULL
    BEGIN
        SELECT 'No hay datos suficientes para calcular la efectividad de la promoción.' AS Mensaje;
        RETURN;
    END

    IF @ingresoTotalDurante < @ingresoTotalAntes
    BEGIN
        SET @porcentaje = ((@ingresoTotalAntes - @ingresoTotalDurante) / @ingresoTotalAntes) * 100;
        SELECT 
            COALESCE(@mediaAntes, 0) AS MediaAntes, 
            COALESCE(@ingresoTotalAntes, 0) AS IngresoTotalAntes, 
            COALESCE(@mediaDurante, 0) AS MediaDurante, 
            COALESCE(@ingresoTotalDurante, 0) AS IngresoTotalDurante, 
            COALESCE(@porcentaje, 0) AS "Porcentaje de decremento";
    END
    ELSE
    BEGIN
        SET @porcentaje = ((@ingresoTotalDurante - @ingresoTotalAntes) / @ingresoTotalAntes) * 100;
        SELECT 
            COALESCE(@mediaAntes, 0) AS MediaAntes, 
            COALESCE(@ingresoTotalAntes, 0) AS IngresoTotalAntes, 
            COALESCE(@mediaDurante, 0) AS MediaDurante, 
            COALESCE(@ingresoTotalDurante, 0) AS IngresoTotalDurante, 
            COALESCE(@porcentaje, 0) AS "Porcentaje de incremento";
    END
END;
GO