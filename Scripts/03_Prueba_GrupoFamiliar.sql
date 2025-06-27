-- ===================================================================
-- CASOS DE PRUEBA ADICIONALES PARA STORED PROCEDURES eSocios
-- ===================================================================

USE Com5600G10
GO

PRINT '=== INICIANDO CASOS DE PRUEBA ADICIONALES ===';

-- ===================================================================
-- 9. CREAR GRUPOS FAMILIARES - eSocios.CrearGrupoFamiliar
-- ===================================================================

PRINT '=== CREANDO GRUPOS FAMILIARES ===';

-- Primero necesitamos crear socios mayores de edad para ser responsables
EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '30000001',
    @nombre = 'Roberto',
    @apellido = 'Martínez',
    @email = 'roberto.martinez@email.com',
    @fecha_nac = '1980-05-15',
    @telefono = '1122334455',
    @telefono_emergencia = '1122334456',
    @obra_social = 'OSDE',
    @nro_obra_social = 'OS30001';

EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '30000002',
    @nombre = 'Ana',
    @apellido = 'López',
    @email = 'ana.lopez@email.com',
    @fecha_nac = '1985-08-22',
    @telefono = '1122334457',
    @telefono_emergencia = '1122334458',
    @obra_social = 'Swiss Medical',
    @nro_obra_social = 'SM30002';

-- Obtener IDs de los socios mayores creados
DECLARE @id_socio_mayor1 INT, @id_socio_mayor2 INT;
SELECT @id_socio_mayor1 = id_socio FROM eSocios.Socio WHERE dni = '30000001';
SELECT @id_socio_mayor2 = id_socio FROM eSocios.Socio WHERE dni = '30000002';

-- Casos exitosos: Crear grupos familiares
EXEC eSocios.CrearGrupoFamiliar @id_adulto_responsable = @id_socio_mayor1;
EXEC eSocios.CrearGrupoFamiliar @id_adulto_responsable = @id_socio_mayor2;

PRINT '--- Casos de error en CrearGrupoFamiliar ---';

-- Error: Adulto responsable inexistente
BEGIN TRY
    EXEC eSocios.CrearGrupoFamiliar @id_adulto_responsable = 999;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Adulto inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Adulto ya responsable de otro grupo
BEGIN TRY
    EXEC eSocios.CrearGrupoFamiliar @id_adulto_responsable = @id_socio_mayor1;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Adulto ya responsable: ' + ERROR_MESSAGE();
END CATCH

-- Error: Intentar asignar menor de edad como responsable
-- Primero obtener ID de un socio menor
DECLARE @id_socio_menor INT;
SELECT @id_socio_menor = id_socio FROM eSocios.Socio WHERE dni = '12345678';

BEGIN TRY
    EXEC eSocios.CrearGrupoFamiliar @id_adulto_responsable = @id_socio_menor;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Menor como responsable: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 10. AGREGAR MIEMBROS A GRUPOS FAMILIARES - eSocios.AgregarMiembroAGrupoFamiliar
-- ===================================================================

PRINT '=== AGREGANDO MIEMBROS A GRUPOS FAMILIARES ===';

-- Obtener IDs de grupos familiares creados
DECLARE @id_grupo1 INT, @id_grupo2 INT;
SELECT @id_grupo1 = id_grupo FROM eSocios.GrupoFamiliar WHERE id_adulto_responsable = @id_socio_mayor1;
SELECT @id_grupo2 = id_grupo FROM eSocios.GrupoFamiliar WHERE id_adulto_responsable = @id_socio_mayor2;

-- Crear más socios para agregar a los grupos
EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '30000003',
    @nombre = 'Lucas',
    @apellido = 'Martínez',
    @email = 'lucas.martinez@email.com',
    @fecha_nac = '2010-03-10',
    @telefono = '1122334459',
    @telefono_emergencia = '1122334460',
    @obra_social = 'OSDE',
    @nro_obra_social = 'OS30003';

EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '30000004',
    @nombre = 'Sofia',
    @apellido = 'López',
    @email = 'sofia.lopez@email.com',
    @fecha_nac = '2015-07-18',
    @telefono = '1122334461',
    @telefono_emergencia = '1122334462',
    @obra_social = 'Swiss Medical',
    @nro_obra_social = 'SM30004';

DECLARE @id_hijo1 INT, @id_hija2 INT;
SELECT @id_hijo1 = id_socio FROM eSocios.Socio WHERE dni = '30000003';
SELECT @id_hija2 = id_socio FROM eSocios.Socio WHERE dni = '30000004';

-- Casos exitosos: Agregar miembros a grupos
EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo1, @id_socio = @id_hijo1;
EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo2, @id_socio = @id_hija2;

PRINT '--- Casos de error en AgregarMiembroAGrupoFamiliar ---';

-- Error: Grupo inexistente
BEGIN TRY
    EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = 999, @id_socio = @id_hijo1;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Grupo inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Socio inexistente
BEGIN TRY
    EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo1, @id_socio = 999;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Intentar agregar al adulto responsable como miembro
BEGIN TRY
    EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo1, @id_socio = @id_socio_mayor1;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Adulto responsable como miembro: ' + ERROR_MESSAGE();
END CATCH

-- Error: Socio ya pertenece a otro grupo
BEGIN TRY
    EXEC eSocios.AgregarMiembroAGrupoFamiliar @id_grupo = @id_grupo2, @id_socio = @id_hijo1;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio ya en otro grupo: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 11. ASIGNAR TUTORES - eSocios.AsignarTutor
-- ===================================================================

PRINT '=== ASIGNANDO TUTORES ===';

-- Casos exitosos: Asignar tutores a socios menores
EXEC eSocios.AsignarTutor
    @id_socio = @id_hijo1,
    @nombre = 'Patricia',
    @apellido = 'Gómez',
    @email = 'patricia.gomez@email.com',
    @fecha_nac = '1975-12-03',
    @telefono = '1133445566',
    @parentesco = 'Tía';

EXEC eSocios.AsignarTutor
    @id_socio = @id_hija2,
    @nombre = 'Eduardo',
    @apellido = 'Fernández',
    @email = 'eduardo.fernandez@email.com',
    @fecha_nac = '1970-09-15',
    @telefono = '1133445567',
    @parentesco = 'Abuelo';

PRINT '--- Casos de error en AsignarTutor ---';

-- Error: Socio inexistente
BEGIN TRY
    EXEC eSocios.AsignarTutor
        @id_socio = 999,
        @nombre = 'Test',
        @apellido = 'Test',
        @email = 'test@email.com',
        @fecha_nac = '1980-01-01',
        @telefono = '1111111111',
        @parentesco = 'Tío';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Intentar asignar tutor a socio mayor
BEGIN TRY
    EXEC eSocios.AsignarTutor
        @id_socio = @id_socio_mayor1,
        @nombre = 'Test',
        @apellido = 'Test',
        @email = 'test2@email.com',
        @fecha_nac = '1980-01-01',
        @telefono = '1111111112',
        @parentesco = 'Padre';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Asignar tutor a mayor: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 12. ASIGNAR TUTORES DESDE SOCIOS - eSocios.AsignarTutorDesdeSocio
-- ===================================================================

PRINT '=== ASIGNANDO TUTORES DESDE SOCIOS EXISTENTES ===';

-- Crear un socio menor adicional para estas pruebas
EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '30000005',
    @nombre = 'Mateo',
    @apellido = 'Silva',
    @email = 'mateo.silva@email.com',
    @fecha_nac = '2012-11-28',
    @telefono = '1122334463',
    @telefono_emergencia = '1122334464',
    @obra_social = 'Galeno',
    @nro_obra_social = 'GA30005';

DECLARE @id_menor_adicional INT;
SELECT @id_menor_adicional = id_socio FROM eSocios.Socio WHERE dni = '30000005';

-- Caso exitoso: Asignar tutor desde socio existente
EXEC eSocios.AsignarTutorDesdeSocio
    @id_socio_menor = @id_menor_adicional,
    @id_socio_tutor = @id_socio_mayor1,
    @parentesco = 'Padre';

PRINT '--- Casos de error en AsignarTutorDesdeSocio ---';

-- Error: Socio menor inexistente
BEGIN TRY
    EXEC eSocios.AsignarTutorDesdeSocio
        @id_socio_menor = 999,
        @id_socio_tutor = @id_socio_mayor1,
        @parentesco = 'Padre';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio menor inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Socio tutor inexistente
BEGIN TRY
    EXEC eSocios.AsignarTutorDesdeSocio
        @id_socio_menor = @id_menor_adicional,
        @id_socio_tutor = 999,
        @parentesco = 'Padre';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Socio tutor inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Intentar asignar tutor menor de edad
BEGIN TRY
    EXEC eSocios.AsignarTutorDesdeSocio
        @id_socio_menor = @id_hijo1,
        @id_socio_tutor = @id_hija2,
        @parentesco = 'Hermana';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Tutor menor de edad: ' + ERROR_MESSAGE();
END CATCH

-- Error: Intentar asignar tutor a socio mayor
BEGIN TRY
    EXEC eSocios.AsignarTutorDesdeSocio
        @id_socio_menor = @id_socio_mayor2,
        @id_socio_tutor = @id_socio_mayor1,
        @parentesco = 'Hermano';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Asignar tutor a mayor: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 13. MODIFICAR TUTORES - eSocios.ModificarTutor
-- ===================================================================

PRINT '=== MODIFICANDO TUTORES ===';

-- Obtener ID de tutor para modificar
DECLARE @id_tutor_test INT;
SELECT TOP 1 @id_tutor_test = id_tutor FROM eSocios.Tutor;

-- Caso exitoso: Modificar datos del tutor
EXEC eSocios.ModificarTutor
    @id_tutor = @id_tutor_test,
    @nombre = 'Patricia Elena',
    @apellido = 'Gómez Rodríguez',
    @email = 'patricia.elena.gomez@email.com',
    @fecha_nac = '1975-12-03',
    @telefono = '1133445568',
    @parentesco = 'Tía materna';

PRINT '--- Casos de error en ModificarTutor ---';

-- Error: Tutor inexistente
BEGIN TRY
    EXEC eSocios.ModificarTutor
        @id_tutor = 999,
        @nombre = 'Test',
        @apellido = 'Test',
        @email = 'test@email.com',
        @fecha_nac = '1980-01-01',
        @telefono = '1111111111',
        @parentesco = 'Test';
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Tutor inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Email duplicado con otro tutor
-- Primero obtener email de otro tutor
DECLARE @email_otro_tutor NVARCHAR(100);
SELECT TOP 1 @email_otro_tutor = email 
FROM eSocios.Tutor 
WHERE id_tutor != @id_tutor_test;

IF @email_otro_tutor IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC eSocios.ModificarTutor
            @id_tutor = @id_tutor_test,
            @nombre = 'Test',
            @apellido = 'Test',
            @email = @email_otro_tutor,
            @fecha_nac = '1980-01-01',
            @telefono = '1111111111',
            @parentesco = 'Test';
    END TRY
    BEGIN CATCH
        PRINT 'Error esperado - Email duplicado: ' + ERROR_MESSAGE();
    END CATCH
END

-- ===================================================================
-- 14. ELIMINAR TUTORES - eSocios.EliminarTutor
-- ===================================================================

PRINT '=== ELIMINANDO TUTORES ===';

-- Crear un tutor adicional para eliminar
EXEC eSocios.AsignarTutor
    @id_socio = @id_hijo1,
    @nombre = 'Miguel',
    @apellido = 'Torres',
    @email = 'miguel.torres@email.com',
    @fecha_nac = '1978-04-20',
    @telefono = '1144556677',
    @parentesco = 'Tío';

DECLARE @id_tutor_eliminar INT;
SELECT @id_tutor_eliminar = id_tutor 
FROM eSocios.Tutor 
WHERE nombre = 'Miguel' AND apellido = 'Torres';

-- Caso exitoso: Eliminar tutor
EXEC eSocios.EliminarTutor @id_tutor = @id_tutor_eliminar;

PRINT '--- Casos de error en EliminarTutor ---';

-- Error: Tutor inexistente
BEGIN TRY
    EXEC eSocios.EliminarTutor @id_tutor = 999;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Tutor inexistente: ' + ERROR_MESSAGE();
END CATCH

-- Error: Intentar eliminar tutor ya eliminado
BEGIN TRY
    EXEC eSocios.EliminarTutor @id_tutor = @id_tutor_eliminar;
END TRY
BEGIN CATCH
    PRINT 'Error esperado - Tutor ya eliminado: ' + ERROR_MESSAGE();
END CATCH

-- ===================================================================
-- 15. ELIMINAR SOCIOS - eSocios.EliminarSocio (casos adicionales)
-- ===================================================================

PRINT '=== CASOS ADICIONALES PARA ELIMINAR SOCIOS ===';

-- Crear un socio adicional para eliminar
EXEC eSocios.insertarSocio 
    @id_grupo_familiar = NULL,
    @dni = '30000006',
    @nombre = 'Temporal',
    @apellido = 'Prueba',
    @email = 'temporal.prueba@email.com',
    @fecha_nac = '1990-01-01',
    @telefono = '1155667788',
    @telefono_emergencia = '1155667789',
    @obra_social = 'OSDE',
    @nro_obra_social = 'OS30006';

DECLARE @id_socio_temporal INT;
SELECT @id_socio_temporal = id_socio FROM eSocios.Socio WHERE dni = '30000006';

-- Caso exitoso: Eliminar socio temporal
EXEC eSocios.EliminarSocio @id_socio = @id_socio_temporal;

-- ===================================================================
-- CONSULTAS DE VERIFICACIÓN FINAL
-- ===================================================================

PRINT '=== VERIFICACIÓN FINAL DE DATOS ===';

-- Mostrar grupos familiares creados
PRINT 'Grupos Familiares:';
SELECT 
    gf.id_grupo,
    gf.descuento,
    s.nombre + ' ' + s.apellido as adulto_responsable,
    COUNT(sm.id_socio) as cantidad_miembros
FROM eSocios.GrupoFamiliar gf
JOIN eSocios.Socio s ON gf.id_adulto_responsable = s.id_socio
LEFT JOIN eSocios.Socio sm ON sm.id_grupo_familiar = gf.id_grupo AND sm.id_socio != gf.id_adulto_responsable
GROUP BY gf.id_grupo, gf.descuento, s.nombre, s.apellido
ORDER BY gf.id_grupo;

-- Mostrar tutores asignados
PRINT 'Tutores asignados:';
SELECT 
    t.id_tutor,
    t.nombre + ' ' + t.apellido as tutor_nombre,
    t.parentesco,
    s.nombre + ' ' + s.apellido as socio_tutelado,
    c.nombre as categoria_socio
FROM eSocios.Tutor t
JOIN eSocios.Socio s ON t.id_socio = s.id_socio
JOIN eSocios.Categoria c ON s.id_categoria = c.id_categoria
ORDER BY t.id_tutor;

-- Mostrar actividades con socios asignados
PRINT 'Actividades y socios:';
SELECT 
    a.nombre as actividad,
    COUNT(r.socio) as cantidad_socios,
    a.costo_mensual
FROM eSocios.Actividad a
LEFT JOIN eSocios.Realiza r ON a.id_actividad = r.id_actividad
GROUP BY a.nombre, a.costo_mensual
ORDER BY a.nombre;

PRINT '=== FIN DE CASOS DE PRUEBA ADICIONALES ===';

-- ===================================================================
-- CASOS DE PRUEBA ADICIONALES PARA VALIDACIONES ESPECÍFICAS
-- ===================================================================

PRINT '=== CASOS ESPECIALES Y VALIDACIONES ADICIONALES ===';

-- Validar que no se puede crear actividad con horarios solapados en días diferentes pero mismo horario
PRINT '--- Prueba de validación de horarios ---';
BEGIN TRY
    EXEC eSocios.CrearActividad
        @nombre = 'Test Horarios Complejos',
        @costo_mensual = 5000.00,
        @dias = 'lunes,martes,miércoles',
        @horarios = '09:00-10:00,10:30-11:30'; -- Sin solapamiento, debería funcionar
    PRINT 'Actividad con horarios complejos creada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Error inesperado en horarios complejos: ' + ERROR_MESSAGE();
END CATCH

-- Probar modificación de actividad agregando horarios sin conflicto
DECLARE @id_actividad_test INT;
SELECT @id_actividad_test = id_actividad FROM eSocios.Actividad WHERE nombre = 'Test Horarios Complejos';

IF @id_actividad_test IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC eSocios.ModificarActividad
            @id_actividad = @id_actividad_test,
            @dias = 'jueves,viernes',
            @horarios = '14:00-15:00',
            @reemplazar_horarios = 0; -- Agregar sin reemplazar
        PRINT 'Horarios agregados correctamente sin conflicto';
    END TRY
    BEGIN CATCH
        PRINT 'Error al agregar horarios: ' + ERROR_MESSAGE();
    END CATCH
END

-- Limpiar actividad de prueba
IF @id_actividad_test IS NOT NULL
BEGIN
    EXEC eSocios.EliminarActividad @id_actividad = @id_actividad_test;
END

PRINT '=== TODAS LAS PRUEBAS COMPLETADAS ===';