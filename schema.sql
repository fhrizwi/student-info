

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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create Student Status table
CREATE TABLE student_status (
    status_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    faculty_id INT,
    is_suspended BOOLEAN DEFAULT FALSE,
    suspension_reason VARCHAR(255),
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert students
INSERT INTO students (student_id, full_name, mobile_number, section, department, gender, batch_year, father_name, address) VALUES
(11232763, 'Rahul Sharma', '9876543210', 'A', 'Computer Science', 'Male', 2022, 'Rajesh Sharma', 'Delhi'),
(11232940, 'Anita Verma', '9876543211', 'B', 'Electronics', 'Female', 2022, 'Suresh Verma', 'Mumbai'),
(2837, 'Karan Mehta', '9876543212', 'A', 'Mechanical', 'Male', 2022, 'Mahesh Mehta', 'Pune');

-- Insert faculty
INSERT INTO faculty (faculty_id, full_name, designation, gender, mobile_number, email_address) VALUES
(239278, 'Dr. Kavita Rao', 'Professor', 'Female', '9876540000', 'kavita.rao@example.com');

-- Insert student status
-- Rahul Sharma: suspended and approved
INSERT INTO student_status (student_id, faculty_id, is_suspended, suspension_reason, is_approved)
VALUES (11232763, 239278, TRUE, 'Violation of code of conduct', TRUE);

-- Anita Verma: suspension requested, not approved
INSERT INTO student_status (student_id, faculty_id, is_suspended, suspension_reason, is_approved)
VALUES (11232940, 239278, TRUE, 'Attendance shortage', FALSE);

-- Karan Mehta: not suspended
INSERT INTO student_status (student_id, faculty_id, is_suspended, suspension_reason, is_approved)
VALUES (2837, 239278, FALSE, NULL, FALSE);

-- Add foreign keys
ALTER TABLE student_status
ADD CONSTRAINT fk_student FOREIGN KEY (student_id)
REFERENCES students(student_id) ON DELETE CASCADE;

ALTER TABLE student_status
ADD CONSTRAINT fk_faculty FOREIGN KEY (faculty_id)
REFERENCES faculty(faculty_id) ON DELETE SET NULL;
