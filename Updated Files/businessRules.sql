--Business Rules--
--Proposed business rules as discussed as a group, including prices, capacity, etc.

USE HolidayFun;
INSERT INTO Resort (resortid, name, street, suburb, state, postcode, country, phoneNumber, emailAddress, description)
VALUES 
(1, 'HolidayFun Main Resort', '1 Beach Rd', 'Waratah West', 'NSW', '2298', 'Australia',
 '02-4000-0000', 'info@holidayfun.com', 'Primary demo resort for HolidayFun');

INSERT INTO FacilityType (facilityTypeId, name, description, capacity) VALUES
(105, 'Pool', 'Outdoor resort pool', 30),
(104, 'Gym', 'Resort gym', 30),
(103, 'Restaurant/Bar', 'Restaurant and bar area', 30),
(102, 'Entertainment Centre', 'Entertainment center with movie room etc.', 25),
(101, 'Rooms', 'Guest rooms', 25);

INSERT INTO Facility (facilityId, name, description, status, resortid, facilityTypeId) VALUES
(105, 'Main Pool', 'Central outdoor pool', 'Available', 1, 105),
(104, 'Resort Gym', 'Cardio and weights area', 'Available', 1, 104),
(103, 'Main Restaurant & Bar', 'Buffet and bar service', 'Available', 1, 103),
(102, 'Entertainment Centre', 'Games and movie room', 'Available', 1, 102),
(101, 'Guest Rooms Block A', 'Standard guest rooms', 'Available', 1, 101);

INSERT INTO ServiceCategory (code, name, description, type) VALUES
('PS', 'Pool Services', 'Services provided at the pool area', 'Facility Service'),
('RS', 'Restaurant Services', 'Dining and buffet services', 'Food & Meals'),
('GS', 'Gym Services', 'Gym access and related services', 'Fitness'),
('ES', 'Entertainment Services', 'Entertainment centre services', 'Entertainment'),
('RRS', 'Room Services', 'In-room services for guests', 'Accommodation');

 INSERT INTO AdvertisedOffer (offerId, name, description, offerType, startDate, endDate, advertisedPrice, advertisedCurrency, inclusions, exclusions, status, gracePeriod, employeeId, serviceItemId, packageId)
 VALUES
 (1, 'Pool Cabana Day Pass', 'Full-day cabana rental by the pool', 'Service',
 '2026-03-01', '2026-12-31', 45.00, 'AUD',
 'Cabana rental, towel service', 'Food and drinks not included', 'Active', 2,
 1, 1051, NULL),
(2, 'Breakfast Buffet Special', 'Buffet breakfast promo', 'Service',
 '2026-03-01', '2026-12-31', 25.00, 'AUD',
 'All-you-can-eat breakfast buffet', 'Drinks above house selection', 'Active', 1,
 1, 1031, NULL),
(3, 'Gym All-Day Pass', 'Unlimited gym access for a day', 'Service',
 '2026-03-01', '2026-12-31', 15.00, 'AUD',
 'Access to all gym equipment', 'Personal training sessions', 'Active', 1,
 1, 1041, NULL),

(4, 'Weekend Getaway Package', '2 nights stay with breakfast included', 'Package',
 '2026-03-01', '2026-12-31', 499.00, 'AUD',
 '2 nights in standard room, daily breakfast', 'Airport transfers, minibar', 'Active', 7,
 1, NULL, 1),
(5, 'Family Fun Package', '3 nights with breakfast and movie room access', 'Package',
 '2026-03-01', '2026-12-31', 799.00, 'AUD',
 '3 nights in family room, breakfasts, movie room access', 'Room service meals', 'Active', 7,
 1, NULL, 2);

INSERT INTO Package (
    packageId, name, description
) VALUES
(1, 'Weekend Getaway', '2-night stay in a standard room with daily breakfast included'),
(2, 'Family Fun Stay', '3-night stay for a family with breakfast and movie room access'),
(3, 'Romantic Escape', '2-night stay for two with dinner set menu and late checkout'),
(4, 'Fitness & Wellness', '2-night stay with daily gym pass and healthy breakfast options'),
(5, 'Business Retreat', '1-night stay with conference room access and lunch buffet');


 INSERT INTO Employee (
    employeeId, name, role, contactNumber, email, location, authLevel
) VALUES
(1, 'Jane Manager', 'Front Office Manager', '02-4000-1001', 'jane.manager@holidayfun.com', 'HolidayFun Main Resort', 3),
(2, 'Tom Supervisor', 'Reservations Supervisor', '02-4000-1002', 'tom.supervisor@holidayfun.com', 'HolidayFun Main Resort', 2),
(3, 'Emily Clark', 'Marketing Executive', '02-4000-1003', 'emily.clark@holidayfun.com', 'HolidayFun Head Office', 2),
(4, 'Michael Lee', 'Billing Officer', '02-4000-1004', 'michael.lee@holidayfun.com', 'HolidayFun Main Resort', 1),
(5, 'Sarah Brown', 'General Manager', '02-4000-1005', 'sarah.brown@holidayfun.com', 'HolidayFun Main Resort', 4);

INSERT INTO ServiceItem (
    serviceItemId, name, description, restrictions, status,
    availableTimes, baseCost, baseCurrency, capacity, categoryCode, resortId
) VALUES
(1051, 'Cabana rental', 'Cabana rental at the pool', NULL, 'Available',
 '8:00 A.M - 5:00 P.M', 35.00, 'AUD', 30, 'PS', 1),

(1052, 'Poolside cocktail drinks', 'Cocktail drinks served poolside', NULL, 'Available',
 '10:00 A.M - 10:00 P.M', 20.00, 'AUD', 30, 'PS', 1),

(1031, 'Breakfast Buffet', 'Breakfast buffet at restaurant', NULL, 'Available',
 '8:00 A.M - 12:00 P.M', 18.00, 'AUD', 30, 'RS', 1),

(1032, 'Lunch Buffet', 'Lunch buffet at restaurant', NULL, 'Available',
 '12:00 P.M - 3:00 P.M', 23.00, 'AUD', 30, 'RS', 1),

(1034, 'Dinner Set Menu', 'Set menu dinner service', NULL, 'Available',
 '5:00 P.M - 10:00 P.M', 35.00, 'AUD', 30, 'RS', 1),

(1041, 'Gym pass', 'Access to resort gym', NULL, 'Available',
 '7:00 A.M - 11:00 P.M', 10.00, 'AUD', 30, 'GS', 1),

(1021, 'Movie room', 'Access to movie room in entertainment centre', NULL, 'Available',
 '10:00 A.M - 10:00 P.M', 20.00, 'AUD', 25, 'ES', 1),

(1011, 'In Room Dining', 'In-room dining service', NULL, 'Available',
 '10:00 A.M - 10:00 P.M', 30.00, 'AUD', 25, 'RRS', 1);
