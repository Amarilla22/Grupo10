use master
go

CREATE DATABASE Com5600G10

use Com5600G10
go

create schema socios

CREATE TABLE socios.Actividad (
	id_actividad int PRIMARY KEY,
	nombre nvarchar(50),
	descuento decimal(5,2),
	costo_mensual decimal(10,2)
);

CREATE TABLE socios.Realiza (
	socio int,
	id_actividad int,
	constraint PKrealiza PRIMARY KEY (socio, id_actividad),
	constraint FKrealiza FOREIGN KEY (socio) references socios.Socio (id_socio),
	constraint FK2realiza FOREIGN KEY (id_actividad) references socios.Socio (id_actividad)
);

CREATE TABLE socios.Dia (
	id_dia smallint PRIMARY KEY,
	nombre varchar(20)
);

CREATE TABLE socios.Horario (
	id_horario int PRIMARY KEY,
	descripcion varchar(20)
);

CREATE TABLE socios.Actividad_Dia (
    id_actividad int,
    id_dia smallint,
    constraint PKActDia PRIMARY KEY (id_actividad, id_dia),
    FOREIGN KEY FKActD(id_actividad) references socios.Actividad(id_actividad),
    FOREIGN KEY FK2ActD(id_dia) references socios.Dia(id_dia)
);

CREATE TABLE socios.Actividad_Horario (
    id_actividad int,
    id_horario int,
    constraint PKActHor PRIMARY KEY (id_actividad, id_horario),
    FOREIGN KEY FKActH(id_actividad) references socios.Actividad(id_actividad),
    FOREIGN KEY FK2ActH(id_horario) references socios.Horario(id_horario)
);