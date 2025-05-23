

CREATE PROCEDURE eSocios.InscribirActividad
    @id_socio INT,
    @id_actividad INT,
    @periodo VARCHAR(20) -- Formato: 'MM/YYYY'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- verificar si el socio ya está inscrito en la actividad
        IF EXISTS (SELECT 1 FROM eSocios.Realiza WHERE socio = @id_socio AND id_actividad = @id_actividad)
        BEGIN
            RAISERROR('El socio ya está inscrito en esta actividad', 16, 1);
        END
        
        -- insertar en Realiza
        INSERT INTO eSocios.Realiza (socio, id_actividad)
        VALUES (@id_socio, @id_actividad);
        
        -- obtener costo de la actividad
        DECLARE @costo DECIMAL(10,2);
        SELECT @costo = costo_mensual FROM eSocios.Actividad WHERE id_actividad = @id_actividad;
        
        -- insertar item de factura
        INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto, periodo)
        VALUES (NULL, 'Actividad', @costo, @periodo);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        THROW;
    END CATCH
END;
GO

-- SP para generar factura con los descuentos correspondientes
CREATE PROCEDURE eCobros.GenerarFactura
    @id_socio INT,
    @periodo VARCHAR(20), -- formato: 'MM/YYYY'
    @fecha_emision DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- establecer fecha por defecto si no se proporciona
        IF @fecha_emision IS NULL SET @fecha_emision = GETDATE();
        
        -- calcular fechas de vencimiento
        DECLARE @fecha_venc_1 DATE = DATEADD(DAY, 5, @fecha_emision); -- primer vencimiento: 5 dias despues de emision
        DECLARE @fecha_venc_2 DATE = DATEADD(DAY, 5, @fecha_venc_1); -- segundo vencimiento: 5 dias despues del primer vencimiento
        
        -- crear la factura
        DECLARE @id_factura INT;
        INSERT INTO eCobros.Factura (
            id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, 
            estado, total, recargo_venc, descuentos
        )
        VALUES (
            @id_socio, @fecha_emision, @fecha_venc_1, @fecha_venc_2, 
            'pendiente', 0, 0, 0 -- valores iniciales
        );
        
        SET @id_factura = SCOPE_IDENTITY();
        
        -- variables para calculos
        DECLARE @total DECIMAL(10,2) = 0;
        DECLARE @porcentaje_descuento_familiar DECIMAL(5,2) = 0;
        DECLARE @porcentaje_descuento_actividades DECIMAL(5,2) = 0;
        DECLARE @total_membresias DECIMAL(10,2) = 0;
        DECLARE @total_actividades DECIMAL(10,2) = 0;
        DECLARE @id_grupo_familiar INT;
        DECLARE @id_categoria INT;
        DECLARE @costo_membresia DECIMAL(10,2);
        
        -- obtener datos del socio
        SELECT 
            @id_grupo_familiar = id_grupo_familiar,
            @id_categoria = id_categoria
        FROM eSocios.Socio
        WHERE id_socio = @id_socio;
        
        -- obtener costo de membresia
        SELECT @costo_membresia = costo_mensual 
        FROM eSocios.Categoria 
        WHERE id_categoria = @id_categoria;
        
        -- agregar membresia a la factura
        INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto, periodo)
        VALUES (@id_factura, 'Membresia', @costo_membresia, @periodo);
        
        SET @total_membresias = @costo_membresia;
        
        -- actualizar items de factura pendientes (actividades y pileta)
        UPDATE eCobros.ItemFactura
        SET id_factura = @id_factura
        WHERE id_socio = @id_socio AND id_factura IS NULL AND periodo = @periodo;
        
        -- calcular total de actividades
        SELECT @total_actividades = SUM(monto)
        FROM eCobros.ItemFactura
        WHERE id_factura = @id_factura AND concepto = 'actividad';
        
        -- calcular porcentajes de descuento
        -- descuento familiar (15% en membresias)
        IF @id_grupo_familiar IS NOT NULL
        BEGIN
            SET @porcentaje_descuento_familiar = 15;
        END
        
        -- descuento por multiples actividades (10% en actividades)
        DECLARE @cant_actividades INT;
        SELECT @cant_actividades = COUNT(*)
        FROM eCobros.ItemFactura
        WHERE id_factura = @id_factura AND concepto = 'actividad';
        
        IF @cant_actividades > 1
        BEGIN
            SET @porcentaje_descuento_actividades = 10;
        END
        
        -- calcular total con descuentos aplicados
        DECLARE @total_con_descuentos DECIMAL(10,2) = 0;
        
        -- aplicar descuento familiar a membresias
        SET @total_con_descuentos = @total_membresias * (1 - (@porcentaje_descuento_familiar/100));
        
        -- aplicar descuento actividades
        SET @total_con_descuentos = @total_con_descuentos + (@total_actividades * (1 - (@porcentaje_descuento_actividades/100)));
        
        -- sumar otros conceptos (pileta, etc)
        SET @total_con_descuentos = @total_con_descuentos + 
            ISNULL((SELECT SUM(monto) FROM eCobros.ItemFactura 
                   WHERE id_factura = @id_factura AND concepto NOT IN ('membresia', 'actividad')), 0);
        
        -- actualizar factura con totales y porcentaje de descuentos
        UPDATE eCobros.Factura
        SET 
            total = @total_con_descuentos,
            descuentos = @porcentaje_descuento_familiar + @porcentaje_descuento_actividades,
            recargo_venc = 0
        WHERE id_factura = @id_factura;
        
        -- actualizar registros de pileta con el id_factura
        UPDATE eCobros.Pileta
        SET id_factura = @id_factura
        WHERE id_socio = @id_socio AND id_factura IS NULL AND 
              CONVERT(VARCHAR(7), fecha, 111) = CONVERT(VARCHAR(7), @periodo, 111);
        
        COMMIT TRANSACTION;
        RETURN @id_factura; -- retorna el id de la factura generada
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        THROW;
    END CATCH
END;
GO

-- procedimiento para aplicar recargo por segundo vencimiento (version modificada)
CREATE PROCEDURE eCobros.AplicarRecargoSegundoVencimiento
    @id_factura INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- verificar si la factura esta en segundo vencimiento
        DECLARE @fecha_venc_1 DATE;
        DECLARE @fecha_venc_2 DATE;
        DECLARE @estado VARCHAR(20);
        DECLARE @total_actual DECIMAL(10,2);
        DECLARE @recargo_aplicado BIT = 0;
        DECLARE @porcentaje_recargo DECIMAL(5,2) = 10; -- porcentaje fijo de recargo
        
        SELECT 
            @fecha_venc_1 = fecha_venc_1,
            @fecha_venc_2 = fecha_venc_2,
            @estado = estado,
            @total_actual = total
        FROM eCobros.Factura
        WHERE id_factura = @id_factura;
        
        -- verificar si ya se aplico recargo
        IF EXISTS 
		(
            SELECT 1 FROM eCobros.ItemFactura 
            WHERE id_factura = @id_factura 
            AND concepto = 'recargo por segundo vencimiento'
        )
        BEGIN
            SET @recargo_aplicado = 1;
        END
        
        -- verificar condiciones para aplicar recargo
        IF @estado = 'pendiente' AND 
           GETDATE() > @fecha_venc_1 AND 
           GETDATE() <= @fecha_venc_2 AND 
           @recargo_aplicado = 0
        BEGIN
            -- calcular monto del recargo (10% del total actual)
            DECLARE @monto_recargo DECIMAL(10,2) = @total_actual * (@porcentaje_recargo / 100.0);
            
            -- actualizar factura con nuevo total y establecer recargo_venc a 10
            UPDATE eCobros.Factura
            SET 
                total = @total_actual + @monto_recargo,
                recargo_venc = @porcentaje_recargo -- ahora si establecemos el 10%
            WHERE id_factura = @id_factura;
            
            -- registrar item de recargo
            INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto, periodo)
            VALUES (
                @id_factura, 
                'recargo por segundo vencimiento', 
                @monto_recargo, 
                CONVERT(VARCHAR(7), GETDATE(), 111)
            );
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO
