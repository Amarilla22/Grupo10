
/*
Entrega 4 - Creacion de la base de datos y objetos.
Fecha de entrega: 23/05/2025
Nro. Comision: 5600
Grupo: 10
Materia: Bases de datos aplicada
Integrantes:
- Moggi Rocio , DNI: 45576066
- Amarilla Santiago, DNI: 45481129 
- Martinez Galo, DNI: 43094675
- Fleita Thiago , DNI: 45233264
*/

use master
go

CREATE DATABASE Com5600G10

use Com5600G10
go

create schema eSocios
go
create schema eCobros
go
create schema eAdministrativos
go

CREATE TABLE eSocios.Categoria ( 
	id_categoria int identity(1,1) PRIMARY KEY,
    nombre varchar(50) NOT NULL,
    costo_mensual decimal(10,2) NOT NULL
);
GO


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
GO


CREATE TABLE eSocios.GrupoFamiliar (
    id_grupo int,
    id_adulto_responsable int,  
    descuento decimal(10,2),
	constraint PKGruFam PRIMARY KEY (id_grupo,id_adulto_responsable),
	constraint FKGruFam FOREIGN KEY (id_adulto_responsable) references eSocios.Socio (id_socio)
);
GO


CREATE TABLE eSocios.Tutor (
    id_tutor int identity(1,1) PRIMARY KEY,
	id_socio int,
    nombre varchar(50) NOT NULL,
    apellido varchar (50) NOT NULL,
    email nvarchar(100) NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
    fecha_nac date NOT NULL, 
    telefono varchar(10) NOT NULL CHECK (
    LEN(telefono) = 10 AND telefono NOT LIKE '%[^0-9]%'),
    parentesco varchar(20) NOT NULL,
    constraint FKTut FOREIGN KEY (id_socio) references eSocios.Socio(id_socio)
);
GO


CREATE TABLE eSocios.Actividad (
	id_actividad int identity (1,1) PRIMARY KEY NOT NULL,
	nombre nvarchar(50) NOT NULL,
	costo_mensual decimal(10,2) NOT NULL
);
GO


CREATE TABLE eSocios.Realiza (
	socio int NOT NULL,
	id_actividad int NOT NULL,
	constraint PKRea PRIMARY KEY (socio, id_actividad),
	constraint FKRea FOREIGN KEY (socio) references eSocios.Socio (id_socio),
	constraint FK2Rea FOREIGN KEY (id_actividad) references eSocios.Actividad (id_actividad)
);
GO

CREATE TABLE eSocios.ActividadDiaHorario (
    id_actividad int NOT NULL,
    dia varchar(20) NOT NULL CHECK (dia IN ('lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo')),
    hora_inicio time NOT NULL CHECK (hora_inicio BETWEEN '00:00:00' AND '23:59:59.9999999'),
    hora_fin time NOT NULL CHECK (hora_fin BETWEEN '00:00:00' AND '23:59:59.9999999'),
    CONSTRAINT PKActDiaHor PRIMARY KEY (id_actividad, dia, hora_inicio),
    CONSTRAINT FKActDiaHor FOREIGN KEY (id_actividad) REFERENCES eSocios.Actividad(id_actividad),
    CONSTRAINT CHK_HorarioValido CHECK (hora_inicio < hora_fin)
);
GO

CREATE TABLE eCobros.Factura 
(
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
GO


CREATE TABLE eCobros.ItemFactura 
(
    id_item int IDENTITY(1,1) PRIMARY KEY,
    id_factura int NOT NULL FOREIGN KEY references eCobros.Factura(id_factura),
    concepto varchar(100) NOT NULL CHECK (concepto IN ('membresia', 'actividad', 'pileta', 'colonia', 'sum')), 
    monto decimal(10, 2) NOT NULL CHECK (monto >= 0),
    periodo varchar(20) NOT NULL,
);
GO


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
GO


CREATE TABLE eCobros.Pago (
    id_pago int PRIMARY KEY,
    id_factura int NOT NULL FOREIGN KEY references eCobros.Factura(id_factura),
    medio_pago varchar(50) NOT NULL CHECK (medio_pago IN ('visa', 'masterCard', 'tarjeta naranja', 'pago facil', 'rapipago', 'mercado pago')),
    monto decimal(10, 2) NOT NULL CHECK (monto >= 0),
    fecha date NOT NULL,
    estado varchar(20) NOT NULL CHECK (estado IN ('completado', 'reembolsado', 'anulado')),
    debito_auto bit NOT NULL
);
GO


CREATE TABLE eCobros.Reembolso (
    id_reembolso int PRIMARY KEY,
    id_pago int NOT NULL FOREIGN KEY references eCobros.Pago(id_pago),
    monto decimal(10, 2)  NOT NULL CHECK (monto >= 0),
    motivo varchar(100) NOT NULL,
    fecha date NOT NULL
);
GO


CREATE TABLE eAdministrativos.UsuarioAdministrativo (
	id_usuario int identity(1,1) PRIMARY KEY,
	rol varchar (50),
	nombre_usuario nvarchar(50),
	clave nvarchar(50),
	fecha_vigencia_clave date,
	ultimo_cambio_clave date
);
GO


