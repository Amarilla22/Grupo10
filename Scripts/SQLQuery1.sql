-- =========================
-- TEST: Crear un nuevo usuario válido
-- Resultado esperado: Inserción exitosa
-- =========================
EXEC eAdministrativos.CrearUsuario
    @rol = 'auxiliar',
    @nombre_usuario = 'aux_2',
    @clave = '12345',
    @vigencia_dias = 90;
GO


SELECT * FROM eAdministrativos.UsuarioAdministrativo

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
-- Resultado esperado: Actualización exitosa
-- =========================
EXEC eAdministrativos.ModificarUsuario
    @id_usuario = 1, -- asumimos que se creó con ID 1
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
-- Resultado esperado: Eliminación exitosa
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


-- =========================
-- TEST: Crear socio con email inválido
-- Resultado esperado: Error - Formato de email inválido
-- =========================
EXEC eSocios.ModificarSocio
    @id_socio = 1,
    @nombre = 'Juan',
    @apellido = 'Pérez',
    @email = 'correo_invalido',
    @fecha_nac = '2000-01-01',
    @telefono = '1122334455',
    @telefono_emergencia = '1144557788',
    @obra_social = 'OSDE',
    @nro_obra_social = '1234';
GO


-- =========================
-- TEST: Dar de baja socio activo
-- Resultado esperado: Cambio de estado a inactivo
-- =========================
EXEC eSocios.EliminarSocio
    @id_socio = 1;
GO


-- =========================
-- TEST: Dar de baja socio ya inactivo
-- Resultado esperado: Error - Ya fue dado de baja
-- =========================
EXEC eSocios.EliminarSocio
    @id_socio = 1;
GO