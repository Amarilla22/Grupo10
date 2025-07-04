
USE Com5600G10
GO



CREATE OR ALTER PROCEDURE eImportacion.ImportarTarifasCategorias
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Crear tabla temporal para importación
        CREATE TABLE #ImportacionCategorias 
        (
            CategoriaSocio VARCHAR(50),
            ValorCuota DECIMAL(10,2),
            VigenteHasta DATE
        );
        
        -- Crear y ejecutar una consulta dinámica para importar desde excel
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
        INSERT INTO #ImportacionCategorias 
        SELECT * FROM OPENROWSET( 
            ''Microsoft.ACE.OLEDB.12.0'', 
            ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'', 
            ''SELECT * FROM [Tarifas$B11:D13]'' 
        );';
        
        EXEC sp_executesql @SQL;
        
        -- Variables para contadores
        DECLARE @FilasInsertadas INT = 0;
        DECLARE @FilasOmitidas INT = 0;
        DECLARE @TotalFilas INT;
        
        -- Contar total de filas válidas en la importación
        SELECT @TotalFilas = COUNT(*)
        FROM #ImportacionCategorias
        WHERE CategoriaSocio IS NOT NULL;
        
        -- Insertar solo los registros que no existen
        INSERT INTO eSocios.Categoria (nombre, costo_mensual, Vigencia)
        SELECT 
            ic.CategoriaSocio,
            ic.ValorCuota,
            ic.VigenteHasta
        FROM #ImportacionCategorias ic
        WHERE ic.CategoriaSocio IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 
            FROM eSocios.Categoria c 
            WHERE c.nombre = ic.CategoriaSocio 
            AND c.costo_mensual = ic.ValorCuota 
            AND c.vigencia = ic.VigenteHasta
        );
        
        SET @FilasInsertadas = @@ROWCOUNT;
        SET @FilasOmitidas = @TotalFilas - @FilasInsertadas;
        
        -- Limpiar tabla temporal
        DROP TABLE #ImportacionCategorias;
        
        -- Devolver resultado detallado
        SELECT 
            @FilasInsertadas as FilasInsertadas,
            @FilasOmitidas as FilasOmitidas,
            @TotalFilas as TotalFilasProcesadas,
            CASE 
                WHEN @FilasInsertadas > 0 AND @FilasOmitidas = 0 THEN 'Importación completada exitosamente'
                WHEN @FilasInsertadas > 0 AND @FilasOmitidas > 0 THEN 'Importación completada con duplicados omitidos'
                WHEN @FilasInsertadas = 0 AND @FilasOmitidas > 0 THEN 'No se insertaron registros - todos son duplicados'
                ELSE 'No se encontraron registros válidos para importar'
            END as Mensaje;
            
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        IF OBJECT_ID('tempdb..#ImportacionCategorias') IS NOT NULL
            DROP TABLE #ImportacionCategorias;
            
        SELECT 
            ERROR_NUMBER() as ErrorNumero,
            ERROR_MESSAGE() as ErrorMensaje,
            'Error en la importación de categorías' as Estado;
    END CATCH
END 
GO


EXEC eImportacion.ImportarTarifasCategorias @RutaArchivo = 'S:\importacion\Datos socios.xlsx'
GO


CREATE OR ALTER PROCEDURE eImportacion.ImportarTarifasPrecioPileta
    @RutaArchivo NVARCHAR(500),
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Crear tabla temporal para importación
        CREATE TABLE #ImportacionActividades 
        (
            Col1 NVARCHAR(100),
            Col2 NVARCHAR(100),
            Col3 NVARCHAR(100), 
            Col4 NVARCHAR(100),
            Col5 NVARCHAR(100)
        );
        
        -- Importar datos desde excel
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
        INSERT INTO #ImportacionActividades 
        SELECT * FROM OPENROWSET( 
            ''Microsoft.ACE.OLEDB.12.0'', 
            ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'', 
            ''SELECT * FROM [Tarifas$B16:F22]'' 
        );';
        
        EXEC sp_executesql @SQL;
        
        IF @Debug = 1 -- Muestra datos importados
        BEGIN
            SELECT 'Datos importados:' as Mensaje;
            SELECT * FROM #ImportacionActividades;
            
            SELECT 'Conteo de filas:' as Mensaje, COUNT(*) as Total FROM #ImportacionActividades;
        END;
        
        -- Crear tabla temporal con los datos a insertar
        CREATE TABLE #DatosAInsertar 
        (
            categoria VARCHAR(30),
            tipo_usuario VARCHAR(20),
            modalidad VARCHAR(30),
            precio DECIMAL(10,2),
            vigencia_hasta DATE,
            activo BIT
        );
        
        DECLARE @FechaVigencia DATE = '2025-02-28';
        
        -- Cargar datos en tabla temporal
        INSERT INTO #DatosAInsertar (categoria, tipo_usuario, modalidad, precio, vigencia_hasta, activo)
        VALUES 
        -- Valor del día
        ('Adultos', 'Socios', 'Valor del dia', 25000.00, @FechaVigencia, 1),
        ('Adultos', 'Invitados', 'Valor del dia', 30000.00, @FechaVigencia, 1),
        ('Menores de 12 años', 'Socios', 'Valor del dia', 15000.00, @FechaVigencia, 1),
        ('Menores de 12 años', 'Invitados', 'Valor del dia', 2000.00, @FechaVigencia, 1),
        
        -- Valor de temporada (socios)
        ('Adultos', 'Socios', 'Valor de temporada', 2000000.00, @FechaVigencia, 1),
        ('Menores de 12 años', 'Socios', 'Valor de temporada', 1200000.00, @FechaVigencia, 1),
        
        -- Valor del Mes (socios)
        ('Adultos', 'Socios', 'Valor del Mes', 625000.00, @FechaVigencia, 1),
        ('Menores de 12 años', 'Socios', 'Valor del Mes', 375000.00, @FechaVigencia, 1);
        
        -- Variables para contadores
        DECLARE @FilasInsertadas INT = 0;
        DECLARE @FilasOmitidas INT = 0;
        DECLARE @TotalFilas INT;
        DECLARE @FilasDesactivadas INT = 0;
        DECLARE @FilasActualizadas INT = 0;
        
        -- Contar total de filas a procesar
        SELECT @TotalFilas = COUNT(*) FROM #DatosAInsertar;
        
        -- MEJORA 1: Verificar si ya existen registros activos con la misma combinación
        -- categoria + tipo_usuario + modalidad + vigencia_hasta
        IF @Debug = 1
        BEGIN
            SELECT 'Registros activos que coinciden con los nuevos:' as Mensaje;
            SELECT pa.*, 'EXISTENTE' as Estado
            FROM eCobros.PreciosAcceso pa
            INNER JOIN #DatosAInsertar di ON 
                pa.categoria = di.categoria 
                AND pa.tipo_usuario = di.tipo_usuario 
                AND pa.modalidad = di.modalidad
                AND pa.vigencia_hasta = di.vigencia_hasta
            WHERE pa.activo = 1;
        END;
        
        -- MEJORA 2: Estrategia mejorada para evitar duplicados
        -- Opción A: Actualizar precios existentes en lugar de desactivar
        UPDATE pa 
        SET 
            precio = di.precio,
            fecha_creacion = GETDATE()
        FROM eCobros.PreciosAcceso pa
        INNER JOIN #DatosAInsertar di ON 
            pa.categoria = di.categoria 
            AND pa.tipo_usuario = di.tipo_usuario 
            AND pa.modalidad = di.modalidad
            AND pa.vigencia_hasta = di.vigencia_hasta
        WHERE pa.activo = 1 
        AND pa.precio != di.precio; -- Solo actualizar si el precio cambió
        
        SET @FilasActualizadas = @@ROWCOUNT;
        
        -- MEJORA 3: Insertar solo registros completamente nuevos
        -- (que no existan con la misma combinación categoria+tipo_usuario+modalidad+vigencia_hasta)
        INSERT INTO eCobros.PreciosAcceso (categoria, tipo_usuario, modalidad, precio, vigencia_hasta, activo)
        SELECT 
            di.categoria,
            di.tipo_usuario,
            di.modalidad,
            di.precio,
            di.vigencia_hasta,
            di.activo
        FROM #DatosAInsertar di
        WHERE NOT EXISTS (
            SELECT 1 
            FROM eCobros.PreciosAcceso pa 
            WHERE pa.categoria = di.categoria 
            AND pa.tipo_usuario = di.tipo_usuario 
            AND pa.modalidad = di.modalidad 
            AND pa.vigencia_hasta = di.vigencia_hasta 
            AND pa.activo = 1  -- Solo verificar contra registros activos
        );
        
        SET @FilasInsertadas = @@ROWCOUNT;
        SET @FilasOmitidas = @TotalFilas - @FilasInsertadas - @FilasActualizadas;
        
        -- MEJORA 4: Verificación final de duplicados
        IF @Debug = 1
        BEGIN
            SELECT 'Verificación de duplicados activos:' as Mensaje;
            SELECT 
                categoria, 
                tipo_usuario, 
                modalidad, 
                vigencia_hasta, 
                COUNT(*) as Cantidad
            FROM eCobros.PreciosAcceso 
            WHERE activo = 1
            GROUP BY categoria, tipo_usuario, modalidad, vigencia_hasta
            HAVING COUNT(*) > 1;
            
            SELECT 'Registros activos después de la importación:' as Mensaje;
            SELECT * FROM eCobros.PreciosAcceso WHERE activo = 1
            ORDER BY categoria, tipo_usuario, modalidad, vigencia_hasta;
        END;
        
        -- Limpiar tablas temporales
        DROP TABLE #ImportacionActividades;
        DROP TABLE #DatosAInsertar;
        
        -- Devolver resultado detallado
        SELECT 
            @FilasInsertadas as FilasInsertadas,
            @FilasActualizadas as FilasActualizadas,
            @FilasOmitidas as FilasOmitidas,
            @FilasDesactivadas as FilasDesactivadas,
            @TotalFilas as TotalFilasProcesadas,
            CASE 
                WHEN @FilasInsertadas > 0 AND @FilasActualizadas = 0 AND @FilasOmitidas = 0 THEN 'Importación completada exitosamente - Solo inserciones'
                WHEN @FilasInsertadas = 0 AND @FilasActualizadas > 0 AND @FilasOmitidas >= 0 THEN 'Importación completada exitosamente - Solo actualizaciones'
                WHEN @FilasInsertadas > 0 AND @FilasActualizadas > 0 THEN 'Importación completada exitosamente - Inserciones y actualizaciones'
                WHEN @FilasInsertadas = 0 AND @FilasActualizadas = 0 AND @FilasOmitidas > 0 THEN 'No se realizaron cambios - todos los registros ya existen'
                ELSE 'No se encontraron registros válidos para importar'
            END as Mensaje;
        
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        IF OBJECT_ID('tempdb..#ImportacionActividades') IS NOT NULL
            DROP TABLE #ImportacionActividades;
            
        IF OBJECT_ID('tempdb..#DatosAInsertar') IS NOT NULL
            DROP TABLE #DatosAInsertar;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        SELECT 
            ERROR_NUMBER() as ErrorNumero,
            @ErrorMessage as ErrorMensaje,
            'Error en la importación de precios de acceso' as Estado;
    END CATCH
END; 
GO


EXEC eImportacion.ImportarTarifasPrecioPileta @RutaArchivo = 'S:\importacion\Datos socios.xlsx'
GO


CREATE OR ALTER PROCEDURE eImportacion.ImportarTarifasActividades
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
   
        CREATE TABLE #ImportacionActividades 
		(
            Actividad NVARCHAR(50),
            ValorPorMes DECIMAL(10,2),
            VigenteHasta DATE
        );
        
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
        INSERT INTO #ImportacionActividades 
        SELECT * FROM OPENROWSET( 
            ''Microsoft.ACE.OLEDB.12.0'', 
            ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'', 
            ''SELECT * FROM [Tarifas$B3:D8]'' 
        );';
        
        EXEC sp_executesql @SQL;
        
        -- Insertar en la tabla definitiva SOLO registros que no existan
        -- Evitar duplicados basándose en nombre, costo_mensual y vigencia
        DECLARE @FilasInsertadas INT;
        
        INSERT INTO eSocios.Actividad (nombre, costo_mensual, vigencia)
        SELECT 
            i.Actividad,
            i.ValorPorMes,
            i.VigenteHasta
        FROM #ImportacionActividades i
        WHERE i.Actividad IS NOT NULL -- Filtrar filas vacías
        AND NOT EXISTS (
            SELECT 1 
            FROM eSocios.Actividad a 
            WHERE a.nombre = i.Actividad 
            AND a.costo_mensual = i.ValorPorMes 
            AND a.vigencia = i.VigenteHasta
        );
        
        SET @FilasInsertadas = @@ROWCOUNT;
        
        -- Obtener registros duplicados para reporte
        DECLARE @FilasDuplicadas INT;
        SELECT @FilasDuplicadas = COUNT(*)
        FROM #ImportacionActividades i
        WHERE i.Actividad IS NOT NULL
        AND EXISTS (
            SELECT 1 
            FROM eSocios.Actividad a 
            WHERE a.nombre = i.Actividad 
            AND a.costo_mensual = i.ValorPorMes 
            AND a.vigencia = i.VigenteHasta
        );
        
        -- Limpiar tabla temporal
        DROP TABLE #ImportacionActividades;
        
        -- Resultado con información detallada
        SELECT 
            @FilasInsertadas as FilasInsertadas,
            @FilasDuplicadas as FilasDuplicadas,
            CASE 
                WHEN @FilasInsertadas > 0 AND @FilasDuplicadas = 0 
                    THEN 'Importación completada exitosamente'
                WHEN @FilasInsertadas > 0 AND @FilasDuplicadas > 0 
                    THEN 'Importación completada con duplicados omitidos'
                WHEN @FilasInsertadas = 0 AND @FilasDuplicadas > 0 
                    THEN 'No se insertaron registros'
                ELSE 'No se encontraron registros válidos para importar'
            END as Mensaje;
            
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        IF OBJECT_ID('tempdb..#ImportacionActividades') IS NOT NULL
            DROP TABLE #ImportacionActividades;
            
        SELECT 
            ERROR_NUMBER() as ErrorNumero,
            ERROR_MESSAGE() as ErrorMensaje,
            'Error en la importación' as Estado;
    END CATCH
END 
GO

EXEC eImportacion.ImportarTarifasActividades @RutaArchivo = 'S:\importacion\Datos socios.xlsx'
GO

CREATE OR ALTER PROCEDURE eImportacion.ImportarResponsablesDePago
    @RutaArchivo NVARCHAR(260),
    @IdCategoria INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @insertados INT = 0;
    DECLARE @total INT = 0;
    
    -- tabla temporal para importación
    CREATE TABLE #ImportacionSocios 
	(
        id_socio NVARCHAR(50),
        nombre NVARCHAR(50),
        apellido NVARCHAR(50),
        dni NVARCHAR(50),
        email NVARCHAR(100),
        fecha_nac NVARCHAR(50),
        telefono NVARCHAR(50),
        telefono_emergencia NVARCHAR(50),
        obra_social NVARCHAR(50),
        nro_obra_social NVARCHAR(50),
        tel_obra_social NVARCHAR(50)
    );
    
    -- Importar datos
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
        INSERT INTO #ImportacionSocios
        SELECT * FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'',
            ''SELECT * FROM [Responsables de Pago$]''
        );
    ';
    EXEC sp_executesql @sql;
    
    -- total de registros importados
    SELECT @total = COUNT(*) FROM #ImportacionSocios;
    
    -- Limpiar y validar datos antes de insertar
    ;WITH DatosLimpios AS (
        SELECT
            CASE 
                WHEN LEN(LTRIM(RTRIM(id_socio))) <= 20 THEN LTRIM(RTRIM(id_socio))
                ELSE LEFT(LTRIM(RTRIM(id_socio)), 20)
            END AS id_socio,
            @IdCategoria AS id_categoria,
            TRY_CAST(REPLACE(REPLACE(dni, '.', ''), '-', '') AS INT) AS dni,

            CASE 
                WHEN LEN(LTRIM(RTRIM(nombre))) <= 50 THEN LTRIM(RTRIM(nombre))
                ELSE LEFT(LTRIM(RTRIM(nombre)), 50)
            END AS nombre,
            CASE 
                WHEN LEN(LTRIM(RTRIM(apellido))) <= 50 THEN LTRIM(RTRIM(apellido))
                ELSE LEFT(LTRIM(RTRIM(apellido)), 50)
            END AS apellido,
            LOWER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(email, ' ', ''), '_', '.'), '..', '.')))) AS email,
            TRY_CONVERT(DATE, fecha_nac, 103) AS fecha_nac,
            TRY_CAST(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(telefono, ' ', ''), '-', ''), '/', ''), '.', ''), '(', ''), ')', '') AS BIGINT) AS telefono,
            TRY_CAST(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(telefono_emergencia, ' ', ''), '-', ''), '/', ''), '.', ''), '(', ''), ')', '') AS BIGINT) AS telefono_emergencia,

            CASE 
                WHEN LEN(LTRIM(RTRIM(obra_social))) <= 50 THEN LTRIM(RTRIM(obra_social))
                ELSE LEFT(LTRIM(RTRIM(obra_social)), 50)
            END AS obra_social,

            CASE 
                WHEN LEN(LTRIM(RTRIM(nro_obra_social))) <= 15 THEN LTRIM(RTRIM(nro_obra_social))
                ELSE LEFT(LTRIM(RTRIM(nro_obra_social)), 15)
            END AS nro_obra_social,

            TRY_CAST(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tel_obra_social, ' ', ''), '-', ''), '/', ''), '.', ''), '(', ''), ')', '') AS BIGINT) AS tel_obra_social
        FROM #ImportacionSocios
        WHERE
            -- Validaciones básicas
            LTRIM(RTRIM(id_socio)) IS NOT NULL
            AND LTRIM(RTRIM(id_socio)) != ''
            AND LEN(LTRIM(RTRIM(id_socio))) <= 20  -- Validar longitud máxima
            AND TRY_CAST(REPLACE(REPLACE(dni, '.', ''), '-', '') AS INT) IS NOT NULL
            AND TRY_CONVERT(DATE, fecha_nac, 103) IS NOT NULL
            AND LTRIM(RTRIM(nombre)) IS NOT NULL
            AND LTRIM(RTRIM(nombre)) != ''
            AND LTRIM(RTRIM(apellido)) IS NOT NULL
            AND LTRIM(RTRIM(apellido)) != ''
            -- Validaciones de email (las mismas del CHECK constraint)
            AND LOWER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(email, ' ', ''), '_', '.'), '..', '.')))) LIKE '%@%.%'
            AND LOWER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(email, ' ', ''), '_', '.'), '..', '.')))) NOT LIKE '%@%@%'
            AND LOWER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(email, ' ', ''), '_', '.'), '..', '.')))) NOT LIKE '@%'
            AND LOWER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(email, ' ', ''), '_', '.'), '..', '.')))) NOT LIKE '%@'
    ),
    -- Eliminar duplicados dentro del mismo archivo
    DatosSinDuplicados AS (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY id_socio
                ORDER BY (SELECT NULL)
            ) AS rn_id_socio,
            ROW_NUMBER() OVER (
                PARTITION BY dni
                ORDER BY (SELECT NULL)
            ) AS rn_dni,
            ROW_NUMBER() OVER (
                PARTITION BY email
                ORDER BY (SELECT NULL)
            ) AS rn_email
        FROM DatosLimpios
    ),
    -- Solo registros únicos del archivo
    DatosUnicos AS (
        SELECT *
        FROM DatosSinDuplicados
        WHERE rn_id_socio = 1 AND rn_dni = 1 AND rn_email = 1
    )
    -- Insertar solo registros que no existan en la base
    INSERT INTO eSocios.Socio (
        id_socio, id_categoria, dni, nombre, apellido, email,
        fecha_nac, telefono, telefono_emergencia, obra_social,
        nro_obra_social, tel_obra_social, activo
    )
    SELECT 
        du.id_socio, du.id_categoria, du.dni, du.nombre, du.apellido, du.email,
        du.fecha_nac, du.telefono, du.telefono_emergencia, du.obra_social,
        du.nro_obra_social, du.tel_obra_social, 1 -- Valor por defecto para activo
    FROM DatosUnicos du
    WHERE NOT EXISTS 
	(
        SELECT 1 FROM eSocios.Socio s
        WHERE 
            s.id_socio = du.id_socio
            OR s.dni = du.dni
            OR LOWER(LTRIM(RTRIM(s.email))) = du.email
    );
    
    SET @insertados = @@ROWCOUNT;
    
    DROP TABLE #ImportacionSocios;
    
    -- resultado
    PRINT 'Proceso completado:'
    PRINT 'Total de registros procesados: ' + CAST(@total AS NVARCHAR(10))
    PRINT 'Registros insertados: ' + CAST(@insertados AS NVARCHAR(10))
    PRINT 'Registros omitidos (duplicados o inválidos): ' + CAST((@total - @insertados) AS NVARCHAR(10))
    
END;
GO


EXEC eImportacion.ImportarResponsablesDePago @RutaArchivo = 'S:\importacion\Datos socios.xlsx', @IdCategoria = 1;
go


CREATE OR ALTER PROCEDURE eImportacion.ImportarGrupoFamiliar
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    CREATE TABLE #ImportacionSocios (
        [nro de socio] NVARCHAR(50),
        [nro de socio RP] NVARCHAR(50),
        [Nombre] NVARCHAR(50),
        [apellido] NVARCHAR(50),
        [DNI] NVARCHAR(20),
        [email personal] NVARCHAR(100),
        [fecha nac] NVARCHAR(20),
        [telefono contacto] NVARCHAR(40),
        [telefono de emergencia] NVARCHAR(40),
        [nombre de obra social] NVARCHAR(50),
        [nro de obra social] NVARCHAR(40),
        [telefono de obra social] NVARCHAR(40)
    );
    
    -- Cargar datos
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'INSERT INTO #ImportacionSocios 
                SELECT * FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'',
                    ''SELECT * FROM [Grupo Familiar$]''
                );';
    
    EXEC sp_executesql @sql;
    
    -- ELIMINAR FILA DE ENCABEZADOS SI EXISTE
    WITH CTE AS (
        SELECT *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
        FROM #ImportacionSocios
        WHERE [nro de socio] = 'nro de socio' OR [Nombre] = 'Nombre'
    )
    DELETE FROM CTE WHERE rn >= 1;
    
    -- Tabla temporal para registrar errores
    CREATE TABLE #Errores (
        id INT IDENTITY(1,1),
        nro_socio NVARCHAR(50),
        dni NVARCHAR(20),
        error_descripcion NVARCHAR(500)
    );
    
    -- CREAR TABLA TEMPORAL CON DATOS LIMPIOS Y CONVERTIDOS
    CREATE TABLE #DatosLimpios (
        nro_socio NVARCHAR(50),
        nro_socio_rp NVARCHAR(50),
        nombre NVARCHAR(50),
        apellido NVARCHAR(50),
        dni INT,
        email NVARCHAR(100),
        fecha_nac DATE,
        telefono BIGINT,
        telefono_emergencia BIGINT,
        obra_social NVARCHAR(50),
        nro_obra_social NVARCHAR(15),
        tel_obra_social BIGINT
    );
    
    -- INSERTAR DATOS LIMPIOS CON VALIDACIONES
    INSERT INTO #DatosLimpios
    SELECT 
        LTRIM(RTRIM([nro de socio])) as nro_socio,
        CASE 
            WHEN [nro de socio RP] IS NULL OR LTRIM(RTRIM([nro de socio RP])) = '' 
            THEN NULL 
            ELSE LTRIM(RTRIM([nro de socio RP])) 
        END as nro_socio_rp,
        LTRIM(RTRIM([Nombre])) as nombre,
        LTRIM(RTRIM([apellido])) as apellido,
        -- CONVERSIÓN DE DNI 
        CASE 
            WHEN CHARINDEX('e', LOWER([DNI])) > 0 
            THEN CAST(CAST([DNI] AS FLOAT) AS INT)
            ELSE TRY_CAST([DNI] AS INT)
        END as dni,
        CASE 
            WHEN [email personal] IS NULL OR LTRIM(RTRIM([email personal])) = ''
            THEN NULL
            ELSE LTRIM(RTRIM([email personal]))
        END as email,
        -- CONVERSIÓN DE FECHA
        COALESCE(
            TRY_CONVERT(DATE, [fecha nac], 103),  -- dd/mm/yyyy
            TRY_CONVERT(DATE, [fecha nac], 101)   -- mm/dd/yyyy
        ) as fecha_nac,
        -- CONVERSIÓN DE TELÉFONOS A BIGINT
        TRY_CAST(REPLACE(REPLACE(REPLACE([telefono contacto], '-', ''), ' ', ''), '(', '') AS BIGINT) as telefono,
        TRY_CAST(REPLACE(REPLACE(REPLACE([telefono de emergencia], '-', ''), ' ', ''), '(', '') AS BIGINT) as telefono_emergencia,
        CASE 
            WHEN [nombre de obra social] IS NULL OR LTRIM(RTRIM([nombre de obra social])) = ''
            THEN NULL
            ELSE LTRIM(RTRIM([nombre de obra social]))
        END as obra_social,
        CASE 
            WHEN [nro de obra social] IS NULL OR LTRIM(RTRIM([nro de obra social])) = ''
            THEN NULL
            ELSE LTRIM(RTRIM([nro de obra social]))
        END as nro_obra_social,
        TRY_CAST(REPLACE(REPLACE(REPLACE([telefono de obra social], '-', ''), ' ', ''), '(', '') AS BIGINT) as tel_obra_social
    FROM #ImportacionSocios
    WHERE [nro de socio] IS NOT NULL 
      AND LTRIM(RTRIM([nro de socio])) != ''
      AND [DNI] IS NOT NULL 
      AND LTRIM(RTRIM([DNI])) != '';
    
    -- REGISTRAR ERRORES DE CONVERSIÓN Y VALIDACIÓN
    INSERT INTO #Errores (nro_socio, dni, error_descripcion)
    SELECT 
        LTRIM(RTRIM([nro de socio])),
        [DNI],
        CASE 
            WHEN (CASE 
                    WHEN CHARINDEX('e', LOWER([DNI])) > 0 
                    THEN CAST(CAST([DNI] AS FLOAT) AS INT)
                    ELSE TRY_CAST([DNI] AS INT)
                  END) IS NULL 
            THEN 'DNI inválido: ' + ISNULL([DNI], 'NULL')
            WHEN (CASE 
                    WHEN CHARINDEX('e', LOWER([DNI])) > 0 
                    THEN CAST(CAST([DNI] AS FLOAT) AS INT)
                    ELSE TRY_CAST([DNI] AS INT)
                  END) < 1000000 OR (CASE 
                    WHEN CHARINDEX('e', LOWER([DNI])) > 0 
                    THEN CAST(CAST([DNI] AS FLOAT) AS INT)
                    ELSE TRY_CAST([DNI] AS INT)
                  END) > 99999999
            THEN 'DNI fuera de rango: ' + ISNULL([DNI], 'NULL')
            WHEN COALESCE(
                    TRY_CONVERT(DATE, [fecha nac], 103),
                    TRY_CONVERT(DATE, [fecha nac], 101)
                 ) IS NULL
            THEN 'Fecha de nacimiento inválida: ' + ISNULL([fecha nac], 'NULL')
            ELSE 'Error de validación'
        END
    FROM #ImportacionSocios
    WHERE [nro de socio] IS NOT NULL 
      AND LTRIM(RTRIM([nro de socio])) != ''
      AND [DNI] IS NOT NULL 
      AND LTRIM(RTRIM([DNI])) != ''
      AND ([nro de socio] NOT IN (SELECT nro_socio FROM #DatosLimpios WHERE nro_socio IS NOT NULL));
    
    -- VALIDAR DUPLICADOS Y REFERENCIAS
    -- Socios que ya existen
    INSERT INTO #Errores (nro_socio, dni, error_descripcion)
    SELECT dl.nro_socio, CAST(dl.dni AS NVARCHAR), 'El número de socio ya existe'
    FROM #DatosLimpios dl
    INNER JOIN eSocios.Socio s ON s.id_socio = dl.nro_socio;
    
    -- DNIs que ya existen
    INSERT INTO #Errores (nro_socio, dni, error_descripcion)
    SELECT dl.nro_socio, CAST(dl.dni AS NVARCHAR), 'El DNI ya existe'
    FROM #DatosLimpios dl
    INNER JOIN eSocios.Socio s ON s.dni = dl.dni;
    
    -- Responsables que no existen
    INSERT INTO #Errores (nro_socio, dni, error_descripcion)
    SELECT dl.nro_socio, CAST(dl.dni AS NVARCHAR), 'El socio responsable no existe: ' + dl.nro_socio_rp
    FROM #DatosLimpios dl
    LEFT JOIN eSocios.Socio s ON s.id_socio = dl.nro_socio_rp
    WHERE dl.nro_socio_rp IS NOT NULL 
      AND s.id_socio IS NULL;
    
    -- Validar que los responsables tengan email (tutores)
    INSERT INTO #Errores (nro_socio, dni, error_descripcion)
    SELECT dl.nro_socio, CAST(dl.dni AS NVARCHAR), 'El socio responsable no tiene email válido (requerido para tutor)'
    FROM #DatosLimpios dl
    INNER JOIN eSocios.Socio s ON s.id_socio = dl.nro_socio_rp
    WHERE dl.nro_socio_rp IS NOT NULL 
      AND (s.email IS NULL OR s.email = '' OR s.email NOT LIKE '%@%.%');
    
    -- Validar que los responsables tengan teléfono (tutores)
    INSERT INTO #Errores (nro_socio, dni, error_descripcion)
    SELECT dl.nro_socio, CAST(dl.dni AS NVARCHAR), 'El socio responsable no tiene teléfono válido (requerido para tutor)'
    FROM #DatosLimpios dl
    INNER JOIN eSocios.Socio s ON s.id_socio = dl.nro_socio_rp
    WHERE dl.nro_socio_rp IS NOT NULL 
      AND s.telefono IS NULL;
    
    -- INSERTAR SOCIOS VÁLIDOS con categoría según edad
    INSERT INTO eSocios.Socio (
        id_socio, id_categoria, dni, nombre, apellido, email, 
        fecha_nac, telefono, telefono_emergencia, obra_social, 
        nro_obra_social, tel_obra_social, activo
    )
    SELECT 
        dl.nro_socio,
        cat.id_categoria,
        dl.dni,
        dl.nombre,
        dl.apellido,
        dl.email,
        dl.fecha_nac,
        dl.telefono,
        dl.telefono_emergencia,
        dl.obra_social,
        dl.nro_obra_social,
        dl.tel_obra_social,
        1 -- activo
    FROM #DatosLimpios dl
    CROSS APPLY (
        SELECT DATEDIFF(YEAR, dl.fecha_nac, GETDATE()) 
               - CASE 
                   WHEN MONTH(dl.fecha_nac) > MONTH(GETDATE()) 
                        OR (MONTH(dl.fecha_nac) = MONTH(GETDATE()) AND DAY(dl.fecha_nac) > DAY(GETDATE()))
                   THEN 1 ELSE 0
                 END AS edad
    ) AS edad_calc
    INNER JOIN eSocios.Categoria cat ON 
        (edad_calc.edad < 12 AND cat.nombre = 'Menor')
        OR (edad_calc.edad BETWEEN 12 AND 17 AND cat.nombre = 'Cadete')
        OR (edad_calc.edad >= 18 AND cat.nombre = 'Mayor')
    WHERE dl.nro_socio NOT IN (SELECT nro_socio FROM #Errores WHERE nro_socio IS NOT NULL);

    -- INSERTAR TUTORES QUE NO EXISTEN
    WITH TutoresAInsertar AS 
	(
        SELECT DISTINCT 
            rp.id_socio as id_tutor,
            rp.nombre,
            rp.apellido, 
            rp.dni,
            rp.email,
            rp.fecha_nac,
            rp.telefono
        FROM #DatosLimpios dl
        INNER JOIN eSocios.Socio rp ON rp.id_socio = dl.nro_socio_rp
        LEFT JOIN eSocios.Tutor t ON t.id_tutor = rp.id_socio
        WHERE dl.nro_socio_rp IS NOT NULL 
          AND t.id_tutor IS NULL
          AND rp.email IS NOT NULL
          AND rp.telefono IS NOT NULL
          AND dl.nro_socio NOT IN (SELECT nro_socio FROM #Errores WHERE nro_socio IS NOT NULL)
    )
    INSERT INTO eSocios.Tutor (id_tutor, nombre, apellido, DNI, email, fecha_nac, telefono)
    SELECT id_tutor, nombre, apellido, dni, email, fecha_nac, telefono
    FROM TutoresAInsertar;
    
    -- CREAR RELACIONES GRUPO FAMILIAR
    INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
    SELECT 
        dl.nro_socio,
        dl.nro_socio_rp,
        0.00,
        'Hijo/a'
    FROM #DatosLimpios dl
    WHERE dl.nro_socio_rp IS NOT NULL
      AND dl.nro_socio NOT IN (SELECT nro_socio FROM #Errores WHERE nro_socio IS NOT NULL)
      AND EXISTS (SELECT 1 FROM eSocios.Tutor t WHERE t.id_tutor = dl.nro_socio_rp);
    
    -- RESULTADOS
    DECLARE @TotalProcesados INT, @TotalInsertados INT, @TotalErrores INT;
    
    SELECT @TotalProcesados = COUNT(*) FROM #DatosLimpios;
    SELECT @TotalErrores = COUNT(DISTINCT nro_socio) FROM #Errores;
    SET @TotalInsertados = @TotalProcesados - @TotalErrores;
    
    PRINT 'RESUMEN DE IMPORTACIÓN:';
    PRINT '=====================';
    PRINT 'Total procesados: ' + CAST(@TotalProcesados AS NVARCHAR);
    PRINT 'Total insertados: ' + CAST(@TotalInsertados AS NVARCHAR);
    PRINT 'Total con errores: ' + CAST(@TotalErrores AS NVARCHAR);
    
    -- Mostrar errores si los hay
    IF EXISTS (SELECT 1 FROM #Errores)
    BEGIN
        PRINT '';
        PRINT 'ERRORES ENCONTRADOS:';
        PRINT '==================';
        SELECT * FROM #Errores ORDER BY id;
    END
    ELSE
    BEGIN
        PRINT '';
        PRINT '¡Importación completada sin errores!';
    END
    
    -- Limpiar tablas temporales
    DROP TABLE #ImportacionSocios;
    DROP TABLE #DatosLimpios;
    DROP TABLE #Errores;
END
GO


EXEC eImportacion.ImportarGrupoFamiliar @RutaArchivo = 'S:\importacion\Datos socios.xlsx';
go

CREATE OR ALTER PROCEDURE eImportacion.ImportarPagoCuotas
    @RutaArchivo NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF OBJECT_ID('tempdb..#ImportacionSocios') IS NOT NULL
            DROP TABLE #ImportacionSocios;
        
        CREATE TABLE #ImportacionSocios (
            id_pago BIGINT,
            fecha DATE,
            id_socio VARCHAR(20),
            valor DECIMAL(10,2),
            medio_pago VARCHAR(50)
        );
        
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
        INSERT INTO #ImportacionSocios 
        SELECT * FROM OPENROWSET( 
            ''Microsoft.ACE.OLEDB.12.0'', 
            ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'', 
            ''SELECT * FROM [pago cuotas$A2:E]'' 
        );';
        
        EXEC sp_executesql @SQL;
        
        -- limpiar y validar datos importados
        DELETE FROM #ImportacionSocios WHERE id_pago IS NULL OR valor <= 0;
        
        -- eliminar registros de socios que no existen en la bd
        DELETE i FROM #ImportacionSocios i 
        LEFT JOIN eSocios.Socio s ON i.id_socio = s.id_socio 
        WHERE s.id_socio IS NULL;
        
        -- mostrar cuántos registros se eliminaron por socios inexistentes
        DECLARE @RegistrosEliminados INT = @@ROWCOUNT;
        IF @RegistrosEliminados > 0
        BEGIN
            PRINT 'Se eliminaron ' + CAST(@RegistrosEliminados AS VARCHAR(10)) + ' registros por socios no encontrados en la base de datos';
        END
        
        -- NUEVO: eliminar registros con id_pago duplicados que ya existen en la tabla de pagos
        DELETE i FROM #ImportacionSocios i 
        INNER JOIN eCobros.Pago p ON i.id_pago = p.id_pago;
        
        -- contar cuántos registros se eliminaron por ser duplicados
        DECLARE @RegistrosDuplicados INT = @@ROWCOUNT;
        IF @RegistrosDuplicados > 0
        BEGIN
            PRINT 'Se eliminaron ' + CAST(@RegistrosDuplicados AS VARCHAR(10)) + ' registros por tener id_pago duplicados';
        END
        
        -- si no quedan registros para procesar, salir con mensaje
        DECLARE @RegistrosParaProcesar INT;
        SELECT @RegistrosParaProcesar = COUNT(*) FROM #ImportacionSocios;
        
        IF @RegistrosParaProcesar = 0
        BEGIN
            PRINT 'No hay registros válidos para procesar después de las validaciones';
            DROP TABLE #ImportacionSocios;
            COMMIT TRANSACTION;
            RETURN;
        END
        
        -- crear facturas para cada pago (una x pago)
        INSERT INTO eCobros.Factura 
		(
            id_socio, 
            fecha_emision, 
            fecha_venc_1, 
            fecha_venc_2, 
            estado, 
            total, 
            recargo_venc, 
            descuentos
        )
        SELECT DISTINCT
            i.id_socio,
            i.fecha as fecha_emision,
            DATEADD(DAY, 5, i.fecha) as fecha_venc_1,  -- vencimiento a 5 días
            DATEADD(DAY, 10, i.fecha) as fecha_venc_2,  -- segundo vencimiento a 10 días
            'pagada' as estado,  -- ya tenemos el pago, entonces la factura está pagada
            i.valor as total,
            0 as recargo_venc,  -- sin recargo
            0 as descuentos     -- sin descuentos
        FROM #ImportacionSocios i;
        
        -- crear tabla temporal para facturas con pagos
        CREATE TABLE #MapeoFacturas (
            id_pago BIGINT,
            id_factura INT,
            id_socio VARCHAR(20),
            fecha DATE,
            valor DECIMAL(10,2),
            medio_pago VARCHAR(50)
        );
        
        INSERT INTO #MapeoFacturas
        SELECT 
            i.id_pago,
            f.id_factura,
            i.id_socio,
            i.fecha,
            i.valor,
            i.medio_pago
        FROM #ImportacionSocios i
        INNER JOIN eCobros.Factura f ON 
            i.id_socio = f.id_socio 
            AND i.fecha = f.fecha_emision 
            AND i.valor = f.total
            AND f.estado = 'pagada';
        
        -- Insertar pagos SOLO si no existen duplicados
        INSERT INTO eCobros.Pago 
		(
            id_pago,
            id_factura,
            medio_pago,
            monto,
            fecha,
            estado,
            debito_auto
        )
        SELECT 
            m.id_pago,
            m.id_factura,
            CASE 
                WHEN LOWER(m.medio_pago) = 'efectivo' THEN 'efectivo'
                WHEN LOWER(m.medio_pago) LIKE '%visa%' THEN 'visa'
                WHEN LOWER(m.medio_pago) LIKE '%master%' THEN 'masterCard'
                WHEN LOWER(m.medio_pago) LIKE '%naranja%' THEN 'tarjeta naranja'
                WHEN LOWER(m.medio_pago) LIKE '%pago facil%' THEN 'pago facil'
                WHEN LOWER(m.medio_pago) LIKE '%rapipago%' THEN 'rapipago'
                WHEN LOWER(m.medio_pago) LIKE '%mercado%' THEN 'mercado pago'
                ELSE 'efectivo' -- Default
            END as medio_pago,
            m.valor as monto,
            m.fecha,
            'completado' as estado,
            0 as debito_auto  -- asumimos que no es débito automático
        FROM #MapeoFacturas m
        WHERE NOT EXISTS (
            SELECT 1 FROM eCobros.Pago p 
            WHERE p.id_pago = m.id_pago
        );
        
        -- contar pagos insertados
        DECLARE @PagosInsertados INT = @@ROWCOUNT;
        
        -- mostrar resumen de la importación
        SELECT 
            @RegistrosParaProcesar as TotalRegistrosProcesados,
            COUNT(DISTINCT id_socio) as TotalSociosAfectados,
            SUM(valor) as MontoTotalImportado,
            @RegistrosEliminados as RegistrosEliminadosPorSocioInexistente,
            @RegistrosDuplicados as RegistrosEliminadosPorDuplicados,
            @PagosInsertados as PagosInsertados,
            CASE 
                WHEN @PagosInsertados > 0 THEN 'Importación completada exitosamente'
                WHEN @RegistrosDuplicados > 0 THEN 'No se insertaron pagos - todos eran duplicados'
                ELSE 'No se insertaron pagos - verificar datos'
            END as Estado
        FROM #ImportacionSocios;
        
        -- limpiar tablas temporales
        DROP TABLE #ImportacionSocios;
        DROP TABLE #MapeoFacturas;
        
        COMMIT TRANSACTION;
        
        PRINT 'Importación completada exitosamente';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- limpiar tablas temporales en caso de error
        IF OBJECT_ID('tempdb..#ImportacionSocios') IS NOT NULL
            DROP TABLE #ImportacionSocios;
        IF OBJECT_ID('tempdb..#MapeoFacturas') IS NOT NULL
            DROP TABLE #MapeoFacturas;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END 
GO


EXEC eImportacion.ImportarPagoCuotas @RutaArchivo = 'S:\importacion\Datos socios.xlsx'
GO

CREATE OR ALTER PROCEDURE eImportacion.ImportarPresentismo
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    CREATE TABLE #ImportacionActividades 
	(
        nro_socio VARCHAR(20),
        actividad NVARCHAR(50),
        fecha_asistencia VARCHAR(20), -- Como string para manejar formatos
        asistencia VARCHAR(5),
        profesor VARCHAR(20)
    );
    
    -- Tabla temporal para datos procesados
    CREATE TABLE #DatosProcesados 
	(
        id_socio VARCHAR(20),
        id_actividad INT,
        fecha_asistencia DATE,
        asistencia VARCHAR(5),
        profesor VARCHAR(20)
    );
    
    BEGIN TRY
        -- Importar datos desde Excel
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
        INSERT INTO #ImportacionActividades 
        SELECT * FROM OPENROWSET( 
            ''Microsoft.ACE.OLEDB.12.0'', 
            ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'', 
            ''SELECT * FROM [presentismo_actividades$A12:E]'' 
        );';
        
        EXEC sp_executesql @SQL;
        
        -- procesar y validar los datos
        INSERT INTO #DatosProcesados (id_socio, id_actividad, fecha_asistencia, asistencia, profesor)
        SELECT 
            i.nro_socio,
            a.id_actividad,
            CASE 
                -- convertir la fecha desde diferentes formatos
                WHEN ISDATE(i.fecha_asistencia) = 1 THEN CONVERT(DATE, i.fecha_asistencia)
                WHEN ISDATE(REPLACE(i.fecha_asistencia, '/', '-')) = 1 THEN CONVERT(DATE, REPLACE(i.fecha_asistencia, '/', '-'))
                ELSE NULL
            END,
            i.asistencia,
            i.profesor
        FROM #ImportacionActividades i
        INNER JOIN eSocios.Socio s ON s.id_socio = i.nro_socio AND s.activo = 1
        INNER JOIN eSocios.Actividad a ON UPPER(LTRIM(RTRIM(a.nombre))) = UPPER(LTRIM(RTRIM(i.actividad)))
        WHERE i.nro_socio IS NOT NULL 
          AND i.actividad IS NOT NULL
          AND i.fecha_asistencia IS NOT NULL
          AND ISDATE(i.fecha_asistencia) = 1;
        
        -- NUEVO: Eliminar duplicados de la tabla temporal antes de insertar
        -- Eliminar registros que ya existen en la tabla de presentismo
        DELETE dp FROM #DatosProcesados dp
        INNER JOIN eSocios.Presentismo p ON 
            dp.id_socio = p.id_socio 
            AND dp.id_actividad = p.id_actividad 
            AND dp.fecha_asistencia = p.fecha_asistencia;
        
        -- Contar duplicados eliminados
        DECLARE @DuplicadosEliminados INT = @@ROWCOUNT;
        
        -- insertar datos válidos en la tabla final (solo los no duplicados)
        INSERT INTO eSocios.Presentismo (id_socio, id_actividad, fecha_asistencia, asistencia, profesor)
        SELECT 
            id_socio,
            id_actividad,
            fecha_asistencia,
            asistencia,
            profesor
        FROM #DatosProcesados
        WHERE fecha_asistencia IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM eSocios.Presentismo p 
            WHERE p.id_socio = #DatosProcesados.id_socio 
            AND p.id_actividad = #DatosProcesados.id_actividad 
            AND p.fecha_asistencia = #DatosProcesados.fecha_asistencia
        );
        
        -- Capturar filas insertadas DESPUÉS del INSERT
        DECLARE @FilasInsertadas INT = @@ROWCOUNT;
        
        -- mostrar estadísticas de la importación
        DECLARE @TotalFilas INT = (SELECT COUNT(*) FROM #ImportacionActividades);
        DECLARE @FilasProcesadasOriginales INT = (SELECT COUNT(*) FROM #DatosProcesados WHERE fecha_asistencia IS NOT NULL) + @DuplicadosEliminados;
        DECLARE @FilasRechazadas INT = @TotalFilas - @FilasProcesadasOriginales;
        
        PRINT 'Importación completada:';
        PRINT 'Total de filas en Excel: ' + CAST(@TotalFilas AS VARCHAR(10));
        PRINT 'Filas insertadas: ' + CAST(@FilasInsertadas AS VARCHAR(10));
        PRINT 'Filas omitidas por duplicados: ' + CAST(@DuplicadosEliminados AS VARCHAR(10));
        PRINT 'Filas rechazadas por errores: ' + CAST(@FilasRechazadas AS VARCHAR(10));
        
        -- Mostrar duplicados encontrados si los hay
        IF @DuplicadosEliminados > 0
        BEGIN
            PRINT '';
            PRINT 'Se encontraron ' + CAST(@DuplicadosEliminados AS VARCHAR(10)) + ' registros duplicados que fueron omitidos';
            PRINT 'Los duplicados se basaron en: id_socio + id_actividad + fecha_asistencia';
        END;
        
        -- mostrar filas rechazadas 
        IF @FilasRechazadas > 0
        BEGIN
            PRINT '';
            PRINT 'Filas rechazadas (motivos posibles):';
            
            -- Socios no encontrados
            SELECT 'Socio no encontrado: ' + ISNULL(i.nro_socio, 'NULL') AS Motivo
            FROM #ImportacionActividades i
            LEFT JOIN eSocios.Socio s ON s.id_socio = i.nro_socio AND s.activo = 1
            WHERE s.id_socio IS NULL AND i.nro_socio IS NOT NULL;
            
            -- Actividades no encontradas
            SELECT 'Actividad no encontrada: ' + ISNULL(i.actividad, 'NULL') AS Motivo
            FROM #ImportacionActividades i
            LEFT JOIN eSocios.Actividad a ON UPPER(LTRIM(RTRIM(a.nombre))) = UPPER(LTRIM(RTRIM(i.actividad)))
            WHERE a.id_actividad IS NULL AND i.actividad IS NOT NULL;
            
            -- Fechas inválidas
            SELECT 'Fecha inválida: ' + ISNULL(i.fecha_asistencia, 'NULL') AS Motivo
            FROM #ImportacionActividades i
            WHERE ISDATE(i.fecha_asistencia) = 0 AND i.fecha_asistencia IS NOT NULL;
            
            -- Datos nulos
            SELECT 'Datos incompletos en fila' AS Motivo
            FROM #ImportacionActividades i
            WHERE i.nro_socio IS NULL OR i.actividad IS NULL OR i.fecha_asistencia IS NULL;
        END;
        
        -- NUEVO: Resumen final como mensaje
        PRINT '';
        PRINT '====== RESUMEN FINAL ======';
        PRINT 'Estado: ' + CASE 
            WHEN @FilasInsertadas > 0 AND @DuplicadosEliminados = 0 AND @FilasRechazadas = 0 
                THEN 'Importación exitosa - Sin errores'
            WHEN @FilasInsertadas > 0 AND (@DuplicadosEliminados > 0 OR @FilasRechazadas > 0)
                THEN 'Importación completada con advertencias'
            WHEN @FilasInsertadas = 0 AND @DuplicadosEliminados > 0 
                THEN 'No se insertaron registros - Todos eran duplicados'
            WHEN @FilasInsertadas = 0 AND @FilasRechazadas > 0 
                THEN 'No se insertaron registros - Todos tenían errores'
            ELSE 'Importación sin resultados'
        END;
        PRINT 'Filas válidas procesadas: ' + CAST((@FilasInsertadas + @DuplicadosEliminados) AS VARCHAR(10)) + ' de ' + CAST(@TotalFilas AS VARCHAR(10));
        PRINT '=============================';
        
    END TRY
    BEGIN CATCH
        PRINT 'Error durante la importación:';
        PRINT ERROR_MESSAGE();
        
        THROW;
    END CATCH;
    
    -- Limpiar tablas temporales
    IF OBJECT_ID('tempdb..#ImportacionActividades') IS NOT NULL
        DROP TABLE #ImportacionActividades;
    IF OBJECT_ID('tempdb..#DatosProcesados') IS NOT NULL
        DROP TABLE #DatosProcesados;
    
END; 
GO


EXEC eImportacion.ImportarPresentismo @RutaArchivo = 'S:\importacion\Datos socios.xlsx'
GO


CREATE OR ALTER PROCEDURE eImportacion.ImportarDatosClima
    @RutaArchivo NVARCHAR(500),
    @NombreUbicacion NVARCHAR(100)
AS
BEGIN
    -- Eliminar tablas temporales si existen
    IF OBJECT_ID('tempdb..#UbicacionTemporal') IS NOT NULL DROP TABLE #UbicacionTemporal;
    IF OBJECT_ID('tempdb..#ClimaTemporal') IS NOT NULL DROP TABLE #ClimaTemporal;

    -- Tabla temporal: ubicación
    CREATE TABLE #UbicacionTemporal 
	(
        latitud NVARCHAR(50),
        longitud NVARCHAR(50),
        elevacion NVARCHAR(50),
        utc_offset_seconds NVARCHAR(50),
        timezone NVARCHAR(50),
        timezone_abbreviation NVARCHAR(50)
    );

    -- Tabla temporal: datos climáticos
    CREATE TABLE #ClimaTemporal 
	(
        Fecha NVARCHAR(50),
        Temperatura NVARCHAR(50),
        Lluvia NVARCHAR(50),
        Humedad NVARCHAR(50),
        Viento NVARCHAR(50)
    );

    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX);

        -- Importar ubicación 
        SET @sql = '
        BULK INSERT #UbicacionTemporal
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIRSTROW = 2,
            LASTROW = 2,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''0x0a'',
            CODEPAGE = ''65001''
        );';
        EXEC sp_executesql @sql;

        -- Importar clima 
        SET @sql = '
        BULK INSERT #ClimaTemporal
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIRSTROW = 4,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''0x0a'',
            CODEPAGE = ''65001''
        );';
        EXEC sp_executesql @sql;

        BEGIN TRANSACTION;

        DECLARE @ubicacion_id INT;

        SELECT TOP 1 @ubicacion_id = u.id
        FROM eSocios.ubicaciones u
        JOIN #UbicacionTemporal t ON
            u.latitud = TRY_CAST(t.latitud AS DECIMAL(10,8)) AND
            u.longitud = TRY_CAST(t.longitud AS DECIMAL(11,8)) AND
            ISNULL(u.elevacion, 0) = ISNULL(TRY_CAST(t.elevacion AS DECIMAL(8,2)), 0) AND
            ISNULL(u.utc_offset_seconds, 0) = ISNULL(TRY_CAST(t.utc_offset_seconds AS INT), 0) AND
            ISNULL(u.timezone, '') = ISNULL(t.timezone, '') AND
            ISNULL(u.timezone_abbreviation, '') = ISNULL(t.timezone_abbreviation, '') AND
            ISNULL(u.nombre_ubicacion, '') = @NombreUbicacion;

        -- si no existe la ubicacion insertarla
        IF @ubicacion_id IS NULL
        BEGIN
            INSERT INTO eSocios.ubicaciones 
			(
                latitud,
                longitud,
                elevacion,
                utc_offset_seconds,
                timezone,
                timezone_abbreviation,
                nombre_ubicacion
            )
            SELECT
                TRY_CAST(latitud AS DECIMAL(10,8)),
                TRY_CAST(longitud AS DECIMAL(11,8)),
                TRY_CAST(elevacion AS DECIMAL(8,2)),
                TRY_CAST(utc_offset_seconds AS INT),
                timezone,
                timezone_abbreviation,
                @NombreUbicacion
            FROM #UbicacionTemporal;

            SET @ubicacion_id = SCOPE_IDENTITY();
        END

        -- Insertar datos meteorológicos
        INSERT INTO eSocios.datos_meteorologicos 
		(
            ubicacion_id,
            fecha_hora,
            temperatura_2m,
            lluvia_mm,
            humedad_relativa_pct,
            velocidad_viento_100m_kmh
        )
        SELECT
            @ubicacion_id,
            TRY_CAST(REPLACE(LTRIM(RTRIM(Fecha)), 'T', ' ') AS DATETIME2),
            TRY_CAST(LTRIM(RTRIM(Temperatura)) AS DECIMAL(5,2)),
            TRY_CAST(LTRIM(RTRIM(Lluvia)) AS DECIMAL(6,2)),
            TRY_CAST(LTRIM(RTRIM(Humedad)) AS INT),
            TRY_CAST(LTRIM(RTRIM(Viento)) AS DECIMAL(6,2))
        FROM #ClimaTemporal
        WHERE 
            TRY_CAST(REPLACE(LTRIM(RTRIM(Fecha)), 'T', ' ') AS DATETIME2) IS NOT NULL AND
            TRY_CAST(LTRIM(RTRIM(Temperatura)) AS DECIMAL(5,2)) IS NOT NULL AND
            TRY_CAST(LTRIM(RTRIM(Lluvia)) AS DECIMAL(6,2)) IS NOT NULL AND
            TRY_CAST(LTRIM(RTRIM(Humedad)) AS INT) IS NOT NULL AND
            TRY_CAST(LTRIM(RTRIM(Viento)) AS DECIMAL(6,2)) IS NOT NULL AND
            NOT EXISTS (
                SELECT 1
                FROM eSocios.datos_meteorologicos dm
                WHERE dm.ubicacion_id = @ubicacion_id
                AND dm.fecha_hora = TRY_CAST(REPLACE(LTRIM(RTRIM(#ClimaTemporal.Fecha)), 'T', ' ') AS DATETIME2)
            );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'Error durante la importación: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


EXEC eImportacion.ImportarDatosClima @RutaArchivo = 'S:\importacion\open-meteo-buenosaires_2024.csv', @NombreUbicacion = 'Buenos Aires';
EXEC eImportacion.ImportarDatosClima @RutaArchivo = 'S:\importacion\open-meteo-buenosaires_2025.csv', @NombreUbicacion = 'Buenos Aires';

