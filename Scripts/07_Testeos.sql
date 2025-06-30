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

-- ================================
-- TEST 1: Crear usuario válido
-- Resultado esperado: Usuario creado con éxito.
-- ================================

use Com5600G10
go

EXEC eAdministrativos.CrearUsuario
    @rol = 'AdministrativoSocio',
    @nombre_usuario = 'juan_socio10',
    @clave = 'Cl@veSegura123',
    @vigencia_dias = 90;
GO

-- ================================
-- TEST 2: Crear usuario duplicado
-- Resultado esperado: Error 'El nombre de usuario ya existe.'
-- ================================
EXEC eAdministrativos.CrearUsuario
    @rol = 'AdministrativoSocio',
    @nombre_usuario = 'juan_socio10',
    @clave = 'OtraCl@ve123',
    @vigencia_dias = 90;
GO

-- ================================
-- TEST 3: Crear usuario con clave débil
-- Resultado esperado: Error por formato de contraseña inválido.
-- ================================
EXEC eAdministrativos.CrearUsuario
    @rol = 'AdministrativoSocio',
    @nombre_usuario = 'clave_invalida2',
    @clave = '12345678',
    @vigencia_dias = 90;
GO


-- ================================
-- TEST 4: Crear usuario con rol inexistente
-- Resultado esperado: Error 'El rol especificado no existe.'
-- ================================
EXEC eAdministrativos.CrearUsuario
    @rol = 'RolInexistente',
    @nombre_usuario = 'usuario_rol_fail',
    @clave = 'Cl@veSegura123',
    @vigencia_dias = 90;
GO

-- ================================
-- TEST 5: Modificar usuario correctamente
-- Resultado esperado: Usuario modificado con éxito.
-- ================================
-- Supone que el ID 1 corresponde al usuario creado en el primer test.
EXEC eAdministrativos.ModificarUsuario
    @id_usuario = 5,
    @rol = 'AdministrativoSocio',
    @nombre_usuario = 'juan_socio_actualizado',
    @clave = 'Nuev@Clav3Segura',
    @vigencia_dias = 60;
GO


-- ================================
-- TEST 6: Modificar usuario inexistente
-- Resultado esperado: Error 'No existe usuario con ese ID.'
-- ================================
EXEC eAdministrativos.ModificarUsuario
    @id_usuario = 9999,
    @rol = 'AdministrativoSocio',
    @nombre_usuario = 'no_existe',
    @clave = 'Cl@veSegura123',
    @vigencia_dias = 90;
GO

-- ================================
-- TEST 7: Modificar usuario con nombre repetido
-- Resultado esperado: Error 'El nombre de usuario ya está en uso.'
-- ================================
EXEC eAdministrativos.CrearUsuario
    @rol = 'AdministrativoSocio',
    @nombre_usuario = 'juan_socio1',
    @clave = 'TempCl@ve123!',
    @vigencia_dias = 90;
GO

-- ================================
-- TEST 8: Intentamos modificar ese usuario con el nombre de otro ya existente
--Resultado esperado: 'El nombre de usuario ya está en uso'
-- ================================
EXEC eAdministrativos.ModificarUsuario
    @id_usuario = 2,
    @rol = 'AdministrativoSocio',
    @nombre_usuario = 'juan_socio_actualizado', -- ya existe
    @clave = 'OtraCl@ve456!',
    @vigencia_dias = 30;
GO