USE Com5600G10
GO

CREATE OR ALTER PROCEDURE eSocios.insertarSocio
    @id_socio VARCHAR(20),
    @dni INT,
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @email NVARCHAR(100),
    @fecha_nac DATE,
    @telefono BIGINT = NULL,
    @telefono_emergencia BIGINT = NULL,
    @obra_social VARCHAR(50) = NULL,
    @nro_obra_social VARCHAR(15) = NULL,
    @tel_obra_social VARCHAR(30) = NULL,
    @activo BIT = 1,
    @id_tutor VARCHAR(20) = NULL,
    @parentesco VARCHAR(20) = NULL,
    @descuento DECIMAL(10,2) = 0
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @edad INT, @categoria_nombre VARCHAR(50), @id_categoria INT;

        -- Calcular edad
        SET @edad = DATEDIFF(YEAR, @fecha_nac, GETDATE()) -
                    CASE 
                        WHEN DATEADD(YEAR, DATEDIFF(YEAR, @fecha_nac, GETDATE()), @fecha_nac) > GETDATE()
                        THEN 1 ELSE 0 
                    END;

        -- Determinar categoría según edad
        IF @edad < 12
            SET @categoria_nombre = 'Menor';
        ELSE IF @edad BETWEEN 12 AND 17
            SET @categoria_nombre = 'Cadete';
        ELSE
            SET @categoria_nombre = 'Mayor';

        -- Obtener ID de categoría
        SELECT TOP 1 @id_categoria = id_categoria
        FROM eSocios.Categoria
        WHERE nombre = @categoria_nombre
        ORDER BY vigencia DESC;

        IF @id_categoria IS NULL
        BEGIN
            RAISERROR('No se encontró la categoría correspondiente a la edad.', 16, 1);
            RETURN;
        END

        -- Validar duplicados
        IF EXISTS (
            SELECT 1 FROM eSocios.Socio 
			WHERE dni = @dni OR id_socio = @id_socio
        )
        BEGIN
            RAISERROR('Ya existe un socio con ese DNI o ID.', 16, 1);
            RETURN;
        END

        -- Insertar en Socio
        INSERT INTO eSocios.Socio (
            id_socio, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono,
            telefono_emergencia, obra_social, nro_obra_social, tel_obra_social, activo
        )
        VALUES (
            @id_socio, @id_categoria, @dni, @nombre, @apellido, @email, @fecha_nac, @telefono,
            @telefono_emergencia, @obra_social, @nro_obra_social, @tel_obra_social, @activo
        );

        -- Si es menor de 18 años requiere tutor
        IF @edad < 18
        BEGIN
            IF @id_tutor IS NULL
            BEGIN
                RAISERROR('Este socio es menor de edad y requiere un tutor.', 16, 1);
                RETURN;
            END

            -- Validar existencia del tutor
            IF NOT EXISTS (
				SELECT 1 FROM eSocios.Tutor 
				WHERE id_tutor = @id_tutor
			)
            BEGIN
                RAISERROR('El tutor especificado no existe.', 16, 1);
                RETURN;
            END

            -- Verificar que el socio no tenga ya tutor
            IF EXISTS (
                SELECT 1 FROM eSocios.GrupoFamiliar 
				WHERE id_socio = @id_socio
            )
            BEGIN
                RAISERROR('Este socio ya tiene un tutor asignado.', 16, 1);
                RETURN;
            END

            -- Insertar vínculo en GrupoFamiliar
            INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
            VALUES (@id_socio, @id_tutor, @descuento, @parentesco);
        END
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO


CREATE OR ALTER PROCEDURE eSocios.EliminarSocio
    @id_socio VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio
        )
        BEGIN
            RAISERROR('El socio no existe.', 16, 1);
            RETURN;
        END

        UPDATE eSocios.Socio
        SET activo = 0
        WHERE id_socio = @id_socio;
    END TRY
    BEGIN CATCH
        DECLARE @MensajeError NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@MensajeError, 16, 1);
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.ModificarSocio
    @id_socio VARCHAR(20),
    @id_categoria INT,
    @dni INT,
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @email NVARCHAR(100),
    @fecha_nac DATE,
    @telefono BIGINT = NULL,
    @telefono_emergencia BIGINT = NULL,
    @obra_social VARCHAR(50) = NULL,
    @nro_obra_social VARCHAR(15) = NULL,
    @tel_obra_social VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Verificar que exista el socio
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio
        )
        BEGIN
            RAISERROR('El socio no existe', 16, 1);
            RETURN;
        END

        -- Verificar que exista la categoría
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.Categoria 
			WHERE id_categoria = @id_categoria
        )
        BEGIN
            RAISERROR('La categoría especificada no existe', 16, 1);
            RETURN;
        END

        -- Verificar que no exista otro socio con ese DNI
        IF EXISTS (
            SELECT 1 FROM eSocios.Socio 
            WHERE dni = @dni AND id_socio <> @id_socio
        )
        BEGIN
            RAISERROR('Ya existe otro socio con ese DNI', 16, 1);
            RETURN;
        END

        -- Actualizar datos y reactivar si estaba inactivo
        UPDATE eSocios.Socio
        SET 
            id_categoria = @id_categoria,
            dni = @dni,
            nombre = @nombre,
            apellido = @apellido,
            email = @email,
            fecha_nac = @fecha_nac,
            telefono = @telefono,
            telefono_emergencia = @telefono_emergencia,
            obra_social = @obra_social,
            nro_obra_social = @nro_obra_social,
            tel_obra_social = @tel_obra_social,
            activo = 1 -- Reactivar en todos los casos
        WHERE id_socio = @id_socio;

    END TRY
    BEGIN CATCH
        DECLARE @MensajeError NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@MensajeError, 16, 1);
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.CrearActividad
    @nombre NVARCHAR(50),
    @costo_mensual DECIMAL(10,2),
    @vigencia DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO eSocios.Actividad (nombre, costo_mensual, vigencia)
        VALUES (@nombre, @costo_mensual, @vigencia);
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.ModificarActividad
    @id_actividad INT,
    @nombre NVARCHAR(50),
    @costo_mensual DECIMAL(10,2),
    @vigencia DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.Actividad 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            RAISERROR('La actividad no existe', 16, 1);
            RETURN;
        END

        UPDATE eSocios.Actividad
        SET nombre = @nombre,
            costo_mensual = @costo_mensual,
            vigencia = @vigencia
        WHERE id_actividad = @id_actividad;
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.EliminarActividad
    @id_actividad INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Verificar existencia de la actividad
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.Actividad 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            RAISERROR('La actividad no existe', 16, 1);
            RETURN;
        END

        -- Verificar si hay socios inscriptos
        IF EXISTS (
            SELECT 1 FROM eSocios.Realiza 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            RAISERROR('No se puede eliminar la actividad porque hay socios inscriptos', 16, 1);
            RETURN;
        END

        -- Verificar si hay presentismo cargado
        IF EXISTS (
            SELECT 1 FROM eSocios.Presentismo 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            RAISERROR('No se puede eliminar la actividad porque hay registros de presentismo', 16, 1);
            RETURN;
        END

        -- Verificar si tiene horarios asignados
        IF EXISTS (
            SELECT 1 FROM eSocios.ActividadDiaHorario 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            RAISERROR('No se puede eliminar la actividad porque tiene horarios asignados', 16, 1);
            RETURN;
        END

        -- Si pasó todos los chequeos, elimino la actividad
        DELETE FROM eSocios.Actividad
        WHERE id_actividad = @id_actividad;
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

--Verifica que exista un socio con el ID dado y luego de eso le asigna la actividad indicada por ID en la tabla Realiza
CREATE OR ALTER PROCEDURE eSocios.AsignarActividad
    @id_socio VARCHAR(20),
    @id_actividad INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar existencia de socio y actividad
        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio AND activo = 1
		)
        BEGIN
            RAISERROR('El socio no existe o está inactivo', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Actividad 
			WHERE id_actividad = @id_actividad
		)
        BEGIN
            RAISERROR('La actividad no existe', 16, 1);
            RETURN;
        END

        -- Verificar que no esté ya inscripto
        IF EXISTS (
            SELECT 1 FROM eSocios.Realiza
            WHERE socio = @id_socio AND id_actividad = @id_actividad
        )
        BEGIN
            RAISERROR('El socio ya está inscripto en esa actividad', 16, 1);
            RETURN;
        END

        INSERT INTO eSocios.Realiza (socio, id_actividad)
        VALUES (@id_socio, @id_actividad);
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.DesinscribirActividad
    @id_socio VARCHAR(20),
    @id_actividad INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.Realiza
            WHERE socio = @id_socio AND id_actividad = @id_actividad
        )
        BEGIN
            RAISERROR('El socio no está inscripto en esa actividad', 16, 1);
            RETURN;
        END

        DELETE FROM eSocios.Realiza
        WHERE socio = @id_socio AND id_actividad = @id_actividad;
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.AgregarHorarioActividad
    @id_actividad INT,
    @dia VARCHAR(20),
    @hora_inicio TIME,
    @hora_fin TIME
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar día
        IF @dia NOT IN ('lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo')
        BEGIN
            RAISERROR('El día ingresado no es válido', 16, 1);
            RETURN;
        END

        -- Validar existencia de la actividad
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.Actividad 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            RAISERROR('La actividad no existe', 16, 1);
            RETURN;
        END

        -- Validar duplicado
        IF EXISTS (
            SELECT 1 FROM eSocios.ActividadDiaHorario
            WHERE id_actividad = @id_actividad AND dia = @dia AND hora_inicio = @hora_inicio
        )
        BEGIN
            RAISERROR('Ese horario ya está asignado a la actividad', 16, 1);
            RETURN;
        END

        INSERT INTO eSocios.ActividadDiaHorario (id_actividad, dia, hora_inicio, hora_fin)
        VALUES (@id_actividad, @dia, @hora_inicio, @hora_fin);
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.ModificarHorarioActividad
    @id_actividad INT,
    @dia_original VARCHAR(20),
    @hora_inicio_original TIME,
    @nuevo_dia VARCHAR(20),
    @nuevo_hora_inicio TIME,
    @nuevo_hora_fin TIME
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar día nuevo
        IF @nuevo_dia NOT IN ('lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo')
        BEGIN
            RAISERROR('El día ingresado no es válido', 16, 1);
            RETURN;
        END

        -- Validar existencia del horario original
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.ActividadDiaHorario
            WHERE id_actividad = @id_actividad AND dia = @dia_original AND hora_inicio = @hora_inicio_original
        )
        BEGIN
            RAISERROR('El horario original no existe', 16, 1);
            RETURN;
        END

        -- Validar que el nuevo horario sea válido
        IF @nuevo_hora_inicio >= @nuevo_hora_fin
        BEGIN
            RAISERROR('La hora de inicio debe ser menor que la hora de fin', 16, 1);
            RETURN;
        END

        -- Actualizar
        UPDATE eSocios.ActividadDiaHorario
        SET dia = @nuevo_dia,
            hora_inicio = @nuevo_hora_inicio,
            hora_fin = @nuevo_hora_fin
        WHERE id_actividad = @id_actividad AND dia = @dia_original AND hora_inicio = @hora_inicio_original;
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.EliminarHorarioActividad
    @id_actividad INT,
    @dia VARCHAR(20),
    @hora_inicio TIME
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar día
        IF @dia NOT IN ('lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo')
        BEGIN
            RAISERROR('El día ingresado no es válido', 16, 1);
            RETURN;
        END

        -- Validar existencia
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.ActividadDiaHorario
            WHERE id_actividad = @id_actividad AND dia = @dia AND hora_inicio = @hora_inicio
        )
        BEGIN
            RAISERROR('El horario no existe para esa actividad', 16, 1);
            RETURN;
        END

        DELETE FROM eSocios.ActividadDiaHorario
        WHERE id_actividad = @id_actividad AND dia = @dia AND hora_inicio = @hora_inicio;
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

-- crea un nuevo grupo familiar asignando un adulto responsable
-- verifica que el adulto no tenga ya un grupo familiar asignado
CREATE OR ALTER PROCEDURE eSocios.CrearGrupoFamiliar
    @id_tutor VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Verificar que el tutor exista
        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Tutor 
			WHERE id_tutor = @id_tutor
		)
        BEGIN
            RAISERROR('El tutor no existe', 16, 1);
            RETURN;
        END

        -- Verificar que no tenga ya un grupo familiar asignado
        IF EXISTS (
            SELECT 1 FROM eSocios.GrupoFamiliar 
			WHERE id_tutor = @id_tutor
        )
        BEGIN
            RAISERROR('El tutor ya tiene un grupo familiar asignado', 16, 1);
            RETURN;
        END

        -- se crea el grupo pero sin miembros todavia (se van a agregar con otro SP)
        -- el grupo se conforma al agregar miembros

        PRINT 'Grupo familiar creado con éxito';
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

-- agrega un miembro a un grupo familiar existente
-- verifica que el miembro no pertenezca ya a otro grupo
CREATE OR ALTER PROCEDURE eSocios.AgregarMiembroAGrupoFamiliar
    @id_socio VARCHAR(20),
    @id_tutor VARCHAR(20),
    @descuento DECIMAL(10,2),
    @parentesco VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar existencia del socio
        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio
		)
        BEGIN
            RAISERROR('El socio no existe.', 16, 1);
            RETURN;
        END

        -- Verificar que el tutor ya tenga un grupo
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.GrupoFamiliar 
			WHERE id_tutor = @id_tutor
        )
        BEGIN
            RAISERROR('El tutor no tiene un grupo familiar creado', 16, 1);
            RETURN;
        END

        -- Verificar que el socio no este ya en otro grupo
        IF EXISTS (
            SELECT 1 FROM eSocios.GrupoFamiliar 
			WHERE id_socio = @id_socio
        )
        BEGIN
            RAISERROR('El socio ya pertenece a un grupo familiar', 16, 1);
            RETURN;
        END

        INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
        VALUES (@id_socio, @id_tutor, @descuento, @parentesco);
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

-- asigna tutor para socio menor
CREATE OR ALTER PROCEDURE eSocios.AsignarTutor
    @id_socio VARCHAR(20),
    @id_tutor VARCHAR(20),
    @descuento DECIMAL(10,2),
    @parentesco VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cat_socio VARCHAR(50);

    BEGIN TRY
        -- Validar existencia
        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio
		)
        BEGIN
            RAISERROR('El socio no existe', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Tutor 
			WHERE id_tutor = @id_tutor
		)
        BEGIN
            RAISERROR('El tutor no existe', 16, 1);
            RETURN;
        END

        -- Validar que el socio sea menor o cadete
        SELECT @cat_socio = c.nombre
        FROM eSocios.Socio s
        JOIN eSocios.Categoria c ON s.id_categoria = c.id_categoria
        WHERE s.id_socio = @id_socio;

        IF @cat_socio NOT IN ('Menor', 'Cadete')
        BEGIN
            RAISERROR('El socio no pertenece a una categoría que requiera tutor (debe ser Menor o Cadete)', 16, 1);
            RETURN;
        END

        -- Verificar que no tenga ya un tutor
        IF EXISTS (
            SELECT 1 FROM eSocios.GrupoFamiliar 
			WHERE id_socio = @id_socio
        )
        BEGIN
            RAISERROR('El socio ya tiene un tutor asignado', 16, 1);
            RETURN;
        END

        -- Asignar tutor
        INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
        VALUES (@id_socio, @id_tutor, @descuento, @parentesco);
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

-- asigna un tutor a un socio menor, tomando los datos de un socio existente
-- el socio tutor debe ser mayor de edad (categoria 'Mayor')
-- el socio al que se le asigna el tutor debe ser menor de edad (categoria 'Menor' o 'Cadete')
CREATE OR ALTER PROCEDURE eSocios.AsignarTutorDesdeSocio
    @id_socio_menor VARCHAR(20),
    @id_socio_tutor VARCHAR(20),
    @descuento DECIMAL(10,2),
    @parentesco VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cat_tutor VARCHAR(50), @cat_menor VARCHAR(50), @id_categoria INT;

    BEGIN TRY
        -- Verificar existencia de ambos socios
        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio_menor
		)
        BEGIN
            RAISERROR('El socio menor no existe', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio_tutor
		)
        BEGIN
            RAISERROR('El socio tutor no existe', 16, 1);
            RETURN;
        END

        -- Obtener categoría de cada socio
        SELECT @cat_menor = c.nombre
        FROM eSocios.Socio s
        JOIN eSocios.Categoria c ON s.id_categoria = c.id_categoria
        WHERE s.id_socio = @id_socio_menor;

        SELECT @cat_tutor = c.nombre
        FROM eSocios.Socio s
        JOIN eSocios.Categoria c ON s.id_categoria = c.id_categoria
        WHERE s.id_socio = @id_socio_tutor;

        IF @cat_tutor <> 'Mayor'
        BEGIN
            RAISERROR('El tutor debe ser un socio con categoría "Mayor"', 16, 1);
            RETURN;
        END

        IF @cat_menor NOT IN ('Menor', 'Cadete')
        BEGIN
            RAISERROR('El socio al que se le asigna tutor no es menor de edad', 16, 1);
            RETURN;
        END

        -- Validar que el menor no tenga ya tutor
        IF EXISTS (
            SELECT 1 FROM eSocios.GrupoFamiliar 
			WHERE id_socio = @id_socio_menor
        )
        BEGIN
            RAISERROR('El socio ya tiene un tutor asignado', 16, 1);
            RETURN;
        END

        -- Insertar tutor en tabla Tutor si no existe
        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Tutor 
			WHERE id_tutor = @id_socio_tutor
		)
        BEGIN
            INSERT INTO eSocios.Tutor (id_tutor, nombre, apellido, DNI, email, fecha_nac, telefono)
            SELECT id_socio, nombre, apellido, dni, email, fecha_nac, telefono)
            FROM eSocios.Socio
            WHERE id_socio = @id_socio_tutor;
        END

        -- Insertar vínculo
        INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
        VALUES (@id_socio_menor, @id_socio_tutor, @descuento, @parentesco);
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.ModificarTutor
    @id_tutor VARCHAR(20),
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @DNI INT,
    @email NVARCHAR(100),
    @fecha_nac DATE,
    @telefono BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Tutor 
			WHERE id_tutor = @id_tutor
		)
        BEGIN
            RAISERROR('El tutor no existe', 16, 1);
            RETURN;
        END

        UPDATE eSocios.Tutor
        SET nombre = @nombre,
            apellido = @apellido,
            DNI = @DNI,
            email = @email,
            fecha_nac = @fecha_nac,
            telefono = @telefono
        WHERE id_tutor = @id_tutor;
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.EliminarTutor
    @id_tutor VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Verificar existencia
        IF NOT EXISTS (
			SELECT 1 FROM eSocios.Tutor 
			WHERE id_tutor = @id_tutor
		)
        BEGIN
            RAISERROR('El tutor no existe', 16, 1);
            RETURN;
        END

        -- Verificar que no tenga socios asignados
        IF EXISTS (
            SELECT 1 FROM eSocios.GrupoFamiliar 
			WHERE id_tutor = @id_tutor
        )
        BEGIN
            RAISERROR('No se puede eliminar el tutor porque tiene socios asignados', 16, 1);
            RETURN;
        END

        DELETE FROM eSocios.Tutor WHERE id_tutor = @id_tutor;
    END TRY
    BEGIN CATCH
        RAISERROR(ERROR_MESSAGE(), 16, 1);
    END CATCH
END
GO
