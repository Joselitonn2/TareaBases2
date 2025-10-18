CREATE OR ALTER PROCEDURE InsertarBitacora
  @IdTipoEvento INT,
  @Descripcion  NVARCHAR(MAX) = NULL,
  @IdPostByUser INT = NULL,
  @PostInIP     VARCHAR(64) = NULL
AS
BEGIN

  SET NOCOUNT ON;
  INSERT INTO dbo.BitacoraEvento(IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
  VALUES(@IdTipoEvento, @Descripcion, @IdPostByUser, @PostInIP);

END
GO
