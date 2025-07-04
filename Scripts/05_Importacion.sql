
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

CREATE OR ALTER PROCEDURE eImportacion.ImportarResponsablesDePago
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
            -- Ajustar a VARCHAR(20) según la nueva definición
            CASE 
                WHEN LEN(LTRIM(RTRIM(id_socio))) <= 20 THEN LTRIM(RTRIM(id_socio))
                ELSE LEFT(LTRIM(RTRIM(id_socio)), 20)
            END AS id_socio,
            @IdCategoria AS id_categoria,
            TRY_CAST(REPLACE(REPLACE(dni, '.', ''), '-', '') AS INT) AS dni,
            -- Ajustar a VARCHAR(50) según la nueva definición
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
            -- Ajustar a VARCHAR(50) según la nueva definición
            CASE 
                WHEN LEN(LTRIM(RTRIM(obra_social))) <= 50 THEN LTRIM(RTRIM(obra_social))
                ELSE LEFT(LTRIM(RTRIM(obra_social)), 50)
            END AS obra_social,
            -- Ajustar a VARCHAR(15) según la nueva definición
            CASE 
                WHEN LEN(LTRIM(RTRIM(nro_obra_social))) <= 15 THEN LTRIM(RTRIM(nro_obra_social))
                ELSE LEFT(LTRIM(RTRIM(nro_obra_social)), 15)
            END AS nro_obra_social,
            -- Convertir tel_obra_social a BIGINT (nuevo tipo de dato)
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
            -- Validaciones de email (las mismas que están en el CHECK constraint)
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


CREATE OR ALTER PROCEDURE eImportacion.ImportarGrupoFamiliar
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
        -- CONVERSIÓN DE DNI CON MANEJO DE NOTACIÓN CIENTÍFICA
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
    
    -- Validar que los responsables tengan email (requerido para tutores)
    INSERT INTO #Errores (nro_socio, dni, error_descripcion)
    SELECT dl.nro_socio, CAST(dl.dni AS NVARCHAR), 'El socio responsable no tiene email válido (requerido para tutor)'
    FROM #DatosLimpios dl
    INNER JOIN eSocios.Socio s ON s.id_socio = dl.nro_socio_rp
    WHERE dl.nro_socio_rp IS NOT NULL 
      AND (s.email IS NULL OR s.email = '' OR s.email NOT LIKE '%@%.%');
    
    -- Validar que los responsables tengan teléfono (requerido para tutores)
    INSERT INTO #Errores (nro_socio, dni, error_descripcion)
    SELECT dl.nro_socio, CAST(dl.dni AS NVARCHAR), 'El socio responsable no tiene teléfono válido (requerido para tutor)'
    FROM #DatosLimpios dl
    INNER JOIN eSocios.Socio s ON s.id_socio = dl.nro_socio_rp
    WHERE dl.nro_socio_rp IS NOT NULL 
      AND s.telefono IS NULL;
    
    -- INSERTAR SOCIOS VÁLIDOS con categoría dinámica según edad
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
    WITH TutoresAInsertar AS (
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


CREATE OR ALTER PROCEDURE eImportacion.ImportarDatosClima
    @RutaArchivo NVARCHAR(500),
    @NombreUbicacion NVARCHAR(100)
AS
BEGIN
    -- Eliminar tablas temporales si existen
    IF OBJECT_ID('tempdb..#UbicacionTemporal') IS NOT NULL DROP TABLE #UbicacionTemporal;
    IF OBJECT_ID('tempdb..#ClimaTemporal') IS NOT NULL DROP TABLE #ClimaTemporal;

    -- Tabla temporal para ubicación (fila 2)
    CREATE TABLE #UbicacionTemporal (
        latitud NVARCHAR(50),
        longitud NVARCHAR(50),
        elevacion NVARCHAR(50),
        utc_offset_seconds NVARCHAR(50),
        timezone NVARCHAR(50),
        timezone_abbreviation NVARCHAR(50)
    );

    -- Tabla temporal para datos climáticos (desde fila 4)
    CREATE TABLE #ClimaTemporal (
        Fecha NVARCHAR(50),
        Temperatura NVARCHAR(50),
        Lluvia NVARCHAR(50),
        Humedad NVARCHAR(50),
        Viento NVARCHAR(50)
    );

    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX);

        -- Importar ubicación (fila 2)
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

        -- Importar clima (desde fila 4)
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

        -- Iniciar transacción
        BEGIN TRANSACTION;

        -- Buscar ubicación existente con los mismos datos y mismo nombre
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

        -- Si no existe, insertarla
        IF @ubicacion_id IS NULL
        BEGIN
            INSERT INTO eSocios.ubicaciones (
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
        INSERT INTO eSocios.datos_meteorologicos (
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


EXEC eImportacion.ImportarDatosClima @RutaArchivo = 'S:\importacion\open-meteo-buenosaires_2025.csv', @NombreUbicacion = 'Buenos Aires';

