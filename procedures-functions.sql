-- Implementacion de procedimientos
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
        -- Obtener el siguiente ID para la tabla FacturaDetalle
        SELECT @nuevoId = ISNULL(MAX(id), 0) + 1 FROM FacturaDetalle;

        -- Insertar el producto en FacturaDetalle
        INSERT INTO FacturaDetalle (id, facturaId, productoId, cantidad, precioPor)
        VALUES (@nuevoId, @facturaId, @productoId, @cantidad, @precioPor);

        PRINT 'Producto agregado correctamente a la factura fisica.';
    END
    ELSE
    BEGIN
        -- Si la factura no pertenece a una venta física, generar un error
        RAISERROR('La factura no corresponde a una venta física.', 16, 1);
    END
END;

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


-- Implementacion de funciones
-- Parte I
--- Funcion A
-- costoEnvio
CREATE FUNCTION costoEnvio (@facturaId INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @costo DECIMAL(10,2)

    -- Verificar si la factura está asociada a una Orden Online
    IF EXISTS (
        SELECT 1
        FROM OrdenOnline
        WHERE facturaId = @facturaId
    )
    BEGIN
        -- Si existe, obtener el costo del envío
        SELECT @costo = te.costoEnvio
        FROM OrdenOnline oo
        JOIN TipoEnvio te ON oo.tipoEnviold = te.id
        WHERE oo.facturaId = @facturaId
    END
    ELSE
    BEGIN
        -- Si no existe, el costo de envío es 0
        SET @costo = 0.00
    END

    RETURN @costo
END

-- montoTotal
CREATE FUNCTION montoTotal (@facturaId INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @subTotal DECIMAL(10,2)
    DECLARE @montoDescuentoTotal DECIMAL(10,2)
    DECLARE @montoIVA DECIMAL(10,2)
    DECLARE @costoEnvio DECIMAL(10,2)
    DECLARE @total DECIMAL(10,2)

    -- Obtener los valores utilizando las funciones existentes
    SET @subTotal = dbo.subTotal(@facturaId)
    SET @montoDescuentoTotal = dbo.montoDescuentoTotal(@facturaId)
    SET @montoIVA = dbo.montoIVA(@facturaId)
    SET @costoEnvio = dbo.costoEnvio(@facturaId)

    -- Calcular el monto total
    SET @total = (@subTotal - @montoDescuentoTotal) + @montoIVA + @costoEnvio

    RETURN @total
END

-- subTotal

CREATE FUNCTION subTotal (@facturaId INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @subtotal DECIMAL(10,2)

    -- Obtener el subtotal directamente de la tabla Factura
    SELECT @subtotal = subTotal
    FROM Factura
    WHERE id = @facturaId

    -- Si no se encuentra la factura, el subtotal es 0
    IF @subtotal IS NULL
    BEGIN
        SET @subtotal = 0.00
    END

    RETURN @subtotal
END

-- Parte II
--- Function B
CREATE FUNCTION isValidPromo (@facturaId INT, @promoId INT)
RETURNS BIT
AS
BEGIN
    DECLARE @isValid BIT;
    SET @isValid = 0; -- Inicialmente se asume que no es válida
	 -- Obtener la promoción
    DECLARE @tipoPromocion VARCHAR(15);
    DECLARE @fechaFin DATE;
   	DECLARE @fechaInicio DATE;
    DECLARE @fechaEmision DATETIME;

   	-- Obtenemos los datos necesarios de la promo
    SELECT @tipoPromocion = p.tipoPromocion, @fechaFin = p.fechaFin, @fechaInicio = fechaInicio 
    FROM Promo p
    WHERE p.id = @promoId;
   -- Obtenemos la fecha de emisión de la factura
    SELECT @fechaEmision = f.fechaEmision
	FROM Factura f 
	WHERE f.id = @facturaId;

    -- Verificar si la factura es online
    IF EXISTS (SELECT 1 FROM OrdenOnline oo WHERE oo.facturaId = @facturaId)
    BEGIN
        -- Verificar si la fecha de fin no ha pasado y el tipo de promoción es 'Online'
        IF (CAST(@fechaEmision AS DATE) BETWEEN @fechaInicio AND @FechaFin)  AND @tipoPromocion IN ('Online', 'Ambos')
        BEGIN
            SET @isValid = 1; -- La promoción es válida
        END
    END
    ELSE
    BEGIN
        -- De lo contrario, es Fisica
        -- Verificar si la fecha de fin no ha pasado y el tipo de promoción es 'Fisica'
        IF (CAST(@fechaEmision AS DATE) BETWEEN @fechaInicio AND @FechaFin)  AND @tipoPromocion IN ('Fisica', 'Ambos')
        BEGIN
            SET @isValid = 1; -- La promoción es válida
        END
    END
   
    RETURN @isValid; -- Retorna el resultado
END;
