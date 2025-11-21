drop database BloodOrganManagement;
-- BloodOrganManagement_full.sql
-- Complete SQL script: schema + sample data + functions + procedures + triggers + event
-- Safe to re-run: drops database if exists then creates it

CREATE DATABASE BloodOrganManagement;
USE BloodOrganManagement;

-- =========================
-- TABLES (schema)
-- =========================
CREATE TABLE Donor (
    Donor_ID INT PRIMARY KEY AUTO_INCREMENT,
    Donor_Name VARCHAR(50) NOT NULL,
    DOB DATE NOT NULL,
    Gender ENUM('Male', 'Female', 'Other'),
    Blood_Group VARCHAR(5) NOT NULL,
    Street VARCHAR(50),
    City VARCHAR(30),
    State VARCHAR(30),
    Email VARCHAR(50)
);

CREATE TABLE Donor_Contact (
    Donor_ID INT,
    Contact_no VARCHAR(15),
    PRIMARY KEY (Donor_ID, Contact_no),
    FOREIGN KEY (Donor_ID) REFERENCES Donor(Donor_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Recipient (
    Recipient_ID INT PRIMARY KEY AUTO_INCREMENT,
    Recipient_Name VARCHAR(50) NOT NULL,
    DOB DATE NOT NULL,
    Gender ENUM('Male', 'Female', 'Other'),
    Blood_Group VARCHAR(5),
    Street VARCHAR(50),
    City VARCHAR(30),
    State VARCHAR(30),
    Email VARCHAR(50)
);

CREATE TABLE Recipient_Contact (
    Recipient_ID INT,
    Contact_no VARCHAR(15),
    PRIMARY KEY (Recipient_ID, Contact_no),
    FOREIGN KEY (Recipient_ID) REFERENCES Recipient(Recipient_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Hospital (
    Hospital_ID INT PRIMARY KEY AUTO_INCREMENT,
    Hospital_Name VARCHAR(100) NOT NULL,
    Street VARCHAR(50),
    City VARCHAR(30),
    State VARCHAR(30)
);

CREATE TABLE Hospital_Contact (
    Hospital_ID INT,
    Contact_no VARCHAR(15),
    PRIMARY KEY (Hospital_ID, Contact_no),
    FOREIGN KEY (Hospital_ID) REFERENCES Hospital(Hospital_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Doctor (
    Doctor_ID INT PRIMARY KEY AUTO_INCREMENT,
    Doctor_Name VARCHAR(50) NOT NULL,
    Speciality VARCHAR(50),
    Hospital_ID INT,
    FOREIGN KEY (Hospital_ID) REFERENCES Hospital(Hospital_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE Doctor_Contact (
    Doctor_ID INT,
    Contact_no VARCHAR(15),
    PRIMARY KEY (Doctor_ID, Contact_no),
    FOREIGN KEY (Doctor_ID) REFERENCES Doctor(Doctor_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE BloodUnit (
    BloodUnit_ID INT PRIMARY KEY AUTO_INCREMENT,
    Blood_Group VARCHAR(5) NOT NULL,
    Donation_Date DATE NOT NULL,
    Expiry_Date DATE,
    Status ENUM('Available', 'Used', 'Expired') DEFAULT 'Available',
    Donor_ID INT,
    Hospital_ID INT,
    FOREIGN KEY (Donor_ID) REFERENCES Donor(Donor_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    FOREIGN KEY (Hospital_ID) REFERENCES Hospital(Hospital_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE Organ (
    Organ_ID INT PRIMARY KEY AUTO_INCREMENT,
    Type VARCHAR(50) NOT NULL,
    Donation_Date DATE,
    Expiry_Date DATE,
    Status ENUM('Available', 'Used', 'Expired') DEFAULT 'Available',
    Donor_ID INT,
    Hospital_ID INT,
    FOREIGN KEY (Donor_ID) REFERENCES Donor(Donor_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    FOREIGN KEY (Hospital_ID) REFERENCES Hospital(Hospital_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE Transplant (
    Transplant_ID INT PRIMARY KEY AUTO_INCREMENT,
    Type ENUM('Organ', 'Blood') NOT NULL,
    Transplant_Date DATE NOT NULL,
    Recipient_ID INT,
    Doctor_ID INT,
    Hospital_ID INT,
    BloodUnit_ID INT,
    Organ_ID INT,
    FOREIGN KEY (Recipient_ID) REFERENCES Recipient(Recipient_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    FOREIGN KEY (Doctor_ID) REFERENCES Doctor(Doctor_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    FOREIGN KEY (Hospital_ID) REFERENCES Hospital(Hospital_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    FOREIGN KEY (BloodUnit_ID) REFERENCES BloodUnit(BloodUnit_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    FOREIGN KEY (Organ_ID) REFERENCES Organ(Organ_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- =========================
-- SAMPLE DATA
-- (keeps your original sample rows)
-- =========================

INSERT INTO Donor (Donor_Name, DOB, Gender, Blood_Group, Street, City, State, Email)
VALUES 
('Asha R', '1990-03-21', 'Female', 'O+', 'MG Road', 'Bangalore', 'Karnataka', 'asha@mail.com'),
('Rahul S', '1988-07-10', 'Male', 'B+', 'JP Nagar', 'Mysore', 'Karnataka', 'rahul@mail.com'),
('Sneha K', '1995-09-05', 'Female', 'A-', 'Gandhi St', 'Chennai', 'Tamil Nadu', 'sneha@mail.com'),
('Vikram D', '1992-01-18', 'Male', 'AB+', 'Race Course', 'Coimbatore', 'Tamil Nadu', 'vikram@mail.com');

INSERT INTO Donor_Contact VALUES
(1, '9876543210'), (1, '9900011122'),
(2, '9988776655'),
(3, '9123456780'), (3, '9234567890'),
(4, '9345678901');

INSERT INTO Recipient (Recipient_Name, DOB, Gender, Blood_Group, Street, City, State, Email)
VALUES 
('Manoj P', '1985-02-14', 'Male', 'O+', 'KR Market', 'Bangalore', 'Karnataka', 'manoj@mail.com'),
('Deepa L', '1993-11-29', 'Female', 'A-', 'Park Road', 'Chennai', 'Tamil Nadu', 'deepa@mail.com'),
('Ravi T', '1989-06-22', 'Male', 'B+', 'Vijayanagar', 'Mysore', 'Karnataka', 'ravi@mail.com'),
('Kavya N', '1998-04-10', 'Female', 'AB+', 'Gandhi Bazaar', 'Coimbatore', 'Tamil Nadu', 'kavya@mail.com');

INSERT INTO Recipient_Contact VALUES
(1, '9345678901'),
(2, '9876501234'), (2, '9834567890'),
(3, '9123409876'),
(4, '9000088888');

INSERT INTO Hospital (Hospital_Name, Street, City, State)
VALUES 
('Apollo Hospital', 'Bannerghatta Road', 'Bangalore', 'Karnataka'),
('Fortis Hospital', 'Adyar', 'Chennai', 'Tamil Nadu'),
('KMC Hospital', 'Vijayanagar', 'Mysore', 'Karnataka'),
('Ganga Hospital', 'RS Puram', 'Coimbatore', 'Tamil Nadu');

INSERT INTO Hospital_Contact VALUES
(1, '08026667788'), (1, '08026667789'),
(2, '0442345678'),
(3, '0821223344'),
(4, '0422233445'), (4, '0422233446');

INSERT INTO Doctor (Doctor_Name, Speciality, Hospital_ID)
VALUES 
('Dr. Nisha Kumar', 'Transplant Surgeon', 1),
('Dr. Raghav Menon', 'Cardiologist', 2),
('Dr. Ameer Khan', 'Hematologist', 3),
('Dr. Priya Rao', 'Nephrologist', 4);

INSERT INTO Doctor_Contact VALUES
(1, '9812345678'),
(2, '9823456789'),
(3, '9834567890'),
(4, '9845678901');

INSERT INTO BloodUnit (Blood_Group, Donation_Date, Expiry_Date, Status, Donor_ID, Hospital_ID)
VALUES 
('O+', '2025-09-01', '2025-10-01', 'Available', 1, 1),
('B+', '2025-08-15', '2025-09-15', 'Used', 2, 1),
('A-', '2025-09-10', '2025-10-10', 'Available', 3, 2),
('AB+', '2025-09-20', '2025-10-20', 'Available', 4, 3);

INSERT INTO Organ (Type, Donation_Date, Expiry_Date, Status, Donor_ID, Hospital_ID)
VALUES 
('Kidney', '2025-08-20', '2025-09-30', 'Used', 1, 1),
('Heart', '2025-09-05', '2025-10-20', 'Available', 2, 2),
('Liver', '2025-09-15', '2025-10-25', 'Available', 3, 3),
('Lung', '2025-09-10', '2025-10-20', 'Used', 4, 4);

INSERT INTO Transplant (Type, Transplant_Date, Recipient_ID, Doctor_ID, Hospital_ID, BloodUnit_ID, Organ_ID)
VALUES
('Blood', '2025-09-10', 1, 1, 1, 2, NULL),
('Organ', '2025-09-25', 2, 2, 2, NULL, 1),
('Blood', '2025-09-20', 3, 3, 3, 4, NULL),
('Organ', '2025-09-28', 4, 4, 4, NULL, 4);

-- =========================
-- FUNCTIONS
-- =========================

DELIMITER //
CREATE FUNCTION GetDonorAge(dob DATE) RETURNS INT
DETERMINISTIC
BEGIN
  RETURN TIMESTAMPDIFF(YEAR, dob, CURDATE());
END;
//

DELIMITER //
CREATE FUNCTION IsExpired_Blood(bid INT) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE exp DATE;
  SELECT Expiry_Date INTO exp FROM BloodUnit WHERE BloodUnit_ID = bid;
  RETURN exp IS NOT NULL AND exp < CURDATE();
END;
//

DELIMITER //
CREATE FUNCTION IsExpired_Organ(oid INT) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE exp DATE;
  SELECT Expiry_Date INTO exp FROM Organ WHERE Organ_ID = oid;
  RETURN exp IS NOT NULL AND exp < CURDATE();
END;
//
DELIMITER ;

-- =========================
-- PROCEDURES: Create / Update / Delete / Select helpers
-- =========================

DELIMITER //
CREATE PROCEDURE AddDonor (
  IN p_name VARCHAR(50),
  IN p_dob DATE,
  IN p_gender ENUM('Male','Female','Other'),
  IN p_blood VARCHAR(5),
  IN p_street VARCHAR(50),
  IN p_city VARCHAR(30),
  IN p_state VARCHAR(30),
  IN p_email VARCHAR(50)
)
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Donor name required';
  END IF;
  INSERT INTO Donor (Donor_Name, DOB, Gender, Blood_Group, Street, City, State, Email)
  VALUES (p_name, p_dob, p_gender, p_blood, p_street, p_city, p_state, p_email);
END;
//

DELIMITER //
CREATE PROCEDURE UpdateDonor (
  IN p_id INT,
  IN p_name VARCHAR(50),
  IN p_dob DATE,
  IN p_gender ENUM('Male','Female','Other'),
  IN p_blood VARCHAR(5),
  IN p_street VARCHAR(50),
  IN p_city VARCHAR(30),
  IN p_state VARCHAR(30),
  IN p_email VARCHAR(50)
)
BEGIN
  IF p_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Donor ID required for update';
  END IF;
  UPDATE Donor SET Donor_Name=p_name, DOB=p_dob, Gender=p_gender, Blood_Group=p_blood, Street=p_street, City=p_city, State=p_state, Email=p_email
  WHERE Donor_ID=p_id;
END;
//

DELIMITER //
CREATE PROCEDURE DeleteDonor (IN p_id INT)
BEGIN
  IF p_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Donor ID required for delete';
  END IF;
  DELETE FROM Donor WHERE Donor_ID = p_id;
END;
//

DELIMITER //
CREATE PROCEDURE AddRecipient (
  IN p_name VARCHAR(50),
  IN p_dob DATE,
  IN p_gender ENUM('Male','Female','Other'),
  IN p_blood VARCHAR(5),
  IN p_street VARCHAR(50),
  IN p_city VARCHAR(30),
  IN p_state VARCHAR(30),
  IN p_email VARCHAR(50)
)
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Recipient name required';
  END IF;
  INSERT INTO Recipient (Recipient_Name, DOB, Gender, Blood_Group, Street, City, State, Email)
  VALUES (p_name, p_dob, p_gender, p_blood, p_street, p_city, p_state, p_email);
END;
//

DELIMITER //
CREATE PROCEDURE UpdateRecipient (
  IN p_id INT,
  IN p_name VARCHAR(50),
  IN p_dob DATE,
  IN p_gender ENUM('Male','Female','Other'),
  IN p_blood VARCHAR(5),
  IN p_street VARCHAR(50),
  IN p_city VARCHAR(30),
  IN p_state VARCHAR(30),
  IN p_email VARCHAR(50)
)
BEGIN
  IF p_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Recipient ID required for update';
  END IF;
  UPDATE Recipient SET Recipient_Name=p_name, DOB=p_dob, Gender=p_gender, Blood_Group=p_blood, Street=p_street, City=p_city, State=p_state, Email=p_email
  WHERE Recipient_ID=p_id;
END;
//

DELIMITER //
CREATE PROCEDURE DeleteRecipient (IN p_id INT)
BEGIN
  IF p_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Recipient ID required for delete';
  END IF;
  DELETE FROM Recipient WHERE Recipient_ID = p_id;
END;
//

DELIMITER //
CREATE PROCEDURE AddHospital (
  IN p_name VARCHAR(100),
  IN p_street VARCHAR(50),
  IN p_city VARCHAR(30),
  IN p_state VARCHAR(30)
)
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hospital name required';
  END IF;
  INSERT INTO Hospital (Hospital_Name, Street, City, State) VALUES (p_name, p_street, p_city, p_state);
END;
//

DELIMITER //
CREATE PROCEDURE UpdateHospital (
  IN p_id INT,
  IN p_name VARCHAR(100),
  IN p_street VARCHAR(50),
  IN p_city VARCHAR(30),
  IN p_state VARCHAR(30)
)
BEGIN
  IF p_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hospital ID required for update';
  END IF;
  UPDATE Hospital SET Hospital_Name=p_name, Street=p_street, City=p_city, State=p_state WHERE Hospital_ID=p_id;
END;
//

DELIMITER //
CREATE PROCEDURE DeleteHospital (IN p_id INT)
BEGIN
  IF p_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hospital ID required for delete';
  END IF;
  DELETE FROM Hospital WHERE Hospital_ID = p_id;
END;
//

DELIMITER //
CREATE PROCEDURE AddDoctor (
  IN p_name VARCHAR(50),
  IN p_speciality VARCHAR(50),
  IN p_hospital INT
)
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor name required';
  END IF;
  INSERT INTO Doctor (Doctor_Name, Speciality, Hospital_ID)
  VALUES (p_name, p_speciality, p_hospital);
END;
//

DELIMITER //
CREATE PROCEDURE UpdateDoctor (
  IN p_id INT,
  IN p_name VARCHAR(50),
  IN p_speciality VARCHAR(50),
  IN p_hospital INT
)
BEGIN
  IF p_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor ID required for update';
  END IF;
  UPDATE Doctor SET Doctor_Name=p_name, Speciality=p_speciality, Hospital_ID=p_hospital WHERE Doctor_ID=p_id;
END;
//

DELIMITER //
CREATE PROCEDURE DeleteDoctor (IN p_id INT)
BEGIN
  IF p_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor ID required for delete';
  END IF;
  DELETE FROM Doctor WHERE Doctor_ID = p_id;
END;
//

DELIMITER //
CREATE PROCEDURE AddBloodUnit (
  IN p_group VARCHAR(5),
  IN p_donation DATE,
  IN p_expiry DATE,
  IN p_donor INT,
  IN p_hospital INT
)
BEGIN
  IF p_group IS NULL OR TRIM(p_group) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Blood group required';
  END IF;
  IF p_expiry IS NOT NULL AND p_expiry < CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Expiry date is in the past - cannot insert expired blood';
  END IF;
  INSERT INTO BloodUnit (Blood_Group, Donation_Date, Expiry_Date, Status, Donor_ID, Hospital_ID)
  VALUES (p_group, p_donation, p_expiry, 'Available', p_donor, p_hospital);
END;
//

DELIMITER //
CREATE PROCEDURE UpdateBloodUnit (
  IN p_id INT,
  IN p_group VARCHAR(5),
  IN p_donation DATE,
  IN p_expiry DATE,
  IN p_status ENUM('Available','Used','Expired'),
  IN p_donor INT,
  IN p_hospital INT
)
BEGIN
  IF p_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BloodUnit ID required for update';
  END IF;
  IF p_status = 'Available' AND p_expiry IS NOT NULL AND p_expiry < CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot mark expired blood as Available';
  END IF;
  UPDATE BloodUnit SET Blood_Group=p_group, Donation_Date=p_donation, Expiry_Date=p_expiry, Status=p_status, Donor_ID=p_donor, Hospital_ID=p_hospital WHERE BloodUnit_ID=p_id;
END;
//

DELIMITER //
CREATE PROCEDURE DeleteBloodUnit (IN p_id INT)
BEGIN
  IF p_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BloodUnit ID required for delete';
  END IF;
  DELETE FROM BloodUnit WHERE BloodUnit_ID = p_id;
END;
//

DELIMITER //
CREATE PROCEDURE AddOrgan (
  IN p_type VARCHAR(50),
  IN p_donation DATE,
  IN p_expiry DATE,
  IN p_donor INT,
  IN p_hospital INT
)
BEGIN
  IF p_type IS NULL OR TRIM(p_type) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Organ type required';
  END IF;
  IF p_expiry IS NOT NULL AND p_expiry < CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Expiry date is in the past - cannot insert expired organ';
  END IF;
  INSERT INTO Organ (Type, Donation_Date, Expiry_Date, Status, Donor_ID, Hospital_ID)
  VALUES (p_type, p_donation, p_expiry, 'Available', p_donor, p_hospital);
END;
//

USE BloodOrganManagement;
DROP PROCEDURE IF EXISTS AddTransplant;
DELIMITER //

CREATE PROCEDURE AddTransplant (
  IN p_type VARCHAR(10),
  IN p_date DATE,
  IN p_recipient INT,
  IN p_doctor INT,
  IN p_hospital INT,
  IN p_bloodunit INT,
  IN p_organ INT
)
BEGIN
  DECLARE v_msg VARCHAR(255);
  -- Basic required fields
  IF p_type IS NULL OR TRIM(p_type) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transplant type required';
  END IF;

  IF p_date IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transplant date required';
  END IF;

  IF p_recipient IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Recipient required';
  END IF;

  -- At least one of bloodunit or organ must be provided
  IF p_bloodunit IS NULL AND p_organ IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Either BloodUnit_ID or Organ_ID must be provided';
  END IF;

  -- If a blood unit is given, validate it
  IF p_bloodunit IS NOT NULL THEN
    -- check expiry
    IF (SELECT Expiry_Date FROM BloodUnit WHERE BloodUnit_ID = p_bloodunit) IS NOT NULL
       AND (SELECT Expiry_Date FROM BloodUnit WHERE BloodUnit_ID = p_bloodunit) < CURDATE() THEN
      SET v_msg = CONCAT('Selected blood unit (', p_bloodunit, ') is expired');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    -- check availability
    IF (SELECT Status FROM BloodUnit WHERE BloodUnit_ID = p_bloodunit) <> 'Available' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selected blood unit is not available';
    END IF;
  END IF;

  -- If an organ is given, validate it
  IF p_organ IS NOT NULL THEN
    -- check expiry
    IF (SELECT Expiry_Date FROM Organ WHERE Organ_ID = p_organ) IS NOT NULL
       AND (SELECT Expiry_Date FROM Organ WHERE Organ_ID = p_organ) < CURDATE() THEN
      SET v_msg = CONCAT('Selected organ (', p_organ, ') is expired');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    -- check availability
    IF (SELECT Status FROM Organ WHERE Organ_ID = p_organ) <> 'Available' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selected organ is not available';
    END IF;
  END IF;

  -- Insert
  INSERT INTO Transplant (Type, Transplant_Date, Recipient_ID, Doctor_ID, Hospital_ID, BloodUnit_ID, Organ_ID)
  VALUES (p_type, p_date, p_recipient, p_doctor, p_hospital, p_bloodunit, p_organ);
END;
//


DELIMITER //

CREATE PROCEDURE GetAvailableBloodByGroup (IN p_group VARCHAR(5))
BEGIN
  SELECT 
    BloodUnit_ID, 
    Blood_Group, 
    Donation_Date, 
    Expiry_Date, 
    Status, 
    Donor_ID, 
    Hospital_ID
  FROM BloodUnit 
  WHERE Status = 'Available'
    AND (p_group IS NULL OR Blood_Group = p_group);
END;
//

DELIMITER ;


DELIMITER //
CREATE PROCEDURE GetAvailableOrgansByType (IN p_type VARCHAR(50))
BEGIN
  SELECT Organ_ID, Type, Donation_Date, Expiry_Date, Status, Donor_ID, Hospital_ID
  FROM Organ WHERE Status='Available' AND (p_type IS NULL OR Type = p_type);
END;
//
DELIMITER ;

-- =========================
-- TRIGGERS
-- =========================

DELIMITER //
CREATE TRIGGER update_blood_status_after_transplant
AFTER INSERT ON Transplant
FOR EACH ROW
BEGIN
  IF NEW.BloodUnit_ID IS NOT NULL THEN
    UPDATE BloodUnit SET Status = 'Used' WHERE BloodUnit_ID = NEW.BloodUnit_ID;
  END IF;
END;
//

DELIMITER //
CREATE TRIGGER update_organ_status_after_transplant
AFTER INSERT ON Transplant
FOR EACH ROW
BEGIN
  IF NEW.Organ_ID IS NOT NULL THEN
    UPDATE Organ SET Status = 'Used' WHERE Organ_ID = NEW.Organ_ID;
  END IF;
END;
//

DELIMITER //
CREATE TRIGGER prevent_blood_available_if_expired
BEFORE UPDATE ON BloodUnit
FOR EACH ROW
BEGIN
  IF NEW.Status = 'Available' AND NEW.Expiry_Date IS NOT NULL AND NEW.Expiry_Date < CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot mark expired blood as Available';
  END IF;
END;
//

DELIMITER //
CREATE TRIGGER prevent_organ_available_if_expired
BEFORE UPDATE ON Organ
FOR EACH ROW
BEGIN
  IF NEW.Status = 'Available' AND NEW.Expiry_Date IS NOT NULL AND NEW.Expiry_Date < CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot mark expired organ as Available';
  END IF;
END;
//
DELIMITER ;

-- =========================
-- DAILY EVENT: mark expired items (optional, requires event_scheduler=ON)
-- =========================
DELIMITER //
CREATE EVENT IF NOT EXISTS daily_mark_expired
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
  -- Mark blood units past expiry as 'Expired'
  UPDATE BloodUnit
  SET Status = 'Expired'
  WHERE Expiry_Date IS NOT NULL AND Expiry_Date < CURDATE() AND Status <> 'Expired';

  -- Mark organs past expiry as 'Expired'
  UPDATE Organ
  SET Status = 'Expired'
  WHERE Expiry_Date IS NOT NULL AND Expiry_Date < CURDATE() AND Status <> 'Expired';
END;
//
DELIMITER ;

-- =========================
-- QUICK CHECK SELECTS (for verification)
-- =========================

-- List available blood units
SELECT * FROM BloodUnit WHERE Status = 'Available';

-- Donors with multiple contacts
SELECT Donor_ID, COUNT(Contact_no) AS NumContacts
FROM Donor_Contact
GROUP BY Donor_ID
HAVING NumContacts > 1;

-- Transplants by doctor
SELECT D.Doctor_Name, T.Type, T.Transplant_Date
FROM Doctor D
JOIN Transplant T ON D.Doctor_ID = T.Doctor_ID;

-- Organs available per hospital
SELECT H.Hospital_Name, O.Type, O.Status
FROM Hospital H
JOIN Organ O ON H.Hospital_ID = O.Hospital_ID
WHERE O.Status = 'Available';

select * from Organ;
INSERT INTO Organ (Type, Donation_Date, Expiry_Date, Status, Donor_ID, Hospital_ID)
VALUES 
('Kidney', '2025-11-07', '2025-12-31', 'Available', 1, 1);

DELIMITER //
CREATE PROCEDURE AddDonorContact (
  IN p_donor INT,
  IN p_contact VARCHAR(15)
)
BEGIN
  IF p_donor IS NULL OR p_contact IS NULL OR TRIM(p_contact) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Donor ID and contact are required';
  END IF;
  INSERT INTO Donor_Contact (Donor_ID, Contact_no) VALUES (p_donor, p_contact);
END;
//
DELIMITER ;

USE BloodOrganManagement;

-- Recipient contacts

DELIMITER //
CREATE PROCEDURE AddRecipientContact(IN p_recipient INT, IN p_contact VARCHAR(15))
BEGIN
  IF p_recipient IS NULL OR TRIM(p_contact) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Recipient ID and contact required';
  END IF;
  INSERT IGNORE INTO Recipient_Contact (Recipient_ID, Contact_no)
  VALUES (p_recipient, p_contact);
END;
//
DELIMITER ;

-- Doctor contacts
-- DROP PROCEDURE IF EXISTS AddDoctorContact;
DELIMITER //
CREATE PROCEDURE AddDoctorContact(IN p_doctor INT, IN p_contact VARCHAR(15))
BEGIN
  IF p_doctor IS NULL OR TRIM(p_contact) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor ID and contact required';
  END IF;
  INSERT IGNORE INTO Doctor_Contact (Doctor_ID, Contact_no)
  VALUES (p_doctor, p_contact);
END;
//
DELIMITER ;

-- Hospital contacts
-- DROP PROCEDURE IF EXISTS AddHospitalContact;

DELIMITER //
CREATE PROCEDURE AddHospitalContact(IN p_hospital INT, IN p_contact VARCHAR(15))
BEGIN
  IF p_hospital IS NULL OR TRIM(p_contact) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hospital ID and contact required';
  END IF;
  INSERT IGNORE INTO Hospital_Contact (Hospital_ID, Contact_no)
  VALUES (p_hospital, p_contact);
END;
//
DELIMITER ;

