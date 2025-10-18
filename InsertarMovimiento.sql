CREATE OR ALTER PROCEDURE InsertarMovimiento
  @IDEmpleado       INT,
  @IDTipoMovimiento INT,
  @Fecha            DATE,
  @Monto            DECIMAL(10,2),
  @IDPostByUser     INT = NULL,
  @IP               VARCHAR(64) = NULL,
  @OutResult        INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  -- Variables
  DECLARE 
    @Accion NVARCHAR(16),
    @SaldoPrevio DECIMAL(10,2),
    @SaldoFinal DECIMAL(10,2),
    @Mensaje NVARCHAR(MAX);

  BEGIN TRY
    BEGIN TRAN;

    -- Obtener información base 
    SELECT @Accion = TipoAccion
    FROM dbo.TipoMovimiento
    WHERE Id = @IDTipoMovimiento;

    SELECT @SaldoPrevio = SaldoVacaciones
    FROM dbo.Empleado
    WHERE Id = @IDEmpleado;

    --Calcular nuevo saldo según tipo de movimiento
    IF @Accion = N'Credito'
      SET @SaldoFinal = @SaldoPrevio + @Monto;
    ELSE
      SET @SaldoFinal = @SaldoPrevio - @Monto;

    -- Validar saldo negativo
    IF @SaldoFinal < 0
    BEGIN
      SET @OutResult = 50011;
      SET @Mensaje = CONCAT(
        'Error ', @OutResult,
        ' | Empleado=', @IDEmpleado,
        ' | TipoMov=', @IDTipoMovimiento,
        ' | Monto=', @Monto,
        ' | SaldoPrevio=', @SaldoPrevio
      );

      EXEC InsertarBitacora 
           @IdTipoEvento = 13,
           @Descripcion = @Mensaje,
           @IdPostByUser = @IDPostByUser,
           @PostInIP = @IP;

      ROLLBACK TRAN;
      RETURN;
    END

    -- Insertar movimiento
    INSERT INTO dbo.Movimiento
      (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP)
    VALUES
      (@IDEmpleado, @IDTipoMovimiento, @Fecha, @Monto, @SaldoFinal, @IDPostByUser, @IP);

    -- Actualizar saldo del empleado
    UPDATE dbo.Empleado
    SET SaldoVacaciones = @SaldoFinal
    WHERE Id = @IDEmpleado;

    -- Registrar éxito
    SET @Mensaje = CONCAT(
      'Empleado=', @IDEmpleado,
      ' | TipoMov=', @IDTipoMovimiento,
      ' | Monto=', @Monto,
      ' | NuevoSaldo=', @SaldoFinal
    );

    EXEC InsertarBitacora 
           @IdTipoEvento = 14,
           @Descripcion = @Mensaje,
           @IdPostByUser = @IDPostByUser,
           @PostInIP = @IP;

    -- Confirmar y finalizar
    SET @OutResult = 0;
    COMMIT TRAN;

  END TRY
  BEGIN CATCH
    ROLLBACK TRAN;

    SET @OutResult = 50008;

    INSERT INTO dbo.DBError(UserName, Number, State, Severity, [Line], [Procedure], [Message])
    VALUES (
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
