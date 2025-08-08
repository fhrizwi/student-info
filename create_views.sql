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
