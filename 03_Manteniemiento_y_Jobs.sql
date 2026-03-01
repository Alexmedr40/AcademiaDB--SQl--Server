-- Crear un nuevo Plan de Mantenimiento
USE msdb;
GO

EXEC sp_add_maintenance_plan
    @plan_name = 'Plan_Mantenimiento_AcademiaDB',
    @description = 'Plan para mantenimiento de la base de datos AcademiaDB',
    @enabled = 1;
GO

-- Agregar un paso para la reorganización de índices
EXEC sp_add_maintenance_plan_subplan
    @plan_name = 'Plan_Mantenimiento_AcademiaDB',
    @subplan_name = 'Reorganizar Índices',
    @subplan_id = 1,
    @subplan_type = 1;
GO

EXEC sp_add_maintenance_plan_task
    @plan_name = 'Plan_Mantenimiento_AcademiaDB',
    @subplan_name = 'Reorganizar Índices',
    @task_name = 'Reorganizar Índices de AcademiaDB',
    @task_type = 2,  -- Reorganización de índices
    @database_name = 'AcademiaDB';
GO

-- Agregar un paso para la comprobación de la integridad de la base de datos
EXEC sp_add_maintenance_plan_task
    @plan_name = 'Plan_Mantenimiento_AcademiaDB',
    @subplan_name = 'Comprobación Integridad',
    @task_name = 'Comprobar Integridad de AcademiaDB',
    @task_type = 3,  -- Comprobación de integridad
    @database_name = 'AcademiaDB';
GO

-- Crear un nuevo Job
USE msdb;
GO

EXEC sp_add_job
    @job_name = 'Respaldo_AcademiaDB',
    @enabled = 1,
    @description = 'Job para realizar respaldo completo de la base de datos AcademiaDB cada 24 horas';
GO

-- Crear un paso para el Job
EXEC sp_add_jobstep
    @job_name = 'Respaldo_AcademiaDB',
    @step_name = 'Respaldo Completo AcademiaDB',
    @subsystem = 'TSQL',
    @command = 'BACKUP DATABASE AcademiaDB TO DISK = ''C:\Backups\AcademiaDB_Full.bak'' WITH INIT;',
    @retry_attempts = 3,
    @retry_interval = 5;
GO

-- Crear un horario para el Job (cada 24 horas)
EXEC sp_add_schedule
    @schedule_name = 'Respaldo Diario AcademiaDB',
    @enabled = 1,
    @freq_type = 4,  -- Diario
    @freq_interval = 1,  -- Cada día
    @freq_subday_type = 1,  -- Cada hora
    @freq_subday_interval = 24,  -- Cada 24 horas
    @active_start_time = 010000;  -- Empieza a las 01:00 AM
GO

-- Asignar el horario al Job
EXEC sp_attach_schedule
    @job_name = 'Respaldo_AcademiaDB',
    @schedule_name = 'Respaldo Diario AcademiaDB';
GO

-- Hacer el Job ejecutable
EXEC sp_add_jobserver
    @job_name = 'Respaldo_AcademiaDB',
    @server_name = @@SERVERNAME;
GO

-- Crear un operador para recibir la alerta
USE msdb;
GO

EXEC sp_add_operator
    @name = 'OperadorFicticio',
    @email_address = 'ficticio@correo.com',
    @enabled = 1;
GO

-- Crear la alerta de espacio en disco
EXEC sp_add_alert
    @name = 'AlertaEspacioDiscoCritico',
    @message_id = 0,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @notification_message = 'Alerta: El espacio en disco es crítico para la base de datos AcademiaDB.',
    @include_event_description = 0,
    @category_name = 'Performance',
    @performance_condition = 'SQLServer:Databases|Data File(s) Size (KB)|_Total|AcademiaDB',
    @operator_name = 'OperadorFicticio';
GO

