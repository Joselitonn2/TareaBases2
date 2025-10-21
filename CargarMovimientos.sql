USE Tarea2BD;
GO
PRINT 'Iniciando carga de Movimientos';
SET NOCOUNT ON;

BEGIN TRY
    DECLARE @xml XML;
    DECLARE @OutResult INT;

    -- 1. Leer el archivo XML
    SELECT @xml = TRY_CAST(BulkColumn AS XML)
    FROM OPENROWSET(
        BULK N'C:\TEMPORAL\DatosOrdenados.xml',
        SINGLE_BLOB
    ) AS x;

    IF @xml IS NULL
        THROW 50020, 'No se pudo leer el XML', 1;

    PRINT 'XML leído.';

    -- 2. Crear una VARIABLE de tabla para almacenar los movimientos del XML
    DECLARE @MovimientosParaCargar TABLE (
        FilaID INT IDENTITY(1,1) PRIMARY KEY,
        DocIdentidad VARCHAR(64),
        IDTipoMovimiento INT,
        Fecha DATE,
        Monto DECIMAL(10,2),
        Username NVARCHAR(64),
        IP VARCHAR(64)
    );

    -- 3. Llenar la variable de tabla, ordenando por la fecha y hora
    INSERT INTO @MovimientosParaCargar (DocIdentidad, IDTipoMovimiento, Fecha, Monto, Username, IP)
    SELECT
        n.value('@ValorDocId','VARCHAR(64)'),
        n.value('@IdTipoMovimiento','INT'),
        n.value('@Fecha','DATE'),
        n.value('@Monto','DECIMAL(10, 2)'),
        n.value('@PostByUser','NVARCHAR(64)'),
        n.value('@PostInIP','VARCHAR(64)')
    FROM @xml.nodes('/Datos/Movimientos/movimiento') AS T(n)
    ORDER BY n.value('@PostTime','DATETIME'); -- Orden cronológico

    -- 4. Iniciar el Bucle WHILE
    DECLARE @Contador INT = 1;
    DECLARE @TotalMovimientos INT = (SELECT COUNT(*) FROM @MovimientosParaCargar);
    
    -- Variables para guardar los datos de CADA movimiento en el bucle
    DECLARE @DocIdentidad VARCHAR(64), @IDTipoMov INT, @Fecha DATE, @Monto DECIMAL(10,2), @Username NVARCHAR(64), @IP VARCHAR(64);

    WHILE @Contador <= @TotalMovimientos
    BEGIN
        -- 4A. Leer la fila actual de la variable de tabla
        SELECT
            @DocIdentidad = DocIdentidad,
            @IDTipoMov = IDTipoMovimiento,
            @Fecha = Fecha,
            @Monto = Monto,
            @Username = Username,
            @IP = IP
        FROM @MovimientosParaCargar
        WHERE FilaID = @Contador;

        PRINT CONCAT(N'  -> Simulando [', @Fecha, N'] Movimiento de ', @Monto, ' para: ', @DocIdentidad);

        -- 4B. Traducir Cédula a IDEmpleado y Username a IDUsuario
        DECLARE @IDEmpleado INT = (SELECT Id FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @DocIdentidad);
        DECLARE @IDUsuario INT = (SELECT Id FROM dbo.Usuario WHERE Username = @Username);
        
        IF @IDEmpleado IS NULL OR @IDUsuario IS NULL
        BEGIN
            PRINT CONCAT('     ADVERTENCIA: No se encontró Empleado (', @DocIdentidad, ') o Usuario (', @Username, '). Omitiendo movimiento.');
        END
        ELSE
        BEGIN
            -- 4C. LLAMAR AL STORED PROCEDURE
            EXEC dbo.InsertarMovimiento
                @IDEmpleado = @IDEmpleado,
                @IDTipoMovimiento = @IDTipoMov,
                @Fecha = @Fecha,
                @Monto = @Monto,
                @IDPostByUser = @IDUsuario,
                @IP = @IP,
                @OutResult = @OutResult OUTPUT;

            -- 4D. Validar el resultado del SP
            IF @OutResult <> 0
            BEGIN
                -- Si el SP devuelve un error
                DECLARE @ErrorMsg NVARCHAR(512) = (SELECT Descripcion FROM dbo.Error WHERE Codigo = @OutResult);
                PRINT CONCAT('     ---> ¡ERROR! El SP devolvió el código ', @OutResult, ' (', ISNULL(@ErrorMsg, 'Descripción no encontrada'), '). Omitiendo este movimiento.');
            END
        END

        -- 4E. Incrementar el contador para pasar a la siguiente fila
        SET @Contador = @Contador + 1;
    END

    PRINT '... Simulación de carga de movimientos finalizada (con posibles errores omitidos).';

END TRY
BEGIN CATCH
    -- Este CATCH ahora solo se activará si hay un error GRAVE
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @Num INT = ERROR_NUMBER(), @St INT = ERROR_STATE(), @Sev INT = ERROR_SEVERITY();
    RAISERROR('[Carga Movimientos con SP-WHILE] %s (Err:%d, State:%d, Sev:%d)', 16, 1, @Msg, @Num, @St, @Sev);
END CATCH;
GO