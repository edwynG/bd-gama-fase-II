

-- Implementacion de funciones

-- FUNCION A

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

--montoDescuentoTotal

CREATE FUNCTION montoDescuentoTotal (@facturaId INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @montoDescuentoTotal DECIMAL(10,2) = 0;
	
	SELECT @montoDescuentoTotal = COALESCE(SUM(DescuentoEspecial.montoDescuentoEspecial) + SUM(p2.valorDescuento),SUM(DescuentoEspecial.montoDescuentoEspecial)) 
			
	FROM(
		/* Obtengo el descuento que se le hace a cada producto individualmente */
		
	    SELECT COALESCE(p1.valorDescuento*fd.cantidad,0) AS montoDescuentoEspecial,
	    		fd.facturaId
	    FROM FacturaDetalle AS fd
	    LEFT JOIN PromoEspecializada AS pe ON fd.productoId = pe.productoId   
	    LEFT JOIN Promo AS p1 ON pe.promoId = p1.id 
	    
    )AS DescuentoEspecial 
    LEFT JOIN FacturaPromo AS fp ON DescuentoEspecial.facturaId = fp.facturaId
    LEFT JOIN Promo AS p2 ON fp.promoId = p2.id

    WHERE DescuentoEspecial.facturaId = @facturaId
    
    
    GROUP BY DescuentoEspecial.facturaId
    RETURN @montoDescuentoTotal
END



-- montoIVA

CREATE FUNCTION montoIVA (@facturaId INT)
RETURNS DECIMAL(10,2)
AS 
BEGIN
    DECLARE @montoIVA DECIMAL(10,2) = 0;
	
	/* Se resta el monto total del precio de todos los productos
	   con el monto dado por todas las promos aplicadas sobre esa factura
	   Adicionalmente se calcula de una vez el IVA */
	SELECT @montoIVA = COALESCE(((SUM(Montos.montoPorGrupo) - SUM(p2.valorDescuento))*16)/100,(SUM(Montos.montoPorGrupo)*16)/100) 
	FROM(
		/*Obtenemos los precios con descuentos especializados por grupo de productos,
		 por eso se multiplica por la cantidad*/
		SELECT fd.facturaId, 
	           COALESCE((fd.precioPor-p1.valorDescuento)*fd.cantidad,fd.precioPor*fd.cantidad) AS montoPorGrupo
	                 
	    FROM Producto AS p
	    LEFT JOIN PromoEspecializada AS pe ON p.id = pe.productoId 
	    LEFT JOIN Promo AS p1 ON pe.promoId = p1.id
	    JOIN FacturaDetalle AS fd on p.id = fd.productoId
	  	WHERE p.esExentoIVA = 0
		) AS Montos
		
	LEFT JOIN FacturaPromo AS fp ON Montos.facturaId = fp.facturaId
	LEFT JOIN Promo AS p2 ON fp.promoId = p2.id
	
	WHERE Montos.facturaId = @FacturaId 
	GROUP BY Montos.facturaId

    RETURN @montoIVA
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

-- Implementacion de procedimientos

--Procedimientos PARTE I

/*  Simular toda una compra online de lo que esté en el carrito dado un cliente. */
-- Procedimiento A

	/* Es necesario que se indique que tipo de envio se usara, asi como el metodo de pago */
CREATE PROCEDURE SimularCompraOnline (@ClienteId INT, @MetodoPagoId INT, @TipoEnvioId INT, @Carrito INT)
AS
BEGIN
	DECLARE @OrdenOnlineId INT;
	DECLARE @NroOrden INT;
	DECLARE @FacturaId INT;
	DECLARE @SubTotal INT;
	DECLARE @MontoDescuentoTotal INT;
	DECLARE @PorcentajeIVA INT;
	DECLARE @MontoIVA INT;
	DECLARE @MontoTotal INT;
	DECLARE @NroTransaccion INT;
	
	-- Datos Factura
	SELECT @FacturaId = ISNULL(MAX(id),0) + 1
	FROM Factura
	
	SET @SubTotal = subTotal(@FacturaId)
	SET @MontoDescuentoTotal = montoDescuentoTotal(@FacturaId)
	SET @PorcentajeIVA = 16
	SET @MontoIVA = montoIVA(@FacturaId)
	SET @MontoTotal = montoTotal(@FacturaId)
	
	-- Datos OrdenOnline
	SELECT @OrdenOnlineId = ISNULL(MAX(id),0) + 1,
		   @NroOrden = ISNULL(MAX(nroOrden),0) + 1  
	FROM ordenOnline
	
	-- Datos Pago
	
	SELECT @NroTransaccion = ISNULL(MAX(nroTransaccion),0) + 1
	FROM Pago
	

	
-- INSERTS
	
	INSERT INTO OrdenOnline (id,clienteId, nroOrden, fechaCreacion, tipoEnvioId, facturaId)
	VALUES (@OrdenOnlineId, @ClienteId, @NroOrden, CURDATE(), @TipoEnvioId, @FacturaId)
	
	INSERT INTO OrdenDetalle (ordenId, productoId, cantidad, precioPor)
	SELECT @OrdenOnlineId, productoId, cantidad, precioPor 
	FROM Carrito
	WHERE clienteId = @ClienteId
	
	INSERT INTO FacturaDetalle (facturaId, productoId, cantidad, precioPor)
	SELECT @FacturaId, productoId, cantidad, precioPor
	FROM Carrito
	WHERE clienteId = @ClienteId
	
	INSERT INTO Factura (id, fechaEmision, clienteId, subTotal, montoDescuentoTotal, porcentajeIVA, montoIVA, montoTotal )
	VALUES (@FacturaId, CURDATE(), @ClienteId, @SubTotal, @MontoDescuentoTotal, @PorcentajeIVA, @MontoIVA, @MontoTotal)
	
	INSERT INTO Pago (facturaId, nroTransaccion, medotoPagoId)
	VALUES (@FacturaId, @NroTransaccion, @MetodoPagoId)

    
	-- ACTUALIZAR EL INVENTARIO
	
	UPDATE Inventario
	SET i.cantidad = i.cantidad - c.cantidad
	FROM Inventario AS i
	JOIN Carrito AS c ON i.productoId = c.productoId
	WHERE c.clienteId = @ClienteId 
	
	
	
END



-- PROCEDIMIENTOS PARTE II

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