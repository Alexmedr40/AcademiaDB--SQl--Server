/*Valores en las Tablas*/

-- Instructores
EXEC sp_InsertarUsuario 1, 'María Pérez', 'maria.perez@academia.com', 'pass123', 'Instructor';
GO

EXEC sp_InsertarUsuario 2, 'Carlos García', 'carlos.garcia@academia.com', 'pass123', 'Instructor';
GO

-- Alumnos
EXEC sp_InsertarUsuario 3, 'Ana Torres', 'ana.torres@academia.com', 'pass123', 'Alumno';
GO

EXEC sp_InsertarUsuario 4, 'Luis Gómez', 'luis.gomez@academia.com', 'pass123', 'Alumno';
GO

EXEC sp_InsertarUsuario 5, 'Sofía Mendoza', 'sofia.mendoza@academia.com', 'pass123', 'Alumno';
GO

EXEC sp_InsertarCurso 1, 'Introducción a Bases de Datos', 1;
GO

EXEC sp_InsertarCurso 2, 'Seguridad en SQL Server', 2;
GO

EXEC sp_InsertarInscripcion 1, 1, 3; -- Ana en Introducción a BD
GO

EXEC sp_InsertarInscripcion 2, 1, 4; -- Luis en Introducción a BD
GO

EXEC sp_InsertarInscripcion 3, 2, 5; -- Sofía en Seguridad
GO

EXEC sp_InsertarUsuario 
    @ID = 6, 
    @Nombre = 'Carlos Pérez', 
    @Email = 'carlos@email.com', 
    @Contraseña = 'abc123', 
    @Tipo = 'Alumno';
GO

EXEC sp_InsertarUsuario 
    @ID = 7, 
    @Nombre = 'Laura Gómez', 
    @Email = 'laura@email.com', 
    @Contraseña = 'abc456', 
    @Tipo = 'Instructor';
GO

EXEC sp_InsertarCurso 
    @ID = 7, 
    @Nombre = 'Base de Datos Avanzado', 
    @InstructorID = 7;  -- Laura Gómez es Instructor
GO

-- PRUEBAS:

/*Pruebas de las Restricciones*/

SELECT * FROM Usuarios
SELECT * FROM Cursos
SELECT * FROM Inscripciones



/* =============================
   PRUEBA: Intento de asignar un Alumno como Instructor del curso (Debe fallar)
   ============================= */
EXEC sp_InsertarCurso 
    @ID = 6, 
    @Nombre = 'Curso Inválido', 
    @InstructorID = 6;  -- Carlos Pérez es Alumno, no debería poder crear el curso
GO

/* =============================
   PRUEBA: Intento de inscribir a un Instructor como Alumno (Debe fallar)
   ============================= */
EXEC sp_InsertarInscripcion 
    @ID = 6, 
    @CursoID = 7, 
    @UsuarioID = 7;  -- Laura Gómez es Instructor, no puede inscribirse como Alumno
GO

/*Pruebas del User*/

/* =============================
  Validar seguridad de UsuarioLectura (no puede insertar datos)
   ============================= */
EXECUTE AS USER = 'UsuarioLectura';
GO
-- Esto debe fallar por falta de permisos:
BEGIN TRY
    INSERT INTO Usuarios (ID, Nombre, Email, Contraseña, Tipo) 
    VALUES (12, 'Usuario Prueba', 'prueba@email.com', 'clave123', 'Alumno');
END TRY
BEGIN CATCH
    PRINT 'Error esperado: UsuarioLectura no tiene permisos de escritura.';
END CATCH;
GO

REVERT;
GO
/*Pruebas de la Auditoria*/

/* =============================
   🔹 PRUEBA: Eliminar Curso y verificar ON DELETE CASCADE + Auditoría
   ============================= */
SELECT * FROM Usuarios
SELECT * FROM Cursos
SELECT * FROM Inscripciones

-- Insertar nuevo curso para prueba
EXEC sp_InsertarCurso 3, 'Curso para Auditoría', 1;

-- Inscribir un alumno
EXEC sp_InsertarInscripcion 4, 3, 3;  -- Ana se inscribe

-- Eliminar curso usando el procedimiento
EXEC sp_EliminarCurso @ID = 3;

-- Verificar que el curso fue eliminado
SELECT * FROM Cursos WHERE ID = 3;

-- Verificar que la inscripción fue eliminada
SELECT * FROM Inscripciones WHERE CursoID = 3;

SELECT event_time, action_id, statement, object_name, database_name, server_principal_name
FROM sys.fn_get_audit_file('C:\Auditoria - Eliminacion de Cursos\*.sqlaudit', DEFAULT, DEFAULT)
ORDER BY event_time DESC;

-- Consultar el archivo de auditoría para verificar que la eliminación fue registrada
SELECT * 
FROM sys.fn_get_audit_file('C:\Auditoria - Eliminacion de Cursos\*.sqlaudit', DEFAULT, DEFAULT);
GO

/*Pruebas del Job */

/* =============================
   🔹 PRUEBA: Verificar existencia del Job
   ============================= */

USE msdb;
GO

SELECT name, enabled
FROM sysjobs
WHERE name = 'Respaldo_AcademiaDB';
GO

/* =============================
   🔹 PRUEBA: Verificar los pasos del Job
   ============================= */

USE msdb;
GO

EXEC sp_help_jobstep @job_name = 'Respaldo_AcademiaDB';
GO

/* =============================
   🔹 PRUEBA: Ejecutar el Job manualmente
   ============================= */

EXEC msdb.dbo.sp_start_job @job_name = 'Respaldo_AcademiaDB';
GO

-- Ver último resultado del job
SELECT TOP 1 job_id, run_date, run_time, run_status
FROM msdb.dbo.sysjobhistory
WHERE job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'Respaldo_AcademiaDB')
ORDER BY run_date DESC, run_time DESC;
GO

/*Pruebas del Plan de Mantenimiento (Punto 4)*/

/* =============================
   🔹 PRUEBA: Verificar que el plan existe
   ============================= */

USE msdb;
GO

SELECT name, description
FROM sysmaintplan_plans
WHERE name = 'Plan_Mantenimiento_AcademiaDB';
GO

/* =============================
   🔹 PRUEBA: Ejecutar manualmente el plan
   ============================= */

EXEC msdb.dbo.sp_start_job @job_name = 'Plan_Mantenimiento_AcademiaDB.Subplan_1';
GO

SELECT TOP 1 run_date, run_time, run_status
FROM msdb.dbo.sysjobhistory
WHERE job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'Plan_Mantenimiento_AcademiaDB.Subplan_1')
ORDER BY run_date DESC, run_time DESC;
GO

/*Pruebas de la Alerta (Punto 5)*/

/* =============================
   🔹 PRUEBA: Verificar que la Alerta existe
   ============================= */
USE msdb;
GO

SELECT name, enabled
FROM msdb.dbo.sysalerts
WHERE name = 'AlertaEspacioDiscoCritico';
GO

/*Pruebas de las Vistas de Gestion Dinamica (Punto 6)*/

-- ¿Qué tan utilizados están los índices en AcademiaDB?
SELECT 
    OBJECT_NAME(s.object_id, DB_ID('AcademiaDB')) AS Tabla,
    i.name AS Nombre_Indice,
    s.user_seeks AS Busquedas,
    s.user_scans AS Escaneos,
    s.user_lookups AS Lookups,
    s.user_updates AS Actualizaciones
FROM sys.dm_db_index_usage_stats s
JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE database_id = DB_ID('AcademiaDB');
GO

-- Consultas que se están ejecutando actualmente en SQL Server
SELECT 
    session_id, 
    status, 
    command, 
    database_id, 
    start_time,
    blocking_session_id
FROM sys.dm_exec_requests
WHERE database_id = DB_ID('AcademiaDB');
GO

-- Estadísticas de tamaño y número de filas por tabla en AcademiaDB
SELECT 
    OBJECT_NAME(object_id) AS Tabla,
    SUM(row_count) AS Filas,
    SUM(reserved_page_count) * 8 AS TamañoKB_Reservado,
    SUM(used_page_count) * 8 AS TamañoKB_Usado
FROM sys.dm_db_partition_stats
WHERE OBJECT_NAME(object_id) IN ('Usuarios', 'Cursos', 'Inscripciones')
GROUP BY object_id;
GO

-- Bloqueos activos en la base de datos AcademiaDB
SELECT 
    request_session_id AS Sesion,
    resource_type AS TipoRecurso,
    resource_description AS Recurso,
    request_mode AS ModoBloqueo,
    request_status AS Estado
FROM sys.dm_tran_locks
WHERE resource_database_id = DB_ID('AcademiaDB');
GO

-- Consultas ejecutadas recientemente con sus estadísticas
SELECT 
    TOP 5
    qs.execution_count AS VecesEjecutada,
    qs.total_logical_reads AS Lecturas,
    qs.total_worker_time AS TiempoCPU,
    SUBSTRING(st.text, 1, 200) AS Consulta
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_worker_time DESC;
GO

/*Pruebas de Recuperacion de Metadatos (Punto 7)*/

-- Listar todas las tablas en AcademiaDB
SELECT 
    TABLE_NAME AS Nombre_Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_CATALOG = 'AcademiaDB' AND TABLE_TYPE = 'BASE TABLE';
GO

-- Claves primarias
SELECT 
    TABLE_NAME AS Tabla,
    CONSTRAINT_NAME AS Clave_Primaria
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE CONSTRAINT_TYPE = 'PRIMARY KEY'
  AND TABLE_CATALOG = 'AcademiaDB';
GO
-- Claves foráneas
SELECT 
    fk.name AS Nombre_Restriccion,
    tp.name AS Tabla_Hija,
    ref.name AS Tabla_Padre,
    c1.name AS Columna_Hija,
    c2.name AS Columna_Padre
FROM 
    sys.foreign_keys fk
    INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
    INNER JOIN sys.tables ref ON fk.referenced_object_id = ref.object_id
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    INNER JOIN sys.columns c1 ON fkc.parent_column_id = c1.column_id AND tp.object_id = c1.object_id
    INNER JOIN sys.columns c2 ON fkc.referenced_column_id = c2.column_id AND ref.object_id = c2.object_id
WHERE fk.is_disabled = 0;
GO

-- Listar las vistas en AcademiaDB
SELECT 
    TABLE_NAME AS Nombre_Vista
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_CATALOG = 'AcademiaDB';
GO

-- Listar procedimientos almacenados en AcademiaDB
SELECT 
    ROUTINE_NAME AS Nombre_Procedimiento
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_CATALOG = 'AcademiaDB' AND ROUTINE_TYPE = 'PROCEDURE';
GO

/*Pruebas de Diagnostico (Punto 8)*/

-- Verificar el uso de espacio de la base de datos
EXEC sp_spaceused;
GO

-- Verificar el uso de espacio por tabla en la base de datos
SELECT 
    t.NAME AS Tabla,
    SUM(p.rows) AS Filas,
    SUM(a.total_pages) * 8 AS Tamaño_KB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.OBJECT_ID
INNER JOIN 
    sys.partitions p ON i.OBJECT_ID = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY 
    t.NAME
ORDER BY 
    Tamaño_KB DESC;
GO

-- Identificar transacciones bloqueadas
SELECT 
    blocking_session_id AS Bloqueante_SessionID,
    session_id AS Bloqueada_SessionID,
    wait_type,
    wait_time,
    wait_resource,
    status,
    command,
    cpu_time,
    total_elapsed_time,
    TEXT AS Consulta
FROM 
    sys.dm_exec_requests AS r
CROSS APPLY 
    sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE 
    r.blocking_session_id <> 0;
GO

-- Obtener información sobre bloqueos de recursos
SELECT 
    r.session_id,
    r.blocking_session_id,
    r.wait_type,
    r.wait_time,
    r.wait_resource,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time,
    r.transaction_id
FROM 
    sys.dm_exec_requests r
WHERE 
    r.blocking_session_id > 0;
GO

-- Consultas más costosas por tiempo de ejecución
SELECT 
    qs.sql_handle,
    qt.text AS Consulta,
    qs.execution_count,
    qs.total_worker_time / 1000 AS CPU_ms, -- CPU en milisegundos
    qs.total_physical_reads AS Lecturas_Dispositivo,
    qs.total_logical_reads AS Lecturas_Lógicas,
    qs.total_elapsed_time / 1000 AS Tiempo_Transcurrido_seg
FROM 
    sys.dm_exec_query_stats qs
CROSS APPLY 
    sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY 
    qs.total_elapsed_time DESC; -- Ordenar por la consulta más costosa en tiempo
GO

-- Consultas recientes y su rendimiento
SELECT 
    r.session_id,
    r.start_time,
    r.status,
    r.cpu_time,
    r.total_elapsed_time,
    t.text AS Consulta
FROM 
    sys.dm_exec_requests r
CROSS APPLY 
    sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE 
    r.start_time > DATEADD(MINUTE, -10, GETDATE()) -- Consultas de los últimos 10 minutos
ORDER BY 
    r.start_time DESC;
GO
