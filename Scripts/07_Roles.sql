/*
Entrega 7 - Roles y permisos.
Fecha de entrega: 27/06/2025
Nro. Comision: 5600
Grupo: 10
Materia: Bases de datos aplicada
Integrantes:
- Moggi Rocio , DNI: 45576066
- Amarilla Santiago, DNI: 45481129 
- Martinez Galo, DNI: 43094675
- Fleita Thiago , DNI: 45233264
*/

--Creacion de roles
use Com5600G10
go

--Creacion de roles
CREATE ROLE JefeTesoreria;
CREATE ROLE AdministrativoCobranza;
CREATE ROLE AdministrativoMorosidad;
CREATE ROLE AdministrativoFacturacion;
CREATE ROLE AdministrativoSocio;
CREATE ROLE SociosWeb;
CREATE ROLE Presidente;
CREATE ROLE Vicepresidente;
CREATE ROLE Secretario;
CREATE ROLE Vocales;

-- ====================================================================
-- ASIGNACIÓN DE PERMISOS A CADA ROL
-- Se otorgan permisos SELECT a las tablas y EXECUTE a los Stored Procedures.	
-- La única excepción para DML directo (INSERT) en tablas es eSocios.Categoria.
-- ====================================================================


-- ====================================================================
--ROL: JefeTesoreria
--Propósito: Acceso de consulta amplio sobre datos financieros y reportes
-- ====================================================================
GRANT SELECT ON SCHEMA::eCobros TO JefeTesoreria;
GRANT SELECT ON SCHEMA::eSocios TO JefeTesoreria;
GRANT SELECT ON SCHEMA::eAdministrativos TO JefeTesoreria;
--CUANDO SE REALICEN LOS REPORTES
--GRANT SELECT ON SCHEMA::eReportes TO JefeTesoreria;
GO

/*CUANDO SE HAGAN LOS SP DE REPORTES, EL JEFE DE TESORERIA SERÍA EL ENCARGADO DE TRABAJAR CON ESE SP. 
--GRANT EXECUTE ON OBJECT::eReportes.ReporteSociosMorosos TO JefeTesoreria;
O sino mejor:
--GRANTEXECUTE ON SCHEMA::eReportes TO JefeTesoreria;
*/

-- ====================================================================
--ROL: AdministrativoCobranza
--Área: Tesorería
--Propósito: Manejo de pagos, facturas, reembolsos y entradas  de pileta
-- ====================================================================

--Permisos de lectura en tablas
GRANT SELECT ON eCobros.Factura TO AdministrativoCobranza;
GRANT SELECT ON eCobros.ItemFactura TO AdministrativoCobranza;
GRANT SELECT ON eCobros.Pago TO AdministrativoCobranza;
GRANT SELECT ON eCobros.Reembolso TO AdministrativoCobranza;
GRANT SELECT ON eCobros.EntradaPileta TO AdministrativoCobranza;
GRANT SELECT ON eSocios.Socio TO AdministrativoCobranza; -- Necesita ver datos del socio
GRANT SELECT ON eSocios.Categoria TO AdministrativoCobranza; -- Puede necesitar ver categorías para contexto
GRANT SELECT ON eSocios.Actividad TO AdministrativoCobranza; -- Puede necesitar ver actividades para contexto

--Permisos para ejecución sobre SPs 
GRANT EXECUTE ON OBJECT::eCobros.CargarPago TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eCobros.AnularPago TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eCobros.RegistrarEntradaPileta TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eCobros.AnularEntradaPileta TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eCobros.BorradoLogicoReembolso TO AdministrativoCobranza;
GO

-- ====================================================================
--ROL:AdministrativoMorosidad
--Área Tesorería
--Propósito: Consulta de estados de adeudados, aplicación de recargos.
-- ====================================================================

--Permisos de lectura en tablas
GRANT SELECT ON eCobros.Factura TO AdministrativoMorosidad;
GRANT SELECT ON eCobros.ItemFactura TO AdministrativoMorosidad;
GRANT SELECT ON eCobros.Pago TO AdministrativoMorosidad;
GRANT SELECT ON eSocios.Socio TO AdministrativoMorosidad; -- Necesita ver info de socios

-- Permisos de ejecución sobre SPs
GRANT EXECUTE ON OBJECT::eCobros.AplicarRecargoSegundoVencimiento TO AdministrativoMorosidad;
-- Si hubieran SPs para notificaciones de morosidad o bloqueo de acceso, irían aquí.
--Implementar este SP, podria hacerse poniendo el estado de socio en 0 (inactivo)
-- GRANT EXECUTE ON OBJECT::eSocios.BloquearAccesoPorMorosidad TO AdministrativoMorosidad;
GO

-- ====================================================================
--ROL:AdministrativoFacturacion
--Área Tesorería
--Propósito: Generación y anulación de facturas, gestión de ítems de factura.
-- ====================================================================

-- Permisos de lectura en tablas
GRANT SELECT ON eCobros.Factura TO AdministrativoFacturacion;
GRANT SELECT ON eCobros.ItemFactura TO AdministrativoFacturacion;
GRANT SELECT ON eSocios.Socio TO AdministrativoFacturacion; -- Necesita ver datos de socios para facturar
GRANT SELECT ON eSocios.Categoria TO AdministrativoFacturacion; -- Para obtener costos de membresía
GRANT SELECT ON eSocios.Realiza TO AdministrativoFacturacion; -- Para obtener actividades del socio
GRANT SELECT ON eSocios.Actividad TO AdministrativoFacturacion; -- Para obtener costos de actividades

-- Permisos de ejecución sobre SPs
GRANT EXECUTE ON OBJECT::eCobros.GenerarFactura TO AdministrativoFacturacion;
GRANT EXECUTE ON OBJECT::eCobros.AnularFactura TO AdministrativoFacturacion;
GO


-- ====================================================================
--ROL:AdministrativoSocio
--Área: Socios
--Propósito: Gestión completa de socios (alta, baja, modificación),
--grupos familiares, tutores, actividades y categorías.
-- ====================================================================

-- Permisos de lectura en tablas (si necesitan consultas directas fuera de SPs)
GRANT SELECT ON SCHEMA::eSocios TO AdministrativoSocio;

--Permisos DML directos para la tabla eSocios.Categoria
GRANT INSERT, UPDATE, DELETE ON eSocios.Categoria TO AdministrativoSocio;

-- Permisos de ejecución sobre TODOS los SPs del esquema eSocios
GRANT EXECUTE ON OBJECT::eSocios.insertarSocio TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.EliminarSocio TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.ModificarSocio TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.ReInsertarSocio TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.ModificarTutor TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.EliminarTutor TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.CrearGrupoFamiliar TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.AgregarMiembroAGrupoFamiliar TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.CrearActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.ModificarActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.EliminarActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.AsignarActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.DesinscribirActividad TO AdministrativoSocio;
--si hay SP de insertarCategoria, va acá
--GRANT EXECUTE ON OBJECT::eSocios.ModificarCategoria TO AdministrativoSocio; --AGREGAR
--GRANT EXECUTE ON OBJECT::eSocios.EliminarCategoria TO AdministrativoSocio; --AGREGAR
GO


-- ====================================================================
--ROL:SociosWeb
--Área: Socios (App)
--Propósito: Acceso restringido a sus propios datos a través de la aplicación web.
-- ====================================================================

-- NOTA IMPORTANTE: La restricción a "sus propios datos" DEBE ser manejada
-- LÓGICAMENTE dentro de los Stored Procedures o Vistas que este rol ejecute.
-- A nivel de GRANT, solo podemos dar permiso sobre el objeto completo.
-- Permisos de lectura en tablas (solo para consulta de sus propios datos, la App filtrará)
GRANT SELECT ON eSocios.Socio TO SociosWeb;
GRANT SELECT ON eSocios.GrupoFamiliar TO SociosWeb;
GRANT SELECT ON eCobros.Factura TO SociosWeb;
GRANT SELECT ON eCobros.ItemFactura TO SociosWeb;
GRANT SELECT ON eCobros.Pago TO SociosWeb;
GRANT SELECT ON eCobros.EntradaPileta TO SociosWeb;
GRANT SELECT ON eSocios.Actividad TO SociosWeb;
GRANT SELECT ON eSocios.Categoria TO SociosWeb;

-- Permisos de ejecución sobre SPs específicos para el socio web.
-- EJEMPLO: Si tienes un SP llamado eSocios.ConsultarDatosSocio(@id_socio),
-- este SP debería internamente usar el ID del socio logueado para filtrar.
-- GRANT EXECUTE ON OBJECT::eSocios.ConsultarMisCuotas TO SociosWeb;
-- GRANT EXECUTE ON OBJECT::eSocios.AgregarFamiliarWeb TO SociosWeb; -- Si hay un SP para esto con validación interna
GO

-- ====================================================================
--ROL:Presidente
--Área: Autoridades
--Propósito: Consulta amplia de todos los datos para supervisión y toma de decisiones. NO DML.
-- ====================================================================

GRANT SELECT ON SCHEMA::eSocios TO Presidente;
GRANT SELECT ON SCHEMA::eCobros TO Presidente;
GRANT SELECT ON SCHEMA::eAdministrativos TO Presidente;
GO

-- ====================================================================
--ROL:VicePresidente
--Área: Autoridades
--Propósito: Consulta amplia de todos los datos para supervisión y toma de decisiones. NO DML.
-- ====================================================================

GRANT SELECT ON SCHEMA::eSocios TO Vicepresidente;
GRANT SELECT ON SCHEMA::eCobros TO Vicepresidente;
GRANT SELECT ON eAdministrativos.UsuarioAdministrativo TO Vicepresidente;
GO

-- ====================================================================
--ROL:Secretario
--Área: Autoridades
--Propósito: Consulta de datos administrativos y algunos operativos.
-- ====================================================================
GRANT SELECT ON eSocios.Socio TO Secretario;
GRANT SELECT ON eSocios.Actividad TO Secretario;
GRANT SELECT ON eCobros.Factura TO Secretario;
GRANT SELECT ON eAdministrativos.UsuarioAdministrativo TO Secretario;
GO


-- ====================================================================
--ROL:Vocales
--Área: Autoridades
--Propósito: Acceso de lectura a alto nivel, principalmente para reportes agregados.
-- ====================================================================
GRANT SELECT ON eSocios.Categoria TO Vocales;
GRANT SELECT ON eSocios.Actividad TO Vocales;
GRANT SELECT ON eCobros.Factura TO Vocales; -- Acceso de lectura, pero el uso real sería para reportes agregados.
-- Si hay vistas de resumen, sería ideal dar permisos sobre ellas.
-- GRANT SELECT ON OBJECT::eReportes.VistaResumenSocios TO Vocales;
GO