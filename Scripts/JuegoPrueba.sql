-- =====================================================
-- JUEGOS DE PRUEBA PARA STORED PROCEDURES eCobros
-- =====================================================
-- Preparaci�n de datos de prueba
-- =====================================================

-- Insertar datos de prueba para socios
INSERT INTO eSocios.Socio (id_socio, nombre, apellido, email)
VALUES 
    (1, 'Juan', 'P�rez', 'juan.perez@email.com'),
    (2, 'Mar�a', 'Gonz�lez', 'maria.gonzalez@email.com'),
    (3, 'Carlos', 'Rodr�guez', 'carlos.rodriguez@email.com');

-- Insertar facturas de prueba
INSERT INTO eCobros.Factura (id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, estado, total, recargo_venc, descuentos)
VALUES 
    (1, '2024-01-15', '2024-02-15', '2024-03-15', 'pendiente', 1000.00, 50, 0),
    (2, '2024-01-16', '2024-02-16', '2024-03-16', 'pendiente', 2500.00, 75, 100),
    (3, '2024-01-17', '2024-02-17', '2024-03-17', 'pagada', 500.00, 0, 50),
    (1, '2024-02-01', '2024-03-01', '2024-04-01', 'anulada', 750.00, 0, 0);

-- Obtener los IDs de facturas generados autom�ticamente
DECLARE @id_factura_1 INT = (SELECT id_factura FROM eCobros.Factura WHERE id_socio = 1 AND total = 1000.00);
DECLARE @id_factura_2 INT = (SELECT id_factura FROM eCobros.Factura WHERE id_socio = 2 AND total = 2500.00);
DECLARE @id_factura_3 INT = (SELECT id_factura FROM eCobros.Factura WHERE id_socio = 3 AND total = 500.00);

-- Insertar algunos pagos de prueba base
INSERT INTO eCobros.Pago (id_pago, id_factura, medio_pago, monto, fecha, estado, debito_auto)
VALUES 
    (1, @id_factura_3, 'tarjeta naranja', 500.00, '2024-01-20', 'completado', 0),
    (2, @id_factura_1, 'visa', 1000.00, '2024-01-21', 'completado', 1);

-- =====================================================
-- PRUEBAS PARA sp_CargarPago
-- =====================================================

PRINT '=== INICIANDO PRUEBAS PARA sp_CargarPago ===';

-- Caso 1: Pago exitoso con tarjeta de cr�dito
PRINT 'Caso 1: Pago exitoso con Visa';
EXEC eCobros.sp_CargarPago 
    @id_pago = 101,
    @id_factura = @id_factura_1,
    @medio_pago = 'visa',
    @monto = 500.00,
    @fecha = '2024-06-15',
    @debito_auto = 0;

-- Caso 2: Pago con MasterCard y d�bito autom�tico
PRINT 'Caso 2: Pago con MasterCard y d�bito autom�tico';
EXEC eCobros.sp_CargarPago 
    @id_pago = 102,
    @id_factura = @id_factura_2,
    @medio_pago = 'masterCard',
    @monto = 2500.00,
    @fecha = '2024-06-16',
    @debito_auto = 1;

-- Caso 3: Pago con Tarjeta Naranja
PRINT 'Caso 3: Pago con Tarjeta Naranja';
EXEC eCobros.sp_CargarPago 
    @id_pago = 103,
    @id_factura = @id_factura_2,
    @medio_pago = 'tarjeta naranja',
    @monto = 1000.00,
    @fecha = '2024-06-16',
    @debito_auto = 0;

-- Caso 4: Pago f�cil
PRINT 'Caso 4: Pago f�cil';
EXEC eCobros.sp_CargarPago 
    @id_pago = 104,
    @id_factura = @id_factura_1,
    @medio_pago = 'pago facil',
    @monto = 250.00,
    @fecha = '2024-06-16',
    @debito_auto = 0;

-- Caso 5: RapiPago
PRINT 'Caso 5: RapiPago';
EXEC eCobros.sp_CargarPago 
    @id_pago = 105,
    @id_factura = @id_factura_1,
    @medio_pago = 'rapipago',
    @monto = 300.00,
    @fecha = '2024-06-16',
    @debito_auto = 0;

-- Caso 6: Mercado Pago
PRINT 'Caso 6: Mercado Pago';
EXEC eCobros.sp_CargarPago 
    @id_pago = 106,
    @id_factura = @id_factura_2,
    @medio_pago = 'mercado pago',
    @monto = 800.00,
    @fecha = '2024-06-16',
    @debito_auto = 0;

-- Caso 7: Pago con fecha NULL (debe usar fecha actual)
PRINT 'Caso 7: Pago con fecha NULL';
EXEC eCobros.sp_CargarPago 
    @id_pago = 107,
    @id_factura = @id_factura_2,
    @medio_pago = 'visa',
    @monto = 150.00,
    @fecha = NULL,
    @debito_auto = 0;

-- Caso 8: ERROR - ID de pago duplicado
PRINT 'Caso 8: Error - ID de pago duplicado';
BEGIN TRY
    EXEC eCobros.sp_CargarPago 
        @id_pago = 101, -- ID ya usado
        @id_factura = @id_factura_1,
        @medio_pago = 'visa',
        @monto = 300.00,
        @fecha = '2024-06-16',
        @debito_auto = 0;
END TRY
BEGIN CATCH
    PRINT 'ERROR CAPTURADO: ' + ERROR_MESSAGE();
END CATCH

-- Caso 9: ERROR - Factura inexistente
PRINT 'Caso 9: Error - Factura inexistente';
BEGIN TRY
    EXEC eCobros.sp_CargarPago 
        @id_pago = 108,
        @id_factura = 999999, -- Factura que no existe
        @medio_pago = 'visa',
        @monto = 500.00,
        @fecha = '2024-06-16',
        @debito_auto = 0;
END TRY
BEGIN CATCH
    PRINT 'ERROR CAPTURADO: ' + ERROR_MESSAGE();
END CATCH

-- Caso 10: ERROR - Monto negativo o cero
PRINT 'Caso 10: Error - Monto negativo';
BEGIN TRY
    EXEC eCobros.sp_CargarPago 
        @id_pago = 109,
        @id_factura = @id_factura_1,
        @medio_pago = 'visa',
        @monto = -100.00, -- Monto negativo
        @fecha = '2024-06-16',
        @debito_auto = 0;
END TRY
BEGIN CATCH
    PRINT 'ERROR CAPTURADO: ' + ERROR_MESSAGE();
END CATCH

-- Caso 11: ERROR - Medio de pago inv�lido
PRINT 'Caso 11: Error - Medio de pago inv�lido';
BEGIN TRY
    EXEC eCobros.sp_CargarPago 
        @id_pago = 110,
        @id_factura = @id_factura_1,
        @medio_pago = 'bitcoin', -- Medio no v�lido seg�n CHECK constraint
        @monto = 100.00,
        @fecha = '2024-06-16',
        @debito_auto = 0;
END TRY
BEGIN CATCH
    PRINT 'ERROR CAPTURADO: ' + ERROR_MESSAGE();
END CATCH

-- Caso 12: Monto muy grande (caso l�mite)
PRINT 'Caso 12: Monto muy grande';
EXEC eCobros.sp_CargarPago 
    @id_pago = 111,
    @id_factura = @id_factura_1,
    @medio_pago = 'visa',
    @monto = 9999999.99,
    @fecha = '2024-06-16',
    @debito_auto = 0;

-- =====================================================
-- PRUEBAS PARA sp_InsertarReembolso
-- =====================================================

PRINT '';
PRINT '=== INICIANDO PRUEBAS PARA sp_InsertarReembolso ===';

-- Caso 1: Reembolso exitoso b�sico
PRINT 'Caso 1: Reembolso exitoso b�sico';
EXEC eCobros.sp_InsertarReembolso 
    @id_reembolso = 201,
    @id_pago = 1,
    @monto = 100.00,
    @motivo = 'Error en facturaci�n',
    @fecha = '2024-06-16';

-- Caso 2: Reembolso con fecha NULL (debe usar fecha actual)
PRINT 'Caso 2: Reembolso con fecha NULL';
EXEC eCobros.sp_InsertarReembolso 
    @id_reembolso = 202,
    @id_pago = 2,
    @monto = 50.00,
    @motivo = 'Solicitud del cliente',
    @fecha = NULL;

-- Caso 3: Reembolso total del pago
PRINT 'Caso 3: Reembolso total del pago';
EXEC eCobros.sp_InsertarReembolso 
    @id_reembolso = 203,
    @id_pago = 101,
    @monto = 500.00,
    @motivo = 'Cancelaci�n de servicio',
    @fecha = '2024-06-16';

-- Caso 4: Reembolso parcial
PRINT 'Caso 4: Reembolso parcial';
EXEC eCobros.sp_InsertarReembolso 
    @id_reembolso = 204,
    @id_pago = 102,
    @monto = 250.00,
    @motivo = 'Descuento aplicado',
    @fecha = '2024-06-16';

-- Caso 5: Reembolso con motivo muy espec�fico
PRINT 'Caso 5: Reembolso con motivo espec�fico';
EXEC eCobros.sp_InsertarReembolso 
    @id_reembolso = 205,
    @id_pago = 103,
    @monto = 100.00,
    @motivo = 'Cobro duplicado - Resoluci�n administrativa #2024-156',
    @fecha = '2024-06-16';

-- Caso 6: ERROR - ID de reembolso duplicado
PRINT 'Caso 6: Error - ID de reembolso duplicado';
BEGIN TRY
    EXEC eCobros.sp_InsertarReembolso 
        @id_reembolso = 201, -- ID ya usado
        @id_pago = 1,
        @monto = 25.00,
        @motivo = 'Motivo duplicado',
        @fecha = '2024-06-16';
END TRY
BEGIN CATCH
    PRINT 'ERROR CAPTURADO: ' + ERROR_MESSAGE();
END CATCH

-- Caso 7: ERROR - Pago inexistente
PRINT 'Caso 7: Error - Pago inexistente';
BEGIN TRY
    EXEC eCobros.sp_InsertarReembolso 
        @id_reembolso = 206,
        @id_pago = 999999, -- Pago que no existe
        @monto = 100.00,
        @motivo = 'Error de sistema',
        @fecha = '2024-06-16';
END TRY
BEGIN CATCH
    PRINT 'ERROR CAPTURADO: ' + ERROR_MESSAGE();
END CATCH

-- Caso 8: ERROR - Monto negativo o cero
PRINT 'Caso 8: Error - Monto negativo';
BEGIN TRY
    EXEC eCobros.sp_InsertarReembolso 
        @id_reembolso = 207,
        @id_pago = 1,
        @monto = -50.00, -- Monto negativo
        @motivo = 'Test monto negativo',
        @fecha = '2024-06-16';
END TRY
BEGIN CATCH
    PRINT 'ERROR CAPTURADO: ' + ERROR_MESSAGE();
END CATCH

-- Caso 9: ERROR - Monto mayor al pago original
PRINT 'Caso 9: Error - Monto mayor al pago original';
BEGIN TRY
    EXEC eCobros.sp_InsertarReembolso 
        @id_reembolso = 208,
        @id_pago = 1, -- Pago de $500
        @monto = 600.00, -- Reembolso mayor
        @motivo = 'Test monto excesivo',
        @fecha = '2024-06-16';
END TRY
BEGIN CATCH
    PRINT 'ERROR CAPTURADO: ' + ERROR_MESSAGE();
END CATCH

-- Caso 10: Motivo en el l�mite de caracteres (100 chars)
PRINT 'Caso 10: Motivo en el l�mite de caracteres';
EXEC eCobros.sp_InsertarReembolso 
    @id_reembolso = 209,
    @id_pago = 2,
    @monto = 25.00,
    @motivo = 'Este motivo tiene exactamente cien caracteres para probar el limite maximo permitido en campo',
    @fecha = '2024-06-16';

-- Caso 11: ERROR - Motivo demasiado largo
PRINT 'Caso 11: Error - Motivo demasiado largo';
BEGIN TRY
    EXEC eCobros.sp_InsertarReembolso 
        @id_reembolso = 210,
        @id_pago = 2,
        @monto = 25.00,
        @motivo = 'Este motivo supera los cien caracteres permitidos y deber�a generar un error al intentar insertarlo en la base',
        @fecha = '2024-06-16';
END TRY
BEGIN CATCH
    PRINT 'ERROR CAPTURADO: ' + ERROR_MESSAGE();
END CATCH

-- Caso 12: M�ltiples reembolsos para el mismo pago
PRINT 'Caso 12: M�ltiples reembolsos para el mismo pago';
EXEC eCobros.sp_InsertarReembolso 
    @id_reembolso = 211,
    @id_pago = 104,
    @monto = 50.00,
    @motivo = 'Primer reembolso parcial',
    @fecha = '2024-06-16';

EXEC eCobros.sp_InsertarReembolso 
    @id_reembolso = 212,
    @id_pago = 104,
    @monto = 75.00,
    @motivo = 'Segundo reembolso parcial',
    @fecha = '2024-06-17';

-- =====================================================
-- CASOS DE PRUEBA PARA VALIDACIONES DE ESTADO
-- =====================================================

PRINT '';
PRINT '=== PRUEBAS DE VALIDACIONES DE ESTADO ===';

-- Caso 13: Intento de pago a factura anulada
DECLARE @id_factura_anulada INT = (SELECT id_factura FROM eCobros.Factura WHERE estado = 'anulada');
PRINT 'Caso 13: Intento de pago a factura anulada';
BEGIN TRY
    EXEC eCobros.sp_CargarPago 
        @id_pago = 301,
        @id_factura = @id_factura_anulada,
        @medio_pago = 'visa',
        @monto = 100.00,
        @fecha = '2024-06-16',
        @debito_auto = 0;
END TRY
BEGIN CATCH
    PRINT 'ERROR CAPTURADO: ' + ERROR_MESSAGE();
END CATCH

-- Caso 14: Verificar que no se actualice estado si hay reembolso pendiente
PRINT 'Caso 14: Estado de factura con reembolsos';

-- =====================================================
-- PRUEBAS DE RENDIMIENTO Y VOLUMEN
-- =====================================================

PRINT '';
PRINT '=== PRUEBAS DE RENDIMIENTO (DATOS MASIVOS) ===';

-- Insertar m�ltiples pagos de forma r�pida
DECLARE @i INT = 1000;
DECLARE @start_time DATETIME = GETDATE();

PRINT 'Insertando 50 pagos masivos...';
WHILE @i <= 1050
BEGIN
    BEGIN TRY
        EXEC eCobros.sp_CargarPago 
            @id_pago = @i,
            @id_factura = @id_factura_1,
            @medio_pago = 'visa',
            @monto = (@i % 100) + 10.00, -- Montos variables
            @fecha = '2024-06-16',
            @debito_auto = (@i % 2); -- Alternar d�bito autom�tico
    END TRY
    BEGIN CATCH
        PRINT 'Error en pago ' + CAST(@i AS VARCHAR) + ': ' + ERROR_MESSAGE();
    END CATCH
    SET @i = @i + 1;
END

DECLARE @end_time DATETIME = GETDATE();
PRINT 'Tiempo transcurrido para pagos: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + 'ms';

-- Insertar m�ltiples reembolsos
SET @i = 2000;
SET @start_time = GETDATE();

PRINT 'Insertando 25 reembolsos masivos...';
WHILE @i <= 2025
BEGIN
    BEGIN TRY
        EXEC eCobros.sp_InsertarReembolso 
            @id_reembolso = @i,
            @id_pago = 1000 + (@i % 10), -- Usar algunos de los pagos reci�n creados
            @monto = (@i % 50) + 5.00, -- Montos variables
            @motivo = 'Reembolso masivo #' + CAST(@i AS VARCHAR),
            @fecha = '2024-06-16';
    END TRY
    BEGIN CATCH
        PRINT 'Error en reembolso ' + CAST(@i AS VARCHAR) + ': ' + ERROR_MESSAGE();
    END CATCH
    SET @i = @i + 1;
END

SET @end_time = GETDATE();
PRINT 'Tiempo transcurrido para reembolsos: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + 'ms';

-- =====================================================
-- VERIFICACI�N DE RESULTADOS
-- =====================================================

PRINT '';
PRINT '=== VERIFICACI�N DE RESULTADOS ===';

-- Contar registros por tabla
PRINT 'Resumen de registros:';
PRINT 'Total facturas: ' + CAST((SELECT COUNT(*) FROM eCobros.Factura) AS VARCHAR);
PRINT 'Total pagos: ' + CAST((SELECT COUNT(*) FROM eCobros.Pago) AS VARCHAR);
PRINT 'Total reembolsos: ' + CAST((SELECT COUNT(*) FROM eCobros.Reembolso) AS VARCHAR);

-- Verificar pagos por medio de pago
PRINT '';
PRINT 'Distribuci�n de pagos por medio:';
SELECT medio_pago, COUNT(*) as cantidad, SUM(monto) as total_monto
FROM eCobros.Pago 
GROUP BY medio_pago
ORDER BY cantidad DESC;

-- Verificar estados de pago
PRINT '';
PRINT 'Distribuci�n de pagos por estado:';
SELECT estado, COUNT(*) as cantidad
FROM eCobros.Pago 
GROUP BY estado;

-- An�lisis financiero por factura
PRINT '';
PRINT 'An�lisis financiero por factura:';
SELECT 
    f.id_factura,
    f.id_socio,
    f.estado as estado_factura,
    f.total as monto_factura,
    ISNULL(SUM(p.monto), 0) as total_pagado,
    ISNULL(SUM(r.monto), 0) as total_reembolsado,
    (f.total - ISNULL(SUM(p.monto), 0) + ISNULL(SUM(r.monto), 0)) as saldo_pendiente,
    COUNT(p.id_pago) as cant_pagos,
    COUNT(r.id_reembolso) as cant_reembolsos
FROM eCobros.Factura f
LEFT JOIN eCobros.Pago p ON f.id_factura = p.id_factura
LEFT JOIN eCobros.Reembolso r ON p.id_pago = r.id_pago
GROUP BY f.id_factura, f.id_socio, f.estado, f.total
ORDER BY f.id_factura;

-- Verificar integridad referencial
PRINT '';
PRINT 'Verificaci�n de integridad referencial:';
PRINT 'Pagos sin factura: ' + CAST((SELECT COUNT(*) FROM eCobros.Pago p WHERE NOT EXISTS (SELECT 1 FROM eCobros.Factura f WHERE f.id_factura = p.id_factura)) AS VARCHAR);
PRINT 'Reembolsos sin pago: ' + CAST((SELECT COUNT(*) FROM eCobros.Reembolso r WHERE NOT EXISTS (SELECT 1 FROM eCobros.Pago p WHERE p.id_pago = r.id_pago)) AS VARCHAR);

PRINT '';
PRINT '=== PRUEBAS COMPLETADAS EXITOSAMENTE ===';

-- =====================================================
-- SCRIPT DE LIMPIEZA (OPCIONAL)
-- =====================================================

/*
-- Descomentar para limpiar datos de prueba despu�s de ejecutar

PRINT 'Limpiando datos de prueba...';

DELETE FROM eCobros.Reembolso WHERE id_reembolso >= 201;
DELETE FROM eCobros.Pago WHERE id_pago >= 101;
DELETE FROM eCobros.Factura WHERE id_socio IN (1, 2, 3);
DELETE FROM eSocios.Socio WHERE id_socio IN (1, 2, 3);

PRINT 'Datos de prueba eliminados.';
*/