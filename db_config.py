import mysql.connector
from mysql.connector import Error
def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="Sukrutha",
        database="BloodOrganManagement"
    )
