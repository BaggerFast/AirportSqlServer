-------------------------------------------------------------------------------------------------
-- PLAYLISTS_INSERT
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

IF NOT EXISTS (SELECT 1 FROM [sys].[tables] WHERE [name] = N'PLAYLISTS') BEGIN
	PRINT N'❌ TABLE [PLAYLISTS] WAS NOT FOUND';
END ELSE BEGIN
    -- CREATE VARIABLES
    DECLARE @TITLE NVARCHAR(100);
    DECLARE @USERNAME NVARCHAR(32);
    DECLARE @ACCESS NVARCHAR(50);

    DECLARE @USER_UID UNIQUEIDENTIFIER;
    DECLARE @ACCESS_UID UNIQUEIDENTIFIER;

    -- CREATE TMP TABLES
    BEGIN 
        DROP TABLE IF EXISTS #CSV;
        CREATE TABLE #CSV (
            [USERNAME] NVARCHAR(50) NOT NULL, 
		    [TITLE] NVARCHAR(100) NOT NULL,
            [ACCESS] NVARCHAR(32) NULL,
        );
        BULK INSERT #CSV FROM '/DataCsv/playlists.csv'
        WITH (
	        FIRSTROW = 2,
	        FIELDTERMINATOR = ';',
	        ROWTERMINATOR = '\n',
            DATAFILETYPE = 'WideChar'
        );
        PRINT N'➕ CREATE TEMP TABLES IS SUCCESS'
    END;

    -- INSERT TABLE
    BEGIN
        DECLARE CUR CURSOR FOR SELECT [USERNAME], [TITLE], [ACCESS] FROM #CSV;
        OPEN CUR;
        FETCH NEXT FROM CUR INTO @USERNAME, @TITLE, @ACCESS;
        WHILE @@FETCH_STATUS = 0 BEGIN
        
            SET @ACCESS_UID = (SELECT [UID] FROM [ACCESS_LEVELS] WHERE [TITLE] = @ACCESS);
            SET @USER_UID = (SELECT [UID] FROM [USERS] WHERE [USERNAME] = @USERNAME);

            MERGE INTO [PLAYLISTS] AS [PLAYLIST]
                USING (VALUES (@USER_UID, @TITLE, @ACCESS_UID)) AS [NEW_PLAYLIST] ([USER_UID], [TITLE], [ACCESS_UID])
                ON [PLAYLIST].[TITLE] = [NEW_PLAYLIST].[TITLE] AND [PLAYLIST].[USER_UID] = [NEW_PLAYLIST].[USER_UID] 
                    AND [PLAYLIST].[ACCESS_UID] = [NEW_PLAYLIST].[ACCESS_UID] 
                WHEN NOT MATCHED THEN
                    INSERT ([USER_UID], [ACCESS_UID], [TITLE]) VALUES
                        (@USER_UID, @ACCESS_UID, @TITLE);
            FETCH NEXT FROM CUR INTO @USERNAME, @TITLE, @ACCESS;
        END;
        CLOSE CUR;
        DEALLOCATE CUR;

        PRINT N'➕ INSERT IS SUCCESS'
    END;
    DROP TABLE IF EXISTS #CSV;
    PRINT N'➕ DROP TEMP TABLES IS SUCCESS'
END;


IF (@IS_COMMIT = 1) BEGIN
    COMMIT TRAN
    PRINT N'➕ INSERT IS COMMITTED'
END ELSE BEGIN
    ROLLBACK TRAN
    PRINT N'❌ JOB IS ROLL-BACKED'
END;
