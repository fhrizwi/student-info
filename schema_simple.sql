-- Enhanced Student Information System Schema
-- HOD (Super Admin) can add students/faculty, approve suspensions
-- Faculty can request suspensions (requires HOD approval)
-- Public can view all students and their status

-- Create Users table for authentication
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type ENUM('HOD', 'FACULTY') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Students table (manual student_id)
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    mobile_number VARCHAR(15),
    section CHAR(1),
    department VARCHAR(50),
    gender ENUM('M', 'F'),
    batch_year INT,
    father_name VARCHAR(100),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Faculty table (manual faculty_id)
CREATE TABLE faculty (
    faculty_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    gender ENUM('M', 'F'),
    mobile_number VARCHAR(15),
    email_address VARCHAR(100),
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Create HOD table
CREATE TABLE hod (
    hod_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    mobile_number VARCHAR(15),
    email_address VARCHAR(100),
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Create Student Status table with enhanced approval workflow
CREATE TABLE student_status (
    status_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    is_suspended BOOLEAN DEFAULT FALSE,
    suspension_reason TEXT,
    status ENUM('ACTIVE', 'SUSPENDED') DEFAULT 'ACTIVE',
    approved_by_user_id INT,
    approval_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(user_id)
);

-- Create Suspension Requests table for tracking faculty requests
CREATE TABLE suspension_requests (
    request_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    requested_by_user_id INT NOT NULL,
    suspension_reason TEXT NOT NULL,
    status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    approved_by_user_id INT,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approval_date TIMESTAMP NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (requested_by_user_id) REFERENCES users(user_id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(user_id)
);

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
LEFT JOIN student_status ss ON s.student_id = ss.student_id
WHERE ss.status = 'ACTIVE' OR ss.status IS NULL;

CREATE VIEW suspended_students AS
SELECT s.*, ss.suspension_reason, ss.status, ss.approval_date
FROM students s
JOIN student_status ss ON s.student_id = ss.student_id
WHERE ss.status = 'SUSPENDED';

CREATE VIEW all_students_public AS
SELECT s.student_id, s.full_name, s.section, s.department, s.gender, s.batch_year,
       COALESCE(ss.status, 'ACTIVE') as status,
       ss.suspension_reason, ss.approval_date
FROM students s
LEFT JOIN student_status ss ON s.student_id = ss.student_id;

CREATE VIEW pending_suspension_requests AS
SELECT sr.*, s.full_name as student_name, s.department, s.section,
       u.username as requested_by_username
FROM suspension_requests sr
JOIN students s ON sr.student_id = s.student_id
JOIN users u ON sr.requested_by_user_id = u.user_id
WHERE sr.status = 'PENDING';
