-------------------------------------------------------------------------------------------------
-- TAGS_DROP
-------------------------------------------------------------------------------------------------
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

DECLARE @IS_COMMIT BIT = 0;
-------------------------------------------------------------------------------------------------
USE VideoHosting;

BEGIN TRAN
PRINT N'➕ JOB IS STARTED';

IF NOT EXISTS (SELECT 1 FROM [sys].[tables] WHERE [name] = N'TAGS') BEGIN
	PRINT N'❌ TABLE [TAGS] WAS NOT FOUND';
END ELSE BEGIN
	DROP TABLE IF EXISTS [TAGS];
	PRINT N'➕ DROP TABLE [TAGS] IS COMPLETED';
END;

IF (@IS_COMMIT = 1) BEGIN
	COMMIT TRAN
	PRINT N'➕ INSERT IS COMMITTED'
END ELSE BEGIN
    ROLLBACK TRAN
	PRINT N'❌ INSERT IS ROLL-BACKED'
END;
