-- ===================================================================
-- CASOS DE USO PARA STORED PROCEDURES eSocios
-- ===================================================================

-- ===================================================================
-- SETUP INICIAL - Datos necesarios para las pruebas
-- ===================================================================

-- Verificar que existan las categor�as necesarias
SELECT * FROM eSocios.Categoria;

-- Si no existen, crearlas (descomenta si es necesario):

INSERT INTO eSocios.Categoria (nombre,costo_mensual) VALUES ('Menor',1000);
INSERT INTO eSocios.Categoria (nombre,costo_mensual) VALUES ('Cadete',2000);
INSERT INTO eSocios.Categoria (nombre,costo_mensual) VALUES ('Mayor',3000);

use Com5600G10
go
-- ===================================================================
-- 1. CREAR ACTIVIDADES - eSocios.CrearActividad
-- ===================================================================

PRINT '=== CREANDO ACTIVIDADES ===';

-- Caso exitoso: Actividad simple sin horarios espec�ficos
EXEC eSocios.CrearActividad
    @nombre = 'Nataci�n Libre',
    @costo_mensual = 5000.00;

-- Caso exitoso: Actividad con horarios espec�ficos
EXEC eSocios.CrearActividad
    @nombre = 'Aqua Aer�bicos',
    @costo_mensual = 7500.50,
    @dias = 'lunes,mi�rcoles,viernes',
    @horarios = '09:00-10:00,18:00-19:00';

-- Caso exitoso: Actividad con m�ltiples horarios
EXEC eSocios.CrearActividad
    @nombre = 'Clases de Tenis',
    @costo_mensual = 12000.00,
    @dias = 'martes,jueves,s�bado',
    @horarios = '10:00-11:30,16:00-17:30';

-- Caso exitoso: Actividad gratuita
EXEC eSocios.CrearActividad
    @nombre = 'Actividad Social',
    @costo_mensual = 0.00;

PRINT '--- Casos de error en CrearActividad ---';

-- Error: Nombre vac�o
BEGIN TRY
    EXEC eSocios.CrearActividad
        @nombre = '',
        @costo_mensual = 5000.00;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Nombre vac�o: ' + ERROR_MESSAGE();
END CATCH

-- Error: Costo negativo
BEGIN TRY
    EXEC eSocios.CrearActividad
        @nombre = 'Test Costo Negativo',
        @costo_mensual = -100.00;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Costo negativo: ' + ERROR_MESSAGE();
END CATCH

-- Error: Nombre duplicado
BEGIN TRY
    EXEC eSocios.CrearActividad
        @nombre = 'Nataci�n Libre', -- Ya existe
        @costo_mensual = 6000.00;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Nombre duplicado: ' + ERROR_MESSAGE();
END CATCH

-- Error: D�as sin horarios
BEGIN TRY
    EXEC eSocios.CrearActividad
        @nombre = 'Test Error D�as',
        @costo_mensual = 5000.00,
        @dias = 'lunes,martes';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - D�as sin horarios: ' + ERROR_MESSAGE();
END CATCH

-- Error: D�a inv�lido
BEGIN TRY
    EXEC eSocios.CrearActividad
        @nombre = 'Test D�a Inv�lido',
        @costo_mensual = 5000.00,
        @dias = 'lunez,martes', -- Error en "lunez"
        @horarios = '09:00-10:00';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - D�a inv�lido: ' + ERROR_MESSAGE();
END CATCH

-- Error: Formato de horario inv�lido
BEGIN TRY
    EXEC eSocios.CrearActividad
        @nombre = 'Test Horario Inv�lido',
        @costo_mensual = 5000.00,
        @dias = 'lunes',
        @horarios = '09:00/10:00'; -- Separador incorrecto
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Formato horario: ' + ERROR_MESSAGE();
END CATCH

-- Error: Hora inicio mayor que hora fin
BEGIN TRY
    EXEC eSocios.CrearActividad
        @nombre = 'Test Hora Inv�lida',
        @costo_mensual = 5000.00,
        @dias = 'lunes',
        @horarios = '10:00-09:00';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Hora inicio > hora fin: ' + ERROR_MESSAGE();
END CATCH

-- Error: Horarios solapados
BEGIN TRY
    EXEC eSocios.CrearActividad
        @nombre = 'Test Solapamiento',
        @costo_mensual = 5000.00,
        @dias = 'lunes',
        @horarios = '09:00-11:00,10:00-12:00'; -- Se solapan
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Horarios solapados: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 2. INSERTAR SOCIOS - eSocios.insertarSocio
-- ===================================================================

PRINT '=== INSERTANDO SOCIOS ===';

-- Caso exitoso: Socio menor (12 a�os)
EXEC eSocios.insertarSocio 
    @id_grupo_familiar = 1,
    @dni = '12345678',
    @nombre = 'Juan',
    @apellido = 'P�rez',
    @email = 'juan.perez@email.com',
    @fecha_nac = '2012-03-15',
    @telefono = '1234567890',
    @telefono_emergencia = '0987654321',
    @obra_social = 'OSDE',
    @nro_obra_social = 'OS12345';

-- Caso exitoso: Socio cadete (15 a�os)
EXEC eSocios.insertarSocio 
    @id_grupo_familiar = 2,
    @dni = '87654321',
    @nombre = 'Mar�a',
    @apellido = 'Gonz�lez',
    @email = 'maria.gonzalez@email.com',
    @fecha_nac = '2009-08-20',
    @telefono = '1111222233',
    @telefono_emergencia = '3333444455',
    @obra_social = 'Swiss Medical',
    @nro_obra_social = 'SM67890';

-- Caso exitoso: Socio mayor (25 a�os)
EXEC eSocios.insertarSocio 
    @id_grupo_familiar = 3,
    @dni = '11223344',
    @nombre = 'Carlos',
    @apellido = 'Rodr�guez',
    @email = 'carlos.rodriguez@email.com',
    @fecha_nac = '1999-12-10',
    @telefono = '5555666677',
    @telefono_emergencia = '7777888899',
    @obra_social = 'Galeno',
    @nro_obra_social = 'GA11111';

-- ===================================================================
-- 3. ASIGNAR ACTIVIDADES - eSocios.AsignarActividad
-- ===================================================================

PRINT '=== ASIGNANDO ACTIVIDADES ===';

-- Obtener IDs de actividades y socios creados
DECLARE @id_natacion INT, @id_aqua INT, @id_tenis INT, @id_social INT;
DECLARE @id_socio1 INT, @id_socio2 INT, @id_socio3 INT;

SELECT @id_natacion = id_actividad FROM eSocios.Actividad WHERE nombre = 'Nataci�n Libre';
SELECT @id_aqua = id_actividad FROM eSocios.Actividad WHERE nombre = 'Aqua Aer�bicos';
SELECT @id_tenis = id_actividad FROM eSocios.Actividad WHERE nombre = 'Clases de Tenis';
SELECT @id_social = id_actividad FROM eSocios.Actividad WHERE nombre = 'Actividad Social';

SELECT @id_socio1 = id_socio FROM eSocios.Socio WHERE dni = '12345678';
SELECT @id_socio2 = id_socio FROM eSocios.Socio WHERE dni = '87654321';
SELECT @id_socio3 = id_socio FROM eSocios.Socio WHERE dni = '11223344';

-- Casos exitosos: Asignar actividades
EXEC eSocios.AsignarActividad @id_socio = @id_socio1, @id_actividad = @id_natacion;
EXEC eSocios.AsignarActividad @id_socio = @id_socio1, @id_actividad = @id_social;
EXEC eSocios.AsignarActividad @id_socio = @id_socio2, @id_actividad = @id_aqua;
EXEC eSocios.AsignarActividad @id_socio = @id_socio2, @id_actividad = @id_tenis;
EXEC eSocios.AsignarActividad @id_socio = @id_socio3, @id_actividad = @id_natacion;

PRINT '--- Casos de error en AsignarActividad ---';

-- Error: Socio inexistente
BEGIN TRY
    EXEC eSocios.AsignarActividad @id_socio = 999, @id_actividad = @id_natacion;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Actividad inexistente
BEGIN TRY
    EXEC eSocios.AsignarActividad @id_socio = @id_socio1, @id_actividad = 999;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Actividad inexistente: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 4. MODIFICAR SOCIOS - eSocios.ModificarSocio
-- ===================================================================

PRINT '=== MODIFICANDO SOCIOS ===';

-- Caso exitoso: Modificar datos de un socio
EXEC eSocios.ModificarSocio
    @id_socio = @id_socio1,
    @nombre = 'Juan Carlos',
    @apellido = 'P�rez Garc�a',
    @email = 'juancarlos.perez@newemail.com',
    @fecha_nac = '2012-03-15',
    @telefono = '1234567891',
    @telefono_emergencia = '0987654322',
    @obra_social = 'OSDE Premium',
    @nro_obra_social = 'OS12346';

PRINT '--- Casos de error en ModificarSocio ---';

-- Error: Email con formato inv�lido
BEGIN TRY
    EXEC eSocios.ModificarSocio
        @id_socio = @id_socio2,
        @nombre = 'Mar�a',
        @apellido = 'Gonz�lez',
        @email = 'email_invalido',
        @fecha_nac = '2009-08-20',
        @telefono = '1111222233',
        @telefono_emergencia = '3333444455',
        @obra_social = 'Swiss Medical',
        @nro_obra_social = 'SM67890';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Email inv�lido: ' + ERROR_MESSAGE();
END CATCH

-- Error: Socio inexistente
BEGIN TRY
    EXEC eSocios.ModificarSocio
        @id_socio = 999,
        @nombre = 'Test',
        @apellido = 'Test',
        @email = 'test@email.com',
        @fecha_nac = '2000-01-01',
        @telefono = '1111111111',
        @telefono_emergencia = '2222222222',
        @obra_social = 'Test',
        @nro_obra_social = 'T123';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio inexistente: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 5. MODIFICAR ACTIVIDADES - eSocios.ModificarActividad
-- ===================================================================

PRINT '=== MODIFICANDO ACTIVIDADES ===';

-- Caso exitoso: Modificar solo nombre y costo
EXEC eSocios.ModificarActividad
    @id_actividad = @id_natacion,
    @nombre = 'Nataci�n Libre Premium',
    @costo_mensual = 6500.00;

-- Caso exitoso: Agregar nuevos horarios sin reemplazar existentes
EXEC eSocios.ModificarActividad
    @id_actividad = @id_social,
    @dias = 'domingo',
    @horarios = '08:00-09:00',
    @reemplazar_horarios = 0;

-- Caso exitoso: Reemplazar completamente los horarios
EXEC eSocios.ModificarActividad
    @id_actividad = @id_aqua,
    @nombre = 'Aqua Aer�bicos Intensivo',
    @costo_mensual = 8000.00,
    @dias = 'lunes,mi�rcoles,viernes,s�bado',
    @horarios = '06:00-08:00,19:00-21:00',
    @reemplazar_horarios = 1;

PRINT '--- Casos de error en ModificarActividad ---';

-- Error: Actividad inexistente
BEGIN TRY
    EXEC eSocios.ModificarActividad @id_actividad = 999, @nombre = 'Test';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Actividad inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Sin par�metros para modificar
BEGIN TRY
    EXEC eSocios.ModificarActividad @id_actividad = @id_natacion;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Sin par�metros: ' + ERROR_MESSAGE();
END CATCH

-- Error: Nombre vac�o
BEGIN TRY
    EXEC eSocios.ModificarActividad @id_actividad = @id_natacion, @nombre = '';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Nombre vac�o: ' + ERROR_MESSAGE();
END CATCH

-- Error: Costo negativo
BEGIN TRY
    EXEC eSocios.ModificarActividad @id_actividad = @id_natacion, @costo_mensual = -500.00;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Costo negativo: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 6. DESINSCRIBIR ACTIVIDADES - eSocios.DesinscribirActividad
-- ===================================================================

PRINT '=== DESINSCRIBIENDO ACTIVIDADES ===';

-- Caso exitoso: Desinscribir socio de una actividad
EXEC eSocios.DesinscribirActividad @id_socio = @id_socio1, @id_actividad = @id_social;

-- Caso exitoso: Desinscribir otro socio
EXEC eSocios.DesinscribirActividad @id_socio = @id_socio2, @id_actividad = @id_tenis;

PRINT '--- Casos de error en DesinscribirActividad ---';

-- Error: Socio no est� inscrito en la actividad
BEGIN TRY
    EXEC eSocios.DesinscribirActividad @id_socio = @id_socio1, @id_actividad = @id_tenis;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio no inscrito: ' + ERROR_MESSAGE();
END CATCH

-- Error: IDs inexistentes
BEGIN TRY
    EXEC eSocios.DesinscribirActividad @id_socio = 999, @id_actividad = 999;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - IDs inexistentes: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 7. ELIMINAR ACTIVIDADES - eSocios.EliminarActividad
-- ===================================================================

PRINT '=== ELIMINANDO ACTIVIDADES ===';

-- Caso exitoso: Eliminar actividad por ID
EXEC eSocios.EliminarActividad @id_actividad = @id_social;

-- Caso exitoso: Eliminar actividad por nombre
EXEC eSocios.EliminarActividad @nombre = 'Clases de Tenis';

PRINT '--- Casos de error en EliminarActividad ---';

-- Error: Sin par�metros
BEGIN TRY
    EXEC eSocios.EliminarActividad;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Sin par�metros: ' + ERROR_MESSAGE();
END CATCH

-- Error: ID inexistente
BEGIN TRY
    EXEC eSocios.EliminarActividad @id_actividad = 999;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - ID inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Nombre inexistente
BEGIN TRY
    EXEC eSocios.EliminarActividad @nombre = 'Actividad Inexistente';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Nombre inexistente: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 8. ELIMINAR SOCIOS - eSocios.EliminarSocio
-- ===================================================================

PRINT '=== ELIMINANDO SOCIOS ===';

-- Caso exitoso: Eliminar un socio
EXEC eSocios.EliminarSocio @id_socio = @id_socio3;

PRINT '--- Casos de error en EliminarSocio ---';

-- Error: Socio inexistente
BEGIN TRY
    EXEC eSocios.EliminarSocio @id_socio = 999;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Intentar eliminar socio ya eliminado
BEGIN TRY
    EXEC eSocios.EliminarSocio @id_socio = @id_socio3;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio ya eliminado: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- CONSULTAS DE VERIFICACI�N
-- ===================================================================

PRINT '=== ESTADO FINAL DE LAS TABLAS ===';

-- Ver socios activos
SELECT 'SOCIOS ACTIVOS' as Tabla;
SELECT id_socio, nombre, apellido, dni, 
       CASE 
           WHEN DATEDIFF(YEAR, fecha_nac, GETDATE()) <= 12 THEN 'Menor'
           WHEN DATEDIFF(YEAR, fecha_nac, GETDATE()) BETWEEN 13 AND 17 THEN 'Cadete'
           ELSE 'Mayor'
       END as categoria_calculada,
       activo
FROM eSocios.Socio;

-- Ver actividades existentes
SELECT 'ACTIVIDADES EXISTENTES' as Tabla;
SELECT a.id_actividad, a.nombre, a.costo_mensual, 
       COUNT(adh.dia) as cantidad_horarios
FROM eSocios.Actividad a
LEFT JOIN eSocios.ActividadDiaHorario adh ON a.id_actividad = adh.id_actividad
GROUP BY a.id_actividad, a.nombre, a.costo_mensual
ORDER BY a.id_actividad;

-- Ver asignaciones de actividades
SELECT 'ASIGNACIONES ACTIVAS' as Tabla;
SELECT s.nombre + ' ' + s.apellido as socio, 
       a.nombre as actividad,
       a.costo_mensual
FROM eSocios.Realiza r
JOIN eSocios.Socio s ON r.socio = s.id_socio
JOIN eSocios.Actividad a ON r.id_actividad = a.id_actividad
WHERE s.activo = 1;

-- Ver horarios de actividades
SELECT 'HORARIOS DE ACTIVIDADES' as Tabla;
SELECT a.nombre as actividad, 
       adh.dia, 
       FORMAT(adh.hora_inicio, 'HH:mm') + '-' + FORMAT(adh.hora_fin, 'HH:mm') as horario
FROM eSocios.Actividad a
JOIN eSocios.ActividadDiaHorario adh ON a.id_actividad = adh.id_actividad
ORDER BY a.nombre, adh.dia, adh.hora_inicio;

PRINT '=== PRUEBAS COMPLETADAS ===';


-- ====================
-- LIMPIEZA DE DATOS - 
-- ====================

PRINT '=== INICIANDO LIMPIEZA DE DATOS ===';

-- Deshabilitar restricciones de clave for�nea temporalmente para facilitar la limpieza
EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";

BEGIN TRY
    BEGIN TRANSACTION;
    
    -- 1. Eliminar asignaciones de actividades (tabla Realiza)
    DELETE FROM eSocios.Realiza;
    PRINT 'Eliminadas todas las asignaciones de actividades (Realiza)';
    
    -- 2. Eliminar horarios de actividades
    DELETE FROM eSocios.ActividadDiaHorario;
    PRINT 'Eliminados todos los horarios de actividades (ActividadDiaHorario)';
    
    -- 3. Eliminar actividades
    DELETE FROM eSocios.Actividad;
    PRINT 'Eliminadas todas las actividades (Actividad)';
    
    -- 4. Eliminar socios
    DELETE FROM eSocios.Socio;
    PRINT 'Eliminados todos los socios (Socio)';
    
    -- 5. Eliminar grupos familiares (si existe la tabla y no tiene referencias)
    IF OBJECT_ID('eSocios.GrupoFamiliar', 'U') IS NOT NULL
    BEGIN
        DELETE FROM eSocios.GrupoFamiliar;
        PRINT 'Eliminados todos los grupos familiares (GrupoFamiliar)';
    END
    
    -- 6. Resetear los contadores de identidad
    IF OBJECT_ID('eSocios.Actividad', 'U') IS NOT NULL
        DBCC CHECKIDENT ('eSocios.Actividad', RESEED, 0);
    
    IF OBJECT_ID('eSocios.Socio', 'U') IS NOT NULL
        DBCC CHECKIDENT ('eSocios.Socio', RESEED, 0);
    
    IF OBJECT_ID('eSocios.GrupoFamiliar', 'U') IS NOT NULL
        DBCC CHECKIDENT ('eSocios.GrupoFamiliar', RESEED, 0);
    
    PRINT 'Contadores de identidad reseteados';
    
    -- Confirmar la transacci�n
    COMMIT TRANSACTION;
    PRINT 'Limpieza completada exitosamente';
    
END TRY
BEGIN CATCH
    -- En caso de error, revertir la transacci�n
    ROLLBACK TRANSACTION;
    PRINT 'Error durante la limpieza: ' + ERROR_MESSAGE();
END CATCH

-- Rehabilitar las restricciones de clave for�nea
EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";

-- ===================================================================
-- VERIFICACI�N FINAL DE LA LIMPIEZA
-- ===================================================================

PRINT '=== VERIFICACI�N POST-LIMPIEZA ===';

-- Verificar que las tablas est�n vac�as (excepto Categor�a)
SELECT 'VERIFICACI�N - Conteo de registros' as Titulo;

SELECT 'Actividad' as Tabla, COUNT(*) as Registros FROM eSocios.Actividad
UNION ALL
SELECT 'ActividadDiaHorario' as Tabla, COUNT(*) as Registros FROM eSocios.ActividadDiaHorario
UNION ALL
SELECT 'Socio' as Tabla, COUNT(*) as Registros FROM eSocios.Socio
UNION ALL
SELECT 'Realiza' as Tabla, COUNT(*) as Registros FROM eSocios.Realiza
UNION ALL
SELECT 'Categoria' as Tabla, COUNT(*) as Registros FROM eSocios.Categoria;

-- Mostrar las categor�as que permanecen
SELECT 'CATEGOR�AS PRESERVADAS' as Titulo;
SELECT * FROM eSocios.Categoria;

PRINT '=== LIMPIEZA COMPLETADA - SISTEMA LISTO PARA NUEVAS PRUEBAS ==='; 

