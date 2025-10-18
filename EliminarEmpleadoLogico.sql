CREATE OR ALTER PROCEDURE EliminarEmpleadoLogico
  @IDEmpleado   INT,
  @IDPostByUser INT = NULL,
  @IP           VARCHAR(64) = NULL,
  @OutResult    INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    BEGIN TRAN;

    -- 1. Desactivar el empleado
    UPDATE dbo.Empleado SET EsActivo = 0 WHERE Id = @IDEmpleado;

    -- 2. Obtener datos para bitácora
    DECLARE @Cedula VARCHAR(64);
    DECLARE @Nombre NVARCHAR(256);
    DECLARE @Puesto NVARCHAR(128);
    DECLARE @Saldo DECIMAL(10,2);
    
    SELECT 
      @Cedula = e.ValorDocumentoIdentidad,
      @Nombre = e.Nombre,
      @Puesto = p.Nombre,
      @Saldo = e.SaldoVacaciones
    FROM dbo.Empleado e 
    JOIN dbo.Puesto p ON p.Id = e.IdPuesto
    WHERE e.Id = @IDEmpleado;

    -- 3. Registrar en bitácora 
    DECLARE @Mensaje NVARCHAR(MAX);
    SET @Mensaje = CONCAT(
      N'Desactivación Lógica -> Cédula=', @Cedula,
      N'; Nombre=', @Nombre,
      N'; Puesto=', @Puesto,
      N'; Saldo=', @Saldo
    );

    EXEC InsertarBitacora 10, @Mensaje, @IDPostByUser, @IP;

    -- 4. Confirmar
    SET @OutResult = 0;
    COMMIT TRAN;

  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    
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
  END CATCH
END

GO
