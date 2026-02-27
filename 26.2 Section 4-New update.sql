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

CREATE OR ALTER PROCEDURE validateCustomer @customerId INT 
AS
BEGIN
-- This section validates user input before making a reservation
	SET NOCOUNT ON;
    DECLARE 
	@name VARCHAR(100),
	@address VARCHAR(100),
	@phoneNumber VARCHAR(20),
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
		THROW, 50000, 'Customer not found', 1;

    IF @name IS NULL OR LTRIM(RTIM(@name))=''
		THROW 50001, 'Please enter name.', 1;
	
    IF @address IS NULL OR LTRIM(RTIM(@address))=''
		THROW 50002, 'Please enter address.', 1;
    
    IF @contactNumber IS NULL OR LTRIM(RTIM(@contactNumber))=''
		THROW 50003, 'Please enter contact number.', 1;
	
    IF @email IS NULL OR LTRIM(RTIM(@email))=''
		THROW 50004, 'Please enter email.', 1;
END;
GO
        
 
 -- This section is for making the reservation with input parameters Customer,
 -- Booking, ServiceItem, Guest, FacilityBooking

CREATE OR ALTER PROCEDURE usp_makeReservation 
	@customerId INT,
    @facilityTypeId INT,
    @startDateTime DATETIME,
    @endDateTime DATETIME,
    @quantity INT,
    @offerId INT,
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
			DECLARE @slotsUSed INT DEFAULT 0;
			DECLARE @facilityId INT;
    
			--get the maximum capacity for this facility type
			SELECT @maxCap =f.capacity
			FROM FacilityType f
			WHERE f.facilityTypeId = @facilityTypeId;
    
			--total number that is already booked in overlapping times 
			SELECT @slotsUsed = ISNULL(sum(b.quantity), 0)
			FROM FacilityBooking fb
			JOIN Facility f ON f.facilityId = fb.facilityId
			JOIN Booking b ON b.bookingId = fb.bookingId
			WHERE f.facilityTypeId = i_facilityTypeId
				AND NOT (@endDate <= fb.startDateTime OR @startDate >= fb.endDateTime);
	
			IF @slotsUsed + @quantity > @maxCap
				THROW 50013, 'Facility has reached maximum capacity', 1;
			
            --pick a facilityId for booking
			SELECT TOP (1) @facilityId = f.facilityId
			FROM Facility f
			WHERE f.facilityTypeId = @facilityTypeId;
    
			IF @facilityId IS NULL
				THROW, 50014, 'No facility exists for this facility type',1;
    
			--create reservation by supplying a reservationNo
            DECLARE @reservationNo INT = (SELECT ISNULL(MAX(reservationNo), 0)+1 FROM Reservation);
            INSERT INTO Reservation(reservationNo, customerId, paymentInfo)
            VALUES(@reservationNo, @customerId, NULL);
            
			--create booking
			DECLARE @reservationNo INT = (SELECT ISNULL(MAX(bookingId), 0) + 1 FROM Booking);
			INSERT INTO Booking(bookingId, reservationNo, offerId, quantity, startDate, endDate);
			VALUES(@bookingId, @reservationNo, @offerId, @quantity, CAST(@startDateTime AS DATE), CAST (@endDateTime AS DATE));
   
			--create FacilityBooking
			DECLARE @facilityBookingId INT = (SELECT ISNULL(MAX(facilityBookingId), 0) + 1 FROM FacilityBooking);
			INSERT INTO FacilityBooking(facilityBookingId, bookingId, facilityId, startDateTIme, endDateTime)
			VALUES (@facilityBookingId, @bookingId, @facilityId, @startDateTime, @endDateTime);
			--create FacilityBooking
			COMMIT TRANSACTION;

		END TRY
		BEGIN CATCH
			IF @@TRANSCOUNT >0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH

END;
GO

    
