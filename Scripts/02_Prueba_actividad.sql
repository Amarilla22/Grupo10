/*
Entrega 4 - Juegos de prueba.
Fecha de entrega: 20/06/2025
Nro. Comision: 5600
Grupo: 10
Materia: Bases de datos aplicada
Integrantes:
- Moggi Rocio , DNI: 45576066
- Amarilla Santiago, DNI: 45481129 
- Martinez Galo, DNI: 43094675
- Fleita Thiago , DNI: 45233264
*/

-- =====================================================
-- CASOS DE PRUEBA PARA STORED PROCEDURES DE ACTIVIDADES
-- =====================================================

-- Limpiar datos previos (opcional - usar con cuidado en producción)
/*
DELETE FROM eSocios.ActividadDiaHorario;
DELETE FROM eSocios.Actividad;
*/

use Com5600G10
go

-- '==========================================';
-- 'CASOS DE PRUEBA - CREAR ACTIVIDAD';
-- '==========================================';

-- CASO 1: Crear actividad con horarios múltiples
PRINT CHAR(13) + '--- CASO 2: Crear actividad con horarios múltiples ---';
EXEC eSocios.CrearActividad 
    @nombre = 'Fulvo',
    @costo_mensual = 6000.00,
    @dias = 'lunes,miércoles,viernes',
    @horarios = '09:00-10:00,18:00-19:00';

-- CASO 2: Crear actividad fin de semana
PRINT CHAR(13) + '--- CASO 3: Crear actividad fin de semana ---';
EXEC eSocios.CrearActividad 
    @nombre = 'voley',
    @costo_mensual = 4500.00,
    @dias = 'sábado,domingo',
    @horarios = '10:00-11:00';

-- CASO 3: Crear actividad gratuita
PRINT CHAR(13) + '--- CASO 4: Crear actividad gratuita ---';
EXEC eSocios.CrearActividad 
    @nombre = 'natacion',
    @costo_mensual = 0.00,
    @dias = 'jueves',
    @horarios = '19:00-20:00';

-- ERROR 1: Nombre vacío
PRINT CHAR(13) + 'ERROR 1: Nombre vacío';
BEGIN TRY
    EXEC eSocios.CrearActividad 
        @nombre = '',
        @costo_mensual = 5000.00;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- ERROR 2: Costo negativo
PRINT CHAR(13) + 'ERROR 2: Costo negativo';
BEGIN TRY
    EXEC eSocios.CrearActividad 
        @nombre = 'Actividad Inválida',
        @costo_mensual = -1000.00;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- ERROR 3: Nombre duplicado
BEGIN TRY
    EXEC eSocios.CrearActividad 
        @nombre = 'Fulvo',
        @costo_mensual = 3000.00;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- ERROR 4: Día inválido
BEGIN TRY
    EXEC eSocios.CrearActividad 
        @nombre = 'Actividad Inválida 2',
        @costo_mensual = 5000.00,
        @dias = 'lunes,martes,invalid_day',
        @horarios = '10:00-11:00';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- ERROR 5: Formato horario inválido
PRINT CHAR(13) + 'ERROR 5: Formato horario inválido';
BEGIN TRY
    EXEC eSocios.CrearActividad 
        @nombre = 'Actividad Inválida 3',
        @costo_mensual = 5000.00,
        @dias = 'lunes',
        @horarios = '10:00_11:00'; -- Sin guión
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- ERROR 6: Hora inicio >= hora fin
BEGIN TRY
    EXEC eSocios.CrearActividad 
        @nombre = 'Actividad Inválida 4',
        @costo_mensual = 5000.00,
        @dias = 'lunes',
        @horarios = '11:00-10:00'; -- Hora fin menor que inicio
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- '==========================================';
-- 'CASOS DE PRUEBA - MODIFICAR ACTIVIDAD';
-- '==========================================';

-- CASO 1: Modificar solo nombre
EXEC eSocios.ModificarActividad 
    @id_actividad = 1,
    @nombre = 'Yoga Avanzado';

-- CASO 2: Modificar solo costo
EXEC eSocios.ModificarActividad 
    @id_actividad = 2,
    @costo_mensual = 7000.00;

-- CASO 3: Agregar horarios (sin reemplazar)
EXEC eSocios.ModificarActividad 
    @id_actividad = 2,
    @dias = 'martes,jueves',
    @horarios = '07:00-08:00',
    @reemplazar_horarios = 0;

-- CASO 4: Reemplazar todos los horarios
EXEC eSocios.ModificarActividad 
    @id_actividad = 3,
    @dias = 'lunes,miércoles,viernes',
    @horarios = '08:00-09:00,17:00-18:00',
    @reemplazar_horarios = 1;

-- CASO 5: Modificar todo
EXEC eSocios.ModificarActividad 
    @id_actividad = 4,
    @nombre = 'Seminario de Nutrición',
    @costo_mensual = 2500.00,
    @dias = 'viernes',
    @horarios = '18:30-20:00',
    @reemplazar_horarios = 1;

-- ERROR 1: ID inexistente
BEGIN TRY
    EXEC eSocios.ModificarActividad 
        @id_actividad = 999,
        @nombre = 'No existe';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- ERROR 2: No especificar campos para modificar
BEGIN TRY
    EXEC eSocios.ModificarActividad 
        @id_actividad = 1;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- ERROR 3: Nombre duplicado
BEGIN TRY
    EXEC eSocios.ModificarActividad 
        @id_actividad = 1,
        @nombre = 'Pilates'; -- Ya existe
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- ERROR 4: Costo negativo
BEGIN TRY
    EXEC eSocios.ModificarActividad 
        @id_actividad = 1,
        @costo_mensual = -500.00;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- '==========================================';
-- 'CASOS DE PRUEBA - ELIMINAR ACTIVIDAD';
-- '==========================================';

-- CASO 1: Eliminar por ID
-- Buscar el ID de la actividad temporal 1

EXEC eSocios.EliminarActividad 
    @id_actividad = 1;

-- CASO 2: Eliminar por nombre
EXEC eSocios.EliminarActividad 
    @nombre = 'voley';

-- CASOS DE ERROR PARA ELIMINAR ACTIVIDAD

-- ERROR 1: No especificar parámetros
BEGIN TRY
    EXEC eSocios.sp_EliminarActividad;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- ERROR 2: ID inexistente
BEGIN TRY
    EXEC eSocios.sp_EliminarActividad 
        @id_actividad = 999;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

-- ERROR 3: Nombre inexistente
BEGIN TRY
    EXEC eSocios.sp_EliminarActividad 
        @nombre = 'Actividad Inexistente';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

--'==========================================';
--'VERIFICACIÓN FINAL - ESTADO DE LAS TABLAS';
--'==========================================';

-- Mostrar detalle de horarios
PRINT CHAR(13) + '--- DETALLE DE HORARIOS ---';
SELECT 
    a.nombre as actividad,
    adh.dia,
    adh.hora_inicio,
    adh.hora_fin
FROM eSocios.Actividad a
INNER JOIN eSocios.ActividadDiaHorario adh ON a.id_actividad = adh.id_actividad
ORDER BY a.nombre, adh.dia, adh.hora_inicio;


-- =====================================================
-- CASOS DE PRUEBA ADICIONALES PARA ESCENARIOS ESPECÍFICOS
-- =====================================================

-- CASO AVANZADO 1: Crear actividad con horarios solapados (debe fallar)
BEGIN TRY
    EXEC eSocios.CrearActividad 
        @nombre = 'Actividad Solapada',
        @costo_mensual = 5000.00,
        @dias = 'lunes',
        @horarios = '09:00-10:30,10:00-11:00'; -- Se solapan
END TRY
BEGIN CATCH
    PRINT 'Error capturado correctamente: ' + ERROR_MESSAGE();
END CATCH

-- CASO AVANZADO 2: Modificar con horarios solapados con existentes (debe fallar)
BEGIN TRY
    -- Intentar agregar horario que solapa con uno existente
    EXEC eSocios.ModificarActividad 
        @id_actividad = 2, -- Pilates que tiene horarios lunes,miércoles,viernes 09:00-10:00,18:00-19:00
        @dias = 'lunes',
        @horarios = '09:30-10:30', -- Solapa con 09:00-10:00
        @reemplazar_horarios = 0;
END TRY
BEGIN CATCH
    PRINT 'Error capturado correctamente: ' + ERROR_MESSAGE();
END CATCH

-- CASO AVANZADO 3: Actividad con muchos horarios
EXEC eSocios.CrearActividad 
    @nombre = 'Spinning Intensivo',
    @costo_mensual = 8000.00,
    @dias = 'lunes,martes,miércoles,jueves,viernes,sábado',
    @horarios = '06:00-07:00,07:30-08:30,18:00-19:00,19:30-20:30';

-- CASO AVANZADO 4: Modificar actividad paso a paso
-- Primero cambiar nombre
EXEC eSocios.ModificarActividad 
    @id_actividad = 1,
    @nombre = 'Yoga Premium';

-- Luego cambiar costo
EXEC eSocios.ModificarActividad 
    @id_actividad = 1,
    @costo_mensual = 8500.00;

-- Finalmente agregar horarios
EXEC eSocios.ModificarActividad 
    @id_actividad = 1,
    @dias = 'martes,jueves',
    @horarios = '06:30-07:30',
    @reemplazar_horarios = 0;

-- '==========================================';
-- 'VERIFICACIÓN FINAL AVANZADA';
-- '==========================================';

-- Contar total de actividades y horarios
SELECT 
    'RESUMEN' as tipo,
    COUNT(DISTINCT a.id_actividad) as total_actividades,
    COUNT(adh.dia) as total_horarios,
    AVG(a.costo_mensual) as costo_promedio
FROM eSocios.Actividad a
LEFT JOIN eSocios.ActividadDiaHorario adh ON a.id_actividad = adh.id_actividad;