/*
Entrega 7 - Creacion de usuarios.
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

USE Com5600G10
GO

-- =========================================================================

			-- CASOS DE PRUEBA - STORED PROCEDURES DE USUARIOS--

-- =========================================================================


-- =========================================================================
--			  --PRIMERO CREO USUARIOS INICIALES PARA CADA ROL--
-- =========================================================================

-- Usuario para JefeTesoreria
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'JefeTesoreria',
    @nombre_usuario = 'jefe_tesoreria01',
    @clave = 'Password123!',
    @vigencia_dias = 90;

-- Usuario para AdministrativoCobranza
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'AdministrativoCobranza',
    @nombre_usuario = 'admin_cobranza01',
    @clave = 'SecurePass456@',
    @vigencia_dias = 90;

-- Usuario para AdministrativoMorosidad
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'AdministrativoMorosidad',
    @nombre_usuario = 'admin_morosidad01',
    @clave = 'StrongPwd789#',
    @vigencia_dias = 90;

-- Usuario para AdministrativoFacturacion
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'AdministrativoFacturacion',
    @nombre_usuario = 'admin_facturacion01',
    @clave = 'ComplexPass012$',
    @vigencia_dias = 90;

-- Usuario para AdministrativoSocio
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'AdministrativoSocio',
    @nombre_usuario = 'admin_socio01',
    @clave = 'ValidPass345%',
    @vigencia_dias = 90;

-- Usuario para SociosWeb
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'SociosWeb',
    @nombre_usuario = 'socio_web01',
    @clave = 'WebPass678&',
    @vigencia_dias = 90;

-- Usuario para Presidente
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'Presidente',
    @nombre_usuario = 'presidente01',
    @clave = 'PresPass901*',
    @vigencia_dias = 90;

-- Usuario para Vicepresidente
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'Vicepresidente',
    @nombre_usuario = 'vicepresidente01',
    @clave = 'VicePass234+',
    @vigencia_dias = 90;

-- Usuario para Secretario
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'Secretario',
    @nombre_usuario = 'secretario01',
    @clave = 'SecretPass567-',
    @vigencia_dias = 90;

-- Usuario para Vocales
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'Vocales',
    @nombre_usuario = 'vocal01',
    @clave = 'VocalPass890=',
    @vigencia_dias = 90;
GO

-- =========================================================================
--			      CASOS DE PRUEBA SP: CrearUsuario
-- =========================================================================

-- TEST 1: Crear usuario con parámetros válidos
-- Resultado esperado: Usuario creado exitosamente
EXEC eAdministrativos.CrearUsuario 
    @rol = 'JefeTesoreria',
    @nombre_usuario = 'test_usuario_valido',
    @clave = 'TestPass123!',
    @vigencia_dias = 90;
GO

-- TEST 2: Intentar crear usuario con nombre duplicado
-- Resultado esperado: Error "El nombre de usuario ya existe."
EXEC eAdministrativos.CrearUsuario 
    @rol = 'JefeTesoreria',
    @nombre_usuario = 'test_usuario_valido', -- Nombre duplicado
    @clave = 'TestPass456@',
    @vigencia_dias = 90;
GO

-- TEST 3: Crear usuario con contraseña inválida (muy corta)
-- Resultado esperado: Error sobre formato de contraseña
EXEC eAdministrativos.CrearUsuario 
    @rol = 'JefeTesoreria',
    @nombre_usuario = 'test_password_corta',
    @clave = 'Pass1!', -- Muy corta
    @vigencia_dias = 90;
GO

-- TEST 4: Crear usuario con rol inexistente
-- Resultado esperado: Error "El rol especificado no existe."
EXEC eAdministrativos.CrearUsuario 
    @rol = 'RolInexistente',
    @nombre_usuario = 'test_rol_inexistente',
    @clave = 'TestPass123!',
    @vigencia_dias = 90;
GO


-- =========================================================================
--			   CASOS DE PRUEBA SP: ModificarUsuario
-- =========================================================================

-- Primero obtenemos los IDs de algunos usuarios para las pruebas

-- TEST 1: Modificar rol de usuario existente
-- Resultado esperado: Usuario modificado exitosamente
DECLARE @id_test INT = (SELECT id_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = 'test_usuario_valido');
EXEC eAdministrativos.ModificarUsuario 
    @id_usuario = @id_test,
    @nuevo_rol = 'AdministrativoMorosidad';
GO

-- TEST 2: Modificar nombre de usuario existente
-- Resultado esperado: Usuario modificado exitosamente
DECLARE @id_test2 INT = (SELECT id_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = 'test_usuario_valido');
EXEC eAdministrativos.ModificarUsuario 
    @id_usuario = @id_test2,
    @nuevo_nombre_usuario = 'test_usuario_valido_renamed';
GO

-- TEST 3: Modificar contraseña de usuario existente
-- Resultado esperado: Usuario modificado exitosamente
DECLARE @id_test3 INT = (SELECT id_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = 'test_usuario_valido_renamed');
EXEC eAdministrativos.ModificarUsuario 
    @id_usuario = @id_test3,
    @nueva_clave = 'NewSecurePass123!',
    @vigencia_dias = 120;
GO


-- TEST 4: Modificar múltiples campos a la vez
-- Resultado esperado: Usuario modificado exitosamente
DECLARE @id_test4 INT = (SELECT id_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = 'admin_cobranza01');
EXEC eAdministrativos.ModificarUsuario 
    @id_usuario = @id_test4,
    @nuevo_rol = 'AdministrativoFacturacion',
    @nuevo_nombre_usuario = 'admin_facturacion_modified',
    @nueva_clave = 'ModifiedPass456@',
    @vigencia_dias = 180;
GO

-- TEST 5: Intentar modificar usuario inexistente
-- Resultado esperado: Error "No existe usuario con ese ID."
EXEC eAdministrativos.ModificarUsuario 
    @id_usuario = 9999, -- ID inexistente
    @nuevo_rol = 'JefeTesoreria';
GO

-- TEST 6: Intentar modificar sin especificar ningún campo
-- Resultado esperado: Error "Debe especificar al menos un campo para modificar."
DECLARE @id_test5 INT = (SELECT id_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = 'jefe_tesoreria01');
EXEC eAdministrativos.ModificarUsuario 
    @id_usuario = @id_test5;
GO

-- TEST 7: Intentar cambiar a nombre de usuario que ya existe
-- Resultado esperado: Error "El nombre de usuario ya está en uso."
DECLARE @id_test6 INT = (SELECT id_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = 'admin_morosidad01');
EXEC eAdministrativos.ModificarUsuario 
    @id_usuario = @id_test6,
    @nuevo_nombre_usuario = 'presidente01'; -- Nombre ya existente
GO

-- TEST 8: Intentar cambiar a contraseña inválida
-- Resultado esperado: Error sobre formato de contraseña
DECLARE @id_test7 INT = (SELECT id_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = 'admin_socio01');
EXEC eAdministrativos.ModificarUsuario 
    @id_usuario = @id_test7,
    @nueva_clave = 'weak'; -- Contraseña inválida
GO

-- TEST 9: Intentar cambiar a rol inexistente
-- Resultado esperado: Error "El rol especificado no existe."
DECLARE @id_test8 INT = (SELECT id_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = 'secretario01');
EXEC eAdministrativos.ModificarUsuario 
    @id_usuario = @id_test8,
    @nuevo_rol = 'RolInexistente';
GO


-- =========================================================================
--			  CASOS DE PRUEBA SP: EliminarUsuario
-- =========================================================================

-- TEST 1: Eliminar usuario existente
-- Resultado esperado: Usuario eliminado exitosamente
DECLARE @id_eliminar INT = (SELECT id_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = 'test_usuario_valido_renamed');
EXEC eAdministrativos.EliminarUsuario @id_usuario = @id_eliminar;
GO

-- TEST 2: Intentar eliminar usuario inexistente
-- Resultado esperado: Error "El usuario no existe."
EXEC eAdministrativos.EliminarUsuario @id_usuario = 9999;
GO

SELECT * FROM eAdministrativos.UsuarioAdministrativo