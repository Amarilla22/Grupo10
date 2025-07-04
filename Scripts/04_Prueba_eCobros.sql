
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.generarFactura
-- ==========================================
USE Com5600G10
GO
-- ==========================================
-- Insertado de datos previos necesarios
-- ==========================================
SET NOCOUNT ON

--categorias
INSERT INTO eSocios.Categoria (nombre, costo_mensual, Vigencia)
VALUES ('Menor', 100, GETDATE()), ('Cadete', 50, GETDATE()), ('Mayor', 0, GETDATE());

--actividades
INSERT INTO eSocios.Actividad (nombre, costo_mensual, vigencia) VALUES ('Natación', 100, GETDATE());
INSERT INTO eSocios.Actividad (nombre, costo_mensual, vigencia) VALUES ('Fútbol', 0, GETDATE());
INSERT INTO eSocios.Actividad (nombre, costo_mensual, vigencia) VALUES ('Tenis', 50, GETDATE());
GO


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.generarFactura
-- ==========================================';
GO

PRINT '=== CASO 1: Socio sin descuentos ===';
-- ==========================================
-- CASO 1: Socio sin descuentos (una actividad, sin grupo familiar)
-- Esperado: total = membresía + actividad
-- ==========================================

-- socio 1
INSERT INTO eSocios.Socio (id_socio, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES ('AA-111', 3, '10000001', 'Ana', 'Lopez', 'ana@example.com', '1995-05-12', '1111111111', '2222222222', 'IOMA', '123');

-- asignar 1 actividad
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES ('AA-111', 1);

-- generar factura
EXEC eCobros.generarFactura @id_socio = 'AA-111';
GO


PRINT '=== CASO 2: Socio con descuento por múltiples actividades ===';
-- ==========================================
-- CASO 2: Socio con descuento por actividades
-- Esperado: descuento 10% sobre actividades
-- ==========================================

-- socio 2
INSERT INTO eSocios.Socio (id_socio, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES ('BB-222', 3, '20000002', 'Bruno', 'Diaz', 'bruno@example.com', '1990-03-20', '1112223333', '4445556666', 'OSDE', '456');

-- asignar múltiples actividades
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES ('BB-222', 1);
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES ('BB-222', 2);

-- generar factura
EXEC eCobros.generarFactura @id_socio = 'BB-222';
GO


PRINT '=== CASO 3: Socio con descuento familiar ===';
-- ==========================================
-- CASO 3: Socio con descuento por grupo familiar
-- Esperado: descuento 15% sobre membresía
-- ==========================================

-- socio 3
INSERT INTO eSocios.Socio (id_socio, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES ('CC-333', 1, '30000003', 'Carlos', 'Perez', 'carlos@example.com', '2005-07-10', '1122334455', '2233445566', 'SwissMed', '789');

-- crear grupo familiar
INSERT INTO eSocios.Tutor(id_tutor, nombre, apellido, DNI, email, fecha_nac, telefono)
VALUES ('TT-111', 'Gabriel', 'Perez',  '40000004', 'gabriel@example.com', '1980-03-20', '4445556666');
INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco) VALUES ('CC-333', 'TT-111', 15, 'Hijo');

-- asignar una actividad
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES ('CC-333', 2);

-- generar factura
EXEC eCobros.generarFactura @id_socio = 'CC-333';
GO


PRINT '=== CASO 4: Socio con descuentos familiar + actividades ===';
-- ==========================================
-- CASO 4: Socio con ambos descuentos (familiar + actividades)
-- Esperado: 15% sobre membresía y 10% sobre actividades
-- ==========================================

-- socio 4
INSERT INTO eSocios.Socio (id_socio, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES ('DD-444', 1, '40000004', 'Lucas', 'Perez', 'lucas@example.com', '2003-11-23', '1122233344', '1144556677', 'OSDE', '778899');

-- agregar al grupo familiar
INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco) VALUES ('DD-444', 'TT-111', 15, 'Hijo');

-- asignar múltiples actividades al miembro
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES ('DD-444', 1);
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES ('DD-444', 2);

-- generar factura
EXEC eCobros.generarFactura @id_socio = 'DD-444';
GO


PRINT '=== CASO 5: Socio invalido ===';
-- ==========================================
-- CASO 5: Socio invalido
-- ==========================================
EXEC eCobros.generarFactura @id_socio = 'ZZ-999';
GO


SELECT 'generarFactura'
SELECT * FROM eCobros.Factura
SELECT * FROM eCobros.ItemFactura
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.verificarVencimiento
-- ==========================================';
GO

PRINT '=== CASO 1: Aplicación exitosa de recargo tras primer vencimiento ===';

UPDATE eCobros.Factura
SET fecha_emision = DATEADD(DAY, -7, GETDATE()),
    fecha_venc_1 = DATEADD(DAY, -2, GETDATE()),
    fecha_venc_2 = DATEADD(DAY, 3, GETDATE())
WHERE id_factura = 1;

EXEC eCobros.verificarVencimiento @id_factura = 1;
GO


PRINT '=== CASO 2: Recargo ya aplicado anteriormente ===';

EXEC eCobros.verificarVencimiento @id_factura = 1;
GO


PRINT '===CASO 3: Factura no vencida ===';

EXEC eCobros.verificarVencimiento @id_factura = 2;
GO


PRINT '===CASO 4: Factura vencida (pasado segundo vencimiento, socio queda inactivo) ===';
UPDATE eCobros.Factura
SET fecha_emision = DATEADD(DAY, -12, GETDATE()),
    fecha_venc_1 = DATEADD(DAY, -7, GETDATE()),
    fecha_venc_2 = DATEADD(DAY, -2, GETDATE())
	WHERE id_factura = 1;
EXEC eCobros.verificarVencimiento @id_factura = 1;
GO


PRINT '===CASO 5: Factura invalida===';
EXEC eCobros.verificarVencimiento @id_factura = 999;
GO


SELECT 'verificarVencimiento'
SELECT * FROM eCobros.Factura
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.anularFactura
-- ==========================================';
GO

PRINT '=== CASO 1: Anular factura válida existente y activa ===';
-- ==========================================
-- CASO 1: Anular factura válida existente y activa
-- Esperado: estado cambia a 'anulada'
-- ==========================================

EXEC eCobros.anularFactura @id_factura = 2;
GO


PRINT '=== CASO 2: Intentar anular factura ya anulada ===';
-- ==========================================
-- CASO 2: Intentar anular factura que ya está anulada
-- Esperado: mensaje 'la factura no existe o ya esta anulada' y sin cambios
-- ==========================================

-- Ejecutar de nuevo para anular factura 1 que ahora está anulada
EXEC eCobros.anularFactura @id_factura = 2;
GO


PRINT '=== CASO 3: Intentar anular factura inexistente ===';
-- ==========================================
-- CASO 3: Intentar anular factura que no existe
-- Esperado: mensaje 'la factura no existe o ya esta anulada'
-- ==========================================

EXEC eCobros.anularFactura @id_factura = 9999;
GO


SELECT 'anularFactura'
SELECT * FROM eCobros.Factura
WHERE estado = 'anulada'
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.registrarEntradaPileta
-- ==========================================';
GO

--precios de entrada
INSERT INTO eCobros.PreciosAcceso 
(categoria, tipo_usuario, modalidad, precio, vigencia_hasta, activo)
VALUES 
('Adultos', 'Socios', 'Valor del dia', 500.00, DATEADD(DAY, 30, GETDATE()), 1),
('Menores de 12 años', 'Invitados', 'Valor del dia', 800.00, DATEADD(DAY, 30, GETDATE()), 1);

--simular lluvia
INSERT INTO eSocios.ubicaciones (latitud, longitud) VALUES (1,1)

INSERT INTO eSocios.datos_meteorologicos 
(ubicacion_id, fecha_hora, lluvia_mm, humedad_relativa_pct)
VALUES 
(1, '2025-07-01 10:00:00', 5.00, 80);
GO

PRINT '=== CASO 1: Entrada válida tipo socio sin lluvia ===';
-- ==========================================
-- CASO 1: Entrada válida tipo 'socio' sin lluvia
-- Esperado: factura con ítem 'Entrada Pileta - socio' y total correcto
-- ==========================================

EXEC eCobros.registrarEntradaPileta 
    @id_socio = 'CC-333',
    @categoria = 'Adultos',
    @tipo_usuario = 'Socios',
    @modalidad = 'Valor del dia';
GO


PRINT '=== CASO 2: Entrada tipo invitado con lluvia (reembolso) ===';
-- ==========================================
-- CASO 2: Entrada válida tipo 'invitado' con lluvia (reembolso)
-- Esperado: factura con ítem positivo 'Entrada Pileta - invitado' y ítem negativo 'Reembolso Entrada Pileta - invitado'
--           total factura = monto - reembolso
-- ==========================================

EXEC eCobros.registrarEntradaPileta 
    @id_socio = 'BB-222',
	@fecha = '2025-07-01',
    @categoria = 'Menores de 12 años',
    @tipo_usuario = 'Invitados',
    @modalidad = 'Valor del dia';
GO


PRINT '=== CASO 3: Socio inexistente ===';
-- ==========================================
-- CASO 3: Intentar registrar entrada con socio inexistente
-- Esperado: mensaje de error y no se inserta nada
-- ==========================================

EXEC eCobros.registrarEntradaPileta 
    @id_socio = 'ZZ-999',
    @categoria = 'Adultos',
    @tipo_usuario = 'Socios',
    @modalidad = 'Valor del dia';
GO


PRINT '=== CASO 4: Tipo de Precio invalido ===
';
-- ==========================================
-- CASO 4: Intentar registrar entrada con @categoria @tipo_usuario o @modalidad
-- Esperado: mensaje de error y no se inserta nada
-- ==========================================

EXEC eCobros.registrarEntradaPileta 
    @id_socio = 'BB-222',
    @categoria = 'Niños',
    @tipo_usuario = 'Socios',
    @modalidad = 'Valor del dia';
GO


PRINT '=== CASO 5: Socio con cuotas impagas ===
';
-- ==========================================
-- CASO 5: Socio con cuotas impagas (moroso) intentando acceder
-- Esperado: mensaje de error y no se inserta nada
-- ==========================================

EXEC eCobros.registrarEntradaPileta 
    @id_socio = 'AA-111',
    @categoria = 'Adultos',
    @tipo_usuario = 'Socios',
    @modalidad = 'Valor del dia';
GO


SELECT 'registrarEntradaPileta'
SELECT * 
FROM eCobros.ItemFactura
WHERE concepto LIKE 'Entrada Pileta%' OR concepto LIKE 'Reembolso%'
SELECT * 
FROM eCobros.Factura
WHERE id_factura = 5
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.eliminarItemFactura
-- ==========================================';
GO
PRINT '=== CASO 1:  Eliminar ítem válido de factura pendiente ===';

EXEC eCobros.eliminarItemFactura @id_item =14;
GO


PRINT '=== CASO 2: Intentar eliminar ítem de factura anulada o pagada ===';

EXEC eCobros.eliminarItemFactura @id_item = 3;
GO


PRINT '=== CASO 3: Eliminar ítem inexistente ===';

EXEC eCobros.eliminarItemFactura @id_item = 999;
GO

SELECT 'eliminarItemFactura'
SELECT * 
FROM eCobros.ItemFactura
WHERE concepto LIKE 'Entrada Pileta%' OR concepto LIKE 'Reembolso%'
SELECT * 
FROM eCobros.Factura
WHERE id_factura = 5
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.cargarPago
-- =========================================='
GO
PRINT '=== CASO 1: Pago completo exitoso ===';

DECLARE @total_factura DECIMAL(10,2);
SELECT @total_factura = total FROM eCobros.Factura WHERE id_factura = 3;
EXEC eCobros.cargarPago
    @id_factura = 3,
    @medio_pago = 'masterCard',
    @monto = @total_factura;
GO


PRINT '=== CASO 2: Pago parcial ===';
DECLARE @total_factura DECIMAL(10,2);
SELECT @total_factura = total/2 FROM eCobros.Factura WHERE id_factura = 4;
EXEC eCobros.cargarPago
    @id_factura = 4,
    @medio_pago = 'visa',
    @monto =  @total_factura;
GO


PRINT '=== CASO 3: Pago excede lo pendiente ===';
EXEC eCobros.cargarPago
    @id_factura = 4,
    @medio_pago = 'transferencia',
    @monto = 99999;
GO


PRINT '=== CASO 4: Pago sobre factura anulada ===';

EXEC eCobros.cargarPago
    @id_factura = 2,
    @medio_pago = 'efectivo',
    @monto = 500;
GO


PRINT '=== CASO 5: La factura no existe ===';
EXEC eCobros.cargarPago
    @id_factura = 999,
    @medio_pago = 'tarjeta naranja',
    @monto = 5000;
GO


SELECT 'cargarPago'
SELECT * FROM eCobros.Pago
SELECT * FROM eCobros.Factura WHERE estado = 'pagada'
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.anularPago
-- =========================================='
GO

PRINT '=== CASO 1: Anulación válida de pago ===';

EXEC eCobros.anularPago @id_pago = 2;
GO


PRINT '=== CASO 2: Pago ya anulado ===';

EXEC eCobros.anularPago @id_pago = 2;
GO


PRINT '=== CASO 3: Pago inexistente ===';

EXEC eCobros.anularPago @id_pago = 999;
GO


SELECT 'anularPago'
SELECT* FROM eCobros.Pago
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.generarReembolso
-- =========================================='
GO

PRINT '=== CASO 1: Reembolso parcial válido ===
';

DECLARE @monto_pago DECIMAL(10,2);
SELECT @monto_pago = monto/2 FROM eCobros.Pago WHERE id_pago = 1;

EXEC eCobros.generarReembolso
    @id_pago = 1, 
    @monto = @monto_pago,
    @motivo = 'Descuento aplicado incorrectamente';
GO


PRINT '=== CASO 2: Reembolso excede monto del pago (espera error) ===
';

EXEC eCobros.generarReembolso
    @id_pago = 1, 
    @monto = 9999, 
    @motivo = 'Intento incorrecto de reembolso';
GO


PRINT '=== CASO 3: Reembolso total válido ===
';

DECLARE @monto_pago DECIMAL(10,2);
SELECT @monto_pago = monto/2 FROM eCobros.Pago WHERE id_pago = 1;

EXEC eCobros.generarReembolso
    @id_pago = 1, 
    @monto = @monto_pago,
    @motivo = 'Error en el cobro';
GO


PRINT '=== CASO 4: Reembolso sobre pago anulado (espera error) ===';

EXEC eCobros.generarReembolso
    @id_pago = 2,
    @monto = 200.00,
    @motivo = 'No debió cobrarse';
GO


PRINT '=== CASO 5: Reembolso sobre pago inexistente (espera error) ===';

EXEC eCobros.generarReembolso
    @id_pago = 9999, 
    @monto = 100.00,
    @motivo = 'Pago no encontrado';
GO


SELECT 'generarReembolso'
SELECT * FROM eCobros.Reembolso
SELECT * FROM eCobros.Pago
GO




PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.eliminarReembolso
-- =========================================='
GO

PRINT '=== CASO 1: Eliminación exitosa ===';
EXEC eCobros.eliminarReembolso @id_reembolso = 1;
GO


PRINT '=== CASO 2: Reembolso inexistente ===';
EXEC eCobros.eliminarReembolso @id_reembolso = 999999;
GO


SELECT 'eliminarReembolso'
SELECT * FROM eCobros.Reembolso
SELECT * FROM eCobros.Pago
GO



PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.reembolsoComoPagoACuenta
-- ==========================================';
GO


PRINT '=== CASO 1: Reembolso válido como pago a cuenta ===';
-- Esperado: Se registra reembolso y se acredita en saldo del socio
EXEC eCobros.reembolsoComoPagoACuenta
    @id_pago = 1,
    @monto = 100.00,
    @motivo = 'Cancelación de actividad';
GO

PRINT '=== CASO 2: Reembolso excede monto del pago ===';
-- Esperado: Error, se rechaza por superar el total pagado
EXEC eCobros.reembolsoComoPagoACuenta
    @id_pago = 1,
    @monto = 4000.00,
    @motivo = 'Intento excedente';
GO

PRINT '=== CASO 3: Reembolso sobre pago anulado ===';
-- Esperado: Error, no se puede reembolsar un pago anulado
-- Preparamos pago anulado
EXEC eCobros.reembolsoComoPagoACuenta
    @id_pago = 2,
    @monto = 1000.00,
    @motivo = 'Pago anulado';
GO

PRINT '=== CASO 4: Reembolso a pago inexistente ===';
-- Esperado: Error, no existe el pago
EXEC eCobros.reembolsoComoPagoACuenta
    @id_pago = 9999,
    @monto = 500.00,
    @motivo = 'Pago inválido';
GO

SELECT 'reembolsoComoPagoACuenta'
SELECT * FROM eCobros.SaldoSocio;
GO



PRINT '
=== TODAS LAS PRUEBAS COMPLETADAS ===';

-- ====================
-- LIMPIEZA DE DATOS - 
-- ====================

PRINT '
=== INICIANDO LIMPIEZA DE DATOS ===';

DELETE FROM eCobros.SaldoSocio;
DELETE FROM eCobros.Reembolso;
DELETE FROM eCobros.Pago;
DELETE FROM eCobros.PreciosAcceso;
DELETE FROM eCobros.ItemFactura;
DELETE FROM eCobros.Factura;
DELETE FROM eSocios.Realiza;
DELETE FROM eSocios.GrupoFamiliar;
DELETE FROM eSocios.Tutor;
DELETE FROM eSocios.Socio;
DELETE FROM eSocios.Actividad;
DELETE FROM eSocios.Categoria;
DELETE FROM eSocios.datos_meteorologicos;
DELETE FROM eSocios.ubicaciones;



DBCC CHECKIDENT ('eSocios.Actividad', RESEED, 0);
DBCC CHECKIDENT ('eSocios.Categoria', RESEED, 0);
DBCC CHECKIDENT ('eCobros.Factura', RESEED, 0);
DBCC CHECKIDENT ('eCobros.ItemFactura', RESEED, 0);
DBCC CHECKIDENT ('eCobros.PreciosAcceso', RESEED, 0);
DBCC CHECKIDENT ('eCobros.Reembolso', RESEED, 0);
DBCC CHECKIDENT ('eSocios.ubicaciones', RESEED, 0);
DBCC CHECKIDENT ('eSocios.datos_meteorologicos', RESEED, 0);

PRINT '
=== LIMPIEZA COMPLETADA - SISTEMA LISTO PARA NUEVAS PRUEBAS ==='; 
GO
