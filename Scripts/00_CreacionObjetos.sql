--CREACION DB
USE master 
GO

DROP DATABASE IF EXISTS Com5600G10
CREATE DATABASE Com5600G10

USE prueba
GO

--CREACION SCHEMAS--

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'eSocios')
	EXEC('CREATE SCHEMA eSocios');
GO

IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name = 'eCobros') 
	EXEC ('CREATE SCHEMA eCobros');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'eAdministrativos')
	EXEC ('CREATE SCHEMA eAdministrativos');
GO



--CREACION DE TABLA CATEGORIA
IF OBJECT_ID(N'eSocios.Categoria', N'U') IS NULL
BEGIN
	CREATE TABLE eSocios.Categoria ( 
	id_categoria INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    costo_mensual DECIMAL(10,2) NOT NULL CHECK (costo_mensual >= 0),
	Vigencia date NOT NULL --Nuevo
	);
END
GO


--CREACION DE TABLA SOCIO
IF OBJECT_ID(N'eSocios.Socio', N'U') IS NULL
BEGIN
CREATE TABLE eSocios.Socio (
    id_socio varchar(20) PRIMARY KEY, --Nuevo
    id_categoria int NOT NULL,
    dni int UNIQUE NOT NULL,
    nombre varchar(50) NOT NULL,
    apellido varchar(50) NOT NULL,
    email nvarchar(100) CHECK (email LIKE '%@%.%' AND email NOT LIKE '%@%@%' AND email NOT LIKE '@%' AND email NOT LIKE '%@'),
    fecha_nac date NOT NULL,
    telefono varchar(20),
    telefono_emergencia varchar(20),
    obra_social varchar(50),
    nro_obra_social varchar(15),
	tel_obra_social varchar(30),
	activo BIT DEFAULT 1 CHECK (activo IN (0,1)),
	constraint FKSoc FOREIGN KEY (id_categoria) references eSocios.Categoria (id_categoria)
);
END
GO


IF OBJECT_ID(N'eSocios.Tutor', N'U') IS NULL
BEGIN
CREATE TABLE eSocios.Tutor ( --Nuevo
    id_tutor varchar(20) PRIMARY KEY,
    nombre varchar(50) NOT NULL, 
    apellido varchar (50) NOT NULL,
	DNI int UNIQUE NOT NULL,
    email nvarchar(100) NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
    fecha_nac date NOT NULL,
    telefono varchar(20) NOT NULL
);
END
GO


--CREACION DE TABLA GRUPO FAMILIAR
IF OBJECT_ID(N'eSocios.GrupoFamiliar', N'U') IS NULL
BEGIN
CREATE TABLE eSocios.GrupoFamiliar (
	id_socio varchar(20),	--Nuevo
    id_tutor varchar(20),  --Nuevo
    descuento decimal(10,2),
	parentesco varchar(20) NOT NULL, --Nuevo
	constraint PKGruFam PRIMARY KEY (id_socio,id_tutor),
	constraint FKGruSoc FOREIGN KEY (id_socio) references eSocios.Socio (id_socio),
	constraint FKGruFam FOREIGN KEY (id_tutor) references eSocios.Tutor (id_tutor)
);
END
GO


--CREACION DE TABLA ACTIVIDAD
IF OBJECT_ID(N'eSocios.Actividad', N'U') IS NULL
BEGIN
	CREATE TABLE eSocios.Actividad (
	id_actividad int identity (1,1) PRIMARY KEY NOT NULL,
	nombre nvarchar(50) NOT NULL,
	costo_mensual decimal(10,2) NOT NULL,
	vigencia date NOT NULL --Nuevo
);
END
GO


IF OBJECT_ID(N'eSocios.Presentismo', N'U') IS NULL
BEGIN
CREATE TABLE eSocios.Presentismo ( --Nuevo
	id_presentismo int IDENTITY (1,1) PRIMARY KEY,
	id_socio varchar(20),
	id_actividad int,
	fecha_asistencia date,
	asistencia varchar(5),
	profesor varchar(20)
	CONSTRAINT FKActPre FOREIGN KEY (id_actividad) references eSocios.Actividad (id_actividad),
	CONSTRAINT FKSocPre FOREIGN KEY (id_socio) references eSocios.Socio (id_socio)
);
END
GO


--CREACION DE TABLA REALIZA
IF OBJECT_ID(N'eSocios.Realiza', N'U') IS NULL
BEGIN
	CREATE TABLE eSocios.Realiza (
	socio varchar(20) NOT NULL,
	id_actividad int NOT NULL,
	constraint PKRea PRIMARY KEY (socio, id_actividad),
	constraint FKRea FOREIGN KEY (socio) references eSocios.Socio (id_socio),
	constraint FK2Rea FOREIGN KEY (id_actividad) references eSocios.Actividad (id_actividad)
);
END
GO


--CREACION DE TABLA ACTIVIDAD DIA HORARIO
IF OBJECT_ID(N'eSocios.ActividadDiaHorario', N'U') IS NULL
BEGIN
	CREATE TABLE eSocios.ActividadDiaHorario ( 
    id_actividad int NOT NULL,
    dia varchar(20) NOT NULL CHECK (dia IN ('lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo')),
    hora_inicio time NOT NULL CHECK (hora_inicio BETWEEN '00:00:00' AND '23:59:59.9999999'),
    hora_fin time NOT NULL CHECK (hora_fin BETWEEN '00:00:00' AND '23:59:59.9999999'),
    CONSTRAINT PKActDiaHor PRIMARY KEY (id_actividad, dia, hora_inicio),
    CONSTRAINT FKActDiaHor FOREIGN KEY (id_actividad) REFERENCES eSocios.Actividad(id_actividad),
    CONSTRAINT CHK_HorarioValido CHECK (hora_inicio < hora_fin)
);
END
GO


IF OBJECT_ID(N'eCobros.Factura', N'U') IS NULL
BEGIN
CREATE TABLE eCobros.Factura (
    id_factura int identity (1,1) PRIMARY KEY,
    id_socio varchar(20) NOT NULL FOREIGN KEY references eSocios.Socio(id_socio),
    fecha_emision date,
    fecha_venc_1 date,
    fecha_venc_2 date,
    estado varchar(20) NOT NULL CHECK (estado IN ('pendiente', 'pagada', 'anulada')),
    total decimal(10, 2) NOT NULL CHECK (total >= 0),
    recargo_venc tinyint CHECK (recargo_venc BETWEEN 0 AND 100),
    descuentos tinyint CHECK (descuentos BETWEEN 0 AND 100)
);
END
GO


--CREACION DE TABLA ITEM FACTURA
IF OBJECT_ID(N'eCobros.ItemFactura', N'U') IS NULL
BEGIN
CREATE TABLE eCobros.ItemFactura --Nuevo
(
    id_item int IDENTITY(1,1) PRIMARY KEY,
	id_factura int FOREIGN KEY references eCobros.Factura (id_factura),
    concepto varchar(100) NOT NULL,
    monto decimal(10, 2) NOT NULL,
    periodo varchar(20) NOT NULL,
);
END
GO


--CREACION DE TABLA ENTRADA PILETA
IF OBJECT_ID(N'eCobros.PreciosAcceso', N'U') IS NULL
BEGIN
CREATE TABLE eCobros.PreciosAcceso ( --Nuevo
    id_precio int IDENTITY(1,1) PRIMARY KEY,
    categoria varchar(30) NOT NULL CHECK (categoria IN ('Adultos', 'Menores de 12 años')),           
    tipo_usuario varchar(20) NOT NULL CHECK (tipo_usuario IN ('Socios', 'Invitados')),       
    modalidad varchar(30) NOT NULL CHECK (modalidad IN ('Valor del dia', 'Valor de temporada', 'Valor del Mes')),         
    precio decimal(10,2) NOT NULL,
    vigencia_hasta date NOT NULL,
    fecha_creacion datetime DEFAULT GETDATE(),
    activo bit DEFAULT 1,   
);
END
GO


--CREACION DE TABLA PAGO
IF OBJECT_ID(N'eCobros.Pago', N'U') IS NULL
BEGIN
	CREATE TABLE eCobros.Pago (
    id_pago bigint PRIMARY KEY,
    id_factura int /*NOT NULL*/ FOREIGN KEY references eCobros.Factura(id_factura),
    medio_pago varchar(50) NOT NULL CHECK (medio_pago IN ('visa', 'masterCard', 'tarjeta naranja', 'pago facil', 'rapipago', 'mercado pago','efectivo')),
    monto decimal(10, 2) NOT NULL CHECK (monto >= 0),
    fecha date NOT NULL,
    estado varchar(20) NOT NULL CHECK (estado IN ('completado', 'reembolsado', 'anulado')),
    debito_auto bit NOT NULL
);
END
GO


--CREACION DE TABLA REEMBOLSO
IF OBJECT_ID(N'eCobros.Reembolso', N'U') IS NULL
BEGIN
	CREATE TABLE eCobros.Reembolso (
    id_reembolso int PRIMARY KEY,
    id_pago int NOT NULL FOREIGN KEY references eCobros.Pago(id_pago),
    monto decimal(10, 2)  NOT NULL CHECK (monto >= 0),
    motivo varchar(100) NOT NULL,
    fecha date NOT NULL
);
END
GO


IF OBJECT_ID(N'eSocios.ubicaciones', N'U') IS NULL
BEGIN
CREATE TABLE eSocios.ubicaciones (
    id INT IDENTITY(1,1) PRIMARY KEY,
    latitud DECIMAL(10,8) NOT NULL,
    longitud DECIMAL(11,8) NOT NULL,
    elevacion DECIMAL(8,2),
    utc_offset_seconds INT,
    timezone VARCHAR(50),
    timezone_abbreviation VARCHAR(10),
    nombre_ubicacion VARCHAR(100),
    created_at DATETIME2 DEFAULT GETDATE(),
);
END
GO


IF OBJECT_ID(N'eSocios.datos_meteorologicos', N'U') IS NULL
BEGIN
CREATE TABLE eSocios.datos_meteorologicos (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ubicacion_id INT NOT NULL,
    fecha_hora DATETIME2 NOT NULL,
    temperatura_2m DECIMAL(5,2),
    lluvia_mm DECIMAL(6,2),
    humedad_relativa_pct INT,
    velocidad_viento_100m_kmh DECIMAL(6,2),
    created_at DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT FKUbi FOREIGN KEY (ubicacion_id) REFERENCES eSocios.ubicaciones(id)
);
END
GO


--CREACION DE TABLA USUARIO ADMINISTRATIVO
IF OBJECT_ID(N'eAdministrativos.UsuarioAdministrativo', N'U') IS NULL
BEGIN
	CREATE TABLE eAdministrativos.UsuarioAdministrativo (
	id_usuario int identity(1,1) PRIMARY KEY,
	rol varchar (50),
	nombre_usuario nvarchar(50),
	clave varbinary(32),
	fecha_vigencia_clave date,
	ultimo_cambio_clave date
);
END
GO
