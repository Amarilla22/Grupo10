-- =====================================================
-- CASOS DE PRUEBA: eSocios.ModificarTutor
-- =====================================================
use j_prueba
go

-- Insertar categoría "Adulto" si no existe

IF NOT EXISTS (
    SELECT 1 FROM eSocios.Categoria WHERE nombre = 'Adulto'
)
BEGIN
    INSERT INTO eSocios.Categoria (nombre, costo_mensual)
    VALUES ('Adulto', 5000.00);
END
GO

-- Obtener id_categoria de "Adulto"
DECLARE @id_categoria_adulto INT;
SELECT @id_categoria_adulto = id_categoria
FROM eSocios.Categoria
WHERE nombre = 'Adulto';

-- ==========================================
-- Insertar socio principal para tutores
-- ==========================================
INSERT INTO eSocios.Socio (
    id_categoria, dni, nombre, apellido, email, fecha_nac,
    telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES (
    @id_categoria_adulto, '90000001', 'Ricardo', 'Sosa', 'ricardo@email.com', '1980-01-01',
    '1111111111', '2222222222', 'OSDE', '9999');

DECLARE @id_socio INT = SCOPE_IDENTITY();

-- ==========================================
-- Insertar tutor modificable
-- ==========================================
INSERT INTO eSocios.Tutor (
    id_socio, nombre, apellido, email, fecha_nac, telefono, parentesco)
VALUES (
    @id_socio, 'Mónica', 'López', 'monica@email.com', '1985-02-10',
    '1234567890', 'Madre');

DECLARE @id_tutor_modificable INT = SCOPE_IDENTITY();

-- ==========================================
-- Insertar tutor adicional (email duplicado)
-- ==========================================
INSERT INTO eSocios.Tutor (
    id_socio, nombre, apellido, email, fecha_nac, telefono, parentesco)
VALUES (
    @id_socio, 'Jorge', 'Ramírez', 'jorge@email.com', '1970-07-07',
    '0987654321', 'Padre');

-- ==========================================
-- Insertar socio y tutor para eliminar
-- ==========================================
INSERT INTO eSocios.Socio (
    id_categoria, dni, nombre, apellido, email, fecha_nac,
    telefono, telefono_emergencia, obra_social, nro_obra_social)
VALUES (
    @id_categoria_adulto, '80000001', 'Sofía', 'Méndez', 'sofia@email.com', '1985-04-12',
    '1112223333', '3332221111', 'Medicus', '8888');

DECLARE @id_socio_eliminar INT = SCOPE_IDENTITY();

INSERT INTO eSocios.Tutor (
    id_socio, nombre, apellido, email, fecha_nac, telefono, parentesco)
VALUES (
    @id_socio_eliminar, 'Esteban', 'Quiroga', 'esteban@email.com', '1980-07-20',
    '1231231234', 'Padre');

DECLARE @id_tutor_eliminar INT = SCOPE_IDENTITY();
GO

PRINT '=== TESTING eSocios.ModificarTutor ===';
GO
-- ==========================================
-- CASO 1: Modificación exitosa
-- ==========================================
DECLARE @id_tutor_valido INT = SCOPE_IDENTITY();
PRINT 'Caso 1: Modificación exitosa de tutor existente';
EXEC eSocios.ModificarTutor
    @id_tutor = @id_tutor_valido,
    @nombre = 'Mónica',
    @apellido = 'Fernández',
    @email = 'monica.nueva@email.com',
    @fecha_nac = '1985-02-10',
    @telefono = '1234567890',
    @parentesco = 'Tía';
GO

-- ==========================================
-- CASO 2: Error - Tutor inexistente
-- ==========================================
PRINT 'Caso 2: Error por tutor inexistente';
BEGIN TRY
    EXEC eSocios.ModificarTutor
        @id_tutor = 9999, -- ID inexistente
        @nombre = 'Falso',
        @apellido = 'Inventado',
        @email = 'noexiste@email.com',
        @fecha_nac = '1990-01-01',
        @telefono = '0000000000',
        @parentesco = 'Tío';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- ==========================================
-- CASO 3: Error - Email duplicado
-- ==========================================
DECLARE @id_tutor_valido INT = SCOPE_IDENTITY();
PRINT 'Caso 3: Error por email duplicado con otro tutor';
BEGIN TRY
    EXEC eSocios.ModificarTutor
        @id_tutor = @id_tutor_valido,
        @nombre = 'Mónica',
        @apellido = 'López',
        @email = 'jorge@email.com', -- Email duplicado
        @fecha_nac = '1985-02-10',
        @telefono = '1234567890',
        @parentesco = 'Madre';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- ==========================================
-- VERIFICACIÓN FINAL
-- ==========================================
PRINT 'Listado final de tutores:';
SELECT id_tutor, nombre, apellido, email, telefono, parentesco
FROM eSocios.Tutor;
GO

PRINT '=== TESTING eSocios.EliminarTutor ===';
GO

DECLARE @id_tutor_eliminar INT = SCOPE_IDENTITY();
-- ==========================================
-- CASO 1: Eliminación exitosa de tutor existente
-- ==========================================
PRINT 'Caso 1: Eliminación exitosa de tutor';
EXEC eSocios.EliminarTutor @id_tutor = @id_tutor_eliminar;
GO

-- ==========================================
-- CASO 2: Error - Tutor no existe
-- ==========================================
PRINT 'Caso 2: Error por tutor inexistente';
BEGIN TRY
    EXEC eSocios.EliminarTutor @id_tutor = 9999; -- ID inválido
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH;
GO

-- ==========================================
-- VERIFICACIÓN FINAL
-- ==========================================
PRINT 'Listado actual de tutores:';
SELECT id_tutor, nombre, apellido, email, telefono, parentesco
FROM eSocios.Tutor;
GO

-----------------PAGOS

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

