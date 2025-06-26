-- ===================================================================
-- CASOS DE PRUEBA PARA NUEVOS STORED PROCEDURES
-- ===================================================================

USE Com5600G10
GO

-- ===================================================================
-- 1. CREAR GRUPO FAMILIAR - eSocios.CrearGrupoFamiliar
-- ===================================================================

PRINT '=== CREANDO GRUPOS FAMILIARES ===';

-- Primero necesitamos socios mayores para ser adultos responsables


-- Insertar adultos responsables (mayores de edad)
EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '30123456',
    @nombre = 'Roberto',
    @apellido = 'Martinez',
    @email = 'roberto.martinez@email.com',
    @fecha_nac = '1985-05-15',
    @telefono = '1122334455',
    @telefono_emergencia = '9988776655',
    @obra_social = 'OSDE',
    @nro_obra_social = 'OS30123';



EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '31234567',
    @nombre = 'Laura',
    @apellido = 'Fernandez',
    @email = 'laura.fernandez@email.com',
    @fecha_nac = '1990-11-20',
    @telefono = '1133445566',
    @telefono_emergencia = '8877665544',
    @obra_social = 'Swiss Medical',
    @nro_obra_social = 'SM31234';



EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '32345678',
    @nombre = 'Miguel',
    @apellido = 'Lopez',
    @email = 'miguel.lopez@email.com',
    @fecha_nac = '1988-03-10',
    @telefono = '1144556677',
    @telefono_emergencia = '7766554433',
    @obra_social = 'Galeno',
    @nro_obra_social = 'GA32345';

DECLARE @id_adulto1 INT
SELECT @id_adulto1 = id_socio FROM eSocios.Socio WHERE dni = '30123456';


-- Casos exitosos: Crear grupos familiares
PRINT '--- Casos exitosos CrearGrupoFamiliar ---';

EXEC eSocios.CrearGrupoFamiliar @id_adulto_responsable = @id_adulto1;
PRINT 'Grupo familiar creado para Roberto Martinez';

DECLARE @id_adulto2 INT;
SELECT @id_adulto2 = id_socio FROM eSocios.Socio WHERE dni = '31234567';


EXEC eSocios.CrearGrupoFamiliar @id_adulto_responsable = @id_adulto2;
PRINT 'Grupo familiar creado para Laura Fernandez';

PRINT '--- Casos de error en CrearGrupoFamiliar ---';

DECLARE @id_adulto3 INT;
SELECT @id_adulto3 = id_socio FROM eSocios.Socio WHERE dni = '32345678';

-- Error: Adulto responsable inexistente
BEGIN TRY
    EXEC eSocios.CrearGrupoFamiliar @id_adulto_responsable = 9999;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Adulto inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Adulto no es mayor de edad (usar un socio menor)
DECLARE @id_menor INT;
SELECT @id_menor = id_socio FROM eSocios.Socio WHERE dni = '12345678'; -- Juan (menor)

BEGIN TRY
    EXEC eSocios.CrearGrupoFamiliar @id_adulto_responsable = @id_menor;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - No es mayor de edad: ' + ERROR_MESSAGE();
END CATCH

-- Error: Adulto ya tiene grupo familiar
BEGIN TRY
    EXEC eSocios.CrearGrupoFamiliar @id_adulto_responsable = @id_adulto1;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Ya tiene grupo familiar: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 2. AGREGAR MIEMBRO A GRUPO FAMILIAR - eSocios.AgregarMiembroAGrupoFamiliar
-- ===================================================================

PRINT '';
PRINT '=== AGREGANDO MIEMBROS A GRUPOS FAMILIARES ===';

-- Obtener IDs de grupos creados
DECLARE @id_grupo1 INT, @id_grupo2 INT;
SELECT @id_grupo1 = id_grupo FROM eSocios.GrupoFamiliar WHERE id_adulto_responsable = @id_adulto1;
SELECT @id_grupo2 = id_grupo FROM eSocios.GrupoFamiliar WHERE id_adulto_responsable = @id_adulto2;

-- Crear algunos socios adicionales para agregar a grupos
DECLARE @id_menor_hijo INT, @id_cadete_hija INT;

EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '40123456',
    @nombre = 'Mateo',
    @apellido = 'Martinez',
    @email = 'mateo.martinez@email.com',
    @fecha_nac = '2015-06-10',
    @telefono = '1122334455',
    @telefono_emergencia = '9988776655',
    @obra_social = 'OSDE',
    @nro_obra_social = 'OS40123';

SELECT @id_menor_hijo = id_socio FROM eSocios.Socio WHERE dni = '40123456';

EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '41234567',
    @nombre = 'Sofia',
    @apellido = 'Fernandez',
    @email = 'sofia.fernandez@email.com',
    @fecha_nac = '2010-09-15',
    @telefono = '1133445566',
    @telefono_emergencia = '8877665544',
    @obra_social = 'Swiss Medical',
    @nro_obra_social = 'SM41234';

SELECT @id_cadete_hija = id_socio FROM eSocios.Socio WHERE dni = '41234567';

-- Casos exitosos: Agregar miembros
PRINT '--- Casos exitosos AgregarMiembroAGrupoFamiliar ---';

EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo1, @id_socio = @id_menor_hijo;
PRINT 'Mateo agregado al grupo familiar de Roberto';

EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo2, @id_socio = @id_cadete_hija;
PRINT 'Sofia agregada al grupo familiar de Laura';

-- Agregar un socio existente sin grupo al grupo 1
DECLARE @id_socio_sin_grupo INT;
SELECT @id_socio_sin_grupo = id_socio FROM eSocios.Socio WHERE dni = '32345678'; -- Miguel

EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo1, @id_socio = @id_socio_sin_grupo;
PRINT 'Miguel agregado al grupo familiar de Roberto';

PRINT '--- Casos de error en AgregarMiembroAGrupoFamiliar ---';

-- Error: Grupo inexistente
BEGIN TRY
    EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = 9999, @id_socio = @id_menor_hijo;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Grupo inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Socio inexistente
BEGIN TRY
    EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo1, @id_socio = 9999;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Socio es el adulto responsable
BEGIN TRY
    EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo1, @id_socio = @id_adulto1;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Es adulto responsable: ' + ERROR_MESSAGE();
END CATCH

-- Error: Socio ya pertenece a otro grupo
BEGIN TRY
    EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo2, @id_socio = @id_menor_hijo;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Ya pertenece a otro grupo: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 3. ASIGNAR TUTOR - eSocios.AsignarTutor
-- ===================================================================

PRINT '';
PRINT '=== ASIGNANDO TUTORES ===';

-- Casos exitosos: Asignar tutores
PRINT '--- Casos exitosos AsignarTutor ---';

DECLARE @id_tutor1 INT, @id_tutor2 INT;

EXEC @id_tutor1 = eSocios.AsignarTutor
    @id_socio = @id_menor_hijo,
    @nombre = 'Ana',
    @apellido = 'Rodriguez',
    @email = 'ana.rodriguez@email.com',
    @fecha_nac = '1982-04-20',
    @telefono = '1199887766',
    @parentesco = 'Madre';

PRINT 'Tutor Ana Rodriguez asignado a Mateo (ID: ' + CAST(@id_tutor1 AS VARCHAR) + ')';

EXEC @id_tutor2 = eSocios.AsignarTutor
    @id_socio = @id_cadete_hija,
    @nombre = 'Carlos',
    @apellido = 'Mendez',
    @email = 'carlos.mendez@email.com',
    @fecha_nac = '1975-12-05',
    @telefono = '1188776655',
    @parentesco = 'Padre';

PRINT 'Tutor Carlos Mendez asignado a Sofia (ID: ' + CAST(@id_tutor2 AS VARCHAR) + ')';

PRINT '--- Casos de error en AsignarTutor ---';

-- Error: Socio inexistente
BEGIN TRY
    EXEC eSocios.AsignarTutor
        @id_socio = 9999,
        @nombre = 'Test',
        @apellido = 'Test',
        @email = 'test@email.com',
        @fecha_nac = '1980-01-01',
        @telefono = '1111111111',
        @parentesco = 'Padre';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Asignar tutor a mayor de edad
BEGIN TRY
    EXEC eSocios.AsignarTutor
        @id_socio = @id_adulto1,
        @nombre = 'Test',
        @apellido = 'Test',
        @email = 'test2@email.com',
        @fecha_nac = '1980-01-01',
        @telefono = '1111111111',
        @parentesco = 'Padre';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio mayor de edad: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 4. ASIGNAR TUTOR DESDE SOCIO - eSocios.AsignarTutorDesdeSocio
-- ===================================================================

PRINT '';
PRINT '=== ASIGNANDO TUTORES DESDE SOCIOS ===';

-- Crear un socio menor adicional para estas pruebas
DECLARE @id_menor_extra INT;

EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '50123456',
    @nombre = 'Lucia',
    @apellido = 'Gomez',
    @email = 'lucia.gomez@email.com',
    @fecha_nac = '2013-08-25',
    @telefono = '1155667788',
    @telefono_emergencia = '1188776655',
    @obra_social = 'OSDE',
    @nro_obra_social = 'OS50123';

SELECT @id_menor_extra = id_socio FROM eSocios.Socio WHERE dni = '50123456';

-- Casos exitosos: Asignar tutores desde socios
PRINT '--- Casos exitosos AsignarTutorDesdeSocio ---';

DECLARE @id_tutor3 INT;

EXEC @id_tutor3 = eSocios.AsignarTutorDesdeSocio
    @id_socio_menor = @id_menor_extra,
    @id_socio_tutor = @id_adulto2,
    @parentesco = 'Tia';

PRINT 'Laura Fernandez asignada como tutora de Lucia (ID: ' + CAST(@id_tutor3 AS VARCHAR) + ')';

PRINT '--- Casos de error en AsignarTutorDesdeSocio ---';

-- Error: Socio menor inexistente
BEGIN TRY
    EXEC eSocios.AsignarTutorDesdeSocio
        @id_socio_menor = 9999,
        @id_socio_tutor = @id_adulto1,
        @parentesco = 'Padre';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio menor inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Socio tutor inexistente
BEGIN TRY
    EXEC eSocios.AsignarTutorDesdeSocio
        @id_socio_menor = @id_menor_extra,
        @id_socio_tutor = 9999,
        @parentesco = 'Padre';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio tutor inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Asignar tutor a mayor de edad
BEGIN TRY
    EXEC eSocios.AsignarTutorDesdeSocio
        @id_socio_menor = @id_adulto1,
        @id_socio_tutor = @id_adulto2,
        @parentesco = 'Hermano';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio no es menor: ' + ERROR_MESSAGE();
END CATCH

-- Error: Tutor no es mayor de edad
DECLARE @id_cadete INT;
SELECT @id_cadete = id_socio FROM eSocios.Socio WHERE dni = '87654321'; -- María (cadete)

BEGIN TRY
    EXEC eSocios.AsignarTutorDesdeSocio
        @id_socio_menor = @id_menor_extra,
        @id_socio_tutor = @id_cadete,
        @parentesco = 'Hermana';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Tutor no es mayor: ' + ERROR_MESSAGE();
END CATCH

-- Error: Ya es tutor del socio
BEGIN TRY
    EXEC eSocios.AsignarTutorDesdeSocio
        @id_socio_menor = @id_menor_extra,
        @id_socio_tutor = @id_adulto2,
        @parentesco = 'Tia';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Ya es tutor: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 5. MODIFICAR TUTOR - eSocios.ModificarTutor
-- ===================================================================

PRINT '';
PRINT '=== MODIFICANDO TUTORES ===';

-- Casos exitosos: Modificar tutores
PRINT '--- Casos exitosos ModificarTutor ---';

EXEC eSocios.ModificarTutor
    @id_tutor = @id_tutor1,
    @nombre = 'Ana María',
    @apellido = 'Rodriguez Vega',
    @email = 'anamaria.rodriguez@email.com',
    @fecha_nac = '1982-04-20',
    @telefono = '1199887777',
    @parentesco = 'Madre';

PRINT 'Tutor ID ' + CAST(@id_tutor1 AS VARCHAR) + ' modificado exitosamente';

PRINT '--- Casos de error en ModificarTutor ---';

-- Error: Tutor inexistente
BEGIN TRY
    EXEC eSocios.ModificarTutor
        @id_tutor = 9999,
        @nombre = 'Test',
        @apellido = 'Test',
        @email = 'test@email.com',
        @fecha_nac = '1980-01-01',
        @telefono = '1111111111',
        @parentesco = 'Padre';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Tutor inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Email duplicado
BEGIN TRY
    EXEC eSocios.ModificarTutor
        @id_tutor = @id_tutor2,
        @nombre = 'Carlos',
        @apellido = 'Mendez',
        @email = 'anamaria.rodriguez@email.com', -- Email ya usado por tutor1
        @fecha_nac = '1975-12-05',
        @telefono = '1188776655',
        @parentesco = 'Padre';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Email duplicado: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 6. ELIMINAR TUTOR - eSocios.EliminarTutor
-- ===================================================================

PRINT '';
PRINT '=== ELIMINANDO TUTORES ===';

-- Casos exitosos: Eliminar tutores
PRINT '--- Casos exitosos EliminarTutor ---';

EXEC eSocios.EliminarTutor @id_tutor = @id_tutor3;
PRINT 'Tutor ID ' + CAST(@id_tutor3 AS VARCHAR) + ' eliminado exitosamente';

PRINT '--- Casos de error en EliminarTutor ---';

-- Error: Tutor inexistente
BEGIN TRY
    EXEC eSocios.EliminarTutor @id_tutor = 9999;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Tutor inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Intentar eliminar tutor ya eliminado
BEGIN TRY
    EXEC eSocios.EliminarTutor @id_tutor = @id_tutor3;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Tutor ya eliminado: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 7. GENERAR FACTURA - eCobros.generarFactura
-- ===================================================================

PRINT '';
PRINT '=== GENERANDO FACTURAS ===';

-- Primero asignar algunas actividades para tener datos completos
DECLARE @id_natacion_test INT, @id_aqua_test INT;
SELECT @id_natacion_test = id_actividad FROM eSocios.Actividad WHERE nombre LIKE 'Natación%';
SELECT @id_aqua_test = id_actividad FROM eSocios.Actividad WHERE nombre LIKE 'Aqua%';

-- Asignar actividades a algunos socios
IF @id_natacion_test IS NOT NULL AND @id_aqua_test IS NOT NULL
BEGIN
    -- Asignar actividades al adulto1 (con grupo familiar)
    IF NOT EXISTS (SELECT 1 FROM eSocios.Realiza WHERE socio = @id_adulto1 AND id_actividad = @id_natacion_test)
        EXEC eSocios.AsignarActividad @id_socio = @id_adulto1, @id_actividad = @id_natacion_test;
    
    IF NOT EXISTS (SELECT 1 FROM eSocios.Realiza WHERE socio = @id_adulto1 AND id_actividad = @id_aqua_test)
        EXEC eSocios.AsignarActividad @id_socio = @id_adulto1, @id_actividad = @id_aqua_test;
END

-- Casos exitosos: Generar facturas
PRINT '--- Casos exitosos generarFactura ---';

DECLARE @id_factura1 INT, @id_factura2 INT, @id_factura3 INT;

-- Factura para socio con grupo familiar y múltiples actividades
EXEC @id_factura1 = eCobros.generarFactura
    @id_socio = @id_adulto1,
    @periodo = '06/2025',
    @fecha_emision = '2025-06-01';

PRINT 'Factura generada para Roberto (grupo familiar + múltiples actividades): ID ' + CAST(@id_factura1 AS VARCHAR);

-- Factura para socio con grupo familiar sin actividades adicionales
EXEC @id_factura2 = eCobros.generarFactura
    @id_socio = @id_adulto2,
    @periodo = '06/2025',
    @fecha_emision = '2025-06-01';

PRINT 'Factura generada para Laura (solo grupo familiar): ID ' + CAST(@id_factura2 AS VARCHAR);

-- Factura para socio menor (hijo en grupo familiar)
EXEC @id_factura3 = eCobros.generarFactura
    @id_socio = @id_menor_hijo,
    @periodo = '06/2025',
    @fecha_emision = '2025-06-01';

PRINT 'Factura generada para Mateo (menor en grupo familiar): ID ' + CAST(@id_factura3 AS VARCHAR);

-- Factura con fecha por defecto (sin especificar fecha_emision)
DECLARE @id_factura4 INT;
EXEC @id_factura4 = eCobros.generarFactura
    @id_socio = @id_cadete_hija,
    @periodo = '06/2025';

PRINT 'Factura generada para Sofia con fecha por defecto: ID ' + CAST(@id_factura4 AS VARCHAR);

PRINT '--- Casos de error en generarFactura ---';

-- Error: Socio inexistente
BEGIN TRY
    DECLARE @id_factura_error INT;
    EXEC @id_factura_error = eCobros.generarFactura
        @id_socio = 9999,
        @periodo = '06/2025';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio inexistente: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 8. CONSULTAS DE VERIFICACIÓN
-- ===================================================================

PRINT '';
PRINT '=== VERIFICACIONES FINALES ===';

-- Mostrar grupos familiares creados
PRINT '--- Grupos Familiares ---';
SELECT 
    gf.id_grupo,
    s.nombre + ' ' + s.apellido as adulto_responsable,
    gf.descuento,
    (SELECT COUNT(*) FROM eSocios.Socio WHERE id_grupo_familiar = gf.id_grupo) as cantidad_miembros
FROM eSocios.GrupoFamiliar gf
JOIN eSocios.Socio s ON gf.id_adulto_responsable = s.id_socio;

-- Mostrar tutores asignados
PRINT '--- Tutores Asignados ---';
SELECT 
    t.id_tutor,
    s.nombre + ' ' + s.apellido as socio_tutelado,
    t.nombre + ' ' + t.apellido as tutor,
    t.parentesco
FROM eSocios.Tutor t
JOIN eSocios.Socio s ON t.id_socio = s.id_socio;

-- Mostrar facturas generadas
PRINT '--- Facturas Generadas ---';
SELECT 
    f.id_factura,
    s.nombre + ' ' + s.apellido as socio,
    f.fecha_emision,
    f.total,
    f.descuentos,
    f.estado
FROM eCobros.Factura f
JOIN eSocios.Socio s ON f.id_socio = s.id_socio
ORDER BY f.id_factura DESC;

PRINT '';
PRINT '=== CASOS DE PRUEBA COMPLETADOS ===';