--CREACION DB
USE master 
GO

DROP DATABASE IF EXISTS Com5600G10
CREATE DATABASE Com5600G10

USE testTP
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
    costo_mensual DECIMAL(10,2) NOT NULL --agregar check >= 0
	);
END
GO

--CREACION DE TABLA SOCIO
IF OBJECT_ID(N'eSocios.Socio', N'U') IS NULL
BEGIN
	CREATE TABLE eSocios.Socio (
    id_socio int identity(1,1) PRIMARY KEY,
    id_grupo_familiar int, 
    id_categoria int NOT NULL,
    dni varchar(8) NOT NULL UNIQUE CHECK (TRY_CAST(dni as INT) > 0), 
    nombre varchar(50) NOT NULL,
    apellido varchar(50) NOT NULL,
    email nvarchar(100) NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
    fecha_nac date NOT NULL,
    telefono varchar(10) CHECK (
    LEN(telefono) = 10 AND telefono NOT LIKE '%[^0-9]%'),
    telefono_emergencia varchar(10) CHECK (
    LEN(telefono_emergencia) = 10 AND telefono_emergencia NOT LIKE '%[^0-9]%'),
    obra_social varchar(50),
    nro_obra_social varchar(15),
	activo BIT DEFAULT 1 CHECK (activo IN (0,1)),
	constraint FKSoc FOREIGN KEY (id_categoria) references eSocios.Categoria (id_categoria)
);
END
GO

--CREACION DE TABLA GRUPO FAMILIAR
IF OBJECT_ID(N'eSocios.GrupoFamiliar', N'U') IS NULL
BEGIN
	CREATE TABLE eSocios.GrupoFamiliar (
    id_grupo int identity(1,1),
    id_adulto_responsable int,  
    descuento decimal(10,2),
	constraint PKGruFam PRIMARY KEY (id_grupo,id_adulto_responsable),
	constraint FKGruFam FOREIGN KEY (id_adulto_responsable) references eSocios.Socio (id_socio)
);
END
GO

--CREACION DE TABLA TUTOR
IF OBJECT_ID(N'eSocios.Tutor', N'U') IS NULL
BEGIN
	CREATE TABLE eSocios.Tutor (
    id_tutor int identity(1,1) PRIMARY KEY,
	id_socio int,
	id_tutor_socio INT,
    nombre varchar(50) NOT NULL,
    apellido varchar (50) NOT NULL,
    email nvarchar(100) NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
    fecha_nac date NOT NULL, 
    telefono varchar(10) NOT NULL CHECK (
    LEN(telefono) = 10 AND telefono NOT LIKE '%[^0-9]%'),
    parentesco varchar(20) NOT NULL,
    constraint FKTut FOREIGN KEY (id_socio) references eSocios.Socio(id_socio),
	constraint FKTut2 FOREIGN KEY (id_tutor_socio) references eSocios.Socio(id_socio)
);
END
GO

--CREACION DE TABLA ACTIVIDAD
IF OBJECT_ID(N'eSocios.Actividad', N'U') IS NULL
BEGIN
	CREATE TABLE eSocios.Actividad (
	id_actividad int identity (1,1) PRIMARY KEY NOT NULL,
	nombre nvarchar(50) NOT NULL,
	costo_mensual decimal(10,2) NOT NULL
);
END
GO

--CREACION DE TABLA REALIZA
IF OBJECT_ID(N'eSocios.Realiza', N'U') IS NULL
BEGIN
	CREATE TABLE eSocios.Realiza (
	socio int NOT NULL,
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

--CREACION TABLA FACTURA
IF OBJECT_ID(N'eCobros.Factura', N'U') IS NULL
BEGIN
	CREATE TABLE eCobros.Factura (
    id_factura int identity (1,1) PRIMARY KEY,
    id_socio int NOT NULL FOREIGN KEY references eSocios.Socio(id_socio),
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
	CREATE TABLE eCobros.ItemFactura (
    id_item int IDENTITY(1,1) PRIMARY KEY,
    id_factura int NOT NULL FOREIGN KEY references eCobros.Factura(id_factura),
    concepto varchar(100) NOT NULL CHECK (concepto IN ('membresia', 'actividad', 'pileta', 'colonia', 'sum', 'recargo por segundo vencimiento','reembolso')), 
    monto decimal(10, 2) NOT NULL CHECK (monto >= 0),
    periodo varchar(20) NOT NULL,
);
END
GO

--CREACION DE TABLA ENTRADA PILETA
IF OBJECT_ID(N'eCobros.EntradaPileta', N'U') IS NULL
BEGIN
	CREATE TABLE eCobros.EntradaPileta (
	id_entrada int identity(1,1) PRIMARY KEY,
	id_socio int NOT NULL,
	id_item_factura int NOT NULL,
	fecha date NOT NULL,
	monto decimal(10,2) NOT NULL CHECK (monto >= 0),
	tipo varchar(8) NOT NULL CHECK (tipo IN ('socio', 'invitado')),
	lluvia bit,
	constraint FKInv FOREIGN KEY (id_socio) references eSocios.Socio(id_socio),
	constraint FKFact FOREIGN KEY (id_item_factura) references eCobros.ItemFactura(id_item)
);
END
GO

--CREACION DE TABLA PAGO
IF OBJECT_ID(N'eCobros.Pago', N'U') IS NULL
BEGIN
	CREATE TABLE eCobros.Pago (
    id_pago int PRIMARY KEY,
    id_factura int NOT NULL FOREIGN KEY references eCobros.Factura(id_factura),
    medio_pago varchar(50) NOT NULL CHECK (medio_pago IN ('visa', 'masterCard', 'tarjeta naranja', 'pago facil', 'rapipago', 'mercado pago')),
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
