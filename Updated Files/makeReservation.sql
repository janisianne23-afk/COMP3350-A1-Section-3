--MakeReservation procedure
-- procedure for adding data onto database from Spring Boot project


CREATE OR ALTER PROCEDURE dbo.usp_makeReservation 
    @customerName VARCHAR(100),
    @customerAddress VARCHAR(255),
    @customerPhone VARCHAR(20),
    @customerEmail VARCHAR(100),
    @facilityTypeId INT,
    @startDateTime DATETIME,
    @endDateTime DATETIME,
    @quantity INT,
    @offerId INT,
    @guests GuestListType READONLY,  
    @totalDue DECIMAL(10,2) OUTPUT   
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @endDateTime <= @startDateTime
        THROW 50010, 'End date must be after start date', 1;
    IF @quantity <= 0
        THROW 50011, 'Please enter valid quantity', 1;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @customerId INT;
        DECLARE @maxCap INT;
        DECLARE @slotsUsed INT = 0;
        DECLARE @serviceItemId INT;
        DECLARE @facilityId INT;
        DECLARE @reservationNo INT;
        DECLARE @bookingId INT;
        DECLARE @facilityBookingId INT;
        DECLARE @depositDue DECIMAL(10,2);
    
        EXEC dbo.validateCustomer @customerName, @customerAddress, @customerPhone, @customerEmail, @customerId OUTPUT;
       
        SELECT @maxCap = ft.capacity
        FROM dbo.FacilityType ft 
        JOIN dbo.Facility f ON f.facilityTypeId = ft.facilityTypeId  
        WHERE ft.facilityTypeId = @facilityTypeId;
        
        IF @maxCap IS NULL
            THROW 50012, 'Invalid facility type ID', 1;

        SELECT @slotsUsed = ISNULL(SUM(b.quantity), 0)
        FROM dbo.FacilityBooking fb
        JOIN dbo.Facility f ON f.facilityId = fb.facilityId
        JOIN dbo.Booking b ON b.bookingId = fb.bookingId
        WHERE f.facilityTypeId = @facilityTypeId
            AND NOT (@endDateTime <= fb.startDateTime OR @startDateTime >= fb.endDateTime);  -- Fixed param names
    
        IF @slotsUsed + @quantity > @maxCap
            THROW 50100, 'Facility has reached maximum capacity', 1;
        
        SELECT @serviceItemId = ao.serviceItemId
        FROM dbo.AdvertisedOffer ao
        WHERE ao.offerId = @offerId;  

        IF @serviceItemId IS NULL  
            THROW 50101, 'Not a valid service item offer', 1;
            
        SELECT @maxCap = si.capacity 
        FROM dbo.ServiceItem si
        WHERE si.serviceItemId = @serviceItemId;
        
        IF @maxCap IS NULL
            THROW 50102, 'Invalid service item ID', 1;
        
        
        SELECT @slotsUsed = ISNULL(SUM(b.quantity), 0)
        FROM dbo.Booking b 
        JOIN dbo.AdvertisedOffer ao ON ao.offerId = b.offerId  
        WHERE ao.serviceItemId = @serviceItemId
            AND NOT (@endDateTime <= b.startDate OR @startDateTime >= b.endDate);
        
        IF @slotsUsed + @quantity > @maxCap
            THROW 50103, 'Service item capacity limit is reached.', 1;
        
        
        SELECT TOP 1 @facilityId = f.facilityId
        FROM dbo.Facility f
        WHERE f.facilityTypeId = @facilityTypeId;
    
        IF @facilityId IS NULL
            THROW 50014, 'No facility exists for this facility type', 1;
    
       
        SELECT @reservationNo = ISNULL(MAX(r.reservationNo), 0) + 1
        FROM dbo.Reservation r;
        
        INSERT INTO dbo.Reservation (reservationNo, customerId, paymentInfo)
        VALUES (@reservationNo, @customerId, NULL);
        
        SELECT @bookingId = ISNULL(MAX(b.bookingId), 0) + 1
        FROM dbo.Booking b;
        
        INSERT INTO dbo.Booking (bookingId, reservationNo, offerId, quantity, startDate, endDate)  
        VALUES (@bookingId, @reservationNo, @offerId, @quantity, CAST(@startDateTime AS DATE), CAST(@endDateTime AS DATE));
   
        SELECT @facilityBookingId = ISNULL(MAX(fb.facilityBookingId), 0) + 1
        FROM dbo.FacilityBooking fb;
        
        INSERT INTO dbo.FacilityBooking (facilityBookingId, bookingId, facilityId, startDateTime, endDateTime)
        VALUES (@facilityBookingId, @bookingId, @facilityId, @startDateTime, @endDateTime);
       
       DECLARE @nextGuestId INT = ISNULL((SELECT MAX(guestId) FROM dbo.Guest), 0) + 1;

        INSERT INTO dbo.Guest (guestId, reservationNo, name, street, suburb, state, postcode, contactNumber, email)
        SELECT @nextGuestId + ROW_NUMBER() OVER (ORDER BY g.name), @reservationNo, g.name, g.street, g.suburb, g.state, g.postcode, g.contactNumber, g.email
        FROM @guests g;
   
        COMMIT TRANSACTION;
        
        SELECT @totalDue = 0;
        SELECT @totalDue = ao.advertisedPrice * @quantity
        FROM dbo.AdvertisedOffer ao WHERE ao.offerId = @offerId;

        SET @depositDue = @totalDue * 0.25;
        
        SELECT @reservationNo AS ReservationNo, 
               @bookingId AS BookingId, 
               @facilityBookingId AS FacilityBookingId,
               @totalDue AS TotalAmountDue,
               @depositDue AS DepositDue;
               
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.validateCustomer 
    @name VARCHAR(100),
    @address VARCHAR(255),
    @contactNumber VARCHAR(20),
    @email VARCHAR(100),
    @customerId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF LTRIM(RTRIM(@name)) = '' OR @address = '' OR LTRIM(RTRIM(@contactNumber)) = '' OR @email = ''
        THROW 50001, 'Missing customer details', 1;

    SELECT @customerId = customerId FROM dbo.Customer 
    WHERE name = @name AND address = @address AND (contactNumber = @contactNumber OR email = @email);
    
    IF @customerId IS NULL
    BEGIN
        SELECT @customerId = ISNULL(MAX(customerId), 0) + 1 FROM dbo.Customer;
        INSERT INTO dbo.Customer (customerId, name, address, contactNumber, email)
        VALUES (@customerId, @name, @address, @contactNumber, @email);
    END
END;
GO


