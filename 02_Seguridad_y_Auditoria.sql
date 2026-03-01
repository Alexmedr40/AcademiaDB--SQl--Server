-- SEGURIDAD DE LA BASE DE DATOS

/*Creacion de UsuarioLectura*/

CREATE LOGIN UsuarioLectura 
WITH PASSWORD = 'Segura123';
GO

CREATE USER UsuarioLectura
FOR LOGIN UsuarioLectura;
GO

GRANT SELECT ON DATABASE::AcademiaDB TO UsuarioLectura;
GO

/*Creacion de Auditoria*/

CREATE SERVER AUDIT Auditoria_EliminarCursos
TO FILE (FILEPATH = 'C:\Auditoria - Eliminacion de Cursos\')
GO

ALTER SERVER AUDIT Auditoria_EliminarCursos WITH(STATE = ON);
GO

CREATE DATABASE AUDIT SPECIFICATION Auditoria_Cursos
FOR SERVER AUDIT Auditoria_EliminarCursos
ADD(DELETE ON Cursos BY PUBLIC);
GO

ALTER DATABASE AUDIT SPECIFICATION Auditoria_Cursos WITH (STATE = ON);  
GO
