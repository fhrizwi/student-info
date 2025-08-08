-- Enhanced Student Information System Schema
-- HOD (Super Admin) can add students/faculty, approve suspensions, and directly suspend students
-- Faculty can login and request student suspensions (requires HOD approval)
-- Students are publicly viewable without login

-- Create Users table for authentication (only HOD and Faculty need login)
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type ENUM('HOD', 'FACULTY') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create Students table (manual student_id)
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    mobile_number VARCHAR(15) NOT NULL,
    section VARCHAR(10),
    department VARCHAR(50),
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    batch_year YEAR NOT NULL,
    father_name VARCHAR(100),
    address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create Faculty table (manual faculty_id)
CREATE TABLE faculty (
    faculty_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    designation VARCHAR(50),
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    mobile_number VARCHAR(15),
    email_address VARCHAR(100) UNIQUE,
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Create HOD table
CREATE TABLE hod (
    hod_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    mobile_number VARCHAR(15),
    email_address VARCHAR(100) UNIQUE,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Create Student Status table with enhanced approval workflow
CREATE TABLE student_status (
    status_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    requested_by_user_id INT,
    approved_by_user_id INT,
    is_suspended BOOLEAN DEFAULT FALSE,
    suspension_reason VARCHAR(255),
    status ENUM('ACTIVE', 'SUSPENSION_REQUESTED', 'SUSPENDED', 'REJECTED') DEFAULT 'ACTIVE',
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approval_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (requested_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Create Suspension Requests table for tracking faculty requests
CREATE TABLE suspension_requests (
    request_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    requested_by_user_id INT NOT NULL,
    approved_by_user_id INT NULL,
    suspension_reason VARCHAR(255) NOT NULL,
    status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approval_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (requested_by_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Insert HOD (Super Admin)
INSERT INTO users (username, password_hash, user_type) VALUES
('hod_admin', '$2y$10$example_hash_for_hod_password', 'HOD');

INSERT INTO hod (full_name, department, mobile_number, email_address, user_id) VALUES
('Dr. Rajesh Kumar', 'Computer Science', '9876540001', 'hod.cs@example.com', 1);

-- Insert Faculty with login credentials
INSERT INTO users (username, password_hash, user_type) VALUES
('faculty_kavita', '$2y$10$example_hash_for_faculty_password', 'FACULTY'),
('faculty_amit', '$2y$10$example_hash_for_faculty_password2', 'FACULTY');

INSERT INTO faculty (faculty_id, full_name, designation, gender, mobile_number, email_address, user_id) VALUES
(239278, 'Dr. Kavita Rao', 'Professor', 'Female', '9876540000', 'kavita.rao@example.com', 2),
(239279, 'Prof. Amit Singh', 'Assistant Professor', 'Male', '9876540002', 'amit.singh@example.com', 3);

-- Insert students (publicly viewable - no login needed)
INSERT INTO students (student_id, full_name, mobile_number, section, department, gender, batch_year, father_name, address) VALUES
(11232763, 'Rahul Sharma', '9876543210', 'A', 'Computer Science', 'Male', 2022, 'Rajesh Sharma', 'Delhi'),
(11232940, 'Anita Verma', '9876543211', 'B', 'Electronics', 'Female', 2022, 'Suresh Verma', 'Mumbai'),
(2837, 'Karan Mehta', '9876543212', 'A', 'Mechanical', 'Male', 2022, 'Mahesh Mehta', 'Pune'),
(11232764, 'Priya Patel', '9876543213', 'C', 'Computer Science', 'Female', 2022, 'Ramesh Patel', 'Bangalore'),
(11232765, 'Vikram Malhotra', '9876543214', 'A', 'Electronics', 'Male', 2022, 'Suresh Malhotra', 'Chennai');

-- Insert initial student statuses
-- Rahul Sharma: suspended and approved by HOD
INSERT INTO student_status (student_id, requested_by_user_id, approved_by_user_id, is_suspended, suspension_reason, status, approval_date)
VALUES (11232763, 1, 1, TRUE, 'Violation of code of conduct', 'SUSPENDED', CURRENT_TIMESTAMP);

-- Anita Verma: suspension requested by faculty, pending HOD approval
INSERT INTO suspension_requests (student_id, requested_by_user_id, suspension_reason, status)
VALUES (11232940, 2, 'Attendance shortage - below 75%', 'PENDING');

-- Karan Mehta: active student
INSERT INTO student_status (student_id, status)
VALUES (2837, 'ACTIVE');

-- Priya Patel: active student
INSERT INTO student_status (student_id, status)
VALUES (11232764, 'ACTIVE');

-- Vikram Malhotra: active student
INSERT INTO student_status (student_id, status)
VALUES (11232765, 'ACTIVE');

-- Create indexes for better performance
CREATE INDEX idx_student_status_student_id ON student_status(student_id);
CREATE INDEX idx_suspension_requests_student_id ON suspension_requests(student_id);
CREATE INDEX idx_suspension_requests_status ON suspension_requests(status);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_user_type ON users(user_type);

-- Create views for easier data access
CREATE VIEW active_students AS
SELECT s.*, ss.status
FROM students s
JOIN student_status ss ON s.student_id = ss.student_id
WHERE ss.status = 'ACTIVE';

CREATE VIEW suspended_students AS
SELECT s.*, ss.suspension_reason, ss.status, ss.approval_date
FROM students s
JOIN student_status ss ON s.student_id = ss.student_id
WHERE ss.status = 'SUSPENDED';

CREATE VIEW all_students_public AS
SELECT s.student_id, s.full_name, s.section, s.department, s.gender, s.batch_year,
       CASE 
           WHEN ss.status = 'SUSPENDED' THEN 'SUSPENDED'
           WHEN ss.status = 'ACTIVE' THEN 'ACTIVE'
           ELSE 'ACTIVE'
       END as current_status,
       ss.suspension_reason
FROM students s
LEFT JOIN student_status ss ON s.student_id = ss.student_id;

CREATE VIEW pending_suspension_requests AS
SELECT sr.*, s.full_name as student_name, s.department, s.section,
       u.username as requested_by_username, f.full_name as requested_by_faculty
FROM suspension_requests sr
JOIN students s ON sr.student_id = s.student_id
JOIN users u ON sr.requested_by_user_id = u.user_id
JOIN faculty f ON u.user_id = f.user_id
WHERE sr.status = 'PENDING';

-- Create stored procedures for common operations

-- Procedure for HOD to create faculty login credentials
DELIMITER //
CREATE PROCEDURE CreateFacultyLogin(
    IN p_username VARCHAR(50),
    IN p_password_hash VARCHAR(255),
    IN p_faculty_id INT
)
BEGIN
    DECLARE v_user_id INT;
    
    -- Create user account
    INSERT INTO users (username, password_hash, user_type) 
    VALUES (p_username, p_password_hash, 'FACULTY');
    
    SET v_user_id = LAST_INSERT_ID();
    
    -- Link to faculty
    UPDATE faculty SET user_id = v_user_id WHERE faculty_id = p_faculty_id;
    
    SELECT v_user_id as new_user_id;
END //
DELIMITER ;

-- Procedure for HOD to approve/reject suspension requests
DELIMITER //
CREATE PROCEDURE ApproveSuspensionRequest(
    IN p_request_id INT,
    IN p_approved_by_user_id INT,
    IN p_approval_status ENUM('APPROVED', 'REJECTED')
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_suspension_reason VARCHAR(255);
    
    -- Get request details
    SELECT student_id, suspension_reason INTO v_student_id, v_suspension_reason
    FROM suspension_requests WHERE request_id = p_request_id;
    
    -- Update suspension request
    UPDATE suspension_requests 
    SET status = p_approval_status, 
        approved_by_user_id = p_approved_by_user_id,
        approval_date = CURRENT_TIMESTAMP
    WHERE request_id = p_request_id;
    
    -- If approved, update student status
    IF p_approval_status = 'APPROVED' THEN
        UPDATE student_status 
        SET is_suspended = TRUE,
            suspension_reason = v_suspension_reason,
            status = 'SUSPENDED',
            approved_by_user_id = p_approved_by_user_id,
            approval_date = CURRENT_TIMESTAMP
        WHERE student_id = v_student_id;
    END IF;
END //
DELIMITER ;

-- Procedure for HOD to directly suspend a student
DELIMITER //
CREATE PROCEDURE DirectSuspendStudent(
    IN p_student_id INT,
    IN p_suspension_reason VARCHAR(255),
    IN p_approved_by_user_id INT
)
BEGIN
    UPDATE student_status 
    SET is_suspended = TRUE,
        suspension_reason = p_suspension_reason,
        status = 'SUSPENDED',
        approved_by_user_id = p_approved_by_user_id,
        approval_date = CURRENT_TIMESTAMP
    WHERE student_id = p_student_id;
END //
DELIMITER ;

-- Procedure for faculty to request student suspension
DELIMITER //
CREATE PROCEDURE RequestStudentSuspension(
    IN p_student_id INT,
    IN p_requested_by_user_id INT,
    IN p_suspension_reason VARCHAR(255)
)
BEGIN
    INSERT INTO suspension_requests (student_id, requested_by_user_id, suspension_reason)
    VALUES (p_student_id, p_requested_by_user_id, p_suspension_reason);
END //
DELIMITER ;
