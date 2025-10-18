USE Tarea2BD;
GO
PRINT 'Iniciando carga de Empleados (Paso 2)...';

BEGIN TRY
    DECLARE @xml XML;

    -- Leer XML
    SELECT @xml = TRY_CAST(BulkColumn AS XML)
    FROM OPENROWSET(
        BULK N'C:\TEMPORAL\DatosOrdenados.xml', -- <-- Tu ruta
        SINGLE_BLOB
    ) AS x;

    IF @xml IS NULL
        THROW 50020, 'No se pudo leer/parsing del XML (ver ruta/permisos/encoding).', 1;

    -- Verificar que Empleado.Id sea IDENTITY
    IF COLUMNPROPERTY(OBJECT_ID('dbo.Empleado'),'Id','IsIdentity') <> 1
        THROW 50022, 'dbo.Empleado.Id no es IDENTITY. Ajusta la tabla antes de insertar.', 1;

    -- --- INICIO DE LA CORRECCIÓN (NO MÁS TABLA TEMPORAL) ---
    
    -- 1. Declarar una VARIABLE de tabla
    DECLARE @PuestosSinMatch TABLE (
        PuestoXml NVARCHAR(128) PRIMARY KEY
    );

    -- 2. Llenar la VARIABLE de tabla
    ;WITH EmpXml AS (
        SELECT
            LTRIM(RTRIM(n.value('@Puesto','NVARCHAR(128)'))) AS PuestoXml
        FROM @xml.nodes('/Datos/Empleados/empleado') AS T(n)
    )
    INSERT INTO @PuestosSinMatch (PuestoXml)
    SELECT DISTINCT ex.PuestoXml
    FROM EmpXml ex
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Puesto p WHERE p.Nombre = ex.PuestoXml);

    -- 3. Revisar la VARIABLE de tabla (igual que antes)
    IF EXISTS (SELECT 1 FROM @PuestosSinMatch)
    BEGIN
        PRINT 'ATENCIÓN: Existen empleados con Puesto que no coincide con dbo.Puesto.Nombre. No se insertarán esas filas.';
        SELECT PuestoXml AS Puesto_No_Encontrado FROM @PuestosSinMatch;  -- para diagnóstico
    END
    -- --- FIN DE LA CORRECCIÓN ---

    -- Insertar empleados (Id autogenerado)
    ;WITH EmpXml AS (
        SELECT
            LTRIM(RTRIM(n.value('@Puesto','NVARCHAR(128)'))) AS PuestoXml,
            n.value('@ValorDocumentoIdentidad','VARCHAR(64)') AS Cedula,
            n.value('@Nombre','NVARCHAR(256)') AS Nombre,
            n.value('@FechaContratacion','DATE') AS FechaContratacion
        FROM @xml.nodes('/Datos/Empleados/empleado') AS T(n)
    )
    INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion)
    SELECT
        p.Id,
        e.Cedula,
        e.Nombre,
        e.FechaContratacion
    FROM EmpXml e
    JOIN dbo.Puesto p ON p.Nombre = e.PuestoXml -- Se salta los que no tienen puesto
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Empleado x
        WHERE x.ValorDocumentoIdentidad = e.Cedula
    );

    PRINT CONCAT('Empleados insertados: ', @@ROWCOUNT);

    -- (Ya no se necesita DROP TABLE)
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN; 
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @Num INT = ERROR_NUMBER(), @St INT = ERROR_STATE(), @Sev INT = ERROR_SEVERITY();
    RAISERROR('[Carga Empleados] %s (Err:%d, State:%d, Sev:%d)', 16, 1, @Msg, @Num, @St, @Sev);
END CATCH;
GO