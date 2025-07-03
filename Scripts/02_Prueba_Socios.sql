
-- ===================================================================
-- CASOS DE USO PARA STORED PROCEDURES eSocios
-- ===================================================================
USE Com5600G10
GO

-- ===================================================================
-- SETUP INICIAL - Datos necesarios para las pruebas
-- ===================================================================
SET NOCOUNT ON

--categorias
INSERT INTO eSocios.Categoria (nombre, costo_mensual, Vigencia)
VALUES ('Menor', 1000, GETDATE()), ('Cadete', 1500, GETDATE()), ('Mayor', 2000, GETDATE());
GO


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.insertarSocio
-- ==========================================';
GO

PRINT '=== CASO 1: Insertar socio mayor de edad (sin tutor) ===';
-- ==========================================
-- Esperado: Inserción correcta, categoría = "Mayor"
-- ==========================================
EXEC eSocios.insertarSocio
    @id_socio = 'MM-001',
    @dni = 30111222,
    @nombre = 'Martin',
    @apellido = 'Medina',
    @email = 'martin.medina@example.com',
    @fecha_nac = '1990-02-15';
GO


PRINT '=== CASO 2: Insertar socio menor de edad con tutor existente===';
-- ==========================================
-- Esperado: Inserción correcta. Tutor vinculado sin descuento.
-- ==========================================
-- Agregar tutor
INSERT INTO eSocios.Tutor (id_tutor, nombre, apellido, DNI, email, fecha_nac, telefono)
VALUES ('TUT-001', 'Laura', 'Ruiz', 45221123, 'laura.ruiz@example.com', '1980-10-10', 1166778899);

EXEC eSocios.insertarSocio
    @id_socio = 'NN-002',
    @dni = 40888999,
    @nombre = 'Nicolas',
    @apellido = 'Ruiz',
    @email = 'nicolas.ruiz@example.com',
    @fecha_nac = '2015-07-01',
    @id_tutor = 'TUT-001',
    @parentesco = 'Hijo';
GO


PRINT '=== CASO 3: Insertar segundo hijo del mismo tutor (se activa descuento) ===';
-- ==========================================
-- Esperado: Ambos socios con descuento 15 en grupo familiar
-- ==========================================
EXEC eSocios.insertarSocio
    @id_socio = 'NN-003',
    @dni = 40888998,
    @nombre = 'Sofía',
    @apellido = 'Ruiz',
    @email = 'sofia.ruiz@example.com',
    @fecha_nac = '2013-03-15',
    @id_tutor = 'TUT-001',
    @parentesco = 'Hija';
GO


PRINT '=== CASO 4: DNI Duplicado ===';
-- ==========================================
-- Esperado: Error por DNI Duplicado
-- ==========================================
EXEC eSocios.insertarSocio
    @id_socio = 'AD-002',
    @dni = 30111222,  -- DNI repetido
    @nombre = 'Alberto',
    @apellido = 'Díaz',
    @email = 'alberto.diaz@example.com',
    @fecha_nac = '1992-04-30';
GO


PRINT '=== CASO 5: Menor sin Tutor ===';
-- ==========================================
-- Esperado: Error por Tutor no ingresado
-- ==========================================
EXEC eSocios.insertarSocio
    @id_socio = 'PE-001',
    @dni = 50123456,
    @nombre = 'Pedro',
    @apellido = 'Espinoza',
    @email = 'pedro@school.com',
    @fecha_nac = '2016-09-05';  -- 7 años (requiere tutor)
GO


PRINT '=== CASO 6: Tutor inexistente ===';
-- ==========================================
-- Esperado: Error por Tutor inexistente
-- ==========================================
EXEC eSocios.insertarSocio
    @id_socio = 'PE-001',
    @dni = 50123456,
    @nombre = 'Pedro',
    @apellido = 'Espinoza',
    @email = 'pedro@school.com',
    @fecha_nac = '2016-09-05',
	@id_tutor = 'TUT-99';  -- Tutor que no existe

GO

SELECT 'insertarSocio'
SELECT * FROM eSocios.Socio
SELECT * FROM eSocios.GrupoFamiliar
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.modificarSocio
-- ==========================================';
GO

PRINT '=== CASO 1: Modificar socio existente cambiando datos personales ===';
-- ==========================================
-- Esperado: Actualización de datos con éxito, incluido cambio de email
-- ==========================================
-- Requiere ID de categoría existente
DECLARE @id_cat INT;
SELECT TOP 1 @id_cat = id_categoria FROM eSocios.Categoria WHERE nombre = 'Mayor' ORDER BY vigencia DESC;

EXEC eSocios.modificarSocio
    @id_socio = 'MM-001',
    @id_categoria = @id_cat,
    @dni = 30111222,
    @nombre = 'Martin Leonardo',
    @apellido = 'Medina',
    @email = 'ml.medina@example.com',
    @fecha_nac = '1990-02-15',
    @telefono = 1199887766,
    @telefono_emergencia = 1177998877,
    @obra_social = 'Swiss Medical',
    @nro_obra_social = '998877',
    @tel_obra_social = 99887766;
GO

PRINT '=== CASO 2: Modificar socio con DNI duplicado (espera error) ===';
-- ==========================================
-- Esperado: Mensaje de error por DNI repetido
-- ==========================================
DECLARE @id_cat INT;
SELECT TOP 1 @id_cat = id_categoria FROM eSocios.Categoria WHERE nombre = 'Cadete' ORDER BY vigencia DESC;

EXEC eSocios.modificarSocio
    @id_socio = 'NN-003',
    @id_categoria = @id_cat,
    @dni = 30111222, -- mismo que 'MM-001'
    @nombre = 'Sofía',
    @apellido = 'Ruiz',
    @email = 'sofia.cambio@example.com',
    @fecha_nac = '2013-03-15',
    @telefono = 1199776655,
    @telefono_emergencia = 1177998877,
    @obra_social = 'IOMA',
    @nro_obra_social = '334456',
    @tel_obra_social = 99887766;
GO

SELECT 'modificarSocio'
SELECT * FROM eSocios.Socio
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.eliminarSocio
-- ==========================================';
GO

PRINT '=== CASO 1: Dar de baja a un socio ===';
-- ==========================================
-- Esperado: Cambio del campo "activo" a 0
-- ==========================================
EXEC eSocios.eliminarSocio @id_socio = 'NN-002';
GO

PRINT '=== CASO 2: Intentar dar de baja a un socio inexistente ===';
-- ==========================================
-- Esperado: Mensaje de "El socio no existe"
-- ==========================================
EXEC eSocios.eliminarSocio @id_socio = 'XX-999';
GO

SELECT 'eliminarSocio'
SELECT id_socio, id_categoria, dni, nombre, apellido, email, fecha_nac, activo FROM eSocios.Socio
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.agregarTutor
-- ==========================================';
GO

PRINT '=== CASO 1: Agregar tutor nuevo ===';
-- Esperado: Tutor agregado correctamente.
EXEC eSocios.agregarTutor 
    @id_tutor = 'TUT-002', 
    @nombre = 'Carlos', 
    @apellido = 'Sosa', 
    @DNI = 45678901, 
    @email = 'carlos.sosa@example.com', 
    @fecha_nac = '1980-06-10', 
    @telefono = 1122334455;

EXEC eSocios.agregarTutor 
    @id_tutor = 'TUT-003', 
    @nombre = 'Mario', 
    @apellido = 'Gómez', 
    @DNI = 50987654, 
    @email = 'mario.gomez@example.com', 
    @fecha_nac = '1985-12-01', 
    @telefono = 1155778899;
GO

PRINT '=== CASO 2: Tutor duplicado (por DNI) ===';
-- Esperado: Error: Ya existe un tutor con ese ID, DNI o email.
EXEC eSocios.agregarTutor 
    @id_tutor = 'TUT-004', 
    @nombre = 'César', 
    @apellido = 'Sánchez', 
    @DNI = 45678901,  -- Duplicado
    @email = 'cesar.sanchez@example.com', 
    @fecha_nac = '1975-03-20', 
    @telefono = 1133445566;
GO


SELECT 'agregarTutor'
SELECT * FROM eSocios.Tutor
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.modificarTutor
-- ==========================================';
GO

PRINT '=== CASO 1: Modificar tutor existente ===';
-- Esperado: Tutor modificado correctamente.
EXEC eSocios.modificarTutor 
    @id_tutor = 'TUT-002', 
    @nombre = 'Carlos Andrés', 
    @apellido = 'Sosa', 
    @DNI = 45678901, 
    @email = 'carlos.andres.sosa@example.com', 
    @fecha_nac = '1980-06-10', 
    @telefono = 1199881122;
GO

PRINT '=== CASO 2: DNI o email ya en uso por otro tutor ===';
-- Esperado: Error: El DNI o el email ya están en uso por otro tutor.
EXEC eSocios.modificarTutor 
    @id_tutor = 'TUT-002', 
    @nombre = 'Carlos A.', 
    @apellido = 'Sosa', 
    @DNI = 50987654,  -- Usado por T-200
    @email = 'mario.gomez@example.com',  -- También en uso
    @fecha_nac = '1980-06-10', 
    @telefono = 1144556677;
GO

SELECT 'modificarTutor'
SELECT * FROM eSocios.Tutor
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.eliminarTutor
-- ==========================================';
GO

PRINT '=== CASO 1: Eliminar tutor sin vínculos familiares ===';
-- Esperado: Tutor eliminado correctamente.
EXEC eSocios.eliminarTutor @id_tutor = 'TUT-003';
GO

PRINT '=== CASO 2: Eliminar tutor con socios asociados ===';
-- Esperado: Error: No se puede eliminar el tutor porque tiene socios vinculados.
EXEC eSocios.eliminarTutor @id_tutor = 'TUT-001';
GO

SELECT 'eliminarTutor'
SELECT * FROM eSocios.Tutor
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.agregarAGrupoFamiliar
-- ==========================================';
GO

PRINT '=== CASO 1: Agregar primer socio al grupo (sin descuento) ===';
-- Esperado: Se asigna descuento 0.

EXEC eSocios.insertarSocio
    @id_socio = 'BB-222',
    @dni = 20111444,
    @nombre = 'Franco',
    @apellido = 'Gonzalez',
    @email = 'fran.gonz@example.com',
    @fecha_nac = '2001-05-01';

EXEC eSocios.agregarAGrupoFamiliar 
    @id_socio = 'BB-222',
    @id_tutor = 'TUT-002',
    @parentesco = 'Hijo';
SELECT 'agregarAGrupoFamiliar'
SELECT * FROM eSocios.GrupoFamiliar
WHERE id_tutor ='TUT-002'
GO



PRINT '=== CASO 2: Agregar segundo socio (descuento aplicado a ambos) ===';
-- Esperado: Se aplica 15% de descuento a los dos socios del tutor.
-- Primero, inserta otro socio
EXEC eSocios.insertarSocio
    @id_socio = 'BB-333',
    @dni = 20111555,
    @nombre = 'Sebastián',
    @apellido = 'Gonzalez',
    @email = 'sebastian.gonz@example.com',
    @fecha_nac = '2003-01-01';

EXEC eSocios.agregarAGrupoFamiliar 
    @id_socio = 'BB-333',
    @id_tutor = 'TUT-002',
    @parentesco = 'Hijo';
GO

PRINT '=== CASO 3: Socio ya tiene grupo familiar ===';
-- Esperado: Mensaje de error
EXEC eSocios.agregarAGrupoFamiliar 
    @id_socio = 'BB-333',
    @id_tutor = 'TUT-002',
    @parentesco = 'Hijo';
GO


SELECT * FROM eSocios.GrupoFamiliar
WHERE id_tutor ='TUT-002'
GO


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eSocios.sacarDeGrupoFamiliar
-- ==========================================';
GO

PRINT '=== CASO 1: Remover socio de grupo familiar con más de un integrante ===';
EXEC eSocios.insertarSocio
    @id_socio = 'BB-444',
    @dni = 40222555,
    @nombre = 'Leo',
    @apellido = 'Gonzalez',
    @email = 'leo.gonz@example.com',
    @fecha_nac = '1998-01-04';

EXEC eSocios.agregarAGrupoFamiliar 
    @id_socio = 'BB-444',
    @id_tutor = 'TUT-002',
    @parentesco = 'Hijo';

SELECT 'sacarDeGrupoFamiliar'
SELECT * FROM eSocios.GrupoFamiliar
WHERE id_tutor ='TUT-002'

EXEC eSocios.sacarDeGrupoFamiliar @id_socio = 'BB-333';
GO



PRINT '=== CASO 2: Remover último socio del grupo familiar ===';
-- Esperado: El descuento del único socio restante se elimina.
EXEC eSocios.sacarDeGrupoFamiliar @id_socio = 'BB-444';
GO


PRINT '=== CASO 3: Intentar remover socio que no pertenece a grupo familiar ===';
-- Esperado: Mensaje de que no pertenece a ningún grupo familiar.
EXEC eSocios.sacarDeGrupoFamiliar @id_socio = 'NN-001';
GO


SELECT * FROM eSocios.GrupoFamiliar
WHERE id_tutor ='TUT-002'
GO


PRINT '=== PRUEBAS COMPLETADAS ===';


PRINT '=== INICIANDO LIMPIEZA DE DATOS ===';

-- Deshabilitar restricciones de clave foránea temporalmente para facilitar la limpieza
EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";


    
    
    -- 1. Eliminar socios
    DELETE FROM eSocios.Socio;
    PRINT 'Eliminados todos los socios (Socio)';

	-- 2. Eliminar tutores
    DELETE FROM eSocios.Tutor;
    PRINT 'Eliminados todos los tutores (Tutor)';

    -- 3. Eliminar grupos familiares (si existe la tabla y no tiene referencias)
    IF OBJECT_ID('eSocios.GrupoFamiliar', 'U') IS NOT NULL
    BEGIN
        DELETE FROM eSocios.GrupoFamiliar;
        PRINT 'Eliminados todos los grupos familiares (GrupoFamiliar)';
    END
	-- 4. Eliminar Categorias
	DELETE FROM eSocios.Categoria;
    PRINT 'Eliminados todas los categorias (Categoria)';
    
    IF OBJECT_ID('eSocios.Categoria', 'U') IS NOT NULL
        DBCC CHECKIDENT ('eSocios.Categoria', RESEED, 0);
    
    

-- Rehabilitar las restricciones de clave foránea
EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";
GO
PRINT '
=== LIMPIEZA COMPLETADA - SISTEMA LISTO PARA NUEVAS PRUEBAS ==='; 