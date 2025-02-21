-- Inserciones
--TipoEnvio
INSERT INTO TipoEnvio (id, nombreEnvio, tiempoEstimadoEntrega, costoEnvio) VALUES
(1, 'Envio inmediato', 1, 50.00),
(2, 'Mismo dia', 4, 30.00),
(3, 'Al dia siguiente', 23, 20.00),
(4, 'Semana siguiente', 168, 6.00),
(5, 'Envio estandar', 72, 15.00);

--FormaPago
INSERT INTO FormaPago (id, nombre, descripcion) VALUES
(1, 'Tarjeta de credito', 'Pago con tarjeta de credito Visa, Mastercard o Amex'),
(2, 'Tarjeta de debito', 'Pago con tarjeta de debito vinculada a una cuenta bancaria'),
(3, 'PayPal', 'Pago a traves de la plataforma PayPal'),
(4, 'Transferencia bancaria', 'Pago mediante transferencia electronica'),
(5, 'Efectivo', 'Pago en efectivo al momento de la entrega'),
(6, 'Cheque', 'Pago mediante cheque bancario'),
(7, 'Criptomonedas', 'Pago con Bitcoin, Ethereum u otras criptomonedas'),
(8, 'Pago movil', 'Pago a traves de aplicaciones moviles de cada banco'),
(9, 'Cashea', 'Pago fraccionado en varias cuotas mensuales'),
(10, 'Zelle', 'Pago a traves de aplicaciones moviles de bancos americanos');

--Cargo
INSERT INTO Cargo (id, nombre, descripcion, salarioBasePorHora) VALUES
(1, 'Cajero', 'Atencion al cliente en caja y cobro de productos', 12.00),
(2, 'Reponedor', 'Encargado de reponer productos en estanterias', 10.00),
(3, 'Gerente de Tienda', 'Responsable de la gestion general del supermercado', 25.00),
(4, 'Auxiliar de Limpieza', 'Mantenimiento y limpieza de las instalaciones', 9.00),
(5, 'Encargado de Almacen', 'Gestiona el inventario y almacen de productos', 15.00),
(6, 'Carnicero', 'Preparacion y venta de productos carnicos', 14.00),
(7, 'Panadero', 'Elaboracion y venta de productos de panaderia', 13.00),
(8, 'Fruteria', 'Encargado de la seccion de frutas y verduras', 12.00),
(9, 'Seguridad', 'Vigilancia y control de acceso en el supermercado', 11.00),
(10, 'Atencion al Cliente', 'Resuelve dudas y quejas de los clientes', 12.00),
(11, 'Promotor', 'Encargado de promociones y degustaciones', 10.00),
(12, 'Operario de Montacargas', 'Maneja montacargas para mover mercancia', 13.00),
(13, 'Tecnico de Refrigeracion', 'Mantenimiento de equipos de refrigeracion', 16.00),
(14, 'Dependiente de Farmacia', 'Atencion en la seccion de farmacia', 14.00),
(15, 'Analista de Inventarios', 'Control y gestion de inventarios', 18.00);


-- Marca
INSERT INTO Marca (id, nombre, descripcion) VALUES
(1, 'Coca-Cola', 'Bebidas gaseosas y refrescos'),
(2, 'Pepsi', 'Bebidas y snacks'),
(3, 'Nestle', 'Productos alimenticios y bebidas'),
(4, 'Unilever', 'Productos de cuidado personal y alimentos'),
(5, 'Kelloggs', 'Cereales y snacks'),
(6, 'Danone', 'Productos lacteos y yogures'),
(7, 'Heinz', 'Salsas y conservas'),
(8, 'Colgate', 'Productos de higiene bucal'),
(9, 'P&G', 'Productos de limpieza y cuidado personal'),
(10, 'Lays', 'Snacks y papas fritas'),
(11, 'Bimbo', 'Pan y productos de panaderia'),
(12, 'La Serenisima', 'Productos lacteos y derivados'),
(13, 'Quilmes', 'Bebidas alcoholicas y cervezas'),
(14, 'Arcor', 'Golosinas y productos alimenticios'),
(15, 'Molinos', 'Harinas y productos alimenticios'),
(16, 'Mondelez', 'Galletas y snacks'),
(17, 'Knorr', 'Sopas y condimentos'),
(18, 'Natura', 'Productos de belleza y cuidado personal'),
(19, 'Fanta', 'Bebidas gaseosas'),
(20, 'Sprite', 'Bebidas gaseosas')

-- Categoria
INSERT INTO Categoria (id, nombre, descripcion) VALUES
(1, 'Bebidas', 'Refrescos, aguas, jugos y bebidas alcoholicas'),
(2, 'Lacteos', 'Leche, yogures, quesos y derivados'),
(3, 'Carnes', 'Carnes frescas y procesadas'),
(4, 'Frutas y Verduras', 'Productos frescos de frutas y verduras'),
(5, 'Panaderia', 'Pan, bollos y productos de reposteria'),
(6, 'Snacks', 'Papas fritas, frutos secos y golosinas'),
(7, 'Congelados', 'Alimentos congelados y listos para cocinar'),
(8, 'Limpieza', 'Productos de limpieza para el hogar'),
(9, 'Cuidado Personal', 'Jabones, champus y productos de higiene'),
(10, 'Despensa', 'Arroz, pasta, legumbres y conservas'),
(11, 'Bebidas Alcoholicas', 'Cervezas, vinos y licores'),
(12, 'Mascotas', 'Alimentos y accesorios para mascotas'),
(13, 'Farmacia', 'Medicamentos y productos de salud'),
(14, 'Hogar', 'Utensilios y articulos para el hogar'),
(15, 'Electrodomesticos', 'Pequenos electrodomesticos'),
(16, 'Bebes', 'Panales, leches y productos para bebes'),
(17, 'Helados', 'Helados y postres congelados'),
(18, 'Cafe e Infusiones', 'Cafe, te y bebidas calientes'),
(19, 'Aceites y Vinagres', 'Aceites, vinagres y aderezos'),
(20, 'Especias y Condimentos', 'Especias, sal y condimentos'),
(21, 'Dulces y Chocolates', 'Chocolates, caramelos y dulces'),
(22, 'Conservas', 'Conservas de pescado, carne y vegetales'),
(23, 'Pastas Frescas', 'Pastas frescas y listas para cocinar'),
(24, 'Salsas y Aderezos', 'Salsas, mayonesas y ketchup'),
(25, 'Cereales', 'Cereales para el desayuno'),
(26, 'Galletas', 'Galletas dulces y saladas'),
(27, 'Enlatados', 'Productos enlatados y conservados'),
(28, 'Huevos', 'Huevos frescos y derivados'),
(29, 'Pescados y Mariscos', 'Pescados y mariscos frescos'),
(30, 'Comida Preparada', 'Platos preparados y listos para consumir');

--Pais
INSERT INTO Pais (id, nombre) VALUES
(1, 'Mexico'),
(2, 'Estados Unidos'),
(3, 'Colombia'),
(4, 'Argentina'),
(5, 'Espana'),
(6, 'Brasil'),
(7, 'Chile'),
(8, 'Peru'),
(9, 'Francia'),
(10, 'Venezuela');

--Estado
INSERT INTO Estado (id, nombre, paisId) VALUES
-- Mexico (id=1)
(1, 'Ciudad de Mexico', 1),
(2, 'Jalisco', 1),
(3, 'Nuevo Leon', 1),
(4, 'Puebla', 1),
(5, 'Veracruz', 1),

-- Estados Unidos (id=2)
(6, 'California', 2),
(7, 'Texas', 2),
(8, 'Nueva York', 2),
(9, 'Florida', 2),
(10, 'Illinois', 2),

-- Colombia (id=3)
(11, 'Bogota D.C.', 3),
(12, 'Antioquia', 3),
(13, 'Valle del Cauca', 3),
(14, 'Santander', 3),
(15, 'Cundinamarca', 3),

-- Argentina (id=4)
(16, 'Buenos Aires', 4),
(17, 'Cordoba', 4),
(18, 'Santa Fe', 4),
(19, 'Mendoza', 4),
(20, 'Tucuman', 4),

-- Venezuela (id=10)
(21, 'Distrito Capital', 10),    
(22, 'Miranda', 10),               
(23, 'Zulia', 10),                 
(24, 'Carabobo', 10),               
(25, 'Lara', 10);


--Ciudad
INSERT INTO Ciudad (id, nombre, estadoId) VALUES
-- Ciudad de Mexico (id=1)
(1, 'Ciudad de Mexico', 1),
(2, 'Iztapalapa', 1),
(3, 'Gustavo A. Madero', 1),

-- Jalisco (id=2)
(4, 'Guadalajara', 2),
(5, 'Zapopan', 2),
(6, 'Tlaquepaque', 2),

-- Nuevo Leon (id=3)
(7, 'Monterrey', 3),
(8, 'San Pedro Garza Garcia', 3),
(9, 'Guadalupe', 3),

-- Puebla (id=4)
(10, 'Puebla', 4),
(11, 'Tehuacan', 4),
(12, 'Cholula', 4),

-- Veracruz (id=5)
(13, 'Veracruz', 5),
(14, 'Xalapa', 5),
(15, 'Cordoba', 5),

-- California (id=6)
(16, 'Los Angeles', 6),
(17, 'San Francisco', 6),
(18, 'San Diego', 6),

-- Texas (id=7)
(19, 'Houston', 7),
(20, 'Dallas', 7),
(21, 'Austin', 7),

-- Nueva York (id=8)
(22, 'Nueva York', 8),
(23, 'Buffalo', 8),
(24, 'Rochester', 8),

-- Florida (id=9)
(25, 'Miami', 9),
(26, 'Orlando', 9),
(27, 'Tampa', 9),

-- Illinois (id=10)
(28, 'Chicago', 10),
(29, 'Springfield', 10),
(30, 'Peoria', 10),

-- Bogota D.C. (id=11)
(31, 'Bogota', 11),

-- Antioquia (id=12)
(32, 'Medellin', 12),
(33, 'Envigado', 12),
(34, 'Bello', 12),

-- Valle del Cauca (id=13)
(35, 'Cali', 13),
(36, 'Palmira', 13),
(37, 'Buenaventura', 13),

-- Santander (id=14)
(38, 'Bucaramanga', 14),
(39, 'Floridablanca', 14),
(40, 'Barrancabermeja', 14),

-- Cundinamarca (id=15)
(41, 'Soacha', 15),
(42, 'Girardot', 15),
(43, 'Facatativa', 15),

-- Buenos Aires (id=16)
(44, 'Buenos Aires', 16),
(45, 'La Plata', 16),
(46, 'Mar del Plata', 16),

-- Venezuela: Distrito Capital (id=21)
(47, 'Caracas', 21),

-- Venezuela: Miranda (id=22)
(48, 'Los Teques', 22),
(49, 'Petare', 22),

-- Venezuela: Zulia (id=23)
(50, 'Maracaibo', 23),

-- Venezuela: Distrito Capital (id=21)
(51, 'El Junquito', 21),

-- Venezuela: Miranda (id=22)
(52, 'Charallave', 22),
(53, 'Cua', 22),
(54, 'Guarenas', 22),

-- Venezuela: Zulia (id=23)
(55, 'Cabimas', 23),
(56, 'Santa Barbara del Zulia', 23),
(57, 'Ciudad Ojeda', 23),

-- Venezuela: Carabobo (id=24)
(58, 'San Joaquin', 24),
(59, 'Bejuma', 24),
(60, 'Tocuyito', 24),

-- Venezuela: Lara (id=25)
(61, 'Quibor', 25),
(62, 'El Tocuyo', 25),
(63, 'Carora', 25),
(64, 'Sanare', 25),
(65, 'Cubiro', 25);
