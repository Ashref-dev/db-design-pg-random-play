-- Sample Customers for Random Play Video Tape Store

-- Clear any existing data
TRUNCATE customers CASCADE;

-- Insert customers with varied registration dates
INSERT INTO customers (first_name, last_name, email, phone, address, registration_date, active) VALUES
('John', 'Smith', 'john.smith@email.com', '555-1234', '123 Main St, Anytown, USA', '2022-01-15', TRUE),
('Emily', 'Johnson', 'emily.j@email.com', '555-2345', '456 Oak Ave, Someville, USA', '2022-02-03', TRUE),
('Michael', 'Williams', 'michael.w@email.com', '555-3456', '789 Pine Rd, Othertown, USA', '2022-01-22', TRUE),
('Sarah', 'Brown', 'sarah.b@email.com', '555-4567', '101 Maple Dr, Newcity, USA', '2022-02-14', TRUE),
('David', 'Jones', 'david.jones@email.com', '555-5678', '202 Cedar Ln, Oldtown, USA', '2022-03-10', TRUE),
('Jessica', 'Garcia', 'jessica.g@email.com', '555-6789', '303 Birch Blvd, Westville, USA', '2022-01-30', TRUE),
('Daniel', 'Martinez', 'daniel.m@email.com', '555-7890', '404 Elm Ct, Easttown, USA', '2022-02-20', TRUE),
('Lisa', 'Rodriguez', 'lisa.r@email.com', '555-8901', '505 Walnut Pl, Southtown, USA', '2022-03-05', TRUE),
('James', 'Hernandez', 'james.h@email.com', '555-9012', '606 Spruce Ave, Northtown, USA', '2022-01-10', TRUE),
('Jennifer', 'Lopez', 'jennifer.l@email.com', '555-0123', '707 Fir St, Centertown, USA', '2022-02-28', TRUE),
('Robert', 'Lee', 'robert.l@email.com', '555-1235', '808 Redwood Dr, Uptown, USA', '2022-03-12', TRUE),
('Patricia', 'Walker', 'patricia.w@email.com', '555-2346', '909 Cherry Ln, Downtown, USA', '2022-01-25', TRUE),
('Christopher', 'Hall', 'chris.h@email.com', '555-3457', '111 Ash Rd, Midtown, USA', '2022-02-08', FALSE),
('Elizabeth', 'Young', 'elizabeth.y@email.com', '555-4568', '222 Poplar Ct, Suburb, USA', '2022-03-18', TRUE),
('Matthew', 'Allen', 'matthew.a@email.com', '555-5679', '333 Hawthorn Pl, Ruraltown, USA', '2022-01-05', TRUE),
('Linda', 'King', 'linda.k@email.com', '555-6780', '444 Cypress Ave, Urbanville, USA', '2022-02-17', TRUE),
('William', 'Wright', 'william.w@email.com', '555-7891', '555 Magnolia Dr, Villageton, USA', '2022-03-01', FALSE),
('Barbara', 'Scott', 'barbara.s@email.com', '555-8902', '666 Juniper Rd, Hamletville, USA', '2022-01-20', TRUE),
('Richard', 'Green', 'richard.g@email.com', '555-9013', '777 Willow Ln, Townsville, USA', '2022-02-11', TRUE),
('Susan', 'Baker', 'susan.b@email.com', '555-0124', '888 Sycamore St, Cityburg, USA', '2022-03-22', TRUE);

-- Display inserted data
SELECT * FROM customers ORDER BY customer_id; 