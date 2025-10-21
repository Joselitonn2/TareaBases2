CREATE OR ALTER PROCEDURE LoginUsuario
  @NombreUsuario  NVARCHAR(64),
  @Password       NVARCHAR(256),
  @IP             VARCHAR(64),
  @OutResult      INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  
  DECLARE @HoraActual DATETIME2 = SYSDATETIME();
  DECLARE @IdUsuarioEncontrado INT = (SELECT Id FROM dbo.Usuario WHERE Username = @NombreUsuario);
  DECLARE @IntentosFallidos INT;
  
  -- Revisar bloqueo
  SELECT @IntentosFallidos = COUNT(*) 
  FROM dbo.BitacoraEvento b
  JOIN dbo.TipoEvento te ON te.Id = b.IdTipoEvento AND te.Nombre IN ('Login No Exitoso', 'Login deshabilitado')
  WHERE (b.IdPostByUser = @IdUsuarioEncontrado OR (b.IdPostByUser IS NULL AND @IdUsuarioEncontrado IS NULL)) 
    AND b.PostInIP = @IP AND b.PostTime >= DATEADD(MINUTE,-5,@HoraActual);

  IF @IntentosFallidos > 5
  BEGIN
    SET @OutResult = 50003;
    EXEC InsertarBitacora 3, 'Bloqueo por intentos excesivos', @IdUsuarioEncontrado, @IP;
    
    SELECT @OutResult AS ResultCode, NULL AS UserID; 
    RETURN;
  END

  -- Validar si el usuario no existe
  IF @IdUsuarioEncontrado IS NULL
  BEGIN
    SET @OutResult = 50001;
    EXEC InsertarBitacora 2, 'Usuario no encontrado', NULL, @IP;
    
    SELECT @OutResult AS ResultCode, NULL AS UserID; 
    RETURN;
  END

  -- Validar contraseña
  IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Id = @IdUsuarioEncontrado AND [Password] = @Password)
  BEGIN
    SET @OutResult = 50002;
    EXEC InsertarBitacora 2, 'Contraseña inválida', @IdUsuarioEncontrado, @IP;
    
    SELECT @OutResult AS ResultCode, NULL AS UserID; 
    RETURN;
  END

  -- Éxito
  SET @OutResult = 0;
  EXEC InsertarBitacora 1, 'Login Exitoso', @IdUsuarioEncontrado, @IP;
  
  SELECT @OutResult AS ResultCode, @IdUsuarioEncontrado AS UserID; 
END
GO
