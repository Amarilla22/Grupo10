use Com5600G10

go


CREATE PROCEDURE insertarSocio
    @id_grupo_familiar INT,
    @dni VARCHAR(15),
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @email NVARCHAR(100),
    @fecha_nac DATE,
    @telefono VARCHAR(20),
    @telefono_emergencia VARCHAR(20),
    @obra_social VARCHAR(50),
    @nro_obra_social VARCHAR(15)
AS
BEGIN
    DECLARE @edad INT
    DECLARE @nombre_categoria VARCHAR(20)
    DECLARE @id_categoria INT

    -- calcular edad
    SET @edad = DATEDIFF(YEAR, @fecha_nac, GETDATE())
    IF DATEADD(YEAR, @edad, @fecha_nac) > GETDATE()
        SET @edad = @edad - 1

    -- determinar categoría por edad
    IF @edad <= 12
        SET @nombre_categoria = 'Menor'
    ELSE IF @edad BETWEEN 13 AND 17
        SET @nombre_categoria = 'Cadete'
    ELSE
        SET @nombre_categoria = 'Mayor'

    -- obtener el id_categoria desde la tabla Categoria
    SELECT @id_categoria = id_categoria
    FROM eSocios.Categoria
    WHERE nombre = @nombre_categoria

    IF @id_categoria IS NULL
    BEGIN
        RAISERROR('No se encontró la categoría correspondiente: %s', 16, 1, @nombre_categoria)
        RETURN
    END

    -- insertar socio
    INSERT INTO eSocios.Socio 
    (
        id_grupo_familiar, id_categoria, dni, nombre, apellido, email,
        fecha_nac, telefono, telefono_emergencia, obra_social, nro_obra_social
    )
    VALUES 
    (
        @id_grupo_familiar, @id_categoria, @dni, @nombre, @apellido, @email,
        @fecha_nac, @telefono, @telefono_emergencia, @obra_social, @nro_obra_social
    )
END
GO

--Verifica que exista un socio con el ID dado y luego de eso le asigna la actividad indicada por ID en la tabla Realiza

CREATE PROCEDURE eSocios.asignarActividad
    @id_socio INT,
    @id_actividad INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Verificar que el socio existe
        IF NOT EXISTS (SELECT 1 FROM eSocios.Socio WHERE id_socio = @id_socio)
            THROW 50001, 'El socio no existe', 1;
            
        -- Verificar que la actividad existe
        IF NOT EXISTS (SELECT 1 FROM eSocios.Actividad WHERE id_actividad = @id_actividad)
            THROW 50002, 'La actividad no existe', 1;
            
        -- Asignar actividad
        INSERT INTO eSocios.Realiza (socio, id_actividad)
        VALUES (@id_socio, @id_actividad);
        
        SELECT 'Actividad asignada correctamente' AS Resultado;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO




CREATE PROCEDURE eSocios.CrearActividad
    @nombre NVARCHAR(50),
    @costo_mensual DECIMAL(10,2),
    @dias VARCHAR(100) = NULL, -- Cadena de días separados por comas (ej: 'lunes,miercoles,viernes')
    @horarios VARCHAR(500) = NULL -- Cadena de horarios en formato HH:MM separados por comas
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @id_actividad INT;
        
        -- Insertar la actividad (el ID se genera automáticamente por IDENTITY)
        INSERT INTO eSocios.Actividad (nombre, costo_mensual)
        VALUES (@nombre, @costo_mensual);
        
        -- Obtener el ID generado automáticamente
        SET @id_actividad = SCOPE_IDENTITY();
        
        -- Asignar días si se proporcionaron
        IF @dias IS NOT NULL
        BEGIN
            DECLARE @dia VARCHAR(20);
            DECLARE @pos INT = 1;
            
            WHILE @pos <= LEN(@dias)
            BEGIN
                SET @dia = LTRIM(RTRIM(SUBSTRING(@dias, @pos, 
                    CHARINDEX(',', @dias + ',', @pos) - @pos)));
                
                IF @dia <> ''
                BEGIN
                    -- Buscar ID del día
                    DECLARE @id_dia SMALLINT;
                    SELECT @id_dia = id_dia FROM eSocios.Dia WHERE nombre = @dia;
                    
                    IF @id_dia IS NOT NULL
                        INSERT INTO eSocios.ActividadDia (id_actividad, id_dia)
                        VALUES (@id_actividad, @id_dia);
                END
                
                SET @pos = CHARINDEX(',', @dias + ',', @pos) + 1;
            END
        END
        
        -- Asignar horarios si se proporcionaron
        IF @horarios IS NOT NULL
        BEGIN
            DECLARE @horario VARCHAR(10);
            DECLARE @hpos INT = 1;
            
            WHILE @hpos <= LEN(@horarios)
            BEGIN
                SET @horario = LTRIM(RTRIM(SUBSTRING(@horarios, @hpos, 
                    CHARINDEX(',', @horarios + ',', @hpos) - @hpos)));
                
                IF @horario <> ''
                BEGIN
                    -- Buscar o crear horario
                    DECLARE @id_horario INT;
                    DECLARE @hora TIME = TRY_CAST(@horario AS TIME);
                    
                    IF @hora IS NOT NULL
                    BEGIN
                        SELECT @id_horario = id_horario 
                        FROM eSocios.Horario 
                        WHERE hora = @hora;
                        
                        IF @id_horario IS NULL
                        BEGIN
                            SELECT @id_horario = ISNULL(MAX(id_horario), 0) + 1 
                            FROM eSocios.Horario;
                            
                            INSERT INTO eSocios.Horario (id_horario, hora)
                            VALUES (@id_horario, @hora);
                        END
                        
                        INSERT INTO eSocios.ActividadHorario (id_actividad, id_horario)
                        VALUES (@id_actividad, @id_horario);
                    END
                END
                
                SET @hpos = CHARINDEX(',', @horarios + ',', @hpos) + 1;
            END
        END
        
        COMMIT TRANSACTION;
        SELECT @id_actividad AS id_actividad;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        THROW;
    END CATCH
END;
GO