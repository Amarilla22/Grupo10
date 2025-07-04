
USE Com5600G10
GO


CREATE OR ALTER PROCEDURE eReportes.GenerarDatosFacturas
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @i INT = 1;
    DECLARE @id_socio VARCHAR(20);
    DECLARE @fecha_emision DATE;
    DECLARE @fecha_venc_1 DATE;
    DECLARE @fecha_venc_2 DATE;
    DECLARE @estado_factura VARCHAR(20);
    DECLARE @total_factura DECIMAL(10,2);

    WHILE @i <= 300
    BEGIN
        -- 1. Socio activo al azar
        SELECT TOP 1 @id_socio = id_socio FROM eSocios.Socio WHERE activo = 1 ORDER BY NEWID();

        -- 2. Fechas
        SET @fecha_emision = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 730, '2023-01-01');
        SET @fecha_venc_1 = DATEADD(DAY, 5, @fecha_emision);
        SET @fecha_venc_2 = DATEADD(DAY, 5, @fecha_venc_1);

        -- 3. Estado aleatorio
        DECLARE @estado_aleatorio INT = ABS(CHECKSUM(NEWID())) % 100;
        IF @estado_aleatorio < 70
            SET @estado_factura = 'pagada';
        ELSE IF @estado_aleatorio < 90
            SET @estado_factura = 'pendiente';
        ELSE
            SET @estado_factura = 'anulada';

        -- 4. Seleccionar actividades sin filtrar por vigencia
        DECLARE @cantidad_items INT = 1 + ABS(CHECKSUM(NEWID())) % 3;
        DECLARE @actividad TABLE (
            id_actividad INT,
            nombre NVARCHAR(50),
            costo DECIMAL(10,2)
        );

        INSERT INTO @actividad (id_actividad, nombre, costo)
        SELECT TOP (@cantidad_items) id_actividad, nombre, costo_mensual
        FROM eSocios.Actividad
        ORDER BY NEWID();

        -- 5. Calcular total solo si hay actividades
        IF EXISTS (SELECT 1 FROM @actividad)
        BEGIN
            SELECT @total_factura = SUM(costo) FROM @actividad;

            INSERT INTO eCobros.Factura (
                id_socio, fecha_emision, fecha_venc_1, fecha_venc_2,
                estado, total, recargo_venc, descuentos
            )
            VALUES (
                @id_socio, @fecha_emision, @fecha_venc_1, @fecha_venc_2,
                @estado_factura, @total_factura, 10, 0
            );

            DECLARE @id_factura INT = SCOPE_IDENTITY();

            -- 6. Insertar ítems (sin campo periodo)
            INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto)
            SELECT 
                @id_factura,
                nombre,
                costo
            FROM @actividad;

            -- 7. Insertar pagos si corresponde
            IF @estado_factura = 'pagada'
            BEGIN
                DECLARE @monto_pagado DECIMAL(10,2);
                DECLARE @pagos INT = 1 + ABS(CHECKSUM(NEWID())) % 2;
                DECLARE @j INT = 1;
                DECLARE @con_recargo BIT = ABS(CHECKSUM(NEWID())) % 2;

                WHILE @j <= @pagos
                BEGIN
                    SET @monto_pagado = CASE 
                        WHEN @con_recargo = 1 THEN ROUND(@total_factura * 1.1, 2)
                        ELSE @total_factura
                    END;

                    IF @pagos = 2 AND @j = 1
                        SET @monto_pagado = ROUND(@monto_pagado * 0.5, 2);

                    INSERT INTO eCobros.Pago (
                        id_pago, id_factura, medio_pago, monto, fecha, estado, debito_auto
                    )
                    VALUES (
                        CAST(CAST(NEWID() AS BINARY(8)) AS BIGINT),
                        @id_factura,
                        (SELECT TOP 1 medio_pago FROM (VALUES 
                            ('visa'), ('masterCard'), ('tarjeta naranja'),
                            ('pago facil'), ('rapipago'), ('mercado pago'), ('efectivo')
                        ) AS mp(medio_pago) ORDER BY NEWID()),
                        @monto_pagado,
                        CASE 
                            WHEN @con_recargo = 1 THEN DATEADD(DAY, 6, @fecha_venc_1)
                            ELSE DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 4, @fecha_emision)
                        END,
                        'completado',
                        ABS(CHECKSUM(NEWID())) % 2
                    );

                    SET @j += 1;
                END
            END
        END

        SET @i += 1;
    END

    PRINT 'Carga de facturas con ítems y pagos generada correctamente';
END
GO


EXEC eReportes.GenerarDatosFacturas
GO


CREATE OR ALTER PROCEDURE eReportes.MorososRecurrentes
    @FechaInicio DATE,
    @FechaFin DATE,
    @MinFallos INT = 2  -- Mínimo número de fallos para incluir en el ranking
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validación de parámetros
    IF @FechaInicio IS NULL OR @FechaFin IS NULL
    BEGIN
        RAISERROR('Las fechas de inicio y fin son obligatorias', 16, 1);
        RETURN;
    END
    
    IF @FechaInicio > @FechaFin
    BEGIN
        RAISERROR('La fecha de inicio no puede ser mayor que la fecha de fin', 16, 1);
        RETURN;
    END
    
    -- Mostrar información del reporte
    PRINT '*** RANKING DE SOCIOS CON FALLOS DE PAGO ***';
    PRINT 'Período: ' + FORMAT(@FechaInicio, 'dd/MM/yyyy') + ' al ' + FORMAT(@FechaFin, 'dd/MM/yyyy');
    PRINT 'Mínimo fallos requeridos: ' + CAST(@MinFallos AS VARCHAR(10));
    PRINT 'Fecha de generación: ' + FORMAT(GETDATE(), 'dd/MM/yyyy HH:mm:ss');
    PRINT 'Criterio: Pago total de factura después del segundo vencimiento';
    PRINT '';
    
    -- RESULTADO PRINCIPAL DEL REPORTE
    WITH FacturasConPagos AS (
        SELECT 
            f.id_factura,
            f.id_socio,
            f.fecha_emision,
            f.fecha_venc_1,
            f.fecha_venc_2,
            f.total as total_factura,
            f.estado,
            -- Sumar pagos completados para cada factura (Windows Function)
            SUM(CASE WHEN p.estado = 'completado' THEN p.monto ELSE 0 END) 
                OVER (PARTITION BY f.id_factura) as total_pagado,
            -- Fecha del último pago completado (Windows Function)
            MAX(CASE WHEN p.estado = 'completado' THEN p.fecha END) 
                OVER (PARTITION BY f.id_factura) as fecha_ultimo_pago
        FROM eCobros.Factura f
        LEFT JOIN eCobros.Pago p ON f.id_factura = p.id_factura
        WHERE 
            -- Facturas en el período especificado
            (f.fecha_venc_1 BETWEEN @FechaInicio AND @FechaFin)
            OR (f.fecha_venc_2 BETWEEN @FechaInicio AND @FechaFin AND f.fecha_venc_2 IS NOT NULL)
    ),
    
    FacturasPagadasCompletas AS (
        SELECT DISTINCT
            id_factura,
            id_socio,
            fecha_emision,
            fecha_venc_1,
            fecha_venc_2,
            total_factura,
            total_pagado,
            fecha_ultimo_pago
        FROM FacturasConPagos
        WHERE 
            -- Solo facturas pagadas completamente
            total_pagado >= total_factura
            AND fecha_ultimo_pago IS NOT NULL
    ),
    
    FallosPago AS (
        SELECT 
            id_factura,
            id_socio,
            fecha_emision,
            fecha_venc_1,
            fecha_venc_2,
            total_factura,
            total_pagado,
            fecha_ultimo_pago,
            -- Determinar si es un fallo
            CASE 
                WHEN fecha_venc_2 IS NOT NULL AND fecha_ultimo_pago > fecha_venc_2 
                THEN 1
                WHEN fecha_venc_2 IS NULL AND fecha_ultimo_pago > fecha_venc_1 
                THEN 1
                ELSE 0
            END as es_fallo,
            -- Mes del fallo
            FORMAT(fecha_ultimo_pago, 'yyyy-MM') as mes_fallo
        FROM FacturasPagadasCompletas
    ),
    
    ResumenPorSocio AS (
        SELECT 
            fp.id_socio,
            s.nombre,
            s.apellido,
            -- Conteo de fallos
            SUM(fp.es_fallo) as total_fallos,
            -- Mes del último fallo
            MAX(CASE WHEN fp.es_fallo = 1 THEN fp.mes_fallo END) as mes_ultimo_fallo
        FROM FallosPago fp
        INNER JOIN eSocios.Socio s ON fp.id_socio = s.id_socio
        WHERE s.activo = 1
        GROUP BY fp.id_socio, s.nombre, s.apellido
        HAVING SUM(fp.es_fallo) >= @MinFallos
    ),
    
    RankingFinal AS (
        SELECT 
            id_socio,
            nombre,
            apellido,
            total_fallos,
            mes_ultimo_fallo,
            -- Ranking por total de fallos (Windows Function)
            DENSE_RANK() OVER (ORDER BY total_fallos DESC) as ranking_fallos
        FROM ResumenPorSocio
    )
    
    SELECT 
        ranking_fallos as 'Ranking',
        id_socio as 'Nro Socio',
        CONCAT(nombre, ' ', apellido) as 'Nombre y Apellido',
        mes_ultimo_fallo as 'Mes Incumplido'
    FROM RankingFinal
    ORDER BY 
        ranking_fallos ASC,
        id_socio ASC;
    
END;
GO


EXEC eReportes.MorososRecurrentes '2023-01-01', '2024-12-31';
GO


CREATE OR ALTER PROCEDURE eReportes.ReporteAcumuladoMensual
    @Anio INT = NULL -- Parámetro opcional, si no se especifica toma el año actual
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Si no se especifica año, tomar el año actual
    IF @Anio IS NULL
        SET @Anio = YEAR(GETDATE());
    
    -- Obtener los datos base con los meses como números
    WITH DatosBase AS (
        SELECT 
            itf.concepto AS Actividad,
            MONTH(f.fecha_emision) AS Mes,
            SUM(itf.monto) AS MontoMes
        FROM eCobros.Factura f
        INNER JOIN eCobros.ItemFactura itf ON f.id_factura = itf.id_factura
        WHERE YEAR(f.fecha_emision) = @Anio
            AND f.estado = 'pagada'
            AND f.fecha_emision <= GETDATE()
        GROUP BY itf.concepto, MONTH(f.fecha_emision)
    ),
    -- Aplicar PIVOT para convertir meses en columnas
    ReportePivot AS (
        SELECT 
            Actividad,
            ISNULL([1], 0) AS Enero,
            ISNULL([2], 0) AS Febrero,
            ISNULL([3], 0) AS Marzo,
            ISNULL([4], 0) AS Abril,
            ISNULL([5], 0) AS Mayo,
            ISNULL([6], 0) AS Junio,
            ISNULL([7], 0) AS Julio,
            ISNULL([8], 0) AS Agosto,
            ISNULL([9], 0) AS Septiembre,
            ISNULL([10], 0) AS Octubre,
            ISNULL([11], 0) AS Noviembre,
            ISNULL([12], 0) AS Diciembre
        FROM DatosBase
        PIVOT (
            SUM(MontoMes)
            FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
        ) AS PivotTable
    )
    -- Resultado final con formato de moneda y total
    SELECT 
        Actividad,
        FORMAT(Enero, 'C', 'es-AR') AS Enero,
        FORMAT(Febrero, 'C', 'es-AR') AS Febrero,
        FORMAT(Marzo, 'C', 'es-AR') AS Marzo,
        FORMAT(Abril, 'C', 'es-AR') AS Abril,
        FORMAT(Mayo, 'C', 'es-AR') AS Mayo,
        FORMAT(Junio, 'C', 'es-AR') AS Junio,
        FORMAT(Julio, 'C', 'es-AR') AS Julio,
        FORMAT(Agosto, 'C', 'es-AR') AS Agosto,
        FORMAT(Septiembre, 'C', 'es-AR') AS Septiembre,
        FORMAT(Octubre, 'C', 'es-AR') AS Octubre,
        FORMAT(Noviembre, 'C', 'es-AR') AS Noviembre,
        FORMAT(Diciembre, 'C', 'es-AR') AS Diciembre,
        FORMAT(
            Enero + Febrero + Marzo + Abril + Mayo + Junio + 
            Julio + Agosto + Septiembre + Octubre + Noviembre + Diciembre, 
            'C', 'es-AR'
        ) AS Total
    FROM ReportePivot
    ORDER BY 
        Enero + Febrero + Marzo + Abril + Mayo + Junio + 
        Julio + Agosto + Septiembre + Octubre + Noviembre + Diciembre DESC;
END;
GO


EXEC eReportes.ReporteAcumuladoMensual @Anio = 2024;
GO


CREATE OR ALTER PROCEDURE eReportes.ReportesCantInasistencias
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.nombre AS categoria_socio,
        a.nombre AS actividad,
        COUNT(DISTINCT s.id_socio) AS cantidad_socios_con_inasistencias,
        COUNT(p.id_presentismo) AS total_inasistencias
    FROM eSocios.Presentismo p
    INNER JOIN eSocios.Socio s ON p.id_socio = s.id_socio
    INNER JOIN eSocios.Categoria c ON s.id_categoria = c.id_categoria
    INNER JOIN eSocios.Actividad a ON p.id_actividad = a.id_actividad
    WHERE p.asistencia IN ('A', 'J') -- Solo ausentes (justificados y no justificados)
    GROUP BY 
        c.id_categoria,
        c.nombre,
        a.id_actividad,
        a.nombre
    ORDER BY 
        total_inasistencias DESC,
        categoria_socio,
        actividad;
    
END
GO


EXEC eReportes.ReportesCantInasistencias
GO


CREATE OR ALTER PROCEDURE eReportes.ReportesSociosInasistencias
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.nombre,
        s.apellido,
        DATEDIFF(YEAR, s.fecha_nac, GETDATE()) 
            - CASE 
                WHEN MONTH(s.fecha_nac) > MONTH(GETDATE()) 
                     OR (MONTH(s.fecha_nac) = MONTH(GETDATE()) AND DAY(s.fecha_nac) > DAY(GETDATE()))
                THEN 1 ELSE 0 
            END AS edad,
        cat.nombre AS categoria,
        act.nombre AS actividad
    FROM eSocios.Presentismo p
    INNER JOIN eSocios.Socio s ON s.id_socio = p.id_socio
    INNER JOIN eSocios.Actividad act ON act.id_actividad = p.id_actividad
    INNER JOIN eSocios.Categoria cat ON cat.id_categoria = s.id_categoria
    WHERE p.asistencia IN ('A', 'J')
    GROUP BY s.nombre, s.apellido, s.fecha_nac, cat.nombre, act.nombre
    ORDER BY s.apellido, s.nombre;
END
GO


EXEC eReportes.ReportesSociosInasistencias