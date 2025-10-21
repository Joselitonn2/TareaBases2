CREATE OR ALTER PROCEDURE LogoutUsuario
  @IDPostByUser INT,
  @IP           VARCHAR(64),
  @OutResult    INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  
  BEGIN TRY
    
    -- Registra el evento de Logout
    EXEC InsertarBitacora 
           @IdTipoEvento = 4, 
           @Descripcion  = N'Cierre de sesión exitoso', 
           @IdPostByUser = @IDPostByUser, 
           @PostInIP     = @IP;
           
    SET @OutResult = 0;
    SELECT @OutResult AS ResultCode;

  END TRY
  BEGIN CATCH
    --InsertarBitacora falla
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
