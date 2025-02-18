-- Creacion de tablas

-- CREAMOS LA TABLA MARCA
CREATE TABLE Marca (
    id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- CREAMOS LA TABLA CATEGORIA
CREATE TABLE Categoria (
    id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- CREAMOS LA TABLA CLIENTE
CREATE TABLE Cliente (
    id INT PRIMARY KEY,
    CI VARCHAR(20) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    sexo CHAR(1) CHECK (sexo IN ('M', 'F')),
    fechaNacimiento DATE,
    fechaRegistro DATE NOT NULL
);

-- CREAMOS LA TABLA DIRECCION DEL CLIENTE, LA CUAL REFERENCIA A CLIENTE
CREATE TABLE ClienteDireccion (
    id INT PRIMARY KEY,
    clienteId INT,
    tipoDireccion VARCHAR(15) CHECK (tipoDireccion IN ('Facturacion', 'Envio')),
    dirLinea1 VARCHAR(100) NOT NULL,
    ciudadId INT,
    FOREIGN KEY (clienteId) REFERENCES Cliente(id)
);

-- CREAMOS LA TABLA PRODUCTO , LA CUAL REFERENCIA A MARCA Y CATEGORIA
CREATE TABLE Producto (
    id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    codigoBarra VARCHAR(50),
    descripcion TEXT,
    tipoPrecio VARCHAR(10) CHECK (tipoPrecio IN ('PorUnidad', 'PorPesoKg')),
    precioPor DECIMAL(10, 2) CHECK (precioPor >= 0),
    esExentoIVA BOOL,
    categoriald INT,
    marcald INT,
    FOREIGN KEY (categoriald) REFERENCES Categoria(id),
    FOREIGN KEY (marcald) REFERENCES Marca(id)
);

-- CREAMOS LA TABLA PRODUCTORECOMENDADO, LA CUAL REFERENCIA A PRODUCTO
CREATE TABLE ProductoRecomendadoParaProducto (
    productoId INT,
    productoRecomendadold INT,
    mensaje TEXT,
    PRIMARY KEY (productoId, productoRecomendadold),
    FOREIGN KEY (productoId) REFERENCES Producto(id),
    FOREIGN KEY (productoRecomendadold) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA PRODUCTOPARACLIENTE, LA CUAL REFERENCIA A LOS PRODUCTOS Y A CLIENTES
CREATE TABLE ProductoRecomendadoParaCliente (
    clienteId INT,
    productoRecomendadold INT,
    fechaRecomendacion DATE,
    mensaje TEXT,
    PRIMARY KEY (clienteId, productoRecomendadold, fechaRecomendacion),
    FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    FOREIGN KEY (productoRecomendadold) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA TIPO DE ENVIO
CREATE TABLE TipoEnvio (
    id INT PRIMARY KEY,
    nombreEnvio VARCHAR(50) NOT NULL,
    tiempoEstimadoEntrega INT CHECK (tiempoEstimadoEntrega >= 0),
    costoEnvio DECIMAL(10, 2) CHECK (costoEnvio >= 0)
);

-- CREAMOS LA TABLA HISTORIA DE CLIENTE, LA CUAL REFERENCIA A CLIENTE Y PRODUCTO
CREATE TABLE HistorialClienteProducto (
    clienteId INT,
    productoId INT,
    fecha DATE,
    tipoAccion VARCHAR(15) CHECK (tipoAccion IN ('Busqueda', 'Carrito', 'Compra')),
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
    precioPor DECIMAL(10, 2) CHECK (precioPor >= 0),
    PRIMARY KEY (clienteId, productoId),
    FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA FORMA DE PAGO
CREATE TABLE FormaPago (
    id INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

--CREAMOS LA TABLA FACTURA, LA CUAL REFERENCIA A CLIENTE
CREATE TABLE Factura (
    id INT PRIMARY KEY,
    fechaEmision DATE,
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
    nroTransaccion VARCHAR(50) NOT NULL,
    metodoPagoId INT,
    PRIMARY KEY (facturaId, nroTransaccion),
    FOREIGN KEY (facturaId) REFERENCES Factura(id),
    FOREIGN KEY (metodoPagoId) REFERENCES FormaPago(id)
);

-- CREAMOS LA TABLA ORDEN ONLINE, LA CUAL REFERENCIA A CLIENTE, TIPO DE ENVIO Y A FACTURA
CREATE TABLE OrdenOnline (
    id INT PRIMARY KEY,
    clienteId INT,
    nroOrden VARCHAR(50) NOT NULL,
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
    nombre VARCHAR(100) NOT NULL
);

-- CREAMOS LA TABLA ESTADO, LA CUAL REFERENCIA A PAIS
CREATE TABLE Estado (
    id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    paisId INT,
    FOREIGN KEY (paisId) REFERENCES Pais(id)
);

-- CREAMOS LA TABLA CIUDAD, LA CUAL REFERENCIA A ESTADO
CREATE TABLE Ciudad (
    id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    estadoId INT,
    FOREIGN KEY (estadoId) REFERENCES Estado(id)
);

-- CREAMOS LA TABLA PROMO
CREATE TABLE Promo (
    id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    slogan VARCHAR(255),
    codigo VARCHAR(50) UNIQUE NOT NULL,
    tipoDescuento VARCHAR(10) CHECK (tipoDescuento IN ('Porcentaje', 'Fijo')),
    valorDescuento DECIMAL(10, 2) CHECK (valorDescuento >= 0),
    fechaInicio DATE,
    fechaFin DATE,
    tipoPromocion VARCHAR(10) CHECK (tipoPromocion IN ('Online', 'Fisica', 'Ambos'))
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
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(255),
    telefono VARCHAR(20),
    horaAbrir INT CHECK (horaAbrir >= 0 AND horaAbrir <= 23),
    horaCerrar INT CHECK (horaCerrar >= 0 AND horaCerrar <= 23),
    ciudadId INT,
    FOREIGN KEY (ciudadId) REFERENCES Ciudad(id)
);

-- CREAMOS LA TABLA CARGO
CREATE TABLE Cargo (
    id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    salarioBasePorHora DECIMAL(10, 2) CHECK (salarioBasePorHora >= 0)
);

-- CREAMOS LA TABLA EMPLEADO, LA CUAL REFERENCIA A CARGO, SUCURSAL Y A EMPLEADO A TRAVEZ DE LA RECURSIVIDAD
CREATE TABLE Empleado (
    id INT PRIMARY KEY,
    CI VARCHAR(20) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    sexo CHAR(1) CHECK (sexo IN ('M', 'F')),
    direccionCorta VARCHAR(255),
    cargoId INT,
    empleadoSupervisorId INT,
    sucursalId INT,
    fechaContrato DATE,
    bonoFijoMensual DECIMAL(10, 2) CHECK (bonoFijoMensual >= 0),
    horaInicio INT CHECK (horaInicio >= 0 AND horaInicio <= 23),
    horaFin INT CHECK (horaFin >= 0 AND horaFin <= 23),
    cantidadDiasTrabajoPorSemana INT CHECK (cantidadDiasTrabajoPorSemana >= 1 AND cantidadDiasTrabajoPorSemana <= 7),
    FOREIGN KEY (cargoId) REFERENCES Cargo(id),
    FOREIGN KEY (empleadoSupervisorId) REFERENCES Empleado(id),
    FOREIGN KEY (sucursalId) REFERENCES Sucursal(id)
);

-- CREAMOS LA TABLA INVENTARIO, LA CUAL REFERENCIA A PRODUCTO
CREATE TABLE Inventario (
    id INT PRIMARY KEY,
    productoId INT,
    cantidad INT CHECK (cantidad >= 0),
    FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- CREAMOS LA TABLA PROVEEDOR LA CUAL REFERENCIA A CIUDAD
CREATE TABLE Proveedor (
    id INT PRIMARY KEY,
    RIF VARCHAR(20) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    contacto VARCHAR(100),
    telefono VARCHAR(20),
    correo VARCHAR(100),
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