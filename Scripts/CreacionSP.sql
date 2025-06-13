
use Com5600G10

go
--borrar
use Aplicada
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


CREATE PROCEDURE eSocios.AgregarOActualizarActividad
    @nombre_actividad NVARCHAR(50),
    @costo_mensual DECIMAL(10,2),
    @dias_horarios NVARCHAR(MAX) -- Formato: "lunes:08:00,10:00;miercoles:09:00;viernes:15:00,18:00"
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @id_actividad INT;
        
        -- crear o actualizar la actividad principal
        IF EXISTS (SELECT 1 FROM eSocios.Actividad WHERE nombre = @nombre_actividad)
        BEGIN
            -- actualizar actividad existente
            UPDATE eSocios.Actividad
            SET costo_mensual = @costo_mensual
            WHERE nombre = @nombre_actividad;
            
            SELECT @id_actividad = id_actividad FROM eSocios.Actividad WHERE nombre = @nombre_actividad;
            
            -- eliminar horarios anteriores para esta actividad
            DELETE FROM eSocios.ActividadHorarioDia WHERE id_actividad = @id_actividad;
        END

        ELSE
        BEGIN
            -- insertar nueva actividad
            INSERT INTO eSocios.Actividad (nombre, costo_mensual)
            VALUES (@nombre_actividad, @costo_mensual);
            
            SET @id_actividad = SCOPE_IDENTITY();
        END
        
        -- procesar dias y horarios
        DECLARE @dia_tabla TABLE (dia_nombre NVARCHAR(10), horarios NVARCHAR(MAX));
        DECLARE @dia_horario_tabla TABLE (dia_nombre NVARCHAR(10), hora TIME(0));
        
        -- primero separar los dias (eliminando espacios)
        INSERT INTO @dia_tabla (dia_nombre, horarios)
        SELECT 
            LTRIM(RTRIM(SUBSTRING(value, 1, CHARINDEX(':', value) - 1))) AS dia_nombre,
            LTRIM(RTRIM(SUBSTRING(value, CHARINDEX(':', value) + 1, LEN(value)))) AS horarios
        FROM STRING_SPLIT(REPLACE(REPLACE(@dias_horarios, ' ', ''), CHAR(13), ''), CHAR(10), ''), ';')
        WHERE value <> '';
        
        -- luego separar los horarios para cada día
        INSERT INTO @dia_horario_tabla (dia_nombre, hora)
        SELECT 
            dt.dia_nombre,
            CAST(CASE 
                WHEN LEN(horario.value) = 5 THEN horario.value + ':00' -- HH:MM
                WHEN LEN(horario.value) = 8 THEN horario.value -- HH:MM:SS
                ELSE '00:00:00' -- Valor por defecto si formato incorrecto
            END AS TIME(0)) AS hora
        FROM @dia_table dt
        CROSS APPLY STRING_SPLIT(dt.horarios, ',') horario
        WHERE horario.value <> '';
        
        -- validar días existentes
        IF EXISTS (
            SELECT 1 FROM @dia_horario_table dht
            LEFT JOIN eSocios.Dia d ON dht.dia_nombre = LOWER(d.nombre)
            WHERE d.id_dia IS NULL
        )
        BEGIN
            -- listar días no reconocidos
            DECLARE @dias_faltantes NVARCHAR(MAX) = (
                SELECT STRING_AGG(dia_nombre, ', ')
                FROM (
                    SELECT DISTINCT dht.dia_nombre
                    FROM @dia_horario_table dht
                    LEFT JOIN eSocios.Dia d ON dht.dia_nombre = LOWER(d.nombre)
                    WHERE d.id_dia IS NULL
                ) AS dias
            );
            
            THROW 50001, 'Los siguientes días no son válidos: ' + @dias_faltantes, 1;
        END
        
        -- Validar e insertar horarios si no existen
        INSERT INTO eSocios.Horario (id_horario, hora)
        SELECT 
            ROW_NUMBER() OVER (ORDER BY hora) + (SELECT ISNULL(MAX(id_horario), 0) FROM eSocios.Horario),
            hora
        FROM (
            SELECT DISTINCT dht.hora
            FROM @dia_horario_table dht
            LEFT JOIN eSocios.Horario h ON dht.hora = h.hora
            WHERE h.id_horario IS NULL
        ) AS nuevos_horarios;
        
        -- Insertar relaciones actividad-día-horario
        INSERT INTO eSocios.ActividadHorarioDia (id_actividad, id_dia, id_horario)
        SELECT 
            @id_actividad,
            d.id_dia,
            h.id_horario
        FROM @dia_horario_table dht
        JOIN eSocios.Dia d ON dht.dia_nombre = LOWER(d.nombre)
        JOIN eSocios.Horario h ON dht.hora = h.hora;
        
        COMMIT TRANSACTION;
        
        SELECT @id_actividad AS id_actividad_creada;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

-- Asignar actividad a socio
CREATE PROCEDURE eSocios.InscribirActividad
    @id_socio INT,
    @id_actividad INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que socio y actividad existen
        IF NOT EXISTS (SELECT 1 FROM eSocios.Socio WHERE id_socio = @id_socio)
            THROW 50001, 'El socio especificado no existe', 1;
            
        IF NOT EXISTS (SELECT 1 FROM eSocios.Actividad WHERE id_actividad = @id_actividad)
            THROW 50002, 'La actividad especificada no existe', 1;
            
        -- Insertar relación
        INSERT INTO eSocios.Realiza (socio, id_actividad)
        VALUES (@id_socio, @id_actividad);
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 2627 -- Violación de clave primaria
            THROW 50003, 'El socio ya está asignado a esta actividad', 1;
        ELSE
        BEGIN
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            THROW 50000, @ErrorMessage, 1;
        END
    END CATCH
END;
GO


-- eliminar actividad de socio
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





-- crear un nuevo grupo familiar asignando un adulto responsable
-- verifica que el adulto no tenga ya un grupo familiar asignado
CREATE PROCEDURE eSocios.CrearGrupoFamiliar
    @id_adulto_responsable INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- verificar que el socio existe y es mayor de edad
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
            
        -- verificar que el adulto no tenga ya un grupo familiar
        IF EXISTS (
            SELECT 1 
            FROM eSocios.GrupoFamiliar 
            WHERE id_adulto_responsable = @id_adulto_responsable
        )
            THROW 50003, 'El adulto ya es responsable de otro grupo familiar', 1;
            
     
        -- crear el grupo familiar con descuento por defecto del 15%
        INSERT INTO eSocios.GrupoFamiliar (id_adulto_responsable, descuento)
        VALUES (@nuevo_id_grupo, @id_adulto_responsable, 15.00);
        
        -- actualizar el socio para que pertenezca al grupo familiar
        UPDATE eSocios.Socio
        SET id_grupo_familiar = @nuevo_id_grupo
        WHERE id_socio = @id_adulto_responsable;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

-- agregar un miembro a un grupo familiar existente
-- verifica que el miembro no pertenezca ya a otro grupo
CREATE PROCEDURE eSocios.AgregarMiembroAGrupoFamiliar
    @id_grupo INT,
    @id_socio INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- verificar que el grupo existe
        IF NOT EXISTS (
            SELECT 1 
            FROM eSocios.GrupoFamiliar 
            WHERE id_grupo = @id_grupo
        )
            THROW 50001, 'El grupo familiar especificado no existe', 1;
            
        -- verificar que el socio existe
        IF NOT EXISTS (
            SELECT 1 
            FROM eSocios.Socio 
            WHERE id_socio = @id_socio
        )
            THROW 50002, 'El socio especificado no existe', 1;
            
        -- verificar que el socio no es ya el adulto responsable
        DECLARE @id_adulto_responsable INT;
        
        SELECT @id_adulto_responsable = id_adulto_responsable
        FROM eSocios.GrupoFamiliar
        WHERE id_grupo = @id_grupo;
        
        IF @id_socio = @id_adulto_responsable
            THROW 50003, 'El socio ya es el adulto responsable de este grupo', 1;
            
        -- verificar que el socio no pertenece ya a otro grupo
        IF EXISTS (
            SELECT 1 
            FROM eSocios.Socio 
            WHERE id_socio = @id_socio 
            AND id_grupo_familiar IS NOT NULL
            AND id_grupo_familiar != @id_grupo
        )
            THROW 50004, 'El socio ya pertenece a otro grupo familiar', 1;
            
        -- agregar el socio al grupo familiar
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
-- Insertar tutor para socio menor
CREATE PROCEDURE eSocios.InsertarTutor
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
        -- Validar que el socio existe y es menor de edad
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
            
        -- Insertar tutor
        INSERT INTO eSocios.Tutor (
            id_socio, nombre, apellido, email, fecha_nac, telefono, parentesco
        )
        VALUES (
            @id_socio, @nombre, @apellido, @email, @fecha_nac, @telefono, @parentesco
        );
        
        RETURN SCOPE_IDENTITY(); -- Retorna el ID del nuevo tutor
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
        -- verificar que el socio a tutelar existe y es menor
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
            
        -- verificar que el socio tutor existe y es mayor
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
            
        -- verificar que no sea ya tutor de este socio
        IF EXISTS (
            SELECT 1 
            FROM eSocios.Tutor 
            WHERE id_socio = @id_socio_menor 
            AND nombre = @nombre_tutor 
            AND apellido = @apellido_tutor
        )
            THROW 50005, 'Este socio ya es tutor del menor especificado', 1;
            
        -- insertar el tutor
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
END;
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
CREATE PROCEDURE eCobros.aplicarRecargoSegundoVencimiento
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
