--JsonMakeReservation procedure
--Json value converter file, for transferring data between Spring Boot project and SQL database

CREATE OR ALTER PROCEDURE dbo.usp_makeReservationWrapper
    @customerName      VARCHAR(100),
    @customerAddress   VARCHAR(255),
    @customerPhone     VARCHAR(20),
    @customerEmail     VARCHAR(100),
    @facilityTypeId    INT,
    @startDateTime     DATETIME,
    @endDateTime       DATETIME,
    @quantity          INT,
    @offerId           INT,
    @guestsJson        NVARCHAR(MAX),      
    @totalDue          DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Guests GuestListType;

    INSERT INTO @Guests (name, street, suburb, state, postcode, contactNumber, email)
    SELECT 
        JSON_VALUE(g.value, '$.name'),
        JSON_VALUE(g.value, '$.street'),
        JSON_VALUE(g.value, '$.suburb'),
        JSON_VALUE(g.value, '$.state'),
        JSON_VALUE(g.value, '$.postcode'),
        JSON_VALUE(g.value, '$.contactNumber'),
        JSON_VALUE(g.value, '$.email')
    FROM OPENJSON(@guestsJson) g;

    EXEC dbo.usp_makeReservation
        @customerName    = @customerName,
        @customerAddress = @customerAddress,
        @customerPhone   = @customerPhone,
        @customerEmail   = @customerEmail,
        @facilityTypeId  = @facilityTypeId,
        @startDateTime   = @startDateTime,
        @endDateTime     = @endDateTime,
        @quantity        = @quantity,
        @offerId         = @offerId,
        @guests          = @Guests,
        @totalDue        = @totalDue OUTPUT;
END;
GO
