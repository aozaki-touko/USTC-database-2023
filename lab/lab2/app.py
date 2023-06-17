from flask import Flask, render_template, request, abort
import config
import numpy as np
import datetime
from db_init import db, db2
import sqlalchemy
from sqlalchemy import func
from models import Bank, Client, Employee, SavingAccount, CheckingAccount, Loan, Apply, \
    Account, Contact, Department, Own, Service, Checking, User
import time
import os
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.config.from_object(config)

db.init_app(app)

cursor = db2.cursor()


@app.route('/')
def hello_world():
    return render_template('login.html')


app.config['UPLOAD_FOLDER'] = os.path.join(app.root_path, 'static/client')
app.config['UPLOAD_FOLDERE'] = os.path.join(app.root_path, 'static/employee')

app.config['ALLOWED_EXTENSIONS'] = {'jpg', 'jpeg', 'png'}


def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']


@app.route('/upload_avatar', methods=['POST'])
def upload_avatar():
    avatar = request.files.get('avatar')
    client_id = request.form.get('clientId')
    if avatar and allowed_file(avatar.filename):
        filename = secure_filename(f'{client_id}.jpg')
        avatar_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        try:
            avatar.save(avatar_path)
        except Exception as e:
            print(f'保存头像失败：{str(e)}')
            return jsonify({'message': '上传头像失败'})
        else:
            print(f'保存头像成功：{avatar_path}')
            return jsonify({'message': '上传头像成功'})
    else:
        return jsonify({'message': '上传头像失败'})


@app.route('/upload_avatarE', methods=['POST'])
def upload_avatarE():
    avatar = request.files.get('avatar')
    client_id = request.form.get('clientId')
    if avatar and allowed_file(avatar.filename):
        filename = secure_filename(f'{client_id}.jpg')
        avatar_path = os.path.join(app.config['UPLOAD_FOLDERE'], filename)
        try:
            avatar.save(avatar_path)
        except Exception as e:
            print(f'保存头像失败：{str(e)}')
            return jsonify({'message': '上传头像失败'})
        else:
            print(f'保存头像成功：{avatar_path}')
            return jsonify({'message': '上传头像成功'})
    else:
        return jsonify({'message': '上传头像失败'})


# 用户登录 ok
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
        return render_template('login.html')
    else:
        if request.form.get('type') == 'signup':

            name = request.form.get('name')
            key = request.form.get('password')
            ret = 100
            cursor.callproc('create_user', (name, key, ret))
            print(ret)
            if ret != 0:
                error_title = '注册错误'
                error_message = '用户名重复'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            return render_template('login.html')

        elif request.form.get('type') == 'login':

            name = request.form.get('name')
            key = request.form.get('password')
            UserNotExist = db.session.query(User).filter_by(username=name).scalar() is None

            if UserNotExist == 1:
                error_title = '登录错误'
                error_message = '用户名不存在'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            user_result = db.session.query(User).filter_by(username=name).first()
            if user_result.password == key:
                return render_template('index.html')
            else:
                error_title = '登录错误'
                error_message = '密码错误'
                return render_template('404.html', error_title=error_title, error_message=error_message)
    return render_template('login.html')


# 重写前端
@app.route('/index')
def index():
    return render_template('index.html')


# 支行管理
@app.route('/bank', methods=['GET', 'POST'])
def bank():
    labels = ['支行名', '所在城市']
    result1 = cursor.execute("select * from bank")
    result = cursor.fetchall()
    if request.method == 'GET':
        return render_template('bank.html', labels=labels, content=result)
    else:
        if request.form.get('type') == 'query':

            bank_name = request.form.get('name')
            bank_city = request.form.get('city')

            if bank_name != "":
                result_query = [(_result[0], _result[1]) for _result in result if _result[0] == bank_name]
            if bank_city != "":
                result_query = [(_result[0], _result[1]) for _result in result if _result[1] == bank_city]
            if bank_city == "" and bank_name == "":
                result_query = result
            return render_template('bank.html', labels=labels, content=result_query)

        elif request.form.get('type') == 'update':
            old_num = request.form.get('key')
            bank_name = request.form.get('bank_name')
            bank_city = request.form.get('bank_city')
            sql = f"update bank set bank.bank_name = '{bank_name}',bank.city = '{bank_city}' WHERE bank.bank_name = '{old_num}'"
            try:
                cursor.execute(sql)
            except Exception as e:
                error_message = '重复的银行名'
                error_title = '更新错误'
                return render_template('404.html', error_title=error_title, error_message=error_message)

        elif request.form.get('type') == 'delete':
            old_num = request.form.get('key')
            # 查找关联员工
            sql = f"select * from bank,bank.employee where bank.bank_name = '{old_num}' and bank.bank_name = employee.bank_name"
            result = cursor.execute(sql)
            BankNotExist = len(cursor.fetchall()) == 0

            if BankNotExist != 1:
                error_title = '删除错误'
                error_message = '支行在存在关联员工'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            # 查找关联贷款
            sql = f"select * from bank,bank.loan where bank.bank_name = '{old_num}' and bank.bank_name = loan.bank_name"
            result = cursor.execute(sql)
            BankNotExist = len(cursor.fetchall()) == 0

            if BankNotExist != 1:
                error_title = '删除错误'
                error_message = '支行在存在关联贷款'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            # 查找关联部门
            sql = f"select * from bank,bank.department where bank.bank_name = '{old_num}' and bank.bank_name = department.bank_name"
            result = cursor.execute(sql)
            BankNotExist = len(cursor.fetchall()) == 0

            if BankNotExist != 1:
                error_title = '删除错误'
                error_message = '支行在存在关联信息'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            cursor.execute(f"delete FROM bank where bank_name = '{old_num}'")
            db2.commit()

        elif request.form.get('type') == 'insert':
            # TODO:需要加一个重复主键的页面跳转(不加也行)
            bank_name = request.form.get('name')
            bank_city = request.form.get('city')
            ret = 0
            aSql = f"call create_bank('{bank_name}','{bank_city}',@b_state)"
            cursor.execute(aSql)
            cursor.execute('select @b_state')
            result3 = cursor.fetchone()
            if result3:
                ret = result3[0]
            if ret == 1:
                error_title = '新建分行错误'
                error_message = '分行名重复'
                return render_template('404.html', error_title=error_title, error_message=error_message)


    result1 = cursor.execute("select * from bank")
    result = cursor.fetchall()

    return render_template('bank.html', labels=labels, content=result)


# 客户管理
@app.route('/client', methods=['GET', 'POST'])
def client():
    labels1 = ['头像', '客户ID', '客户姓名', '客户电话', '客户住址', '联系人姓名', '联系人电话', '关系']
    labels2 = ['客户ID', '员工ID', '服务类型']
    sql1 = "select client_id,client_name,client.telephone,address,name,contact.telephone,relationship from contact,client where client_id = contact.connect_id"
    sql2 = "select * from connection"
    _ = cursor.execute(sql1)
    result1 = cursor.fetchall()
    _ = cursor.execute(sql2)
    result2 = cursor.fetchall()

    if request.method == 'GET':
        return render_template('client.html', labels1=labels1, labels2=labels2, content1=result1, content2=result2)
    else:
        if request.form.get('type') == 'query1':
            clientID = request.form.get('clientID')
            clientName = request.form.get('name')
            clientPhone = request.form.get('phone')
            clientAddress = request.form.get('address')
            coname = request.form.get('cname')
            cophone = request.form.get('cphone')
            corelation = request.form.get('crelation')
            result_query1 = [x for x in result1]
            if clientID != '':
                result_query1 = [x for x in result_query1 if x[0] == clientID]
            if clientName != '':
                result_query1 = [x for x in result_query1 if x[1] == clientName]
            if clientPhone != '':
                result_query1 = [x for x in result_query1 if x[2] == clientPhone]
            if clientAddress != '':
                result_query1 = [x for x in result_query1 if x[3] == clientAddress]
            if coname != '':
                result_query1 = [x for x in result_query1 if x[4] == coname]
            if cophone != '':
                result_query1 = [x for x in result_query1 if x[5] == cophone]
            if corelation != '':
                result_query1 = [x for x in result_query1 if x[6] == corelation]

            return render_template('client.html', labels1=labels1, labels2=labels2, content1=result_query1,
                                   content2=result2)

        elif request.form.get('type') == 'query2':
            clientID = request.form.get('clientID')
            employeeID = request.form.get('staffId')
            stype = request.form.get('Type')
            result_query2 = [x for x in result2]
            if clientID != '':
                result_query2 = [x for x in result_query2 if x[1] == clientID]
            if employeeID != '':
                result_query2 = [x for x in result_query2 if x[0] == employeeID]
            if stype != '':
                result_query2 = [x for x in result_query2 if x[2] == int(stype)]

            return render_template('client.html', labels1=labels1, labels2=labels2, content1=result1,
                                   content2=result_query2)

        elif request.form.get('type') == 'update1':
            clientID = request.form.get('key')
            clientName = request.form.get('name')
            clientPhone = request.form.get('phone')
            clientAddress = request.form.get('address')
            coname = request.form.get('cname')
            cophone = request.form.get('cphone')
            corelation = request.form.get('crelation')
            updateSql = f"update client set client_name = '{clientName}',telephone = '{clientPhone}', address = '{clientAddress}' where client_id = '{clientID}'"
            cursor.execute(updateSql)
            updateSql = f"update contact set name = '{coname}',telephone = '{cophone}',relationship = '{corelation}' where connect_id ='{clientID}'"
            cursor.execute(updateSql)
            db2.commit()

        elif request.form.get('type') == 'update2':
            clientID = request.form.get('key')
            employeeID = request.form.get('staffId')
            stype = request.form.get('Type')
            updateSql = f"update connection set employee_id = '{employeeID}',service = {stype} where  client_id = '{clientID}'"
            cursor.execute(updateSql)
            db2.commit()

        elif request.form.get('type') == 'delete1':
            clientID = request.form.get('key')
            Ssql = f"select * from own_account where client_id = '{clientID}'"
            _ = cursor.execute(Ssql)
            CheckingNotExist = len(cursor.fetchall()) == 0

            if CheckingNotExist != 1:
                error_title = '删除错误'
                error_message = '客户存在关联账户'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            Ssql = f"select * from own_loan where client_id = '{clientID}'"
            _ = cursor.execute(Ssql)
            CheckingNotExist = len(cursor.fetchall()) == 0
            if CheckingNotExist != 1:
                error_title = '删除错误'
                error_message = '客户存在贷款记录'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            Ssql = f"select * from connection where client_id = '{clientID}'"
            _ = cursor.execute(Ssql)
            CheckingNotExist = len(cursor.fetchall()) == 0
            if CheckingNotExist != 1:
                error_title = '删除错误'
                error_message = '客户存在关联服务'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            deleteSql = f"DELETE FROM contact where connect_id = '{clientID}'"
            cursor.execute(deleteSql)
            deleteSql = f"DELETE FROM client where client_id = '{clientID}'"
            cursor.execute(deleteSql)
            filename = secure_filename(f'{clientID}.jpg')
            avatar_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            try:
                os.remove(avatar_path)
                print(f"The file {avatar_path} has been deleted successfully.")
            except OSError as e:
                print(f"Error: {avatar_path} - {e.strerror}.")
            db2.commit()

        elif request.form.get('type') == 'delete2':
            clientID = request.form.get('key')
            deleteSql = f"DELETE FROM connection where client_id = '{clientID}'"
            cursor.execute(deleteSql)
            filename = secure_filename(f'{clientID}.jpg')
            avatar_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            try:
                os.remove(avatar_path)
                print(f"The file {avatar_path} has been deleted successfully.")
            except OSError as e:
                print(f"Error: {avatar_path} - {e.strerror}.")
            db2.commit()

        elif request.form.get('type') == 'insert2':

            clientID = request.form.get('clientID')
            employeeID = request.form.get('staffId')
            stype = request.form.get('Type')
            print(stype)
            sql = f"insert into connection(employee_id, client_id, service) VALUES ('{employeeID}','{clientID}',{int(stype)})"
            cursor.execute(sql)
            db2.commit()

            _ = cursor.execute(sql2)
            result2 = cursor.fetchall()

            return render_template('client.html', labels1=labels1, labels2=labels2, content1=result1, content2=result2)

        elif request.form.get('type') == 'insert1':
            clientID = request.form.get('clientID')
            clientName = request.form.get('name')
            clientPhone = request.form.get('phone')
            clientAddress = request.form.get('address')
            coname = request.form.get('cname')
            cophone = request.form.get('cphone')
            corelation = request.form.get('crelation')
            # todo:加一个添加失败跳转

            ret1 = 0
            c1Sql = f"call create_client('{clientID}','{clientName}','{clientPhone}','{clientAddress}','',@c1_state)"
            cursor.execute(c1Sql)
            cursor.execute('select @c1_state')
            result3 = cursor.fetchone()
            if result3:
                ret1 = result3[0]
            if ret1 == 1:
                error_title = '新建客户错误'
                error_message = '客户id重复'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            ret2 = 0
            c2Sql = f"call create_contact('{clientID}','{coname}','{cophone}','{corelation}',@c2_state)"
            cursor.execute(c2Sql)
            cursor.execute('select @c2_state')
            result4 = cursor.fetchone()
            if result4:
                ret2 = result4[0]
            if ret2 == 1:
                error_title = '新建联系人错误'
                error_message = '客户id不存在或重复绑定'
                # 需要回滚
                return render_template('404.html', error_title=error_title, error_message=error_message)

    _ = cursor.execute(sql1)
    result1 = cursor.fetchall()
    _ = cursor.execute(sql2)
    result2 = cursor.fetchall()
    return render_template('client.html', labels1=labels1, labels2=labels2, content1=result1, content2=result2)


# 员工管理
# TODO:需要再加一个点击员工信息,查看图片的功能
@app.route('/employee', methods=['GET', 'POST'])
def employee():
    labels1 = ['员工头像', '员工ID', '员工姓名', '员工电话', '员工住址', '雇佣日期', '所在支行', '部门号', '部门名称', '部门经理ID']
    labels2 = ['银行名', '部门号', '部门名称', '部门经理ID']

    sql1 = 'select employee_id,employee.name,telephone,address,employ_date,employee.bank_name,department.department_id,department.name,manager_id from employee,manager_table,department where employee.department = department.department_id and manager_table.department_id = department.department_id'
    _ = cursor.execute(sql1)
    result = cursor.fetchall()

    sql2 = 'select department.bank_name,department.department_id,department.name,manager_id from department,manager_table where department.department_id = manager_table.department_id and department.bank_name = manager_table.bank_name'
    _ = cursor.execute(sql2)
    result2 = cursor.fetchall()

    if request.method == 'GET':
        return render_template('employee.html', labels1=labels1, labels2=labels2, content=result, content2=result2)
    else:
        if request.form.get('type') == 'query1':
            ID = request.form.get('staffID')
            name = request.form.get('name')
            phone = request.form.get('phone')
            address = request.form.get('address')
            date = request.form.get('date')
            Bank = request.form.get('bank')
            departID = request.form.get('departId')
            departName = request.form.get('departName')
            ManagerID = request.form.get('ManagerId')
            result_query = [x for x in result]
            flag = False
            if ID != '':
                result_query = [x for x in result_query if x[0] == ID]
                flag = True
            if name != '':
                result_query = [x for x in result_query if x[1] == name]
                flag = True
            if phone != '':
                flag = True
                result_query = [x for x in result_query if x[2] == phone]
            if address != '':
                flag = True
                result_query = [x for x in result_query if x[3] == address]
            if date != '':
                date = date.split('-')
                date = datetime.date(
                    int(date[0]), int(date[1]), int(date[2]))
                result_query = [x for x in result_query if x[4] == date]
                flag = True
            if Bank != '':
                result_query = [x for x in result_query if x[5] == Bank]
                flag = True
            if departID != '':
                result_query = [x for x in result_query if x[6] == int(departID)]
                flag = True
            if departName != '':
                result_query = [x for x in result_query if x[7] == departName]
                flag = True
            if ManagerID != '':
                result_query = [x for x in result_query if x[8] == ManagerID]
                flag = True

            result = result_query
            return render_template('employee.html', labels1=labels1, labels2=labels2, content=result, content2=result2)

        elif request.form.get('type') == 'query2':
            bank = request.form.get('bank')
            departID = request.form.get('departId')
            departName = request.form.get('departName')
            ManagerID = request.form.get('ManagerId')
            result_query2 = [x for x in result2]

            if departID != '':
                flag = True
                result_query2 = [x for x in result_query2 if x[1] == int(departID)]
            if departName != '':
                flag = True
                result_query2 = [x for x in result_query2 if x[2] == departName]
            if bank != '':
                flag = True
                result_query2 = [x for x in result_query2 if x[0] == bank]
            if ManagerID != '':
                flag = True
                result_query2 = [x for x in result_query2 if x[3] == ManagerID]

            result = result
            result2 = result_query2

            return render_template('employee.html', labels1=labels1, labels2=labels2, content=result, content2=result2)

        elif request.form.get('type') == 'update1':
            """如果跨银行,需要检查部门"""
            oldID = request.form.get('key')

            phone = request.form.get('phone')
            address = request.form.get('address')
            Bank = request.form.get('bank')
            departID = int(request.form.get('departId'))
            sqlUpdate = f"update employee set telephone = '{phone}' , address = '{address}',bank_name = '{Bank}',department = {departID}  where employee_id = '{oldID}'"
            cursor.execute(sqlUpdate)
            db2.commit()

        elif request.form.get('type') == 'update2':
            oldID1 = request.form.get('key1')
            oldID2 = int(request.form.get('key2'))

            departName = request.form.get('departName')
            departType = request.form.get('departType')
            ManagerID = request.form.get('ManagerId')

            # 更新功能不允许修改bank名和department id
            ret = 0

            if not ret:
                sqlUpdate = f"update manager_table set manager_id = '{ManagerID}' where department_id = {oldID2} and bank_name = '{oldID1}'"
                cursor.execute(sqlUpdate)
                sqlUpdate = f"update department set type = '{departType}',name = '{departName}' where department_id = {oldID2} and bank_name = '{oldID1}'"
                cursor.execute(sqlUpdate)

                db2.commit()



        elif request.form.get('type') == 'delete1':
            oldID = request.form.get('key')
            qSql = f"select * from connection where employee_id = '{oldID}'"
            cursor.execute(qSql)
            EmployeeNotExist = len(cursor.fetchall()) == 0

            if EmployeeNotExist != 1:
                error_title = '删除错误'
                error_message = '员工在存在关联服务关系'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            qSql = f"select * from manager_table where manager_id = '{oldID}'"
            cursor.execute(qSql)
            EmployeeNotExist = len(cursor.fetchall()) == 0
            if EmployeeNotExist != 1:
                error_title = '删除错误'
                error_message = '员工是经理'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            filename = secure_filename(f'{oldID}.jpg')
            avatar_path = os.path.join(app.config['UPLOAD_FOLDERE'], filename)
            try:
                os.remove(avatar_path)
                print(f"The file {avatar_path} has been deleted successfully.")
            except OSError as e:
                print(f"Error: {avatar_path} - {e.strerror}.")
            qSql = f"DELETE FROM employee WHERE employee_id = '{oldID}'"
            cursor.execute(qSql)
            db2.commit()

        elif request.form.get('type') == 'delete2':
            # 在删除部门之前,需要把其他所有的员工(包括经理)转到另一个部门,此时,经理所在部门和将要被删除的部门不同
            oldID = request.form.get('key2')
            qSql = f"select * from employee where department = {oldID}"
            cursor.execute(qSql)
            filename = secure_filename(f'{oldID}.jpg')
            avatar_path = os.path.join(app.config['UPLOAD_FOLDERE'], filename)
            try:
                os.remove(avatar_path)
                print(f"The file {avatar_path} has been deleted successfully.")
            except OSError as e:
                print(f"Error: {avatar_path} - {e.strerror}.")
            DepartmentNotExist = len((cursor.fetchall())) == 0

            if DepartmentNotExist != 1:
                error_title = '删除错误'
                error_message = '部门在存在关联员工'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            # 此时,移除manager_table的部门,和department的部门
            qSql = f"delete from manager_table where department_id = {oldID}"
            cursor.execute(qSql)
            qSql = f"delete from department where department_id = {oldID}"
            cursor.execute(qSql)
            db2.commit()


        elif request.form.get('type') == 'insert1':
            ID = request.form.get('staffID')
            name = request.form.get('name')
            phone = request.form.get('phone')
            address = request.form.get('address')
            date = request.form.get('date')
            Bank = request.form.get('bank')
            departID = request.form.get('departId')
            departName = request.form.get('departName')
            # STR_TO_DATE('2023-06-16', '%Y-%m-%d');
            eSql = f"call create_employee('{ID}','{Bank}',{departID},'{name}','{phone}','{address}','',(STR_TO_DATE('{date}', '%Y-%m-%d')),'{departName}',@e_state)"
            cursor.execute(eSql)
            cursor.execute('select @e_state')
            result3 = cursor.fetchone()
            if result3:
                ret = result3[0]
            if ret == 1:
                error_title = '新建雇员错误'
                error_message = 'ID重复或分行or部门不存在'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            _ = cursor.execute(sql1)
            result = cursor.fetchall()

            return render_template('employee.html', labels1=labels1, labels2=labels2, content=result, content2=result2)

        elif request.form.get('type') == 'insert2':
            departID = request.form.get('departId')
            departName = request.form.get('departName')
            departType = request.form.get('departType')
            ManagerID = request.form.get('ManagerId')
            bank = request.form.get('bank')
            # todo:加入失败跳转
            dSql = f"call create_department('{bank}','{departName}','{departType}',{departID},@d_state)"
            cursor.execute(dSql)
            cursor.execute('select @d_state')
            result3 = cursor.fetchone()
            if result3:
                ret = result3[0]
            if ret == 1:
                error_title = '新建部门错误'
                error_message = 'ID重复或分行不存在'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            mSql = f"call set_manager('{bank}',{departID},'{ManagerID}',@m_state)"
            cursor.execute(mSql)
            cursor.execute('select @m_state')
            result3 = cursor.fetchone()
            if result3:
                ret = result3[0]
            if ret!=0:
                mSql = f"delete from department where department_id = {departID}"
                cursor.execute(mSql)
                db2.commit()
            if ret == 1:
                error_title = '设置部门管理人错误'
                error_message = '设置了不合法的经理或部门'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 2:
                error_title = '设置部门管理人错误'
                error_message = '该部门已有管理人'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 3:
                error_title = '设置部门管理人错误'
                error_message = '此人已为其他部门管理人'
                return render_template('404.html', error_title=error_title, error_message=error_message)

    sql1 = 'select employee_id,employee.name,telephone,address,employ_date,employee.bank_name,department.department_id,department.name,manager_id from employee,manager_table,department where employee.department = department.department_id and manager_table.department_id = department.department_id'
    _ = cursor.execute(sql1)
    result = cursor.fetchall()

    sql2 = 'select department.bank_name,department.department_id,department.name,manager_id from department,manager_table where department.department_id = manager_table.department_id and department.bank_name = manager_table.bank_name'
    _ = cursor.execute(sql2)
    result2 = cursor.fetchall()
    return render_template('employee.html', labels1=labels1, labels2=labels2, content=result, content2=result2)


@app.route('/transfer', methods=['GET', 'POST'])
def transfer():
    if request.method == "GET":
        return render_template('transfer.html')
    if request.form.get('type') == 'caddAcc':
        # TODO:需要加一个重复主键的页面跳转(不加也行)
        accFromId = str(request.form.get('accFromId'))
        accToID = str(request.form.get('accToID'))
        amount = float(request.form.get('amount'))
        ret = 10
        cursor.execute(f"call transfer('{accFromId}','{accToID}',{amount},@tf_state);")
        cursor.execute('select @tf_state')
        result = cursor.fetchone()
        if result:
            ret = result[0]

        if ret == 2:
            error_title = '转账错误'
            error_message = '转账金额非法'
            return render_template('404.html', error_title=error_title, error_message=error_message)
        if ret == 3:
            error_title = '转账错误'
            error_message = '转出账户余额不足'
            return render_template('404.html', error_title=error_title, error_message=error_message)
        if ret == 4:
            error_title = '转账错误'
            error_message = '账户不存在'
            return render_template('404.html', error_title=error_title, error_message=error_message)
        if accToID == accFromId:
            error_title = '转账错误'
            error_message = '不能给自己转账'
            return render_template('404.html', error_title=error_title, error_message=error_message)
    return render_template('transfer.html')


# 账户管理
@app.route('/account', methods=['GET', 'POST'])
def account():
    labels1 = ['账户号', '客户ID', '客户姓名', '开户时间', '账户余额', '利率']
    labels2 = ['账户号', '客户ID', '客户姓名', '开户时间', '账户余额', '透支额度']
    # 重写sql
    try:
        sql1 = "select account.account_id,client.client_id,client_name,account.create_date,balance,interest_rate from own_account,account,client,saving_account where account.account_id = own_account.account_id and saving_account.account_id = own_account.account_id and type = 0 and client.client_id = own_account.client_id"
        cursor.execute(sql1)
        result1 = cursor.fetchall()
        sql2 = "select account.account_id,client.client_id,client_name,account.create_date,balance,overdraft from own_account,account,client,check_account where account.account_id = own_account.account_id and check_account.account_id = own_account.account_id and type = 1 and client.client_id = own_account.client_id"
        cursor.execute(sql2)
        result2 = cursor.fetchall()
    except Exception as e:
        print('客户创建失败:', e)

    print(len(result2))

    if request.method == 'GET':
        return render_template('account.html', labels1=labels1, labels2=labels2, content1=result1, content2=result2)
    else:
        if request.form.get('type') == 'squery':
            accID = request.form.get('accId')
            clientID = request.form.get('clientID')
            clientName = request.form.get('clientName')
            openDate = request.form.get('openDate')
            balance = request.form.get('balance')
            interestRate = request.form.get('interest')
            flag = False
            result_query = [x for x in result1]
            if accID != "":
                result_query = [x for x in result_query if x[0] == accID]
                flag = True
            if clientID != "":
                result_query = [x for x in result_query if x[1] == clientID]
                flag = True
            if clientName != "":
                result_query = [x for x in result_query if x[2] == clientName]
                flag = True
            if openDate != "":
                date = openDate.split('-')
                date = datetime.date(
                    int(date[0]), int(date[1]), int(date[2]))
                result_query = [x for x in result_query if x[3] == date]
                flag = True
            if balance != "":
                result_query = [x for x in result_query if x[4] == float(balance)]
                flag = True
            if interestRate != "":
                result_query = [x for x in result_query if x[5] == float(interestRate)]
                flag = True

            return render_template('account.html', labels1=labels1, labels2=labels2, content1=result_query,
                                   content2=result2)

        elif request.form.get('type') == 'cquery':
            accID = request.form.get('accId')
            clientID = request.form.get('clientID')
            clientName = request.form.get('clientName')
            openDate = request.form.get('openDate')
            balance = request.form.get('balance')
            overDraft = request.form.get('overDraft')

            flag = False
            result_query = [x for x in result2]
            if accID != "":
                result_query = [x for x in result_query if x[0] == accID]
                flag = True
            if clientID != "":
                result_query = [x for x in result_query if x[1] == clientID]
                flag = True
            if clientName != "":
                result_query = [x for x in result_query if x[2] == clientName]
                flag = True
            if openDate != "":
                date = openDate.split('-')
                date = datetime.date(
                    int(date[0]), int(date[1]), int(date[2]))
                result_query = [x for x in result_query if x[3] == date]
                flag = True
            if balance != "":
                result_query = [x for x in result_query if x[4] == float(balance)]
                flag = True
            if overDraft != "":
                result_query = [x for x in result_query if x[5] == float(overDraft)]
                flag = True

            return render_template('account.html', labels1=labels1, labels2=labels2, content1=result1,
                                   content2=result_query)

        elif request.form.get('type') == 'saddAcc':
            accID = request.form.get('accId')
            clientID = request.form.get('clientID')
            openDate = request.form.get('openDate')

            openDate = openDate.split('-')
            openDate = datetime.date(
                int(openDate[0]), int(openDate[1]), int(openDate[2]))
            ret = 0

            #cursor.callproc('create_account', (accID, 0, openDate, clientID, ret, ''))
            #print('创建成功')
            cursor.execute(f"call create_account('{accID}',0,(STR_TO_DATE('{openDate}', '%Y-%m-%d')),'{clientID}',@sa_state,@msg);")
            cursor.execute('select @sa_state')
            result = cursor.fetchone()
            if result:
                ret = result[0]
            if ret == 1:
                error_title = '创建错误'
                error_message = '重复账户号,或账户不存在'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 2:
                error_title = '创建错误'
                error_message = '账户不存在'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 3:
                error_title = '创建错误'
                error_message = '账户类型不合法'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 4:
                error_title = '创建错误'
                error_message = '客户最多只能有一个此类型账户'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            # todo 根据ret不等于0跳转到其他的404

        elif request.form.get('type') == 'caddAcc':
            accID = request.form.get('accId')
            clientID = request.form.get('clientID')
            openDate = request.form.get('openDate')

            openDate = openDate.split('-')
            openDate = datetime.date(
                int(openDate[0]), int(openDate[1]), int(openDate[2]))
            ret = 0
            # todo 加入异常跳转

            cursor.execute(
                f"call create_account('{accID}',1,(STR_TO_DATE('{openDate}', '%Y-%m-%d')),'{clientID}',@sa_state,@msg);")
            cursor.execute('select @sa_state')
            result = cursor.fetchone()
            if result:
                ret = result[0]
            if ret == 1:
                error_title = '创建错误'
                error_message = '重复账户号,或账户不存在'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 2:
                error_title = '创建错误'
                error_message = '账户不存在'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 3:
                error_title = '创建错误'
                error_message = '账户类型不合法'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 4:
                error_title = '创建错误'
                error_message = '客户最多只能有一个此类型账户'
                return render_template('404.html', error_title=error_title, error_message=error_message)


        elif request.form.get('type') == 'supdate':
            oldAccount = request.form.get('key')
            balance = float(request.form.get('sBalance'))
            interestRate = float(request.form.get('sInterest'))

            sqlUpdate = f"update account set balance = {balance} where account_id = '{oldAccount}'"
            cursor.execute(sqlUpdate)
            db2.commit()
            sqlUpdate = f"update saving_account set interest_rate = {interestRate} where account_id = '{oldAccount}'"
            cursor.execute(sqlUpdate)
            db2.commit()

        elif request.form.get('type') == 'cupdate':
            oldAccount = request.form.get('key')
            balance = float(request.form.get('cBalance'))
            overDraft = float(request.form.get('cOver'))
            sqlUpdate = f"update account set balance = {balance} where account_id = '{oldAccount}'"
            cursor.execute(sqlUpdate)
            sqlUpdate = f"update check_account set overdraft = {overDraft} where account_id = '{oldAccount}'"
            cursor.execute(sqlUpdate)
            db2.commit()

        elif request.form.get('type') == 'sdelete':
            oldID = request.form.get('key')
            qSql = f"delete from saving_account where account_id = '{oldID}'"
            cursor.execute(qSql)
            qSql = f"delete from own_account where account_id = '{oldID}'"
            cursor.execute(qSql)
            qSql = f"delete from account where account_id = '{oldID}'"
            cursor.execute(qSql)
            db2.commit()

        elif request.form.get('type') == 'cdelete':
            oldID = request.form.get('key')
            qSql = f"""select loan.loan_id,client.client_id from loan,own_loan,client,check_account,own_account
                                     where client.client_id = own_loan.client_id
                                       and own_loan.loan_id = loan.loan_id and loan.status = 0
                                        and client.client_id = '{oldID}' and check_account.account_id = own_account.account_id
                                       and own_account.client_id = client.client_id"""

            cursor.execute(qSql)
            flag = len(cursor.fetchall()) == 0
            if flag != 0:
                error_title = '删除错误'
                error_message = '不可删除没有还清的贷款'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            qSql = f"delete from check_account where account_id = '{oldID}'"
            cursor.execute(qSql)
            qSql = f"delete from own_account where account_id = '{oldID}'"
            cursor.execute(qSql)
            qSql = f"delete from account where account_id = '{oldID}'"
            cursor.execute(qSql)
            db2.commit()
        cursor.execute(sql1)
        result1 = cursor.fetchall()
        cursor.execute(sql2)
        result2 = cursor.fetchall()
        return render_template('account.html', labels1=labels1, labels2=labels2, content1=result1, content2=result2)


# 贷款管理
@app.route('/debt', methods=['GET', 'POST'])
def debt():
    labels1 = ['贷款号', '发放支行', '贷款人id', '贷款金额', '已支付金额', '贷款状态']
    labels2 = ['支付号', '贷款号', '客户ID', '支付金额', '支付日期']

    sql1 = "select loan.loan_id,bank_name,client_id,amount,paid_amount,status from loan,own_loan where loan.loan_id = own_loan.loan_id"
    sql2 = "select pay_id,loan_id,pay_c_id,amount,pay_date from pay_loan"
    try:
        cursor.execute(sql1)
        result1 = cursor.fetchall()
        cursor.execute(sql2)
        result2 = cursor.fetchall()
    except Exception as e:
        print('客户创建失败:', e)

    if request.method == 'GET':
        return render_template('debt.html', labels1=labels1, labels2=labels2, content1=result1, content2=result2)
    else:
        if request.form.get('type') == 'main_query':
            num = request.form.get('num')
            Bank = request.form.get('bank')
            money = request.form.get('money')
            state = request.form.get('state')
            content_query1 = [x for x in result1]
            if num != '':
                content_query1 = [x for x in content_query1 if x[0] == num]
            if Bank != '':
                content_query1 = [x for x in content_query1 if x[1] == Bank]
            if money != '':
                content_query1 = [x for x in content_query1 if x[2] == money]
            if state != '':
                content_query1 = [x for x in content_query1 if x[5] == int(state)]

            return render_template('debt.html', labels1=labels1, labels2=labels2, content1=content_query1,
                                   content2=result2)

        elif request.form.get('type') == 'delete':
            oldNum = request.form.get('key')

            qSql = f"select * from loan where loan_id = '{oldNum}' and status = 1"
            cursor.execute(qSql)
            flag = len(cursor.fetchall()) == 1
            if flag == 0:
                error_title = '删除错误'
                error_message = '不可删除没有还清的贷款'
                return render_template('404.html', error_title=error_title, error_message=error_message)

            qSql = f"delete from own_loan where loan_id = '{oldNum}'"
            cursor.execute(qSql)
            qSql = f"delete  from pay_loan where loan_id = '{oldNum}'"
            cursor.execute(qSql)
            qSql = f"delete from loan where loan_id = '{oldNum}'"
            cursor.execute(qSql)
            db2.commit()

        elif request.form.get('type') == 'insert':
            # todo:加一个贷款失败跳转(ycl加)
            num = request.form.get('num')
            Bank = request.form.get('bank')
            money = float(request.form.get('money'))
            client_id = request.form.get('client')
            ret = 10
            aSql = f"call apply_loan('{Bank}','{num}',{money},'{client_id}',@al_state)"
            cursor.execute(aSql)
            cursor.execute('select @al_state')
            result3 = cursor.fetchone()
            if result3:
                ret = result3[0]
            if ret == 1:
                error_title = '贷款申请错误'
                error_message = '申请超额或申请金额非法'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 2:
                error_title = '贷款申请错误'
                error_message = '不存在此分行'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 4:
                error_title = '贷款申请错误'
                error_message = '不存在此分行或贷款号重复'
                return render_template('404.html', error_title=error_title, error_message=error_message)



        elif request.form.get('type') == 'query':
            loanNum = request.form.get('loanNum')
            clientID = request.form.get('clientID')
            payID = request.form.get('payID')
            date = request.form.get('date')
            money = request.form.get('money')

            content_query2 = [x for x in result2]
            if loanNum != '':
                content_query2 = [x for x in content_query2 if x[1] == loanNum]
            if clientID != '':
                content_query2 = [x for x in content_query2 if x[2] == clientID]
            if payID != '':
                content_query2 = [x for x in content_query2 if x[0] == payID]
            if date != '':
                date = date.split('-')
                date = datetime.date(int(date[0]), int(date[1]), int(date[2]))
                content_query2 = [x for x in content_query2 if x[4] == date]
            if money != '':
                content_query2 = [x for x in content_query2 if x[3] == float(money)]

            return render_template('debt.html', labels1=labels1, labels2=labels2, content1=result1,
                                   content2=content_query2)

        elif request.form.get('type') == 'give':
            bank = request.form.get('bankName')
            loanNum = request.form.get('loanNum')
            clientID = request.form.get('clientID')
            payID = request.form.get('payID')
            money = float(request.form.get('money'))

            ret = 10
            # 此处是支付贷款
            # todo:加一个支付结果跳转
            qSql = f"call pay_loan('{bank}','{loanNum}','{payID}',{money},(CURDATE()),'{clientID}',@pl_state)"
            cursor.execute(qSql)
            cursor.execute('select @pl_state')
            result = cursor.fetchone()
            if result:
                ret = result[0]
            if ret == 1:
                error_title = '贷款支付错误'
                error_message = '支付号重复'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 2:
                error_title = '贷款支付错误'
                error_message = '金额非法'
                return render_template('404.html', error_title=error_title, error_message=error_message)
            if ret == 3:
                error_title = '贷款支付错误'
                error_message = '贷款号错误'
                return render_template('404.html', error_title=error_title, error_message=error_message)


    try:
        cursor.execute(sql1)
        result1 = cursor.fetchall()
        cursor.execute(sql2)
        result2 = cursor.fetchall()
    except Exception as e:
        print('客户创建失败:', e)

    return render_template('debt.html', labels1=labels1, labels2=labels2, content1=result1, content2=result2)


@app.route('/404')
def not_found():
    return render_template('404.html', error_title='错误标题', error_message='错误信息')


@app.errorhandler(Exception)
def err_handle(e):
    error_message = ''
    error_title = ''
    if (type(e) == IndexError):
        error_title = '填写错误'
        error_message = '日期格式错误! (yyyy-mm-dd)'
    elif (type(e) == AssertionError):
        error_title = '删除错误'
        error_message = '删除条目仍有依赖！'
    elif (type(e) == sqlalchemy.exc.IntegrityError):
        error_title = '更新/插入错误'
        error_message = str(e._message())
    return render_template('404.html', error_title=error_title, error_message=error_message)


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8000, debug=True)
