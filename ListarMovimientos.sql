CREATE OR ALTER PROCEDURE ListarMovimientos
  @IdEmpleadoConsultar INT
AS
BEGIN

  SET NOCOUNT ON;
  SELECT m.Id, m.Fecha, tm.Nombre AS TipoMovimiento, m.Monto, m.NuevoSaldo,
         u.Username AS PostByUser, m.PostInIP, m.PostTime
  FROM dbo.Movimiento m
  JOIN dbo.TipoMovimiento tm ON tm.Id = m.IdTipoMovimiento
  LEFT JOIN dbo.Usuario u ON u.Id = m.IdPostByUser
  WHERE m.IdEmpleado = @IdEmpleadoConsultar
  ORDER BY m.Fecha DESC, m.Id DESC;

END
GO