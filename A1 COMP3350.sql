DROP DATABASE HolidayFun;

CREATE DATABASE HolidayFun;

USE HolidayFun;


CREATE TABLE Resort (
	resortid INT PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	address VARCHAR(255),
		street VARCHAR(255),
		suburb VARCHAR(255),
		state VARCHAR(50),
		postcode VARCHAR(10)
		);
        
CREATE TABLE FacilityType (
	id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255)
	); 
    
CREATE TABLE Facility (
	idFacility INT PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	description CHAR(255),
	status VARCHAR(255),
    
    FOREIGN KEY (resortid) REFERENCES Resort(resortid),
    FOREIGN KEY (facility_type_id) REFERENCES FacilityType(id)
);

CREATE TABLE ServiceCategory (
	code INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255)
);

CREATE TABLE ServiceItem (
	id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    restrictions VARCHAR(255),
    status VARCHAR(50),
    availableTimes VARCHAR(255),
    baseCost DECIMAL(10,2),
    baseCurrency CHAR(3),
    capacity INT,
    
    FOREIGN KEY (category_code) REFERENCES ServiceCategory(code)
);


CREATE TABLE AdvertisedService (
	id INT PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	description VARCHAR(255),
	startDate DATE,
	endDate DATE,
	advertisedPrice DECIMAL (10,2),
	advertisedCurrency CHAR(3),
	inclusions VARCHAR(255),
	exclusions VARCHAR(255),
	status VARCHAR(50),
	gracePeriod INT,
    
    FOREIGN KEY (service_item_id) REFERENCES ServiceItem(id)
);

CREATE TABLE Customer (
	id INT PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	address VARCHAR(255),
	contact VARCHAR(255),
	number VARCHAR(13),
	email VARCHAR(255),
    )
CREATE TABLE Reservation (
	reservationNo INT PRIMARY KEY,
    customerID INT NOT NULL,
    advertised_service_id INT NOT NULL,
    paymentInfo VARCHAR(255),
    
    FOREIGN KEY (customer_id) REFERENCES Customer(id),
    FOREIGN KEY (advertised_service_id) REFERENCES Advertised(d)
    );
    







   

    




