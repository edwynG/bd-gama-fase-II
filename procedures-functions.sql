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
	DECLARE @ingresoTotalAntes MONEY;
	DECLARE @ingresoTotalDurante MONEY;
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