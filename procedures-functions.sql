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