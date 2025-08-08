#!/usr/bin/env python3
"""
Check database tables and structure
"""

import mysql.connector

# Database configuration for XAMPP
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',  # XAMPP default - no password
    'database': 'student_info'
}

def check_database():
    """Check database structure"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Get all tables
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        
        print("📋 Database Tables:")
        for table in tables:
            print(f"  • {table[0]}")
        
        # Check if key tables exist
        key_tables = ['users', 'students', 'faculty', 'hod', 'student_status', 'suspension_requests']
        missing_tables = []
        
        for table in key_tables:
            cursor.execute(f"SHOW TABLES LIKE '{table}'")
            if not cursor.fetchall():
                missing_tables.append(table)
        
        if missing_tables:
            print(f"\n❌ Missing tables: {', '.join(missing_tables)}")
            print("💡 Please execute schema.sql manually in phpMyAdmin")
        else:
            print("\n✅ All required tables exist!")
        
        cursor.close()
        conn.close()
        
    except mysql.connector.Error as err:
        print(f"❌ Error checking database: {err}")

if __name__ == "__main__":
    check_database()
