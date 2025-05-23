<<<<<<< HEAD
--prueba de github
=======
CREATE DATABASE Com5600G10

use Com5600G10
go

create schema eSocios
go
create schema eCobros
go

CREATE TABLE eSocios.Categoria ( 
	id_categoria int PRIMARY KEY,
    nombre varchar(50),
    costo_mensual decimal(10,2),
);

CREATE TABLE eSocios.Socio (
    id_socio int identity(1,1) PRIMARY KEY,
    id_grupo_familiar int, 
    id_categoria int NOT NULL,
    dni varchar(15) NOT NULL UNIQUE CHECK (TRY_CAST(dni as INT) > 0), 
    nombre varchar(50) NOT NULL,
    apellido varchar(50) NOT NULL,
    email nvarchar(100) NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
    fecha_nac date NOT NULL,
    telefono varchar(20),
    telefono_emergencia varchar(20),
    obra_social varchar(50),
    nro_obra_social varchar(15),
    estado varchar(10) NOT NULL CHECK (estado in ('Activo','Inactivo')),
	constraint FKCat FOREIGN KEY (id_categoria) references eSocios.Categoria (id_categoria)
);

CREATE TABLE eSocios.GrupoFamiliar (
    id_grupo int PRIMARY KEY,
    id_adulto_responsable int, 
    descuento decimal(10,2)
);

CREATE TABLE eSocios.Actividad (
	id_actividad int PRIMARY KEY,
	nombre nvarchar(50),
	descuento decimal(5,2),
	costo_mensual decimal(10,2)
);

CREATE TABLE eSocios.Realiza (
	socio int,
	id_actividad int,
	constraint PKrealiza PRIMARY KEY (socio, id_actividad),
	constraint FKrealiza FOREIGN KEY (socio) references eSocios.Socio (id_socio),
	constraint FK2realiza FOREIGN KEY (id_actividad) references eSocios.Actividad (id_actividad)
);

CREATE TABLE eSocios.Dia (
	id_dia smallint PRIMARY KEY,
	nombre varchar(20)
);

CREATE TABLE eSocios.Horario (
	id_horario int PRIMARY KEY,
	descripcion varchar(20)
);

CREATE TABLE eSocios.ActividadDia (
    id_actividad int,
    id_dia smallint,
    constraint PKActDia PRIMARY KEY (id_actividad, id_dia),
    constraint FKActDia FOREIGN KEY (id_actividad) references eSocios.Actividad(id_actividad),
    constraint FK2ActDia FOREIGN KEY (id_dia) references eSocios.Dia(id_dia)
);

CREATE TABLE eSocios.ActividadHorario (
    id_actividad int,
    id_horario int,
    constraint PKActHor PRIMARY KEY (id_actividad, id_horario),
    constraint FKActHor FOREIGN KEY (id_actividad) references eSocios.Actividad(id_actividad),
    constraint FK2ActHor FOREIGN KEY (id_horario) references eSocios.Horario(id_horario)
);

CREATE TABLE eCobros.Factura 
(
    id_factura int PRIMARY KEY,
    id_socio int NOT NULL FOREIGN KEY references eSocios.Socio(id_socio),
    fecha_emision date,
    fecha_venc_1 date,
    fecha_venc_2 date,
    estado varchar(20) NOT NULL CHECK (estado IN ('pendiente', 'pagada', 'anulada')),
    total decimal(10, 2) NOT NULL CHECK (total >= 0),
    recargo_venc tinyint CHECK (recargo_venc BETWEEN 0 AND 100),
    descuentos tinyint CHECK (descuentos BETWEEN 0 AND 100)
);

CREATE TABLE eCobros.Pileta (
    id_Entrada int PRIMARY KEY,
    id_Factura int,
    id_Socio int,
    fecha date,
    monto decimal (10,2),
    lluvia bit,
    tipo nvarchar(15),
    constraint PKPil FOREIGN KEY (id_Factura) references eCobros.Factura(id_Factura),
    constraint PK2Pil FOREIGN KEY (id_Socio) references eSocios.Socio(id_Socio)
);

CREATE TABLE eCobros.ItemFactura 
(
    id_item int IDENTITY(1,1) PRIMARY KEY,
    id_factura int NOT NULL FOREIGN KEY references eCobros.Factura(id_factura),
    concepto varchar(100) NOT NULL CHECK (concepto IN ('Membresía', 'Actividad', 'Pileta', 'Colonia', 'SUM')), 
    monto decimal(10, 2) NOT NULL CHECK (monto >= 0),
    periodo varchar(20) NOT NULL,
);

CREATE TABLE eCobros.Pago (
    id_pago int PRIMARY KEY,
    id_factura int NOT NULL FOREIGN KEY references eCobros.Factura(id_factura),
    medio_pago varchar(50) NOT NULL CHECK (medio_pago IN ('Visa', 'MasterCard', 'Tarjeta Naranja', 'Pago Fácil', 'Rapipago', 'Transferencia Mercado Pago')),
    monto decimal(10, 2) NOT NULL CHECK (monto >= 0),
    fecha date NOT NULL,
    estado varchar(20) NOT NULL CHECK (estado IN ('Completado', 'Reembolsado')),
    debito_auto bit NOT NULL
);

CREATE TABLE eCobros.Reembolso (
    id_reembolso int PRIMARY KEY,
    id_pago int NOT NULL FOREIGN KEY references eCobros.Pago(id_pago),
    monto decimal(10, 2)  NOT NULL CHECK (monto >= 0),
    motivo varchar(100) NOT NULL,
    fecha date NOT NULL
);
>>>>>>> 20b041d7b7804972b57ab0771be191607392908d
