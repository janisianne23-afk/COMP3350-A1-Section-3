-- This section is for making the reservation with input parameters Customer,
 -- Booking, ServiceItem, Guest, FacilityBooking

CREATE OR ALTER PROCEDURE dbo.usp_makeReservation 
	@customerId INT,
    @facilityTypeId INT,
    @startDateTime DATETIME,
    @endDateTime DATETIME,
    @quantity INT,
    @offerId INT,
    @guests GuestListType READONLY
	@totalDue DECIMAL(10,2);
    AS
    BEGIN
		SET NOCOUNT ON;
        
        --validation
        IF @endDateTime <= @startDateTime
			THROW 50010, 'End date must be after start date',1;
		IF @quantity <=0
			THROW, 50011, 'Please enter valid quantity',1;
		
		--validate customer details
		EXEC validateCustomer @customerId = @customerId;
        BEGIN TRY
			BEGIN TRANSACTION;
            
			DECLARE @maxCap INT;
			DECLARE @slotsUsed INT DEFAULT 0;
			DECLARE @serviceItemId INT;
			DECLARE @facilityId INT;
            DECLARE @reservationNo INT;
            DECLARE @bookingId INT;
            DECLARE @facilityBookingId INT;
			DECLARE @depositDue DECIMAL(10,2);
    
			--get the maximum capacity for this facility type
			SELECT @maxCap =f.capacity
			FROM dbo.FacilityType ft
			WHERE ft.facilityTypeId = @facilityTypeId;
            
            IF @maxCap IS NULL
				THROW 50012, 'Invalid facility ID', 1;

			--total number that is already booked in overlapping times 
			SELECT @slotsUsed = ISNULL(sum(b.quantity), 0)
			FROM dbo.FacilityBooking fb
			JOIN dbo.Facility f ON f.facilityId = fb.facilityId
			JOIN Booking b ON b.bookingId = fb.bookingId
			WHERE f.facilityTypeId = i_facilityTypeId
				AND NOT (@endDate <= fb.startDateTime OR @startDate >= fb.endDateTime);
	
			IF @slotsUsed + @quantity > @maxCap
				THROW 50100, 'Facility has reached maximum capacity', 1;
			
            --serviceItem capacity chec
            SELECT @serviceItemId = ao.serviceItemId
            FROM dbo.AdvertisedOffer ao
            WHere ao.offerId = @offerId;
            
            IF @slotsUsed + @quantity > @maxCap
				THROW 50101, 'Not a valid service item offer', 1;
                
            SELECT @maxCap = si.capasity
            FROM dbo.ServiceItem si
            WHERE si.serviceItemId = @serviceItemId;
            
            IF @maxCap IS NULL
				THROW 50102, 'Invalid service item ID', 1;
			
            --capacity for overlaping window
            SELECT @slotsUsed = ISNULL(sum(b.quantity), 0)
			FROM dbo.Booking b 
			JOIN dbo.AdvertisedOffer ao ON ao.offerId = b.offerId
			JOIN Booking b ON b.bookingId = fb.bookingId
			WHERE ao.serviceItemId = @serviceItemId
				AND NOT (@endDate <= b.startDateTime OR @startDate >= b.endDateTime);
			
            IF @slotsUsed + @quantity > @maxCap
				THROW 50103, 'Service item capacity limit is reached.', 1;
			
            --pick a facilityId for booking
			SELECT TOP (1) @facilityId = f.facilityId
			FROM dbo.Facility f
			WHERE f.facilityTypeId = @facilityTypeId;
    
			IF @facilityId IS NULL
				THROW, 50014, 'No facility exists for this facility type',1;
    
			--create reservation by supplying a reservationNo
            SELECT @reservationNo = ISNULL(MAX(r.reservationNo), 0) + 1
            FROM dbo.Reservation r;
            
            INSERT INTO dbo.Reservation(reservationNo, customerID, paymentInfo)
            VALUES(@reservationNo, @customerId, NULL);
            
			--create booking
			SELECT @bookingId = INSULL(MAX(b.bookingId), 0) + 1
            FROM dbo.Booking b;
            
			INSERT INTO dbo.Booking(bookingId, reservationNo, offerId, quantity, startDate, endDate)
			VALUES(
				@bookingId, 
				@reservationNo, 
				@offerId, 
				@quantity, 
				CAST(@startDateTime AS DATE), 
				CAST (@endDateTime AS DATE)
            );
   
			
            SELECT @facilityBookingId = ISNULL(MAX(fb.facilityBookingId), 0) + 1
            FROM dbo.FacilityBooking fb;
            
            INSERT INTO dbo.FacilityBooking(facilityBookingId, bookingId, facilityId, startDateTime, endDateTime)
            VALUES (@facilityBookingId, @bookingId, @facilityId, @startDateTime, @endDateTime);
           
           --add guests (if they have guests with them)
            INSERT INTO dbo.Guest (guestId, reservationNo, name, street, suburb, state,
            postcode, contactNumber, email)
            SELECT
				(SELECT ISNULL(MAX(g1.guestId), 0) FROM Guest g1) + ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS guestId,
                @reservationNo,
                g.name, g.street,g.suburb, g.state, g.postcode, g.contactNumber, g.email
			FROM @guests g;
   
			COMMIT TRANSACTION;
            
            --return confirmation
            SELECT @reservationNo AS ReservationNo, @bookingId AS BookingId, @facilityBookingId AS FacilityBookingId;

			--process/add payment
			SELECT @totalDue = ISNULL(SUM(c.amount),0)
			FROM dbo.Charge c 
			JOIN dbo.Booking b ON b.bookingId = c.bookingId
			WHERE b.reservationNo = @reservationNo;

			--calculate deposit due 
			SET @depositDue = CAST(@totalDue * 0.25 AS DECIMAL(10,2));

		END TRY

		SELECT @reservationNo AS ReservationNo,
		@totalDue AS TotalAmountDue,
		@depositDue AS DepositDue,
		
		BEGIN CATCH
			IF @@TRANCOUNT >0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH

END;
GO

    