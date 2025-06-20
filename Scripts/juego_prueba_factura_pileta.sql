
-- ============================================
-- CASOS DE PRUEBA: eCobros.generarFactura
-- ============================================
PRINT '=== TESTING eCobros.generarFactura ===';

-- CASO 1: Socio v�lido con categor�a y actividades
PRINT 'Caso 1: Factura v�lida con descuentos';
EXEC eCobros.generarFactura @id_socio = 1, @periodo = '06/2025';

-- CASO 2: Socio inexistente (sin categor�a asociada)
PRINT 'Caso 2: Error por socio inexistente';
BEGIN TRY
    EXEC eCobros.generarFactura @id_socio = 999, @periodo = '06/2025';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 3: Periodo mal formateado
PRINT 'Caso 3: Periodo mal formateado';
EXEC eCobros.generarFactura @id_socio = 1, @periodo = 'Junio';

-- CASO 4: Factura con fecha de emisi�n expl�cita
PRINT 'Caso 4: Fecha de emisi�n personalizada';
EXEC eCobros.generarFactura @id_socio = 1, @periodo = '06/2025', @fecha_emision = '2025-06-10';

-- ============================================
-- CASOS DE PRUEBA: eCobros.aplicarRecargoSegundoVencimiento
-- ============================================
PRINT '=== TESTING eCobros.aplicarRecargoSegundoVencimiento ===';

-- CASO 1: Aplicar recargo por segundo vencimiento
PRINT 'Caso 1: Aplicar recargo a factura v�lida';
EXEC eCobros.aplicarRecargoSegundoVencimiento @id_factura = 1001;

-- CASO 2: Recargo ya aplicado
PRINT 'Caso 2: Recargo ya aplicado previamente';
EXEC eCobros.aplicarRecargoSegundoVencimiento @id_factura = 1001;

-- CASO 3: Factura inexistente
PRINT 'Caso 3: Error por factura inexistente';
BEGIN TRY
    EXEC eCobros.aplicarRecargoSegundoVencimiento @id_factura = 9999;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 4: Segundo vencimiento expirado
PRINT 'Caso 4: Factura ya vencida completamente';
EXEC eCobros.aplicarRecargoSegundoVencimiento @id_factura = 1003;

-- ============================================
-- CASOS DE PRUEBA: eCobros.anularFactura
-- ============================================
PRINT '=== TESTING eCobros.anularFactura ===';

-- CASO 1: Anular factura v�lida
PRINT 'Caso 1: Anulaci�n correcta';
EXEC eCobros.anularFactura @id_factura = 1004;

-- CASO 2: Factura ya anulada
PRINT 'Caso 2: Error por factura ya anulada';
BEGIN TRY
    EXEC eCobros.anularFactura @id_factura = 1005;
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

-- CASO 1: Entrada v�lida de socio
PRINT 'Caso 1: Entrada v�lida de socio';
EXEC eCobros.RegistrarEntradaPileta @id_socio = 1, @tipo = 'socio';

-- CASO 2: Entrada con lluvia
PRINT 'Caso 2: Entrada con lluvia';
EXEC eCobros.RegistrarEntradaPileta @id_socio = 1, @tipo = 'socio', @lluvia = 1;

-- CASO 3: Tipo inv�lido
PRINT 'Caso 3: Error por tipo inv�lido';
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

-- CASO 6: Entrada v�lida de invitado
PRINT 'Caso 6: Entrada de invitado sin lluvia';
EXEC eCobros.RegistrarEntradaPileta @id_socio = 1, @tipo = 'invitado';

-- CASO 7: Entrada de invitado con lluvia
PRINT 'Caso 7: Invitado con reembolso por lluvia';
EXEC eCobros.RegistrarEntradaPileta @id_socio = 1, @tipo = 'invitado', @lluvia = 1;

-- ============================================
-- CASOS DE PRUEBA: eCobros.AnularEntradaPileta
-- ============================================
PRINT '=== TESTING eCobros.AnularEntradaPileta ===';

-- CASO 1: Anular entrada v�lida
PRINT 'Caso 1: Anulaci�n simple de entrada';
EXEC eCobros.AnularEntradaPileta @id_entrada = 2001;

-- CASO 2: Anulaci�n no permitida (reembolso por lluvia)
PRINT 'Caso 2: Error por entrada con reembolso';
BEGIN TRY
    EXEC eCobros.AnularEntradaPileta @id_entrada = 2002;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 3: Entrada con factura pagada, sin reembolso
PRINT 'Caso 3: Entrada pagada sin aplicar reembolso';
BEGIN TRY
    EXEC eCobros.AnularEntradaPileta @id_entrada = 2003;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;

-- CASO 4: Entrada pagada, con reembolso
PRINT 'Caso 4: Anulaci�n con reembolso expl�cito';
EXEC eCobros.AnularEntradaPileta @id_entrada = 2003, @aplicar_reembolso = 1;

-- CASO 5: Entrada inexistente
PRINT 'Caso 5: Error por entrada inexistente';
BEGIN TRY
    EXEC eCobros.AnularEntradaPileta @id_entrada = 9999;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;