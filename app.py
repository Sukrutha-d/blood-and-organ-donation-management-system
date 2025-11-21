from flask import Flask, render_template, request, redirect, flash, url_for
from db_config import get_connection
from mysql.connector import Error
from flask import Flask, render_template, request, redirect, url_for, flash, session
from functools import wraps
app = Flask(__name__)
#app.secret_key = "replace-with-a-secure-random-key"
app.secret_key = "super-secret-key"   # already present, keep same

# ---------------- Helpers ----------------
def fetch_all(query, params=()):
    """Fetch rows as dicts."""
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute(query, params)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows

def execute_proc(proc_sql, params=()):
    """Execute a stored procedure or SQL safely."""
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(proc_sql, params)
        conn.commit()
    finally:
        cur.close()
        conn.close()

# ---------------- Dashboard ----------------
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        conn = get_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT * FROM Users WHERE Username=%s AND Password=%s", (username, password))
        user = cur.fetchone()
        cur.close()
        conn.close()

        if user:
            session["user_id"] = user["User_ID"]
            session["username"] = user["Username"]
            flash("Login successful!", "success")
            return redirect(url_for("dashboard"))
        else:
            flash("Invalid username or password!", "danger")

    return render_template("login.html")
@app.route("/logout")
def logout():
    session.clear()
    flash("Logged out successfully.", "info")
    return redirect(url_for("login"))


def login_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if "user_id" not in session:
            flash("Please login first!", "warning")
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return wrapper
@app.route("/")
@login_required
def dashboard():
    try:
        donors = fetch_all("SELECT COUNT(*) AS cnt FROM Donor")[0]['cnt']
        recipients = fetch_all("SELECT COUNT(*) AS cnt FROM Recipient")[0]['cnt']
        blood_available = fetch_all("SELECT COUNT(*) AS cnt FROM BloodUnit WHERE Status='Available'")[0]['cnt']
        organ_available = fetch_all("SELECT COUNT(*) AS cnt FROM Organ WHERE Status='Available'")[0]['cnt']
        recent_transplants = fetch_all("""
            SELECT t.Transplant_ID, t.Type, t.Transplant_Date, 
                   t.Recipient_ID, t.Doctor_ID, t.Hospital_ID,
                   t.BloodUnit_ID, t.Organ_ID
            FROM Transplant t
            ORDER BY t.Transplant_Date DESC LIMIT 6
        """)
    except Error as e:
        flash("Database error: " + str(e), "danger")
        donors = recipients = blood_available = organ_available = 0
        recent_transplants = []
    return render_template("dashboard.html",
                           donors=donors,
                           recipients=recipients,
                           blood_available=blood_available,
                           organ_available=organ_available,
                           recent_transplants=recent_transplants)

# ---------------- Donors CRUD ----------------
# ---- donors listing (with contacts aggregated) ----
@app.route("/donors")
def donors():
    # join with Donor_Contact and aggregate contacts into a comma-separated string
    rows = fetch_all("""
        SELECT D.Donor_ID, D.Donor_Name, D.DOB,
               TIMESTAMPDIFF(YEAR, D.DOB, CURDATE()) AS Age,
               D.Gender, D.Blood_Group, D.Email, D.Street, D.City, D.State,
               GROUP_CONCAT(DC.Contact_no SEPARATOR ',') AS contacts
        FROM Donor D
        LEFT JOIN Donor_Contact DC ON D.Donor_ID = DC.Donor_ID
        GROUP BY D.Donor_ID
        ORDER BY D.Donor_ID
    """)
    return render_template("donors.html", donors=rows)


# ---- add donor (and optional primary contact) ----
@app.route("/donors/add", methods=["POST"])
def add_donor():
    f = request.form
    try:
        # call proc to add donor (keeps validations centralized in DB)
        execute_proc("CALL AddDonor(%s,%s,%s,%s,%s,%s,%s,%s)", (
            f.get("name"), f.get("dob") or None, f.get("gender") or None, f.get("blood_group") or None,
            f.get("street") or None, f.get("city") or None, f.get("state") or None, f.get("email") or None
        ))

        # if contact provided, insert into Donor_Contact
        contact = f.get("contact")
        if contact and contact.strip():
            # get last inserted donor id (reliable if single-user demo); alternative: return id from stored proc
            last = fetch_all("SELECT MAX(Donor_ID) AS id FROM Donor")[0]['id']
            # insert contact (use stored proc if you added it, otherwise direct insert)
            try:
                execute_proc("CALL AddDonorContact(%s, %s)", (last, contact.strip()))
            except Error:
                # fallback to direct insert if stored proc not present
                conn = get_connection()
                cur = conn.cursor()
                cur.execute("INSERT IGNORE INTO Donor_Contact (Donor_ID, Contact_no) VALUES (%s, %s)", (last, contact.strip()))
                conn.commit()
                cur.close()
                conn.close()

        flash("Donor added successfully!", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("donors"))
# Show/manage contacts for a donor
@app.route("/donor_contacts/<int:id>")
def donor_contacts(id):
    donor = fetch_all("SELECT * FROM Donor WHERE Donor_ID = %s", (id,))
    if not donor:
        flash("Donor not found.", "warning")
        return redirect(url_for("donors"))
    contacts = fetch_all("SELECT Contact_no FROM Donor_Contact WHERE Donor_ID = %s ORDER BY Contact_no", (id,))
    return render_template("donor_contacts.html", donor=donor[0], contacts=contacts)

# Add a contact for a donor
@app.route("/donor_contacts/add", methods=["POST"])
def donor_contacts_add():
    donor_id = request.form.get("donor_id")
    contact = request.form.get("contact")
    if not donor_id or not contact or not contact.strip():
        flash("Donor ID and contact required.", "warning")
        return redirect(url_for("donors"))
    try:
        # use stored proc if available
        try:
            execute_proc("CALL AddDonorContact(%s, %s)", (donor_id, contact.strip()))
        except Error:
            # fallback direct insert
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("INSERT IGNORE INTO Donor_Contact (Donor_ID, Contact_no) VALUES (%s, %s)", (donor_id, contact.strip()))
            conn.commit()
            cur.close()
            conn.close()
        flash("Contact added.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("donor_contacts", id=donor_id))

# Delete a contact for a donor
@app.route("/donor_contacts/delete", methods=["POST"])
def donor_contacts_delete():
    donor_id = request.form.get("donor_id")
    contact = request.form.get("contact")
    if not donor_id or not contact:
        flash("Missing donor id or contact.", "warning")
        return redirect(url_for("donors"))
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("DELETE FROM Donor_Contact WHERE Donor_ID = %s AND Contact_no = %s", (donor_id, contact))
        conn.commit()
        cur.close()
        conn.close()
        flash("Contact removed.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("donor_contacts", id=donor_id))


@app.route("/donors/edit/<int:id>", methods=["GET","POST"])
def edit_donor(id):
    if request.method == "POST":
        f = request.form
        try:
            execute_proc("CALL UpdateDonor(%s,%s,%s,%s,%s,%s,%s,%s,%s)", (
                id, f.get("name"), f.get("dob"), f.get("gender"), f.get("blood_group"),
                f.get("street"), f.get("city"), f.get("state"), f.get("email")
            ))
            flash("Donor updated!", "success")
        except Error as e:
            flash(str(e), "danger")
        return redirect(url_for("donors"))
    donor = fetch_all("SELECT * FROM Donor WHERE Donor_ID = %s", (id,))
    if not donor:
        flash("Donor not found.", "warning")
        return redirect(url_for("donors"))
    return render_template("edit_donor.html", donor=donor[0])

@app.route("/donors/delete/<int:id>", methods=["POST"])
def delete_donor(id):
    try:
        execute_proc("CALL DeleteDonor(%s)", (id,))
        flash("Donor deleted.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("donors"))

# ---------------- Recipients CRUD ----------------
@app.route("/recipients")
def recipients():
    rows = fetch_all("SELECT * FROM Recipient ORDER BY Recipient_ID")
    return render_template("recipients.html", recipients=rows)

@app.route("/recipients/add", methods=["POST"])
def add_recipient():
    f = request.form
    try:
        execute_proc("CALL AddRecipient(%s,%s,%s,%s,%s,%s,%s,%s)", (
            f.get("name"), f.get("dob"), f.get("gender"), f.get("blood_group"),
            f.get("street"), f.get("city"), f.get("state"), f.get("email")
        ))
        flash("Recipient added!", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("recipients"))

@app.route("/recipients/edit/<int:id>", methods=["GET","POST"])
def edit_recipient(id):
    if request.method == "POST":
        f = request.form
        try:
            execute_proc("CALL UpdateRecipient(%s,%s,%s,%s,%s,%s,%s,%s,%s)", (
                id, f.get("name"), f.get("dob"), f.get("gender"), f.get("blood_group"),
                f.get("street"), f.get("city"), f.get("state"), f.get("email")
            ))
            flash("Recipient updated!", "success")
        except Error as e:
            flash(str(e), "danger")
        return redirect(url_for("recipients"))
    recipient = fetch_all("SELECT * FROM Recipient WHERE Recipient_ID = %s", (id,))
    if not recipient:
        flash("Recipient not found.", "warning")
        return redirect(url_for("recipients"))
    return render_template("edit_recipient.html", recipient=recipient[0])

@app.route("/recipients/delete/<int:id>", methods=["POST"])
def delete_recipient(id):
    try:
        execute_proc("CALL DeleteRecipient(%s)", (id,))
        flash("Recipient deleted.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("recipients"))

# -------- Recipient Contacts --------
@app.route("/recipient_contacts/<int:id>")
def recipient_contacts(id):
    rec = fetch_all("SELECT * FROM Recipient WHERE Recipient_ID=%s", (id,))
    if not rec:
        flash("Recipient not found.", "warning")
        return redirect(url_for("recipients"))
    contacts = fetch_all("SELECT Contact_no FROM Recipient_Contact WHERE Recipient_ID=%s", (id,))
    return render_template("recipient_contacts.html", recipient=rec[0], contacts=contacts)

@app.route("/recipient_contacts/add", methods=["POST"])
def recipient_contacts_add():
    rid = request.form.get("recipient_id")
    contact = request.form.get("contact")
    if not rid or not contact.strip():
        flash("Recipient ID and contact required.", "warning")
        return redirect(url_for("recipients"))
    try:
        execute_proc("CALL AddRecipientContact(%s, %s)", (rid, contact.strip()))
        flash("Contact added.", "success")
    except Error:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("INSERT IGNORE INTO Recipient_Contact VALUES (%s, %s)", (rid, contact.strip()))
        conn.commit()
        cur.close()
        conn.close()
        flash("Contact added.", "success")
    return redirect(url_for("recipient_contacts", id=rid))

@app.route("/recipient_contacts/delete", methods=["POST"])
def recipient_contacts_delete():
    rid = request.form.get("recipient_id")
    contact = request.form.get("contact")
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM Recipient_Contact WHERE Recipient_ID=%s AND Contact_no=%s", (rid, contact))
    conn.commit()
    cur.close()
    conn.close()
    flash("Contact deleted.", "success")
    return redirect(url_for("recipient_contacts", id=rid))


# ---------------- Hospitals CRUD ----------------
@app.route("/hospitals")
def hospitals():
    rows = fetch_all("SELECT * FROM Hospital ORDER BY Hospital_ID")
    return render_template("hospitals.html", hospitals=rows)

@app.route("/hospitals/add", methods=["POST"])
def add_hospital():
    f = request.form
    try:
        execute_proc("CALL AddHospital(%s,%s,%s,%s)", (
            f.get("name"), f.get("street"), f.get("city"), f.get("state")
        ))
        flash("Hospital added!", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("hospitals"))

@app.route("/hospitals/edit/<int:id>", methods=["GET","POST"])
def edit_hospital(id):
    if request.method == "POST":
        f = request.form
        try:
            execute_proc("CALL UpdateHospital(%s,%s,%s,%s,%s)", (
                id, f.get("name"), f.get("street"), f.get("city"), f.get("state")
            ))
            flash("Hospital updated!", "success")
        except Error as e:
            flash(str(e), "danger")
        return redirect(url_for("hospitals"))
    hospital = fetch_all("SELECT * FROM Hospital WHERE Hospital_ID=%s", (id,))
    if not hospital:
        flash("Hospital not found.", "warning")
        return redirect(url_for("hospitals"))
    return render_template("edit_hospital.html", hospital=hospital[0])

@app.route("/hospitals/delete/<int:id>", methods=["POST"])
def delete_hospital(id):
    try:
        execute_proc("CALL DeleteHospital(%s)", (id,))
        flash("Hospital deleted.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("hospitals"))
# -------- Hospital Contacts --------
@app.route("/hospital_contacts/<int:id>")
def hospital_contacts(id):
    hos = fetch_all("SELECT * FROM Hospital WHERE Hospital_ID=%s", (id,))
    if not hos:
        flash("Hospital not found.", "warning")
        return redirect(url_for("hospitals"))
    contacts = fetch_all("SELECT Contact_no FROM Hospital_Contact WHERE Hospital_ID=%s", (id,))
    return render_template("hospital_contacts.html", hospital=hos[0], contacts=contacts)

@app.route("/hospital_contacts/add", methods=["POST"])
def hospital_contacts_add():
    hid = request.form.get("hospital_id")
    contact = request.form.get("contact")
    if not hid or not contact.strip():
        flash("Hospital ID and contact required.", "warning")
        return redirect(url_for("hospitals"))
    try:
        execute_proc("CALL AddHospitalContact(%s, %s)", (hid, contact.strip()))
        flash("Contact added.", "success")
    except Error:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("INSERT IGNORE INTO Hospital_Contact VALUES (%s, %s)", (hid, contact.strip()))
        conn.commit()
        cur.close()
        conn.close()
        flash("Contact added.", "success")
    return redirect(url_for("hospital_contacts", id=hid))

@app.route("/hospital_contacts/delete", methods=["POST"])
def hospital_contacts_delete():
    hid = request.form.get("hospital_id")
    contact = request.form.get("contact")
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM Hospital_Contact WHERE Hospital_ID=%s AND Contact_no=%s", (hid, contact))
    conn.commit()
    cur.close()
    conn.close()
    flash("Contact deleted.", "success")
    return redirect(url_for("hospital_contacts", id=hid))

# ---------------- Doctors CRUD ----------------
@app.route("/doctors")
def doctors():
    rows = fetch_all("""
        SELECT D.Doctor_ID, D.Doctor_Name, D.Speciality, H.Hospital_Name
        FROM Doctor D
        LEFT JOIN Hospital H ON D.Hospital_ID = H.Hospital_ID
        ORDER BY D.Doctor_ID
    """)
    return render_template("doctors.html", doctors=rows)

@app.route("/doctors/add", methods=["POST"])
def add_doctor():
    f = request.form
    try:
        execute_proc("CALL AddDoctor(%s,%s,%s)", (
            f.get("name"), f.get("speciality"), f.get("hospital_id") or None
        ))
        flash("Doctor added.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("doctors"))

@app.route("/doctors/edit/<int:id>", methods=["GET","POST"])
def edit_doctor(id):
    if request.method == "POST":
        f = request.form
        try:
            execute_proc("CALL UpdateDoctor(%s,%s,%s,%s)", (
                id, f.get("name"), f.get("speciality"), f.get("hospital_id") or None
            ))
            flash("Doctor updated.", "success")
        except Error as e:
            flash(str(e), "danger")
        return redirect(url_for("doctors"))
    doctor = fetch_all("SELECT * FROM Doctor WHERE Doctor_ID = %s", (id,))
    if not doctor:
        flash("Doctor not found.", "warning")
        return redirect(url_for("doctors"))
    hospitals = fetch_all("SELECT Hospital_ID, Hospital_Name FROM Hospital")
    return render_template("edit_doctor.html", doctor=doctor[0], hospitals=hospitals)

@app.route("/doctors/delete/<int:id>", methods=["POST"])
def delete_doctor(id):
    try:
        execute_proc("CALL DeleteDoctor(%s)", (id,))
        flash("Doctor deleted.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("doctors"))
# -------- Doctor Contacts --------
@app.route("/doctor_contacts/<int:id>")
def doctor_contacts(id):
    doc = fetch_all("SELECT * FROM Doctor WHERE Doctor_ID=%s", (id,))
    if not doc:
        flash("Doctor not found.", "warning")
        return redirect(url_for("doctors"))
    contacts = fetch_all("SELECT Contact_no FROM Doctor_Contact WHERE Doctor_ID=%s", (id,))
    return render_template("doctor_contacts.html", doctor=doc[0], contacts=contacts)

@app.route("/doctor_contacts/add", methods=["POST"])
def doctor_contacts_add():
    did = request.form.get("doctor_id")
    contact = request.form.get("contact")
    if not did or not contact.strip():
        flash("Doctor ID and contact required.", "warning")
        return redirect(url_for("doctors"))
    try:
        execute_proc("CALL AddDoctorContact(%s, %s)", (did, contact.strip()))
        flash("Contact added.", "success")
    except Error:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("INSERT IGNORE INTO Doctor_Contact VALUES (%s, %s)", (did, contact.strip()))
        conn.commit()
        cur.close()
        conn.close()
        flash("Contact added.", "success")
    return redirect(url_for("doctor_contacts", id=did))

@app.route("/doctor_contacts/delete", methods=["POST"])
def doctor_contacts_delete():
    did = request.form.get("doctor_id")
    contact = request.form.get("contact")
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM Doctor_Contact WHERE Doctor_ID=%s AND Contact_no=%s", (did, contact))
    conn.commit()
    cur.close()
    conn.close()
    flash("Contact deleted.", "success")
    return redirect(url_for("doctor_contacts", id=did))


# ---------------- Blood Units CRUD ----------------
@app.route("/blood")
def blood():
    q = "SELECT * FROM BloodUnit WHERE 1=1"
    params = []
    group_filter = request.args.get("group")
    status_filter = request.args.get("status")
    if group_filter:
        q += " AND Blood_Group = %s"
        params.append(group_filter)
    if status_filter:
        q += " AND Status = %s"
        params.append(status_filter)
    rows = fetch_all(q + " ORDER BY BloodUnit_ID", tuple(params))
    return render_template("blood.html", units=rows)

@app.route("/blood/add", methods=["POST"])
def add_blood():
    f = request.form
    try:
        execute_proc("CALL AddBloodUnit(%s,%s,%s,%s,%s)", (
            f.get("group"), f.get("donation_date"), f.get("expiry_date") or None,
            f.get("donor_id") or None, f.get("hospital_id") or None
        ))
        flash("Blood unit added.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("blood"))

@app.route("/blood/edit/<int:id>", methods=["GET","POST"])
def edit_blood(id):
    if request.method == "POST":
        f = request.form
        try:
            execute_proc("CALL UpdateBloodUnit(%s,%s,%s,%s,%s,%s,%s)", (
                id, f.get("group"), f.get("donation_date"),
                f.get("expiry_date") or None, f.get("status"),
                f.get("donor_id") or None, f.get("hospital_id") or None
            ))
            flash("Blood unit updated.", "success")
        except Error as e:
            flash(str(e), "danger")
        return redirect(url_for("blood"))
    unit = fetch_all("SELECT * FROM BloodUnit WHERE BloodUnit_ID=%s", (id,))
    if not unit:
        flash("Blood unit not found.", "warning")
        return redirect(url_for("blood"))
    return render_template("edit_blood.html", unit=unit[0])

@app.route("/blood/delete/<int:id>", methods=["POST"])
def delete_blood(id):
    try:
        execute_proc("CALL DeleteBloodUnit(%s)", (id,))
        flash("Blood unit deleted.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("blood"))

# ---------------- Organs CRUD ----------------
@app.route("/organs")
def organs():
    rows = fetch_all("SELECT * FROM Organ ORDER BY Organ_ID")
    return render_template("organs.html", organs=rows)

@app.route("/organs/add", methods=["POST"])
def add_organ():
    f = request.form
    try:
        execute_proc("CALL AddOrgan(%s,%s,%s,%s,%s)", (
            f.get("type"), f.get("donation_date"), f.get("expiry_date") or None,
            f.get("donor_id") or None, f.get("hospital_id") or None
        ))
        flash("Organ added.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("organs"))

@app.route("/organs/edit/<int:id>", methods=["GET","POST"])
def edit_organ(id):
    if request.method == "POST":
        f = request.form
        try:
            execute_proc("CALL UpdateOrgan(%s,%s,%s,%s,%s,%s,%s)", (
                id, f.get("type"), f.get("donation_date"),
                f.get("expiry_date") or None, f.get("status"),
                f.get("donor_id") or None, f.get("hospital_id") or None
            ))
            flash("Organ updated.", "success")
        except Error as e:
            flash(str(e), "danger")
        return redirect(url_for("organs"))
    organ = fetch_all("SELECT * FROM Organ WHERE Organ_ID=%s", (id,))
    if not organ:
        flash("Organ not found.", "warning")
        return redirect(url_for("organs"))
    return render_template("edit_organ.html", organ=organ[0])

@app.route("/organs/delete/<int:id>", methods=["POST"])
def delete_organ(id):
    try:
        execute_proc("CALL DeleteOrgan(%s)", (id,))
        flash("Organ deleted.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("organs"))

# ---------------- Transplants ----------------
@app.route("/transplants")
def transplants():
    rows = fetch_all("SELECT * FROM Transplant ORDER BY Transplant_Date DESC")
    return render_template("transplants.html", transplants=rows)

@app.route("/transplants/add", methods=["POST"])
def add_transplant():
    f = request.form
    try:
        execute_proc("CALL AddTransplant(%s,%s,%s,%s,%s,%s,%s)", (
            f.get("type"), f.get("date"),
            f.get("recipient_id") or None, f.get("doctor_id") or None,
            f.get("hospital_id") or None, f.get("bloodunit_id") or None,
            f.get("organ_id") or None
        ))
        flash("Transplant recorded. Status auto-updated by trigger.", "success")
    except Error as e:
        flash(str(e), "danger")
    return redirect(url_for("transplants"))

# ---------------- Run App ----------------
if __name__ == "__main__":
    app.run(debug=True)
