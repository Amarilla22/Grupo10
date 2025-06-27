
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

use Com5600G10
go



CREATE PROCEDURE eSocios.insertarSocio
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


CREATE PROCEDURE eSocios.EliminarSocio
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


CREATE PROCEDURE eSocios.ModificarSocio
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

CREATE PROCEDURE eSocios.AsignarActividad
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
CREATE PROCEDURE eSocios.DesinscribirActividad
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
CREATE PROCEDURE eSocios.CrearGrupoFamiliar
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
CREATE PROCEDURE eSocios.AgregarMiembroAGrupoFamiliar
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
CREATE PROCEDURE eSocios.AsignarTutor
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
CREATE PROCEDURE eSocios.AsignarTutorDesdeSocio
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


CREATE PROCEDURE eSocios.ModificarTutor
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


CREATE PROCEDURE eSocios.EliminarTutor
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


-- SP para generar factura con los descuentos correspondientes
CREATE PROCEDURE eCobros.generarFactura
    @id_socio INT,
    @periodo VARCHAR(20), -- formato: 'MM/YYYY'
    @fecha_emision DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- establecer fecha por defecto si no se proporciona
        IF @fecha_emision IS NULL 
            SET @fecha_emision = GETDATE();
        
        -- calcular fechas de vencimiento
        DECLARE @fecha_venc_1 DATE = DATEADD(DAY, 5, @fecha_emision);
        DECLARE @fecha_venc_2 DATE = DATEADD(DAY, 5, @fecha_venc_1);
        
        -- crear la factura
        DECLARE @id_factura INT;
        INSERT INTO eCobros.Factura (
            id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, 
            estado, total, recargo_venc, descuentos
        )
        VALUES (
            @id_socio, @fecha_emision, @fecha_venc_1, @fecha_venc_2, 
            'pendiente', 0, 0, 0
        );
        
        SET @id_factura = SCOPE_IDENTITY();
        
        -- variables de calculo
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
        
        -- obtener costo de la membresia
        SELECT @costo_membresia = costo_mensual 
        FROM eSocios.Categoria 
        WHERE id_categoria = @id_categoria;
        
        -- insertar item de membresia
        INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto, periodo)
        VALUES (@id_factura, 'membresia', @costo_membresia, @periodo);
        
        SET @total_membresias = @costo_membresia;
        
        -- insertar items por actividades asignadas
        INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto, periodo)
        SELECT 
            @id_factura, 
            'actividad', 
            a.costo_mensual, 
            @periodo
        FROM eSocios.Realiza sa
        JOIN eSocios.Actividad a ON sa.id_actividad = a.id_actividad
        WHERE sa.socio = @id_socio;
        
        -- calcular total de actividades
        SELECT @total_actividades = ISNULL(SUM(monto), 0)
        FROM eCobros.ItemFactura
        WHERE id_factura = @id_factura AND concepto = 'actividad';
        
        -- aplicar descuento familiar (15%)
        IF @id_grupo_familiar IS NOT NULL
            SET @porcentaje_descuento_familiar = 15;
        
        -- aplicar descuento por multiples actividades (10%)
        DECLARE @cant_actividades INT;
        SELECT @cant_actividades = COUNT(*)
        FROM eCobros.ItemFactura
        WHERE id_factura = @id_factura AND concepto = 'actividad';
        
        IF @cant_actividades > 1
            SET @porcentaje_descuento_actividades = 10;
        
        -- calcular total con descuentos
        DECLARE @total_con_descuentos DECIMAL(10,2) = 0;
        SET @total_con_descuentos = 
            @total_membresias * (1 - @porcentaje_descuento_familiar / 100) +
            @total_actividades * (1 - @porcentaje_descuento_actividades / 100);
        
        -- agregar otros conceptos (ej: pileta)
        SET @total_con_descuentos = @total_con_descuentos + 
            ISNULL((
                SELECT SUM(monto)
                FROM eCobros.ItemFactura
                WHERE id_factura = @id_factura 
                AND concepto NOT IN ('membresia', 'actividad')
            ), 0);
        
        -- actualizar la factura con los totales
        UPDATE eCobros.Factura
        SET 
            total = @total_con_descuentos,
            descuentos = @porcentaje_descuento_familiar + @porcentaje_descuento_actividades,
            recargo_venc = 0
        WHERE id_factura = @id_factura;
        
        COMMIT TRANSACTION;
        
        RETURN @id_factura;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END; --galo
GO


-- procedimiento para aplicar recargo por segundo vencimiento
CREATE PROCEDURE eCobros.aplicarRecargoSegundoVencimiento
    @id_factura INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- verifica si la factura esta en segundo vencimiento
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
        
        -- verifica si ya se aplico recargo
        IF EXISTS 
		(
            SELECT 1 FROM eCobros.ItemFactura 
            WHERE id_factura = @id_factura 
            AND concepto = 'recargo por segundo vencimiento'
        )
        BEGIN
            SET @recargo_aplicado = 1;
        END
        
        -- verifica condiciones para aplicar recargo
        IF @estado = 'pendiente' AND 
           GETDATE() > @fecha_venc_1 AND 
           GETDATE() <= @fecha_venc_2 AND 
           @recargo_aplicado = 0
        BEGIN
            -- calcula monto del recargo (10% del total actual)
            DECLARE @monto_recargo DECIMAL(10,2) = @total_actual * (@porcentaje_recargo / 100.0);
            
            -- actualiza factura con nuevo total y establecer recargo_venc a 10
            UPDATE eCobros.Factura
            SET 
                total = @total_actual + @monto_recargo,
                recargo_venc = @porcentaje_recargo -- ahora si establecemos el 10%
            WHERE id_factura = @id_factura;
            
            -- registra item de recargo
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


--borrado logico para factura
CREATE PROCEDURE eCobros.anularFactura
    @id_factura INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- verificar que la factura exista y no este anulada
        IF NOT EXISTS (
            SELECT 1 
            FROM eCobros.Factura 
            WHERE id_factura = @id_factura AND estado <> 'anulada'
        )
        BEGIN
            RAISERROR('la factura no existe o ya esta anulada', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- actualizar estado a anulada
        UPDATE eCobros.Factura
        SET estado = 'anulada'
        WHERE id_factura = @id_factura;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END; --galo
GO



CREATE PROCEDURE eCobros.RegistrarEntradaPileta
    @id_socio INT,
    @fecha DATE = NULL,
    @tipo VARCHAR(8), -- 'socio' o 'invitado'
    @lluvia BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Valida que el socio existe
        IF NOT EXISTS (SELECT 1 FROM eSocios.Socio WHERE id_socio = @id_socio)
            THROW 50001, 'El socio especificado no existe', 1;
            
        -- valida tipo de entrada
        IF @tipo NOT IN ('socio', 'invitado')
            THROW 50002, 'Tipo de entrada no válido. Debe ser "socio" o "invitado"', 1;
            
        -- establece fecha por defecto (hoy)
        IF @fecha IS NULL
            SET @fecha = CONVERT(DATE, GETDATE());
            
        -- determina monto según tipo y tarifas
        DECLARE @monto DECIMAL(10,2);
        
        IF @tipo = 'socio'
            SET @monto =  500.00 -- valor por defecto para socios
        ELSE
            SET @monto =  800.00 -- valor por defecto para invitados
            
        -- verifica morosidad 
        IF  EXISTS (
            SELECT 1 
            FROM eCobros.Factura 
            WHERE id_socio = @id_socio 
              AND estado = 'pendiente'
              AND fecha_venc_2 < @fecha
        )
            THROW 50003, 'El socio tiene cuotas impagas y no puede acceder a la pileta', 1;
            
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
            INSERT INTO eCobros.Factura (
                id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, estado, total
            )
            VALUES (
                @id_socio, @fecha, DATEADD(DAY, 5, @fecha), DATEADD(DAY, 10, @fecha), 'pendiente', 0
            );
            
            SET @id_factura = SCOPE_IDENTITY();
        END
        
        -- crea ítem en factura para la entrada
        INSERT INTO eCobros.ItemFactura (
            id_factura, concepto, monto, periodo
        )
        VALUES (
            @id_factura, 'pileta', @monto, FORMAT(@fecha, 'yyyyMM')
        );
        
        SET @id_item = SCOPE_IDENTITY();
        
        -- actualiza total de la factura
        UPDATE eCobros.Factura
        SET total = total + @monto
        WHERE id_factura = @id_factura;
        
        -- registra la entrada a la pileta
        INSERT INTO eCobros.EntradaPileta (
            id_socio, id_item_factura, fecha, monto, tipo, lluvia
        )
        VALUES (
            @id_socio, @id_item, @fecha, @monto, @tipo, @lluvia
        );
        
        -- aplica reembolso automático si hay lluvia
        IF @lluvia = 1
        BEGIN
            DECLARE @reembolso DECIMAL(10,2) = @monto * 0.6; -- 60% de reembolso
            
            -- crea factura de reembolso
            DECLARE @id_factura_reembolso INT;
            
            INSERT INTO eCobros.Factura (
                id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, estado, total
            )
            VALUES (
                @id_socio, @fecha, @fecha, @fecha, 'pagada', -@reembolso
            );
            
            SET @id_factura_reembolso = SCOPE_IDENTITY();
            
            -- crea ítem en factura para el reembolso
            INSERT INTO eCobros.ItemFactura (
                id_factura, concepto, monto, periodo
            )
            VALUES (
                @id_factura_reembolso, 'pileta', -@reembolso, FORMAT(@fecha, 'yyyyMM')
            );
            
            -- registra pago del reembolso (como saldo a favor)
            INSERT INTO eCobros.Pago (
                id_pago, id_factura, medio_pago, monto, fecha, estado, debito_auto
            )
            VALUES (
                NEXT VALUE FOR seq_pagos, @id_factura_reembolso, 'reembolso', @reembolso, @fecha, 'completado', 0
            );
        END
        
        COMMIT TRANSACTION;
        
        SELECT 
            SCOPE_IDENTITY() AS id_entrada,
            @monto AS monto_cobrado,
            CASE WHEN @lluvia = 1 THEN @monto * 0.6 ELSE 0 END AS monto_reembolsado,
            'Entrada registrada correctamente' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW;
    END CATCH
END; --galo
GO



CREATE PROCEDURE eCobros.AnularEntradaPileta
    @id_entrada INT,
    @aplicar_reembolso BIT = 0 -- indica si se debe aplicar reembolso
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @id_item_factura INT;
        DECLARE @monto DECIMAL(10,2);
        DECLARE @id_factura INT;
        DECLARE @fecha DATE;
        DECLARE @tipo VARCHAR(8);
        DECLARE @id_socio INT;
        DECLARE @lluvia BIT;
        DECLARE @estado_factura VARCHAR(20);
        
        SELECT 
            @id_item_factura = ep.id_item_factura,
            @monto = ep.monto,
            @id_factura = it.id_factura,
            @fecha = ep.fecha,
            @tipo = ep.tipo,
            @id_socio = ep.id_socio,
            @lluvia = ep.lluvia,
            @estado_factura = f.estado
        FROM eCobros.EntradaPileta ep
        JOIN eCobros.ItemFactura it ON ep.id_item_factura = it.id_item
        JOIN eCobros.Factura f ON it.id_factura = f.id_factura
        WHERE ep.id_entrada = @id_entrada;
        
        -- valida que la entrada existe
        IF @id_item_factura IS NULL
            THROW 50001, 'La entrada especificada no existe', 1;
            
        -- valida que no sea una entrada ya reembolsada por lluvia
        IF @lluvia = 1
            THROW 50002, 'No se puede anular una entrada con reembolso por lluvia procesado', 1;
            
        -- valida que la factura no esté pagada
        IF @estado_factura = 'pagada' AND @aplicar_reembolso = 0
            THROW 50003, 'La factura asociada ya está pagada. Use @aplicar_reembolso=1 para generar reembolso', 1;
        
        -- elimina el registro de entrada
        DELETE FROM eCobros.EntradaPileta
        WHERE id_entrada = @id_entrada;
        
        -- elimina el ítem de factura
        DELETE FROM eCobros.ItemFactura
        WHERE id_item = @id_item_factura;
        
        -- actualiza total de la factura
        UPDATE eCobros.Factura
        SET total = total - @monto
        WHERE id_factura = @id_factura;
        
        -- si la factura queda sin ítems, se anula
        IF NOT EXISTS (
            SELECT 1 
            FROM eCobros.ItemFactura 
            WHERE id_factura = @id_factura
        )
            DELETE FROM eCobros.Factura
            WHERE id_factura = @id_factura;
            
        -- aplica el reembolso si corresponde
        IF @aplicar_reembolso = 1 AND @estado_factura = 'pagada'
        BEGIN
            DECLARE @reembolso DECIMAL(10,2) = @monto;
            
            -- crea factura de reembolso
            DECLARE @id_factura_reembolso INT;
            
            INSERT INTO eCobros.Factura (
                id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, estado, total
            )
            VALUES (
                @id_socio, GETDATE(), GETDATE(), GETDATE(), 'pagada', -@reembolso
            );
            
            SET @id_factura_reembolso = SCOPE_IDENTITY();
            
            -- crea ítem en factura para el reembolso
            INSERT INTO eCobros.ItemFactura (
                id_factura, concepto, monto, periodo
            )
            VALUES (
                @id_factura_reembolso, 'pileta', -@reembolso, FORMAT(@fecha, 'yyyyMM')
            );
            
            -- registra el pago del reembolso (como saldo a favor)
            INSERT INTO eCobros.Pago (
                id_pago, id_factura, medio_pago, monto, fecha, estado, debito_auto
            )
            VALUES (
                NEXT VALUE FOR seq_pagos, @id_factura_reembolso, 'reembolso', @reembolso, GETDATE(), 'completado', 0
            );
        END
        
        COMMIT TRANSACTION;
        
        SELECT 
            1 AS resultado,
            'Entrada anulada correctamente' AS mensaje,
            @monto AS monto_anulado,
            CASE WHEN @aplicar_reembolso = 1 AND @estado_factura = 'pagada' THEN @monto ELSE 0 END AS monto_reembolsado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();     
        THROW;
    END CATCH
END; --galo
GO


CREATE PROCEDURE eCobros.CargarPago
    @id_pago INT,
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
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Si no se proporciona fecha, usar la fecha actual
        IF @fecha IS NULL
            SET @fecha_pago = GETDATE();
        ELSE
            SET @fecha_pago = @fecha;
        
        -- Validar que la factura existe y obtener su estado y total
        SELECT @estado_factura = estado, 
               @total_factura = total
        FROM eCobros.Factura 
        WHERE id_factura = @id_factura;
        
        -- Si no se encontró la factura, @estado_factura será NULL
        IF @estado_factura IS NULL
        BEGIN
            THROW 50001, 'La factura especificada no existe.', 1;
            RETURN;
        END
        
        -- Validar que la factura no esté anulada
        IF @estado_factura = 'anulada'
        BEGIN
            THROW 50001, 'No se puede registrar un pago para una factura anulada.', 1;
            RETURN;
        END
        
        -- Validar que la factura no esté ya completamente pagada
        IF @estado_factura = 'pagada'
        BEGIN
            THROW 50001, 'La factura ya se encuentra completamente pagada.', 1;
            RETURN;
        END
        
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
        
        -- Validar que el id_pago no exista (si se proporciona)
        IF EXISTS (SELECT 1 FROM eCobros.Pago WHERE id_pago = @id_pago)
        BEGIN
            THROW 50001, 'Ya existe un pago con el ID especificado.', 1;
            RETURN;
        END
        
        -- Insertar el pago
        INSERT INTO eCobros.Pago (
            id_pago, 
            id_factura, 
            medio_pago, 
            monto, 
            fecha, 
            estado, 
            debito_auto
        )
        VALUES (
            @id_pago,
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
go


CREATE PROCEDURE eCobros.AnularPago --Actualiza factura
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


CREATE PROCEDURE eCobros.BorradoLogicoReembolso
    @id_reembolso INT,
    @motivo_baja VARCHAR(100) = 'ELIMINADO LOGICAMENTE'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar que el reembolso existe y no está marcado como eliminado
        IF NOT EXISTS (
            SELECT 1 
            FROM eCobros.Reembolso 
            WHERE id_reembolso = @id_reembolso 
            AND motivo NOT LIKE 'ELIMINADO:%'
        )
        BEGIN
            THROW 50010, 'El reembolso no existe o ya está eliminado lógicamente', 1;
        END
        
        -- Obtener información del reembolso
        DECLARE @id_pago INT;
        DECLARE @monto_reembolso DECIMAL(10,2);
        DECLARE @motivo_original VARCHAR(100);
        
        SELECT @id_pago = id_pago, @monto_reembolso = monto, @motivo_original = motivo
        FROM eCobros.Reembolso 
        WHERE id_reembolso = @id_reembolso;
        
        -- Marcar como eliminado modificando el motivo
        UPDATE eCobros.Reembolso 
        SET motivo = 'ELIMINADO: ' + @motivo_original
        WHERE id_reembolso = @id_reembolso;
        
        -- Recalcular el total de reembolsos activos para el pago (excluyendo eliminados)
        DECLARE @total_reembolsos_activos DECIMAL(10,2) = 0;
        SELECT @total_reembolsos_activos = ISNULL(SUM(monto), 0)
        FROM eCobros.Reembolso 
        WHERE id_pago = @id_pago AND motivo NOT LIKE 'ELIMINADO:%';
        
        -- Obtener el monto del pago original
        DECLARE @monto_pago DECIMAL(10,2);
        SELECT @monto_pago = monto 
        FROM eCobros.Pago 
        WHERE id_pago = @id_pago;
        
        -- Actualizar el estado del pago según los reembolsos activos
        IF @total_reembolsos_activos = 0
        BEGIN
            -- No hay reembolsos activos, volver a estado completado
            UPDATE eCobros.Pago 
            SET estado = 'completado' 
            WHERE id_pago = @id_pago;
        END
        ELSE IF @total_reembolsos_activos < @monto_pago
        BEGIN
            -- Reembolso parcial, mantener como completado
            UPDATE eCobros.Pago 
            SET estado = 'completado' 
            WHERE id_pago = @id_pago;
        END
        ELSE IF @total_reembolsos_activos = @monto_pago
        BEGIN
            -- Reembolso total, mantener como reembolsado
            UPDATE eCobros.Pago 
            SET estado = 'reembolsado' 
            WHERE id_pago = @id_pago;
        END
        
        COMMIT TRANSACTION;
        
        PRINT 'Reembolso eliminado lógicamente de forma correcta';
        SELECT 
            'SUCCESS' AS Result, 
            @id_reembolso AS ReembolsoId,
            @monto_reembolso AS MontoReembolso,
            @total_reembolsos_activos AS TotalReembolsosActivos,
            @monto_pago AS MontoPago;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Capturar y relanzar el error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END; ----R
GO



CREATE PROCEDURE eAdministrativos.CrearUsuario
	@rol VARCHAR(50),
	@nombre_usuario NVARCHAR(50),
	@clave NVARCHAR(50),
	@vigencia_dias INT = 90 --cada 3 meses caduca contraseña
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		--Verifico si existe un usuario con el mismo nombre
		IF EXISTS (
			SELECT 1
			FROM eAdministrativos.UsuarioAdministrativo
			WHERE nombre_usuario = @nombre_usuario
		)
			THROW 50001, 'El nombre de usuario ya existe.',1;

			--Insercion nuevo usuario
			INSERT INTO eAdministrativos.UsuarioAdministrativo (
				rol, nombre_usuario, clave, fecha_vigencia_clave, ultimo_cambio_clave
			)
			VALUES (
				@rol, @nombre_usuario, @clave, DATEADD(DAY, @vigencia_dias, GETDATE()), GETDATE()
			); --dateadd le suma @vigencia_dias a la fecha de hoy, dando como result la fecha vigencia (cuando caduca) 

			PRINT 'Usuario creado con éxito.';
	END TRY
	BEGIN CATCH
		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END;--------T
GO


CREATE PROCEDURE eAdministrativos.ModificarUsuario
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

	--Actualizacion
	UPDATE eAdministrativos.UsuarioAdministrativo
		SET 
			rol = @rol,
			nombre_usuario = @nombre_usuario,
			clave = @clave,
			fecha_vigencia_clave = DATEADD(DAY,@vigencia_dias,GETDATE()),
			ultimo_cambio_clave = GETDATE()
		WHERE id_usuario = @id_usuario;

		PRINT 'Usuario modificado con éxito.';
	END TRY
	BEGIN CATCH
		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END; --------T
GO


CREATE PROCEDURE eAdministrativos.EliminarUsuario
	@id_usuario INT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
	--Validar existencia usuario
		IF NOT EXISTS (SELECT 1 FROM eAdministrativos.UsuarioAdministrativo WHERE id_usuario = @id_usuario)
			THROW 50001, 'El usuario no existe.', 1;


	--Eliminar
	DELETE FROM eAdministrativos.UsuarioAdministrativo
	WHERE id_usuario = @id_usuario

	PRINT 'Usuario eliminado con éxito.';
	END TRY
	BEGIN CATCH
		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END; --------T
GO

