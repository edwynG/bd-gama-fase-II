-- Implementación de triggers
--- Parte I
-- Trigger A
-- A.1
CREATE TRIGGER InventoryFill
ON ProveedorProducto
AFTER INSERT 
AS
BEGIN
    -- Declarar una tabla temporal para almacenar los registros de inserted
    DECLARE @TempInserted TABLE (
        productoId INT,
        totalCantidad INT
    );

    -- Insertar los registros de inserted en la tabla temporal
    INSERT INTO @TempInserted (productoId, totalCantidad)
    SELECT productoId, SUM(cantidad) AS totalCantidad
    FROM inserted
    GROUP BY productoId;

    -- Procesar cada registro individualmente
    DECLARE @productoId INT;
    DECLARE @totalCantidad INT;

    DECLARE cur CURSOR FOR
    SELECT productoId, totalCantidad
    FROM @TempInserted;

    OPEN cur;
    FETCH NEXT FROM cur INTO @productoId, @totalCantidad;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calcula el posible nuevo id para el inventario
        DECLARE @nuevoId INT;
        SELECT @nuevoId = ISNULL(MAX(id), 0) + 1 FROM Inventario;

        -- Actualizar o insertar en la tabla Inventario
        MERGE INTO Inventario AS target
        USING (SELECT @productoId AS productoId, @totalCantidad AS totalCantidad) AS source
        ON target.productoId = source.productoId
        WHEN MATCHED THEN
            UPDATE SET cantidad = target.cantidad + source.totalCantidad
        WHEN NOT MATCHED THEN
            INSERT (id, productoId, cantidad)
            VALUES (@nuevoId, source.productoId, source.totalCantidad);

        FETCH NEXT FROM cur INTO @productoId, @totalCantidad;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO
-- A.2
-- Orden Online
CREATE TRIGGER CreateInvoiceOnlineOrder
ON OrdenOnline
INSTEAD OF INSERT
AS
BEGIN
    -- Declarar una tabla temporal para almacenar los registros de inserted
    DECLARE @TempInserted TABLE (
        id INT,
        clienteId INT,
        nroOrden INT,
        fechaCreacion DATETIME,
        tipoEnvioId INT,
        facturaId INT
    );

    -- Insertar los registros de inserted en la tabla temporal
    INSERT INTO @TempInserted (id, clienteId, nroOrden, fechaCreacion, tipoEnvioId, facturaId)
    SELECT id, clienteId, nroOrden, fechaCreacion, tipoEnvioId, facturaId
    FROM inserted;

    -- Procesar cada registro individualmente
    DECLARE @id INT;
    DECLARE @clienteId INT;
    DECLARE @nroOrden INT;
    DECLARE @fechaCreacion DATETIME;
    DECLARE @tipoEnvioId INT;
    DECLARE @facturaId INT;

    DECLARE cur CURSOR FOR
    SELECT id, clienteId, nroOrden, fechaCreacion, tipoEnvioId, facturaId
    FROM @TempInserted;

    OPEN cur;
    FETCH NEXT FROM cur INTO @id, @clienteId, @nroOrden, @fechaCreacion, @tipoEnvioId, @facturaId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Verificar si la factura no existe para crearla
        IF NOT EXISTS (SELECT 1 FROM Factura f WHERE f.id = @facturaId)
        BEGIN
            -- Crear la factura
            INSERT INTO Factura (id, fechaEmision, clienteId, subTotal, montoDescuentoTotal, porcentajeIVA, montoIVA, montoTotal)
            VALUES (@facturaId, GETDATE(), @clienteId, 0, 0, 16, 0, 0);

            -- Insertar la orden online
            INSERT INTO OrdenOnline (id, clienteId, nroOrden, fechaCreacion, tipoEnvioId, facturaId)
            VALUES (@id, @clienteId, @nroOrden, @fechaCreacion, @tipoEnvioId, @facturaId);

            -- Verificar si existen detalles de la orden
            IF NOT EXISTS (SELECT 1 FROM OrdenDetalle WHERE ordenId = @id)
            BEGIN
                -- Insertar al menos 3 productos aleatorios en OrdenDetalle
                INSERT INTO OrdenDetalle (ordenId, productoId, cantidad, precioPor)
                SELECT TOP 4
                    @id,
                    id,
                    CAST((RAND(CHECKSUM(NEWID())) * 10 + 1) AS INT), -- Genera una cantidad aleatoria entre 1 y 10
                    ISNULL(precioPor, 0)
                FROM Producto
                ORDER BY NEWID();
            END

            -- Insertar los detalles de la orden en FacturaDetalle
            INSERT INTO FacturaDetalle (facturaId, productoId, cantidad, precioPor)
            SELECT 
                @facturaId,
                productoId,
                cantidad,
                precioPor
            FROM OrdenDetalle
            WHERE ordenId = @id;

            UPDATE Factura 
			SET subTotal = dbo.subTotal(@facturaId), 
				montoDescuentoTotal = dbo.montoDescuentoTotal(@facturaId),
				montoIVA = dbo.montoIVA(@facturaId),
				montoTotal = dbo.montoTotal(@facturaId)
			WHERE id = @facturaId;
             -- Validar y agregar forma de pago si no existe
            IF NOT EXISTS (SELECT 1 FROM Pago WHERE facturaId = @facturaId)
            BEGIN
                DECLARE @nroTransaccion INT;

                -- Calcular el siguiente número de transacción
                SELECT @nroTransaccion = ISNULL(MAX(nroTransaccion), 0) + 1 FROM Pago;

                DECLARE @metodoPagoId INT;
                SET @metodoPagoId = CAST((RAND(CHECKSUM(NEWID())) * 10 + 1) AS INT); -- Genera un ID de método de pago aleatorio entre 1 y 10

                INSERT INTO Pago (facturaId, nroTransaccion, metodoPagoId)
                VALUES (@facturaId, @nroTransaccion, @metodoPagoId);
            END
        END
        ELSE
        BEGIN
            -- Insertar la orden online
            INSERT INTO OrdenOnline (id, clienteId, nroOrden, fechaCreacion, tipoEnvioId, facturaId)
            VALUES (@id, @clienteId, @nroOrden, @fechaCreacion, @tipoEnvioId, @facturaId);
        END

        FETCH NEXT FROM cur INTO @id, @clienteId, @nroOrden, @fechaCreacion, @tipoEnvioId, @facturaId;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO

-- Compra Fisica
CREATE TRIGGER CreateInvoicePhysicalSale
ON VentaFisica
INSTEAD OF INSERT
AS
BEGIN
    -- Declarar una tabla temporal para almacenar los registros de inserted
    DECLARE @TempInserted TABLE (
        facturaId INT,
        sucursalId INT,
        empleadoId INT
    );

    -- Insertar los registros de inserted en la tabla temporal
    INSERT INTO @TempInserted (facturaId, sucursalId, empleadoId)
    SELECT facturaId, sucursalId, empleadoId
    FROM inserted;

    -- Procesar cada registro individualmente
    DECLARE @facturaId INT;
    DECLARE @sucursalId INT;
    DECLARE @empleadoId INT;

    DECLARE cur CURSOR FOR
    SELECT facturaId, sucursalId, empleadoId
    FROM @TempInserted;

    OPEN cur;
    FETCH NEXT FROM cur INTO @facturaId, @sucursalId, @empleadoId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Verificar si la factura no existe para crearla
        IF NOT EXISTS (SELECT 1 FROM Factura f WHERE f.id = @facturaId)
        BEGIN
            -- Crear la factura con un cliente aleatorio
            DECLARE @randomClienteId INT;
            SELECT TOP 1 @randomClienteId = id FROM Cliente ORDER BY NEWID();

            INSERT INTO Factura (id, fechaEmision, clienteId, subTotal, montoDescuentoTotal, porcentajeIVA, montoIVA, montoTotal)
            VALUES (@facturaId, GETDATE(), @randomClienteId, 0, 0, 16, 0, 0);

            -- Insertar al menos 3 productos aleatorios en FacturaDetalle
            INSERT INTO FacturaDetalle (facturaId, productoId, cantidad, precioPor)
            SELECT TOP 4
                @facturaId,
                id,
                CAST((RAND(CHECKSUM(NEWID())) * 10 + 1) AS INT), -- Genera una cantidad aleatoria entre 1 y 10
                ISNULL(precioPor, 0)
            FROM Producto
            ORDER BY NEWID();

            UPDATE Factura 
			SET subTotal = dbo.subTotal(@facturaId), 
				montoDescuentoTotal = dbo.montoDescuentoTotal(@facturaId),
				montoIVA = dbo.montoIVA(@facturaId),
				montoTotal = dbo.montoTotal(@facturaId)
			WHERE id = @facturaId;
             -- Validar y agregar forma de pago si no existe
            IF NOT EXISTS (SELECT 1 FROM Pago WHERE facturaId = @facturaId)
            BEGIN
                DECLARE @nroTransaccion INT;

                -- Calcular el siguiente número de transacción
                SELECT @nroTransaccion = ISNULL(MAX(nroTransaccion), 0) + 1 FROM Pago;

                DECLARE @metodoPagoId INT;
                SET @metodoPagoId = CAST((RAND(CHECKSUM(NEWID())) * 10 + 1) AS INT); -- Genera un ID de método de pago aleatorio entre 1 y 10

                INSERT INTO Pago (facturaId, nroTransaccion, metodoPagoId)
                VALUES (@facturaId, @nroTransaccion, @metodoPagoId);
            END
        END

        -- Insertar la venta física
        INSERT INTO VentaFisica (facturaId, sucursalId, empleadoId)
        VALUES (@facturaId, @sucursalId, @empleadoId);

        FETCH NEXT FROM cur INTO @facturaId, @sucursalId, @empleadoId;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO
-- A.3
-- Agregan al carrito
CREATE TRIGGER addCartToHistory
ON Carrito
AFTER INSERT
AS
BEGIN
	DECLARE @tipo VARCHAR(10) = 'Carrito';
    INSERT INTO HistorialClienteProducto(clienteId, productoId, fecha, tipoAccion)
    SELECT clienteId, productoId, fechaAgregado, @tipo FROM inserted 
END;
GO
-- Compran un producto
CREATE TRIGGER addInvoiceToHistory
ON FacturaDetalle
AFTER INSERT
AS
BEGIN
	DECLARE @tipo VARCHAR(10) = 'Compra';
    INSERT INTO HistorialClienteProducto(clienteId, productoId, fecha, tipoAccion)
    SELECT clienteId, productoId, fechaEmision, @tipo  
    FROM (
    	SELECT f.clienteId, temp.productoId, f.fechaEmision
    	FROM inserted temp
    	JOIN Factura f ON f.id = temp.facturaId
    	GROUP BY f.clienteId, temp.productoId, f.fechaEmision
    ) AS Compra 

END;
GO

-- A.4
CREATE TRIGGER recommendProductsToClient
ON HistorialClienteProducto
AFTER INSERT
AS
BEGIN
    DECLARE @message VARCHAR(50) = 'Producto recomendado por compra o busqueda frecuente';
    INSERT INTO ProductoRecomendadoParaCliente(clienteId, productoRecomendadoId, fechaRecomendacion, mensaje)
    SELECT Recomendados.clienteId, Recomendados.productoRecomendadoId, GETDATE(), @message
    FROM (
        -- Obtener productos recomendados para cliente dado los productos que compro o busco mas de tres veces
        SELECT frecuentes.clienteId, pr.productoRecomendadoId 
        FROM (
            -- Obtener los productos que el cliente ha buscado o compro más de 3 veces
            SELECT temp.clienteId, temp.productoId
            FROM inserted temp
            JOIN HistorialClienteProducto temp2 ON temp.clienteId = temp2.clienteId AND temp.productoId = temp2.productoId
            WHERE temp.tipoAccion IN ('Busqueda', 'Compra')
            GROUP BY temp.clienteId, temp.productoId
            HAVING COUNT(*) > 3
        ) AS frecuentes
        JOIN ProductoRecomendadoParaProducto pr ON pr.productoId = frecuentes.productoId
        GROUP BY frecuentes.clienteId, pr.productoRecomendadoId
    ) as Recomendados
END;
GO

-- Trigger B
CREATE TRIGGER updatePriceProduct
ON ProveedorProducto
AFTER INSERT
AS
BEGIN
    -- Actualizar el precio del producto en la tabla Producto
    UPDATE p
    SET p.precioPor =  i.precioPor + (i.precioPor * 0.30)  -- Aumentar el precio de compra en un 30%
    FROM Producto p
    JOIN inserted i ON p.id = i.productoId;  -- Solo actualizar los productos que fueron comprados
END;
GO

-- Parte II
--- Trigger C
-- Al insertar datos en FacturaPromo: llama al verificador de promo válida y acepta el registro o no.
-- Trigger para verificar la promoción al insertar en FacturaPromo
CREATE TRIGGER TR_FacturaPromo_VerificarPromocion
ON FacturaPromo
INSTEAD OF INSERT
AS
BEGIN
	
    -- Validar promociones no válidas para las filas en bloque
    IF EXISTS(SELECT 1
		FROM Inserted i 
		WHERE NOT dbo.isValidPromo(i.facturaId,i.promoId)=1)
	BEGIN
        RAISERROR('La promoción no es válida para el tipo de compra.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Insertar todas las filas válidas desde inserted
    INSERT INTO FacturaPromo (facturaId, promoId)
    SELECT facturaId, promoId
    FROM inserted;
END;

GO


-- TRIGGER D
-- Verificar cantidad de Stock para OrdenOnline y para VentaFisica

-- Trigger encargado de verificar Stock para OrdenDetalle(OrdenOnline).
-- Trigger para validar el stock al insertar en OrdenDetalle
CREATE TRIGGER TR_OrdenDetalle_ValidarStock
ON OrdenDetalle
INSTEAD OF INSERT
AS
BEGIN
    -- Tabla de errores de stock
    CREATE TABLE #ErroresStock (
        ordenId INT,
        productoId INT,
        cantidad INT,
        mensaje VARCHAR(255)
    );

    -- Validar stock e insertar filas válidas
    INSERT INTO OrdenDetalle (ordenId, productoId, cantidad, precioPor)
    SELECT i.ordenId, i.productoId, i.cantidad, i.precioPor
    FROM inserted i
    LEFT JOIN Inventario inv ON i.productoId = inv.productoId
    WHERE inv.cantidad IS NOT NULL AND inv.cantidad >= i.cantidad;

    -- Registrar errores en la tabla temporal
    INSERT INTO #ErroresStock (ordenId, productoId, cantidad, mensaje)
    SELECT i.ordenId, i.productoId, i.cantidad, 
           CASE 
               WHEN inv.cantidad IS NULL THEN 'Producto no disponible en inventario'
               WHEN inv.cantidad < i.cantidad THEN 'Stock insuficiente'
           END AS mensaje
    FROM inserted i
    LEFT JOIN Inventario inv ON i.productoId = inv.productoId
    WHERE inv.cantidad IS NULL OR inv.cantidad < i.cantidad;

    -- Mostrar mensajes de error si los hay
    IF EXISTS (SELECT 1 FROM #ErroresStock)
    BEGIN
        SELECT * FROM #ErroresStock;
        RAISERROR('Existen problemas de stock en algunos productos. Verifique los registros.', 10, 1);
    END
END;
GO



-- Trigger encargado de verificar Stock para FacturaDetalle(VentaFisica)
CREATE TRIGGER TR_FacturaDetalle_ValidarStock
ON FacturaDetalle
INSTEAD OF INSERT
AS
BEGIN
    CREATE TABLE #ErroresStock (
        facturaId INT,
        productoId INT,
        cantidad INT,
        mensaje VARCHAR(255)
    );

    -- Validar stock e insertar filas válidas
    INSERT INTO FacturaDetalle (facturaId, productoId, cantidad, precioPor)
    SELECT i.facturaId, i.productoId, i.cantidad, i.precioPor
    FROM inserted i
    LEFT JOIN Inventario inv ON i.productoId = inv.productoId
    WHERE inv.cantidad IS NOT NULL AND inv.cantidad >= i.cantidad;

    -- Registrar errores en la tabla temporal
    INSERT INTO #ErroresStock (facturaId, productoId, cantidad, mensaje)
    SELECT i.facturaId, i.productoId, i.cantidad, 
           CASE 
               WHEN inv.cantidad IS NULL THEN 'Producto no disponible en inventario'
               WHEN inv.cantidad < i.cantidad THEN 'Stock insuficiente'
           END AS mensaje
    FROM inserted i
    LEFT JOIN Inventario inv ON i.productoId = inv.productoId
    WHERE inv.cantidad IS NULL OR inv.cantidad < i.cantidad;

    -- Mostrar mensajes de error si los hay
    IF EXISTS (SELECT 1 FROM #ErroresStock)
    BEGIN
        SELECT * FROM #ErroresStock;
        RAISERROR('Existen problemas de stock en algunos productos. Verifique los registros.', 10, 1);
    END
END;
GO



-- Parte III 
-- Trigger E
   CREATE TRIGGER RestoreStock
  ON FacturaDetalle
  AFTER DELETE 
  AS 
  BEGIN

    UPDATE i
    SET i.cantidad = i.cantidad + d.cantidad
    FROM Inventario i, deleted d
    WHERE i.productoId = d.productoId;

END;
GO