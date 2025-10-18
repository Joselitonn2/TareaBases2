USE Tarea2BD; -- 1. Asegúrate de estar en la base de datos correcta
GO

SET NOCOUNT ON;
PRINT 'Iniciando carga de catálogos (Paso 1)...';

BEGIN TRY
    DECLARE @xml XML;
    DECLARE @RowCount INT;

    -- 2. Leer el archivo XML desde la ruta especificada
    SELECT @xml = TRY_CAST(BulkColumn AS XML)
    FROM OPENROWSET(
        BULK N'C:\TEMPORAL\DatosOrdenados.xml', -- <-- Esta es tu ruta
        SINGLE_BLOB
    ) AS x;

    -- 3. Validar que el XML se haya leído
    IF @xml IS NULL
        THROW 50020, 'No se pudo leer el XML (Revisa la ruta o permisos de C:\TEMPORAL)', 1;

    PRINT 'XML leído correctamente.';

    -- 4. Cargar Puestos
    -- (Tu script de Empleado DEPENDE de esto)
    MERGE INTO dbo.Puesto AS Target
    USING (
        SELECT
            n.value('@Nombre','NVARCHAR(128)') AS Nombre,
            n.value('@SalarioxHora','DECIMAL(10, 2)') AS Salario
        FROM @xml.nodes('/Datos/Puestos/Puesto') AS T(n)
    ) AS Source
    ON Target.Nombre = Source.Nombre -- Evita duplicados por nombre
    WHEN NOT MATCHED THEN
        INSERT (Nombre, SalarioxHora)
        VALUES (Source.Nombre, Source.Salario);
    
    SET @RowCount = @@ROWCOUNT;
    PRINT CONCAT('...Puestos insertados/actualizados: ', @RowCount);

    -- 5. Cargar Tipos de Evento
    -- (Tus SPs DEPENDEN de esto)
    MERGE INTO dbo.TipoEvento AS Target
    USING (
        SELECT
            n.value('@Id','INT') AS Id,
            n.value('@Nombre','NVARCHAR(128)') AS Nombre
        FROM @xml.nodes('/Datos/TiposEvento/TipoEvento') AS T(n)
    ) AS Source
    ON Target.Id = Source.Id -- Coincide por Id
    WHEN NOT MATCHED THEN
        INSERT (Id, Nombre) VALUES (Source.Id, Source.Nombre)
    WHEN MATCHED THEN
        UPDATE SET Target.Nombre = Source.Nombre;

    SET @RowCount = @@ROWCOUNT;
    PRINT CONCAT('...Tipos de Evento insertados/actualizados: ', @RowCount);

    -- 6. Cargar Tipos de Movimiento
    -- (Tus SPs y Movimientos DEPENDEN de esto)
    MERGE INTO dbo.TipoMovimiento AS Target
    USING (
        SELECT
            n.value('@Id','INT') AS Id,
            n.value('@Nombre','NVARCHAR(128)') AS Nombre,
            n.value('@TipoAccion','NVARCHAR(16)') AS TipoAccion
        FROM @xml.nodes('/Datos/TiposMovimientos/TipoMovimiento') AS T(n)
    ) AS Source
    ON Target.Id = Source.Id -- Coincide por Id
    WHEN NOT MATCHED THEN
        INSERT (Id, Nombre, TipoAccion) 
        VALUES (Source.Id, Source.Nombre, Source.TipoAccion)
    WHEN MATCHED THEN
        UPDATE SET Target.Nombre = Source.Nombre, Target.TipoAccion = Source.TipoAccion;
    
    SET @RowCount = @@ROWCOUNT;
    PRINT CONCAT('...Tipos de Movimiento insertados/actualizados: ', @RowCount);

    -- 7. Cargar Usuarios
    -- (Tus SPs y Movimientos DEPENDEN de esto)
    MERGE INTO dbo.Usuario AS Target
    USING (
        SELECT
            n.value('@Id','INT') AS Id,
            n.value('@Nombre','NVARCHAR(64)') AS Username,
            n.value('@Pass','NVARCHAR(256)') AS Password
        FROM @xml.nodes('/Datos/Usuarios/usuario') AS T(n)
    ) AS Source
    ON Target.Id = Source.Id -- Coincide por Id
    WHEN NOT MATCHED THEN
        INSERT (Id, Username, Password) 
        VALUES (Source.Id, Source.Username, Source.Password)
    WHEN MATCHED THEN
        UPDATE SET Target.Username = Source.Username, Target.Password = Source.Password;

    SET @RowCount = @@ROWCOUNT;
    PRINT CONCAT('...Usuarios insertados/actualizados: ', @RowCount);

    -- 8. Cargar Errores
    -- (Tus SPs usan estos códigos)
    MERGE INTO dbo.Error AS Target
    USING (
        SELECT
            n.value('@Codigo','INT') AS Codigo,
            n.value('@Descripcion','NVARCHAR(512)') AS Descripcion
        FROM @xml.nodes('/Datos/Error/errorCodigo') AS T(n)
    ) AS Source
    ON Target.Codigo = Source.Codigo -- Coincide por Codigo
    WHEN NOT MATCHED THEN
        INSERT (Codigo, Descripcion) 
        VALUES (Source.Codigo, Source.Descripcion)
    WHEN MATCHED THEN
        UPDATE SET Target.Descripcion = Source.Descripcion;
    
    SET @RowCount = @@ROWCOUNT;
    PRINT CONCAT('...Errores insertados/actualizados: ', @RowCount);
    
    PRINT 'Carga de catálogos finalizada.'

END TRY
BEGIN CATCH
    -- 9. Manejo de Errores
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @Num INT = ERROR_NUMBER(), @St INT = ERROR_STATE(), @Sev INT = ERROR_SEVERITY();
    RAISERROR('[Carga Catálogos] %s (Err:%d, State:%d, Sev:%d)', 16, 1, @Msg, @Num, @St, @Sev);
END CATCH;
GO