Blood & Organ Management System

A full-stack project using Flask, MySQL, Bootstrap, Stored Procedures, Triggers, and an optional Tkinter Desktop GUI.

📌 Overview

The Blood & Organ Management System is designed to manage:

Donors

Recipients

Doctors

Hospitals

Blood Units

Organs

Transplant Records

It includes:

A web-based interface built using Flask + Bootstrap

A MySQL database with stored procedures, functions, views, and triggers

An optional Tkinter GUI for desktop usage

Secure login & session management

🏗️ Features
✔ Donor Management

Add, edit, delete donors

Auto calculate age using stored function

Contact details included

✔ Recipient Management

Add, edit, delete recipient records

Track blood group & address

✔ Doctor Management

Assign hospital

Maintain specialization

Contact details added

✔ Hospital Management

Maintain hospital locations & IDs

✔ Blood Units

Add/update blood units

Expiry validation using functions

Status auto-updates via TRIGGER

✔ Organs

Add/update organ availability

Expiry validation

Trigger updates on transplant

✔ Transplants

Supports blood OR organ OR both

Calls stored procedure AddTransplant()

Automatically updates related statuses

✔ Authentication

Login page

Session handling

Dashboard visible only after login

✔ Tkinter Desktop GUI (Optional)

Donor, recipient, blood, organ, transplant management

Uses procedures + triggers

🧰 Technologies Used
Layer	Technology
Frontend	HTML, Bootstrap 5, Jinja2 Templates
Backend	Flask (Python)
Database	MySQL
Logic	Stored Procedures, Functions, Triggers
Optional Desktop App	Tkinter
📂 Project Structure
BloodOrganApp/
│── app.py
│── db_config.py
│── schema.sql
│── stored_procedures.sql
│── triggers.sql
│── README.md
│── /templates
│     ├── layout.html
│     ├── login.html
│     ├── dashboard.html
│     ├── donors.html
│     ├── recipients.html
│     ├── hospitals.html
│     ├── doctors.html
│     ├── blood.html
│     ├── organs.html
│     ├── transplants.html
│── /static
│     ├── css/style.css
│     ├── images/
│── /gui (optional)
      ├── main_gui.py

⚙️ Setup Instructions
1️⃣ Install Requirements
pip install flask mysql-connector-python

2️⃣ Import the Database

Import these SQL files into MySQL Workbench:

schema.sql

stored_procedures.sql

triggers.sql

3️⃣ Update DB Config

In db_config.py:

def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="YOUR_PASSWORD",
        database="BloodOrganManagement"
    )

4️⃣ Run the Flask App
python app.py


Visit:

http://127.0.0.1:5000

5️⃣ To run Tkinter GUI (Optional)
python gui/main_gui.py

🖥️ Screenshots (optional – you can add later)

Dashboard

Donor Page

Recipients

Hospitals

Doctors

Blood & Organ Units

Transplant Entry

🔒 Login Credentials

Default login:

Username: admin
Password: admin123


(You can change this in the users table.)

🚀 Future Enhancements

Email notifications for blood shortage

Advanced matching algorithm for organ transplant

Role-based access (Admin, Doctor, Staff)

API for mobile apps

🤝 Contributors

SUKRUTHA D
SPOORTHI S H