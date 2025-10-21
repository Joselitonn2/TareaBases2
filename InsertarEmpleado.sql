CREATE OR ALTER PROCEDURE InsertarEmpleado
  @DocumentoIdentidad VARCHAR(64),   
  @NombreCompleto     NVARCHAR(256),  
  @IDPuesto           INT,
  @FechaContratacion  DATE,
  @IDPostByUser       INT = NULL,
  @IP                 VARCHAR(64) = NULL,   
  @IDNuevoEmpleado    INT OUTPUT,
  @OutResult          INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;


  -- 1. Validaciones de formato
  IF @DocumentoIdentidad LIKE '%[^0-9]%' BEGIN SET @OutResult = 50010; SELECT @OutResult AS ResultCode; RETURN; END;
  IF @NombreCompleto LIKE '%[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ .-]%' BEGIN SET @OutResult = 50009; SELECT @OutResult AS ResultCode; RETURN; END;

  -- 2. Validaciones de duplicados
  IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @DocumentoIdentidad) 
  BEGIN 
    SET @OutResult = 50004; SELECT @OutResult AS ResultCode; RETURN; 
  END;
  
  IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE Nombre = @NombreCompleto) 
  BEGIN 
    SET @OutResult = 50005; SELECT @OutResult AS ResultCode; RETURN; 
  END;

  -- 3. Transacción
  BEGIN TRY
    BEGIN TRAN;

    INSERT INTO dbo.Empleado(IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion)
    VALUES(@IDPuesto, @DocumentoIdentidad, @NombreCompleto, @FechaContratacion);

    -- Obtener el ID del nuevo empleado
    SET @IDNuevoEmpleado = SCOPE_IDENTITY();

    -- Registrar éxito en bitácora 
    DECLARE @Mensaje NVARCHAR(MAX);
    SET @Mensaje = CONCAT(
      N'Cédula: ', @DocumentoIdentidad,
      N'; Nombre: ', @NombreCompleto,
      N'; PuestoId: ', @IDPuesto
    );

    EXEC InsertarBitacora 6, @Mensaje, @IDPostByUser, @IP; 

    COMMIT TRAN;
    SET @OutResult = 0;
    SELECT @OutResult AS ResultCode;

  END TRY
  BEGIN CATCH
    ROLLBACK TRAN;
    
    SET @OutResult = 50008;
    
    INSERT INTO dbo.DBError(
        UserName, 
        ErrorNumber, 
        ErrorState, 
        ErrorSeverity, 
        ErrorLine, 
        ErrorProcedure, 
        ErrorMessage
    )
    VALUES(
        SUSER_SNAME(), 
        ERROR_NUMBER(), 
        ERROR_STATE(), 
        ERROR_SEVERITY(), 
        ERROR_LINE(), 
        ERROR_PROCEDURE(), 
        ERROR_MESSAGE()
    );
    SELECT @OutResult AS ResultCode;
  END CATCH
END
GO
