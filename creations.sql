-- Creacion de tablas

-- TABLA DE PRODUCTOS RECOMENDADOS PARA CLIENTES
CREATE TABLE ProductoRecomendadoParaCliente (
    clienteId INT NOT NULL,
    productoRecomendadoId INT NOT NULL,
    fechaRecomendacion DATE NOT NULL,
    mensaje VARCHAR(255) NOT NULL,
    CONSTRAINT CHK_Mensaje_No_Nulo CHECK (mensaje <> ''),
    CONSTRAINT PK_ProductoRecomendadoParaCliente PRIMARY KEY (clienteId, productoRecomendadoId)
);

-- TABLA DE CATEGORIA
CREATE TABLE Categoria (
    id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255),
    CONSTRAINT CHK_Categoria_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT PK_Categoria PRIMARY KEY (id)
);

-- TABLA DE MARCA
CREATE TABLE Marca (
    id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255),
    CONSTRAINT CHK_Marca_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT PK_Marca PRIMARY KEY (id)
);

-- TABLA DEL HISTORIAL DE PRODUCTOS DE UN CLIENTE
CREATE TABLE HistorialClienteProducto (
    clienteId INT NOT NULL,
    productoId INT NOT NULL,
    fecha DATE NOT NULL,
    tipoAccion VARCHAR(10) NOT NULL,
    CONSTRAINT CHK_TipoAccion CHECK (tipoAccion IN ('Busqueda', 'Carrito', 'Compra')),
    CONSTRAINT PK_HistorialClienteProducto PRIMARY KEY (clienteId, productoId, fecha),
    CONSTRAINT FK_HistorialClienteProducto_Cliente FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    CONSTRAINT FK_HistorialClienteProducto_Producto FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- TABLA CARRITO
CREATE TABLE Carrito (
    clienteId INT NOT NULL,
    productoId INT NOT NULL,
    fechaAgregado DATE NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad >= 0),
    precioPor VARCHAR(10) NOT NULL CHECK (precioPor IN ('PorUnidad', 'PorPesoKg')),
    CONSTRAINT PK_Carrito PRIMARY KEY (clienteId, productoId, fechaAgregado),
    CONSTRAINT FK_Carrito_Cliente FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    CONSTRAINT FK_Carrito_Producto FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- TABLA TIPOS DE ENVIO
CREATE TABLE TipoEnvio (
    id INT NOT NULL,
    nombreEnvio VARCHAR(100) NOT NULL,
    tiempoEstimadoEntrega INT NOT NULL CHECK (tiempoEstimadoEntrega BETWEEN 0 AND 23),
    costoEnvio DECIMAL(10, 2) NOT NULL CHECK (costoEnvio >= 0),
    CONSTRAINT CHK_TipoEnvio_Nombre_No_Nulo CHECK (nombreEnvio <> ''),
    CONSTRAINT PK_TipoEnvio PRIMARY KEY (id)
);

-- TABLA DE ORDENES ONLINE
CREATE TABLE OrdenOnline (
    id INT NOT NULL,
    clienteId INT NOT NULL,
    nroOrden VARCHAR(50) NOT NULL,
    fechaCreacion DATE NOT NULL,
    tipoEnvioId INT NOT NULL,
    facturaId INT,
    CONSTRAINT CHK_OrdenOnline_NroOrden_No_Nulo CHECK (nroOrden <> ''),
    CONSTRAINT PK_OrdenOnline PRIMARY KEY (id),
    CONSTRAINT FK_OrdenOnline_Cliente FOREIGN KEY (clienteId) REFERENCES Cliente(id),
    CONSTRAINT FK_OrdenOnline_TipoEnvio FOREIGN KEY (tipoEnvioId) REFERENCES TipoEnvio(id),
    CONSTRAINT FK_OrdenOnline_Factura FOREIGN KEY (facturaId) REFERENCES Factura(id)
);

-- TABLA DE LOS DETALLES DE ORDEN
CREATE TABLE OrdenDetalle (
    id INT NOT NULL,
    ordenId INT NOT NULL,
    productoId INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad >= 0),
    precioPor VARCHAR(10) NOT NULL CHECK (precioPor IN ('PorUnidad', 'PorPesoKg')),
    CONSTRAINT PK_OrdenDetalle PRIMARY KEY (id),
    CONSTRAINT FK_OrdenDetalle_Orden FOREIGN KEY (ordenId) REFERENCES OrdenOnline(id),
    CONSTRAINT FK_OrdenDetalle_Producto FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- TABLAS DE LAS VENTAS FISICAS
CREATE TABLE VentaFisica (
    facturaId INT NOT NULL,
    sucursalId INT NOT NULL,
    empleadoId INT NOT NULL,
    CONSTRAINT PK_VentaFisica PRIMARY KEY (facturaId, sucursalId, empleadoId),
    CONSTRAINT FK_VentaFisica_Factura FOREIGN KEY (facturaId) REFERENCES Factura(id),
    CONSTRAINT FK_VentaFisica_Sucursal FOREIGN KEY (sucursalId) REFERENCES Sucursal(id),
    CONSTRAINT FK_VentaFisica_Empleado FOREIGN KEY (empleadoId) REFERENCES Empleado(id)
);

-- TABLA DE FACTURA
CREATE TABLE Factura (
    id INT NOT NULL,
    fechaEmision DATE NOT NULL,
    clienteId INT NOT NULL,
    subTotal DECIMAL(10, 2) NOT NULL CHECK (subTotal >= 0),
    montoDescuentoTotal DECIMAL(10, 2) NOT NULL CHECK (montoDescuentoTotal >= 0),
    porcentajeIVA DECIMAL(5, 2) NOT NULL CHECK (porcentajeIVA >= 0),
    montoIVA DECIMAL(10, 2) NOT NULL CHECK (montoIVA >= 0),
    montoTotal DECIMAL(10, 2) NOT NULL CHECK (montoTotal >= 0),
    CONSTRAINT PK_Factura PRIMARY KEY (id),
    CONSTRAINT FK_Factura_Cliente FOREIGN KEY (clienteId) REFERENCES Cliente(id)
);

-- TABLA DE LOS DETALLES DE FACTURA
CREATE TABLE FacturaDetalle (
    id INT NOT NULL,
    facturaId INT NOT NULL,
    productoId INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad >= 0),
    precioPor VARCHAR(10) NOT NULL CHECK (precioPor IN ('PorUnidad', 'PorPesoKg')),
    CONSTRAINT PK_FacturaDetalle PRIMARY KEY (id),
    CONSTRAINT FK_FacturaDetalle_Factura FOREIGN KEY (facturaId) REFERENCES Factura(id),
    CONSTRAINT FK_FacturaDetalle_Producto FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- TABLA DE PAGO
CREATE TABLE Pago (
    facturaId INT NOT NULL,
    nroTransaccion VARCHAR(50) NOT NULL,
    metodoPagoId INT NOT NULL,
    CONSTRAINT PK_Pago PRIMARY KEY (facturaId, nroTransaccion),
    CONSTRAINT FK_Pago_Factura FOREIGN KEY (facturaId) REFERENCES Factura(id),
    CONSTRAINT FK_Pago_MetodoPago FOREIGN KEY (metodoPagoId) REFERENCES FormaPago(id)
);

-- TABLA DE LAS FORMAS DE PAGO
CREATE TABLE FormaPago (
    id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255),
    CONSTRAINT CHK_FormaPago_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT PK_FormaPago PRIMARY KEY (id)
);

-- TABLA DE PROMO
CREATE TABLE Promo (
    id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    slogan VARCHAR(255),
    codigo VARCHAR(50) NOT NULL,
    tipoDescuento VARCHAR(10) NOT NULL CHECK (tipoDescuento IN ('Porcentaje', 'Fijo')),
    valorDescuento DECIMAL(10, 2) NOT NULL CHECK (valorDescuento >= 0),
    fechaInicio DATE NOT NULL,
    fechaFin DATE NOT NULL,
    tipoPromocion VARCHAR(10) NOT NULL CHECK (tipoPromocion IN ('Online', 'Fisica', 'Ambos')),
    CONSTRAINT CHK_Promo_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT PK_Promo PRIMARY KEY (id)
);

-- TABLA DE PROMO ESPECIALIZADA
CREATE TABLE PromoEspecializada (
    id INT NOT NULL,
    promoId INT NOT NULL,
    productoId INT,
    categoriaId INT,
    marcaId INT,
    CONSTRAINT PK_PromoEspecializada PRIMARY KEY (id),
    CONSTRAINT FK_PromoEspecializada_Promo FOREIGN KEY (promoId) REFERENCES Promo(id),
    CONSTRAINT FK_PromoEspecializada_Producto FOREIGN KEY (productoId) REFERENCES Producto(id),
    CONSTRAINT FK_PromoEspecializada_Categoria FOREIGN KEY (categoriaId) REFERENCES Categoria(id),
    CONSTRAINT FK_PromoEspecializada_Marca FOREIGN KEY (marcaId) REFERENCES Marca(id)
);

-- TABLA DE FACTURA PROMO
CREATE TABLE FacturaPromo (
    facturaId INT NOT NULL,
    promoId INT NOT NULL,
    CONSTRAINT PK_FacturaPromo PRIMARY KEY (facturaId, promoId),
    CONSTRAINT FK_FacturaPromo_Factura FOREIGN KEY (facturaId) REFERENCES Factura(id),
    CONSTRAINT FK_FacturaPromo_Promo FOREIGN KEY (promoId) REFERENCES Promo(id)
);

-- TABLA DE PAIS
CREATE TABLE Pais (
    id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    CONSTRAINT CHK_Pais_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT PK_Pais PRIMARY KEY (id)
);

-- TABLA DE ESTADO
CREATE TABLE Estado (
    id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    paisId INT NOT NULL,
    CONSTRAINT CHK_Estado_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT PK_Estado PRIMARY KEY (id),
    CONSTRAINT FK_Estado_Pais FOREIGN KEY (paisId) REFERENCES Pais(id)
);

-- TABLA DE CIUDAD
CREATE TABLE Ciudad (
    id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    estadoId INT NOT NULL,
    CONSTRAINT CHK_Ciudad_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT PK_Ciudad PRIMARY KEY (id),
    CONSTRAINT FK_Ciudad_Estado FOREIGN KEY (estadoId) REFERENCES Estado(id)
);

-- TABLA DE SUCURSAL
CREATE TABLE Sucursal (
    id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    horaAbrir INT NOT NULL CHECK (horaAbrir BETWEEN 0 AND 23),
    horaCerrar INT NOT NULL CHECK (horaCerrar BETWEEN 0 AND 23),
    ciudadId INT NOT NULL,
    CONSTRAINT CHK_Sucursal_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT PK_Sucursal PRIMARY KEY (id),
    CONSTRAINT FK_Sucursal_Ciudad FOREIGN KEY (ciudadId) REFERENCES Ciudad(id)
);

-- TABLA DE EMPLEADO
CREATE TABLE Empleado (
    id INT NOT NULL,
    CI VARCHAR(20) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    sexo CHAR(1) NOT NULL CHECK (sexo IN ('M', 'F')),
    direccionCorta VARCHAR(255) NOT NULL,
    cargoId INT NOT NULL,
    empleadoSupervisorId INT,
    sucursalId INT NOT NULL,
    fechaContrato DATE NOT NULL,
    bonoFijoMensual DECIMAL(10, 2) NOT NULL CHECK (bonoFijoMensual >= 0),
    horaInicio INT NOT NULL CHECK (horaInicio BETWEEN 0 AND 23),
    horaFin INT NOT NULL CHECK (horaFin BETWEEN 0 AND 23),
    cantidadDiasTrabajoPorSemana INT NOT NULL CHECK (cantidadDiasTrabajoPorSemana BETWEEN 1 AND 7),
    CONSTRAINT CHK_Empleado_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT CHK_Empleado_Apellido_No_Nulo CHECK (apellido <> ''),
    CONSTRAINT PK_Empleado PRIMARY KEY (id),
    CONSTRAINT FK_Empleado_Cargo FOREIGN KEY (cargoId) REFERENCES Cargo(id),
    CONSTRAINT FK_Empleado_Sucursal FOREIGN KEY (sucursalId) REFERENCES Sucursal(id)
);

-- TABLA DE CARGO
CREATE TABLE Cargo (
    id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255),
    salarioBasePorHora DECIMAL(10, 2) NOT NULL CHECK (salarioBasePorHora >= 0),
    CONSTRAINT CHK_Cargo_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT PK_Cargo PRIMARY KEY (id)
);

-- TABLA DE INVENTARIO
CREATE TABLE Inventario (
    id INT NOT NULL,
    productoId INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad >= 0),
    CONSTRAINT PK_Inventario PRIMARY KEY (id),
    CONSTRAINT FK_Inventario_Producto FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- TABLA DE PROVEEDOR
CREATE TABLE Proveedor (
    id INT NOT NULL,
    RIF VARCHAR(20) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    contacto VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    ciudadId INT NOT NULL,
    CONSTRAINT CHK_Proveedor_Nombre_No_Nulo CHECK (nombre <> ''),
    CONSTRAINT CHK_Proveedor_Contacto_No_Nulo CHECK (contacto <> ''),
    CONSTRAINT PK_Proveedor PRIMARY KEY (id),
    CONSTRAINT FK_Proveedor_Ciudad FOREIGN KEY (ciudadId) REFERENCES Ciudad(id)
);

-- TABLA DE PROVEDOR ASOCIADA A PRODUCTO
CREATE TABLE ProveedorProducto (
    id INT NOT NULL,
    proveedorId INT NOT NULL,
    productoId INT NOT NULL,
    fechaCompra DATE NOT NULL,
    precioPor VARCHAR(10) NOT NULL CHECK (precioPor IN ('PorUnidad', 'PorPesoKg')),
    cantidad INT NOT NULL CHECK (cantidad >= 0),
    CONSTRAINT PK_ProveedorProducto PRIMARY KEY (id),
    CONSTRAINT FK_ProveedorProducto_Proveedor FOREIGN KEY (proveedorId) REFERENCES Proveedor(id),
    CONSTRAINT FK_ProveedorProducto_Producto FOREIGN KEY (productoId) REFERENCES Producto(id)
);

-- Implementación de triggers
