-- Implementacion de procedimientos
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

-- Implementacion de funciones