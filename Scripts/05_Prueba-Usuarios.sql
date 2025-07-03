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

USE Com5600G10
GO

-- =========================
-- TEST: Crear un nuevo usuario v�lido
-- Resultado esperado: Inserci�n exitosa
-- =========================
EXEC eAdministrativos.CrearUsuario
    @rol = 'auxiliar',
    @nombre_usuario = 'aux_2',
    @clave = '12345',
    @vigencia_dias = 90;
GO


-- =========================
-- TEST: Crear usuario duplicado
-- Resultado esperado: Error - El nombre de usuario ya existe
-- =========================
EXEC eAdministrativos.CrearUsuario
    @rol = 'auxiliar',
    @nombre_usuario = 'aux_1',
    @clave = 'abc321',
    @vigencia_dias = 90;
GO

SELECT * FROM eAdministrativos.UsuarioAdministrativo


-- =========================
-- TEST: Modificar usuario existente
-- Resultado esperado: Actualizaci�n exitosa
-- =========================
EXEC eAdministrativos.ModificarUsuario
    @id_usuario = 1, -- asumimos que se cre� con ID 1
    @rol = 'cajero',
    @nombre_usuario = 'admin_modificado',
    @clave = 'claveNueva',
    @vigencia_dias = 60;
GO


-- =========================
-- TEST: Modificar usuario inexistente
-- Resultado esperado: Error - No existe usuario con ese ID
-- =========================
EXEC eAdministrativos.ModificarUsuario
    @id_usuario = 9999,
    @rol = 'admin',
    @nombre_usuario = 'usuario_inexistente',
    @clave = 'clave',
    @vigencia_dias = 60;
GO

-- =========================
-- TEST: Eliminar usuario
-- Resultado esperado: Eliminaci�n exitosa
-- =========================
EXEC eAdministrativos.EliminarUsuario
    @id_usuario = 3;
GO


-- =========================
-- TEST: Eliminar usuario ya eliminado
-- Resultado esperado: Error - El usuario no existe
-- =========================
EXEC eAdministrativos.EliminarUsuario
    @id_usuario = 1;
GO