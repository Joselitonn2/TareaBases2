SET NOCOUNT ON;

CREATE TABLE Puesto (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(128) NOT NULL UNIQUE,
    SalarioxHora DECIMAL(10, 2) NOT NULL
);

CREATE TABLE TipoMovimiento (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(128) NOT NULL UNIQUE,
    TipoAccion VARCHAR(16) NOT NULL CHECK (TipoAccion IN ('Credito', 'Debito'))
);

CREATE TABLE Usuario (
    Id INT PRIMARY KEY,
    Username VARCHAR(64) NOT NULL UNIQUE,
    Password VARCHAR(256) NOT NULL
);

CREATE TABLE TipoEvento (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE Error (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Codigo INT NOT NULL UNIQUE,
    Descripcion VARCHAR(512) NOT NULL
);

CREATE TABLE Empleado (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdPuesto INT NOT NULL,
    ValorDocumentoIdentidad VARCHAR(64) NOT NULL UNIQUE,
    Nombre VARCHAR(256) NOT NULL UNIQUE,
    FechaContratacion DATE NOT NULL DEFAULT GETDATE(),
    SaldoVacaciones DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    EsActivo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Empleado_Puesto FOREIGN KEY (IdPuesto) REFERENCES Puesto(Id)
);

CREATE TABLE BitacoraEvento (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdTipoEvento INT NOT NULL,
    Descripcion VARCHAR(MAX),
    IdPostByUser INT,
    PostInIP VARCHAR(64) NOT NULL,
    PostTime DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Bitacora_TipoEvento FOREIGN KEY (IdTipoEvento) REFERENCES TipoEvento(Id),
    CONSTRAINT FK_Bitacora_Usuario FOREIGN KEY (IdPostByUser) REFERENCES Usuario(Id)
);

CREATE TABLE Movimiento (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdEmpleado INT NOT NULL,
    IdTipoMovimiento INT NOT NULL,
    Fecha DATE NOT NULL DEFAULT GETDATE(),
    Monto DECIMAL(10, 2) NOT NULL,
    NuevoSaldo DECIMAL(10, 2) NOT NULL,
    IdPostByUser INT NOT NULL,
    PostInIP VARCHAR(64) NOT NULL,
    PostTime DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Movimiento_Empleado FOREIGN KEY (IdEmpleado) REFERENCES Empleado(Id),
    CONSTRAINT FK_Movimiento_TipoMovimiento FOREIGN KEY (IdTipoMovimiento) REFERENCES TipoMovimiento(Id),
    CONSTRAINT FK_Movimiento_Usuario FOREIGN KEY (IdPostByUser) REFERENCES Usuario(Id)
);

CREATE TABLE DBError (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    UserName VARCHAR(128),
    ErrorNumber INT,
    ErrorState INT,
    ErrorSeverity INT,
    ErrorLine INT,
    ErrorProcedure VARCHAR(MAX),
    ErrorMessage VARCHAR(MAX),
    ErrorDateTime DATETIME DEFAULT GETDATE()
);
