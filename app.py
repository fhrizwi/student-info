#!/usr/bin/env python3
"""
🎓 Student Information System
Production-ready Flask application with XAMPP MySQL integration
"""

from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import mysql.connector
import bcrypt
import jwt
import datetime
import os
from functools import wraps

app = Flask(__name__)
app.secret_key = 'student-info-secret-key-2024'  # Change in production
CORS(app)

# Database configuration for XAMPP
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',  # XAMPP default - no password
    'database': 'student_info'
}

def get_db_connection():
    """Create database connection"""
    return mysql.connector.connect(**DB_CONFIG)

def token_required(f):
    """Decorator to check if user is authenticated"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'message': 'Token is missing!'}), 401
        
        try:
            token = token.split(' ')[1]  # Remove 'Bearer ' prefix
            data = jwt.decode(token, app.secret_key, algorithms=['HS256'])
            current_user = data['user_id']
        except:
            return jsonify({'message': 'Token is invalid!'}), 401
        
        return f(current_user, *args, **kwargs)
    return decorated

def hod_required(f):
    """Decorator to check if user is HOD"""
    @wraps(f)
    def decorated(current_user, *args, **kwargs):
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT user_type FROM users WHERE user_id = %s", (current_user,))
        user = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        if not user or user['user_type'] != 'HOD':
            return jsonify({'message': 'HOD access required!'}), 403
        
        return f(current_user, *args, **kwargs)
    return decorated

def faculty_required(f):
    """Decorator to check if user is faculty"""
    @wraps(f)
    def decorated(current_user, *args, **kwargs):
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT user_type FROM users WHERE user_id = %s", (current_user,))
        user = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        if not user or user['user_type'] not in ['HOD', 'FACULTY']:
            return jsonify({'message': 'Faculty access required!'}), 403
        
        return f(current_user, *args, **kwargs)
    return decorated

# Frontend Route
@app.route('/')
def index():
    return render_template('index.html')

# Authentication Routes
@app.route('/api/login', methods=['POST'])
def login():
    """Login for HOD and Faculty"""
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        return jsonify({'message': 'Username and password required!'}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get user
    cursor.execute("""
        SELECT u.*, 
               CASE 
                   WHEN u.user_type = 'HOD' THEN h.full_name
                   WHEN u.user_type = 'FACULTY' THEN f.full_name
               END as full_name
        FROM users u
        LEFT JOIN hod h ON u.user_id = h.user_id
        LEFT JOIN faculty f ON u.user_id = f.user_id
        WHERE u.username = %s AND u.is_active = TRUE
    """, (username,))
    user = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    if not user:
        return jsonify({'message': 'Invalid credentials!'}), 401
    
    # Check password
    if bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
        token = jwt.encode({
            'user_id': user['user_id'],
            'username': user['username'],
            'user_type': user['user_type'],
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }, app.secret_key, algorithm='HS256')
        
        return jsonify({
            'message': 'Login successful!',
            'token': token,
            'user': {
                'user_id': user['user_id'],
                'username': user['username'],
                'user_type': user['user_type'],
                'full_name': user['full_name']
            }
        })
    
    return jsonify({'message': 'Invalid credentials!'}), 401

# Public Routes (No authentication required)
@app.route('/api/students', methods=['GET'])
def get_all_students():
    """Get all students (public access)"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM all_students_public ORDER BY student_id")
    students = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return jsonify({
        'message': 'Students retrieved successfully!',
        'students': students
    })

@app.route('/api/students/suspended', methods=['GET'])
def get_suspended_students():
    """Get suspended students (public access)"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM suspended_students ORDER BY student_id")
    students = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return jsonify({
        'message': 'Suspended students retrieved successfully!',
        'students': students
    })

@app.route('/api/students/active', methods=['GET'])
def get_active_students():
    """Get active students (public access)"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM active_students ORDER BY student_id")
    students = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return jsonify({
        'message': 'Active students retrieved successfully!',
        'students': students
    })

# HOD Routes
@app.route('/api/hod/students', methods=['POST'])
@token_required
@hod_required
def add_student(current_user):
    """HOD can add new students"""
    data = request.get_json()
    
    required_fields = ['student_id', 'full_name', 'mobile_number', 'department', 'gender', 'batch_year']
    for field in required_fields:
        if field not in data:
            return jsonify({'message': f'{field} is required!'}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Insert student
        cursor.execute("""
            INSERT INTO students (student_id, full_name, mobile_number, section, department, gender, batch_year, father_name, address)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            data['student_id'], data['full_name'], data['mobile_number'],
            data.get('section'), data['department'], data['gender'], data['batch_year'],
            data.get('father_name'), data.get('address')
        ))
        
        # Insert student status as active
        cursor.execute("""
            INSERT INTO student_status (student_id, status)
            VALUES (%s, 'ACTIVE')
        """, (data['student_id'],))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Student added successfully!'}), 201
        
    except mysql.connector.Error as err:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({'message': f'Error adding student: {err}'}), 400

@app.route('/api/hod/faculty', methods=['POST'])
@token_required
@hod_required
def add_faculty(current_user):
    """HOD can add new faculty"""
    data = request.get_json()
    
    required_fields = ['faculty_id', 'full_name', 'designation', 'gender']
    for field in required_fields:
        if field not in data:
            return jsonify({'message': f'{field} is required!'}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Insert faculty
        cursor.execute("""
            INSERT INTO faculty (faculty_id, full_name, designation, gender, mobile_number, email_address)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            data['faculty_id'], data['full_name'], data['designation'], data['gender'],
            data.get('mobile_number'), data.get('email_address')
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Faculty added successfully!'}), 201
        
    except mysql.connector.Error as err:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({'message': f'Error adding faculty: {err}'}), 400

@app.route('/api/hod/faculty/<int:faculty_id>/login', methods=['POST'])
@token_required
@hod_required
def create_faculty_login(current_user, faculty_id):
    """HOD creates login credentials for faculty"""
    data = request.get_json()
    
    if not data.get('username') or not data.get('password'):
        return jsonify({'message': 'Username and password required!'}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Hash password
        password_hash = bcrypt.hashpw(data['password'].encode('utf-8'), bcrypt.gensalt())
        
        # Create user account
        cursor.execute("""
            INSERT INTO users (username, password_hash, user_type)
            VALUES (%s, %s, 'FACULTY')
        """, (data['username'], password_hash.decode('utf-8')))
        
        user_id = cursor.lastrowid
        
        # Link to faculty
        cursor.execute("UPDATE faculty SET user_id = %s WHERE faculty_id = %s", (user_id, faculty_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Faculty login created successfully!'}), 201
        
    except mysql.connector.Error as err:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({'message': f'Error creating login: {err}'}), 400

@app.route('/api/hod/suspend/<int:student_id>', methods=['POST'])
@token_required
@hod_required
def direct_suspend_student(current_user, student_id):
    """HOD can directly suspend students"""
    data = request.get_json()
    
    if not data.get('reason'):
        return jsonify({'message': 'Suspension reason required!'}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            UPDATE student_status 
            SET is_suspended = TRUE, suspension_reason = %s, status = 'SUSPENDED',
                approved_by_user_id = %s, approval_date = CURRENT_TIMESTAMP
            WHERE student_id = %s
        """, (data['reason'], current_user, student_id))
        
        if cursor.rowcount == 0:
            # If no existing record, create one
            cursor.execute("""
                INSERT INTO student_status (student_id, is_suspended, suspension_reason, status, approved_by_user_id, approval_date)
                VALUES (%s, TRUE, %s, 'SUSPENDED', %s, CURRENT_TIMESTAMP)
            """, (student_id, data['reason'], current_user))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Student suspended successfully!'}), 200
        
    except mysql.connector.Error as err:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({'message': f'Error suspending student: {err}'}), 400

@app.route('/api/hod/requests', methods=['GET'])
@token_required
@hod_required
def get_pending_requests(current_user):
    """HOD can see pending suspension requests"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM pending_suspension_requests ORDER BY request_date")
    requests = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return jsonify({
        'message': 'Pending requests retrieved successfully!',
        'requests': requests
    })

@app.route('/api/hod/requests/<int:request_id>/approve', methods=['POST'])
@token_required
@hod_required
def approve_suspension_request(current_user, request_id):
    """HOD approves/rejects suspension requests"""
    data = request.get_json()
    action = data.get('action')  # 'approve' or 'reject'
    
    if action not in ['approve', 'reject']:
        return jsonify({'message': 'Action must be approve or reject!'}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Update suspension request
        status = 'APPROVED' if action == 'approve' else 'REJECTED'
        cursor.execute("""
            UPDATE suspension_requests 
            SET status = %s, approved_by_user_id = %s, approval_date = CURRENT_TIMESTAMP
            WHERE request_id = %s
        """, (status, current_user, request_id))
        
        if action == 'approve':
            # Get request details
            cursor.execute("SELECT student_id, suspension_reason FROM suspension_requests WHERE request_id = %s", (request_id,))
            request_data = cursor.fetchone()
            
            if request_data:
                # Update student status
                cursor.execute("""
                    UPDATE student_status 
                    SET is_suspended = TRUE, suspension_reason = %s, status = 'SUSPENDED',
                        approved_by_user_id = %s, approval_date = CURRENT_TIMESTAMP
                    WHERE student_id = %s
                """, (request_data[1], current_user, request_data[0]))
                
                if cursor.rowcount == 0:
                    # If no existing record, create one
                    cursor.execute("""
                        INSERT INTO student_status (student_id, is_suspended, suspension_reason, status, approved_by_user_id, approval_date)
                        VALUES (%s, TRUE, %s, 'SUSPENDED', %s, CURRENT_TIMESTAMP)
                    """, (request_data[0], request_data[1], current_user))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': f'Request {action}d successfully!'}), 200
        
    except mysql.connector.Error as err:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({'message': f'Error processing request: {err}'}), 400

# Faculty Routes
@app.route('/api/faculty/students', methods=['GET'])
@token_required
@faculty_required
def faculty_get_students(current_user):
    """Faculty can view all students"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM all_students_public ORDER BY student_id")
    students = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return jsonify({
        'message': 'Students retrieved successfully!',
        'students': students
    })

@app.route('/api/faculty/suspend/<int:student_id>', methods=['POST'])
@token_required
@faculty_required
def request_student_suspension(current_user, student_id):
    """Faculty can request student suspension"""
    data = request.get_json()
    
    if not data.get('reason'):
        return jsonify({'message': 'Suspension reason required!'}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            INSERT INTO suspension_requests (student_id, requested_by_user_id, suspension_reason)
            VALUES (%s, %s, %s)
        """, (student_id, current_user, data['reason']))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Suspension request submitted successfully!'}), 201
        
    except mysql.connector.Error as err:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({'message': f'Error submitting request: {err}'}), 400

@app.route('/api/faculty/requests', methods=['GET'])
@token_required
@faculty_required
def faculty_get_requests(current_user):
    """Faculty can see their own requests"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("""
        SELECT sr.*, s.full_name as student_name, s.department, s.section
        FROM suspension_requests sr
        JOIN students s ON sr.student_id = s.student_id
        WHERE sr.requested_by_user_id = %s
        ORDER BY sr.request_date DESC
    """, (current_user,))
    requests = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return jsonify({
        'message': 'Requests retrieved successfully!',
        'requests': requests
    })

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'message': 'Endpoint not found!'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'message': 'Internal server error!'}), 500

if __name__ == '__main__':
    print("🎓 Student Information System")
    print("=" * 50)
    print("📋 Available endpoints:")
    print("  • GET  /api/students - Public student list")
    print("  • GET  /api/students/active - Active students only")
    print("  • GET  /api/students/suspended - Suspended students only")
    print("  • POST /api/login - HOD/Faculty login")
    print("  • POST /api/hod/students - Add student (HOD)")
    print("  • POST /api/hod/faculty - Add faculty (HOD)")
    print("  • POST /api/hod/faculty/<id>/login - Create faculty login (HOD)")
    print("  • POST /api/hod/suspend/<id> - Direct suspend (HOD)")
    print("  • GET  /api/hod/requests - Pending requests (HOD)")
    print("  • POST /api/hod/requests/<id>/approve - Approve/reject (HOD)")
    print("  • GET  /api/faculty/students - View students (Faculty)")
    print("  • POST /api/faculty/suspend/<id> - Request suspension (Faculty)")
    print("  • GET  /api/faculty/requests - My requests (Faculty)")
    print("\n🌐 Web Interface: http://localhost:5000")
    print("=" * 50)
    
    app.run(debug=True, host='0.0.0.0', port=5000)
