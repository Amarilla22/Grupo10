
-- ===================================================================
-- CASOS DE USO PARA STORED PROCEDURES eSocios
-- ===================================================================
USE Com5600G10
SET NOCOUNT ON
GO


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.agregarCategoria
-- ==========================================';
GO

PRINT '=== CASO 1: Agregar categoría válida ===';
DECLARE @fechaFutura DATE = DATEADD(MONTH, 3, GETDATE());
EXEC eSocios.agregarCategoria 
    @nombre = 'Mayor',
    @costo_mensual = 2000,
    @vigencia = @fechaFutura; 
GO

PRINT '=== CASO 2: Agregar categoría con costo negativo ===';
-- Esperado: Mensaje "Costo mensual invalido"
DECLARE @fechaFutura DATE = DATEADD(MONTH, 3, GETDATE());

EXEC eSocios.agregarCategoria 
    @nombre = 'Negativa',
    @costo_mensual = -100,
    @vigencia = @fechaFutura;
GO

PRINT '=== CASO 3: Agregar categoría con vigencia incorrecta ===';
-- Esperado: Mensaje "Fecha de Vigencia incorrecta"
EXEC eSocios.agregarCategoria 
    @nombre = 'Mayor',
    @costo_mensual = 1100,
    @vigencia = '2020-07-01';
GO

SELECT 'agregarCategoria'
SELECT * FROM eSocios.Categoria
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.modificarCategoria
-- ==========================================';
GO

PRINT '=== CASO 1: Modificar categoría existente ===';
-- Esperado: Modificación correcta
DECLARE @fechaFutura DATE = DATEADD(MONTH, 3, GETDATE());
EXEC eSocios.modificarCategoria 
    @id_categoria = 1,
    @nombre = 'Jóvenes',
    @costo_mensual = 2600,
    @vigencia = @fechaFutura;
GO

PRINT '=== CASO 2: Modificar categoría inexistente ===';
-- Esperado: Mensaje "La categoría no existe"
DECLARE @fechaFutura DATE = DATEADD(MONTH, 3, GETDATE());

EXEC eSocios.modificarCategoria 
    @id_categoria = 9999,
    @nombre = 'Fantasía',
    @costo_mensual = 1234,
    @vigencia = @fechaFutura;
GO

PRINT '=== CASO 3: Modificar con costo mensual negativo ===';
-- Esperado: Mensaje "Costo mensual invalido"
EXEC eSocios.modificarCategoria 
    @id_categoria = 1,
    @nombre = 'ErrorNegativo',
    @costo_mensual = -300,
    @vigencia = '2025-07-01';
GO


PRINT '=== CASO 4: Fecha de Vigencia incorrecta ===';
-- Esperado: Mensaje "Fecha de Vigencia incorrecta"
EXEC eSocios.modificarCategoria 
    @id_categoria = 1,
    @nombre = 'Menor',
    @costo_mensual = 1000,
    @vigencia = '2021-07-01';
GO


SELECT 'modificarCategoria'
SELECT * FROM eSocios.Categoria
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.eliminarCategoria
-- ==========================================';
GO

PRINT '=== CASO 1: Eliminar categoría no asignada a socios ===';
-- Esperado: Eliminación exitosa
DECLARE @fechaFutura DATE = DATEADD(MONTH, 3, GETDATE());
EXEC eSocios.agregarCategoria 
    @nombre = 'Temporal',
    @costo_mensual = 2000,
    @vigencia = @fechaFutura;

DECLARE @id_temp INT;
SELECT TOP 1 @id_temp = id_categoria FROM eSocios.Categoria WHERE nombre = 'Temporal';

SELECT 'eliminarCategoria'
SELECT * FROM eSocios.Categoria

EXEC eSocios.eliminarCategoria @id_categoria = @id_temp;
GO

PRINT '=== CASO 2: Eliminar categoría inexistente ===';
-- Esperado: Mensaje "La categoría no existe"
EXEC eSocios.eliminarCategoria @id_categoria = 9999;
GO

PRINT '=== CASO 3: Eliminar categoría asignada a socios ===';
-- Esperado: Mensaje "No se puede eliminar la categoría porque está asignada"

INSERT INTO eSocios.Socio 
(
    id_socio, id_categoria, dni, nombre, apellido, fecha_nac, activo
)
VALUES 
(
    'AA-001', 1, 35123456, 'Facundo', 'Crespo', '2002-03-15', 1
);


EXEC eSocios.eliminarCategoria @id_categoria = 1;
GO


SELECT * FROM eSocios.Categoria
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.crearActividad
-- ==========================================';
GO

PRINT '=== CASO 1: Crear actividad válida ===';
-- Esperado: Se crea una actividad sin errores
DECLARE @fechaFutura DATE = DATEADD(MONTH, 3, GETDATE());

EXEC eSocios.crearActividad 
    @nombre = 'Natación',
    @costo_mensual = 4500,
    @vigencia = @fechaFutura;

	EXEC eSocios.crearActividad 
    @nombre = 'Futbol',
    @costo_mensual = 2000,
    @vigencia = @fechaFutura;
GO

PRINT '=== CASO 2: Crear actividad con costo negativo ===';
-- Esperado: Mensaje de "Costo mensual invalido"
DECLARE @fechaFutura DATE = DATEADD(MONTH, 3, GETDATE());

EXEC eSocios.crearActividad 
    @nombre = 'Boxeo',
    @costo_mensual = -2000,
    @vigencia = @fechaFutura;
GO

PRINT '=== CASO 3: Crear actividad con vigencia incorrecta ===';
-- Esperado: Mensaje "Fecha de Vigencia incorrecta"

EXEC eSocios.crearActividad 
    @nombre = 'Boxeo',
    @costo_mensual = 2000,
    @vigencia = '2021-07-01';
GO

SELECT 'crearActividad'
SELECT * FROM eSocios.Actividad
GO


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.modificarActividad
-- ==========================================';
GO

PRINT '=== CASO 1: Modificar nombre y costo de actividad existente ===';
-- Esperado: Actualización correcta
DECLARE @fechaFutura DATE = DATEADD(MONTH, 3, GETDATE());
EXEC eSocios.modificarActividad 
    @id_actividad = 1,
    @nombre = 'Natación adultos',
    @costo_mensual = 5000,
    @vigencia = @fechaFutura;
GO

PRINT '=== CASO 2: Modificar actividad inexistente ===';
-- Esperado: Mensaje "La actividad no existe"
DECLARE @fechaFutura DATE = DATEADD(MONTH, 3, GETDATE());
EXEC eSocios.modificarActividad 
    @id_actividad = 9999,
    @nombre = 'Yoga',
    @costo_mensual = 3000,
    @vigencia = @fechaFutura;
GO


PRINT '=== CASO 3: Fecha de Vigencia incorrecta ===';
-- Esperado: Mensaje "Fecha de Vigencia incorrecta"
EXEC eSocios.modificarActividad 
    @id_actividad = 1,
    @nombre = 'Yoga',
    @costo_mensual = 3000,
    @vigencia = '2018-07-01';
GO


SELECT 'modificarActividad'
SELECT * FROM eSocios.Actividad
GO


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.agregarHorarioActividad
-- ==========================================';
GO

PRINT '=== CASO 1: Asignar horario válido a una actividad existente ===';
-- Esperado: Inserción exitosa
EXEC eSocios.agregarHorarioActividad 
    @id_actividad = 1,
    @dia = 'lunes',
    @hora_inicio = '10:00',
    @hora_fin = '11:00';

EXEC eSocios.agregarHorarioActividad 
    @id_actividad = 2,
    @dia = 'sabado',
    @hora_inicio = '8:00',
    @hora_fin = '12:00';

GO

PRINT '=== CASO 2: Día inválido ===';
-- Esperado: Mensaje "El día ingresado no es válido"
DECLARE @id_natacion INT;
SELECT @id_natacion = id_actividad FROM eSocios.Actividad WHERE nombre = 'Natación adultos';
EXEC eSocios.agregarHorarioActividad 
    @id_actividad = @id_natacion,
    @dia = 'feriado',
    @hora_inicio = '12:00',
    @hora_fin = '13:00';
GO

PRINT '=== CASO 3: Horario duplicado para mismo día y hora_inicio ===';
-- Esperado: Mensaje "Ese horario ya está asignado a la actividad"
DECLARE @id_natacion INT;
SELECT @id_natacion = id_actividad FROM eSocios.Actividad WHERE nombre = 'Natación adultos';
EXEC eSocios.agregarHorarioActividad 
    @id_actividad = @id_natacion,
    @dia = 'lunes',
    @hora_inicio = '10:00',
    @hora_fin = '11:30';
GO

SELECT 'agregarHorarioActividad'
SELECT * 
FROM eSocios.ActividadDiaHorario adh
RIGHT JOIN eSocios.Actividad ac ON ac.id_actividad = adh.id_actividad
GO


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.eliminarHorarioActividad
-- ==========================================';
GO

PRINT '=== CASO 1: Eliminar horario existente ===';
-- Esperado: Eliminación correcta
DECLARE @id_natacion INT;
SELECT @id_natacion = id_actividad FROM eSocios.Actividad WHERE nombre = 'Natación adultos';
EXEC eSocios.eliminarHorarioActividad 
    @id_actividad = @id_natacion,
    @dia = 'lunes',
    @hora_inicio = '10:00';
GO

PRINT '=== CASO 2: Eliminar horario que no existe ===';
-- Esperado: RAISERROR "El horario no existe para esa actividad"
DECLARE @id_natacion INT;
SELECT @id_natacion = id_actividad FROM eSocios.Actividad WHERE nombre = 'Natación adultos';
EXEC eSocios.eliminarHorarioActividad 
    @id_actividad = @id_natacion,
    @dia = 'lunes',
    @hora_inicio = '15:00';
GO


SELECT 'eliminarHorarioActividad'
SELECT * 
FROM eSocios.ActividadDiaHorario adh
RIGHT JOIN eSocios.Actividad ac ON ac.id_actividad = adh.id_actividad
GO


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.eliminarActividad
-- ==========================================';
GO

PRINT '=== CASO 1: Eliminar actividad sin inscriptos ni horarios ===';
-- Esperado: Eliminación exitosa
-- Primero creamos una actividad sin relaciones
DECLARE @fechaFutura DATE = DATEADD(MONTH, 3, GETDATE());
EXEC eSocios.crearActividad 
    @nombre = 'Pilates',
    @costo_mensual = 3200,
    @vigencia = @fechaFutura;

SELECT 'eliminarActividad'
SELECT * 
FROM eSocios.ActividadDiaHorario adh
RIGHT JOIN eSocios.Actividad ac ON ac.id_actividad = adh.id_actividad

DECLARE @id_pilates INT;
SELECT @id_pilates = id_actividad FROM eSocios.Actividad WHERE nombre = 'Pilates';

EXEC eSocios.eliminarActividad @id_actividad = @id_pilates;
GO

PRINT '=== CASO 2: Eliminar actividad con horario asignado ===';
-- Esperado: Mensaje "No se puede eliminar la actividad porque tiene horarios asignados"
EXEC eSocios.eliminarActividad @id_actividad = 2;
GO

SELECT * 
FROM eSocios.ActividadDiaHorario adh
RIGHT JOIN eSocios.Actividad ac ON ac.id_actividad = adh.id_actividad
GO


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.inscribirActividad
-- ==========================================';
GO

PRINT '=== CASO 1: Inscribir socio activo en actividad existente ===';
-- Esperado: Inserción exitosa en eSocios.Realiza

-- Insertar socio activo
INSERT INTO eSocios.Socio 
(
    id_socio, id_categoria, dni, nombre, apellido, fecha_nac, activo
)
VALUES 
(
    'AC-001', 1, 34123456, 'Agustin', 'Crespo', '2000-03-15', 1
);

EXEC eSocios.inscribirActividad 
    @id_socio = 'AC-001',
    @id_actividad = 2;

EXEC eSocios.inscribirActividad 
    @id_socio = 'AC-001',
    @id_actividad = 1;
GO


PRINT '=== CASO 2: Socio ya inscripto en la actividad ===';
-- Esperado: Mensaje de advertencia
EXEC eSocios.inscribirActividad 
    @id_socio =  'AC-001',
    @id_actividad = 2;
GO

PRINT '=== CASO 3: Socio inexistente o inactivo ===';
-- Esperado: "El socio no existe o está inactivo"
EXEC eSocios.inscribirActividad 
    @id_socio = 'ZZ-999',
    @id_actividad = 1;
GO

PRINT '=== CASO 4: Actividad inexistente ===';
-- Esperado: "La actividad no existe"
EXEC eSocios.inscribirActividad 
    @id_socio =  'AC-001',
    @id_actividad = 9999;
GO

SELECT 'inscribirActividad'
SELECT * FROM eSocios.Realiza
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.desinscribirActividad
-- ==========================================';
GO

PRINT '=== CASO 1: Desinscribir socio inscripto en actividad ===';
-- Esperado: Eliminación de la inscripción
EXEC eSocios.desinscribirActividad 
    @id_socio = 'AC-001',
    @id_actividad = 2;
GO

PRINT '=== CASO 2: Socio no inscripto en la actividad ===';
-- Esperado: Mensaje "El socio no existe o no está inscripto en esa actividad"
EXEC eSocios.desinscribirActividad 
    @id_socio = 'AA-001',
    @id_actividad = 1;
GO

SELECT 'desinscribirActividad'
SELECT * FROM eSocios.Realiza
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.registrarPresentismo
-- ==========================================';
GO


PRINT '=== CASO 1: Registrar presentismo válido ===';
-- Esperado: Registro exitoso

-- Prepara inscripciones válidas
EXEC eSocios.inscribirActividad 
    @id_socio = 'AC-001',
    @id_actividad = 2;

EXEC eSocios.registrarPresentismo 
    @id_socio = 'AC-001',
    @id_actividad = 2,
    @asistencia = 'Sí',
    @profesor = 'JRGONZALEZ';
GO

PRINT '=== CASO 2: Registrar presentismo duplicado ===';
-- Esperado: Mensaje de advertencia de duplicado
EXEC eSocios.registrarPresentismo 
    @id_socio = 'AC-001',
    @id_actividad = 2,
    @asistencia = 'Sí',
    @profesor = 'JRGONZALEZ';
GO

PRINT '=== CASO 3: Socio inexistente ===';
-- Esperado: Error "El socio especificado no existe"
EXEC eSocios.registrarPresentismo 
    @id_socio = 'NO-EXISTE',
    @id_actividad = 1,
    @asistencia = 'Sí',
    @profesor = 'JRGONZALEZ';
GO

PRINT '=== CASO 4: Actividad inexistente ===';
-- Esperado: Error "La actividad especificada no existe"
EXEC eSocios.registrarPresentismo 
    @id_socio = 'AC-001',
    @id_actividad = 9999,
    @asistencia = 'Sí',
    @profesor = 'JRGONZALEZ';
GO


SELECT 'registrarPresentismo'
SELECT * FROM eSocios.Presentismo
GO



PRINT '=== TODAS LAS PRUEBAS COMPLETADAS ===';

PRINT '
=== INICIANDO LIMPIEZA DE DATOS ===';


DELETE FROM eSocios.Realiza;
DELETE FROM eSocios.Presentismo;
DELETE FROM eSocios.ActividadDiaHorario;
DELETE FROM eSocios.Actividad;
DELETE FROM eSocios.Socio;
DELETE FROM eSocios.Categoria;

-- Reiniciar identidades
DBCC CHECKIDENT ('eSocios.Actividad', RESEED, 0);
DBCC CHECKIDENT ('eSocios.Categoria', RESEED, 0);

PRINT '
=== LIMPIEZA COMPLETADA - SISTEMA LISTO PARA NUEVAS PRUEBAS ==='; 
