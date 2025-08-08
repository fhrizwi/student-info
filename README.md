# 🎓 Student Information System

A complete Student Information System with hierarchical access control, built with Flask and MySQL (XAMPP).

## 📋 System Overview

This system implements a hierarchical access control system:

- **HOD (Head of Department)**: Super admin with full control
  - Add students and faculty
  - Create login credentials for faculty
  - Directly suspend students
  - Approve/reject faculty suspension requests

- **Faculty**: Limited access with approval workflow
  - View all students
  - Request student suspensions (requires HOD approval)

- **Public**: No login required
  - View all students and their suspension status

## 🗄️ Database Setup (XAMPP)

### Prerequisites
1. Install XAMPP
2. Start Apache and MySQL services
3. Ensure MySQL is running on port 3306

### Quick Setup
```bash
# 1. Install Python dependencies
pip install -r requirements.txt

# 2. Setup database (creates tables and default data)
python setup_database.py

# 3. Run the application
python app.py
```

### Manual Database Setup
1. Open phpMyAdmin: http://localhost/phpmyadmin
2. Create database: `student_info`
3. Import `schema.sql` to create tables
4. Run `python setup_database.py` to add default data

## 🚀 Running the Application

```bash
python app.py
```

Access the web interface at: **http://localhost:5000**

## 🔑 Default Login Credentials

### HOD Access
- **Username**: hod@example.com
- **Password**: hod123

### Faculty Access
- **Username**: faculty@example.com
- **Password**: faculty123

## 📊 API Endpoints

### Public Endpoints (No Authentication)
- `GET /api/students` - View all students
- `GET /api/students/active` - View active students only
- `GET /api/students/suspended` - View suspended students only

### HOD Endpoints (Requires HOD Login)
- `POST /api/login` - HOD/Faculty login
- `POST /api/hod/students` - Add new student
- `POST /api/hod/faculty` - Add new faculty
- `POST /api/hod/faculty/<id>/login` - Create faculty login credentials
- `POST /api/hod/suspend/<id>` - Directly suspend student
- `GET /api/hod/requests` - View pending suspension requests
- `POST /api/hod/requests/<id>/approve` - Approve/reject suspension requests

### Faculty Endpoints (Requires Faculty Login)
- `GET /api/faculty/students` - View all students
- `POST /api/faculty/suspend/<id>` - Request student suspension
- `GET /api/faculty/requests` - View own suspension requests

## 🔄 System Workflow

1. **HOD creates faculty accounts** with login credentials
2. **Faculty logs in** using HOD-provided credentials
3. **Faculty views students** and requests suspensions
4. **HOD reviews** and approves/rejects suspension requests
5. **HOD can directly suspend** students without approval
6. **Public can view** all students and their suspension status
7. **Students don't need login** - their info is publicly accessible

## 📁 Project Structure

```
student-info/
├── app.py                 # Main Flask application
├── setup_database.py      # Database initialization script
├── schema.sql            # Database schema
├── requirements.txt      # Python dependencies
├── README.md            # This file
└── templates/
    └── index.html       # Web interface
```

## 🛠️ Features

### ✅ Implemented Features
- **Hierarchical Access Control**: HOD > Faculty > Public
- **JWT Authentication**: Secure token-based authentication
- **Student Management**: Add, view, and manage students
- **Suspension Workflow**: Faculty requests → HOD approval
- **Direct Suspension**: HOD can suspend students directly
- **Public Access**: Students viewable without login
- **Responsive Web Interface**: Modern, mobile-friendly UI
- **Database Views**: Optimized queries for different user roles
- **Stored Procedures**: Business logic in database layer

### 🔒 Security Features
- **Password Hashing**: Bcrypt for secure password storage
- **JWT Tokens**: Secure authentication with expiration
- **Role-based Access**: Different permissions for different user types
- **Input Validation**: Server-side validation for all inputs
- **SQL Injection Protection**: Parameterized queries

## 🧪 Testing

### Manual Testing
1. **Public Access**: Visit http://localhost:5000
2. **HOD Login**: Use HOD credentials to access admin features
3. **Faculty Login**: Use Faculty credentials to request suspensions
4. **Workflow Test**: Faculty requests → HOD approves → Student suspended

### API Testing
```bash
# Test public endpoints
curl http://localhost:5000/api/students

# Test HOD login
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"hod@example.com","password":"hod123"}'
```

## 🛠️ Troubleshooting

### Common Issues

1. **MySQL Connection Failed**
   - Ensure XAMPP MySQL is running
   - Check database name is `student_info`
   - Verify credentials in `app.py`

2. **Port 5000 Already in Use**
   ```python
   # Change port in app.py
   app.run(debug=True, host='0.0.0.0', port=5001)
   ```

3. **Import Errors**
   ```bash
   pip install -r requirements.txt
   ```

4. **Database Errors**
   ```bash
   # Re-run database setup
   python setup_database.py
   ```

## 📋 Requirements

### System Requirements
- Python 3.7+
- XAMPP (MySQL)
- Modern web browser

### Python Dependencies
- Flask 2.3.3
- Flask-CORS 4.0.0
- mysql-connector-python 8.1.0
- bcrypt 4.0.1
- PyJWT 2.8.0
- python-dotenv 1.0.0

## 🎯 Next Steps

### Immediate
1. **Customize**: Modify student/faculty data
2. **Test**: Verify all workflows function correctly
3. **Deploy**: Move to production server

### Future Enhancements
1. **Student Photos**: Add profile pictures
2. **Attendance Tracking**: Monitor student attendance
3. **Notifications**: Email/SMS alerts for suspensions
4. **Reports**: Generate detailed reports
5. **Multi-department**: Support multiple departments
6. **Audit Trail**: Track all system changes

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Verify XAMPP MySQL is running
3. Ensure all dependencies are installed
4. Check database connection settings

---

**🎓 Student Information System is ready for production use!**
