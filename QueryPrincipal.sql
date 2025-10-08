CREATE TABLE dbo.Empleados
(
    id INT IDENTITY (1, 1) PRIMARY KEY,
    Nombre VARCHAR(128) NOT NULL,
    Salario MONEY NOT NULL
);

INSERT dbo.Empleados (Nombre, Salario) VALUES ('Juan Perez', 250000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Maria Lopez', 310000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Carlos Ramirez', 280000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Ana Fernandez', 295000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Luis Gonzalez', 320000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Elena Rojas', 275000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Pedro Vargas', 330000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Laura Castro', 260000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Diego Morales', 310000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Gabriela Soto', 270000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Andres Herrera', 300000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Paula Jimenez', 285000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Roberto Solis', 340000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Adriana Marin', 265000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Manuel Ruiz', 315000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Sofia Cordero', 290000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Ricardo Arias', 325000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Daniela Pineda', 275000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Fernando Chaves', 305000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Natalia Vargas', 295000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Esteban Salazar', 310000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Carmen Alfaro', 270000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Oscar Quesada', 335000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Patricia Araya', 280000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Javier Acosta', 320000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Marcela Brenes', 265000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Guillermo Vargas', 345000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Karla Rojas', 285000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Alberto Jimenez', 310000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Monica Campos', 275000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Hector Lopez', 335000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Vanessa Solano', 295000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Felipe Muñoz', 300000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Isabel Navarro', 280000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Raul Mendez', 315000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Cristina Marin', 270000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Alejandro Vega', 340000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Teresa Campos', 290000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Mauricio Porras', 325000.00);
INSERT dbo.Empleados (Nombre, Salario) VALUES ('Liliana Cordero', 305000.00);

CREATE PROCEDURE dbo.ObtenerEmpleados
AS
BEGIN
    SET NOCOUNT ON;

    SELECT id, Nombre, Salario
    FROM dbo.Empleados
    ORDER BY Nombre ASC;
END;

CREATE OR ALTER PROCEDURE dbo.InsertarEmpleado
    @Nombre VARCHAR(128),
    @Salario MONEY
AS
BEGIN
    SET NOCOUNT ON;

   
    IF EXISTS (SELECT 1 FROM dbo.Empleados WHERE Nombre = @Nombre)
    BEGIN
        RAISERROR('Empleado ya existe.', 16, 1);
        RETURN -1;
    END;

    INSERT INTO dbo.Empleados (Nombre, Salario)
    VALUES (@Nombre, @Salario);

    RETURN 0;
END;

EXEC dbo.ObtenerEmpleados
EXEC dbo.InsertarEmpleado @Nombre = 'Alejandro Luna', @Salario = 350000.00;

