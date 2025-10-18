CREATE OR ALTER PROCEDURE InsertarMovimiento
  @IDEmpleado       INT,
  @IDTipoMovimiento INT,
  @Fecha            DATE,
  @Monto            DECIMAL(10, 2),
  @IDPostByUser     INT = NULL,
  @IP               VARCHAR(64) = NULL,
  @OutResult        INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  -- Variables
  DECLARE @TipoAccion NVARCHAR(16);
  DECLARE @SaldoActual DECIMAL(10, 2);
  DECLARE @NuevoSaldo DECIMAL(10, 2);

  BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Obtener datos 
    SELECT @TipoAccion = TipoAccion 
    FROM dbo.TipoMovimiento 
    WHERE Id = @IDTipoMovimiento;
    
    SELECT @SaldoActual = SaldoVacaciones 
    FROM dbo.Empleado 
    WHERE Id = @IDEmpleado;

    -- 2. Calcular nuevo saldo
    SET @NuevoSaldo = CASE 
        WHEN @TipoAccion = N'Credito' THEN @SaldoActual + @Monto 
        ELSE @SaldoActual - @Monto 
    END;

    -- 3. Validar regla de negocio
    IF @NuevoSaldo < 0
    BEGIN
      SET @OutResult = 50011; -- Saldo negativo

      DECLARE @DetalleError NVARCHAR(MAX);
      SET @DetalleError = N'Error ' + CAST(@OutResult AS NVARCHAR(10)) +
                          N'; EmpleadoId=' + CAST(@IDEmpleado AS NVARCHAR(20)) +
                          N'; TipoMovimiento=' + CAST(@IDTipoMovimiento AS NVARCHAR(20)) +
                          N'; Monto=' + CAST(@Monto AS NVARCHAR(32)) +
                          N'; SaldoPrevio=' + CAST(@SaldoActual AS NVARCHAR(32));

      -- Registra el error y revierte
      EXEC InsertarBitacora 13, @DetalleError, @IDPostByUser, @IP;
      ROLLBACK TRANSACTION;
      RETURN;
    END

    -- 4. Insertar el historial de movimiento
    INSERT INTO dbo.Movimiento(IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP)
    VALUES(@IDEmpleado, @IDTipoMovimiento, @Fecha, @Monto, @NuevoSaldo, @IDPostByUser, @IP);

    -- 5. Actualizar el saldo del empleado
    UPDATE dbo.Empleado SET SaldoVacaciones = @NuevoSaldo WHERE Id = @IDEmpleado;

    -- 6. Registrar éxito en bitácora
    DECLARE @DetalleExito NVARCHAR(MAX);
    SET @DetalleExito = N'EmpleadoId=' + CAST(@IDEmpleado AS NVARCHAR(20)) +
                        N'; TipoMovimiento=' + CAST(@IDTipoMovimiento AS NVARCHAR(20)) +
                        N'; Monto=' + CAST(@Monto AS NVARCHAR(32)) +
                        N'; NuevoSaldo=' + CAST(@NuevoSaldo AS NVARCHAR(32));

    EXEC InsertarBitacora 14, @DetalleExito, @IDPostByUser, @IP;

    -- 7. Confirmar y finalizar
    SET @OutResult = 0;
    COMMIT TRANSACTION;

  END TRY
  BEGIN CATCH
    -- 8. Manejo de errores
    ROLLBACK TRANSACTION; 
    SET @OutResult = 50008; -- Error general
    
    INSERT INTO dbo.DBError(UserName, Number, State, Severity, [Line], [Procedure], [Message])
    VALUES(SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE());
  END CATCH
END
GO