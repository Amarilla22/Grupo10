
/*
Entrega 4 - Creacion de store procedures.
Fecha de entrega: 20/06/2025
Nro. Comision: 5600
Grupo: 10
Materia: Bases de datos aplicada
Integrantes:
- Moggi Rocio , DNI: 45576066
- Amarilla Santiago, DNI: 45481129 
- Martinez Galo, DNI: 43094675
- Fleita Thiago , DNI: 45233264
*/

USE Com5600G10
GO


CREATE OR ALTER PROCEDURE eSocios.insertarSocio
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

    -- calcula edad
    SET @edad = DATEDIFF(YEAR, @fecha_nac, GETDATE())
    IF DATEADD(YEAR, @edad, @fecha_nac) > GETDATE()
        SET @edad = @edad - 1

    -- determina la categoría por edad
    IF @edad <= 12
        SET @nombre_categoria = 'Menor'
    ELSE IF @edad BETWEEN 13 AND 17
        SET @nombre_categoria = 'Cadete'
    ELSE
        SET @nombre_categoria = 'Mayor'

    -- obtiene el id_categoria desde la tabla Categoria
    SELECT @id_categoria = id_categoria
    FROM eSocios.Categoria
    WHERE nombre = @nombre_categoria

    IF @id_categoria IS NULL
    BEGIN
        RAISERROR('No se encontró la categoría correspondiente: %s', 16, 1, @nombre_categoria)
        RETURN
    END

    -- inserta el socio
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


CREATE OR ALTER PROCEDURE eSocios.EliminarSocio
	@id_socio INT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF NOT EXISTS (SELECT 1 FROM eSocios.Socio WHERE id_socio = @id_socio AND activo = 1)
			THROW 50001, 'El socio no existe o ya fue dado de baja.', 1;

		--borrado logico
		UPDATE eSocios.Socio
		SET activo = 0
		WHERE id_socio = @id_socio;

		PRINT 'Socio eliminado con éxito.';
	END TRY
	BEGIN CATCH
		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END; --------T
GO


CREATE OR ALTER PROCEDURE eSocios.ModificarSocio
	@id_socio INT,
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
	SET NOCOUNT ON;

	BEGIN TRY
		--Validar que el socio exista y esté activo
		IF NOT EXISTS (SELECT 1 FROM eSocios.Socio WHERE id_socio = @id_socio AND activo = 1)
			THROW 50001, 'El socio no existe o esta inactivo.', 1;

		--Validar formato email
		IF @email NOT LIKE '%@%.%'
			THROW 50002, 'Formato de email invalido.', 1;

		--Actualizacion
		UPDATE eSocios.Socio
		SET
			nombre = @nombre,
			apellido = @apellido,
			email = @email,
			telefono = @telefono,
			telefono_emergencia = @telefono_emergencia,
			obra_social = @obra_social,
			nro_obra_social = @nro_obra_social
		WHERE id_socio = @id_socio;

		PRINT 'Socio modificado con éxito.';
	END TRY
	BEGIN CATCH
		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END; --------T
GO


--Verifica que exista un socio con el ID dado y luego de eso le asigna la actividad indicada por ID en la tabla Realiza

CREATE OR ALTER PROCEDURE eSocios.AsignarActividad
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


CREATE OR ALTER PROCEDURE eSocios.CrearActividad
    @nombre NVARCHAR(50),
    @costo_mensual DECIMAL(10,2),
    @dias NVARCHAR(200) = NULL, -- Días separados por coma: 'lunes,miércoles,viernes'
    @horarios NVARCHAR(200) = NULL -- Horarios separados por coma: '09:00-10:00,18:00-19:00'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @id_actividad INT;
    DECLARE @error_message NVARCHAR(500);
    DECLARE @dia VARCHAR(20);
    DECLARE @horario VARCHAR(20);
    DECLARE @hora_inicio TIME;
    DECLARE @hora_fin TIME;
    DECLARE @pos INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validaciones básicas
        IF @nombre IS NULL OR TRIM(@nombre) = ''
        BEGIN
            RAISERROR('El nombre de la actividad es obligatorio', 16, 1);
            RETURN;
        END
        
        IF @costo_mensual IS NULL OR @costo_mensual < 0
        BEGIN
            RAISERROR('El costo mensual debe ser mayor o igual a 0', 16, 1);
            RETURN;
        END
        
        -- Verificar si ya existe una actividad con el mismo nombre
        IF EXISTS (SELECT 1 FROM eSocios.Actividad WHERE nombre = @nombre)
        BEGIN
            RAISERROR('Ya existe una actividad con ese nombre', 16, 1);
            RETURN;
        END
        
        -- Validar que si se pasan días también se pasen horarios y viceversa
        IF (@dias IS NOT NULL AND @horarios IS NULL) OR (@dias IS NULL AND @horarios IS NOT NULL)
        BEGIN
            RAISERROR('Si especifica días debe especificar horarios y viceversa', 16, 1);
            RETURN;
        END
        
        -- Crear la actividad
        INSERT INTO eSocios.Actividad (nombre, costo_mensual)
        VALUES (@nombre, @costo_mensual);
        
        SET @id_actividad = SCOPE_IDENTITY();
        
        -- Si se proporcionaron días y horarios, procesarlos
        IF @dias IS NOT NULL AND @horarios IS NOT NULL
        BEGIN
            -- Crear tabla temporal para combinar días y horarios
            CREATE TABLE #TempDias (dia VARCHAR(20));
            CREATE TABLE #TempHorarios (hora_inicio TIME, hora_fin TIME);
            CREATE TABLE #TempCombinacion (dia VARCHAR(20), hora_inicio TIME, hora_fin TIME);
            
            -- Procesar días (separados por coma)
            DECLARE @dias_temp NVARCHAR(200) = @dias + ',';
            WHILE CHARINDEX(',', @dias_temp) > 0
            BEGIN
                SET @pos = CHARINDEX(',', @dias_temp);
                SET @dia = LTRIM(RTRIM(SUBSTRING(@dias_temp, 1, @pos - 1)));
                
                -- Validar día
                IF @dia NOT IN ('lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo')
                BEGIN
                    RAISERROR('Día inválido: %s. Debe ser: lunes, martes, miércoles, jueves, viernes, sábado, domingo', 16, 1, @dia);
                    RETURN;
                END
                
                INSERT INTO #TempDias (dia) VALUES (@dia);
                SET @dias_temp = SUBSTRING(@dias_temp, @pos + 1, LEN(@dias_temp));
            END
            
            -- Procesar horarios (formato: '09:00-10:00,18:00-19:00')
            DECLARE @horarios_temp NVARCHAR(200) = @horarios + ',';
            WHILE CHARINDEX(',', @horarios_temp) > 0
            BEGIN
                SET @pos = CHARINDEX(',', @horarios_temp);
                SET @horario = LTRIM(RTRIM(SUBSTRING(@horarios_temp, 1, @pos - 1)));
                
                -- Validar formato horario (debe contener guión)
                IF CHARINDEX('-', @horario) = 0
                BEGIN
                    RAISERROR('Formato de horario inválido: %s. Use formato HH:MM-HH:MM', 16, 1, @horario);
                    RETURN;
                END
                
                -- Extraer hora inicio y fin
                SET @hora_inicio = CAST(SUBSTRING(@horario, 1, CHARINDEX('-', @horario) - 1) AS TIME);
                SET @hora_fin = CAST(SUBSTRING(@horario, CHARINDEX('-', @horario) + 1, LEN(@horario)) AS TIME);
                
                -- Validar que hora inicio < hora fin
                IF @hora_inicio >= @hora_fin
                BEGIN
                    RAISERROR('La hora de inicio debe ser menor que la hora de fin: %s', 16, 1, @horario);
                    RETURN;
                END
                
                INSERT INTO #TempHorarios (hora_inicio, hora_fin) VALUES (@hora_inicio, @hora_fin);
                SET @horarios_temp = SUBSTRING(@horarios_temp, @pos + 1, LEN(@horarios_temp));
            END
            
            -- Crear todas las combinaciones día-horario
            INSERT INTO #TempCombinacion (dia, hora_inicio, hora_fin)
            SELECT d.dia, h.hora_inicio, h.hora_fin
            FROM #TempDias d
            CROSS JOIN #TempHorarios h;
            
            -- Verificar solapamientos de horarios en el mismo día
            IF EXISTS (
                SELECT dia 
                FROM #TempCombinacion t1
                WHERE EXISTS (
                    SELECT 1 FROM #TempCombinacion t2 
                    WHERE t1.dia = t2.dia 
                        AND t1.hora_inicio != t2.hora_inicio
                        AND (t1.hora_inicio < t2.hora_fin AND t1.hora_fin > t2.hora_inicio)
                )
            )
            BEGIN
                RAISERROR('Hay horarios que se solapan en el mismo día', 16, 1);
                RETURN;
            END
            
            -- Insertar todas las combinaciones
            INSERT INTO eSocios.ActividadDiaHorario (id_actividad, dia, hora_inicio, hora_fin)
            SELECT @id_actividad, dia, hora_inicio, hora_fin
            FROM #TempCombinacion;
            
            DROP TABLE #TempDias;
            DROP TABLE #TempHorarios;
            DROP TABLE #TempCombinacion;
        END   
        COMMIT TRANSACTION;
        
        -- Retornar información de la actividad creada
        SELECT 
            a.id_actividad,
            a.nombre,
            a.costo_mensual,
            COUNT(adh.dia) as cantidad_horarios
        FROM eSocios.Actividad a
        LEFT JOIN eSocios.ActividadDiaHorario adh ON a.id_actividad = adh.id_actividad
        WHERE a.id_actividad = @id_actividad
        GROUP BY a.id_actividad, a.nombre, a.costo_mensual;
        
        PRINT 'Actividad creada exitosamente con ID: ' + CAST(@id_actividad as VARCHAR(10));
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @error_message = ERROR_MESSAGE();
        RAISERROR(@error_message, 16, 1);
    END CATCH
END
GO



CREATE OR ALTER PROCEDURE eSocios.ModificarActividad
    @id_actividad INT,
    @nombre NVARCHAR(50) = NULL,
    @costo_mensual DECIMAL(10,2) = NULL,
    @dias NVARCHAR(200) = NULL, -- Días separados por coma: 'lunes,miércoles,viernes'
    @horarios NVARCHAR(200) = NULL, -- Horarios separados por coma: '09:00-10:00,18:00-19:00'
    @reemplazar_horarios BIT = 0 -- 0 = mantener horarios existentes, 1 = reemplazar todos los horarios
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @error_message NVARCHAR(500);
    DECLARE @dia VARCHAR(20);
    DECLARE @horario VARCHAR(20);
    DECLARE @hora_inicio TIME;
    DECLARE @hora_fin TIME;
    DECLARE @pos INT;
    DECLARE @nombre_actual NVARCHAR(50);
    DECLARE @costo_actual DECIMAL(10,2);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar que la actividad existe
        IF NOT EXISTS (SELECT 1 FROM eSocios.Actividad WHERE id_actividad = @id_actividad)
        BEGIN
            RAISERROR('No existe una actividad con ID: %d', 16, 1, @id_actividad);
            RETURN;
        END
        
        -- Obtener datos actuales
        SELECT @nombre_actual = nombre, @costo_actual = costo_mensual
        FROM eSocios.Actividad 
        WHERE id_actividad = @id_actividad;
        
        -- Si no se pasan parámetros para modificar, mostrar error
        IF @nombre IS NULL AND @costo_mensual IS NULL AND @dias IS NULL AND @horarios IS NULL
        BEGIN
            RAISERROR('Debe especificar al menos un campo para modificar', 16, 1);
            RETURN;
        END
        
        -- Validar nombre si se proporciona
        IF @nombre IS NOT NULL
        BEGIN
            IF TRIM(@nombre) = ''
            BEGIN
                RAISERROR('El nombre de la actividad no puede estar vacío', 16, 1);
                RETURN;
            END
            
            -- Verificar que no exista otra actividad con el mismo nombre
            IF EXISTS (SELECT 1 FROM eSocios.Actividad WHERE nombre = @nombre AND id_actividad != @id_actividad)
            BEGIN
                RAISERROR('Ya existe otra actividad con el nombre: %s', 16, 1, @nombre);
                RETURN;
            END
        END
        
        -- Validar costo si se proporciona
        IF @costo_mensual IS NOT NULL AND @costo_mensual < 0
        BEGIN
            RAISERROR('El costo mensual debe ser mayor o igual a 0', 16, 1);
            RETURN;
        END
        
        -- Validar que si se pasan días también se pasen horarios y viceversa
        IF (@dias IS NOT NULL AND @horarios IS NULL) OR (@dias IS NULL AND @horarios IS NOT NULL)
        BEGIN
            RAISERROR('Si especifica días debe especificar horarios y viceversa', 16, 1);
            RETURN;
        END
        
        -- Actualizar datos básicos de la actividad
        UPDATE eSocios.Actividad 
        SET 
            nombre = ISNULL(@nombre, nombre),
            costo_mensual = ISNULL(@costo_mensual, costo_mensual)
        WHERE id_actividad = @id_actividad;
        
        -- Procesar horarios si se proporcionaron
        IF @dias IS NOT NULL AND @horarios IS NOT NULL
        BEGIN
            -- Si se debe reemplazar todos los horarios, eliminar los existentes
            IF @reemplazar_horarios = 1
            BEGIN
                DELETE FROM eSocios.ActividadDiaHorario WHERE id_actividad = @id_actividad;
            END
            
            -- Crear tablas temporales
            CREATE TABLE #TempDias (dia VARCHAR(20));
            CREATE TABLE #TempHorarios (hora_inicio TIME, hora_fin TIME);
            CREATE TABLE #TempCombinacion (dia VARCHAR(20), hora_inicio TIME, hora_fin TIME);
            
            -- Procesar días (separados por coma)
            DECLARE @dias_temp NVARCHAR(200) = @dias + ',';
            WHILE CHARINDEX(',', @dias_temp) > 0
            BEGIN
                SET @pos = CHARINDEX(',', @dias_temp);
                SET @dia = LTRIM(RTRIM(SUBSTRING(@dias_temp, 1, @pos - 1)));
                
                -- Validar día
                IF @dia NOT IN ('lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo')
                BEGIN
                    RAISERROR('Día inválido: %s. Debe ser: lunes, martes, miércoles, jueves, viernes, sábado, domingo', 16, 1, @dia);
                    RETURN;
                END
                
                INSERT INTO #TempDias (dia) VALUES (@dia);
                SET @dias_temp = SUBSTRING(@dias_temp, @pos + 1, LEN(@dias_temp));
            END
            
            -- Procesar horarios (formato: '09:00-10:00,18:00-19:00')
            DECLARE @horarios_temp NVARCHAR(200) = @horarios + ',';
            WHILE CHARINDEX(',', @horarios_temp) > 0
            BEGIN
                SET @pos = CHARINDEX(',', @horarios_temp);
                SET @horario = LTRIM(RTRIM(SUBSTRING(@horarios_temp, 1, @pos - 1)));
                
                -- Validar formato horario (debe contener guión)
                IF CHARINDEX('-', @horario) = 0
                BEGIN
                    RAISERROR('Formato de horario inválido: %s. Use formato HH:MM-HH:MM', 16, 1, @horario);
                    RETURN;
                END
                
                -- Extraer hora inicio y fin
                SET @hora_inicio = CAST(SUBSTRING(@horario, 1, CHARINDEX('-', @horario) - 1) AS TIME);
                SET @hora_fin = CAST(SUBSTRING(@horario, CHARINDEX('-', @horario) + 1, LEN(@horario)) AS TIME);
                
                -- Validar que hora inicio < hora fin
                IF @hora_inicio >= @hora_fin
                BEGIN
                    RAISERROR('La hora de inicio debe ser menor que la hora de fin: %s', 16, 1, @horario);
                    RETURN;
                END
                
                INSERT INTO #TempHorarios (hora_inicio, hora_fin) VALUES (@hora_inicio, @hora_fin);
                SET @horarios_temp = SUBSTRING(@horarios_temp, @pos + 1, LEN(@horarios_temp));
            END
            
            -- Crear todas las combinaciones día-horario
            INSERT INTO #TempCombinacion (dia, hora_inicio, hora_fin)
            SELECT d.dia, h.hora_inicio, h.hora_fin
            FROM #TempDias d
            CROSS JOIN #TempHorarios h;
            
            -- Verificar solapamientos con horarios existentes (si no se reemplazan)
            IF @reemplazar_horarios = 0
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM #TempCombinacion tc
                    WHERE EXISTS (
                        SELECT 1 FROM eSocios.ActividadDiaHorario adh
                        WHERE adh.id_actividad = @id_actividad
                            AND adh.dia = tc.dia
                            AND (tc.hora_inicio < adh.hora_fin AND tc.hora_fin > adh.hora_inicio)
                    )
                )
                BEGIN
                    RAISERROR('Los nuevos horarios se solapan con horarios existentes', 16, 1);
                    RETURN;
                END
            END
            
            -- Verificar solapamientos entre los nuevos horarios
            IF EXISTS (
                SELECT dia 
                FROM #TempCombinacion t1
                WHERE EXISTS (
                    SELECT 1 FROM #TempCombinacion t2 
                    WHERE t1.dia = t2.dia 
                        AND t1.hora_inicio != t2.hora_inicio
                        AND (t1.hora_inicio < t2.hora_fin AND t1.hora_fin > t2.hora_inicio)
                )
            )
            BEGIN
                RAISERROR('Hay horarios que se solapan en el mismo día', 16, 1);
                RETURN;
            END
            
            -- Insertar los nuevos horarios (evitar duplicados si no se reemplazaron)
            INSERT INTO eSocios.ActividadDiaHorario (id_actividad, dia, hora_inicio, hora_fin)
            SELECT @id_actividad, tc.dia, tc.hora_inicio, tc.hora_fin
            FROM #TempCombinacion tc
            WHERE NOT EXISTS (
                SELECT 1 FROM eSocios.ActividadDiaHorario adh
                WHERE adh.id_actividad = @id_actividad
                    AND adh.dia = tc.dia
                    AND adh.hora_inicio = tc.hora_inicio
                    AND adh.hora_fin = tc.hora_fin
            );
            
            DROP TABLE #TempDias;
            DROP TABLE #TempHorarios;
            DROP TABLE #TempCombinacion;
        END
        
        COMMIT TRANSACTION;
        
        -- Retornar información de la actividad modificada
        SELECT 
            a.id_actividad,
            a.nombre,
            a.costo_mensual,
            COUNT(adh.dia) as cantidad_horarios,
            CASE 
                WHEN @nombre IS NOT NULL AND @nombre != @nombre_actual THEN 'Nombre modificado'
                ELSE 'Nombre sin cambios'
            END as cambio_nombre,
            CASE 
                WHEN @costo_mensual IS NOT NULL AND @costo_mensual != @costo_actual THEN 'Costo modificado'
                ELSE 'Costo sin cambios'
            END as cambio_costo,
            CASE 
                WHEN @dias IS NOT NULL AND @horarios IS NOT NULL THEN 
                    CASE WHEN @reemplazar_horarios = 1 THEN 'Horarios reemplazados' ELSE 'Horarios agregados' END
                ELSE 'Horarios sin cambios'
            END as cambio_horarios
        FROM eSocios.Actividad a
        LEFT JOIN eSocios.ActividadDiaHorario adh ON a.id_actividad = adh.id_actividad
        WHERE a.id_actividad = @id_actividad
        GROUP BY a.id_actividad, a.nombre, a.costo_mensual;
        
        PRINT 'Actividad modificada exitosamente';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @error_message = ERROR_MESSAGE();
        RAISERROR(@error_message, 16, 1);
    END CATCH
END
GO



CREATE OR ALTER PROCEDURE eSocios.EliminarActividad
    @id_actividad INT = NULL,
    @nombre NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @error_message NVARCHAR(500);
    DECLARE @nombre_actividad NVARCHAR(50);
    DECLARE @cantidad_horarios INT;
    DECLARE @costo_actividad DECIMAL(10,2);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar que se proporcione al menos un parámetro de búsqueda
        IF @id_actividad IS NULL AND @nombre IS NULL
        BEGIN
            RAISERROR('Debe especificar el ID o el nombre de la actividad a eliminar', 16, 1);
            RETURN;
        END
        
        -- Si se proporciona nombre, buscar el ID
        IF @nombre IS NOT NULL AND @id_actividad IS NULL
        BEGIN
            SELECT @id_actividad = id_actividad 
            FROM eSocios.Actividad 
            WHERE nombre = @nombre;
            
            IF @id_actividad IS NULL
            BEGIN
                RAISERROR('No se encontró una actividad con el nombre: %s', 16, 1, @nombre);
                RETURN;
            END
        END
        
        -- Verificar que la actividad existe
        IF NOT EXISTS (SELECT 1 FROM eSocios.Actividad WHERE id_actividad = @id_actividad)
        BEGIN
            RAISERROR('No existe una actividad con ID: %d', 16, 1, @id_actividad);
            RETURN;
        END
        
        -- Obtener información de la actividad antes de eliminarla
        SELECT 
            @nombre_actividad = nombre,
            @costo_actividad = costo_mensual
        FROM eSocios.Actividad 
        WHERE id_actividad = @id_actividad;
        
        -- Contar horarios asociados
        SELECT @cantidad_horarios = COUNT(*)
        FROM eSocios.ActividadDiaHorario 
        WHERE id_actividad = @id_actividad;
        
        -- Verificar si hay dependencias (esto sería útil si tienes otras tablas relacionadas)
        -- Por ejemplo, si tienes una tabla de inscripciones:
        /*
        IF EXISTS (SELECT 1 FROM eSocios.Inscripciones WHERE id_actividad = @id_actividad)
        BEGIN
            RAISERROR('No se puede eliminar la actividad porque tiene inscripciones asociadas', 16, 1);
            RETURN;
        END
        */
        
        -- Eliminar horarios primero (por la foreign key)
        DELETE FROM eSocios.ActividadDiaHorario 
        WHERE id_actividad = @id_actividad;
        
        -- Eliminar la actividad
        DELETE FROM eSocios.Actividad 
        WHERE id_actividad = @id_actividad;
        
        COMMIT TRANSACTION;
        
        -- Mostrar confirmación de eliminación
        SELECT 
            'ACTIVIDAD ELIMINADA EXITOSAMENTE' as Resultado,
            @id_actividad as ID_Eliminado,
            @nombre_actividad as Nombre_Eliminado,
            @costo_actividad as Costo_Eliminado,
            @cantidad_horarios as Horarios_Eliminados,
            GETDATE() as Fecha_Eliminacion;
        
        PRINT 'Actividad "' + @nombre_actividad + '" eliminada exitosamente con ' + CAST(@cantidad_horarios as VARCHAR(10)) + ' horarios asociados';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @error_message = ERROR_MESSAGE();
        RAISERROR(@error_message, 16, 1);
    END CATCH
END
GO

	-- elimina a un socio de una actividad
CREATE OR ALTER PROCEDURE eSocios.DesinscribirActividad
		@id_socio INT,
		@id_actividad INT
	AS
	BEGIN
		SET NOCOUNT ON;
    
		BEGIN TRY
			DELETE FROM eSocios.Realiza
			WHERE socio = @id_socio AND id_actividad = @id_actividad;
        
			IF @@ROWCOUNT = 0
				THROW 50001, 'El socio no está asignado a esta actividad', 1;
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
			THROW 50000, @ErrorMessage, 1;
		END CATCH
	END;
GO


-- crea un nuevo grupo familiar asignando un adulto responsable
-- verifica que el adulto no tenga ya un grupo familiar asignado
CREATE OR ALTER PROCEDURE eSocios.CrearGrupoFamiliar
    @id_adulto_responsable INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- verifica que el socio existe y es mayor de edad
        DECLARE @id_categoria INT;
        DECLARE @categoria_nombre VARCHAR(50);
        
        SELECT @id_categoria = id_categoria 
        FROM eSocios.Socio 
        WHERE id_socio = @id_adulto_responsable;
        
        IF @id_categoria IS NULL
            THROW 50001, 'El adulto responsable especificado no existe', 1;
            
        SELECT @categoria_nombre = nombre 
        FROM eSocios.Categoria 
        WHERE id_categoria = @id_categoria;
        
        IF @categoria_nombre != 'Mayor'
            THROW 50002, 'El adulto responsable debe ser mayor de edad', 1;
            
        -- verifica que el adulto no tenga ya un grupo familiar
        IF EXISTS (
            SELECT 1 
            FROM eSocios.GrupoFamiliar 
            WHERE id_adulto_responsable = @id_adulto_responsable
        )
            THROW 50003, 'El adulto ya es responsable de otro grupo familiar', 1;
            
     
        -- crea el grupo familiar con descuento por defecto del 15%
        INSERT INTO eSocios.GrupoFamiliar (id_adulto_responsable, descuento)
        VALUES ( @id_adulto_responsable, 15.00);
        
        -- obtiene el ID del grupo recién creado
		DECLARE @id_grupo_familiar INT;
        SET @id_grupo_familiar = SCOPE_IDENTITY();
        
        -- actualiza el socio para que pertenezca al grupo familiar
        UPDATE eSocios.Socio
        SET id_grupo_familiar = @id_grupo_familiar
        WHERE id_socio = @id_adulto_responsable;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO


-- agrega un miembro a un grupo familiar existente
-- verifica que el miembro no pertenezca ya a otro grupo
CREATE OR ALTER PROCEDURE eSocios.AgregarMiembroAGrupoFamiliar
    @id_grupo INT,
    @id_socio INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- verifica que el grupo existe
        IF NOT EXISTS (
            SELECT 1 
            FROM eSocios.GrupoFamiliar 
            WHERE id_grupo = @id_grupo
        )
            THROW 50001, 'El grupo familiar especificado no existe', 1;
            
        -- verifica que el socio existe
        IF NOT EXISTS (
            SELECT 1 
            FROM eSocios.Socio 
            WHERE id_socio = @id_socio
        )
            THROW 50002, 'El socio especificado no existe', 1;
            
        -- verifica que el socio no es ya el adulto responsable
        DECLARE @id_adulto_responsable INT;
        
        SELECT @id_adulto_responsable = id_adulto_responsable
        FROM eSocios.GrupoFamiliar
        WHERE id_grupo = @id_grupo;
        
        IF @id_socio = @id_adulto_responsable
            THROW 50003, 'El socio ya es el adulto responsable de este grupo', 1;
            
        -- verifica que el socio no pertenece ya a otro grupo
        IF EXISTS (
            SELECT 1 
            FROM eSocios.Socio 
            WHERE id_socio = @id_socio 
            AND id_grupo_familiar IS NOT NULL
            AND id_grupo_familiar != @id_grupo
        )
            THROW 50004, 'El socio ya pertenece a otro grupo familiar', 1;
            
        -- agrega el socio al grupo familiar
        UPDATE eSocios.Socio
        SET id_grupo_familiar = @id_grupo
        WHERE id_socio = @id_socio;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;

GO


-- asigna tutor para socio menor
CREATE OR ALTER PROCEDURE eSocios.AsignarTutor
    @id_socio INT,
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @email NVARCHAR(100),
    @fecha_nac DATE,
    @telefono VARCHAR(10),
    @parentesco VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- valida que el socio existe y es menor de edad
        DECLARE @id_categoria INT;
        DECLARE @categoria_nombre VARCHAR(50);
        DECLARE @edad INT;
        
        SELECT @id_categoria = id_categoria, @edad = DATEDIFF(YEAR, fecha_nac, GETDATE())
        FROM eSocios.Socio
        WHERE id_socio = @id_socio;
        
        IF @id_categoria IS NULL
            THROW 50001, 'El socio especificado no existe', 1;
            
        SELECT @categoria_nombre = nombre 
        FROM eSocios.Categoria 
        WHERE id_categoria = @id_categoria;
        
        IF @categoria_nombre = 'Mayor' OR @edad >= 18
            THROW 50002, 'Solo se pueden asignar tutores a socios menores de edad', 1;
            
        -- insertar tutor
        INSERT INTO eSocios.Tutor (
            id_socio, nombre, apellido, email, fecha_nac, telefono, parentesco
        )
        VALUES (
            @id_socio, @nombre, @apellido, @email, @fecha_nac, @telefono, @parentesco
        );
        
        RETURN SCOPE_IDENTITY(); -- retorna el ID del nuevo tutor
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO


-- asigna un tutor a un socio menor, tomando los datos de un socio existente
-- el socio tutor debe ser mayor de edad (categoria 'Mayor')
-- el socio al que se le asigna el tutor debe ser menor de edad (categoria 'Menor' o 'Cadete')
CREATE OR ALTER PROCEDURE eSocios.AsignarTutorDesdeSocio
    @id_socio_menor INT,
    @id_socio_tutor INT,
    @parentesco VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- verifica que el socio a tutelar existe y es menor
        DECLARE @categoria_menor VARCHAR(50);
        DECLARE @edad_menor INT;
        
        SELECT @categoria_menor = c.nombre, 
               @edad_menor = DATEDIFF(YEAR, s.fecha_nac, GETDATE())
        FROM eSocios.Socio s
        JOIN eSocios.Categoria c ON s.id_categoria = c.id_categoria
        WHERE s.id_socio = @id_socio_menor;
        
        IF @categoria_menor IS NULL
            THROW 50001, 'El socio a tutelar no existe', 1;
            
        IF @categoria_menor = 'Mayor' OR @edad_menor >= 18
            THROW 50002, 'Solo se pueden asignar tutores a socios menores de edad', 1;
            
        -- verifica que el socio tutor existe y es mayor
        DECLARE @categoria_tutor VARCHAR(50);
        DECLARE @nombre_tutor VARCHAR(50);
        DECLARE @apellido_tutor VARCHAR(50);
        DECLARE @email_tutor NVARCHAR(100);
        DECLARE @fecha_nac_tutor DATE;
        DECLARE @telefono_tutor VARCHAR(10);
        
        SELECT @categoria_tutor = c.nombre,
               @nombre_tutor = s.nombre,
               @apellido_tutor = s.apellido,
               @email_tutor = s.email,
               @fecha_nac_tutor = s.fecha_nac,
               @telefono_tutor = s.telefono
        FROM eSocios.Socio s
        JOIN eSocios.Categoria c ON s.id_categoria = c.id_categoria
        WHERE s.id_socio = @id_socio_tutor;
        
        IF @categoria_tutor IS NULL
            THROW 50003, 'El socio tutor no existe', 1;
            
        IF @categoria_tutor != 'Mayor'
            THROW 50004, 'El tutor debe ser mayor de edad', 1;
            
        -- verifica que no sea ya tutor de este socio
        IF EXISTS (
            SELECT 1 
            FROM eSocios.Tutor 
            WHERE id_socio = @id_socio_menor 
            AND nombre = @nombre_tutor 
            AND apellido = @apellido_tutor
        )
            THROW 50005, 'Este socio ya es tutor del menor especificado', 1;
            
        -- inserta el tutor
        INSERT INTO eSocios.Tutor (
            id_socio,
            nombre,
            apellido,
            email,
            fecha_nac,
            telefono,
            parentesco
        )
        VALUES (
            @id_socio_menor,
            @nombre_tutor,
            @apellido_tutor,
            @email_tutor,
            @fecha_nac_tutor,
            @telefono_tutor,
            @parentesco
        );
        
        RETURN SCOPE_IDENTITY(); -- retorna el id del nuevo tutor
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END; --------------
GO


CREATE OR ALTER PROCEDURE eSocios.ModificarTutor
		@id_tutor INT,
		@nombre VARCHAR(50),
		@apellido VARCHAR(50),
		@email NVARCHAR(100),
		@fecha_nac DATE,
		@telefono VARCHAR(10),
		@parentesco VARCHAR(20)
	AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
	-- Verificar que el tutor exista
			IF NOT EXISTS (
				SELECT 1 
				FROM eSocios.Tutor 
				WHERE id_tutor = @id_tutor
			)
			THROW 60001, 'El tutor especificado no existe', 1;

	-- Verificar que no se repita el email con otro tutor
			IF EXISTS (
				SELECT 1 
				FROM eSocios.Tutor 
				WHERE email = @email AND id_tutor <> @id_tutor
			)
			THROW 60002, 'Ya existe otro tutor con ese email', 1;
	-- Actualizar datos del tutor
			UPDATE eSocios.Tutor
			SET nombre = @nombre,
				apellido = @apellido,
				email = @email,
				fecha_nac = @fecha_nac,
				telefono = @telefono,
				parentesco = @parentesco
			WHERE id_tutor = @id_tutor;

		END TRY
		BEGIN CATCH
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
			THROW 50000, @ErrorMessage, 1;
		END CATCH
	END; ----R
GO


CREATE OR ALTER PROCEDURE eSocios.EliminarTutor
		@id_tutor INT
	AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
	-- Verificar que el tutor exista
			IF NOT EXISTS (
				SELECT 1 
				FROM eSocios.Tutor 
				WHERE id_tutor = @id_tutor
			)
			THROW 60101, 'El tutor especificado no existe', 1;

	-- Eliminar tutor
			DELETE FROM eSocios.Tutor
			WHERE id_tutor = @id_tutor;

		END TRY
		BEGIN CATCH
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
			THROW 60100, @ErrorMessage, 1;
		END CATCH
	END; ----R
	GO


-- SP para generar factura mensual con el total de actividades y membresia 
CREATE OR ALTER PROCEDURE eCobros.generarFactura
    @id_socio INT,
    @periodo VARCHAR(20), -- formato: 'MM/YYYY'
    @fecha_emision DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    --verifica que el socio existe
    IF NOT EXISTS (SELECT 1 FROM eSocios.Socio WHERE id_socio = @id_socio)
    BEGIN
        PRINT CONCAT('Error: El socio con ID ', @id_socio, ' no existe.');
        RETURN -1;
    END;
    
    --obtiene el grupo y categoria
    DECLARE @id_grupo_familiar INT, @id_categoria INT, @costo_membresia DECIMAL(10,2);
    
    SELECT 
        @id_grupo_familiar = id_grupo_familiar,
        @id_categoria = id_categoria
    FROM eSocios.Socio
    WHERE id_socio = @id_socio;
    
    --valida que la categoria existe y tiene costo
    SELECT @costo_membresia = costo_mensual 
    FROM eSocios.Categoria 
    WHERE id_categoria = @id_categoria;

    IF @costo_membresia IS NULL
    BEGIN
        PRINT CONCAT('Error: La categoría con ID ', @id_categoria, ' no existe o no tiene costo definido.');
        RETURN -1;
    END;
    

    DECLARE @id_factura INT;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- establece fecha por defecto si no se proporciona
        IF @fecha_emision IS NULL 
            SET @fecha_emision = GETDATE();
        
        -- calcula fechas de vencimiento
        DECLARE @fecha_venc_1 DATE = DATEADD(DAY, 5, @fecha_emision);
        DECLARE @fecha_venc_2 DATE = DATEADD(DAY, 5, @fecha_venc_1);
        
        -- variables de calculo
        DECLARE @total_membresias DECIMAL(10,2) = @costo_membresia;
        DECLARE @porcentaje_descuento_familiar DECIMAL(5,2) = 0;
        DECLARE @porcentaje_descuento_actividades DECIMAL(5,2) = 0;
        
        -- aplica o no descuento familiar 
        IF @id_grupo_familiar IS NOT NULL
            SELECT @porcentaje_descuento_familiar = ISNULL(descuento, 0)
            FROM eSocios.GrupoFamiliar
            WHERE id_grupo = @id_grupo_familiar;
        
        -- calcular total de actividades
        DECLARE @total_actividades DECIMAL(10,2) = 0;
        SELECT @total_actividades = ISNULL(SUM(a.costo_mensual), 0)
        FROM eSocios.Realiza sa
        JOIN eSocios.Actividad a ON sa.id_actividad = a.id_actividad
        WHERE sa.socio = @id_socio;
        
        -- descuento por multiples actividades
        IF (SELECT COUNT(*) FROM eSocios.Realiza WHERE socio = @id_socio) > 1
            SET @porcentaje_descuento_actividades = 10;
        
        -- calcula total con descuentos
        DECLARE @total_con_descuentos DECIMAL(10,2) = 
            @total_membresias * (1 - @porcentaje_descuento_familiar / 100) +
            @total_actividades * (1 - @porcentaje_descuento_actividades / 100);
        
        -- inserta factura
        INSERT INTO eCobros.Factura 
		(
            id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, 
            estado, total, recargo_venc, descuentos
        )
        VALUES 
		(
            @id_socio, @fecha_emision, @fecha_venc_1, @fecha_venc_2, 
            'pendiente', @total_con_descuentos, 0, 
            @porcentaje_descuento_familiar + @porcentaje_descuento_actividades
        );
        
        SET @id_factura = SCOPE_IDENTITY();
        
        -- insertar item de membresia
        DECLARE @nombre_categoria VARCHAR(50);
        SELECT @nombre_categoria = nombre
        FROM eSocios.Categoria
        WHERE id_categoria = @id_categoria;
        
        INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto, periodo)
        VALUES (
            @id_factura, 
            CONCAT('Membresía - ', @nombre_categoria), 
            @costo_membresia, 
            @periodo
        );
        
        -- insertar items por actividades
        INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto, periodo)
        SELECT 
            @id_factura, 
            a.nombre,      
            a.costo_mensual, 
            @periodo
        FROM eSocios.Realiza sa
        JOIN eSocios.Actividad a ON sa.id_actividad = a.id_actividad
        WHERE sa.socio = @id_socio;
        
        COMMIT TRANSACTION;
		PRINT CONCAT('Factura generada correctamente con ID: ', @id_factura);
        RETURN @id_factura;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END;
GO

-- procedimiento para aplicar recargo por segundo vencimiento
CREATE OR ALTER PROCEDURE eCobros.aplicarRecargoSegundoVencimiento
    @id_factura INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @fecha_venc_1 DATE;
        DECLARE @fecha_venc_2 DATE;
        DECLARE @estado VARCHAR(20);
        DECLARE @total_actual DECIMAL(10,2);
        DECLARE @recargo_aplicado BIT = 0;
        DECLARE @porcentaje_recargo DECIMAL(5,2) = 10;

        -- verifica si la factura existe
        IF NOT EXISTS (SELECT 1 FROM eCobros.Factura WHERE id_factura = @id_factura)
        BEGIN
            PRINT 'La factura con ID ' + CAST(@id_factura AS VARCHAR) + ' no existe.';
            RETURN;
        END;

        -- obtiene datos de la factura
        SELECT 
            @fecha_venc_1 = fecha_venc_1,
            @fecha_venc_2 = fecha_venc_2,
            @estado = estado,
            @total_actual = total
        FROM eCobros.Factura
        WHERE id_factura = @id_factura;

        -- verifica si ya se aplico el recargo
        IF EXISTS (
            SELECT 1 
            FROM eCobros.ItemFactura 
            WHERE id_factura = @id_factura 
              AND concepto = 'recargo por segundo vencimiento'
        )
        BEGIN
            SET @recargo_aplicado = 1;
            PRINT 'Ya se había aplicado el recargo para la factura ' + CAST(@id_factura AS VARCHAR) + '.';
            RETURN;
        END;

        -- evalua condiciones de vencimiento
        IF @estado <> 'pendiente'
        BEGIN
            PRINT 'La factura ' + CAST(@id_factura AS VARCHAR) + ' no está pendiente.';
            RETURN;
        END;

        IF GETDATE() <= @fecha_venc_1
        BEGIN
            PRINT 'La factura ' + CAST(@id_factura AS VARCHAR) + ' aún está en primer vencimiento.';
            RETURN;
        END;
        
        IF GETDATE() > @fecha_venc_1
        BEGIN
            -- aplica recargo del 10%
            DECLARE @monto_recargo DECIMAL(10,2) = @total_actual * (@porcentaje_recargo / 100.0);

            -- actualiza total y recargo en factura
            UPDATE eCobros.Factura
            SET 
                total = @total_actual + @monto_recargo,
                recargo_venc = @porcentaje_recargo
            WHERE id_factura = @id_factura;

            -- inserta item de recargo
            INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto, periodo)
            VALUES (
                @id_factura, 
                'recargo por segundo vencimiento', 
                @monto_recargo, 
                CONVERT(VARCHAR(7), GETDATE(), 111)
            );

            PRINT 'Recargo aplicado correctamente a la factura ' + CAST(@id_factura AS VARCHAR) + 
                  '. Monto: $' + CAST(@monto_recargo AS VARCHAR);
            RETURN;
        END;

        IF GETDATE() > @fecha_venc_2
        BEGIN
            PRINT 'La factura ' + CAST(@id_factura AS VARCHAR) + 
                  ' ya superó el segundo vencimiento y se encuentra en mora. No se aplica recargo.';
            RETURN;
        END;
    END TRY
    BEGIN CATCH
        PRINT 'Error en la ejecución: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO


--borrado logico para factura
CREATE OR ALTER PROCEDURE eCobros.anularFactura
    @id_factura INT
AS
BEGIN
    SET NOCOUNT ON;


    -- verificar que la factura exista y no esté anulada
    IF NOT EXISTS (
        SELECT 1 
        FROM eCobros.Factura 
        WHERE id_factura = @id_factura AND estado <> 'anulada'
    )
    BEGIN
        PRINT 'La factura no existe o ya está anulada.';
        RETURN;
    END

    -- actualizar estado a anulada
    UPDATE eCobros.Factura
    SET estado = 'anulada'
    WHERE id_factura = @id_factura;

    -- Confirmación
    PRINT 'Factura ' + CAST(@id_factura AS VARCHAR(10)) + ' anulada correctamente.';
END;
GO


--registra una entrada a la pileta y se ascocia a una factura
CREATE OR ALTER PROCEDURE eCobros.RegistrarEntradaPileta
    @id_socio INT,
    @fecha DATE = NULL,
    @tipo VARCHAR(8), -- 'socio' o 'invitado'
    @lluvia BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Valida que el socio existe
	IF NOT EXISTS (SELECT 1 FROM eSocios.Socio WHERE id_socio = @id_socio)
    BEGIN
        PRINT 'Error: El socio especificado no existe.';
        RETURN;
    END

    -- valida tipo de entrada
    IF @tipo NOT IN ('socio', 'invitado')
    BEGIN
        PRINT 'Error: Tipo de entrada no válido. Debe ser "socio" o "invitado".';
        RETURN;
    END
    
    -- establece fecha por defecto (hoy)
    IF @fecha IS NULL
		SET @fecha = CONVERT(DATE, GETDATE());


    -- verifica morosidad 
	IF EXISTS
	(
		SELECT 1
        FROM eCobros.Factura
        WHERE id_socio = @id_socio
          AND estado = 'pendiente'
          AND fecha_venc_2 < @fecha
    )
    BEGIN
        PRINT 'Error: El socio tiene cuotas impagas y no puede acceder a la pileta.';
        RETURN;
    END

    -- determina monto según tipo y tarifas
    DECLARE @monto DECIMAL(10,2);
        
    IF @tipo = 'socio'
        SET @monto =  500.00 -- valor por defecto para socios
    ELSE
        SET @monto =  800.00 -- valor por defecto para invitados


    BEGIN TRY
        BEGIN TRANSACTION;
  
        -- crea factura si no existe una para hoy
        DECLARE @id_factura INT;
        DECLARE @id_item INT;
        
        -- busca factura existente para hoy
        SELECT @id_factura = id_factura
        FROM eCobros.Factura
        WHERE id_socio = @id_socio 
          AND CONVERT(DATE, fecha_emision) = @fecha
          AND estado = 'pendiente';
        
        IF @id_factura IS NULL
        BEGIN
            -- crea nueva factura
            INSERT INTO eCobros.Factura 
			(
                id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, estado, total
            )
            VALUES 
			(
                @id_socio, @fecha, DATEADD(DAY, 5, @fecha), DATEADD(DAY, 10, @fecha), 'pendiente', 0
            );
            
            SET @id_factura = SCOPE_IDENTITY();
        END
        
        -- crea ítem en factura para la entrada
        INSERT INTO eCobros.ItemFactura 
		(
            id_factura, concepto, monto, periodo
        )
        VALUES 
		(
            @id_factura, 'Entrada Pileta - ' + @tipo, @monto, FORMAT(@fecha, 'yyyyMM')
        );
        
        SET @id_item = SCOPE_IDENTITY();
        
        -- actualiza total de la factura
        UPDATE eCobros.Factura
        SET total = total + @monto
        WHERE id_factura = @id_factura;
        
        
        -- aplica reembolso automático si hay lluvia
		DECLARE @reembolso DECIMAL(10,2) = 0
        IF @lluvia = 1
        BEGIN
            SET @reembolso = @monto * 0.6; -- 60% de reembolso
            
            -- crea ítem en factura para el reembolso
            INSERT INTO eCobros.ItemFactura 
			(
                id_factura, concepto, monto, periodo
            )
            VALUES 
			(
                @id_factura, 'Reembolso Por Lluvia Entrada Pileta - ' + @tipo, -@reembolso, FORMAT(@fecha, 'yyyyMM')
            );

            -- resta el reembolso al total
            UPDATE eCobros.Factura
            SET total = total - @reembolso
            WHERE id_factura = @id_factura;
        END

        -- registra la entrada a la pileta
        INSERT INTO eCobros.EntradaPileta 
		(
            id_socio, id_item_factura, fecha, monto, tipo, lluvia
        )
        VALUES (
            @id_socio, @id_item, @fecha, @monto - @reembolso, @tipo, @lluvia
        );
		
        COMMIT TRANSACTION;
        PRINT 'La entrada a la pileta se registró correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

--reembolsa una entrada a la pileta
CREATE OR ALTER PROCEDURE eCobros.AnularEntradaPileta
    @id_entrada INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que la entrada exista 
    IF NOT EXISTS 
	(
        SELECT 1 FROM eCobros.EntradaPileta
        WHERE id_entrada = @id_entrada 
    )
    BEGIN
        PRINT 'Error: La entrada no existe';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Obtener datos de la entrada y factura relacionada
        DECLARE 
            @id_item INT,
            @id_factura INT,
            @monto DECIMAL(10,2),
            @tipo VARCHAR(8),
            @fecha DATE;

		SELECT 
            @id_item = ep.id_item_factura,
            @monto  = ep.monto,
            @tipo = ep.tipo,
            @fecha = ep.fecha,
            @id_factura = it.id_factura
        FROM eCobros.ItemFactura it 
        INNER JOIN eCobros.EntradaPileta ep ON ep.id_item_factura = it.id_item
        WHERE ep.id_entrada = @id_entrada;

        -- inserta reembolso en factura
        INSERT INTO eCobros.ItemFactura 
		(
            id_factura, concepto, monto, periodo
        )
        VALUES 
		(
            @id_factura, 'Reembolso Entrada Pileta - ' + @tipo, -@monto, FORMAT(@fecha, 'yyyyMM')
        );

        -- Actualizar total factura restando monto
        UPDATE eCobros.Factura
        SET total = total - @monto
        WHERE id_factura = @id_factura;

        COMMIT TRANSACTION;

        PRINT 'Entrada anulada y reembolso aplicado correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END;
GO



--genera un pago asociado a una factura
CREATE OR ALTER PROCEDURE eCobros.CargarPago
    @id_factura INT,
    @medio_pago VARCHAR(50),
    @monto DECIMAL(10,2),
    @fecha DATE = NULL,
    @debito_auto BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables para validaciones
    DECLARE @estado_factura VARCHAR(20);
    DECLARE @total_factura DECIMAL(10,2);
    DECLARE @total_pagado DECIMAL(10,2) = 0;
    DECLARE @fecha_pago DATE;
	DECLARE @id_pago INT;
    
    -- Validar que la factura existe y obtener su estado y total
    SELECT @estado_factura = estado, 
            @total_factura = total
    FROM eCobros.Factura 
    WHERE id_factura = @id_factura;
        
    -- Si no se encontró la factura, @estado_factura será NULL
    IF @estado_factura IS NULL
    BEGIN
        PRINT 'La factura especificada no existe.';
        RETURN;
    END

    -- Validar que la factura no esté anulada
    IF @estado_factura = 'anulada'
    BEGIN
        PRINT 'No se puede registrar un pago para una factura anulada.';
        RETURN;
    END

    -- Validar que la factura no esté ya completamente pagada
    IF @estado_factura = 'pagada'
    BEGIN
        PRINT 'La factura ya se encuentra completamente pagada.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Si no se proporciona fecha, usar la fecha actual
        IF @fecha IS NULL
            SET @fecha_pago = GETDATE();
        ELSE
            SET @fecha_pago = @fecha;
  
        -- Calcular el total ya pagado para esta factura
        SELECT @total_pagado = ISNULL(SUM(monto), 0)
        FROM eCobros.Pago 
        WHERE id_factura = @id_factura 
          AND estado = 'completado';
        
        -- Validar que el monto del pago no exceda el saldo pendiente
        IF (@total_pagado + @monto) > @total_factura
        BEGIN
            DECLARE @saldo_pendiente DECIMAL(10,2) = @total_factura - @total_pagado;
            DECLARE @mensaje_error VARCHAR(200) = 
                'El monto del pago (' + CAST(@monto AS VARCHAR(20)) + 
                ') excede el saldo pendiente de la factura (' + 
                CAST(@saldo_pendiente AS VARCHAR(20)) + ').';
            THROW 50001, @mensaje_error, 1;
            RETURN;
        END
        
        
        -- Insertar el pago
        INSERT INTO eCobros.Pago 
		(
            id_factura, 
            medio_pago, 
            monto, 
            fecha, 
            estado, 
            debito_auto
        )
        VALUES (
            @id_factura,
            @medio_pago,
            @monto,
            @fecha_pago,
            'completado',
            @debito_auto
        );
        
        -- Actualizar el estado de la factura si está completamente pagada
        IF (@total_pagado + @monto) = @total_factura
        BEGIN
            UPDATE eCobros.Factura 
            SET estado = 'pagada' 
            WHERE id_factura = @id_factura;
        END

        SET @id_pago = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
        
        -- Mensaje de éxito
        PRINT 'Pago registrado exitosamente.';
        PRINT 'ID Pago: ' + CAST(@id_pago AS VARCHAR(10));
        PRINT 'Monto: $' + CAST(@monto AS VARCHAR(20));
        PRINT 'Medio de pago: ' + @medio_pago;
        
        IF (@total_pagado + @monto) = @total_factura
            PRINT 'Factura marcada como PAGADA completamente.';
        ELSE
        BEGIN
            DECLARE @saldo_restante DECIMAL(10,2) = @total_factura - (@total_pagado + @monto);
            PRINT 'Saldo restante: $' + CAST(@saldo_restante AS VARCHAR(20));
        END
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Capturar y mostrar el error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        THROW 50000, @ErrorMessage, @ErrorState;
    END CATCH
END
GO

--bprrado logico de pago
CREATE OR ALTER PROCEDURE eCobros.AnularPago 
    @id_pago INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar que el pago existe y está en estado 'completado'
        IF NOT EXISTS (
            SELECT 1 
            FROM eCobros.Pago 
            WHERE id_pago = @id_pago AND estado = 'completado'
        )
        BEGIN
            RAISERROR('El pago no existe o no está en estado completado.', 16, 1);
            RETURN;
        END
        
        -- Validar que no tenga reembolsos procesados
        IF EXISTS (
            SELECT 1 
            FROM eCobros.Reembolso 
            WHERE id_pago = @id_pago
        )
        BEGIN
            RAISERROR('No se puede anular un pago que tiene reembolsos asociados.', 16, 1);
            RETURN;
        END
        
        -- Realizar el borrado lógico cambiando el estado
        UPDATE eCobros.Pago 
        SET estado = 'anulado'
        WHERE id_pago = @id_pago;
        
        -- Obtener datos de la factura para actualizar su estado si es necesario
        DECLARE @id_factura INT;
        DECLARE @total_factura DECIMAL(10,2);
        DECLARE @total_pagado DECIMAL(10,2) = 0;
        
        SELECT @id_factura = id_factura 
        FROM eCobros.Pago 
        WHERE id_pago = @id_pago;
        
        SELECT @total_factura = total 
        FROM eCobros.Factura 
        WHERE id_factura = @id_factura;
        
        -- Calcular el total pagado (excluyendo pagos anulados)
        SELECT @total_pagado = ISNULL(SUM(monto), 0)
        FROM eCobros.Pago 
        WHERE id_factura = @id_factura 
          AND estado = 'completado';
        
        -- Actualizar estado de la factura
        IF @total_pagado = 0
        BEGIN
            -- Si no hay pagos, vuelve a pendiente
            UPDATE eCobros.Factura 
            SET estado = 'pendiente' 
            WHERE id_factura = @id_factura;
        END
        ELSE IF @total_pagado < @total_factura
        BEGIN
            -- Si hay pagos parciales, vuelve a pendiente
            UPDATE eCobros.Factura 
            SET estado = 'pendiente' 
            WHERE id_factura = @id_factura;
        END
        -- Si @total_pagado = @total_factura, mantiene estado 'pagada'
        
        COMMIT TRANSACTION;
        
        PRINT 'Pago anulado exitosamente.';
        PRINT 'ID Pago: ' + CAST(@id_pago AS VARCHAR(10));
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

--genera un reembolso para un pago
CREATE OR ALTER PROCEDURE eCobros.GenerarReembolso
    @id_pago INT,
    @monto DECIMAL(10,2),
    @motivo VARCHAR(100),
    @fecha DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones
    DECLARE @estado_pago VARCHAR(20);
    DECLARE @monto_pago DECIMAL(10,2);
    DECLARE @total_reembolsado DECIMAL(10,2) = 0;
    DECLARE @fecha_reembolso DATE;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Obtener estado y monto del pago
        SELECT @estado_pago = estado, @monto_pago = monto
        FROM eCobros.Pago
        WHERE id_pago = @id_pago;

        IF @estado_pago IS NULL
        BEGIN
            PRINT 'Error: El pago especificado no existe.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @estado_pago = 'anulado'
        BEGIN
            PRINT 'Error: No se puede reembolsar un pago anulado.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calcular total ya reembolsado para el pago
        SELECT @total_reembolsado = ISNULL(SUM(monto), 0)
        FROM eCobros.Reembolso
        WHERE id_pago = @id_pago;

        -- Validar que el nuevo reembolso no supere el total pagado
        IF (@total_reembolsado + @monto) > @monto_pago
        BEGIN
            PRINT 'Error: El monto del reembolso excede el total del pago original.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Fecha por defecto
        IF @fecha IS NULL
            SET @fecha_reembolso = CONVERT(DATE, GETDATE());
        ELSE
            SET @fecha_reembolso = @fecha;

        -- Insertar el reembolso
        INSERT INTO eCobros.Reembolso (id_pago, monto, motivo, fecha)
        VALUES (@id_pago, @monto, @motivo, @fecha_reembolso);

        -- Determinar nuevo estado del pago
        IF (@total_reembolsado + @monto) = @monto_pago
        BEGIN
            -- Reembolso total
            UPDATE eCobros.Pago
            SET estado = 'reembolsado'
            WHERE id_pago = @id_pago;
        END
        ELSE
        BEGIN
            -- Reembolso parcial, se mantiene en estado 'completado'
            UPDATE eCobros.Pago
            SET estado = 'completado'
            WHERE id_pago = @id_pago;
        END

        COMMIT TRANSACTION;

        PRINT 'Reembolso registrado exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error inesperado: ' + @ErrorMessage;
    END CATCH
END;
GO


--cancela un reembolso
CREATE OR ALTER PROCEDURE eCobros.EliminarReembolso
    @id_reembolso INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar que el reembolso existe
        IF NOT EXISTS (
            SELECT 1 
            FROM eCobros.Reembolso 
            WHERE id_reembolso = @id_reembolso
        )
        BEGIN
            PRINT 'Error: El reembolso no existe.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Obtener información del reembolso
        DECLARE @id_pago INT;
        SELECT @id_pago = id_pago
        FROM eCobros.Reembolso
        WHERE id_reembolso = @id_reembolso;

        -- Eliminar el reembolso
        DELETE FROM eCobros.Reembolso 
        WHERE id_reembolso = @id_reembolso;

        -- Recalcular los reembolsos activos
        DECLARE @total_reembolsado DECIMAL(10,2) = 0;
        SELECT @total_reembolsado = ISNULL(SUM(monto), 0)
        FROM eCobros.Reembolso
        WHERE id_pago = @id_pago;

        -- Obtener el monto original del pago
        DECLARE @monto_pago DECIMAL(10,2);
        SELECT @monto_pago = monto 
        FROM eCobros.Pago 
        WHERE id_pago = @id_pago;

        -- Ajustar estado del pago
        IF @total_reembolsado = 0
        BEGIN
            UPDATE eCobros.Pago 
            SET estado = 'completado' 
            WHERE id_pago = @id_pago;
        END
        ELSE IF @total_reembolsado < @monto_pago
        BEGIN
            UPDATE eCobros.Pago 
            SET estado = 'completado' 
            WHERE id_pago = @id_pago;
        END
        ELSE IF @total_reembolsado = @monto_pago
        BEGIN
            UPDATE eCobros.Pago 
            SET estado = 'reembolsado' 
            WHERE id_pago = @id_pago;
        END

        COMMIT TRANSACTION;
        PRINT 'Reembolso eliminado correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE eAdministrativos.CrearUsuario
	@rol VARCHAR(50),
	@nombre_usuario NVARCHAR(50),
	@clave NVARCHAR(50),
	@vigencia_dias INT = 90
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF EXISTS (
			SELECT 1
			FROM eAdministrativos.UsuarioAdministrativo
			WHERE nombre_usuario = @nombre_usuario
		)
			THROW 50001, 'El nombre de usuario ya existe.',1;

		-- Validación de formato de clave (además del CHECK_POLICY del login)
		IF LEN(@clave) < 8  OR @clave NOT LIKE '%[A-Z]%' OR @clave NOT LIKE '%[a-z]%' OR @clave NOT LIKE '%[0-9]%' OR @clave NOT LIKE '%[^a-zA-Z0-9]%'
			THROW 50003, 'La contraseña debe tener al menos 8 caracteres, incluyendo mayúsculas, minúsculas, números y símbolos.', 1;

		IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @rol AND type = 'R')
			THROW 50004, 'El rol especificado no existe.', 1;

		
		-- Inserción en tabla lógica
		INSERT INTO eAdministrativos.UsuarioAdministrativo (
			rol, nombre_usuario, clave, fecha_vigencia_clave, ultimo_cambio_clave
		)
		VALUES (
			@rol, @nombre_usuario, @clave, DATEADD(DAY, @vigencia_dias, GETDATE()), GETDATE()
		);

		-- Crear LOGIN
		DECLARE @sql_login NVARCHAR(MAX) = '
			IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = ''' + @nombre_usuario + ''')
			BEGIN
				CREATE LOGIN [' + @nombre_usuario + '] 
				WITH PASSWORD = ''' + @clave + ''', 
				CHECK_POLICY = ON;
			END';
		EXEC (@sql_login);

		-- Crear USER
        DECLARE @sql_user NVARCHAR(MAX) = '
        IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''' + @nombre_usuario + ''')
        BEGIN
            CREATE USER [' + @nombre_usuario + '] FOR LOGIN [' + @nombre_usuario + '];
        END';
        EXEC (@sql_user);

		-- Asignar al rol
        DECLARE @sql_role NVARCHAR(MAX) = '
        ALTER ROLE [' + @rol + '] ADD MEMBER [' + @nombre_usuario + ']';
        EXEC (@sql_role);

		PRINT 'Usuario creado con éxito.';
	END TRY
	BEGIN CATCH
		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END;
GO



CREATE OR ALTER PROCEDURE eAdministrativos.ModificarUsuario
	@id_usuario INT,
	@rol VARCHAR(50),
	@nombre_usuario NVARCHAR(50),
	@clave NVARCHAR (50),
	@vigencia_dias INT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		--Validacion existencia
		IF NOT EXISTS (SELECT 1 FROM eAdministrativos.UsuarioAdministrativo WHERE id_usuario = @id_usuario)
			THROW 50001, 'No existe usuario con ese ID.', 1;

		--Validar que el nuevo nombre no esté en uso
		IF EXISTS (SELECT 1 FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = @nombre_usuario AND id_usuario <> @id_usuario)
			THROW 50002, 'El nombre de usuario ya está en uso.', 1;

		-- Validación de formato de clave 
		IF LEN(@clave) < 8 
			OR @clave NOT LIKE '%[A-Z]%' 
			OR @clave NOT LIKE '%[a-z]%' 
			OR @clave NOT LIKE '%[0-9]%' 
			OR @clave NOT LIKE '%[^a-zA-Z0-9]%' 
				THROW 50003, 'La contraseña debe tener al menos 8 caracteres, incluyendo mayúsculas, minúsculas, números y símbolos.', 1;


		IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @rol AND type = 'R')
			THROW 50004, 'El rol especificado no existe.', 1;

		--Obtener el nombre anterior
		DECLARE @nombre_anterior NVARCHAR(50);
		SELECT @nombre_anterior = nombre_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE id_usuario = @id_usuario;
	
		--Actualizacion
		UPDATE eAdministrativos.UsuarioAdministrativo
			SET 
				rol = @rol,
				nombre_usuario = @nombre_usuario,
				clave = @clave,
				fecha_vigencia_clave = DATEADD(DAY,@vigencia_dias,GETDATE()),
				ultimo_cambio_clave = GETDATE()
			WHERE id_usuario = @id_usuario;


		--Si el nombre cambió, renombra login y usuario
		IF @nombre_anterior <> @nombre_usuario
			BEGIN
				DECLARE @sql_rename_login NVARCHAR(MAX) = 'ALTER LOGIN [' + @nombre_anterior + '] WITH NAME = [' + @nombre_usuario + ']';
				EXEC (@sql_rename_login);

				--Cambbiar nombre del USER
				DECLARE @sql_rename_user NVARCHAR(MAX) = 'ALTER USER [' + @nombre_anterior + '] WITH NAME = [' + @nombre_usuario + ']';
				EXEC (@sql_rename_user);
		END

		-- Actualizar contraseña del login
		DECLARE @sql_password NVARCHAR(MAX) = '
			ALTER LOGIN [' + @nombre_usuario + '] WITH PASSWORD = ''' + @clave + '''';
		EXEC (@sql_password);

		-- Reasignar al rol
		DECLARE @sql_role NVARCHAR(MAX) = '
			ALTER ROLE [' + @rol + '] ADD MEMBER [' + @nombre_usuario + ']';
		EXEC (@sql_role);

		PRINT 'Usuario modificado con éxito.';
	END TRY
	BEGIN CATCH
		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END; 
GO


CREATE OR ALTER PROCEDURE eAdministrativos.EliminarUsuario
	@id_usuario INT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
	--Validar existencia usuario
		IF NOT EXISTS (SELECT 1 FROM eAdministrativos.UsuarioAdministrativo WHERE id_usuario = @id_usuario)
			THROW 50001, 'El usuario no existe.', 1;

	--Obtener nombre de usuario
	DECLARE @nombre_usuario NVARCHAR(50);
	SELECT @nombre_usuario = nombre_usuario FROM eAdministrativos.UsuarioAdministrativo WHERE id_usuario = @id_usuario;
	
	--Eliminar usuario 
	DELETE FROM eAdministrativos.UsuarioAdministrativo
	WHERE id_usuario = @id_usuario

	-- Eliminar USER de base de datos
		DECLARE @sql_drop_user NVARCHAR(MAX) = '
			IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''' + @nombre_usuario + ''')
			DROP USER [' + @nombre_usuario + ']';
		EXEC (@sql_drop_user);

		-- Eliminar LOGIN del servidor
		DECLARE @sql_drop_login NVARCHAR(MAX) = '
			IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = ''' + @nombre_usuario + ''')
			DROP LOGIN [' + @nombre_usuario + ']';
		EXEC (@sql_drop_login);

		PRINT 'Usuario eliminado con éxito.';
	END TRY
	BEGIN CATCH
		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END; 
GO

