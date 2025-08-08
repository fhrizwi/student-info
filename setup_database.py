#!/usr/bin/env python3
"""
🎓 Student Information System - Database Setup
Insert default data for XAMPP (schema already executed manually)
"""

import mysql.connector
import bcrypt
import sys

# Database configuration for XAMPP
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',  # XAMPP default - no password
    'database': 'student_info'
}

def insert_default_data():
    """Insert default HOD and sample data"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Create default HOD password hash
        hod_password = 'hod123'
        hod_password_hash = bcrypt.hashpw(hod_password.encode('utf-8'), bcrypt.gensalt())
        
        # Insert users first (to avoid foreign key constraint)
        cursor.execute("""
            INSERT INTO users (user_id, username, password_hash, user_type, is_active)
            VALUES (1, 'hod@example.com', %s, 'HOD', TRUE)
        """, (hod_password_hash.decode('utf-8'),))
        
        # Insert default HOD
        cursor.execute("""
            INSERT INTO hod (full_name, department, mobile_number, email_address, user_id)
            VALUES ('Dr. John Smith', 'Computer Science', '+1234567890', 'hod@example.com', 1)
        """)
        
        # Insert sample faculty
        faculty_password = 'faculty123'
        faculty_password_hash = bcrypt.hashpw(faculty_password.encode('utf-8'), bcrypt.gensalt())
        
        cursor.execute("""
            INSERT INTO users (user_id, username, password_hash, user_type, is_active)
            VALUES (2, 'faculty@example.com', %s, 'FACULTY', TRUE)
        """, (faculty_password_hash.decode('utf-8'),))
        
        cursor.execute("""
            INSERT INTO faculty (faculty_id, full_name, gender, mobile_number, email_address, user_id)
            VALUES (1, 'Prof. Sarah Johnson', 'F', '+1234567891', 'faculty@example.com', 2)
        """)
        
        # Insert sample students
        sample_students = [
            (1, 'Alice Johnson', '+1234567892', 'A', 'Computer Science', 'F', 2024, 'John Johnson', '123 Main St'),
            (2, 'Bob Smith', '+1234567893', 'B', 'Computer Science', 'M', 2024, 'Mike Smith', '456 Oak Ave'),
            (3, 'Charlie Brown', '+1234567894', 'A', 'Computer Science', 'M', 2024, 'David Brown', '789 Pine Rd')
        ]
        
        for student in sample_students:
            cursor.execute("""
                INSERT INTO students (student_id, full_name, mobile_number, section, department, gender, batch_year, father_name, address)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, student)
            
            # Add student status as active
            cursor.execute("""
                INSERT INTO student_status (student_id, status)
                VALUES (%s, 'ACTIVE')
            """, (student[0],))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        print("✅ Default data inserted successfully")
        return True
        
    except mysql.connector.Error as err:
        print(f"❌ Error inserting default data: {err}")
        return False

def main():
    print("🎓 Student Information System - Database Setup")
    print("=" * 50)
    
    print("\n1️⃣  Checking database connection...")
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        conn.close()
        print("✅ Database connection successful")
    except mysql.connector.Error as err:
        print(f"❌ Database connection failed: {err}")
        print("💡 Make sure XAMPP MySQL is running")
        sys.exit(1)
    
    print("\n2️⃣  Schema already executed manually - skipping...")
    print("✅ Database schema is ready")
    
    print("\n3️⃣  Inserting default data...")
    if not insert_default_data():
        print("❌ Failed to insert default data")
        sys.exit(1)
    
    print("\n" + "=" * 50)
    print("✅ DATABASE SETUP COMPLETED!")
    print("=" * 50)
    print("\n🔑 Default Login Credentials:")
    print("  HOD: hod@example.com / hod123")
    print("  Faculty: faculty@example.com / faculty123")
    print("\n📊 Sample Data:")
    print("  • 3 sample students added")
    print("  • 1 HOD account created")
    print("  • 1 Faculty account created")
    print("\n🚀 Next Steps:")
    print("  1. Run: python app.py")
    print("  2. Open: http://localhost:5000")
    print("\n🎯 System is ready for use!")

if __name__ == "__main__":
    main()
