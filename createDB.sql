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
        
 
 