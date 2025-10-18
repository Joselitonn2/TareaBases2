CREATE OR ALTER PROCEDURE EliminarEmpleadoFisico
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

    -- 1. Obtener datos para bit�cora (ANTES de borrar)
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

    -- 2. Borrar dependencias (movimientos)
    DELETE FROM dbo.Movimiento WHERE IdEmpleado = @IDEmpleado;
    
    -- 3. Borrar al empleado (Borrado F�sico)
    DELETE FROM dbo.Empleado WHERE Id = @IDEmpleado;

    -- 4. Registrar en bit�cora 
    DECLARE @Mensaje NVARCHAR(MAX);
    SET @Mensaje = CONCAT(
      N'Eliminaci�n f�sica -> C�dula=', @Cedula,
      N'; Nombre=', @Nombre,
      N'; Puesto=', @Puesto,
      N'; Saldo=', @Saldo
    );

    EXEC InsertarBitacora 10, @Mensaje, @IDPostByUser, @IP;

    -- 5. Confirmar
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