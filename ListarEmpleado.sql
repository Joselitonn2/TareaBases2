CREATE OR ALTER PROCEDURE ListarEmpleado
  @TerminoBusqueda NVARCHAR(120) = NULL
AS
BEGIN
  SET NOCOUNT ON;


  IF @TerminoBusqueda IS NOT NULL AND LTRIM(RTRIM(@TerminoBusqueda)) = ''
  BEGIN
    SET @TerminoBusqueda = NULL;
  END


  DECLARE @FiltroLike NVARCHAR(122) = '%' + @TerminoBusqueda + '%';

  -- 3. Consulta principal
  SELECT TOP (200)
    e.Id, e.Nombre, e.ValorDocumentoIdentidad, e.SaldoVacaciones, p.Nombre AS Puesto
  FROM dbo.Empleado e
  JOIN dbo.Puesto p ON p.Id = e.IdPuesto
  WHERE 
    e.EsActivo = 1 
    AND (
      @TerminoBusqueda IS NULL -- Opci�n 1: No hay filtro
      OR
      -- Opci�n 2: Es un nombre
      (
        @TerminoBusqueda LIKE '%[A-Za-z�������������� ]%' 
        AND NOT @TerminoBusqueda LIKE '%[^A-Za-z�������������� ]%' 
        AND e.Nombre LIKE @FiltroLike
      )
      OR
      -- Opci�n 3: Es una c�dula
      (
        @TerminoBusqueda NOT LIKE '%[^0-9]%' 
        AND e.ValorDocumentoIdentidad LIKE @FiltroLike 
      )
    )
  ORDER BY e.Nombre ASC;

  -- 4. Registrar la b�squeda en la bit�cora
  IF @TerminoBusqueda IS NOT NULL
  BEGIN
    DECLARE @IDTipoEvento INT;
    
    IF @TerminoBusqueda NOT LIKE '%[^0-9]%'
      SET @IDTipoEvento = 12; -- Es C�dula
    ELSE
      SET @IDTipoEvento = 11; -- Es Nombre
    
    EXEC InsertarBitacora @IDTipoEvento, @TerminoBusqueda, NULL, NULL;
  END
END
GO