/****** Object:  StoredProcedure [metric].[DoobJob_SaveCounter]    Script Date: 2015-05-11 19:17:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [metric].[DoobJob_SaveCounter]
  @counterIdentifier  varchar(500),
  @counterDate        date = NULL,
  @subjectIDs         varchar(MAX) = NULL,
  @subjectTexts       varchar(MAX) = NULL,
  @keyIDs             varchar(MAX) = NULL,
  @keyTexts           varchar(MAX) = NULL,
  @values             varchar(MAX) = NULL,
  @columnID1          tinyint = NULL,
  @values1            varchar(MAX) = NULL,
  @columnID2          tinyint = NULL,
  @values2            varchar(MAX) = NULL,
  @columnID3          tinyint = NULL,
  @values3            varchar(MAX) = NULL,
  @columnID4          tinyint = NULL,
  @values4            varchar(MAX) = NULL,
  @columnID5          tinyint = NULL,
  @values5            varchar(MAX) = NULL,
  @columnID6          tinyint = NULL,
  @values6            varchar(MAX) = NULL,
  @columnID7          tinyint = NULL,
  @values7            varchar(MAX) = NULL,
  @columnID8          tinyint = NULL,
  @values8            varchar(MAX) = NULL,
  @columnID9          tinyint = NULL,
  @values9            varchar(MAX) = NULL,
  @columnID10         tinyint = NULL,
  @values10           varchar(MAX) = NULL,
  @eventParentID      int = NULL
AS
  SET NOCOUNT ON
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  DECLARE @counterID smallint, @dataCount int, @insertCount int, @updateCount int

  BEGIN TRY
    EXEC metric.GetDates @counterDate OUTPUT
    SET @counterID = zmetric.Counters_ID(@counterIdentifier)

    DECLARE @eventID int
    EXEC @eventID = zsystem.Events_TaskStarted 'metric.DoobJob_SaveCounter', @counterIdentifier, @int_1=@counterID, @date_1=@counterDate, @parentID=@eventParentID

    IF @counterID IS NULL
      RAISERROR ('Counter not found', 16, 1)

    IF @subjectTexts IS NOT NULL OR @keyTexts IS NOT NULL
    BEGIN
      DECLARE @lookupText nvarchar(200), @lookupID int
      DECLARE @cursor CURSOR
    END

    -- Special lookup table handling if @subjectTexts used
    IF @subjectTexts IS NOT NULL
    BEGIN
      IF @subjectIDs IS NOT NULL
        RAISERROR ('@subjectIDs and @subjectTexts both set', 16, 1)

      DECLARE @subjectLookupTableID int
      SELECT @subjectLookupTableID = subjectLookupTableID FROM zmetric.counters WHERE counterID = @counterID
      IF @subjectLookupTableID IS NULL
        RAISERROR ('zmetric.counters.subjectLookupTableID not set', 16, 1)

      DECLARE @subjectLookupTableSourceForID varchar(20)
      SELECT @subjectLookupTableSourceForID = sourceForID FROM zsystem.lookupTables WHERE lookupTableID = @subjectLookupTableID
      IF @subjectLookupTableSourceForID NOT IN ('MAX', 'TEXT')
        RAISERROR ('zsystem.lookupTables.sourceForID not MAX or TEXT', 16, 1)

      DECLARE @subjectLookupTable TABLE (lookupText nvarchar(450) COLLATE Latin1_General_CI_AI NOT NULL PRIMARY KEY, lookupID int NOT NULL)
      INSERT INTO @subjectLookupTable (lookupText, lookupID)
           SELECT lookupText, lookupID FROM zsystem.lookupValues WHERE lookupTableID = @subjectLookupTableID

      DECLARE @subjectTextsTable TABLE (lookupText nvarchar(450) COLLATE Latin1_General_CI_AI NOT NULL PRIMARY KEY, lookupID int NULL)
      DECLARE @subjectTextsCount int
      INSERT INTO @subjectTextsTable (lookupText)
           SELECT DISTINCT string FROM zutil.CharListToTableTrim(@subjectTexts)
      SET @subjectTextsCount = @@ROWCOUNT

      UPDATE T
         SET T.lookupID = L.lookupID
        FROM @subjectTextsTable T
          INNER JOIN @subjectLookupTable L ON L.lookupText = T.lookupText
      IF @@ROWCOUNT != @subjectTextsCount
      BEGIN
        -- Something is missing from subject lookup table
        IF @subjectLookupTableSourceForID = 'MAX'
        BEGIN
          DECLARE @subjectLookupMaxID int
          SELECT @subjectLookupMaxID = MAX(lookupID) FROM zsystem.lookupValues WHERE lookupTableID = @subjectLookupTableID
          IF @subjectLookupMaxID IS NULL SET @subjectLookupMaxID = 0
        END

        SET @cursor = CURSOR LOCAL STATIC READ_ONLY
          FOR SELECT lookupText FROM @subjectTextsTable WHERE lookupID IS NULL
        OPEN @cursor
        FETCH NEXT FROM @cursor INTO @lookupText
        WHILE @@FETCH_STATUS = 0
        BEGIN
          IF @subjectLookupTableSourceForID = 'MAX'
          BEGIN
            SET @subjectLookupMaxID = @subjectLookupMaxID + 1
            UPDATE @subjectTextsTable SET lookupID = @subjectLookupMaxID WHERE lookupText = @lookupText
            INSERT INTO zsystem.lookupValues (lookupTableID, lookupID, lookupText) VALUES (@subjectLookupTableID, @subjectLookupMaxID, @lookupText)
          END
          ELSE
          BEGIN
            EXEC @lookupID = zsystem.Texts_ID @lookupText
            UPDATE @subjectTextsTable SET lookupID = @lookupID WHERE lookupText = @lookupText
            INSERT INTO zsystem.lookupValues (lookupTableID, lookupID, lookupText) VALUES (@subjectLookupTableID, @lookupID, @lookupText)
          END

          FETCH NEXT FROM @cursor INTO @lookupText
        END
        CLOSE @cursor
        DEALLOCATE @cursor
      END
    END

    -- Special lookup table handling if @keyTexts used
    IF @keyTexts IS NOT NULL
    BEGIN
      IF @keyIDs IS NOT NULL
        RAISERROR ('@keyIDs and @keyTexts both set', 16, 1)

      DECLARE @keyLookupTableID int
      SELECT @keyLookupTableID = keyLookupTableID FROM zmetric.counters WHERE counterID = @counterID
      IF @keyLookupTableID IS NULL
        RAISERROR ('zmetric.counters.keyLookupTableID not set', 16, 1)

      DECLARE @keyLookupTableSourceForID varchar(20)
      SELECT @keyLookupTableSourceForID = sourceForID FROM zsystem.lookupTables WHERE lookupTableID = @keyLookupTableID
      IF @keyLookupTableSourceForID NOT IN ('MAX', 'TEXT')
        RAISERROR ('zsystem.lookupTables.sourceForID not MAX or TEXT', 16, 1)

      DECLARE @keyLookupTable TABLE (lookupText nvarchar(450) COLLATE Latin1_General_CI_AI NOT NULL PRIMARY KEY, lookupID int NOT NULL)
      INSERT INTO @keyLookupTable (lookupText, lookupID)
           SELECT lookupText, lookupID FROM zsystem.lookupValues WHERE lookupTableID = @keyLookupTableID

      DECLARE @keyTextsTable TABLE (lookupText nvarchar(450) COLLATE Latin1_General_CI_AI NOT NULL PRIMARY KEY, lookupID int NULL)
      DECLARE @keyTextsCount int
      INSERT INTO @keyTextsTable (lookupText)
           SELECT DISTINCT string FROM zutil.CharListToTableTrim(@keyTexts)
      SET @keyTextsCount = @@ROWCOUNT

      UPDATE T
         SET T.lookupID = L.lookupID
        FROM @keyTextsTable T
          INNER JOIN @keyLookupTable L ON L.lookupText = T.lookupText
      IF @@ROWCOUNT != @keyTextsCount
      BEGIN
        -- Something is missing from key lookup table
        IF @keyLookupTableSourceForID = 'MAX'
        BEGIN
          DECLARE @keyLookupMaxID int
          SELECT @keyLookupMaxID = MAX(lookupID) FROM zsystem.lookupValues WHERE lookupTableID = @keyLookupTableID
          IF @keyLookupMaxID IS NULL SET @keyLookupMaxID = 0
        END

        SET @cursor = CURSOR LOCAL STATIC READ_ONLY
          FOR SELECT lookupText FROM @keyTextsTable WHERE lookupID IS NULL
        OPEN @cursor
        FETCH NEXT FROM @cursor INTO @lookupText
        WHILE @@FETCH_STATUS = 0
        BEGIN
          IF @keyLookupTableSourceForID = 'MAX'
          BEGIN
            SET @keyLookupMaxID = @keyLookupMaxID + 1
            UPDATE @keyTextsTable SET lookupID = @keyLookupMaxID WHERE lookupText = @lookupText
            INSERT INTO zsystem.lookupValues (lookupTableID, lookupID, lookupText) VALUES (@keyLookupTableID, @keyLookupMaxID, @lookupText)
          END
          ELSE
          BEGIN
            EXEC @lookupID = zsystem.Texts_ID @lookupText
            UPDATE @keyTextsTable SET lookupID = @lookupID WHERE lookupText = @lookupText
            INSERT INTO zsystem.lookupValues (lookupTableID, lookupID, lookupText) VALUES (@keyLookupTableID, @lookupID, @lookupText)
          END

          FETCH NEXT FROM @cursor INTO @lookupText
        END
        CLOSE @cursor
        DEALLOCATE @cursor
      END
    END

    -- Save counter data, either using @values or special column support
    DECLARE @data TABLE (subjectID int, keyID int, value float, PRIMARY KEY(subjectID, keyID))
    IF @values IS NOT NULL
    BEGIN
      IF @subjectIDs IS NULL AND @subjectTexts IS NULL AND @keyIDs IS NULL AND @keyTexts IS NULL
      BEGIN
        -- No subjects / No keys
        INSERT INTO @data (subjectID, keyID, value) VALUES (0, 0, CONVERT(float, @values))
      END

      ELSE IF @subjectIDs IS NOT NULL AND @keyIDs IS NULL AND @keyTexts IS NULL
      BEGIN
        -- Subjects (columns) as IDs / No keys
        INSERT INTO @data (subjectID, keyID, value)
             SELECT S.number, 0, V.number
               FROM zutil.IntListToOrderedTable(@subjectIDs) S
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = S.[row]
      END
      ELSE IF @subjectTexts IS NOT NULL AND @keyIDs IS NULL AND @keyTexts IS NULL
      BEGIN
        -- Subjects (columns) as Texts / No keys
        INSERT INTO @data (subjectID, keyID, value)
             SELECT LS.lookupID, 0, V.number
               FROM zutil.CharListToOrderedTableTrim(@subjectTexts) S
                 INNER JOIN @subjectTextsTable LS ON LS.lookupText = S.string COLLATE Latin1_General_CI_AI
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = S.[row]
      END

      ELSE IF @subjectIDs IS NULL AND @subjectTexts IS NULL AND @keyIDs IS NOT NULL
      BEGIN
        -- No subjects / Keys as IDs
        INSERT INTO @data (subjectID, keyID, value)
             SELECT 0, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = K.[row]
      END
      ELSE IF @subjectIDs IS NULL AND @subjectTexts IS NULL AND @keyTexts IS NOT NULL
      BEGIN
        -- No subjects / Keys as Texts
        INSERT INTO @data (subjectID, keyID, value)
             SELECT 0, LK.lookupID, V.number
               FROM zutil.CharListToOrderedTableTrim(@keyTexts) K
                 INNER JOIN @keyTextsTable LK ON LK.lookupText = K.string COLLATE Latin1_General_CI_AI
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = K.[row]
      END

      ELSE IF @subjectIDs IS NOT NULL AND @keyIDs IS NOT NULL
      BEGIN
        -- Subjects as IDs / Keys as IDs
        INSERT INTO @data (subjectID, keyID, value)
             SELECT S.number, K.number, V.number
               FROM zutil.IntListToOrderedTable(@subjectIDs) S
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = S.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = S.[row]
      END
      ELSE IF @subjectTexts IS NOT NULL AND @keyIDs IS NOT NULL
      BEGIN
        -- Subjects as Texts / Keys as IDs
        INSERT INTO @data (subjectID, keyID, value)
             SELECT LS.lookupID, K.number, V.number
               FROM zutil.CharListToOrderedTableTrim(@subjectTexts) S
                 INNER JOIN @subjectTextsTable LS ON LS.lookupText = S.string COLLATE Latin1_General_CI_AI
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = S.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = S.[row]
      END
      ELSE IF @subjectIDs IS NOT NULL AND @keyTexts IS NOT NULL
      BEGIN
        -- Subjects as IDs / Keys as Texts
        INSERT INTO @data (subjectID, keyID, value)
             SELECT S.number, LK.lookupID, V.number
               FROM zutil.IntListToOrderedTable(@subjectIDs) S
                 INNER JOIN zutil.CharListToOrderedTableTrim(@keyTexts) K ON K.[row] = S.[row]
                   INNER JOIN @keyTextsTable LK ON LK.lookupText = K.string COLLATE Latin1_General_CI_AI
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = S.[row]
      END
      ELSE IF @subjectTexts IS NOT NULL AND @keyTexts IS NOT NULL
      BEGIN
        -- Subjects as Texts / Keys as Texts
        INSERT INTO @data (subjectID, keyID, value)
             SELECT LS.lookupID, LK.lookupID, V.number
               FROM zutil.CharListToOrderedTableTrim(@subjectTexts) S
                 INNER JOIN @subjectTextsTable LS ON LS.lookupText = S.string COLLATE Latin1_General_CI_AI
                 INNER JOIN zutil.CharListToOrderedTableTrim(@keyTexts) K ON K.[row] = S.[row]
                   INNER JOIN @keyTextsTable LK ON LK.lookupText = K.string COLLATE Latin1_General_CI_AI
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = S.[row]
      END
      ELSE
        RAISERROR ('Parameter combination not supported', 16, 1)
    END
    ELSE
    BEGIN
      -- Special column support (max 10 columns, only supported with @keyIDs)
      IF @keyIDs IS NULL
        RAISERROR ('Special column support only supported with @keyIDs', 16, 1)

      IF @columnID1 IS NOT NULL
      BEGIN
        INSERT INTO @data (subjectID, keyID, value)
             SELECT @columnID1, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values1) V ON V.[row] = K.[row]
      END
      IF @columnID2 IS NOT NULL
      BEGIN
        INSERT INTO @data (subjectID, keyID, value)
             SELECT @columnID2, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values2) V ON V.[row] = K.[row]
      END
      IF @columnID3 IS NOT NULL
      BEGIN
        INSERT INTO @data (subjectID, keyID, value)
             SELECT @columnID3, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values3) V ON V.[row] = K.[row]
      END
      IF @columnID4 IS NOT NULL
      BEGIN
        INSERT INTO @data (subjectID, keyID, value)
             SELECT @columnID4, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values4) V ON V.[row] = K.[row]
      END
      IF @columnID5 IS NOT NULL
      BEGIN
        INSERT INTO @data (subjectID, keyID, value)
             SELECT @columnID5, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values5) V ON V.[row] = K.[row]
      END
      IF @columnID6 IS NOT NULL
      BEGIN
        INSERT INTO @data (subjectID, keyID, value)
             SELECT @columnID6, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values6) V ON V.[row] = K.[row]
      END
      IF @columnID7 IS NOT NULL
      BEGIN
        INSERT INTO @data (subjectID, keyID, value)
             SELECT @columnID7, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values7) V ON V.[row] = K.[row]
      END
      IF @columnID8 IS NOT NULL
      BEGIN
        INSERT INTO @data (subjectID, keyID, value)
             SELECT @columnID8, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values8) V ON V.[row] = K.[row]
      END
      IF @columnID9 IS NOT NULL
      BEGIN
        INSERT INTO @data (subjectID, keyID, value)
             SELECT @columnID9, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values9) V ON V.[row] = K.[row]
      END
      IF @columnID10 IS NOT NULL
      BEGIN
        INSERT INTO @data (subjectID, keyID, value)
             SELECT @columnID10, K.number, V.number
               FROM zutil.IntListToOrderedTable(@keyIDs) K
                 INNER JOIN zutil.FloatListToOrderedTable(@values10) V ON V.[row] = K.[row]
      END
    END
    SET @dataCount = @@ROWCOUNT

    -- If simple insert fails then go for slower update/insert
    BEGIN TRY
      INSERT INTO zmetric.keyCounters (counterID, counterDate, columnID, keyID, value)
           SELECT @counterID, @counterDate, subjectID, keyID, value FROM @data ORDER BY subjectID, keyID
      SET @insertCount = @@ROWCOUNT
    END TRY
    BEGIN CATCH
      UPDATE D SET D.value = X.value
        FROM @data X
          INNER JOIN zmetric.keyCounters D ON D.counterID = @counterID AND D.columnID = X.subjectID AND D.keyID = X.keyID AND D.counterDate = @counterDate
       WHERE D.value != X.value
      SET @updateCount = @@ROWCOUNT

      INSERT INTO zmetric.keyCounters (counterID, counterDate, columnID, keyID, value)
           SELECT @counterID, @counterDate, X.subjectID, X.keyID, X.value
             FROM @data X
               LEFT JOIN zmetric.keyCounters D ON D.counterID = @counterID AND D.columnID = X.subjectID AND D.keyID = X.keyID AND D.counterDate = @counterDate
            WHERE D.counterID IS NULL
            ORDER BY X.subjectID, X.keyID
      SET @insertCount = @@ROWCOUNT
    END CATCH

    EXEC zsystem.Events_TaskCompleted @eventID, @int_1=@counterID, @int_2=@dataCount, @int_3=@insertCount, @int_4=@updateCount, @date_1=@counterDate
  END TRY
  BEGIN CATCH
    DECLARE @eventText nvarchar(max) = ERROR_MESSAGE()
    EXEC zsystem.Events_TaskError @eventID, @eventText, @int_1=@counterID, @int_2=@dataCount, @int_3=@insertCount, @int_4=@updateCount, @date_1=@counterDate
    EXEC zsystem.CatchError 'metric.DoobJob_SaveCounter'
    RETURN -1
  END CATCH

GO
/****** Object:  StoredProcedure [metric].[DoobJob_SaveTimeCounter]    Script Date: 2015-05-11 19:17:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [metric].[DoobJob_SaveTimeCounter]
  @counterIdentifier  varchar(500),
  @counterDates       varchar(MAX),
  @columnIDs          varchar(MAX) = NULL,
  @keyIDs             varchar(MAX) = NULL,
  @keyTexts           varchar(MAX) = NULL,
  @values             varchar(MAX) = NULL,
  @columnID1          tinyint = NULL,
  @values1            varchar(MAX) = NULL,
  @columnID2          tinyint = NULL,
  @values2            varchar(MAX) = NULL,
  @columnID3          tinyint = NULL,
  @values3            varchar(MAX) = NULL,
  @columnID4          tinyint = NULL,
  @values4            varchar(MAX) = NULL,
  @columnID5          tinyint = NULL,
  @values5            varchar(MAX) = NULL,
  @columnID6          tinyint = NULL,
  @values6            varchar(MAX) = NULL,
  @columnID7          tinyint = NULL,
  @values7            varchar(MAX) = NULL,
  @columnID8          tinyint = NULL,
  @values8            varchar(MAX) = NULL,
  @columnID9          tinyint = NULL,
  @values9            varchar(MAX) = NULL,
  @columnID10         tinyint = NULL,
  @values10           varchar(MAX) = NULL,
  @eventParentID      int = NULL
AS
  SET NOCOUNT ON
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  DECLARE @counterID smallint, @dataCount int, @insertCount int, @updateCount int

  BEGIN TRY
    SET @counterID = zmetric.Counters_ID(@counterIdentifier)

    DECLARE @eventID int
    EXEC @eventID = zsystem.Events_TaskStarted 'metric.DoobJob_SaveTimeCounter', @counterIdentifier, @int_1=@counterID, @parentID=@eventParentID

    IF @counterID IS NULL
      RAISERROR ('Counter not found', 16, 1)

    -- Special lookup table handling if @keyTexts used
    IF @keyTexts IS NOT NULL
    BEGIN
      IF @keyIDs IS NOT NULL
        RAISERROR ('@keyIDs and @keyTexts both set', 16, 1)

      DECLARE @keyLookupTableID int
      SELECT @keyLookupTableID = keyLookupTableID FROM zmetric.counters WHERE counterID = @counterID
      IF @keyLookupTableID IS NULL
        RAISERROR ('zmetric.counters.keyLookupTableID not set', 16, 1)

      DECLARE @keyLookupTableSourceForID varchar(20)
      SELECT @keyLookupTableSourceForID = sourceForID FROM zsystem.lookupTables WHERE lookupTableID = @keyLookupTableID
      IF @keyLookupTableSourceForID NOT IN ('MAX', 'TEXT')
        RAISERROR ('zsystem.lookupTables.sourceForID not MAX or TEXT', 16, 1)

      DECLARE @keyLookupTable TABLE (lookupText nvarchar(450) COLLATE Latin1_General_CI_AI NOT NULL PRIMARY KEY, lookupID int NOT NULL)
      INSERT INTO @keyLookupTable (lookupText, lookupID)
           SELECT lookupText, lookupID FROM zsystem.lookupValues WHERE lookupTableID = @keyLookupTableID

      DECLARE @keyTextsTable TABLE (lookupText nvarchar(450) COLLATE Latin1_General_CI_AI NOT NULL PRIMARY KEY, lookupID int NULL)
      DECLARE @keyTextsCount int
      INSERT INTO @keyTextsTable (lookupText)
           SELECT DISTINCT string FROM zutil.CharListToTableTrim(@keyTexts)
      SET @keyTextsCount = @@ROWCOUNT

      UPDATE T
         SET T.lookupID = L.lookupID
        FROM @keyTextsTable T
          INNER JOIN @keyLookupTable L ON L.lookupText = T.lookupText
      IF @@ROWCOUNT != @keyTextsCount
      BEGIN
        -- Something is missing from key lookup table
        IF @keyLookupTableSourceForID = 'MAX'
        BEGIN
          DECLARE @keyLookupMaxID int
          SELECT @keyLookupMaxID = MAX(lookupID) FROM zsystem.lookupValues WHERE lookupTableID = @keyLookupTableID
          IF @keyLookupMaxID IS NULL SET @keyLookupMaxID = 0
        END

        DECLARE @lookupText nvarchar(200), @lookupID int
        DECLARE @cursor CURSOR
        SET @cursor = CURSOR LOCAL STATIC READ_ONLY
          FOR SELECT lookupText FROM @keyTextsTable WHERE lookupID IS NULL
        OPEN @cursor
        FETCH NEXT FROM @cursor INTO @lookupText
        WHILE @@FETCH_STATUS = 0
        BEGIN
          IF @keyLookupTableSourceForID = 'MAX'
          BEGIN
            SET @keyLookupMaxID = @keyLookupMaxID + 1
            UPDATE @keyTextsTable SET lookupID = @keyLookupMaxID WHERE lookupText = @lookupText
            INSERT INTO zsystem.lookupValues (lookupTableID, lookupID, lookupText) VALUES (@keyLookupTableID, @keyLookupMaxID, @lookupText)
          END
          ELSE
          BEGIN
            EXEC @lookupID = zsystem.Texts_ID @lookupText
            UPDATE @keyTextsTable SET lookupID = @lookupID WHERE lookupText = @lookupText
            INSERT INTO zsystem.lookupValues (lookupTableID, lookupID, lookupText) VALUES (@keyLookupTableID, @lookupID, @lookupText)
          END

          FETCH NEXT FROM @cursor INTO @lookupText
        END
        CLOSE @cursor
        DEALLOCATE @cursor
      END
    END

    -- Save counter data, either using @values or special column support
    DECLARE @data TABLE (counterDate datetime2(0), columnID tinyint, keyID int, value float)

    IF @values IS NOT NULL
    BEGIN
      IF @columnIDs IS NULL AND @keyIDs IS NULL AND @keyTexts IS NULL
      BEGIN
        -- No columns / No keys
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, 0, 0, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = D.[row]
      END
      ELSE IF @columnIDs IS NULL AND @keyIDs IS NOT NULL
      BEGIN
        -- No columns / Keys as IDs
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, 0, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = D.[row]
      END
      ELSE IF @columnIDs IS NULL AND @keyTexts IS NOT NULL
      BEGIN
        -- No columns / Keys as Texts
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, 0, LK.lookupID, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.CharListToOrderedTableTrim(@keyTexts) K ON K.[row] = D.[row]
                   INNER JOIN @keyTextsTable LK ON LK.lookupText = K.string COLLATE Latin1_General_CI_AI
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = D.[row]
      END

      ELSE IF @columnIDs IS NOT NULL AND @keyIDs IS NULL AND @keyTexts IS NULL
      BEGIN
        -- Columns / No keys
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, C.number, 0, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@columnIDs) C ON C.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = D.[row]
      END
      ELSE IF @columnIDs IS NOT NULL AND @keyIDs IS NOT NULL
      BEGIN
        -- Columns / Keys as IDs
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, C.number, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@columnIDs) C ON C.[row] = D.[row]
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = D.[row]
      END
      ELSE IF @columnIDs IS NOT NULL AND @keyTexts IS NOT NULL
      BEGIN
        -- Columns / Keys as Texts
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, C.number, LK.lookupID, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@columnIDs) C ON C.[row] = D.[row]
                 INNER JOIN zutil.CharListToOrderedTableTrim(@keyTexts) K ON K.[row] = D.[row]
                   INNER JOIN @keyTextsTable LK ON LK.lookupText = K.string COLLATE Latin1_General_CI_AI
                 INNER JOIN zutil.FloatListToOrderedTable(@values) V ON V.[row] = D.[row]
      END
      ELSE
        RAISERROR ('Parameter combination not supported', 16, 1)
    END
    ELSE
    BEGIN
      -- Special column support (max 10 columns, only supported with @keyIDs)
      IF @keyIDs IS NULL
        RAISERROR ('Special column support only supported with @keyIDs', 16, 1)

      IF @columnID1 IS NOT NULL
      BEGIN
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, @columnID1, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values1) V ON V.[row] = D.[row]
      END
      IF @columnID2 IS NOT NULL
      BEGIN
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, @columnID2, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values2) V ON V.[row] = D.[row]
      END
      IF @columnID3 IS NOT NULL
      BEGIN
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, @columnID3, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values3) V ON V.[row] = D.[row]
      END
      IF @columnID4 IS NOT NULL
      BEGIN
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, @columnID4, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values4) V ON V.[row] = D.[row]
      END
      IF @columnID5 IS NOT NULL
      BEGIN
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, @columnID5, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values5) V ON V.[row] = D.[row]
      END
      IF @columnID6 IS NOT NULL
      BEGIN
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, @columnID6, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values6) V ON V.[row] = D.[row]
      END
      IF @columnID7 IS NOT NULL
      BEGIN
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, @columnID7, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values7) V ON V.[row] = D.[row]
      END
      IF @columnID8 IS NOT NULL
      BEGIN
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, @columnID8, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values8) V ON V.[row] = D.[row]
      END
      IF @columnID9 IS NOT NULL
      BEGIN
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, @columnID9, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values9) V ON V.[row] = D.[row]
      END
      IF @columnID10 IS NOT NULL
      BEGIN
        INSERT INTO @data (counterDate, columnID, keyID, value)
             SELECT D.dateValue, @columnID10, K.number, V.number
               FROM zutil.DateListToOrderedTable(@counterDates) D
                 INNER JOIN zutil.IntListToOrderedTable(@keyIDs) K ON K.[row] = D.[row]
                 INNER JOIN zutil.FloatListToOrderedTable(@values10) V ON V.[row] = D.[row]
      END
    END
    SET @dataCount = @@ROWCOUNT

    -- If simple insert fails then go for slower update/insert
    BEGIN TRY
      INSERT INTO zmetric.keyTimeCounters (counterID, counterDate, columnID, keyID, value)
           SELECT @counterID, counterDate, columnID, keyID, value FROM @data ORDER BY columnID, keyID
      SET @insertCount = @@ROWCOUNT
    END TRY
    BEGIN CATCH
      UPDATE D SET D.value = X.value
        FROM @data X
          INNER JOIN zmetric.keyTimeCounters D ON D.counterID = @counterID AND D.columnID = X.columnID AND D.keyID = X.keyID AND D.counterDate = X.counterDate
       WHERE D.value != X.value
      SET @updateCount = @@ROWCOUNT

      INSERT INTO zmetric.keyTimeCounters (counterID, counterDate, columnID, keyID, value)
           SELECT @counterID, X.counterDate, X.columnID, X.keyID, X.value
             FROM @data X
               LEFT JOIN zmetric.keyTimeCounters D ON D.counterID = @counterID AND D.columnID = X.columnID AND D.keyID = X.keyID AND D.counterDate = X.counterDate
            WHERE D.counterID IS NULL
            ORDER BY X.columnID, X.keyID
      SET @insertCount = @@ROWCOUNT
    END CATCH

    EXEC zsystem.Events_TaskCompleted @eventID, @int_1=@counterID, @int_2=@dataCount, @int_3=@insertCount, @int_4=@updateCount
  END TRY
  BEGIN CATCH
    DECLARE @eventText nvarchar(max) = ERROR_MESSAGE()
    EXEC zsystem.Events_TaskError @eventID, @eventText, @int_1=@counterID, @int_2=@dataCount, @int_3=@insertCount, @int_4=@updateCount
    EXEC zsystem.CatchError 'metric.DoobJob_SaveTimeCounter'
    RETURN -1
  END CATCH

GO