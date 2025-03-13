-- Implementacion de funciones
-- Parte I
--- Funcion A
-- A.1
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

--- A.2
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
