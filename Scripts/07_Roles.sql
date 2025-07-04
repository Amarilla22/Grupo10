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
USE Com5600G10
GO

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
-- ASIGNACI�N DE PERMISOS A CADA ROL
-- Se otorgan permisos SELECT a las tablas y EXECUTE a los Stored Procedures.	
-- La �nica excepci�n para DML directo (INSERT) en tablas es eSocios.Categoria.
-- ====================================================================


-- ====================================================================
--ROL: JefeTesoreria
--Prop�sito: Acceso de consulta amplio sobre datos financieros y reportes
-- ====================================================================
GRANT SELECT ON SCHEMA::eCobros TO JefeTesoreria;
GRANT SELECT ON SCHEMA::eSocios TO JefeTesoreria;
GRANT SELECT ON SCHEMA::eAdministrativos TO JefeTesoreria;
GRANT SELECT ON SCHEMA::eReportes TO JefeTesoreria;

--Permisos para ejecuci�n sobre SPs
GRANT EXECUTE ON SCHEMA::eReportes TO JefeTesoreria;
GO


-- ====================================================================
--ROL: AdministrativoCobranza
--�rea: Tesorer�a
--Prop�sito: Manejo de pagos, facturas, reembolsos y entradas  de pileta
-- ====================================================================

--Permisos de lectura en tablas
GRANT SELECT ON eCobros.Factura TO AdministrativoCobranza;
GRANT SELECT ON eCobros.ItemFactura TO AdministrativoCobranza;
GRANT SELECT ON eCobros.Pago TO AdministrativoCobranza;
GRANT SELECT ON eCobros.Reembolso TO AdministrativoCobranza;
GRANT SELECT ON eCobros.PreciosAcceso TO AdministrativoCobranza;
GRANT SELECT ON eSocios.Socio TO AdministrativoCobranza; -- Necesita ver datos del socio
GRANT SELECT ON eSocios.Categoria TO AdministrativoCobranza; -- Puede necesitar ver categor�as para contexto
GRANT SELECT ON eSocios.Actividad TO AdministrativoCobranza; -- Puede necesitar ver actividades para contexto

--Permisos para ejecuci�n sobre SPs 
GRANT EXECUTE ON OBJECT::eCobros.cargarPago TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eCobros.anularPago TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eCobros.registrarEntradaPileta TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eCobros.generarReembolso TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eCobros.eliminarReembolso TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eCobros.reembolsoComoPagoACuenta TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eImportacion.ImportarTarifasCategorias TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eImportacion.ImportarTarifasPrecioPileta TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eImportacion.ImportarResponsablesDePago TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eImportacion.ImportarPagoCuotas TO AdministrativoCobranza;
GRANT EXECUTE ON OBJECT::eImportacion.ImportarDatosClima TO AdministrativoSocio;
GO

-- ====================================================================
--ROL:AdministrativoMorosidad
--�rea Tesorer�a
--Prop�sito: Consulta de estados de adeudados, aplicaci�n de recargos.
-- ====================================================================

--Permisos de lectura en tablas
GRANT SELECT ON eCobros.Factura TO AdministrativoMorosidad;
GRANT SELECT ON eCobros.ItemFactura TO AdministrativoMorosidad;
GRANT SELECT ON eCobros.Pago TO AdministrativoMorosidad;
GRANT SELECT ON eSocios.Socio TO AdministrativoMorosidad; -- Necesita ver info de socios

-- Permisos de ejecuci�n sobre SPs
 GRANT EXECUTE ON OBJECT::eCobros.verificarVencimiento TO AdministrativoMorosidad;
GO

-- ====================================================================
--ROL:AdministrativoFacturacion
--�rea Tesorer�a
--Prop�sito: Generaci�n y anulaci�n de facturas, gesti�n de �tems de factura.
-- ====================================================================

-- Permisos de lectura en tablas
GRANT SELECT ON eCobros.Factura TO AdministrativoFacturacion;
GRANT SELECT ON eCobros.ItemFactura TO AdministrativoFacturacion;
GRANT SELECT ON eSocios.Socio TO AdministrativoFacturacion; -- Necesita ver datos de socios para facturar
GRANT SELECT ON eSocios.Categoria TO AdministrativoFacturacion; -- Para obtener costos de membres�a
GRANT SELECT ON eSocios.Realiza TO AdministrativoFacturacion; -- Para obtener actividades del socio
GRANT SELECT ON eSocios.Actividad TO AdministrativoFacturacion; -- Para obtener costos de actividades

-- Permisos de ejecuci�n sobre SPs
GRANT EXECUTE ON OBJECT::eCobros.generarFactura TO AdministrativoFacturacion;
GRANT EXECUTE ON OBJECT::eCobros.anularFactura TO AdministrativoFacturacion;
GRANT EXECUTE ON OBJECT::eCobros.eliminarItemFactura TO AdministrativoFacturacion;
GO


-- ====================================================================
--ROL:AdministrativoSocio
--�rea: Socios
--Prop�sito: Gesti�n completa de socios (alta, baja, modificaci�n),
--grupos familiares, tutores, actividades y categor�as.
-- ====================================================================

-- Permisos de lectura en tablas (si necesitan consultas directas fuera de SPs)
GRANT SELECT ON SCHEMA::eSocios TO AdministrativoSocio;

--Permisos DML directos para la tabla eSocios.Categoria
GRANT INSERT ON OBJECT::eSocios.Categoria TO AdministrativoSocio;

-- Permisos de ejecuci�n sobre TODOS los SPs del esquema eSocios
GRANT EXECUTE ON OBJECT::eSocios.insertarSocio TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.eliminarSocio TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.modificarSocio TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.agregarTutor TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.modificarTutor TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.eliminarTutor TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.agregarAGrupoFamiliar TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.sacarDeGrupoFamiliar TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.crearActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.modificarActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.eliminarActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.agregarCategoria TO AdministrativoSocio; 
GRANT EXECUTE ON OBJECT::eSocios.modificarCategoria TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.eliminarCategoria TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.agregarHorarioActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.eliminarHorarioActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.inscribirActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.desinscribirActividad TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eSocios.registrarPresentismo TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eImportacion.ImportarGrupoFamiliar TO AdministrativoSocio;
GRANT EXECUTE ON OBJECT::eImportacion.ImportarPresentismo TO AdministrativoSocio;
GO


-- ====================================================================
--ROL:SociosWeb
--�rea: Socios (App)
--Prop�sito: Acceso restringido a sus propios datos a trav�s de la aplicaci�n web.
-- ====================================================================

-- NOTA IMPORTANTE: La restricci�n a "sus propios datos" DEBE ser manejada
-- L�GICAMENTE dentro de los Stored Procedures o Vistas que este rol ejecute.
-- A nivel de GRANT, solo podemos dar permiso sobre el objeto completo.
-- Permisos de lectura en tablas (solo para consulta de sus propios datos, la App filtrar?)
GRANT SELECT ON eSocios.Socio TO SociosWeb;
GRANT SELECT ON eSocios.GrupoFamiliar TO SociosWeb;
GRANT SELECT ON eCobros.Factura TO SociosWeb;
GRANT SELECT ON eCobros.ItemFactura TO SociosWeb;
GRANT SELECT ON eCobros.Pago TO SociosWeb;
GRANT SELECT ON eCobros.PreciosAcceso TO SociosWeb;
GRANT SELECT ON eSocios.Actividad TO SociosWeb;
GRANT SELECT ON eSocios.Categoria TO SociosWeb;

-- Permisos de ejecuci�n sobre SPs espec�ficos para el socio web.
-- EJEMPLO: Si tienes un SP llamado eSocios.ConsultarDatosSocio(@id_socio),
-- este SP deber�a internamente usar el ID del socio logueado para filtrar.
-- GRANT EXECUTE ON OBJECT::eSocios.ConsultarMisCuotas TO SociosWeb;
-- GRANT EXECUTE ON OBJECT::eSocios.AgregarFamiliarWeb TO SociosWeb; -- Si hay un SP para esto con validaci?n interna
GO

-- ====================================================================
--ROL:Presidente
--�rea: Autoridades
--Prop�sito: Consulta amplia de todos los datos para supervisi�n y toma de decisiones. NO DML.
-- ====================================================================

GRANT SELECT ON SCHEMA::eSocios TO Presidente;
GRANT SELECT ON SCHEMA::eCobros TO Presidente;
GRANT SELECT ON SCHEMA::eAdministrativos TO Presidente;
GO

-- ====================================================================
--ROL:VicePresidente
--�rea: Autoridades
--Prop�sito: Consulta amplia de todos los datos para supervisi�n y toma de decisiones. NO DML.
-- ====================================================================

GRANT SELECT ON SCHEMA::eSocios TO Vicepresidente;
GRANT SELECT ON SCHEMA::eCobros TO Vicepresidente;
GRANT SELECT ON eAdministrativos.UsuarioAdministrativo TO Vicepresidente;
GO

-- ====================================================================
--ROL:Secretario
--�rea: Autoridades
--Prop�sito: Consulta de datos administrativos y algunos operativos.
-- ====================================================================
GRANT SELECT ON eSocios.Socio TO Secretario;
GRANT SELECT ON eSocios.Actividad TO Secretario;
GRANT SELECT ON eCobros.Factura TO Secretario;
GRANT SELECT ON eAdministrativos.UsuarioAdministrativo TO Secretario;
GO


-- ====================================================================
--ROL:Vocales
--�rea: Autoridades
--Prop�sito: Acceso de lectura a alto nivel, principalmente para reportes agregados.
-- ====================================================================
GRANT SELECT ON eSocios.Categoria TO Vocales;
GRANT SELECT ON eSocios.Actividad TO Vocales;
GRANT SELECT ON eCobros.Factura TO Vocales; -- Acceso de lectura, pero el uso real ser�a para reportes agregados.
-- Si hay vistas de resumen, ser�a ideal dar permisos sobre ellas.
-- GRANT SELECT ON OBJECT::eReportes.VistaResumenSocios TO Vocales;
GO