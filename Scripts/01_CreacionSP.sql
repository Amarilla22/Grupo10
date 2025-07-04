
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


-- se inserta un socio, si es menor de edad es requerido un tutor
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
    @parentesco VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- valida duplicados
        IF EXISTS 
        (
            SELECT 1 FROM eSocios.Socio 
            WHERE dni = @dni OR id_socio = @id_socio
        )
        BEGIN
            PRINT 'Error: Ya existe un socio con ese DNI o ID.';
            RETURN;
        END

        DECLARE @edad INT, @categoria_nombre VARCHAR(50), @id_categoria INT;

        -- calcula edad
        SET @edad = DATEDIFF(YEAR, @fecha_nac, GETDATE()) -
                    CASE 
                        WHEN DATEADD(YEAR, DATEDIFF(YEAR, @fecha_nac, GETDATE()), @fecha_nac) > GETDATE()
                        THEN 1 ELSE 0 
                    END;

        -- determina categoría según edad
        IF @edad < 12
            SET @categoria_nombre = 'Menor';
        ELSE IF @edad BETWEEN 12 AND 17
            SET @categoria_nombre = 'Cadete';
        ELSE
            SET @categoria_nombre = 'Mayor';

        -- obtiene ID de categoría
        SELECT TOP 1 @id_categoria = id_categoria
        FROM eSocios.Categoria
        WHERE nombre = @categoria_nombre
        ORDER BY vigencia DESC;

        IF @id_categoria IS NULL
        BEGIN
            PRINT 'Error: No se encontró la categoría correspondiente a la edad.';
            RETURN;
        END

        -- si es menor de edad requiere un tutor
        IF @edad < 18
        BEGIN
            IF @id_tutor IS NULL
            BEGIN
                PRINT 'Error: Este socio es menor de edad y requiere un tutor.';
                RETURN;
            END

			-- valida que el tutor exista
			IF NOT EXISTS 
			(
				SELECT 1 FROM eSocios.Tutor WHERE id_tutor = @id_tutor
			)
			BEGIN
				PRINT 'Error: El tutor especificado no existe.';
				RETURN;
			END
		END

        -- inserta en socio
        INSERT INTO eSocios.Socio 
        (
            id_socio, id_categoria, dni, nombre, apellido, email, fecha_nac, telefono,
            telefono_emergencia, obra_social, nro_obra_social, tel_obra_social, activo
        )
        VALUES 
        (
            @id_socio, @id_categoria, @dni, @nombre, @apellido, @email, @fecha_nac, @telefono,
            @telefono_emergencia, @obra_social, @nro_obra_social, @tel_obra_social, @activo
        );

        PRINT 'Socio insertado correctamente.';

		IF @id_tutor IS NOT NULL
		BEGIN
			DECLARE @socio_existente VARCHAR(20);
			DECLARE @descuento_existente DECIMAL(10,2);

			-- verifica si el tutor ya tiene otro socio relacionado
			SELECT TOP 1 
				@socio_existente = id_socio, 
				@descuento_existente = descuento
			FROM eSocios.GrupoFamiliar
			WHERE id_tutor = @id_tutor;

			IF @socio_existente IS NOT NULL
			BEGIN
				IF @descuento_existente > 0
				BEGIN
					-- el tutor ya tiene grupo con descuento, se asigna al nuevo socio también
					INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
					VALUES (@id_socio, @id_tutor, @descuento_existente, @parentesco);
				END
				ELSE
				BEGIN
					-- si el grupo no tiene descuento, se aplica a ambos
					INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
					VALUES (@id_socio, @id_tutor, 15, @parentesco);

					UPDATE eSocios.GrupoFamiliar
					SET descuento = 15
					WHERE id_socio = @socio_existente AND id_tutor = @id_tutor;
				END
			END
			ELSE
			BEGIN
				-- primer socio del tutor, sin descuento
				INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
				VALUES (@id_socio, @id_tutor, 0, @parentesco);
			END
		END
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- modifica los dato de un socio
CREATE OR ALTER PROCEDURE eSocios.modificarSocio
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
        -- verifica que exista el socio
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio
        )
        BEGIN
            PRINT 'El socio no existe';
            RETURN;
        END

        -- verifica que exista la categoria
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Categoria 
			WHERE id_categoria = @id_categoria
        )
        BEGIN
            PRINT 'La categoría especificada no existe';
            RETURN;
        END

        -- verifica que no exista otro socio con ese DNI
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.Socio 
            WHERE dni = @dni AND id_socio <> @id_socio
        )
        BEGIN
            PRINT 'Ya existe otro socio con ese DNI';
            RETURN;
        END

        -- actualiza datos y reactiva si estaba inactivo
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
            activo = 1 -- reactiva en todos los casos
        WHERE id_socio = @id_socio;
        PRINT 'Socio modificado correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- da de baja un socio
CREATE OR ALTER PROCEDURE eSocios.eliminarSocio
    @id_socio VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio
        )
        BEGIN
            PRINT 'El socio no existe.';
            RETURN;
        END

        UPDATE eSocios.Socio
        SET activo = 0
        WHERE id_socio = @id_socio;

        PRINT CONCAT('Dado de baja Socio ', @id_socio);
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO



--agrega los datos de un tutor
CREATE OR ALTER PROCEDURE eSocios.agregarTutor
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
        -- valida duplicados por ID o DNI o Email
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.Tutor 
            WHERE id_tutor = @id_tutor OR DNI = @DNI OR email = @email
        )
        BEGIN
            PRINT 'Error: Ya existe un tutor con ese ID, DNI o email.';
            RETURN;
        END

        -- insertar el tutor
        INSERT INTO eSocios.Tutor 
		(
            id_tutor, nombre, apellido, DNI, email, fecha_nac, telefono
        ) 
		VALUES 
		(
            @id_tutor, @nombre, @apellido, @DNI, @email, @fecha_nac, @telefono
        );

        PRINT 'Tutor agregado correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

--modifica los datos de un tutor
CREATE OR ALTER PROCEDURE eSocios.modificarTutor
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
        -- verifica existencia del tutor
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Tutor WHERE id_tutor = @id_tutor
        )
        BEGIN
            PRINT 'Error: El tutor especificado no existe.';
            RETURN;
        END

        -- valida que DNI o email no estén en uso por otro tutor
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.Tutor 
            WHERE (DNI = @DNI OR email = @email) AND id_tutor <> @id_tutor
        )
        BEGIN
            PRINT 'Error: El DNI o el email ya están en uso por otro tutor.';
            RETURN;
        END

        -- actualiza datos
        UPDATE eSocios.Tutor
        SET nombre = @nombre,
            apellido = @apellido,
            DNI = @DNI,
            email = @email,
            fecha_nac = @fecha_nac,
            telefono = @telefono
        WHERE id_tutor = @id_tutor;

        PRINT 'Tutor modificado correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

--elimina los datos de un tutor
CREATE OR ALTER PROCEDURE eSocios.eliminarTutor
    @id_tutor VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- verifica que el tutor existe
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Tutor WHERE id_tutor = @id_tutor
        )
        BEGIN
            PRINT 'Error: El tutor no existe.';
            RETURN;
        END

        -- verifica que no tenga socios asociados
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.GrupoFamiliar WHERE id_tutor = @id_tutor
        )
        BEGIN
            PRINT 'Error: No se puede eliminar el tutor porque tiene socios vinculados.';
            RETURN;
        END

        -- eliminar tutor
        DELETE FROM eSocios.Tutor WHERE id_tutor = @id_tutor;

        PRINT 'Tutor eliminado correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO



-- agrega un socio a un grupo familiar
CREATE OR ALTER PROCEDURE eSocios.agregarAGrupoFamiliar
	@id_socio VARCHAR(20),
    @id_tutor VARCHAR(20),
	@parentesco VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- verifica que el socio exista
        IF NOT EXISTS 
		(
			SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio
		)
        BEGIN
            PRINT 'El socio no existe';
            RETURN;
        END

        -- verifica que el tutor exista
        IF NOT EXISTS 
		(
			SELECT 1 FROM eSocios.Tutor 
			WHERE id_tutor = @id_tutor
		)
        BEGIN
            PRINT 'El tutor no existe';
            RETURN;
        END

        -- verificar que no tenga ya un grupo familiar asignado
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.GrupoFamiliar 
			WHERE id_socio = @id_socio
        )
        BEGIN
            PRINT 'El socio ya tiene un grupo familiar asignado';
            RETURN;
        END

		-- busca si el tutor ya tiene al menos un socio vinculado
        DECLARE @socio_existente VARCHAR(20);
        DECLARE @descuento_existente DECIMAL(10,2);

        SELECT TOP 1 
            @socio_existente = id_socio, 
            @descuento_existente = descuento
        FROM eSocios.GrupoFamiliar
        WHERE id_tutor = @id_tutor;

        IF @socio_existente IS NOT NULL
        BEGIN
            IF @descuento_existente > 0
            BEGIN
                -- el grupo familiar ya posee descuento
                INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
                VALUES (@id_socio, @id_tutor, @descuento_existente, @parentesco);
            END
            ELSE
            BEGIN
                -- sin descuento, se otorgan descuentos a ambos
                INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
                VALUES (@id_socio, @id_tutor, 15, @parentesco);

                UPDATE eSocios.GrupoFamiliar
                SET descuento = 15
                WHERE id_socio = @socio_existente AND id_tutor = @id_tutor;
            END
        END
        ELSE
        BEGIN
            -- primer socio del grupo, sin descuento
            INSERT INTO eSocios.GrupoFamiliar (id_socio, id_tutor, descuento, parentesco)
            VALUES (@id_socio, @id_tutor, 0, @parentesco);
        END

        PRINT 'Socio agregado al grupo familiar correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- cada un socio a un grupo familiar
CREATE OR ALTER PROCEDURE eSocios.sacarDeGrupoFamiliar
    @id_socio VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- verifica que el socio este en un grupo familiar
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.GrupoFamiliar WHERE id_socio = @id_socio
        )
        BEGIN
            PRINT 'El socio no pertenece a ningún grupo familiar.';
            RETURN;
        END

        -- obtiene el tutor del grupo familiar
        DECLARE @id_tutor VARCHAR(20);
        SELECT @id_tutor = id_tutor
        FROM eSocios.GrupoFamiliar
        WHERE id_socio = @id_socio;

        -- elimina al socio del grupo familiar
        DELETE FROM eSocios.GrupoFamiliar
        WHERE id_socio = @id_socio;

        PRINT 'Socio removido del grupo familiar.';

        -- verifica cuantos socios siguen vinculados al mismo tutor
        DECLARE @cantidad_restante INT;
        SELECT @cantidad_restante = COUNT(*)
        FROM eSocios.GrupoFamiliar
        WHERE id_tutor = @id_tutor;

        -- si solo queda uno y tenía descuento 15, se lo quitamos
        IF @cantidad_restante = 1
        BEGIN
            UPDATE eSocios.GrupoFamiliar
            SET descuento = 0
            WHERE id_tutor = @id_tutor;
            
            PRINT 'El tutor solo tiene un socio restante. Descuento eliminado.';
        END
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO



-- agrega los datos de una actividad
CREATE OR ALTER PROCEDURE eSocios.agregarCategoria
    @nombre VARCHAR(50),
    @costo_mensual DECIMAL(10,2),
    @vigencia DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
		--verifica un costo mensual valido
		IF @costo_mensual < 0
			BEGIN
				PRINT 'Costo mensual invalido';
				RETURN;
			END

		-- verifica que la vigencia sea una fecha futura
        IF @vigencia <= CAST(GETDATE() AS DATE)
        BEGIN
            PRINT 'La vigencia debe ser una fecha futura';
            RETURN;
        END

        INSERT INTO eSocios.Categoria (nombre, costo_mensual, vigencia)
        VALUES (@nombre, @costo_mensual, @vigencia);

        PRINT 'Categoría agregada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- modifica los datos de una categoria
CREATE OR ALTER PROCEDURE eSocios.modificarCategoria
    @id_categoria INT,
    @nombre VARCHAR(50),
    @costo_mensual DECIMAL(10,2),
    @vigencia DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- verifica existencia
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Categoria WHERE id_categoria = @id_categoria
        )
        BEGIN
            PRINT 'Error: La categoría no existe.';
            RETURN;
        END

		--verifica un costo mensual valido
		IF @costo_mensual < 0
			BEGIN
				PRINT 'Costo mensual invalido';
				RETURN;
			END

		-- verifica que la vigencia sea una fecha futura
        IF @vigencia <= CAST(GETDATE() AS DATE)
        BEGIN
            PRINT 'La vigencia debe ser una fecha futura';
            RETURN;
        END

		--actualiza
        UPDATE eSocios.Categoria
        SET nombre = @nombre,
            costo_mensual = @costo_mensual,
            vigencia = @vigencia
        WHERE id_categoria = @id_categoria;

        PRINT 'Categoría modificada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- modifica los datos de una categoria
CREATE OR ALTER PROCEDURE eSocios.eliminarCategoria
    @id_categoria INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- verifica existencia
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Categoria WHERE id_categoria = @id_categoria
        )
        BEGIN
            PRINT 'Error: La categoría no existe.';
            RETURN;
        END

        -- verifica que no este asignada a socios
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.Socio WHERE id_categoria = @id_categoria
        )
        BEGIN
            PRINT 'Error: No se puede eliminar la categoría porque está asignada a uno o más socios.';
            RETURN;
        END
		--elimina
        DELETE FROM eSocios.Categoria WHERE id_categoria = @id_categoria;

        PRINT 'Categoría eliminada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO



-- crea una actividad
CREATE OR ALTER PROCEDURE eSocios.crearActividad
    @nombre NVARCHAR(50),
    @costo_mensual DECIMAL(10,2),
    @vigencia DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
		IF @costo_mensual < 0
			BEGIN
				PRINT 'Costo mensual invalido';
				RETURN;
			END

		 -- verifica que la vigencia sea una fecha futura
        IF @vigencia <= CAST(GETDATE() AS DATE)
        BEGIN
            PRINT 'La vigencia debe ser una fecha futura';
            RETURN;
        END

        INSERT INTO eSocios.Actividad (nombre, costo_mensual, vigencia)
        VALUES (@nombre, @costo_mensual, @vigencia);
		       
		PRINT 'Actividad creada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- modifica nombre, precio y vigencia de una actividad
CREATE OR ALTER PROCEDURE eSocios.modificarActividad
    @id_actividad INT,
    @nombre NVARCHAR(50),
    @costo_mensual DECIMAL(10,2),
    @vigencia DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
		--verifica que la actividad existe
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Actividad 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            PRINT 'La actividad no existe';
            RETURN;
        END

		-- verifica que la vigencia sea una fecha futura
        IF @vigencia <= CAST(GETDATE() AS DATE)
        BEGIN
            PRINT 'La vigencia debe ser una fecha futura';
            RETURN;
        END

		--actualiza los datos
        UPDATE eSocios.Actividad
        SET nombre = @nombre,
            costo_mensual = @costo_mensual,
            vigencia = @vigencia
        WHERE id_actividad = @id_actividad;
		PRINT 'Actividad modificada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- elimina una actividad
CREATE OR ALTER PROCEDURE eSocios.eliminarActividad
    @id_actividad INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- verifica existencia de la actividad
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Actividad 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            PRINT 'La actividad no existe';
            RETURN;
        END

        -- verifica si hay socios inscriptos
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.Realiza 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            PRINT 'No se puede eliminar la actividad porque hay socios inscriptos';
            RETURN;
        END

        -- verifica si hay presentismo cargado
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.Presentismo 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            PRINT 'No se puede eliminar la actividad porque hay registros de presentismo';
            RETURN;
        END

        -- verifica si tiene horarios asignados
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.ActividadDiaHorario 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            PRINT 'No se puede eliminar la actividad porque tiene horarios asignados';
            RETURN;
        END

        -- si paso todos los chequeos, elimino la actividad
        DELETE FROM eSocios.Actividad
        WHERE id_actividad = @id_actividad;
		PRINT 'La actividad fue eliminada correctamente';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- establece horarios para una actividad
CREATE OR ALTER PROCEDURE eSocios.agregarHorarioActividad
    @id_actividad INT,
    @dia VARCHAR(20),
    @hora_inicio TIME,
    @hora_fin TIME
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- valida existencia de la actividad
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Actividad 
			WHERE id_actividad = @id_actividad
        )
        BEGIN
            PRINT 'La actividad no existe';
            RETURN;
        END

        -- valida dia
        IF @dia NOT IN ('lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo')
        BEGIN
            PRINT 'El día ingresado no es válido';
            RETURN;
        END

        -- valida duplicado
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.ActividadDiaHorario
            WHERE id_actividad = @id_actividad AND dia = @dia AND hora_inicio = @hora_inicio
        )
        BEGIN
            PRINT 'Ese horario ya está asignado a la actividad';
            RETURN;
        END
		--inserta
        INSERT INTO eSocios.ActividadDiaHorario (id_actividad, dia, hora_inicio, hora_fin)
        VALUES (@id_actividad, @dia, @hora_inicio, @hora_fin);
		PRINT 'Horarios agregados correctamente';

    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE eSocios.eliminarHorarioActividad
    @id_actividad INT,
    @dia VARCHAR(20),
    @hora_inicio TIME
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- valida existencia de la actividad
        IF NOT EXISTS (
            SELECT 1 FROM eSocios.ActividadDiaHorario
            WHERE id_actividad = @id_actividad AND dia = @dia AND hora_inicio = @hora_inicio
        )
        BEGIN
            RAISERROR('El horario no existe para esa actividad', 16, 1);
            RETURN;
        END

        -- valida dia
        IF @dia NOT IN ('lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo')
        BEGIN
            RAISERROR('El día ingresado no es válido', 16, 1);
            RETURN;
        END

		--borra
        DELETE FROM eSocios.ActividadDiaHorario
        WHERE id_actividad = @id_actividad AND dia = @dia AND hora_inicio = @hora_inicio;
		PRINT 'Horarios eliminados correctamente';

    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO



--verifica que exista un socio con el ID dado y luego de eso le asigna la actividad indicada por ID en la tabla Realiza
CREATE OR ALTER PROCEDURE eSocios.inscribirActividad
    @id_socio VARCHAR(20),
    @id_actividad INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- valida existencia de socio
        IF NOT EXISTS 
		(
			SELECT 1 FROM eSocios.Socio 
			WHERE id_socio = @id_socio AND activo = 1
		)
        BEGIN
            PRINT 'El socio no existe o está inactivo';
            RETURN;
        END
        -- valida existencia de actividad
        IF NOT EXISTS 
		(
			SELECT 1 FROM eSocios.Actividad 
			WHERE id_actividad = @id_actividad
		)
        BEGIN
            PRINT 'La actividad no existe';
            RETURN;
        END

        -- verifica que no este inscripto
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.Realiza
            WHERE socio = @id_socio AND id_actividad = @id_actividad
        )
        BEGIN
            PRINT 'El socio ya está inscripto en esa actividad';
            RETURN;
        END

        INSERT INTO eSocios.Realiza (socio, id_actividad)
        VALUES (@id_socio, @id_actividad);

		PRINT 'Socio inscrito correctamente';

    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- elimina a un socio de una actividad
CREATE OR ALTER PROCEDURE eSocios.desinscribirActividad
    @id_socio VARCHAR(20),
    @id_actividad INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Realiza
            WHERE socio = @id_socio AND id_actividad = @id_actividad
        )
        BEGIN
            PRINT 'El socio no existe o no está inscripto en esa actividad';
            RETURN;
        END

        DELETE FROM eSocios.Realiza
        WHERE socio = @id_socio AND id_actividad = @id_actividad;

		PRINT 'Socio dado de baja de actividad correctamente';

    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO
-- registra presentismo de un socio a una actividad
CREATE OR ALTER PROCEDURE eSocios.registrarPresentismo
    @id_socio VARCHAR(20),
    @id_actividad INT,
    @fecha_asistencia DATE = NULL,
    @asistencia VARCHAR(5),
    @profesor VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- verifica que el socio exista
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Socio WHERE id_socio = @id_socio
        )
        BEGIN
            PRINT 'Error: El socio especificado no existe.';
            RETURN;
        END

        -- verifica que la actividad exista
        IF NOT EXISTS 
		(
            SELECT 1 FROM eSocios.Actividad WHERE id_actividad = @id_actividad
        )
        BEGIN
            PRINT 'Error: La actividad especificada no existe.';
            RETURN;
        END

        -- fecha por defecto
        IF @fecha_asistencia IS NULL
            SET @fecha_asistencia = CONVERT(DATE, GETDATE());

        -- verifica si ya se registro asistencia para ese socio, actividad y fecha
        IF EXISTS 
		(
            SELECT 1 FROM eSocios.Presentismo
            WHERE id_socio = @id_socio AND id_actividad = @id_actividad AND fecha_asistencia = @fecha_asistencia
        )
        BEGIN
            PRINT 'Advertencia: Ya existe un registro de presentismo para este socio, actividad y fecha.';
            RETURN;
        END

        -- Inserta el registro
        INSERT INTO eSocios.Presentismo 
		(
            id_socio, id_actividad, fecha_asistencia, asistencia, profesor
        )
        VALUES 
		(
            @id_socio, @id_actividad, @fecha_asistencia, @asistencia, @profesor
        );

        PRINT 'Presentismo registrado correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO




-- SP para generar factura mensual con el total de actividades y membresia 
CREATE OR ALTER PROCEDURE eCobros.generarFactura
    @id_socio VARCHAR(20),
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
    
   -- obtiene la categoria del socio
    DECLARE @id_categoria INT, @costo_membresia DECIMAL(10,2);
    SELECT 
        @id_categoria = id_categoria
    FROM eSocios.Socio
    WHERE id_socio = @id_socio;

	-- valida que la categoria existe y tiene costo
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
        
        -- calculo de descuentos
        DECLARE @total_membresias DECIMAL(10,2) = @costo_membresia;
        DECLARE @porcentaje_descuento_familiar DECIMAL(5,2) = 0;
        DECLARE @porcentaje_descuento_actividades DECIMAL(5,2) = 0;
        
        -- verifica si tiene grupo familiar
        IF EXISTS (SELECT 1 FROM eSocios.GrupoFamiliar WHERE id_socio = @id_socio)
            SELECT @porcentaje_descuento_familiar = ISNULL(descuento, 0)
            FROM eSocios.GrupoFamiliar
            WHERE id_socio = @id_socio;
        
        -- total actividades
        DECLARE @total_actividades DECIMAL(10,2) = 0;
        SELECT @total_actividades = ISNULL(SUM(a.costo_mensual), 0)
        FROM eSocios.Realiza sa
        JOIN eSocios.Actividad a ON sa.id_actividad = a.id_actividad
        WHERE sa.socio = @id_socio;

        -- descuento por multiples actividades
        IF (SELECT COUNT(*) FROM eSocios.Realiza WHERE socio = @id_socio) > 1
            SET @porcentaje_descuento_actividades = 10;
        
        -- total con descuentos
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
        
        -- nombre de la categoria para item de membresia
        DECLARE @nombre_categoria VARCHAR(50);
        SELECT @nombre_categoria = nombre
        FROM eSocios.Categoria
        WHERE id_categoria = @id_categoria;
        
        -- inserta item de membresia
        INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto)
        VALUES 
		(
            @id_factura, 
            CONCAT('Membresía - ', @nombre_categoria), 
            @costo_membresia
        );
       
        -- inserta items por actividades
        INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto)
        SELECT 
            @id_factura, 
            a.nombre,      
            a.costo_mensual
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

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

-- si se paso del primer vencimiento aplica recargo, si se paso del segundo vencimiento inhabilita al socio
CREATE OR ALTER PROCEDURE eCobros.verificarVencimiento
    @id_factura INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @fecha_venc_1 DATE;
        DECLARE @fecha_venc_2 DATE;
        DECLARE @estado VARCHAR(20);
        DECLARE @total_actual DECIMAL(10,2);
        DECLARE @id_socio VARCHAR(20);
        DECLARE @porcentaje_recargo DECIMAL(5,2) = 10;--10% de recargo
        DECLARE @recargo_ya_aplicado BIT = 0;

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
            @total_actual = total,
            @id_socio = id_socio
        FROM eCobros.Factura
        WHERE id_factura = @id_factura;

        -- verifica estado de la factura
        IF @estado <> 'pendiente'
        BEGIN
            PRINT 'La factura ' + CAST(@id_factura AS VARCHAR) + ' no está pendiente.';
            RETURN;
        END;

        IF GETDATE() < @fecha_venc_1
		BEGIN
            PRINT 'La factura ' + CAST(@id_factura AS VARCHAR) + ' no está vencida.';
            RETURN;
        END;

        -- verifica si ya se aplico el recargo
        IF GETDATE() < @fecha_venc_2 AND EXISTS 
		(
            SELECT 1 
            FROM eCobros.ItemFactura 
            WHERE id_factura = @id_factura 
              AND concepto = 'recargo por vencimiento'
        )
        BEGIN
            SET @recargo_ya_aplicado = 1;
            PRINT 'Ya se había aplicado el recargo para la factura ' + CAST(@id_factura AS VARCHAR) + '.';
			RETURN
        END;

        -- si paso del segundo vencimiento
        IF GETDATE() > @fecha_venc_2
        BEGIN
            -- inactiva al socio
            UPDATE eSocios.Socio
            SET activo = 0
            WHERE id_socio = @id_socio;

            PRINT 'La factura ' + CAST(@id_factura AS VARCHAR) + 
                  ' ya superó el segundo vencimiento. El socio ' + @id_socio + ' fue marcado como inactivo.';
            RETURN;
        END;

        -- si estamos entre vencimiento 1 y 2 Y aún no se aplico recargo
        IF GETDATE() > @fecha_venc_1 AND GETDATE() <= @fecha_venc_2 AND @recargo_ya_aplicado = 0
        BEGIN
            DECLARE @monto_recargo DECIMAL(10,2) = ROUND(@total_actual * (@porcentaje_recargo / 100.0), 2);

            -- actualiza factura
            UPDATE eCobros.Factura
            SET 
                total = @total_actual + @monto_recargo,
                recargo_venc = @porcentaje_recargo
            WHERE id_factura = @id_factura;

            -- inserta item de recargo
            INSERT INTO eCobros.ItemFactura (id_factura, concepto, monto)
            VALUES 
			(
                @id_factura, 
                'recargo por vencimiento', 
                @monto_recargo
            );

            PRINT 'Recargo aplicado correctamente a la factura ' + CAST(@id_factura AS VARCHAR) + 
                  '. Monto: $' + CAST(@monto_recargo AS VARCHAR);
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
    IF NOT EXISTS 
	(
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

    PRINT 'Factura ' + CAST(@id_factura AS VARCHAR(10)) + ' anulada correctamente.';
END;
GO



--registra una entrada a la pileta y se ascocia a una factura
CREATE OR ALTER PROCEDURE eCobros.registrarEntradaPileta
    @id_socio VARCHAR(20),
    @fecha DATE = NULL,
    @categoria VARCHAR(30), -- 'Adultos' o 'Menores de 12 años'
    @tipo_usuario VARCHAR(20), -- 'Socios' o 'Invitados'
    @modalidad VARCHAR(30) -- 'Valor del dia', 'Valor de temporada', 'Valor del Mes'
AS
BEGIN
    SET NOCOUNT ON;

    -- validaciones 
    IF NOT EXISTS (SELECT 1 FROM eSocios.Socio WHERE id_socio = @id_socio)
    BEGIN
        PRINT 'Error: El socio especificado no existe.';
        RETURN;
    END

    IF @fecha IS NULL
        SET @fecha = CONVERT(DATE, GETDATE());

    -- verifica morosidad
    IF EXISTS 
	(
        SELECT 1
        FROM eCobros.Factura
        WHERE id_socio = @id_socio AND estado = 'pendiente' AND fecha_venc_2 < @fecha
    )
    BEGIN
        PRINT 'Error: El socio tiene cuotas impagas y no puede acceder a la pileta.';
        RETURN;
    END

    -- obtiene precio vigente según categoría, tipo y modalidad
    DECLARE @precio_base DECIMAL(10,2);

    SELECT TOP 1 @precio_base = precio
    FROM eCobros.PreciosAcceso
    WHERE categoria = @categoria
      AND tipo_usuario = @tipo_usuario
      AND modalidad = @modalidad
      AND activo = 1
      AND vigencia_hasta >= @fecha
    ORDER BY vigencia_hasta ASC;

    IF @precio_base IS NULL
    BEGIN
        PRINT 'Error: No se encontró un precio válido para los parámetros indicados.';
        RETURN;
    END

    -- determina si hubo lluvia (solo aplica para modalidad 'Valor del dia')
    DECLARE @reembolso DECIMAL(10,2) = 0;

    IF @modalidad = 'Valor del dia'
    BEGIN
        IF EXISTS 
		(
            SELECT 1
            FROM eSocios.datos_meteorologicos
			WHERE CONVERT(DATE, fecha_hora) = @fecha
				AND lluvia_mm > 0
        )
        BEGIN
            SET @reembolso = @precio_base * 0.6;--reembolso del 60%
        END
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- crea factura si no hay una abierta en la fecha
        DECLARE @id_factura INT;

        SELECT @id_factura = id_factura
        FROM eCobros.Factura
        WHERE id_socio = @id_socio
          AND fecha_emision = @fecha
          AND estado = 'pendiente';

        IF @id_factura IS NULL
        BEGIN
            INSERT INTO eCobros.Factura 
			(
                id_socio, fecha_emision, fecha_venc_1, fecha_venc_2, estado, total, recargo_venc, descuentos
            )
            VALUES 
			(
                @id_socio, @fecha, DATEADD(DAY,5,@fecha), DATEADD(DAY,10,@fecha), 'pendiente', 0, 0, 0
            );

            SET @id_factura = SCOPE_IDENTITY();
        END

        -- inserta ítem de acceso
        INSERT INTO eCobros.ItemFactura 
		(
            id_factura, concepto, monto
        )
        VALUES 
		(
            @id_factura, CONCAT('Entrada Pileta - ', @tipo_usuario, ' (', @modalidad, ')'), @precio_base
        );

        -- aplica reembolso si corresponde
        IF @reembolso > 0
        BEGIN
            INSERT INTO eCobros.ItemFactura 
			(
                id_factura, concepto, monto
            )
            VALUES 
			(
                @id_factura, 'Reembolso por lluvia', -@reembolso
            );
        END

        -- Actualiza total de factura
        UPDATE eCobros.Factura
        SET total = total + @precio_base - @reembolso
        WHERE id_factura = @id_factura;

        COMMIT TRANSACTION;
        PRINT CONCAT('Entrada registrada. Total: $', FORMAT(@precio_base - @reembolso, 'N2'));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
--elimina el item de una factura
CREATE OR ALTER PROCEDURE eCobros.eliminarItemFactura
    @id_item INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- valida que el item existe
        IF NOT EXISTS (SELECT 1 FROM eCobros.ItemFactura WHERE id_item = @id_item)
        BEGIN
            PRINT 'Error: El ítem especificado no existe.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- obtiene datos del item y la factura asociada
        DECLARE @id_factura INT;
        DECLARE @monto DECIMAL(10,2);
        DECLARE @estado_factura VARCHAR(20);

        SELECT 
            @id_factura = id_factura,
            @monto = monto
        FROM eCobros.ItemFactura
        WHERE id_item = @id_item;

        -- valida estado de la factura
        SELECT @estado_factura = estado
        FROM eCobros.Factura
        WHERE id_factura = @id_factura;

        IF @estado_factura IN ('pagada', 'anulada')
        BEGIN
            PRINT 'Error: No se puede eliminar un ítem de una factura pagada o anulada.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- elimina el item
        DELETE FROM eCobros.ItemFactura
        WHERE id_item = @id_item;

        -- ajusta el total de la factura
        UPDATE eCobros.Factura
        SET total = total - @monto
        WHERE id_factura = @id_factura;

        COMMIT TRANSACTION;

        PRINT 'Ítem eliminado correctamente y total de factura actualizado.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END;
GO



--genera un pago asociado a una factura
CREATE OR ALTER PROCEDURE eCobros.cargarPago
    @id_factura INT,
    @medio_pago VARCHAR(50),
    @monto DECIMAL(10,2),
    @fecha DATE = NULL,
    @debito_auto BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @estado_factura VARCHAR(20);
    DECLARE @total_factura DECIMAL(10,2);
    DECLARE @total_pagado DECIMAL(10,2) = 0;
    DECLARE @fecha_pago DATE;
    DECLARE @id_pago BIGINT;

    -- valida que la factura existe
    SELECT 
        @estado_factura = estado, 
        @total_factura = total
    FROM eCobros.Factura 
    WHERE id_factura = @id_factura;
    
    IF @estado_factura IS NULL
    BEGIN
        PRINT 'La factura especificada no existe.';
        RETURN;
    END

    IF @estado_factura = 'anulada'
    BEGIN
        PRINT 'No se puede registrar un pago para una factura anulada.';
        RETURN;
    END

    IF @estado_factura = 'pagada'
    BEGIN
        PRINT 'La factura ya se encuentra completamente pagada.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @fecha IS NULL
            SET @fecha_pago = GETDATE();
        ELSE
            SET @fecha_pago = @fecha;

        -- total pagado hasta ahora
        SELECT @total_pagado = ISNULL(SUM(monto), 0)
        FROM eCobros.Pago 
        WHERE id_factura = @id_factura AND estado = 'completado';

		IF (@total_pagado + @monto) > @total_factura
		BEGIN
			DECLARE @saldo_pendiente DECIMAL(10,2) = @total_factura - @total_pagado;
			PRINT 'Error: El monto del pago (' + CAST(@monto AS VARCHAR(20)) + 
				  ') excede el saldo pendiente de la factura (' + 
				  CAST(@saldo_pendiente AS VARCHAR(20)) + ').';
			ROLLBACK TRANSACTION;
			RETURN;
		END

        -- genera nuevo id_pago
        SELECT @id_pago = ISNULL(MAX(id_pago), 0) + 1 FROM eCobros.Pago;

        -- inserta el pago
        INSERT INTO eCobros.Pago 
		(
            id_pago, id_factura, medio_pago, monto, fecha, estado, debito_auto
        )
        VALUES 
		(
            @id_pago, @id_factura, @medio_pago, @monto, @fecha_pago, 'completado', @debito_auto
        );

        -- actualiza estado de factura si se paga completamente
        IF (@total_pagado + @monto) = @total_factura
        BEGIN
            UPDATE eCobros.Factura 
            SET estado = 'pagada' 
            WHERE id_factura = @id_factura;
        END

        COMMIT TRANSACTION;

        -- mensajes
        PRINT 'Pago registrado exitosamente.';
        PRINT 'ID Pago: ' + CAST(@id_pago AS VARCHAR(20));
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

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

--borrado logico de pago
CREATE OR ALTER PROCEDURE eCobros.anularPago 
    @id_pago bigint
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- valida que el pago existe y está en estado 'completado'
        IF NOT EXISTS 
        (
            SELECT 1 
            FROM eCobros.Pago 
            WHERE id_pago = @id_pago AND estado = 'completado'
        )
        BEGIN
            PRINT 'Error: El pago no existe o no está en estado completado.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- valida que no tenga reembolsos procesados
        IF EXISTS 
        (
            SELECT 1 
            FROM eCobros.Reembolso 
            WHERE id_pago = @id_pago
        )
        BEGIN
            PRINT 'Error: No se puede anular un pago que tiene reembolsos asociados.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- realiza el borrado lógico cambiando el estado
        UPDATE eCobros.Pago 
        SET estado = 'anulado'
        WHERE id_pago = @id_pago;
        
        -- obtiene datos de la factura para actualizar su estado si es necesario
        DECLARE @id_factura INT;
        DECLARE @total_factura DECIMAL(10,2);
        DECLARE @total_pagado DECIMAL(10,2) = 0;
        
        SELECT @id_factura = id_factura 
        FROM eCobros.Pago 
        WHERE id_pago = @id_pago;
        
        SELECT @total_factura = total 
        FROM eCobros.Factura 
        WHERE id_factura = @id_factura;
        
        -- calcula el total pagado (excluyendo pagos anulados)
        SELECT @total_pagado = ISNULL(SUM(monto), 0)
        FROM eCobros.Pago 
        WHERE id_factura = @id_factura 
          AND estado = 'completado';
        
        -- actualiza estado de la factura
        IF @total_pagado = 0
        BEGIN
            UPDATE eCobros.Factura 
            SET estado = 'pendiente' 
            WHERE id_factura = @id_factura;
        END
        ELSE IF @total_pagado < @total_factura
        BEGIN
            UPDATE eCobros.Factura 
            SET estado = 'pendiente' 
            WHERE id_factura = @id_factura;
        END
        
        COMMIT TRANSACTION;
        
        PRINT 'Pago anulado exitosamente.';
        PRINT 'ID Pago: ' + CAST(@id_pago AS VARCHAR(20));
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO

--genera un reembolso para un pago
CREATE OR ALTER PROCEDURE eCobros.generarReembolso
    @id_pago BIGINT,
    @monto DECIMAL(10,2),
    @motivo VARCHAR(100),
    @fecha DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- validaciones
    DECLARE @estado_pago VARCHAR(20);
    DECLARE @monto_pago DECIMAL(10,2);
    DECLARE @total_reembolsado DECIMAL(10,2) = 0;
    DECLARE @fecha_reembolso DATE;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- obtiene estado y monto del pago
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

        -- calcula total ya reembolsado para el pago
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

        -- fecha por defecto
        IF @fecha IS NULL
            SET @fecha_reembolso = CONVERT(DATE, GETDATE());
        ELSE
            SET @fecha_reembolso = @fecha;

        -- inserta el reembolso
        INSERT INTO eCobros.Reembolso (id_pago, monto, motivo, fecha)
        VALUES (@id_pago, @monto, @motivo, @fecha_reembolso);

        -- determina nuevo estado del pago
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
CREATE OR ALTER PROCEDURE eCobros.eliminarReembolso
    @id_reembolso INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar que el reembolso existe
        IF NOT EXISTS 
		(
            SELECT 1 
            FROM eCobros.Reembolso 
            WHERE id_reembolso = @id_reembolso
        )
        BEGIN
            PRINT 'Error: El reembolso no existe.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- obtiene informacion del reembolso
        DECLARE @id_pago BIGINT;
        SELECT @id_pago = id_pago
        FROM eCobros.Reembolso
        WHERE id_reembolso = @id_reembolso;

        -- elimina el reembolso
        DELETE FROM eCobros.Reembolso 
        WHERE id_reembolso = @id_reembolso;

        -- calcula los reembolsos activos
        DECLARE @total_reembolsado DECIMAL(10,2) = 0;
        SELECT @total_reembolsado = ISNULL(SUM(monto), 0)
        FROM eCobros.Reembolso
        WHERE id_pago = @id_pago;

        -- obtiene el monto original del pago
        DECLARE @monto_pago DECIMAL(10,2);
        SELECT @monto_pago = monto 
        FROM eCobros.Pago 
        WHERE id_pago = @id_pago;

        -- ajusta estado del pago
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


CREATE OR ALTER PROCEDURE eCobros.reembolsoComoPagoACuenta
    @id_pago BIGINT,
    @monto DECIMAL(10,2),
    @motivo VARCHAR(100),
    @fecha DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @estado_pago VARCHAR(20);
    DECLARE @monto_pago DECIMAL(10,2);
    DECLARE @total_reembolsado DECIMAL(10,2) = 0;
    DECLARE @fecha_reembolso DATE;
    DECLARE @id_socio VARCHAR(20);

    BEGIN TRY
        BEGIN TRANSACTION;

      -- obtiene estado, monto y socio del pago
        SELECT 
            @estado_pago = p.estado,
            @monto_pago = p.monto,
            @id_socio = f.id_socio
        FROM eCobros.Pago p
        INNER JOIN eCobros.Factura f ON p.id_factura = f.id_factura
        WHERE p.id_pago = @id_pago;

		IF @estado_pago IS NULL
        BEGIN
            PRINT 'Error: El pago no existe.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @estado_pago = 'anulado'
        BEGIN
            PRINT 'Error: No se puede reembolsar un pago anulado.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @total_reembolsado = ISNULL(SUM(monto), 0)
        FROM eCobros.Reembolso
        WHERE id_pago = @id_pago;

        IF (@total_reembolsado + @monto) > @monto_pago
        BEGIN
            PRINT 'Error: El reembolso excede el monto pagado.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @fecha IS NULL
            SET @fecha_reembolso = CONVERT(DATE, GETDATE());
        ELSE
            SET @fecha_reembolso = @fecha;

        -- inserta en reembolso
        INSERT INTO eCobros.Reembolso (id_pago, monto, motivo, fecha)
        VALUES (@id_pago, @monto, @motivo, @fecha_reembolso);

        -- registra o actualiza saldo del socio
        IF EXISTS (SELECT 1 FROM eCobros.SaldoSocio WHERE id_socio = @id_socio)
        BEGIN
            UPDATE eCobros.SaldoSocio
            SET saldo = saldo + @monto
            WHERE id_socio = @id_socio;
        END
        ELSE
        BEGIN
            INSERT INTO eCobros.SaldoSocio (id_socio, saldo)
            VALUES (@id_socio, @monto);
        END

        -- actualiza estado del pago
        IF (@total_reembolsado + @monto) = @monto_pago
        BEGIN
            UPDATE eCobros.Pago
            SET estado = 'reembolsado'
            WHERE id_pago = @id_pago;
        END

        COMMIT TRANSACTION;
        PRINT 'Reembolso registrado como saldo a favor del socio.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'Error inesperado: ' + ERROR_MESSAGE();
    END CATCH
END
GO




CREATE OR ALTER PROCEDURE eAdministrativos.crearUsuario
	@rol VARCHAR(50),
	@nombre_usuario NVARCHAR(50),
	@clave NVARCHAR(50), --La clave se recibe en texto plano para el hash
	@vigencia_dias INT = 90
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		--Validar si el nombre de usuario ya existe
		IF EXISTS (
			SELECT 1
			FROM eAdministrativos.UsuarioAdministrativo
			WHERE nombre_usuario = @nombre_usuario
		)
			THROW 50001, 'El nombre de usuario ya existe.',1;

		-- Validación de formato de clave
		IF LEN(@clave) < 8  OR @clave NOT LIKE '%[A-Z]%' OR @clave NOT LIKE '%[a-z]%' OR @clave NOT LIKE '%[0-9]%' OR @clave NOT LIKE '%[^a-zA-Z0-9]%'
			THROW 50003, 'La contraseña debe tener al menos 8 caracteres, incluyendo mayúsculas, minúsculas, números y símbolos.', 1;

		--Validar que el rol exista en la base de datos
		IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @rol AND type = 'R')
			THROW 50004, 'El rol especificado no existe.', 1;

		BEGIN TRANSACTION

		-- Inserción en tabla lógica con HASH de la clave
		INSERT INTO eAdministrativos.UsuarioAdministrativo (
			rol, nombre_usuario, clave, fecha_vigencia_clave, ultimo_cambio_clave
		)
		VALUES (
			@rol, 
			@nombre_usuario, 
			HASHBYTES('SHA2_256',@clave), 
			DATEADD(DAY, @vigencia_dias, GETDATE()), GETDATE()
		);

		-- Crear LOGIN a nivel servidor
		--Se utiliza la clave en texto plano para crear el LOGIN, ya que SQL Server
		--gestionará el hash interno para el LOGIN del servidor.
		--Se establece la base de datos 'Com5600G10' como default para este login
		DECLARE @sql_login NVARCHAR(MAX);
		DECLARE @db_name SYSNAME = 'Com5600G10';
		SET @sql_login = '
			IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = ''' + @nombre_usuario + ''')
			BEGIN
				CREATE LOGIN [' + @nombre_usuario + ']
				WITH PASSWORD = ''' + @clave + ''',
				DEFAULT_DATABASE = [' + @db_name + '], -- Establece la base de datos actual como default
				CHECK_POLICY = ON, -- Se recomienda mantener la política de check del login activa
				CHECK_EXPIRATION = ON; -- Se recomienda activar la expiración para logins de usuario
			END';
			EXEC sp_executesql @sql_login; --sp_executesql para seguridad y manejo de parametros

		-- Crear USER
        DECLARE @sql_user NVARCHAR(MAX) = '
        IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''' + @nombre_usuario + ''')
        BEGIN
            CREATE USER [' + @nombre_usuario + '] FOR LOGIN [' + @nombre_usuario + '];
        END';
        EXEC sp_executesql @sql_user;

		-- Asignar el USER al Rol de base de datos especificado
        DECLARE @sql_role NVARCHAR(MAX) = '
        ALTER ROLE [' + @rol + '] ADD MEMBER [' + @nombre_usuario + ']';
        EXEC sp_executesql @sql_role;

		COMMIT TRANSACTION; --Confirma todos los cambios si todo fue exitoso
		PRINT 'Usuario creado con éxito.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION; --En caso de algun fallo rollback

		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END;
GO

CREATE OR ALTER PROCEDURE eAdministrativos.modificarUsuario
	@id_usuario INT,
	@nuevo_rol VARCHAR(50) = NULL, --opcional
	@nuevo_nombre_usuario NVARCHAR(50) = NULL, --opcional
	@nueva_clave NVARCHAR (50) = NULL, --opcional
	@vigencia_dias INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		--Validacion existencia
		IF NOT EXISTS (SELECT 1 FROM eAdministrativos.UsuarioAdministrativo WHERE id_usuario = @id_usuario)
			THROW 50001, 'No existe usuario con ese ID.', 1;
		
		--Obtener datos actuales del usuario
		DECLARE @rol_actual VARCHAR(50);
		DECLARE @nombre_usuario_actual NVARCHAR(50);
		DECLARE @clave_hash_actual VARBINARY(32); -- Para comparar hashes
		DECLARE @fecha_vigencia_clave_actual DATE;
		
		SELECT
			@rol_actual = rol,
			@nombre_usuario_actual = nombre_usuario,
			@clave_hash_actual = clave,
			@fecha_vigencia_clave_actual = fecha_vigencia_clave
		FROM eAdministrativos.UsuarioAdministrativo
		WHERE id_usuario = @id_usuario;

		--Validar si al menos un parámetro de modificacion fue proporcionado
		IF @nuevo_rol IS NULL AND @nuevo_nombre_usuario IS NULL AND @nueva_clave IS NULL AND @vigencia_dias IS NULL
			THROW 50002, 'Debe especificar al menos un campo para modificar.', 1;

		--Validar que el nuevo nombre no esté en uso por otro usuario
		IF @nuevo_nombre_usuario IS NOT NULL AND @nuevo_nombre_usuario <> @nombre_usuario_actual
		BEGIN
			IF EXISTS (SELECT 1 FROM eAdministrativos.UsuarioAdministrativo WHERE nombre_usuario = @nuevo_nombre_usuario AND id_usuario <> @id_usuario)
				THROW 50003, 'El nombre de usuario ya está en uso.', 1;
		END
		

		-- Validación de formato de nueva clave
		IF @nueva_clave IS NOT NULL
		BEGIN
			IF LEN(@nueva_clave) < 8 
			OR @nueva_clave NOT LIKE '%[A-Z]%' 
			OR @nueva_clave NOT LIKE '%[a-z]%' 
			OR @nueva_clave NOT LIKE '%[0-9]%' 
			OR @nueva_clave NOT LIKE '%[^a-zA-Z0-9]%' 
				THROW 50004, 'La contraseña debe tener al menos 8 caracteres, incluyendo mayúsculas, minúsculas, números y símbolos.', 1;
		END
		
		--Validar que el nuevo Rol exista como ROLE en la DB
		IF @nuevo_rol IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @nuevo_rol AND type = 'R')
				THROW 50005, 'El rol especificado no existe.', 1;
		END
		
		BEGIN TRANSACTION
	
		--Actualizacion en la tabla
		UPDATE eAdministrativos.UsuarioAdministrativo
			SET 
				rol = COALESCE(@nuevo_rol, @rol_actual),
				nombre_usuario = COALESCE(@nuevo_nombre_usuario, @nombre_usuario_actual),
				clave = COALESCE(HASHBYTES('SHA2_256', @nueva_clave), @clave_hash_actual),
				fecha_vigencia_clave = COALESCE(DATEADD(DAY, @vigencia_dias, GETDATE()), @fecha_vigencia_clave_actual),
				ultimo_cambio_clave = CASE WHEN @nueva_clave IS NOT NULL THEN GETDATE() ELSE ultimo_cambio_clave END
			WHERE id_usuario = @id_usuario;

		--Cambios en LOGIN y USER
		DECLARE @sql_dynamic NVARCHAR(MAX);
		DECLARE @current_db_name SYSNAME = DB_NAME();

		-- Si el nombre de usuario cambió, renombrar LOGIN y USER
		IF @nuevo_nombre_usuario IS NOT NULL AND @nuevo_nombre_usuario <> @nombre_usuario_actual
		BEGIN
			-- Renombrar LOGIN
			SET @sql_dynamic = N'ALTER LOGIN [' + @nombre_usuario_actual + N'] WITH NAME = [' + @nuevo_nombre_usuario + N'];';
			EXEC sp_executesql @sql_dynamic;

			-- Renombrar USER
			SET @sql_dynamic = N'ALTER USER [' + @nombre_usuario_actual + N'] WITH NAME = [' + @nuevo_nombre_usuario + N'];';
			EXEC sp_executesql @sql_dynamic;
		END;

		-- Si la clave cambió, actualizar contraseña del LOGIN
		IF @nueva_clave IS NOT NULL
		BEGIN
			-- Usar el nombre de usuario que será el actual después de un posible renombramiento
			DECLARE @login_name_for_password NVARCHAR(50) = ISNULL(@nuevo_nombre_usuario, @nombre_usuario_actual);
			
			-- Usar QUOTENAME para manejar caracteres especiales en la contraseña
			SET @sql_dynamic = N'ALTER LOGIN [' + @login_name_for_password + N'] WITH PASSWORD = ' + QUOTENAME(@nueva_clave, '''') + N', CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = [' + @current_db_name + N'];';
			EXEC sp_executesql @sql_dynamic;
		END;

		-- Si el rol cambió, reasignar el USER al nuevo rol
		IF @nuevo_rol IS NOT NULL AND @nuevo_rol <> @rol_actual
		BEGIN
			DECLARE @final_username NVARCHAR(50) = ISNULL(@nuevo_nombre_usuario, @nombre_usuario_actual);
			
			-- Remover del rol antiguo (si no es 'public' y existe)
			IF @rol_actual IS NOT NULL AND @rol_actual <> 'public' AND 
			   EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @rol_actual AND type = 'R')
			BEGIN
				SET @sql_dynamic = N'ALTER ROLE [' + @rol_actual + N'] DROP MEMBER [' + @final_username + N'];';
				EXEC sp_executesql @sql_dynamic;
			END;

			-- Añadir al nuevo rol
			SET @sql_dynamic = N'ALTER ROLE [' + @nuevo_rol + N'] ADD MEMBER [' + @final_username + N'];';
			EXEC sp_executesql @sql_dynamic;
		END;

		COMMIT TRANSACTION;
		PRINT 'Usuario modificado con éxito.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END; 
GO


CREATE OR ALTER PROCEDURE eAdministrativos.eliminarUsuario
	@id_usuario INT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
	--Validar existencia usuario
		IF NOT EXISTS (SELECT 1 FROM eAdministrativos.UsuarioAdministrativo WHERE id_usuario = @id_usuario)
			THROW 50001, 'El usuario no existe.', 1;

		--Obtener nombre de usuario y el rol
		DECLARE @nombre_usuario NVARCHAR(50);
		DECLARE @rol_asociado VARCHAR(50);
		SELECT @nombre_usuario = nombre_usuario, @rol_asociado = rol
		FROM eAdministrativos.UsuarioAdministrativo WHERE id_usuario = @id_usuario;
	
		BEGIN TRANSACTION

		--Eliminar usuario 
		DELETE FROM eAdministrativos.UsuarioAdministrativo
		WHERE id_usuario = @id_usuario

		-- Remover el USER de la base de datos de su rol (si no es 'public')
		-- Es importante quitarlo del rol antes de eliminar el USER si no es el rol 'public'
			IF @rol_asociado IS NOT NULL AND @rol_asociado <> 'public' AND EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @rol_asociado AND type = 'R')
			BEGIN
				DECLARE @sql_drop_role_member NVARCHAR(MAX) = 'ALTER ROLE [' + @rol_asociado + '] DROP MEMBER [' + @nombre_usuario + '];';
				EXEC sp_executesql @sql_drop_role_member;
			END;

		--Eliminar el USER de la base de datos (si existe)
		DECLARE @sql_drop_user NVARCHAR(MAX);
		SET @sql_drop_user = '
			IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''' + @nombre_usuario + ''')
			BEGIN
				DROP USER [' + @nombre_usuario + '];
			END;';
		EXEC sp_executesql @sql_drop_user;

		-- Eliminar el LOGIN del servidor (si existe)
		DECLARE @sql_drop_login NVARCHAR(MAX);
		SET @sql_drop_login = '
			IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = ''' + @nombre_usuario + ''')
			BEGIN
				DROP LOGIN [' + @nombre_usuario + '];
			END;';
		EXEC sp_executesql @sql_drop_login;

		COMMIT TRANSACTION;
		PRINT 'Usuario eliminado con éxito.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
		THROW 50000, @msg, 1;
	END CATCH
END; 
GO