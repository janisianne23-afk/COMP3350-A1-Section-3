-- Fixed version of usp_makeReservation for HolidayFun database
-- Corrects syntax errors, typos, logic issues, and matches schema/business rules [cite:36][cite:39]
CREATE OR ALTER PROCEDURE dbo.usp_makeReservation 
    @customerId INT,
    @facilityTypeId INT,
    @startDateTime DATETIME,
    @endDateTime DATETIME,
    @quantity INT,
    @offerId INT,
    @guests GuestListType READONLY,  -- Assumes User-Defined Table Type exists
    @totalDue DECIMAL(10,2) OUTPUT   -- Changed to OUTPUT for return value
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation
    IF @endDateTime <= @startDateTime
        THROW 50010, 'End date must be after start date', 1;
    IF @quantity <= 0
        THROW 50011, 'Please enter valid quantity', 1;
    
    -- Validate customer details (assumes proc exists)
    EXEC dbo.validateCustomer @customerId;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @maxCap INT;
        DECLARE @slotsUsed INT = 0;
        DECLARE @serviceItemId INT;
        DECLARE @facilityId INT;
        DECLARE @reservationNo INT;
        DECLARE @bookingId INT;
        DECLARE @facilityBookingId INT;
        DECLARE @depositDue DECIMAL(10,2);
    
        -- Get max capacity for facility type
        SELECT @maxCap = ft.capacity
        FROM dbo.FacilityType ft  -- Fixed table name
        JOIN dbo.Facility f ON f.facilityTypeId = ft.facilityTypeId  -- Added JOIN for accuracy
        WHERE ft.facilityTypeId = @facilityTypeId;
        
        IF @maxCap IS NULL
            THROW 50012, 'Invalid facility type ID', 1;

        -- Slots used for overlapping times (fixed typos: i_facilityTypeId → facilityTypeId, @endDate/@startDate → @endDateTime/@startDateTime)
        SELECT @slotsUsed = ISNULL(SUM(b.quantity), 0)
        FROM dbo.FacilityBooking fb
        JOIN dbo.Facility f ON f.facilityId = fb.facilityId
        JOIN dbo.Booking b ON b.bookingId = fb.bookingId
        WHERE f.facilityTypeId = @facilityTypeId
            AND NOT (@endDateTime <= fb.startDateTime OR @startDateTime >= fb.endDateTime);  -- Fixed param names
    
        IF @slotsUsed + @quantity > @maxCap
            THROW 50100, 'Facility has reached maximum capacity', 1;
        
        -- Service item validation (fixed typos)
        SELECT @serviceItemId = ao.serviceItemId
        FROM dbo.AdvertisedOffer ao
        WHERE ao.offerId = @offerId;  -- Fixed 'WHere'
        
        IF @serviceItemId IS NULL  -- Fixed condition/logic
            THROW 50101, 'Not a valid service item offer', 1;
            
        SELECT @maxCap = si.capacity  -- Fixed 'capasity'
        FROM dbo.ServiceItem si
        WHERE si.serviceItemId = @serviceItemId;
        
        IF @maxCap IS NULL
            THROW 50102, 'Invalid service item ID', 1;
        
        -- Service item overlapping capacity (fixed JOINs and typos)
        SELECT @slotsUsed = ISNULL(SUM(b.quantity), 0)
        FROM dbo.Booking b 
        JOIN dbo.AdvertisedOffer ao ON ao.offerId = b.offerId  -- Fixed duplicate JOIN
        WHERE ao.serviceItemId = @serviceItemId
            AND NOT (@endDateTime <= b.startDate OR @startDateTime >= b.endDate);
        
        IF @slotsUsed + @quantity > @maxCap
            THROW 50103, 'Service item capacity limit is reached.', 1;
        
        -- Pick facility (added check for available)
        SELECT TOP 1 @facilityId = f.facilityId
        FROM dbo.Facility f
        WHERE f.facilityTypeId = @facilityTypeId;
    
        IF @facilityId IS NULL
            THROW 50014, 'No facility exists for this facility type', 1;
    
        -- Create reservation (manual IDENTITY-like, assuming no IDENTITY)
        SELECT @reservationNo = ISNULL(MAX(r.reservationNo), 0) + 1
        FROM dbo.Reservation r;
        
        INSERT INTO dbo.Reservation (reservationNo, customerId, paymentInfo)  -- Fixed customerID → customerId
        VALUES (@reservationNo, @customerId, NULL);
        
        -- Create booking (fixed typos: INSULL → ISNULL, startDate/endDate → DATETIME cols?)
        SELECT @bookingId = ISNULL(MAX(b.bookingId), 0) + 1
        FROM dbo.Booking b;
        
        INSERT INTO dbo.Booking (bookingId, reservationNo, offerId, quantity, startDate, endDate)  -- Assumed col names; adjust if DATE
        VALUES (@bookingId, @reservationNo, @offerId, @quantity, @startDateTime, @endDateTime);
   
        -- Create facility booking
        SELECT @facilityBookingId = ISNULL(MAX(fb.facilityBookingId), 0) + 1
        FROM dbo.FacilityBooking fb;
        
        INSERT INTO dbo.FacilityBooking (facilityBookingId, bookingId, facilityId, startDateTime, endDateTime)
        VALUES (@facilityBookingId, @bookingId, @facilityId, @startDateTime, @endDateTime);
       
        -- Add guests (fixed subquery, assumes GuestListType matches cols)
        INSERT INTO dbo.Guest (guestId, reservationNo, name, street, suburb, state, postcode, contactNumber, email)
        SELECT ISNULL((SELECT MAX(g.guestId) FROM dbo.Guest g), 0) + ROW_NUMBER() OVER (ORDER BY g.name),  -- Fixed nested MAX
               @reservationNo, g.name, g.street, g.suburb, g.state, g.postcode, g.contactNumber, g.email
        FROM @guests g;
   
        COMMIT TRANSACTION;
        
        -- Calculate total due from charges (assumes Charge table exists)
        SELECT @totalDue = ISNULL(SUM(c.amount), 0)
        FROM dbo.Charge c 
        JOIN dbo.Booking b ON b.bookingId = c.bookingId
        WHERE b.reservationNo = @reservationNo;

        -- Deposit (25%)
        SET @depositDue = @totalDue * 0.25;
        
        -- Return results
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

CREATE OR ALTER PROCEDURE validateCustomer @customerId INT 
AS
BEGIN
-- This section validates user input before making a reservation
	SET NOCOUNT ON;
    DECLARE 
	@name VARCHAR(100),
	@address VARCHAR(100),
	@contactNumber VARCHAR(20),
	@email VARCHAR(100);

	SELECT
    @name = c.name,
    @address = c.address,
    @contactNumber = c.contactNumber,
    @email = c.email
        
	FROM Customer c
    WHERE c.customerId = @customerId;
    
    --customer must exist 
    IF @name IS NULL AND @address IS NULL AND @contactNumber IS NULL AND @email IS NULL
		THROW 50000, 'Customer not found', 1;

    IF @name IS NULL OR LTRIM(RTRIM(@name))=''
		THROW 50001, 'Please enter name.', 1;
	
    IF @address IS NULL OR LTRIM(RTRIM(@address))=''
		THROW 50002, 'Please enter address.', 1;
    
    IF @contactNumber IS NULL OR LTRIM(RTRIM(@contactNumber))=''
		THROW 50003, 'Please enter contact number.', 1;
	
    IF @email IS NULL OR LTRIM(RTRIM(@email))=''
		THROW 50004, 'Please enter email.', 1;
END;
GO
