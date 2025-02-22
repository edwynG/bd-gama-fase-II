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
    nombre VARCHAR(MAX) NOT NULL,
    descripcion VARCHAR(MAX)
);

-- CREAMOS LA TABLA CATEGORIA
CREATE TABLE Categoria (
    id INT PRIMARY KEY,
    nombre VARCHAR(MAX) NOT NULL,
    descripcion VARCHAR(MAX)
);

-- CREAMOS LA TABLA CLIENTE
CREATE TABLE Cliente (
    id INT PRIMARY KEY,
    CI  INT,
    nombre VARCHAR(MAX) NOT NULL,
    apellido VARCHAR(MAX) NOT NULL,
    correo VARCHAR(MAX) NOT NULL,
    sexo CHAR(1) CHECK (sexo IN ('M', 'F')),
    fechaNacimiento DATE,
    fechaRegistro DATE NOT NULL
);

-- CREAMOS LA TABLA DIRECCION DEL CLIENTE, LA CUAL REFERENCIA A CLIENTE
CREATE TABLE ClienteDireccion (
    id INT PRIMARY KEY,
    clienteId INT,
    tipoDireccion VARCHAR(MAX) CHECK (tipoDireccion IN ('Facturacion', 'Envio')),
    dirLinea1 VARCHAR(MAX) NOT NULL,
    ciudadId INT,
    FOREIGN KEY (clienteId) REFERENCES Cliente(id)
);

-- CREAMOS LA TABLA PRODUCTO , LA CUAL REFERENCIA A MARCA Y CATEGORIA
CREATE TABLE Producto (
    id INT PRIMARY KEY,
    nombre VARCHAR(MAX) NOT NULL,
    codigoBarra VARCHAR(MAX),
    descripcion VARCHAR(MAX),
    tipoPrecio VARCHAR(MAX) CHECK (tipoPrecio IN ('PorUnidad', 'PorPesoKg')),
    precioPor MONEY CHECK (precioPor >= 0),
    esExentoIVA BIT NOT NULL,
    categoriald INT,
    marcald INT,
    FOREIGN KEY (categoriald) REFERENCES Categoria(id),
    FOREIGN KEY (marcald) REFERENCES Marca(id)
);

-- CREAMOS LA TABLA PRODUCTORECOMENDADO, LA CUAL REFERENCIA A PRODUCTO
CREATE TABLE ProductoRecomendadoParaProducto (
    productoId INT,
    productoRecomendadold INT,
    mensaje VARCHAR(MAX),
    PRIMARY KEY (productoId, productoRecomendadold),
    FOREIGN KEY (productoId) REFERENCES Producto(id),
    FOREIGN KEY (productoRecomendadold) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA PRODUCTOPARACLIENTE, LA CUAL REFERENCIA A LOS PRODUCTOS Y A CLIENTES
CREATE TABLE ProductoRecomendadoParaCliente (
    clienteId INT,
    productoRecomendadold INT,
    fechaRecomendacion DATE,
    mensaje VARCHAR(MAX),
    PRIMARY KEY (clienteId, productoRecomendadold, fechaRecomendacion),
    FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    FOREIGN KEY (productoRecomendadold) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA TIPO DE ENVIO
CREATE TABLE TipoEnvio (
    id INT PRIMARY KEY,
    nombreEnvio VARCHAR(MAX) NOT NULL,
    tiempoEstimadoEntrega INT,
    costoEnvio MONEY CHECK (costoEnvio >= 0)
);

-- CREAMOS LA TABLA HISTORIA DE CLIENTE, LA CUAL REFERENCIA A CLIENTE Y PRODUCTO
CREATE TABLE HistorialClienteProducto (
    clienteId INT,
    productoId INT,
    fecha DATE,
    tipoAccion VARCHAR(MAX) CHECK (tipoAccion IN ('Busqueda', 'Carrito', 'Compra')),
    PRIMARY KEY (clienteId, productoId, fecha),
    FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA CARRITO, LA CUAL REFERENCIA A CLIENTE Y PRODUCTO
CREATE TABLE Carrito (
    clienteId INT,
    productoId INT,
    fechaAgregado DATE,
    cantidad INT CHECK (cantidad >= 0),
    precioPor MONEY CHECK (precioPor >= 0),
    PRIMARY KEY (clienteId, productoId),
    FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA FORMA DE PAGO
CREATE TABLE FormaPago (
    id INT PRIMARY KEY,
    nombre VARCHAR(MAX) NOT NULL,
    descripcion VARCHAR(MAX)
);

--CREAMOS LA TABLA FACTURA, LA CUAL REFERENCIA A CLIENTE
CREATE TABLE Factura (
    id INT PRIMARY KEY,
    fechaEmision DATE,
    clienteId INT,
    subTotal MONEY CHECK (subTotal >= 0),
    montoDescuentoTotal MONEY CHECK (montoDescuentoTotal >= 0),
    porcentajeIVA DECIMAL(5, 2) CHECK (porcentajeIVA >= 0),
    montoIVA MONEY CHECK (montoIVA >= 0),
    montoTotal MONEY CHECK (montoTotal >= 0),
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
    fechaCreacion DATE,
    tipoEnvioId INT,
    facturaId INT,
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
    nombre VARCHAR(MAX) NOT NULL
);

-- CREAMOS LA TABLA ESTADO, LA CUAL REFERENCIA A PAIS
CREATE TABLE Estado (
    id INT PRIMARY KEY,
    nombre VARCHAR(MAX) NOT NULL,
    paisId INT,
    FOREIGN KEY (paisId) REFERENCES Pais(id)
);

-- CREAMOS LA TABLA CIUDAD, LA CUAL REFERENCIA A ESTADO
CREATE TABLE Ciudad (
    id INT PRIMARY KEY,
    nombre VARCHAR(MAX) NOT NULL,
    estadoId INT,
    FOREIGN KEY (estadoId) REFERENCES Estado(id)
);

-- CREAMOS LA TABLA PROMO
CREATE TABLE Promo (
    id INT PRIMARY KEY,
    nombre VARCHAR(MAX) NOT NULL,
    slogan VARCHAR(MAX),
    codigo INT,
    tipoDescuento VARCHAR(MAX) CHECK (tipoDescuento IN ('Porcentaje', 'Fijo')),
    valorDescuento MONEY CHECK (valorDescuento >= 0),
    fechaInicio DATE,
    fechaFin DATE,
    tipoPromocion VARCHAR(MAX) CHECK (tipoPromocion IN ('Online', 'Fisica', 'Ambos'))
);

-- CREAMOS LA TABLA PROMO ESPECIALIZADA, LA CUAL REFERENCIA A PROMO, PRODUCTO, CATEGORIA Y MARCA
CREATE TABLE PromoEspecializada (
    id INT PRIMARY KEY,
    promoId INT,
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
    nombre VARCHAR(MAX) NOT NULL,
    direccion VARCHAR(MAX),
    telefono VARCHAR(MAX),
    horaAbrir INT CHECK (horaAbrir BETWEEN 0 AND 23 ),
    horaCerrar INT CHECK (horaCerrar BETWEEN 0 AND 23),
    ciudadId INT,
    FOREIGN KEY (ciudadId) REFERENCES Ciudad(id)
);

-- CREAMOS LA TABLA CARGO
CREATE TABLE Cargo (
    id INT PRIMARY KEY,
    nombre VARCHAR(MAX) NOT NULL,
    descripcion VARCHAR(MAX),
    salarioBasePorHora MONEY CHECK (salarioBasePorHora >= 0)
);

-- CREAMOS LA TABLA EMPLEADO, LA CUAL REFERENCIA A CARGO, SUCURSAL Y A EMPLEADO A TRAVEZ DE LA RECURSIVIDAD
CREATE TABLE Empleado (
    id INT PRIMARY KEY,
    CI INT,
    nombre VARCHAR(MAX) NOT NULL,
    apellido VARCHAR(MAX) NOT NULL,
    sexo CHAR(1) CHECK (sexo IN ('M', 'F')),
    direccionCorta VARCHAR(MAX),
    cargoId INT,
    empleadoSupervisorId INT,
    sucursalId INT,
    fechaContrato DATE,
    bonoFijoMensual MONEY CHECK (bonoFijoMensual >= 0),
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
    RIF VARCHAR(MAX),
    nombre VARCHAR(MAX) NOT NULL,
    contacto VARCHAR(MAX) NOT NULL,
    telefono VARCHAR(MAX),
    correo VARCHAR(MAX),
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