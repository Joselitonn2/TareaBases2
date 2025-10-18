CREATE OR ALTER PROCEDURE LoginUsuario
  @NombreUsuario  NVARCHAR(64),
  @Password     NVARCHAR(256),
  @IP    VARCHAR(64),
  @ResultadoCodigo INT OUTPUT -- 0 exito, 50001 user no existe, 50002 password invalida/incorrecta, 50003 deshabilitado
AS
BEGIN
  SET NOCOUNT ON;

  -- --- Declaración de variables ---
  DECLARE @HoraActual DATETIME2 = SYSUTCDATETIME();
  DECLARE @IdUsuarioEncontrado INT;

  -- 1. Buscar al usuario
  SET @IdUsuarioEncontrado = (SELECT Id FROM dbo.Usuario WHERE Username = @NombreUsuario);

  -- 2. Revisar bloqueo
  IF (
    SELECT COUNT(*)
    FROM dbo.BitacoraEvento b
    JOIN dbo.TipoEvento te ON te.Id = b.IdTipoEvento AND te.Nombre IN ('Login No Exitoso', 'Login deshabilitado')
    WHERE b.IdPostByUser = @IdUsuarioEncontrado
      AND b.PostInIP = @IP
      AND b.PostTime >= DATEADD(MINUTE, -5, @HoraActual)
  ) > 5
  BEGIN
    SET @ResultadoCodigo = 50003; -- Deshabilitado
    EXEC InsertarBitacora @IdTipoEvento = 3, -- <-- (Tu lógica de números)
                          @Descripcion  = 'Bloqueo por intentos excesivos',
                          @IdPostByUser = @IdUsuarioEncontrado,
                          @PostInIP     = @IP;
    RETURN;
  END



  -- 3. Validar si el usuario no existe
  IF @IdUsuarioEncontrado IS NULL
  BEGIN
    SET @ResultadoCodigo = 50001; -- Username no existe
    EXEC InsertarBitacora @IdTipoEvento = 2, -- <-- (Tu lógica de números)
                          @Descripcion  = 'Usuario no encontrado',
                          @IdPostByUser = NULL,
                          @PostInIP     = @IP;
    RETURN;
  END

  -- 4. Validar contraseña (el usuario SÍ existe)
  IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Id = @IdUsuarioEncontrado AND [Password] = @Password)
  BEGIN
    SET @ResultadoCodigo = 50002; -- Password incorrecta
    EXEC InsertarBitacora @IdTipoEvento = 2, -- <-- (Tu lógica de números)
                          @Descripcion  = 'Contraseña inválida',
                          @IdPostByUser = @IdUsuarioEncontrado,
                          @PostInIP     = @IP;
    RETURN;
  END

  -- 5. Éxito
  SET @ResultadoCodigo = 0;
  EXEC InsertarBitacora @IdTipoEvento = 1, -- <-- (Tu lógica de números)
                        @Descripcion  = NULL,
                        @IdPostByUser = @IdUsuarioEncontrado,
                        @PostInIP     = @IP;
END
GO