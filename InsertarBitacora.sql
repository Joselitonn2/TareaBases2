CREATE PROCEDURE InsertarBitacora
  @IdTipoEvento INT,
  @Descripcion  NVARCHAR(1000) = NULL,
  @IdPostByUser INT = NULL,
  @PostInIP     VARCHAR(45) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO dbo.BitacoraEvento(IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
  VALUES(@IdTipoEvento, @Descripcion, @IdPostByUser, @PostInIP);
END
GO