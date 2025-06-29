
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
INSERT INTO eSocios.Categoria (nombre, costo_mensual)
VALUES ('Menor', 2000), ('Cadete', 3000), ('Mayor', 4000);

--actividades
INSERT INTO eSocios.Actividad (nombre, costo_mensual) VALUES ('Natación', 1500);
INSERT INTO eSocios.Actividad (nombre, costo_mensual) VALUES ('Fútbol', 1800);
INSERT INTO eSocios.Actividad (nombre, costo_mensual) VALUES ('Tenis', 2000);


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.aplicarRecargoSegundoVencimiento
-- ==========================================';
-- ==========================================
-- CASO 1: Socio sin descuentos (una actividad, sin grupo familiar)
-- Esperado: total = membresía + actividad
-- ==========================================
PRINT '
=== CASO 1: Socio sin descuentos ===';

INSERT INTO eSocios.Socio (id_grupo_familiar, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES (NULL, 3, '10000001', 'Ana', 'Lopez', 'ana@example.com', '1995-05-12', '1111111111', '2222222222', 'IOMA', '123');

-- asignar 1 actividad
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES (1, 1);

-- generar factura
EXEC eCobros.generarFactura @id_socio = 1, @periodo = '06/2025', @fecha_emision = '2025-06-01';

-- ==========================================
-- CASO 2: Socio con descuento por actividades
-- Esperado: descuento 10% sobre actividades
-- ==========================================
PRINT '
=== CASO 2: Socio con descuento por múltiples actividades ===';

INSERT INTO eSocios.Socio (id_grupo_familiar, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES (NULL, 3, '20000002', 'Bruno', 'Diaz', 'bruno@example.com', '1990-03-20', '1112223333', '4445556666', 'OSDE', '456');

-- asignar múltiples actividades
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES (2, 1);
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES (2, 2);

-- generar factura
EXEC eCobros.generarFactura @id_socio = 2, @periodo = '06/2025', @fecha_emision = '2025-06-01';

-- ==========================================
-- CASO 3: Socio con descuento por grupo familiar
-- Esperado: descuento 15% sobre membresía
-- ==========================================
PRINT '
=== CASO 3: Socio con descuento familiar ===';

-- socio adulto responsable
INSERT INTO eSocios.Socio (id_grupo_familiar, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES (NULL, 3, '30000003', 'Carlos', 'Perez', 'carlos@example.com', '1980-07-10', '1122334455', '2233445566', 'SwissMed', '789');

-- crear grupo familiar
INSERT INTO eSocios.GrupoFamiliar (id_adulto_responsable, descuento) VALUES (3, 15);

-- asociar socio al grupo
UPDATE eSocios.Socio SET id_grupo_familiar = SCOPE_IDENTITY() WHERE id_socio = 3;

-- asignar una actividad
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES (3, 1);

-- generar factura
EXEC eCobros.generarFactura @id_socio = 3, @periodo = '06/2025', @fecha_emision = '2025-06-01';


-- ==========================================
-- CASO 4: Socio con ambos descuentos (familiar + actividades)
-- Esperado: 15% sobre membresía y 10% sobre actividades
-- ==========================================
PRINT CHAR(10) +'=== CASO 4: Socio con descuentos familiar + actividades ===';

-- socio responsable
INSERT INTO eSocios.Socio (id_grupo_familiar, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES (NULL, 3, '40000004', 'Mario', 'Gonzalez', 'mario@example.com', '1985-11-23', '1122233344', '1144556677', 'OSDE', '778899');

-- crear grupo familiar
INSERT INTO eSocios.GrupoFamiliar (id_adulto_responsable, descuento) VALUES (4, 15);
DECLARE @grupoFamID INT = SCOPE_IDENTITY();
UPDATE eSocios.Socio SET id_grupo_familiar = @grupoFamID WHERE id_socio = 4;

-- nuevo miembro del grupo familiar (socio 5)
INSERT INTO eSocios.Socio (id_grupo_familiar, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES (@grupoFamID, 3, '50000004', 'Lucia', 'Gonzalez', 'lucia@example.com', '1990-06-25', '1112233445', '1122334455', 'SwissMed', '556677');

-- asignar múltiples actividades al miembro
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES (5, 1);
INSERT INTO eSocios.Realiza (socio, id_actividad) VALUES (5, 2);

-- generar factura
EXEC eCobros.generarFactura @id_socio = 5, @periodo = '06/2025', @fecha_emision = '2025-06-01';

SELECT * FROM eCobros.Factura


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.aplicarRecargoSegundoVencimiento
-- ==========================================';

-- ==========================================
-- CASO 1: Aplicación exitosa de recargo tras segundo vencimiento
-- ==========================================
PRINT '
=== CASO 1: Aplicación exitosa de recargo tras segundo vencimiento ===';

UPDATE eCobros.Factura
SET fecha_emision = DATEADD(DAY, -20, GETDATE()),
    fecha_venc_1 = DATEADD(DAY, -15, GETDATE()),
    fecha_venc_2 = DATEADD(DAY, -10, GETDATE())
WHERE id_socio = 1;

EXEC eCobros.aplicarRecargoSegundoVencimiento @id_factura = 1;

-- ==========================================
-- CASO 2: Recargo ya aplicado anteriormente
-- ==========================================
PRINT '
=== CASO 2: Recargo ya aplicado anteriormente ===';

EXEC eCobros.aplicarRecargoSegundoVencimiento @id_factura = 1;

-- ==========================================
-- CASO 3: Factura no vencida
-- ==========================================
PRINT '
===CASO 3: Factura no vencida ===';

UPDATE eCobros.Factura
SET fecha_emision = GETDATE(),
    fecha_venc_1 = DATEADD(DAY, 3, GETDATE()),
    fecha_venc_2 = DATEADD(DAY, 8, GETDATE())
WHERE id_socio = 2;

EXEC eCobros.aplicarRecargoSegundoVencimiento @id_factura = 2;

SELECT * FROM eCobros.Factura


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.anularFactura
-- ==========================================';

-- ==========================================
-- CASO 1: Anular factura válida existente y activa
-- Esperado: estado cambia a 'anulada'
-- ==========================================
PRINT '
=== CASO 1: Anular factura válida existente y activa ===';

EXEC eCobros.anularFactura @id_factura = 1;

-- ==========================================
-- CASO 2: Intentar anular factura que ya está anulada
-- Esperado: mensaje 'la factura no existe o ya esta anulada' y sin cambios
-- ==========================================
PRINT '
=== CASO 2: Intentar anular factura ya anulada ===';

-- Ejecutar de nuevo para anular factura 1 que ahora está anulada
EXEC eCobros.anularFactura @id_factura = 1;

-- ==========================================
-- CASO 3: Intentar anular factura que no existe
-- Esperado: mensaje 'la factura no existe o ya esta anulada'
-- ==========================================
PRINT '
=== CASO 3: Intentar anular factura inexistente ===';

EXEC eCobros.anularFactura @id_factura = 9999;
SELECT * FROM eCobros.Factura


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.RegistrarEntradaPileta
-- ==========================================';

-- ==========================================
-- CASO 1: Entrada válida tipo 'socio' sin lluvia
-- Esperado: factura con ítem 'Entrada Pileta - socio' y total correcto
-- ==========================================
PRINT '
=== CASO 1: Entrada válida tipo socio sin lluvia ===';

EXEC eCobros.RegistrarEntradaPileta 
    @id_socio = 1, 
    @fecha = '2025-06-01', 
    @tipo = 'socio', 
    @lluvia = 0;


-- ==========================================
-- CASO 2: Entrada válida tipo 'invitado' con lluvia (reembolso)
-- Esperado: factura con ítem positivo 'Entrada Pileta - invitado' y ítem negativo 'Reembolso Entrada Pileta - invitado'
--           total factura = monto - reembolso
-- ==========================================
PRINT '
=== CASO 2: Entrada tipo invitado con lluvia (reembolso) ===';

EXEC eCobros.RegistrarEntradaPileta 
    @id_socio = 1, 
    @fecha = '2025-06-01', 
    @tipo = 'invitado', 
    @lluvia = 1;


-- ==========================================
-- CASO 3: Intentar registrar entrada con socio inexistente
-- Esperado: mensaje de error y no se inserta nada
-- ==========================================
PRINT '
=== CASO 3: Socio inexistente ===';

EXEC eCobros.RegistrarEntradaPileta 
    @id_socio = 9999, 
    @fecha = '2025-06-01', 
    @tipo = 'socio', 
    @lluvia = 0;

-- ==========================================
-- CASO 4: Intentar registrar entrada con tipo inválido
-- Esperado: mensaje de error y no se inserta nada
-- ==========================================
PRINT '
=== CASO 4: Tipo inválido ===';

EXEC eCobros.RegistrarEntradaPileta 
    @id_socio = 1, 
    @fecha = '2025-06-01', 
    @tipo = 'otro', 
    @lluvia = 0;

-- ==========================================
-- CASO 5: Socio con cuotas impagas (moroso) intentando acceder
-- Esperado: mensaje de error y no se inserta nada
-- ==========================================
PRINT '
=== CASO 5: Socio con cuotas impagas ===';

-- Preparar factura morosa para el socio 3 en fecha anterior
UPDATE eCobros.Factura
SET estado = 'pendiente', fecha_venc_2 = DATEADD(DAY, -1, GETDATE())
WHERE id_socio = 3;

EXEC eCobros.RegistrarEntradaPileta 
    @id_socio = 3, 
    @tipo = 'socio', 
    @lluvia = 0;

SELECT * 
FROM eCobros.EntradaPileta


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.AnularEntradaPileta
-- =========================================='

-- ==========================================
-- CASO 1: Anulación exitosa de entrada válida
-- Esperado: se agrega ítem negativo en factura y se descuenta el monto
-- ==========================================
PRINT '
=== CASO 1: Anulación exitosa ===';

EXEC eCobros.AnularEntradaPileta @id_entrada = 1;

-- ==========================================
-- CASO 2: Anulación de entrada inexistente
-- Esperado: mensaje de error 'La entrada no existe'
-- ==========================================
PRINT '
=== CASO 2: Entrada inexistente ===';

EXEC eCobros.AnularEntradaPileta @id_entrada = 999;


-- ==========================================
-- CASO 3: Entrada con lluvia, luego anulada
-- Esperado: se genera reembolso por el restante del monto
-- ==========================================
PRINT '
=== CASO 3: Entrada con lluvia y luego anulada ===';

-- Anular entrada con lluvia
EXEC eCobros.AnularEntradaPileta @id_entrada = 2;

SELECT * FROM eCobros.ItemFactura WHERE id_factura =5


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.CargarPago
-- =========================================='

-- ==========================================
-- CASO 1: Pago exitoso que completa una factura
-- ==========================================
PRINT '
=== CASO 1: Pago completo exitoso ===';

DECLARE @total_factura DECIMAL(10,2);
SELECT @total_factura = total FROM eCobros.Factura WHERE id_factura = 2;
EXEC eCobros.CargarPago
    @id_factura = 2,
    @medio_pago = 'masterCard',
    @monto = @total_factura;

-- ==========================================
-- CASO 2: Pago parcial
-- ==========================================
PRINT '
=== CASO 2: Pago parcial ===';
EXEC eCobros.CargarPago
    @id_factura = 3,
    @medio_pago = 'visa',
    @monto = 1000; 

-- ==========================================
-- CASO 3: Monto excede lo pendiente
-- ==========================================
PRINT '
=== CASO 3: Pago excede lo pendiente ===';

EXEC eCobros.CargarPago
    @id_factura = 3,
    @medio_pago = 'transferencia',
    @monto = 99999;
GO

-- ==========================================
-- CASO 4: Pago a factura anulada
-- ==========================================
PRINT '
=== CASO 4: Pago sobre factura anulada ===';

EXEC eCobros.CargarPago
    @id_factura = 1,
    @medio_pago = 'efectivo',
    @monto = 500;
GO

-- ==========================================
-- CASO 5: La factura no existe
-- ==========================================
PRINT '
=== CASO 5: La factura no existe ===';

EXEC eCobros.CargarPago
    @id_factura = 999,
    @medio_pago = 'tarjeta naranja',
    @monto = 5000;
GO

SELECT * FROM eCobros.Pago

PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.AnularPago
-- =========================================='

PRINT '
=== CASO 1: Anulación válida de pago ===';

EXEC eCobros.AnularPago @id_pago = 2;

-- ==========================================
-- CASO 2: Anular un pago ya anulado
-- ==========================================
PRINT '
=== CASO 2: Pago ya anulado ===';

EXEC eCobros.AnularPago @id_pago = 2;

-- ==========================================
-- CASO 3: Anular pago inexistente
-- ==========================================
PRINT '
=== CASO 3: Pago inexistente ===';

EXEC eCobros.AnularPago @id_pago = 999;

SELECT* FROM eCobros.Pago


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.GenerarReembolso
-- =========================================='

-- ==========================================
-- CASO 1: Reembolso parcial válido
-- ==========================================
PRINT '
=== CASO 1: Reembolso parcial válido ===';

DECLARE @monto_pago DECIMAL(10,2);
SELECT @monto_pago = monto/2 FROM eCobros.Pago WHERE id_pago = 1;

EXEC eCobros.GenerarReembolso
    @id_pago = 1, 
    @monto = @monto_pago,
    @motivo = 'Descuento aplicado incorrectamente';


-- ==========================================
-- CASO 2: Reembolso que excede el monto del pago
-- ==========================================
PRINT '
=== CASO 2: Reembolso excede monto del pago (espera error) ===';

EXEC eCobros.GenerarReembolso
    @id_pago = 1, 
    @monto = 9999, 
    @motivo = 'Intento incorrecto de reembolso';


-- ========================================
-- CASO 3: Reembolso total válido
-- ==========================================
PRINT '
=== CASO 3: Reembolso total válido ===';
EXEC eCobros.GenerarReembolso
    @id_pago = 1, 
    @monto = @monto_pago,
    @motivo = 'Error en el cobro';


-- ==========================================
-- CASO 4: Reembolso sobre pago anulado (espera error)
-- ==========================================
PRINT '
=== CASO 4: Reembolso sobre pago anulado (espera error) ===';

EXEC eCobros.GenerarReembolso
    @id_pago = 2,
    @monto = 200.00,
    @motivo = 'No debió cobrarse';


-- ==========================================
-- CASO 5: Reembolso sobre pago inexistente
-- ==========================================
PRINT '
=== CASO 5: Reembolso sobre pago inexistente (espera error) ===';

EXEC eCobros.GenerarReembolso
    @id_pago = 9999, 
    @monto = 100.00,
    @motivo = 'Pago no encontrado';

SELECT * FROM eCobros.Pago
SELECT * FROM eCobros.Reembolso


PRINT '
-- ==========================================
-- CASOS DE PRUEBA PARA SP: eCobros.EliminarReembolso
-- =========================================='

-- ==========================================
-- CASO 1: Eliminación exitosa
-- ==========================================
PRINT '
=== CASO 1: Eliminación exitosa ===';
EXEC eCobros.EliminarReembolso @id_reembolso = 2;

-- ==========================================
-- CASO 2: Eliminar reembolso que no existe
-- ==========================================
PRINT '
=== CASO 2: Reembolso inexistente ===';
EXEC eCobros.EliminarReembolso @id_reembolso = 999999;

SELECT * FROM eCobros.Reembolso

PRINT '=== TODAS LAS PRUEBAS COMPLETADAS ===';

-- ====================
-- LIMPIEZA DE DATOS - 
-- ====================

PRINT '
=== INICIANDO LIMPIEZA DE DATOS ===';

DELETE FROM eCobros.Reembolso;
DELETE FROM eCobros.Pago;
DELETE FROM eCobros.EntradaPileta;
DELETE FROM eCobros.ItemFactura;
DELETE FROM eCobros.Factura;
DELETE FROM eSocios.Realiza;
DELETE FROM eSocios.GrupoFamiliar;
DELETE FROM eSocios.Socio;
DELETE FROM eSocios.Actividad;
DELETE FROM eSocios.Categoria;


DBCC CHECKIDENT ('eSocios.Socio', RESEED, 0);
DBCC CHECKIDENT ('eSocios.GrupoFamiliar', RESEED, 0);
DBCC CHECKIDENT ('eSocios.Actividad', RESEED, 0);
DBCC CHECKIDENT ('eSocios.Categoria', RESEED, 0);
DBCC CHECKIDENT ('eCobros.Factura', RESEED, 0);
DBCC CHECKIDENT ('eCobros.ItemFactura', RESEED, 0);
DBCC CHECKIDENT ('eCobros.EntradaPileta', RESEED, 0);
DBCC CHECKIDENT ('eCobros.Pago', RESEED, 0);
DBCC CHECKIDENT ('eCobros.Reembolso', RESEED, 0);

PRINT '
=== LIMPIEZA COMPLETADA - SISTEMA LISTO PARA NUEVAS PRUEBAS ==='; 
