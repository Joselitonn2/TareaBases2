CREATE OR ALTER PROCEDURE ActualizarEmpleado
  @IDEmpleado         INT,
  @DocumentoIdentidad VARCHAR(64),
  @NombreCompleto     NVARCHAR(256),
  @IDPuesto           INT,
  @IDPostByUser       INT = NULL,
  @IP                 VARCHAR(64) = NULL,
  @OutResult          INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    BEGIN TRAN;

    -- 1. Validaciones de formato
    IF @DocumentoIdentidad LIKE '%[^0-9]%' BEGIN SET @OutResult = 50010; GOTO Fail; END;
    IF @NombreCompleto LIKE '%[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ .-]%' BEGIN SET @OutResult = 50009; GOTO Fail; END;

    -- 2. Validaciones de duplicados
    IF EXISTS(SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @DocumentoIdentidad AND Id <> @IDEmpleado) 
    BEGIN 
      SET @OutResult = 50006; GOTO Fail; 
    END;
    
    IF EXISTS(SELECT 1 FROM dbo.Empleado WHERE Nombre = @NombreCompleto AND Id <> @IDEmpleado) 
    BEGIN 
      SET @OutResult = 50007; GOTO Fail; 
    END;

    -- 3. Obtener datos "Antes" para bitácora
    DECLARE @CedulaAnterior VARCHAR(64);
    DECLARE @NombreAnterior NVARCHAR(256);
    DECLARE @PuestoAnterior NVARCHAR(128);

    SELECT 
      @CedulaAnterior = e.ValorDocumentoIdentidad, 
      @NombreAnterior = e.Nombre, 
      @PuestoAnterior = p.Nombre
    FROM dbo.Empleado e
    JOIN dbo.Puesto p ON p.Id = e.IdPuesto
    WHERE e.Id = @IDEmpleado;

    -- 4. Actualizar el empleado
    UPDATE dbo.Empleado
    SET ValorDocumentoIdentidad = @DocumentoIdentidad,
        Nombre = @NombreCompleto,
        IdPuesto = @IDPuesto
    WHERE Id = @IDEmpleado;

    -- 5. Registrar éxito en bitácora
    SET @OutResult = 0;
    
    DECLARE @PuestoNuevo NVARCHAR(128) = (SELECT Nombre FROM dbo.Puesto WHERE Id = @IDPuesto);
    DECLARE @MensajeExito NVARCHAR(MAX);
    
    SET @MensajeExito = CONCAT(
      N'Empleado actualizado. ID: ', @IDEmpleado,
      N' | Antes -> [Ced:', @CedulaAnterior, N', Nom:', @NombreAnterior, N', Puesto:', @PuestoAnterior, N']',
      N' | Despues -> [Ced:', @DocumentoIdentidad, N', Nom:', @NombreCompleto, N', Puesto:', @PuestoNuevo, N']'
    );

    EXEC InsertarBitacora 8, @MensajeExito, @IDPostByUser, @IP;

    COMMIT TRAN;
    SELECT @OutResult AS ResultCode;
    RETURN;

    -- 6. Ruta de fallo
    Fail:
      DECLARE @MensajeError NVARCHAR(MAX);
      SET @MensajeError = CONCAT(
        N'Error ', @OutResult,
        N'; Ced=', @DocumentoIdentidad,
        N'; Nombre=', @NombreCompleto,
        N'; PuestoId=', @IDPuesto
      );
      
      EXEC InsertarBitacora 7, @MensajeError, @IDPostByUser, @IP;
      ROLLBACK TRAN;
      SELECT @OutResult AS ResultCode;

  END TRY
  BEGIN CATCH
    -- 7. CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    
    SET @OutResult = 50008;

    
    INSERT INTO dbo.DBError(
        UserName, ErrorNumber, ErrorState, ErrorSeverity, 
        ErrorLine, ErrorProcedure, ErrorMessage
    )
    VALUES(
        SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), 
        ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE()
    );
    SELECT @OutResult AS ResultCode;
  END CATCH
END
GO
