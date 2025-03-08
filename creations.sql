-- Creacion de tablas

-- Este script de SQL Server es para eliminar todas las restricciones de clave foráneas de las tablas para poder eliminarlas si existen
-- Este algoritmo es solo para usarlo en desarrollo, por lo que no estoy seguro si podemos enviar el proyecto junto con este script, en caso de que no se pueda, simplemente se eliminara antes de enviarlo.

-- NOTA: La utilidad de este script, es para poder aplicar cambios a las tablas sin tener que eliminarlas manualmente y crearlas de nuevo.

-- Inicia script
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += 'ALTER TABLE ' + QUOTENAME(OBJECT_NAME(parent_object_id)) + 
                ' DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.foreign_keys

EXEC sp_executesql @sql;

-- En caso de que existan las tablas se eliminan
DROP TABLE IF EXISTS Marca;
DROP TABLE IF EXISTS Categoria;
DROP TABLE IF EXISTS Cliente;
DROP TABLE IF EXISTS ClienteDireccion;
DROP TABLE IF EXISTS Producto;
DROP TABLE IF EXISTS ProductoRecomendadoParaProducto;
DROP TABLE IF EXISTS ProductoRecomendadoParaCliente;
DROP TABLE IF EXISTS TipoEnvio;
DROP TABLE IF EXISTS HistorialClienteProducto;
DROP TABLE IF EXISTS Carrito;
DROP TABLE IF EXISTS FormaPago;
DROP TABLE IF EXISTS Factura;
DROP TABLE IF EXISTS FacturaDetalle;
DROP TABLE IF EXISTS Pago;
DROP TABLE IF EXISTS OrdenOnline;
DROP TABLE IF EXISTS OrdenDetalle;
DROP TABLE IF EXISTS Pais;
DROP TABLE IF EXISTS Estado;
DROP TABLE IF EXISTS Ciudad;
DROP TABLE IF EXISTS Promo;
DROP TABLE IF EXISTS PromoEspecializada;
DROP TABLE IF EXISTS FacturaPromo;
DROP TABLE IF EXISTS Sucursal;
DROP TABLE IF EXISTS Cargo;
DROP TABLE IF EXISTS Empleado;
DROP TABLE IF EXISTS Inventario;
DROP TABLE IF EXISTS Proveedor;
DROP TABLE IF EXISTS ProveedorProducto;
DROP TABLE IF EXISTS VentaFisica;
-- fin del script

-- CREAMOS LA TABLA MARCA
CREATE TABLE Marca (
    id INT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL,
    descripcion VARCHAR(256)
);

-- CREAMOS LA TABLA CATEGORIA
CREATE TABLE Categoria (
    id INT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL,
    descripcion VARCHAR(256)
);

-- CREAMOS LA TABLA CLIENTE
CREATE TABLE Cliente (
    id INT PRIMARY KEY,
    CI  INT UNIQUE,
    nombre VARCHAR(256) NOT NULL,
    apellido VARCHAR(256) NOT NULL,
    correo VARCHAR(256) UNIQUE NOT NULL,
    sexo CHAR(1) CHECK (sexo IN ('M', 'F')),
    fechaNacimiento DATE,
    fechaRegistro DATE NOT NULL
);

-- CREAMOS LA TABLA DIRECCION DEL CLIENTE, LA CUAL REFERENCIA A CLIENTE
CREATE TABLE ClienteDireccion (
    id INT PRIMARY KEY,
    clienteId INT,
    tipoDireccion VARCHAR(256) CHECK (tipoDireccion IN ('Facturacion', 'Envio')),
    dirLinea1 VARCHAR(256) NOT NULL,
    ciudadId INT,
    FOREIGN KEY (clienteId) REFERENCES Cliente(id)
);

-- CREAMOS LA TABLA PRODUCTO , LA CUAL REFERENCIA A MARCA Y CATEGORIA
CREATE TABLE Producto (
    id INT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL,
    codigoBarra VARCHAR(256) UNIQUE,
    descripcion VARCHAR(256),
    tipoPrecio VARCHAR(256) CHECK (tipoPrecio IN ('PorUnidad', 'PorPesoKg')),
    precioPor DECIMAL(10, 2) CHECK (precioPor >= 0),
    esExentoIVA BIT NOT NULL,
    categoriaId INT,
    marcaId INT,
    FOREIGN KEY (categoriaId) REFERENCES Categoria(id),
    FOREIGN KEY (marcaId) REFERENCES Marca(id)
);

-- CREAMOS LA TABLA PRODUCTORECOMENDADO, LA CUAL REFERENCIA A PRODUCTO
CREATE TABLE ProductoRecomendadoParaProducto (
    productoId INT,
    productoRecomendadoId INT,
    mensaje VARCHAR(256),
    PRIMARY KEY (productoId, productoRecomendadoId),
    FOREIGN KEY (productoId) REFERENCES Producto(id),
    FOREIGN KEY (productoRecomendadoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA PRODUCTOPARACLIENTE, LA CUAL REFERENCIA A LOS PRODUCTOS Y A CLIENTES
CREATE TABLE ProductoRecomendadoParaCliente (
    clienteId INT,
    productoRecomendadoId INT,
    fechaRecomendacion DATETIME,
    mensaje VARCHAR(256),
    PRIMARY KEY (clienteId, productoRecomendadoId, fechaRecomendacion),
    FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    FOREIGN KEY (productoRecomendadoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA TIPO DE ENVIO
CREATE TABLE TipoEnvio (
    id INT PRIMARY KEY,
    nombreEnvio VARCHAR(256) NOT NULL,
    tiempoEstimadoEntrega INT,
    costoEnvio DECIMAL(10, 2) CHECK (costoEnvio >= 0)
);

-- CREAMOS LA TABLA HISTORIA DE CLIENTE, LA CUAL REFERENCIA A CLIENTE Y PRODUCTO
CREATE TABLE HistorialClienteProducto (
    clienteId INT,
    productoId INT,
    fecha DATETIME,
    tipoAccion VARCHAR(256) CHECK (tipoAccion IN ('Busqueda', 'Carrito', 'Compra')),
    PRIMARY KEY (clienteId, productoId, fecha),
    FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA CARRITO, LA CUAL REFERENCIA A CLIENTE Y PRODUCTO
CREATE TABLE Carrito (
    clienteId INT,
    productoId INT,
    fechaAgregado DATETIME,
    cantidad INT CHECK (cantidad >= 0),
    precioPor DECIMAL(10, 2) CHECK (precioPor >= 0),
    PRIMARY KEY (clienteId, productoId),
    FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA FORMA DE PAGO
CREATE TABLE FormaPago (
    id INT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL,
    descripcion VARCHAR(256)
);

--CREAMOS LA TABLA FACTURA, LA CUAL REFERENCIA A CLIENTE
CREATE TABLE Factura (
    id INT PRIMARY KEY,
    fechaEmision DATETIME,
    clienteId INT,
    subTotal DECIMAL(10, 2) CHECK (subTotal >= 0),
    montoDescuentoTotal DECIMAL(10, 2) CHECK (montoDescuentoTotal >= 0),
    porcentajeIVA DECIMAL(5, 2) CHECK (porcentajeIVA >= 0),
    montoIVA DECIMAL(10, 2) CHECK (montoIVA >= 0),
    montoTotal DECIMAL(10, 2) CHECK (montoTotal >= 0),
    FOREIGN KEY (clienteId) REFERENCES Cliente(id)
);

-- CREAMOS LA TABLA FACTURA DETALLE, LA CUAL REFERENCIA A FACTURA Y PRODUCTO
CREATE TABLE FacturaDetalle (
    id INT PRIMARY KEY,
    facturaId INT,
    productoId INT,
    cantidad INT CHECK (cantidad >= 0),
    precioPor DECIMAL(10, 2) CHECK (precioPor >= 0),
    FOREIGN KEY (facturaId) REFERENCES Factura(id),
    FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA PAGO, LA CUAL REFERENCIA A FACTURA Y FORMA DE PAGO
CREATE TABLE Pago (
    facturaId INT,
    nroTransaccion INT NOT NULL,
    metodoPagoId INT,
    PRIMARY KEY (facturaId, nroTransaccion),
    FOREIGN KEY (facturaId) REFERENCES Factura(id),
    FOREIGN KEY (metodoPagoId) REFERENCES FormaPago(id)
);

-- CREAMOS LA TABLA ORDEN ONLINE, LA CUAL REFERENCIA A CLIENTE, TIPO DE ENVIO Y A FACTURA
CREATE TABLE OrdenOnline (
    id INT PRIMARY KEY,
    clienteId INT,
    nroOrden INT NOT NULL,
    fechaCreacion DATETIME,
    tipoEnvioId INT,
    facturaId INT UNIQUE NULL,
    FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    FOREIGN KEY (tipoEnvioId) REFERENCES TipoEnvio(id),
    FOREIGN KEY (facturaId) REFERENCES Factura(id)
);

-- CREAMOS LA TABLA ORDENDETALLE, LA CUAL REFERENCIA A ORDEN ONLINE Y A PRODUCTO
CREATE TABLE OrdenDetalle (
    id INT PRIMARY KEY,
    ordenId INT,
    productoId INT,
    cantidad INT CHECK (cantidad >= 0),
    precioPor DECIMAL(10, 2) CHECK (precioPor >= 0),
    FOREIGN KEY (ordenId) REFERENCES OrdenOnline(id),
    FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA PAIS
CREATE TABLE Pais (
    id INT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL
);

-- CREAMOS LA TABLA ESTADO, LA CUAL REFERENCIA A PAIS
CREATE TABLE Estado (
    id INT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL,
    paisId INT,
    FOREIGN KEY (paisId) REFERENCES Pais(id)
);

-- CREAMOS LA TABLA CIUDAD, LA CUAL REFERENCIA A ESTADO
CREATE TABLE Ciudad (
    id INT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL,
    estadoId INT,
    FOREIGN KEY (estadoId) REFERENCES Estado(id)
);

-- CREAMOS LA TABLA PROMO
CREATE TABLE Promo (
    id INT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL,
    slogan VARCHAR(256),
    codigo INT UNIQUE,
    tipoDescuento VARCHAR(256) CHECK (tipoDescuento IN ('Porcentaje', 'Fijo')),
    valorDescuento DECIMAL(10, 2) CHECK (valorDescuento >= 0),
    fechaInicio DATE,
    fechaFin DATE,
    tipoPromocion VARCHAR(256) CHECK (tipoPromocion IN ('Online', 'Fisica', 'Ambos'))
);

-- CREAMOS LA TABLA PROMO ESPECIALIZADA, LA CUAL REFERENCIA A PROMO, PRODUCTO, CATEGORIA Y MARCA
CREATE TABLE PromoEspecializada (
    id INT PRIMARY KEY,
    promoId INT NOT NULL,
    productoId INT,
    categoriaId INT,
    marcaId INT,
    FOREIGN KEY (promoId) REFERENCES Promo(id),
    FOREIGN KEY (productoId) REFERENCES Producto(id),
    FOREIGN KEY (categoriaId) REFERENCES Categoria(id),
    FOREIGN KEY (marcaId) REFERENCES Marca(id)
);

-- CREAMOS LA TABLA FACTURA PROMO, LA CUAL REFERENCIA A FACTURA Y PROMO
CREATE TABLE FacturaPromo (
    facturaId INT,
    promoId INT,
    PRIMARY KEY (facturaId, promoId),
    FOREIGN KEY (facturaId) REFERENCES Factura(id),
    FOREIGN KEY (promoId) REFERENCES Promo(id)
);

-- CREAMOS LA TABLA SUCURSAL, LA CUAL REFERENCIA A CIUDAD
CREATE TABLE Sucursal (
    id INT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL,
    direccion VARCHAR(256),
    telefono VARCHAR(256),
    horaAbrir INT CHECK (horaAbrir BETWEEN 0 AND 23 ),
    horaCerrar INT CHECK (horaCerrar BETWEEN 0 AND 23),
    ciudadId INT,
    FOREIGN KEY (ciudadId) REFERENCES Ciudad(id)
);

-- CREAMOS LA TABLA CARGO
CREATE TABLE Cargo (
    id INT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL,
    descripcion VARCHAR(256),
    salarioBasePorHora DECIMAL(10, 2) CHECK (salarioBasePorHora >= 0)
);

-- CREAMOS LA TABLA EMPLEADO, LA CUAL REFERENCIA A CARGO, SUCURSAL Y A EMPLEADO A TRAVEZ DE LA RECURSIVIDAD
CREATE TABLE Empleado (
    id INT PRIMARY KEY,
    CI INT UNIQUE,
    nombre VARCHAR(256) NOT NULL,
    apellido VARCHAR(256) NOT NULL,
    sexo CHAR(1) CHECK (sexo IN ('M', 'F')),
    direccionCorta VARCHAR(256),
    cargoId INT,
    empleadoSupervisorId INT,
    sucursalId INT,
    fechaContrato DATE,
    bonoFijoMensual DECIMAL(10, 2) CHECK (bonoFijoMensual >= 0),
    horaInicio INT CHECK (horaInicio BETWEEN 0 AND 23),
    horaFin INT CHECK (horaFin BETWEEN 0 AND 23),
    cantidadDiasTrabajoPorSemana INT CHECK (cantidadDiasTrabajoPorSemana BETWEEN 1 AND 7),
    FOREIGN KEY (cargoId) REFERENCES Cargo(id),
    FOREIGN KEY (empleadoSupervisorId) REFERENCES Empleado(id),
    FOREIGN KEY (sucursalId) REFERENCES Sucursal(id)
);

-- CREAMOS LA TABLA INVENTARIO, LA CUAL REFERENCIA A PRODUCTO
CREATE TABLE Inventario (
    id INT PRIMARY KEY,
    productoId INT UNIQUE,
    cantidad INT CHECK (cantidad >= 0),
    FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA PROVEEDOR LA CUAL REFERENCIA A CIUDAD
CREATE TABLE Proveedor (
    id INT PRIMARY KEY,
    RIF VARCHAR(256) UNIQUE,
    nombre VARCHAR(256) NOT NULL,
    contacto VARCHAR(256) NOT NULL,
    telefono VARCHAR(256),
    correo VARCHAR(256) UNIQUE,
    ciudadId INT,
    FOREIGN KEY (ciudadId) REFERENCES Ciudad(id)
);

--CREAMOS LA TABLA PROVEEDORPRODUCTO, LA CUAL REFERENCIA A PROVEEDOR Y A PRODUCTO
CREATE TABLE ProveedorProducto (
    id INT PRIMARY KEY,
    proveedorId INT,
    productoId INT,
    fechaCompra DATE,
    precioPor DECIMAL(10, 2) CHECK (precioPor >= 0),
    cantidad INT CHECK (cantidad >= 0),
    FOREIGN KEY (proveedorId) REFERENCES Proveedor(id),
    FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA VENTA FISICA, LA CUAL REFERENCIA A FACTURA, SUCURSAL Y EMPLEADO
CREATE TABLE VentaFisica (
    facturaId INT,
    sucursalId INT,
    empleadoId INT,
    PRIMARY KEY (facturaId, sucursalId, empleadoId),
    FOREIGN KEY (facturaId) REFERENCES Factura(id),
    FOREIGN KEY (sucursalId) REFERENCES Sucursal(id),
    FOREIGN KEY (empleadoId) REFERENCES Empleado(id)
);

-- Implementación de triggers
--- Parte I
-- Trigger A
-- A.1
CREATE TRIGGER InventoryFill
ON ProveedorProducto
AFTER INSERT 
AS
BEGIN
    -- Calcula el posible nuevo id para el inventario
	DECLARE @nuevoId INT;
	SELECT @nuevoId = ISNULL(MAX(id), 0) + 1 FROM Inventario;

    -- Actualizar o insertar en la tabla Inventario
    MERGE INTO Inventario AS target
    USING (SELECT productoId, SUM(cantidad) AS totalCantidad FROM inserted GROUP BY productoId) AS source
    ON target.productoId = source.productoId
    WHEN MATCHED THEN
        UPDATE SET cantidad = target.cantidad + source.totalCantidad
    WHEN NOT MATCHED THEN
        INSERT (id, productoId, cantidad)
        VALUES (@nuevoId,source.productoId, source.totalCantidad);
END;

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
            VALUES (@facturaId, GETDATE(), @clienteId, 0, 16, 0, 0, 0);

            -- Insertar la orden online
            INSERT INTO OrdenOnline (id, clienteId, nroOrden, fechaCreacion, tipoEnvioId, facturaId)
            VALUES (@id, @clienteId, @nroOrden, @fechaCreacion, @tipoEnvioId, @facturaId);

            -- Verificar si existen detalles de la orden
            IF NOT EXISTS (SELECT 1 FROM OrdenDetalle WHERE ordenId = @id)
            BEGIN
                -- Insertar al menos 3 productos aleatorios en OrdenDetalle
                INSERT INTO OrdenDetalle (id, ordenId, productoId, cantidad, precioPor)
                SELECT TOP 3
                    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (SELECT ISNULL(MAX(id), 0) FROM OrdenDetalle),
                    @id,
                    id,
                    CAST((RAND(CHECKSUM(NEWID())) * 10 + 1) AS INT), -- Genera una cantidad aleatoria entre 1 y 10
                    precioPor
                FROM Producto
                ORDER BY NEWID();
            END

            -- Insertar los detalles de la orden en FacturaDetalle
            INSERT INTO FacturaDetalle (id, facturaId, productoId, cantidad, precioPor)
            SELECT 
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (SELECT ISNULL(MAX(id), 0) FROM FacturaDetalle),
                @facturaId,
                productoId,
                cantidad,
                precioPor
            FROM OrdenDetalle
            WHERE ordenId = @id;
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
            VALUES (@facturaId, GETDATE(), @randomClienteId, 0, 16, 0, 0, 0);

            -- Insertar al menos 3 productos aleatorios en FacturaDetalle
            INSERT INTO FacturaDetalle (id, facturaId, productoId, cantidad, precioPor)
            SELECT TOP 4
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (SELECT ISNULL(MAX(id), 0) FROM FacturaDetalle),
                @facturaId,
                id,
                CAST((RAND(CHECKSUM(NEWID())) * 10 + 1) AS INT), -- Genera una cantidad aleatoria entre 1 y 10
                precioPor
            FROM Producto
            ORDER BY NEWID();
        END

        -- Insertar la venta física
        INSERT INTO VentaFisica (facturaId, sucursalId, empleadoId)
        VALUES (@facturaId, @sucursalId, @empleadoId);

        FETCH NEXT FROM cur INTO @facturaId, @sucursalId, @empleadoId;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;

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