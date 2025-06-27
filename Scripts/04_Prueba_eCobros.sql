-- ============================================
-- CASOS DE PRUEBA: eCobros.generarFactura
-- ============================================
PRINT '=== TESTING eCobros.generarFactura ===';

-- CASO 1: Socio válido con categoría y actividades
PRINT 'Caso 1: Factura válida con descuentos';
EXEC eCobros.generarFactura @id_socio = 1, @periodo = '06/2025';

-- CASO 2: Socio inexistente (sin categoría asociada)
PRINT 'Caso 2: Error por socio inexistente';
BEGIN TRY
    EXEC eCobros.generarFactura @id_socio = 999, @periodo = '06/2025';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 3: Factura con fecha de emisión explícita
PRINT 'Caso 3: Fecha de emisión personalizada';
EXEC eCobros.generarFactura @id_socio = 2, @periodo = '03/2025', @fecha_emision = '2025-03-10';

-- ============================================
-- CASOS DE PRUEBA: eCobros.aplicarRecargoSegundoVencimiento
-- ============================================
PRINT '=== TESTING eCobros.aplicarRecargoSegundoVencimiento ===';

-- CASO 1: Aplicar recargo por segundo vencimiento
PRINT 'Caso 1: Aplicar recargo a factura válida';
EXEC eCobros.aplicarRecargoSegundoVencimiento @id_factura = 2;

-- CASO 2: Recargo ya aplicado
PRINT 'Caso 2: Recargo ya aplicado previamente';
EXEC eCobros.aplicarRecargoSegundoVencimiento @id_factura = 2;

-- CASO 3: Factura inexistente
PRINT 'Caso 3: Error por factura inexistente';
BEGIN TRY
    EXEC eCobros.aplicarRecargoSegundoVencimiento @id_factura = 9999;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;


-- ============================================
-- CASOS DE PRUEBA: eCobros.anularFactura
-- ============================================
PRINT '=== TESTING eCobros.anularFactura ===';

-- CASO 1: Anular factura válida
PRINT 'Caso 1: Anulación correcta';
EXEC eCobros.anularFactura @id_factura = 1;

-- CASO 2: Factura ya anulada
PRINT 'Caso 2: Error por factura ya anulada';
BEGIN TRY
    EXEC eCobros.anularFactura @id_factura = 1;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 3: Factura inexistente
PRINT 'Caso 3: Error por factura inexistente';
BEGIN TRY
    EXEC eCobros.anularFactura @id_factura = 9999;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- ============================================
-- CASOS DE PRUEBA: eCobros.RegistrarEntradaPileta
-- ============================================
PRINT '=== TESTING eCobros.RegistrarEntradaPileta ===';

-- CASO 1: Entrada válida de socio
PRINT 'Caso 1: Entrada válida de socio';
EXEC eCobros.RegistrarEntradaPileta @id_socio = 1, @tipo = 'socio';

-- CASO 2: Entrada con lluvia
PRINT 'Caso 2: Entrada con lluvia';
EXEC eCobros.RegistrarEntradaPileta @id_socio = 3, @tipo = 'socio', @lluvia = 1;

-- CASO 3: Tipo inválido
PRINT 'Caso 3: Error por tipo inválido';
BEGIN TRY
    EXEC eCobros.RegistrarEntradaPileta @id_socio = 1, @tipo = 'externo';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 4: Socio inexistente
PRINT 'Caso 4: Error por socio inexistente';
BEGIN TRY
    EXEC eCobros.RegistrarEntradaPileta @id_socio = 999, @tipo = 'socio';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 5: Socio con morosidad
PRINT 'Caso 5: Error por cuotas impagas';
BEGIN TRY
    EXEC eCobros.RegistrarEntradaPileta @id_socio = 2, @tipo = 'socio';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 6: Entrada válida de invitado
PRINT 'Caso 6: Entrada de invitado sin lluvia';
EXEC eCobros.RegistrarEntradaPileta @id_socio = 1, @tipo = 'invitado';

-- CASO 7: Entrada de invitado con lluvia
PRINT 'Caso 7: Invitado con reembolso por lluvia';
EXEC eCobros.RegistrarEntradaPileta @id_socio = 1, @tipo = 'invitado', @lluvia = 1;

-- ============================================
-- CASOS DE PRUEBA: eCobros.AnularEntradaPileta
-- ============================================
PRINT '=== TESTING eCobros.AnularEntradaPileta ===';

-- CASO 1: Anular entrada válida
PRINT 'Caso 1: Anulación simple de entrada';
EXEC eCobros.AnularEntradaPileta @id_entrada = 1;

-- CASO 2: Anulación no permitida (reembolso por lluvia)
PRINT 'Caso 2: Error por entrada con reembolso';
BEGIN TRY
    EXEC eCobros.AnularEntradaPileta @id_entrada = 2;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 3: Entrada con factura pagada, sin reembolso
PRINT 'Caso 3: Entrada pagada sin aplicar reembolso';
BEGIN TRY
    EXEC eCobros.AnularEntradaPileta @id_entrada = 3;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 4: Entrada inexistente
PRINT 'Caso 4: Error por entrada inexistente';
BEGIN TRY
    EXEC eCobros.AnularEntradaPileta @id_entrada = 9999;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- =====================================================
-- SETUP PARA TEST DE PAGOS Y ANULACIONES
-- =====================================================

PRINT '=== CREANDO DATOS PARA TEST DE PAGOS Y ANULACIONES ===';
GO

-- Insertar socio
INSERT INTO eSocios.Socio (
    id_categoria, dni, nombre, apellido, email, fecha_nac,
    telefono, telefono_emergencia, obra_social, nro_obra_social
)
VALUES (
    1, '77777777', 'Laura', 'Bianchi', 'laura.bianchi@email.com', '1990-01-01',
    '1111111111', '2222222222', 'OSDE', '12345'
);

DECLARE @id_socio INT = SCOPE_IDENTITY();

-- Insertar factura pendiente
INSERT INTO eCobros.Factura (
    id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, estado, total, recargo_venc, descuentos
)
VALUES (
    @id_socio, '2025-06-01', '2025-06-10', '2025-06-20', 'pendiente', 10000, 0, 0
);

DECLARE @id_factura INT = SCOPE_IDENTITY();

-- Insertar ítem en factura
INSERT INTO eCobros.ItemFactura (
    id_factura, concepto, monto, periodo
)
VALUES (
    @id_factura, 'membresia', 10000, 'junio-2025'
);

-- Factura pagada parcial (para test de exceso o múltiples pagos)
INSERT INTO eCobros.Factura (
    id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, estado, total, recargo_venc, descuentos
)
VALUES (
    @id_socio, '2025-06-01', '2025-06-10', '2025-06-20', 'pendiente', 15000, 0, 0
);

DECLARE @id_factura_parcial INT = SCOPE_IDENTITY();

-- Pago parcial sobre esa factura
INSERT INTO eCobros.Pago (
    id_pago, id_factura, medio_pago, monto, fecha, estado, debito_auto
)
VALUES (
    8001, @id_factura_parcial, 'visa', 5000, GETDATE(), 'completado', 0
);
GO

PRINT '=== DATOS DE COBROS LISTOS ===';
GO


-- =====================================================
-- CASOS DE PRUEBA: eCobros.CargarPago
-- =====================================================

PRINT '=== TESTING eCobros.CargarPago ===';
GO

-- Caso 1: Pago exitoso completo
PRINT 'Caso 1: Registrar pago completo válido';
EXEC eCobros.CargarPago 
    @id_pago = 9003,
    @id_factura = 1,         -- corresponde a factura de $10.000
    @medio_pago = 'visa',
    @monto = 10000,
    @fecha = '2025-06-15',
    @debito_auto = 0;
GO

-- Caso 2: Pago parcial
PRINT 'Caso 2: Registrar pago parcial';
EXEC eCobros.CargarPago 
    @id_pago = 9010,
    @id_factura = 2,         -- corresponde a factura de $15.000 con $5.000 ya pagados
    @medio_pago = 'masterCard',
    @monto = 3000,
    @fecha = '2025-06-16',
    @debito_auto = 0;
GO

-- Caso 3: Error - monto excede lo pendiente
PRINT 'Caso 3: Error por monto mayor al saldo pendiente';
BEGIN TRY
    EXEC eCobros.CargarPago 
        @id_pago = 9003,
        @id_factura = 2,     -- ya tiene $5.000 + $3.000 pagados
        @medio_pago = 'visa',
        @monto = 8000,       -- excede el saldo ($7.000)
        @fecha = NULL,
        @debito_auto = 0;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Caso 4: Error - factura no existe
PRINT 'Caso 4: Error por factura inexistente';
BEGIN TRY
    EXEC eCobros.CargarPago 
        @id_pago = 9004,
        @id_factura = 9999,
        @medio_pago = 'rapipago',
        @monto = 5000,
        @fecha = NULL,
        @debito_auto = 0;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Caso 5: Error - pago duplicado (id_pago repetido)
PRINT 'Caso 5: Error por ID de pago duplicado';
BEGIN TRY
    EXEC eCobros.CargarPago 
        @id_pago = 9001, -- ya usado en caso 1
        @id_factura = 1,
        @medio_pago = 'visa',
        @monto = 1000,
        @fecha = NULL,
        @debito_auto = 0;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Caso 6: Error - factura anulada
PRINT 'Caso 6: Error por factura anulada';
-- Anulamos primero la factura 1 manualmente para simular
UPDATE eCobros.Factura SET estado = 'anulada' WHERE id_factura = 1;

BEGIN TRY
    EXEC eCobros.CargarPago 
        @id_pago = 9005,
        @id_factura = 1,
        @medio_pago = 'visa',
        @monto = 500,
        @fecha = NULL,
        @debito_auto = 0;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Verificar estado de facturas y pagos
PRINT 'Estado de Facturas y Pagos:';
SELECT f.id_factura, f.estado AS estado_factura, f.total,
       p.id_pago, p.monto, p.estado AS estado_pago
FROM eCobros.Factura f
LEFT JOIN eCobros.Pago p ON f.id_factura = p.id_factura
ORDER BY f.id_factura, p.id_pago;
GO


-- =====================================================
-- CASOS DE PRUEBA: eCobros.AnularPago
-- =====================================================

PRINT '=== TESTING eCobros.AnularPago ===';
GO

-- Caso 1: Anular un pago sin reembolsos
PRINT 'Caso 1: Anular pago válido (sin reembolsos)';
-- Creamos un nuevo pago sobre factura 2
EXEC eCobros.CargarPago 
    @id_pago = 9006,
    @id_factura = 2,
    @medio_pago = 'mercado pago',
    @monto = 2000,
    @fecha = '2025-06-17',
    @debito_auto = 0;

-- Ahora lo anulamos
EXEC eCobros.AnularPago 
    @id_pago = 9006;
GO

-- Caso 2: Error - Pago no existe
PRINT 'Caso 2: Error por pago inexistente';
BEGIN TRY
    EXEC eCobros.AnularPago 
        @id_pago = 9999;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Caso 3: Error - Pago no está en estado completado
PRINT 'Caso 3: Error por estado no válido';
-- Reutilizamos pago 9006 que ya fue anulado
BEGIN TRY
    EXEC eCobros.AnularPago 
        @id_pago = 9006;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Caso 4: Error - Tiene reembolso asociado
PRINT 'Caso 4: No se puede anular si tiene reembolsos';
-- Creamos nuevo pago para simular
EXEC eCobros.CargarPago 
    @id_pago = 9007,
    @id_factura = 2,
    @medio_pago = 'pago facil',
    @monto = 1500,
    @fecha = '2025-06-18',
    @debito_auto = 0;

-- Reembolso sobre ese pago
EXEC eCobros.InsertarReembolso 
    @id_reembolso = 9501,
    @id_pago = 9007,
    @monto = 1000,
    @motivo = 'Error de sistema';

-- Intento de anulación
BEGIN TRY
    EXEC eCobros.AnularPago 
        @id_pago = 9007;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Verificar pagos y estado de factura 2
PRINT 'Estado de pagos y factura relacionada:';
SELECT p.id_pago, p.estado AS estado_pago, r.id_reembolso, r.monto AS monto_reembolso
FROM eCobros.Pago p
LEFT JOIN eCobros.Reembolso r ON p.id_pago = r.id_pago
WHERE p.id_factura = 2;

SELECT id_factura, estado AS estado_factura, total
FROM eCobros.Factura
WHERE id_factura = 2;
GO

