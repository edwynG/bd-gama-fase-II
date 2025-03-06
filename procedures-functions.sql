-- Implementacion de procedimientos

-- Procedimiento C Crear factura física dado un cliente y un empleado (esto creará también la relación VentaFisica).

CREATE PROCEDURE CrearFacturaFisica
    @clienteId INT,
    @empleadoId INT
AS
BEGIN
    -- Variables para almacenar los totales
    DECLARE @subTotal MONEY = 0,
            @montoIVA MONEY = 0,
            @montoTotal MONEY = 0,
            @fechaEmision DATETIME = GETDATE(),
            @facturaId INT,
            @sucursalId INT;

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

    -- Insertar la nueva factura
    INSERT INTO Factura (fechaEmisión, clienteId, subTotal, montoDescuentoTotal, porcentajeIVA, montoIVA, montoTotal)
    VALUES (@fechaEmision, @clienteId, @subTotal, 0, 18, @montoIVA, @montoTotal);

    -- Obtener el ID de la factura generada
    SET @facturaId = SCOPE_IDENTITY();

    -- Crear la relación en VentaFisica
    INSERT INTO VentaFisica (facturaId, sucursalId, empleadoId)
    VALUES (@facturaId, @sucursalId, @empleadoId);

END

-- Implementacion de funciones