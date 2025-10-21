USE Tarea2BD;
GO
PRINT 'Iniciando carga de Empleados';
SET NOCOUNT ON;

BEGIN TRY
    DECLARE @xml XML;
    DECLARE @OutResult INT;
    DECLARE @IDNuevoEmpleado INT;

    -- Leer el archivo XML
    SELECT @xml = TRY_CAST(BulkColumn AS XML)
    FROM OPENROWSET(
        BULK N'C:\TEMPORAL\DatosOrdenados.xml',
        SINGLE_BLOB
    ) AS x;

    IF @xml IS NULL
        THROW 50020, 'No se pudo leer el XML', 1;

    PRINT 'XML leído.';

    
    DECLARE @AdminUserID INT = (SELECT Id FROM dbo.Usuario WHERE Username = 'UsuarioScripts');
    DECLARE @AdminUserIP VARCHAR(64) = '127.0.0.1';

    IF @AdminUserID IS NULL
        THROW 50021, 'No se encontró el usuario', 1;

    -- 1. Crear una VARIABLE de tabla para almacenar los empleados del XML
    DECLARE @EmpleadosParaCargar TABLE (
        FilaID INT IDENTITY(1,1) PRIMARY KEY, -- Fila para el bucle
        Documento VARCHAR(64),
        Nombre NVARCHAR(256),
        PuestoNombre NVARCHAR(128),
        Fecha DATE
    );

    -- 2. Llenar la variable de tabla, ordenando por fecha de contratación
    INSERT INTO @EmpleadosParaCargar (Documento, Nombre, PuestoNombre, Fecha)
    SELECT
        n.value('@ValorDocumentoIdentidad','VARCHAR(64)'),
        n.value('@Nombre','NVARCHAR(256)'),
        n.value('@Puesto','NVARCHAR(128)'),
        n.value('@FechaContratacion','DATE')
    FROM @xml.nodes('/Datos/Empleados/empleado') AS T(n)
    ORDER BY n.value('@FechaContratacion','DATE');

    -- 3. Iniciar el Bucle WHILE
    DECLARE @Contador INT = 1;
    DECLARE @TotalEmpleados INT = (SELECT COUNT(*) FROM @EmpleadosParaCargar);
    
    -- Variables para guardar los datos de CADA empleado en el bucle
    DECLARE @Documento VARCHAR(64), @Nombre NVARCHAR(256), @PuestoNombre NVARCHAR(128), @Fecha DATE;

    WHILE @Contador <= @TotalEmpleados
    BEGIN
        --Leer la fila actual de la variable de tabla
        SELECT
            @Documento = Documento,
            @Nombre = Nombre,
            @PuestoNombre = PuestoNombre,
            @Fecha = Fecha
        FROM @EmpleadosParaCargar
        WHERE FilaID = @Contador;

        PRINT CONCAT(N'  -> Simulando [', @Fecha, N'] Contratación de: ', @Nombre);

        --Traducir el Nombre del Puesto a su ID numérico
        DECLARE @IDPuesto INT = (SELECT Id FROM dbo.Puesto WHERE Nombre = @PuestoNombre);
        
        IF @IDPuesto IS NULL
        BEGIN
            PRINT CONCAT('No se encontró el puesto "', @PuestoNombre, '". Omitiendo este empleado.');
        END
        ELSE
        BEGIN
            --llamar SP
            EXEC dbo.InsertarEmpleado
                @DocumentoIdentidad = @Documento,
                @NombreCompleto = @Nombre,
                @IDPuesto = @IDPuesto,
                @FechaContratacion = @Fecha,
                @IDPostByUser = @AdminUserID,
                @IP = @AdminUserIP,
                @IDNuevoEmpleado = @IDNuevoEmpleado OUTPUT,
                @OutResult = @OutResult OUTPUT;

            --Validar el resultado del SP
            IF @OutResult <> 0
            BEGIN
                DECLARE @ErrorMsg NVARCHAR(512) = (SELECT Descripcion FROM dbo.Error WHERE Codigo = @OutResult);
                THROW 50030, @ErrorMsg, 1;
            END
        END

        --Incrementar el contador para pasar a la siguiente fila
        SET @Contador = @Contador + 1;
    END

    PRINT 'carga de empleados finalizada exitosamente.';

END TRY
BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @Num INT = ERROR_NUMBER(), @St INT = ERROR_STATE(), @Sev INT = ERROR_SEVERITY();
    RAISERROR('[Carga Empleados] %s (Err:%d, State:%d, Sev:%d)', 16, 1, @Msg, @Num, @St, @Sev);
END CATCH;
GO
