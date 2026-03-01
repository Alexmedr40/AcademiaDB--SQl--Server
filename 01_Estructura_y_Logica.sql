-- BASE DE DATOS:

CREATE DATABASE AcademiaDB
GO

USE AcademiaDB
GO

-- TABLAS:

/*Tabla Usuario*/

CREATE TABLE Usuarios (
ID INT PRIMARY KEY, 
Nombre NVARCHAR(50) NOT NULL, 
Email NVARCHAR(100) UNIQUE NOT NULL, 
Contraseña NVARCHAR(255) NOT NULL, 
Tipo NVARCHAR(20) CHECK (Tipo IN ('Alumno', 'Instructor')) NOT NULL -- Solo se pueden asignar estos dos valores: "Alumno" o "Instructor"
);
GO

/* Tabla Cursos*/

CREATE TABLE Cursos (
ID INT PRIMARY KEY, 
Nombre VARCHAR(100) NOT NULL, 
InstructorID INT NOT NULL, 
FOREIGN KEY (InstructorID) REFERENCES Usuarios(ID)
);
GO

-- Trigger para validar que solo instructores puedan ser asignados a cursos
CREATE TRIGGER T_ValidarInstructor
ON Cursos
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM inserted i -- 'inserted' contiene los registros recién insertados o actualizados
        JOIN Usuarios u ON i.InstructorID = u.ID -- Se une con la tabla Usuarios para verificar el tipo
        WHERE u.Tipo <> 'Instructor' -- Si el usuario no es 'Instructor', la validación fallará
    )
    BEGIN
	-- Si se encuentra un InstructorID inválido, se lanza un error
        RAISERROR ('Instructor debe ser de tipo "Instructor"', 16, 1);
		-- 16 = Severidad del error (16 indica error del usuario, no del sistema)
        -- 1 = Estado del error (puede ser cualquier número, generalmente usado para identificar el origen)

	-- Se revierte la transacción para evitar que se inserten datos incorrectos
        ROLLBACK TRANSACTION;
    END
END;
GO

/* Tabla Inscripciones */

CREATE TABLE Inscripciones (
ID INT PRIMARY KEY, 
CursoID INT NOT NULL, 
UsuarioID INT NOT NULL,
FOREIGN KEY (CursoID) REFERENCES Cursos(ID) ON DELETE CASCADE,
FOREIGN KEY (UsuarioID) REFERENCES Usuarios(ID),
);
GO

-- Trigger para validar que solo alumnos puedan inscribirse en cursos
CREATE TRIGGER T_ValidarAlumno
ON Inscripciones  -- Se aplica a la tabla Inscripciones
FOR INSERT, UPDATE  -- Se ejecuta en cada inserción o actualización
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM inserted i  -- 'inserted' contiene los registros recién insertados o actualizados
        JOIN Usuarios u ON i.UsuarioID = u.ID  -- Se une con la tabla Usuarios para verificar el tipo
        WHERE u.Tipo <> 'Alumno'  -- Si el usuario no es 'Alumno', la validación fallará
    )
    BEGIN
        -- Si se encuentra un UsuarioID inválido, se lanza un error
        RAISERROR ('Usuario debe ser de tipo "Alumno"', 16, 1);
        -- 16 = Severidad del error (16 indica error del usuario, no del sistema)
        -- 1 = Estado del error (puede ser cualquier número, generalmente usado para identificar el origen)
        
        -- Se revierte la transacción para evitar que se inserten datos incorrectos
        ROLLBACK TRANSACTION;
    END
END;
GO

-- PROCEDIMIENTOS ALMACENADOS:

-- Procedimiento: Insertar Usuario
CREATE PROCEDURE sp_InsertarUsuario
    @ID INT,
    @Nombre NVARCHAR(50),
    @Email NVARCHAR(100),
    @Contraseña NVARCHAR(255),
    @Tipo NVARCHAR(20)
AS
BEGIN
    INSERT INTO Usuarios (ID, Nombre, Email, Contraseña, Tipo)
    VALUES (@ID, @Nombre, @Email, @Contraseña, @Tipo);
END;
GO

-- Procedimiento: Insertar Curso
CREATE PROCEDURE sp_InsertarCurso
    @ID INT,
    @Nombre VARCHAR(100),
    @InstructorID INT
AS
BEGIN
    INSERT INTO Cursos (ID, Nombre, InstructorID)
    VALUES (@ID, @Nombre, @InstructorID);
END;
GO

-- Procedimiento: Insertar Inscripción
CREATE PROCEDURE sp_InsertarInscripcion
    @ID INT,
    @CursoID INT,
    @UsuarioID INT
AS
BEGIN
    INSERT INTO Inscripciones (ID, CursoID, UsuarioID)
    VALUES (@ID, @CursoID, @UsuarioID);
END;
GO

-- Procedimiento: Eliminar Curso
CREATE PROCEDURE sp_EliminarCurso
    @ID INT
AS
BEGIN
    DELETE FROM Cursos WHERE ID = @ID;
END;
GO

-- VISTAS:

CREATE VIEW V_Usuarios AS
SELECT 
    ID AS UsuarioID,
    Nombre AS NombreUsuario,
    Email,
    Tipo
FROM Usuarios;
GO

CREATE VIEW V_Cursos AS
SELECT 
    c.ID AS CursoID,
    c.Nombre AS NombreCurso,
    u.Nombre AS Instructor
FROM Cursos c
JOIN Usuarios u ON c.InstructorID = u.ID;
GO

CREATE VIEW V_Inscripciones AS
SELECT 
    i.ID AS InscripcionID,
    u.Nombre AS NombreAlumno,
    c.Nombre AS NombreCurso
FROM Inscripciones i
JOIN Usuarios u ON i.UsuarioID = u.ID
JOIN Cursos c ON i.CursoID = c.ID;
GO

CREATE VIEW V_Cursos_ConInscripciones AS
SELECT 
    c.ID AS CursoID,
    c.Nombre AS NombreCurso,
    COUNT(i.UsuarioID) AS TotalInscritos
FROM Cursos c
LEFT JOIN Inscripciones i ON c.ID = i.CursoID
GROUP BY c.ID, c.Nombre;
GO

SELECT * FROM V_Usuarios;
SELECT * FROM V_Cursos;
SELECT * FROM V_Inscripciones;
SELECT * FROM V_Cursos_ConInscripciones;
