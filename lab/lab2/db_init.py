from flask_sqlalchemy import SQLAlchemy
import mysql.connector

db = SQLAlchemy()

db2 = mysql.connector.connect(
    host='localhost',
    user='root',
    passwd='aaaaa',
    database='bank',
    auth_plugin='mysql_native_password'
)
