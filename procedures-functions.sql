-- Implementacion de procedimientos
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

    -- Calcular la media de ingresos y monto total desde 3 meses antes de la promoción
    SELECT 
        @mediaAntes = AVG(f.montoTotal), 
        @ingresoTotalAntes = SUM(f.montoTotal) 
    FROM Factura f 
    WHERE f.fechaEmision BETWEEN DATEADD(MONTH, -3, @fechaInicio) AND @fechaInicio;

    -- Calcular la media de ingresos y monto total durante la promoción
    SELECT 
        @mediaDurante = AVG(f.montoTotal), 
        @ingresoTotalDurante = SUM(f.montoTotal) 
    FROM Factura f 
    WHERE f.fechaEmision BETWEEN @fechaInicio AND @fechaFin;

    -- Calcular el porcentaje de cambio
    IF @mediaAntes IS NULL OR @mediaDurante IS NULL
    BEGIN
        SELECT 'No hay datos suficientes para calcular la efectividad de la promoción.' AS Mensaje;
        RETURN;
    END

    IF @mediaDurante < @mediaAntes
    BEGIN
        SET @porcentaje = ((@mediaAntes - @mediaDurante) / @mediaAntes) * 100;
        SELECT 
            @mediaAntes AS MediaAntes, 
            @ingresoTotalAntes AS IngresoTotalAntes, 
            @mediaDurante AS MediaDurante, 
            @ingresoTotalDurante AS IngresoTotalDurante, 
            @porcentaje AS "Porcentaje de Decremento";
    END
    ELSE
    BEGIN
        SET @porcentaje = ((@mediaDurante - @mediaAntes) / @mediaAntes) * 100;
        SELECT 
            @mediaAntes AS MediaAntes, 
            @ingresoTotalAntes AS IngresoTotalAntes, 
            @mediaDurante AS MediaDurante, 
            @ingresoTotalDurante AS IngresoTotalDurante, 
            @porcentaje AS "Porcentaje de Incremento";
    END
END;

-- Implementacion de funciones
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