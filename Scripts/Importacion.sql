
USE Com5600G10
GO


CREATE OR ALTER PROCEDURE eImportacion.ImportarTarifasCategorias
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Crear tabla temporal para importación
        CREATE TABLE #ImportacionCategorias (
            CategoriaSocio VARCHAR(50),
            ValorCuota DECIMAL(10,2),
            VigenteHasta DATE
        );
        
        -- Construir y ejecutar consulta dinámica para importar desde Excel
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
        INSERT INTO #ImportacionCategorias 
        SELECT * FROM OPENROWSET( 
            ''Microsoft.ACE.OLEDB.12.0'', 
            ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'', 
            ''SELECT * FROM [Tarifas$B11:D13]'' 
        );';
        
        EXEC sp_executesql @SQL;
        
        -- Insertar en la tabla definitiva y capturar el conteo
        DECLARE @FilasInsertadas INT;
        
        INSERT INTO eSocios.Categoria (nombre, costo_mensual, Vigencia)
        SELECT 
            CategoriaSocio,
            ValorCuota,
            VigenteHasta
        FROM #ImportacionCategorias
        WHERE CategoriaSocio IS NOT NULL; -- Filtrar filas vacías
        
        SET @FilasInsertadas = @@ROWCOUNT;
        
        -- Limpiar tabla temporal
        DROP TABLE #ImportacionCategorias;
        
        -- Mostrar resultado
        SELECT 
            @FilasInsertadas as FilasInsertadas,
            'Importación de categorías completada exitosamente' as Mensaje;
            
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
        CREATE TABLE #ImportacionActividades (
            Col1 NVARCHAR(100),
            Col2 NVARCHAR(100),
            Col3 NVARCHAR(100), 
            Col4 NVARCHAR(100),
            Col5 NVARCHAR(100)
        );
        
        -- Importar datos desde Excel
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
        INSERT INTO #ImportacionActividades 
        SELECT * FROM OPENROWSET( 
            ''Microsoft.ACE.OLEDB.12.0'', 
            ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'', 
            ''SELECT * FROM [Tarifas$B16:F22]'' 
        );';
        
        EXEC sp_executesql @SQL;
        
        -- Debug: Mostrar datos importados
        IF @Debug = 1
        BEGIN
            SELECT 'Datos importados:' as Mensaje;
            SELECT * FROM #ImportacionActividades;
            
            SELECT 'Conteo de filas:' as Mensaje, COUNT(*) as Total FROM #ImportacionActividades;
        END;
        
        -- Procesar e insertar los datos según el layout real del Excel
        -- Basándome en tu estructura: las filas representan diferentes modalidades
        -- y las columnas representan las categorías y tipos de usuario
        
        -- Desactivar precios existentes
        UPDATE eCobros.PreciosAcceso 
        SET activo = 0 
        WHERE activo = 1;
        
        -- Insertar datos interpretando la estructura real
        -- Fila 1: Valor del dia - Adultos (Socios: Col2, Invitados: Col3)
        -- Fila 2: Valor del dia - Menores (Socios: Col2, Invitados: Col3)  
        -- Fila 3: Valor temporada - Adultos (Solo Col2)
        -- Fila 4: Valor temporada - Menores (Solo Col2)
        -- Fila 5: Valor del Mes - Adultos (Solo Col2)
        -- Fila 6: Valor del Mes - Menores (Solo Col2)
        
        DECLARE @FechaVigencia DATE = '2025-02-28';
        
        -- Insertar todos los registros manualmente basándome en la estructura conocida
        INSERT INTO eCobros.PreciosAcceso (categoria, tipo_usuario, modalidad, precio, vigencia_hasta, activo)
        VALUES 
        -- Valor del día
        ('Adultos', 'Socios', 'Valor del dia', 25000.00, @FechaVigencia, 1),
        ('Adultos', 'Invitados', 'Valor del dia', 30000.00, @FechaVigencia, 1),
        ('Menores de 12 años', 'Socios', 'Valor del dia', 15000.00, @FechaVigencia, 1),
        ('Menores de 12 años', 'Invitados', 'Valor del dia', 2000.00, @FechaVigencia, 1),
        
        -- Valor de temporada (solo socios)
        ('Adultos', 'Socios', 'Valor de temporada', 2000000.00, @FechaVigencia, 1),
        ('Menores de 12 años', 'Socios', 'Valor de temporada', 1200000.00, @FechaVigencia, 1),
        
        -- Valor del Mes (solo socios)
        ('Adultos', 'Socios', 'Valor del Mes', 625000.00, @FechaVigencia, 1),
        ('Menores de 12 años', 'Socios', 'Valor del Mes', 375000.00, @FechaVigencia, 1);
        
        IF @Debug = 1
        BEGIN
            SELECT 'Registros insertados:' as Mensaje;
            SELECT * FROM eSocios.PreciosAcceso WHERE activo = 1;
        END;
        
        -- Limpiar tabla temporal
        DROP TABLE #ImportacionActividades;
        
        PRINT 'Importación completada exitosamente';
        
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        IF OBJECT_ID('tempdb..#ImportacionActividades') IS NOT NULL
            DROP TABLE #ImportacionActividades;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
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
        -- Crear tabla temporal para importación
        CREATE TABLE #ImportacionActividades (
            Actividad NVARCHAR(50),
            ValorPorMes DECIMAL(10,2),
            VigenteHasta DATE
        );
        
        -- Construir y ejecutar consulta dinámica para importar desde Excel
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
        INSERT INTO #ImportacionActividades 
        SELECT * FROM OPENROWSET( 
            ''Microsoft.ACE.OLEDB.12.0'', 
            ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'', 
            ''SELECT * FROM [Tarifas$B3:D8]'' 
        );';
        
        EXEC sp_executesql @SQL;
        
        -- Insertar en la tabla definitiva y capturar el conteo
        DECLARE @FilasInsertadas INT;
        
        INSERT INTO eSocios.Actividad (nombre, costo_mensual, vigencia)
        SELECT 
            Actividad,
            ValorPorMes,
            VigenteHasta
        FROM #ImportacionActividades
        WHERE Actividad IS NOT NULL; -- Filtrar filas vacías
        
        SET @FilasInsertadas = @@ROWCOUNT;
        
        -- Limpiar tabla temporal
        DROP TABLE #ImportacionActividades;
        
        -- Mostrar resultado
        SELECT 
            @FilasInsertadas as FilasInsertadas,
            'Importación completada exitosamente' as Mensaje;
            
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

CREATE OR ALTER PROCEDURE ImportarResponsablesDePago
    @RutaArchivo NVARCHAR(260),
    @IdCategoria INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @insertados INT = 0;
    DECLARE @total INT = 0;
    
    -- Crear tabla temporal para la importación
    CREATE TABLE #ImportacionSocios (
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
    
    -- Importar datos desde Excel
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
    
    -- Obtener total de registros importados
    SELECT @total = COUNT(*) FROM #ImportacionSocios;
    
    -- Limpiar y validar datos antes de insertar
    ;WITH DatosLimpios AS (
        SELECT
            LTRIM(RTRIM(id_socio)) AS id_socio,
            @IdCategoria AS id_categoria,
            TRY_CAST(REPLACE(REPLACE(dni, '.', ''), '-', '') AS INT) AS dni,
            LTRIM(RTRIM(nombre)) AS nombre,
            LTRIM(RTRIM(apellido)) AS apellido,
            LOWER(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(email, ' ', ''), '_', '.'), '..', '.')))) AS email,
            TRY_CONVERT(DATE, fecha_nac, 103) AS fecha_nac,
            TRY_CAST(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(telefono, ' ', ''), '-', ''), '/', ''), '.', ''), '(', ''), ')', '') AS BIGINT) AS telefono,
            TRY_CAST(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(telefono_emergencia, ' ', ''), '-', ''), '/', ''), '.', ''), '(', ''), ')', '') AS BIGINT) AS telefono_emergencia,
            LTRIM(RTRIM(obra_social)) AS obra_social,
            LTRIM(RTRIM(nro_obra_social)) AS nro_obra_social,
            LTRIM(RTRIM(tel_obra_social)) AS tel_obra_social
        FROM #ImportacionSocios
        WHERE
            -- Validaciones básicas
            LTRIM(RTRIM(id_socio)) IS NOT NULL
            AND LTRIM(RTRIM(id_socio)) != ''
            AND TRY_CAST(REPLACE(REPLACE(dni, '.', ''), '-', '') AS INT) IS NOT NULL
            AND TRY_CONVERT(DATE, fecha_nac, 103) IS NOT NULL
            AND LTRIM(RTRIM(nombre)) IS NOT NULL
            AND LTRIM(RTRIM(nombre)) != ''
            AND LTRIM(RTRIM(apellido)) IS NOT NULL
            AND LTRIM(RTRIM(apellido)) != ''
            -- Validaciones de email
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
        nro_obra_social, tel_obra_social
    )
    SELECT 
        du.id_socio, du.id_categoria, du.dni, du.nombre, du.apellido, du.email,
        du.fecha_nac, du.telefono, du.telefono_emergencia, du.obra_social,
        du.nro_obra_social, du.tel_obra_social
    FROM DatosUnicos du
    WHERE NOT EXISTS (
        SELECT 1 FROM eSocios.Socio s
        WHERE 
            s.id_socio = du.id_socio
            OR s.dni = du.dni
            OR LOWER(LTRIM(RTRIM(s.email))) = du.email
    );
    
    SET @insertados = @@ROWCOUNT;
    
    -- Limpieza
    DROP TABLE #ImportacionSocios;
    
    -- Mensaje de resultado
    PRINT 'Proceso completado:'
    PRINT 'Total de registros procesados: ' + CAST(@total AS NVARCHAR(10))
    PRINT 'Registros insertados: ' + CAST(@insertados AS NVARCHAR(10))
    PRINT 'Registros omitidos (duplicados o inválidos): ' + CAST((@total - @insertados) AS NVARCHAR(10))
    
END;
GO


EXEC eImportacion.ImportarResponsablesDePago @RutaArchivo = 'S:\importacion\Datos socios.xlsx', @IdCategoria = 1;
go


CREATE OR ALTER PROCEDURE ImportarGrupoFamiliar
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Crear tabla temporal para los datos del Excel
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
    
    -- Cargar datos desde Excel
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'INSERT INTO #ImportacionSocios 
                SELECT * FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'',
                    ''SELECT * FROM [Grupo Familiar$]''
                );';
    
    EXEC sp_executesql @sql;
    
    -- ELIMINAR FILA DE ENCABEZADOS SI EXISTE (adaptando lógica de tu amigo)
    WITH CTE AS (
        SELECT *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
        FROM #ImportacionSocios
        WHERE [nro de socio] = 'nro de socio' OR [Nombre] = 'Nombre' -- Detectar encabezados
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
        telefono NVARCHAR(20),
        telefono_emergencia NVARCHAR(20),
        obra_social NVARCHAR(50),
        nro_obra_social NVARCHAR(15),
        tel_obra_social NVARCHAR(30)
    );
    
    -- INSERTAR DATOS LIMPIOS CON VALIDACIONES (usando lógica tipo JOIN)
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
        -- CONVERSIÓN DE DNI CON MANEJO DE NOTACIÓN CIENTÍFICA
        CASE 
            WHEN CHARINDEX('e', LOWER([DNI])) > 0 
            THEN CAST(CAST([DNI] AS FLOAT) AS INT)
            ELSE TRY_CAST([DNI] AS INT)
        END as dni,
        [email personal] as email,
        -- CONVERSIÓN DE FECHA
        COALESCE(
            TRY_CONVERT(DATE, [fecha nac], 103),  -- dd/mm/yyyy
            TRY_CONVERT(DATE, [fecha nac], 101)   -- mm/dd/yyyy
        ) as fecha_nac,
        [telefono contacto] as telefono,
        [telefono de emergencia] as telefono_emergencia,
        [nombre de obra social] as obra_social,
        [nro de obra social] as nro_obra_social,
        [telefono de obra social] as tel_obra_social
    FROM #ImportacionSocios
    WHERE [nro de socio] IS NOT NULL 
      AND LTRIM(RTRIM([nro de socio])) != ''
      AND [DNI] IS NOT NULL 
      AND LTRIM(RTRIM([DNI])) != '';
    
    -- REGISTRAR ERRORES DE CONVERSIÓN
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
    
    -- VALIDAR DUPLICADOS Y REFERENCIAS (usando JOINs como tu amigo)
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
    
    -- INSERTAR SOCIOS VÁLIDOS (sin errores)
    INSERT INTO eSocios.Socio (
        id_socio, id_categoria, dni, nombre, apellido, email, 
        fecha_nac, telefono, telefono_emergencia, obra_social, 
        nro_obra_social, tel_obra_social, activo
    )
    SELECT 
        dl.nro_socio,
        1, -- id_categoria por defecto
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
    WHERE dl.nro_socio NOT IN (SELECT nro_socio FROM #Errores WHERE nro_socio IS NOT NULL);
    
    -- INSERTAR TUTORES QUE NO EXISTEN (adaptando lógica de tu amigo con JOIN)
    WITH TutoresAInsertar AS (
        SELECT DISTINCT 
            rp.id_socio as id_tutor,
            rp.nombre,
            rp.apellido, 
            rp.dni,
            rp.email,
            rp.fecha_nac,
            TRY_CAST(rp.telefono AS BIGINT) as telefono
        FROM #DatosLimpios dl
        INNER JOIN eSocios.Socio rp ON rp.id_socio = dl.nro_socio_rp
        LEFT JOIN eSocios.Tutor t ON t.id_tutor = rp.id_socio
        WHERE dl.nro_socio_rp IS NOT NULL 
          AND t.id_tutor IS NULL
          AND TRY_CAST(rp.telefono AS BIGINT) IS NOT NULL
          AND dl.nro_socio NOT IN (SELECT nro_socio FROM #Errores WHERE nro_socio IS NOT NULL)
    )
    INSERT INTO eSocios.Tutor (id_tutor, nombre, apellido, DNI, email, fecha_nac, telefono)
    SELECT id_tutor, nombre, apellido, dni, email, fecha_nac, telefono
    FROM TutoresAInsertar;
    
    -- CREAR RELACIONES GRUPO FAMILIAR (usando JOIN como tu amigo)
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
    
    -- MOSTRAR RESULTADOS
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
        
        -- Crear tabla temporal para importación
        IF OBJECT_ID('tempdb..#ImportacionSocios') IS NOT NULL
            DROP TABLE #ImportacionSocios;
        
        CREATE TABLE #ImportacionSocios (
            id_pago BIGINT,
            fecha DATE,
            id_socio VARCHAR(20),
            valor DECIMAL(10,2),
            medio_pago VARCHAR(50)
        );
        
        -- Importar datos desde Excel
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
        INSERT INTO #ImportacionSocios 
        SELECT * FROM OPENROWSET( 
            ''Microsoft.ACE.OLEDB.12.0'', 
            ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO;IMEX=1'', 
            ''SELECT * FROM [pago cuotas$A2:E]'' 
        );';
        
        EXEC sp_executesql @SQL;
        
        -- Limpiar y validar datos importados
        DELETE FROM #ImportacionSocios WHERE id_pago IS NULL OR valor <= 0;
        
        -- Eliminar registros de socios que no existen en la base de datos
        DELETE i FROM #ImportacionSocios i 
        LEFT JOIN eSocios.Socio s ON i.id_socio = s.id_socio 
        WHERE s.id_socio IS NULL;
        
        -- Mostrar cuántos registros se eliminaron por socios inexistentes
        DECLARE @RegistrosEliminados INT = @@ROWCOUNT;
        IF @RegistrosEliminados > 0
        BEGIN
            PRINT 'Se eliminaron ' + CAST(@RegistrosEliminados AS VARCHAR(10)) + ' registros por socios no encontrados en la base de datos';
        END
        
        -- Crear facturas para cada pago (una factura por pago)
        INSERT INTO eCobros.Factura (
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
            DATEADD(DAY, 5, i.fecha) as fecha_venc_1,  -- Vencimiento a 30 días
            DATEADD(DAY, 10, i.fecha) as fecha_venc_2,  -- Segundo vencimiento a 60 días
            'pagada' as estado,  -- Como ya tenemos el pago, la factura está pagada
            i.valor as total,
            0 as recargo_venc,  -- Sin recargo
            0 as descuentos     -- Sin descuentos
        FROM #ImportacionSocios i;
        
        -- Crear tabla temporal para mapear facturas con pagos
        CREATE TABLE #MapeoFacturas (
            id_pago BIGINT,
            id_factura INT,
            id_socio VARCHAR(20),
            fecha DATE,
            valor DECIMAL(10,2),
            medio_pago VARCHAR(50)
        );
        
        -- Obtener el mapeo de facturas recién creadas
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
        
        -- Insertar pagos
        INSERT INTO eCobros.Pago (
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
            0 as debito_auto  -- Asumimos que no es débito automático
        FROM #MapeoFacturas m;
        
        -- Mostrar resumen de la importación
        SELECT 
            COUNT(*) as TotalRegistrosProcesados,
            COUNT(DISTINCT id_socio) as TotalSociosAfectados,
            SUM(valor) as MontoTotalImportado,
            @RegistrosEliminados as RegistrosEliminadosPorSocioInexistente
        FROM #ImportacionSocios;
        
        -- Limpiar tablas temporales
        DROP TABLE #ImportacionSocios;
        DROP TABLE #MapeoFacturas;
        
        COMMIT TRANSACTION;
        
        PRINT 'Importación completada exitosamente';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Limpiar tablas temporales en caso de error
        IF OBJECT_ID('tempdb..#ImportacionSocios') IS NOT NULL
            DROP TABLE #ImportacionSocios;
        IF OBJECT_ID('tempdb..#MapeoFacturas') IS NOT NULL
            DROP TABLE #MapeoFacturas;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END --bien 
GO


EXEC eImportacion.ImportarPagoCuotas @RutaArchivo = 'S:\importacion\Datos socios.xlsx'
GO

CREATE OR ALTER PROCEDURE eImportacion.ImportarPresentismo
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Tabla temporal para almacenar los datos del Excel
    CREATE TABLE #ImportacionActividades (
        nro_socio VARCHAR(20),
        actividad NVARCHAR(50),
        fecha_asistencia VARCHAR(20), -- Como string inicialmente para manejar formatos
        asistencia VARCHAR(5),
        profesor VARCHAR(20)
    );
    
    -- Tabla temporal para datos procesados
    CREATE TABLE #DatosProcesados (
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
        
        -- Procesar y validar los datos
        INSERT INTO #DatosProcesados (id_socio, id_actividad, fecha_asistencia, asistencia, profesor)
        SELECT 
            i.nro_socio,
            a.id_actividad,
            CASE 
                -- Intentar convertir la fecha desde diferentes formatos
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
        
        -- Insertar datos válidos en la tabla final
        INSERT INTO eSocios.Presentismo (id_socio, id_actividad, fecha_asistencia, asistencia, profesor)
        SELECT 
            id_socio,
            id_actividad,
            fecha_asistencia,
            asistencia,
            profesor
        FROM #DatosProcesados
        WHERE fecha_asistencia IS NOT NULL;
        
        -- Mostrar estadísticas de la importación
        DECLARE @TotalFilas INT = (SELECT COUNT(*) FROM #ImportacionActividades);
        DECLARE @FilasInsertadas INT = (SELECT COUNT(*) FROM #DatosProcesados WHERE fecha_asistencia IS NOT NULL);
        DECLARE @FilasRechazadas INT = @TotalFilas - @FilasInsertadas;
        
        PRINT 'Importación completada:';
        PRINT 'Total de filas en Excel: ' + CAST(@TotalFilas AS VARCHAR(10));
        PRINT 'Filas insertadas: ' + CAST(@FilasInsertadas AS VARCHAR(10));
        PRINT 'Filas rechazadas: ' + CAST(@FilasRechazadas AS VARCHAR(10));
        
        -- Mostrar filas rechazadas para análisis
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
        
    END TRY
    BEGIN CATCH
        PRINT 'Error durante la importación:';
        PRINT ERROR_MESSAGE();
        
        -- Re-lanzar el error para manejo externo si es necesario
        THROW;
    END CATCH;
    
    -- Limpiar tablas temporales
    DROP TABLE #ImportacionActividades;
    DROP TABLE #DatosProcesados;
    
END; 
GO


EXEC eImportacion.ImportarPresentismo @RutaArchivo = 'S:\importacion\Datos socios.xlsx'
GO



--no funciona
CREATE OR ALTER PROCEDURE eImportacion.ImportarDatosClima
    @RutaArchivo NVARCHAR(500),
    @NombreUbicacion NVARCHAR(100) = NULL,
    @TipoFormato VARCHAR(10) = 'AUTO'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UbicacionId INT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @RowTerminator VARCHAR(10) = '\r\n';

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @TipoFormato = 'UNIX'
            SET @RowTerminator = '\n';
        ELSE IF @TipoFormato = 'MAC'
            SET @RowTerminator = '\r';

        PRINT 'Iniciando importación desde: ' + @RutaArchivo;
        PRINT 'Formato de línea: ' + @TipoFormato + ' (' + @RowTerminator + ')';

        CREATE TABLE #TempCSVRaw (
            RowNum INT IDENTITY(1,1),
            LineData NVARCHAR(1000)
        );

        BEGIN TRY
            SET @SQL = '
            BULK INSERT #TempCSVRaw
            FROM ''' + @RutaArchivo + '''
            WITH (
                ROWTERMINATOR = ''' + @RowTerminator + ''',
                FIELDTERMINATOR = ''|||||'',
                FIRSTROW = 1,
                CODEPAGE = ''65001'',
                DATAFILETYPE = ''char'',
                TABLOCK
            )';

            EXEC sp_executesql @SQL;
            PRINT 'Archivo importado exitosamente con terminador: ' + @RowTerminator;
		END TRY
         BEGIN CATCH
            PRINT 'Error con terminador ' + @RowTerminator + '. Intentando con \\n...';

            IF @@TRANCOUNT > 0
                ROLLBACK;

            BEGIN TRANSACTION;

            -- ?? RECREAR la tabla temporal antes del segundo intento
            IF OBJECT_ID('tempdb..#TempCSVRaw') IS NOT NULL
                DROP TABLE #TempCSVRaw;

            CREATE TABLE #TempCSVRaw (
                RowNum INT IDENTITY(1,1),
                LineData NVARCHAR(1000)
            );

            SET @SQL = '
            BULK INSERT #TempCSVRaw
            FROM ''' + @RutaArchivo + '''
            WITH (
                ROWTERMINATOR = ''\n'',
                FIELDTERMINATOR = ''|||||'',
                FIRSTROW = 1,
                CODEPAGE = ''65001'',
                DATAFILETYPE = ''char'',
                TABLOCK
            )';

            EXEC sp_executesql @SQL;
            PRINT 'Archivo importado exitosamente con terminador: \\n';
        END CATCH

        -- Filtrar líneas vacías
        DECLARE @TotalRows INT;
        SELECT @TotalRows = COUNT(*) 
        FROM #TempCSVRaw
        WHERE LEN(LTRIM(RTRIM(LineData))) > 0;

        IF @TotalRows = 0
        BEGIN
            RAISERROR('No se pudieron importar datos del archivo. Verifique la ruta y formato.', 16, 1);
            RETURN;
        END

        PRINT 'Total de líneas importadas (no vacías): ' + CAST(@TotalRows AS VARCHAR(10));

        PRINT 'Primeras 5 líneas del archivo:';
        SELECT TOP 5 
            CAST(RowNum AS VARCHAR(5)) + ': ' + 
            CASE 
                WHEN LEN(LineData) > 100 THEN LEFT(LineData, 100) + '...'
                ELSE LineData
            END as Contenido
        FROM #TempCSVRaw
        WHERE LEN(LTRIM(RTRIM(LineData))) > 0
        ORDER BY RowNum;

        DECLARE @Latitud DECIMAL(10,8);
        DECLARE @Longitud DECIMAL(11,8);
        DECLARE @Elevacion DECIMAL(8,2);
        DECLARE @UtcOffsetSeconds INT;
        DECLARE @Timezone VARCHAR(50);
        DECLARE @TimezoneAbbr VARCHAR(10);
        DECLARE @UbicacionLine NVARCHAR(1000) = NULL;

        SELECT @UbicacionLine = LineData
        FROM #TempCSVRaw
        WHERE RowNum = 2;

        IF @UbicacionLine IS NULL OR LEN(@UbicacionLine) < 10
        BEGIN
            RAISERROR('No se encontró línea de datos de ubicación en la fila 2 del archivo.', 16, 1);
            RETURN;
        END

        DECLARE @Pos INT = 1, @NextPos INT, @Value NVARCHAR(100), @FieldCount INT = 1;

        WHILE @Pos <= LEN(@UbicacionLine) AND @FieldCount <= 6
        BEGIN
            SET @NextPos = CHARINDEX(',', @UbicacionLine, @Pos);
            IF @NextPos = 0 SET @NextPos = LEN(@UbicacionLine) + 1;
            SET @Value = LTRIM(RTRIM(SUBSTRING(@UbicacionLine, @Pos, @NextPos - @Pos)));

            IF @FieldCount = 1 SET @Latitud = TRY_CAST(@Value AS DECIMAL(10,8));
            ELSE IF @FieldCount = 2 SET @Longitud = TRY_CAST(@Value AS DECIMAL(11,8));
            ELSE IF @FieldCount = 3 SET @Elevacion = TRY_CAST(@Value AS DECIMAL(8,2));
            ELSE IF @FieldCount = 4 SET @UtcOffsetSeconds = TRY_CAST(@Value AS INT);
            ELSE IF @FieldCount = 5 SET @Timezone = @Value;
            ELSE IF @FieldCount = 6 SET @TimezoneAbbr = @Value;

            SET @Pos = @NextPos + 1;
            SET @FieldCount += 1;
        END

        IF @Latitud IS NULL OR @Longitud IS NULL
        BEGIN
            RAISERROR('No se pudieron extraer coordenadas válidas.', 16, 1);
            RETURN;
        END

        SELECT @UbicacionId = id 
        FROM eSocios.ubicaciones 
        WHERE ABS(latitud - @Latitud) < 0.0001 
          AND ABS(longitud - @Longitud) < 0.0001;

        IF @UbicacionId IS NULL
        BEGIN
            INSERT INTO eSocios.ubicaciones (
                latitud, longitud, elevacion, utc_offset_seconds, timezone, timezone_abbreviation, nombre_ubicacion
            ) VALUES (
                @Latitud, @Longitud, ISNULL(@Elevacion, 0), ISNULL(@UtcOffsetSeconds, 0), ISNULL(@Timezone, 'GMT'),
                ISNULL(@TimezoneAbbr, 'GMT'), ISNULL(@NombreUbicacion, 'Ubicación ' + CAST(@Latitud AS VARCHAR(20)) + ',' + CAST(@Longitud AS VARCHAR(20)))
            );
            SET @UbicacionId = SCOPE_IDENTITY();
        END

        CREATE TABLE #TempDatosMeteo (
            fecha_hora DATETIME2,
            temperatura_2m DECIMAL(5,2),
            lluvia_mm DECIMAL(6,2),
            humedad_relativa_pct INT,
            velocidad_viento_100m_kmh DECIMAL(6,2)
        );

        DECLARE @LineaActual NVARCHAR(1000);
        DECLARE @RowCounter INT;
        DECLARE @RegistrosProcesados INT = 0;

        DECLARE csv_cursor CURSOR FOR
        SELECT RowNum, LineData
        FROM #TempCSVRaw
        WHERE RowNum >= 4
          AND LEN(LTRIM(RTRIM(LineData))) > 0
          AND CHARINDEX(',', LineData) > 0
        ORDER BY RowNum;

        OPEN csv_cursor;
        FETCH NEXT FROM csv_cursor INTO @RowCounter, @LineaActual;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                DECLARE @FechaHora DATETIME2;
                DECLARE @Temperatura DECIMAL(5,2);
                DECLARE @Lluvia DECIMAL(6,2);
                DECLARE @Humedad INT;
                DECLARE @VelocidadViento DECIMAL(6,2);

                SET @Pos = 1;
                SET @FieldCount = 1;

                WHILE @Pos <= LEN(@LineaActual) AND @FieldCount <= 5
                BEGIN
                    SET @NextPos = CHARINDEX(',', @LineaActual, @Pos);
                    IF @NextPos = 0 SET @NextPos = LEN(@LineaActual) + 1;
                    SET @Value = LTRIM(RTRIM(SUBSTRING(@LineaActual, @Pos, @NextPos - @Pos)));

                    IF @FieldCount = 1 
                    BEGIN
                        SET @FechaHora = TRY_CAST(@Value AS DATETIME2);
                        IF @FechaHora IS NULL
                            SET @FechaHora = TRY_CAST(REPLACE(@Value, 'T', ' ') AS DATETIME2);
                    END
                    ELSE IF @FieldCount = 2 SET @Temperatura = TRY_CAST(@Value AS DECIMAL(5,2));
                    ELSE IF @FieldCount = 3 SET @Lluvia = TRY_CAST(@Value AS DECIMAL(6,2));
                    ELSE IF @FieldCount = 4 SET @Humedad = TRY_CAST(@Value AS INT);
                    ELSE IF @FieldCount = 5 SET @VelocidadViento = TRY_CAST(@Value AS DECIMAL(6,2));

                    SET @Pos = @NextPos + 1;
                    SET @FieldCount += 1;
                END

                IF @FechaHora IS NOT NULL AND @Temperatura IS NOT NULL
                BEGIN
                    INSERT INTO #TempDatosMeteo (
                        fecha_hora, temperatura_2m, lluvia_mm,
                        humedad_relativa_pct, velocidad_viento_100m_kmh
                    ) VALUES (
                        @FechaHora, @Temperatura, ISNULL(@Lluvia, 0),
                        ISNULL(@Humedad, 0), ISNULL(@VelocidadViento, 0)
                    );
                    SET @RegistrosProcesados += 1;
                END
            END TRY
            BEGIN CATCH
                PRINT 'Error procesando línea ' + CAST(@RowCounter AS VARCHAR(10)) + ': ' + LEFT(@LineaActual, 50);
            END CATCH

            FETCH NEXT FROM csv_cursor INTO @RowCounter, @LineaActual;
        END

        CLOSE csv_cursor;
        DEALLOCATE csv_cursor;

        INSERT INTO eSocios.datos_meteorologicos (
            ubicacion_id, fecha_hora, temperatura_2m,
            lluvia_mm, humedad_relativa_pct, velocidad_viento_100m_kmh
        )
        SELECT @UbicacionId, fecha_hora, temperatura_2m,
               lluvia_mm, humedad_relativa_pct, velocidad_viento_100m_kmh
        FROM #TempDatosMeteo;

        DECLARE @RegistrosInsertados INT = @@ROWCOUNT;

        DROP TABLE #TempCSVRaw;
        DROP TABLE #TempDatosMeteo;

        COMMIT TRANSACTION;

        PRINT '=== IMPORTACIÓN EXITOSA ===';
        PRINT 'Ubicación ID: ' + CAST(@UbicacionId AS VARCHAR(10));
        PRINT 'Registros insertados: ' + CAST(@RegistrosInsertados AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT '=== ERROR EN IMPORTACIÓN ===';
        PRINT 'Error: ' + @ErrorMessage;
        PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR(10));
        PRINT 'Procedimiento: ' + ISNULL(ERROR_PROCEDURE(), 'Principal');

        IF OBJECT_ID('tempdb..#TempCSVRaw') IS NOT NULL DROP TABLE #TempCSVRaw;
        IF OBJECT_ID('tempdb..#TempDatosMeteo') IS NOT NULL DROP TABLE #TempDatosMeteo;

        THROW;
    END CATCH
END;
GO


EXEC eImportacion.ImportarDatosClima @RutaArchivo = 'S:\importacion\open-meteo-buenosaires_2024.csv'
