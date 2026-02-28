DROP DATABASE HolidayFun;

CREATE DATABASE HolidayFun;

USE HolidayFun;


CREATE TABLE Resort (
	resortid INT PRIMARY KEY NOT NULL,
	name VARCHAR(100) NOT NULL,
		street VARCHAR(100) NOT NULL,
		suburb VARCHAR(100) NOT NULL,
		state VARCHAR(50) NOT NULL,
		postcode VARCHAR(10) NOT NULL,
		country VARCHAR (255) NOT NULL,
		phoneNumber VARCHAR(20),
        emailAddress VARCHAR(100),
        description VARCHAR(255)
	);
        
CREATE TABLE FacilityType (
	facilityTypeId INT PRIMARY KEY NOT NULL,
	name VARCHAR(100) UNIQUE NOT NULL,
    description VARCHAR(255),
    capacity INT NOT NULL
	); 
    
CREATE TABLE Facility (
	facilityId INT PRIMARY KEY NOT NULL,
	name VARCHAR(100) NOT NULL,
	description CHAR(255),
	status VARCHAR(255),
    
    resortid INT NOT NULL,
    facilityTypeId INT NOT NULL,
    
    FOREIGN KEY (resortid) REFERENCES Resort(resortid)
		ON UPDATE CASCADE
        ON DELETE NO ACTION,
    FOREIGN KEY (facilityTypeId) REFERENCES FacilityType(facilityTypeId)
		ON UPDATE CASCADE
        ON DELETE NO ACTION
	);

CREATE TABLE ServiceCategory (
	code VARCHAR(20) PRIMARY KEY NOT NULL,
    name VARCHAR(100) UNIQUE NOT NULL,
    description VARCHAR(255),
    type VARCHAR(50)
	);

CREATE TABLE ServiceItem (
	serviceItemId INT PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    restrictions VARCHAR(255),
    status VARCHAR(50) NOT NULL,
    availableTimes VARCHAR(100),
    baseCost DECIMAL(10,2) NOT NULL,
    baseCurrency VARCHAR(10) NOT NULL,
    capacity INT NOT NULL,
    categoryCode VARCHAR(20) NOT NULL,
    resortId INT NOT NULL,
    
    FOREIGN KEY (categoryCode) REFERENCES ServiceCategory(code)
		ON UPDATE CASCADE
        ON DELETE NO ACTION,
	FOREIGN KEY (resortId) REFERENCES Resort(resortId)
		ON UPDATE CASCADE
        ON DELETE NO ACTION
	);

CREATE TABLE Package (
	packageId INT PRIMARY KEY NOT NULL,
	name VARCHAR(100) NOT NULL,
	description VARCHAR(255)
);

CREATE TABLE PackageService (
	packageId INT NOT NULL,
	serviceItemId INT NOT NULL,
    
    PRIMARY KEY(packageId, serviceItemId),
    
	FOREIGN KEY (packageId) REFERENCES Package(packageId)
		ON UPDATE CASCADE
		ON DELETE CASCADE,

	FOREIGN KEY (serviceItemId) REFERENCES ServiceItem(serviceItemId)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE Employee(
	employeeId INT PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    contactNumber VARCHAR(20),
    email VARCHAR(100),
    location VARCHAR(100),
    authLevel INT NOT NULL
    );
    
CREATE TABLE AdvertisedOffer (
	offerId INT PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	description VARCHAR(255),
	offerType VARCHAR(50) NOT NULL,
	startDate DATE NOT NULL,
    endDate DATE NOT NULL,
	advertisedPrice DECIMAL(10,2) NOT NULL,
	advertisedCurrency VARCHAR(10) NOT NULL,
	inclusions VARCHAR(255),
	exclusions VARCHAR(255),
	status VARCHAR(50) NOT NULL,
	gracePeriod INT NOT NULL,
    
	employeeId INT NOT NULL,
	serviceItemId INT,
	packageId INT,
    
    CHECK(
		(serviceItemId IS NOT NULL AND packageId IS NULL)
		OR
		(serviceItemId IS NULL AND packageId IS NOT NULL)
    ),
    
	FOREIGN KEY (employeeId) REFERENCES Employee(employeeId)
		ON UPDATE CASCADE
		ON DELETE NO ACTION,

	FOREIGN KEY (serviceItemId) REFERENCES ServiceItem(serviceItemId)
		ON UPDATE CASCADE
		ON DELETE CASCADE,

	FOREIGN KEY (packageId) REFERENCES Package(packageId)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE Customer (
	customerId INT PRIMARY KEY NOT NULL,
	name VARCHAR(100) NOT NULL,
	address VARCHAR(255) NOT NULL,
	contactNumber VARCHAR(20),
	email VARCHAR(100)
    );
    
CREATE TABLE Reservation (
	reservationNo INT PRIMARY KEY NOT NULL,
    customerID INT NOT NULL,
    paymentInfo VARCHAR(255), 
    
    FOREIGN KEY (customerId) REFERENCES Customer(customerId)
		ON UPDATE CASCADE
		ON DELETE NO ACTION,
        
	--FOREIGN KEY (PackageService) REFERENCES AdvertisedServicePackage(id)
    );
    
CREATE TABLE Booking (
	bookingId INT PRIMARY KEY NOT NULL,
    reservationNo INT NOT NULL,
    offerId INT NOT NULL,
    quantity INT NOT NULL,
    startDate DATE NOT NULL,
    endDate DATE NOT NULL,
    
    FOREIGN KEY (reservationNo) REFERENCES Reservation(reservationNo)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
    
    FOREIGN KEY (offerId) REFERENCES AdvertisedOffer(offerId)
		ON UPDATE CASCADE
		ON DELETE NO ACTION
);

CREATE TABLE FacilityBooking (
	facilityBookingId INT PRIMARY KEY NOT NULL,
	bookingId INT NOT NULL, 
	facilityId INT NOT NULL,
	startDateTime DATETIME NOT NULL,
	endDateTime DATETIME NOT NULL,

	FOREIGN KEY (bookingId) REFERENCES Booking(bookingId)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
        
	FOREIGN KEY (facilityId) REFERENCES Facility(facilityId)
		ON UPDATE CASCADE
		ON DELETE NO ACTION
    );
    
CREATE TABLE Guest (
	guestId INT PRIMARY KEY NOT NULL,
	reservationNo INT NOT NULL,
	name VARCHAR(100) NOT NULL,
	street VARCHAR(100),
	suburb VARCHAR(100),
	state VARCHAR(50),
	postcode VARCHAR(10),
	contactNumber VARCHAR(20),
	email VARCHAR(100),

	FOREIGN KEY (reservationNo) REFERENCES Reservation(reservationNo)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE Charge (
	chargeId INT PRIMARY KEY NOT NULL,
	bookingId INT NOT NULL,
	dateAndTime DATETIME NOT NULL,
	description VARCHAR(255),
	amount DECIMAL(10,2) NOT NULL,
	currency VARCHAR(10) NOT NULL,
	chargeType VARCHAR(50),
	source VARCHAR(100),
    
	FOREIGN KEY (bookingId) REFERENCES Booking(bookingId)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);
    
CREATE TABLE Payment (
	paymentId INT PRIMARY KEY NOT NULL,
    reservationNo INT NOT NULL,
	paymentDateAndTime DATE NOT NULL,
	amount DECIMAL(10,2) NOT NULL,
	currency VARCHAR(10) NOT NULL,
	method VARCHAR(50) NOT NULL,
    
    FOREIGN KEY (reservationNo) REFERENCES Reservation(reservationNo)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE Discount (
	discountId INT PRIMARY KEY NOT NULL,
    reservationNo INT NOT NULL,
    amount DECIMAL(10,2),
    percentage DECIMAL(5,2),
    reason VARCHAR(255),
    headOfficeAuthorisation BIT,
    appliedDateandTime DATETIME NOT NULL,
    
    FOREIGN KEY (reservationNo) REFERENCES Reservation(reservationNo)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);
        
 
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

    
