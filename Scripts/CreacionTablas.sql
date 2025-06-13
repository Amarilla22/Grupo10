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
--borrar
use Aplicada
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

CREATE TABLE eSocios.Socio (
    id_socio int identity(1,1) PRIMARY KEY,
    id_grupo_familiar int, 
    id_categoria int NOT NULL,
    dni varchar(8) NOT NULL UNIQUE CHECK (TRY_CAST(dni as INT) > 0), 
    nombre varchar(50) NOT NULL,
    apellido varchar(50) NOT NULL,
    email nvarchar(100) NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
    fecha_nac date NOT NULL,
    telefono varchar(10) CHECK (LEN(telefono) = 10 AND telefono NOT LIKE '%[^0-9]%'),
    telefono_emergencia varchar(10) CHECK (LEN(telefono_emergencia) = 10 AND telefono_emergencia NOT LIKE '%[^0-9]%'),
    obra_social varchar(50),
    nro_obra_social varchar(15),
	constraint FKSoc FOREIGN KEY (id_categoria) references eSocios.Categoria (id_categoria)--no hace falta
);

CREATE TABLE eSocios.GrupoFamiliar (
    id_grupo int identity(1,1),
    id_adulto_responsable int,  
    descuento decimal(10,2),--ver
	constraint PKGruFam PRIMARY KEY (id_grupo,id_adulto_responsable),
	constraint FKGruFam FOREIGN KEY (id_adulto_responsable) references eSocios.Socio (id_socio)
);

CREATE TABLE eSocios.Tutor (
    id_tutor int PRIMARY KEY,
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

CREATE TABLE eSocios.Actividad (
	id_actividad int identity (1,1) PRIMARY KEY NOT NULL,
	nombre nvarchar(50) NOT NULL,
	costo_mensual decimal(10,2) NOT NULL
);

CREATE TABLE eSocios.Realiza (
	socio int NOT NULL,
	id_actividad int NOT NULL,
	constraint PKRea PRIMARY KEY (socio, id_actividad),
	constraint FKRea FOREIGN KEY (socio) references eSocios.Socio (id_socio),
	constraint FK2Rea FOREIGN KEY (id_actividad) references eSocios.Actividad (id_actividad)
);

CREATE TABLE eSocios.Dia (
	id_dia smallint PRIMARY KEY,
	nombre varchar(10) NOT NULL CHECK (nombre IN ('lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'))
);

CREATE TABLE eSocios.Horario (
	id_horario int PRIMARY KEY,
	hora  TIME(0) NOT NULL

);

CREATE TABLE eSocios.ActividadHorarioDia (
    id_actividad INT NOT NULL,
    id_dia SMALLINT NOT NULL,
    id_horario INT NOT NULL,
    CONSTRAINT PK_ActividadHorarioDia PRIMARY KEY (id_actividad, id_dia, id_horario),
    CONSTRAINT FK_ActividadHorarioDia_Actividad FOREIGN KEY (id_actividad) REFERENCES eSocios.Actividad(id_actividad),
    CONSTRAINT FK_ActividadHorarioDia_Dia FOREIGN KEY (id_dia) REFERENCES eSocios.Dia(id_dia),
    CONSTRAINT FK_ActividadHorarioDia_Horario FOREIGN KEY (id_horario) REFERENCES eSocios.Horario(id_horario)
);

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

--datos del invitado del socio a la pileta
CREATE TABLE eSocios.Invitado (
	id_invitado int identity(1,1) PRIMARY KEY,
	id_socio int NOT NULL,
	nombre varchar(50) NOT NULL,
	apellido varchar(50) NOT NULL,
	dni varchar(8) NOT NULL UNIQUE CHECK (TRY_CAST(dni as INT) > 0),
	constraint FKInv FOREIGN KEY (id_socio) references eSocios.Socio(id_socio)
)

CREATE TABLE eCobros.PiletaInvitado (
	id_entrada int identity(1,1) PRIMARY KEY,
	id_invitado int NOT NULL,
	id_factura int NOT NULL,
	fecha date NOT NULL,
	monto decimal(10,2) NOT NULL CHECK (monto >= 0),
	lluvia bit,
	constraint FKInv FOREIGN KEY (id_invitado) references eSocios.Invitado(id_invitado),
	constraint FKFact FOREIGN KEY (id_factura) references eCobros.Factura (id_factura)
)

CREATE TABLE eCobros.ItemFactura 
(
    id_item int IDENTITY(1,1) PRIMARY KEY,
    id_factura int NOT NULL FOREIGN KEY references eCobros.Factura(id_factura),
    concepto varchar(100) NOT NULL CHECK (concepto IN ('membresia', 'actividad', 'pileta', 'colonia', 'sum')), 
    monto decimal(10, 2) NOT NULL CHECK (monto >= 0),
    periodo varchar(20) NOT NULL,
);

CREATE TABLE eCobros.Pago (
    id_pago int PRIMARY KEY,
    id_factura int NOT NULL FOREIGN KEY references eCobros.Factura(id_factura),
    medio_pago varchar(50) NOT NULL CHECK (medio_pago IN ('visa', 'masterCard', 'tarjeta naranja', 'pago facil', 'rapipago', 'mercado pago')),
    monto decimal(10, 2) NOT NULL CHECK (monto >= 0),
    fecha date NOT NULL,
    estado varchar(20) NOT NULL CHECK (estado IN ('completado', 'reembolsado')),
    debito_auto bit NOT NULL
);

CREATE TABLE eCobros.Reembolso (
    id_reembolso int PRIMARY KEY,
    id_pago int NOT NULL FOREIGN KEY references eCobros.Pago(id_pago),
    monto decimal(10, 2)  NOT NULL CHECK (monto >= 0),
    motivo varchar(100) NOT NULL,
    fecha date NOT NULL
);

CREATE TABLE eAdministrativos.UsuarioAdministrativo (
	id_usuario int identity(1,1) PRIMARY KEY,
	rol varchar (50),
	nombre_usuario nvarchar(50),
	clave nvarchar(50),
	fecha_vigencia_clave date,
	ultimo_cambio_clave date
);
