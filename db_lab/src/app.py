import os
from pywebio.platform.tornado import start_server
from pywebio import session
from pywebio.input import *
from pywebio.output import *
import mysql.connector
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
import time

# 数据库连接配置
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '123',
    'database': 'lab3'
}

# 创建数据库连接
db_connection = mysql.connector.connect(**db_config)

# 公寓楼/房间管理
def apartments_manage():
    """ 公寓管理系统

    管理公寓楼和房间
    """
    actions = select('公寓管理系统', ['公寓楼管理', '房间管理'], required=True)
    if actions == '公寓楼管理':
        action = select('公寓楼管理', ['增加公寓楼', '删除公寓楼', '修改公寓楼信息', '查询公寓楼信息'], required=True)
        if action == '增加公寓楼':
            def check_form(data):
                if len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['apFloors'] <= 0:
                    return ('apFloors', '公寓楼层数必须是正数')
                
            data = input_group("增加公寓楼",[
                input("公寓楼编号：", name='apNum', type="text", required=True),
                input("公寓楼名称：", name='apName', type="text", required=True),
                input("公寓楼层数：", name='apFloors', type="number", required=True)
            ], validate=check_form)
            
            # 调用存储过程来增加公寓楼
            cursor = db_connection.cursor()
            result = cursor.callproc('addApartment', (data['apNum'], data['apName'], data['apFloors'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '删除公寓楼':
            def check_form(data):
                if len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                
            data = input_group("删除公寓楼",[
                input("公寓楼编号：", name='apNum', type="text", required=True)
            ], validate=check_form)

            # 调用存储过程来查询指定公寓楼的所有房间信息
            cursor = db_connection.cursor()
            cursor.callproc('getRoomsByApartment', (data['apNum'],))
            for result in cursor.stored_results():
                rooms_data = result.fetchall()
            cursor.close()

            # 调用存储过程来删除公寓楼
            cursor = db_connection.cursor()
            result = cursor.callproc('deleteApartment', (data['apNum'], ''))
            db_connection.commit()
            cursor.close()

            if result[-1] == '成功':
                for rooms in rooms_data:
                    img_path = rooms[4]
                    if img_path != None:
                        os.remove(img_path)
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '修改公寓楼信息':
            def check_form(data):
                if len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['apFloors'] != None and data['apFloors'] <= 0:
                    return ('apFloors', '公寓楼层数必须是正数')
                
            data = input_group("修改公寓楼信息",[
                input("公寓楼编号：", name='apNum', type="text", required=True),
                input("公寓楼新名称：", name='apName', type="text"),
                input("公寓楼新层数：", name='apFloors', type="number")
            ], validate=check_form)
            if len(data['apName']) == 0:
                data['apName'] = None
            
            # 调用存储过程来修改公寓楼信息
            cursor = db_connection.cursor()
            result = cursor.callproc('updateApartment', (data['apNum'], data['apName'], data['apFloors'], ''))
            db_connection.commit()
            cursor.close()
            
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '查询公寓楼信息':
            # 查询所有公寓楼信息
            cursor = db_connection.cursor()
            cursor.execute("SELECT * FROM Apartments")
            apartments_data = cursor.fetchall()
            cursor.close()
            put_text('所有公寓楼信息')
            put_table(apartments_data, header=['公寓楼编号', '公寓楼名称', '公寓楼层数'])

            # 获取所有公寓的信息以填充下拉框
            cursor = db_connection.cursor()
            cursor.execute("SELECT Ap_number FROM Apartments")
            apartments = cursor.fetchall()
            cursor.close()
            
            selected_ap = select('选择要查询的公寓楼编号', [item[0] for item in apartments], required=True)
            
            # 调用存储过程来查询指定公寓楼的所有房间信息
            cursor = db_connection.cursor()
            cursor.callproc('getRoomsByApartment', (selected_ap,))
            for result in cursor.stored_results():
                rooms_data = result.fetchall()
            cursor.close()
            
            put_text('公寓楼编号为 {} 的所有房间信息'.format(selected_ap))
            put_table(rooms_data, header=['房间楼层', '房间编号', '总可容纳人数', '已住人数', '房间图片路径'])

    elif actions == '房间管理':
        action = select('房间管理', ['增加房间', '删除房间', '修改房间信息', '查询房间信息'], required=True)
        if action == '增加房间':
            def check_form(data):
                if len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['floor_'] <= 0:
                    return ('floor_', '楼层数必须是正数')
                if data['numberOnFloor'] <= 0:
                    return ('numberOnFloor', '房间编号必须是正数')
                if data['capacity'] <= 0:
                    return ('capacity', '房间容量必须是正数')
                
            data = input_group("增加房间",[
                input("公寓楼编号：", name='apNum', type="text", required=True),
                input("房间楼层：", name='floor_', type="number", required=True),
                input("房间编号：", name='numberOnFloor', type="number", required=True),
                input("房间容量：", name='capacity', type="number", required=True),
                file_upload("房间图片：", name='roomImg', accept="image/*")
            ], validate=check_form)
            if data['roomImg'] != None:
                # 将图片保存到服务器并返回路径
                filename = data['roomImg']["filename"]
                with open(f'.\src\image\{filename}', 'wb') as f:
                    f.write(data['roomImg']['content'])
                data['roomImg'] = f'.\src\image\{filename}'
            
            # 调用存储过程来增加房间
            cursor = db_connection.cursor()
            result = cursor.callproc('addRoom', (data['apNum'], data['floor_'], data['numberOnFloor'], data['capacity'], data['roomImg'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '删除房间':
            def check_form(data):
                if len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['floor_'] <= 0:
                    return ('floor_', '楼层数必须是正数')
                if data['numberOnFloor'] <= 0:
                    return ('numberOnFloor', '房间编号必须是正数')
                
            data = input_group("删除房间",[
                input("公寓楼编号：", name='apNum', type="text", required=True),
                input("房间楼层：", name='floor_', type="number", required=True),
                input("房间编号：", name='numberOnFloor', type="number", required=True)
            ], validate=check_form)

            # 若原来有图片，需要删除
            cursor = db_connection.cursor()
            cursor.callproc('getRoomCapacity', (data['apNum'], data['floor_'], data['numberOnFloor']))
            for result in cursor.stored_results():
                room_capacity = result.fetchall()
            cursor.close()
            
            # 调用存储过程来删除房间
            cursor = db_connection.cursor()
            result = cursor.callproc('deleteRoom', (data['apNum'], data['floor_'], data['numberOnFloor'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                img_path = room_capacity[0][2]
                if img_path != None:
                    os.remove(img_path)
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '修改房间信息':
            def check_form(data):
                if len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['floor_'] <= 0:
                    return ('floor_', '楼层数必须是正数')
                if data['numberOnFloor'] <= 0:
                    return ('numberOnFloor', '房间编号必须是正数')
                if data['capacity'] != None and data['capacity'] <= 0:
                    return ('capacity', '房间容量必须是正数')
                
            data = input_group("修改房间信息",[
                input("公寓楼编号：", name='apNum', type="text", required=True),
                input("房间楼层：", name='floor_', type="number", required=True),
                input("房间编号：", name='numberOnFloor', type="number", required=True),
                input("房间新容量：", name='capacity', type="number"),
                file_upload("房间图片：", name='roomImg', accept="image/*")
            ], validate=check_form)
            if data['roomImg'] != None:
                # 将图片保存到服务器并返回路径
                filename = data['roomImg']["filename"]
                with open(f'.\src\image\{filename}', 'wb') as f:
                    f.write(data['roomImg']['content'])
                data['roomImg'] = f'.\src\image\{filename}'

            # 若原来有图片，需要删除
            cursor = db_connection.cursor()
            cursor.callproc('getRoomCapacity', (data['apNum'], data['floor_'], data['numberOnFloor']))
            for result in cursor.stored_results():
                room_capacity = result.fetchall()
            cursor.close()
            
            # 调用存储过程来修改房间信息
            cursor = db_connection.cursor()
            result = cursor.callproc('updateRoom', (data['apNum'], data['floor_'], data['numberOnFloor'], data['capacity'], data['roomImg'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                img_path = room_capacity[0][2]
                if img_path != None:
                    os.remove(img_path)
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '查询房间信息':
            # 查询所有房间信息
            cursor = db_connection.cursor()
            cursor.execute("SELECT * FROM Rooms")
            rooms_data = cursor.fetchall()
            cursor.close()
            put_text('所有房间信息')
            put_table(rooms_data, header=['公寓楼编号', '房间楼层', '房间编号', '总可容纳人数', '已住人数', '房间图片路径'])

            # 获取所有房间的信息以填充下拉框
            cursor = db_connection.cursor()
            cursor.execute("SELECT Ap_number, Floor_, Number_onFloor FROM Rooms")
            rooms = cursor.fetchall()
            cursor.close()
            
            room_options = ["{}-{}-{}".format(room[0], room[1], room[2]) for room in rooms]
            selected_room = select('选择要查询的房间（公寓楼-楼层-房间号）', room_options, required=True)
            
            apNum, floor_, numberOnFloor = selected_room.split('-')
            
            # 调用存储过程来查询指定房间的学生信息和房间容量信息
            cursor = db_connection.cursor()
            cursor.callproc('getRoomDetails', (apNum, floor_, numberOnFloor))
            for result in cursor.stored_results():
                room_details = result.fetchall()
            cursor.close()

            cursor = db_connection.cursor()
            cursor.callproc('getRoomCapacity', (apNum, floor_, numberOnFloor))
            for result in cursor.stored_results():
                room_capacity = result.fetchall()
            cursor.close()
            
            put_text('{}公寓 {}层 {}号房间居住信息'.format(apNum, floor_, numberOnFloor))
            put_text('总可容纳人数：{}    已住人数：{}'.format(room_capacity[0][0], room_capacity[0][1]))
            img_path = room_capacity[0][2]
            if img_path != None:
                img = open(img_path, 'rb').read()  
                put_image(img, width='400px')

            put_table(room_details, header=['学生编号', '学生姓名', '学生性别'])

    apartments_manage()


# 学生增删改查，入住退宿，报修入口
def students_manage():
    """ 学生管理系统

    管理学生信息和住宿信息
    """
    actions = select('学生管理系统', ['学生基本信息管理', '学生住宿管理', '学生报修系统'], required=True)
    if actions == '学生基本信息管理':
        action = select('学生基本信息管理', ['增加学生', '删除学生', '修改学生信息', '查询学生信息'], required=True)
        if action == '增加学生':
            def check_form(data):
                if len(data['stuNum']) != 10:
                    return ('stuNum', '学号格式不正确')
                if len(data['apNum']) != 0 and len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['floor_'] != None and data['floor_'] <= 0:
                    return ('floor_', '楼层数必须是正数')
                if data['numberOnFloor'] != None and data['numberOnFloor'] <= 0:
                    return ('numberOnFloor', '房间编号必须是正数')
                
            data = input_group("增加学生",[
                input("学生学号：", name='stuNum', type="text", required=True),
                input("公寓楼编号：", name='apNum', type="text"),
                input("房间楼层：", name='floor_', type="number"),
                input("房间编号：", name='numberOnFloor', type="number"),
                input("学生姓名：", name='stuName', type="text", required=True),
                select("学生性别：", name='stuGender', options=[["男",0],["女",1]], index=0)
            ], validate=check_form)
            if len(data['apNum']) == 0:
                data['apNum'] = None
            
            # 调用存储过程来增加学生
            cursor = db_connection.cursor()
            result = cursor.callproc('addStudent', (data['stuNum'], data['apNum'], data['floor_'], data['numberOnFloor'], data['stuName'], data['stuGender'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '删除学生':
            def check_form(data):
                if len(data['stuNum']) != 10:
                    return ('stuNum', '学号格式不正确')
                
            data = input_group("删除学生",[
                input("学生学号：", name='stuNum', type="text", required=True)
            ], validate=check_form)
            
            # 调用存储过程来删除学生
            cursor = db_connection.cursor()
            result = cursor.callproc('deleteStudent', (data['stuNum'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '修改学生信息':
            def check_form(data):
                if len(data['stuNum']) != 10:
                    return ('stuNum', '学号格式不正确')
                if len(data['apNum']) != 0 and len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['floor_'] != None and data['floor_'] <= 0:
                    return ('floor_', '楼层数必须是正数')
                if data['numberOnFloor'] != None and data['numberOnFloor'] <= 0:
                    return ('numberOnFloor', '房间编号必须是正数')
                
            data = input_group("修改学生信息",[
                input("学生学号：", name='stuNum', type="text", required=True),
                input("公寓楼编号：", name='apNum', type="text"),
                input("房间楼层：", name='floor_', type="number"),
                input("房间编号：", name='numberOnFloor', type="number"),
                input("学生姓名：", name='stuName', type="text"),
                select("学生性别：", name='stuGender', options=[["男",0],["女",1],["不改变",2]], index=2)
            ], validate=check_form)
            if len(data['apNum']) == 0:
                data['apNum'] = None
            if len(data['stuName']) == 0:
                data['stuName'] = None
            if data['stuGender'] == 2:
                data['stuGender'] = None
            
            # 调用存储过程来修改学生信息
            cursor = db_connection.cursor()
            result = cursor.callproc('updateStudent', (data['stuNum'], data['apNum'], data['floor_'], data['numberOnFloor'], data['stuName'], data['stuGender'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '查询学生信息':
            # 查询所有学生信息
            cursor = db_connection.cursor()
            cursor.execute("SELECT * FROM Students")
            rooms_data = cursor.fetchall()
            cursor.close()
            put_text('所有学生信息')
            put_table(rooms_data, header=['学号', '所住公寓楼编号', '所住楼层', '所住房间编号', '姓名', '性别'])

            # 获取所有学生的信息以填充下拉框
            cursor = db_connection.cursor()
            cursor.execute("SELECT Stu_number FROM Students")
            students = cursor.fetchall()
            cursor.close()
            
            stuNum = select('选择要查询的学生学号', [item[0] for item in students], required=True)
            
            # 调用存储过程来查询指定学生信息
            cursor = db_connection.cursor()
            cursor.callproc('getStudentDetails', (stuNum,))
            for result in cursor.stored_results():
                stu_details = result.fetchall()
            cursor.close()
            
            put_text('学号为{}的学生信息'.format(stuNum))
            put_table(stu_details, header=['所住公寓楼编号', '所住楼层', '所住房间编号', '姓名', '性别'])


    elif actions == '学生住宿管理':
        action = select('学生住宿管理', ['学生入住', '学生退宿'], required=True)
        if action == '学生入住':
            def check_form(data):
                if len(data['stuNum']) != 10:
                    return ('stuNum', '学号格式不正确')
                if len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['floor_'] <= 0:
                    return ('floor_', '楼层数必须是正数')
                if data['numberOnFloor'] <= 0:
                    return ('numberOnFloor', '房间编号必须是正数')
                
            data = input_group("学生入住",[
                input("学生学号：", name='stuNum', type="text", required=True),
                input("公寓楼编号：", name='apNum', type="text", required=True),
                input("房间楼层：", name='floor_', type="number", required=True),
                input("房间编号：", name='numberOnFloor', type="number", required=True)
            ], validate=check_form)
            
            # 调用存储过程来进行学生入住
            cursor = db_connection.cursor()
            result = cursor.callproc('checkinStudent', (data['stuNum'], data['apNum'], data['floor_'], data['numberOnFloor'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '学生退宿':
            def check_form(data):
                if len(data['stuNum']) != 10:
                    return ('stuNum', '学号格式不正确')
                
            data = input_group("学生退宿",[
                input("学生学号：", name='stuNum', type="text", required=True)
            ], validate=check_form)
            
            # 调用存储过程来进行学生退宿
            cursor = db_connection.cursor()
            result = cursor.callproc('checkoutStudent', (data['stuNum'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

    elif actions == '学生报修系统':
        action = select('学生报修系统', ['新增报修', '删除报修记录', '维修情况登记', '查询报修信息'], required=True)
        if action == '新增报修':
            def check_form(data):
                if len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['floor_'] <= 0:
                    return ('floor_', '楼层数必须是正数')
                if data['numberOnFloor'] <= 0:
                    return ('numberOnFloor', '房间编号必须是正数')
                if len(data['stuNum']) != 10:
                    return ('stuNum', '学号格式不正确')
                
            data = input_group("新增报修",[
                input("公寓楼编号：", name='apNum', type="text", required=True),
                input("房间楼层：", name='floor_', type="number", required=True),
                input("房间编号：", name='numberOnFloor', type="number", required=True),
                input("学生学号：", name='stuNum', type="text", required=True),
                input("报修细节：", name='details_', type="text")
            ], validate=check_form)
            if len(data['details_']) == 0:
                data['details_'] = None
            
            # 调用存储过程来新增报修
            cursor = db_connection.cursor()
            result = cursor.callproc('addRepair', (data['apNum'], data['floor_'], data['numberOnFloor'], data['stuNum'], data['details_'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '删除报修记录':
            def check_form(data):
                if data['repairID'] <= 0:
                    return ('repairID', '报修编号为正数')
                if len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['floor_'] <= 0:
                    return ('floor_', '楼层数必须是正数')
                if data['numberOnFloor'] <= 0:
                    return ('numberOnFloor', '房间编号必须是正数')
                if len(data['stuNum']) != 10:
                    return ('stuNum', '学号格式不正确')
                
            data = input_group("删除报修记录",[
                input("报修编号：", name='repairID', type="number", required=True),
                input("公寓楼编号：", name='apNum', type="text", required=True),
                input("房间楼层：", name='floor_', type="number", required=True),
                input("房间编号：", name='numberOnFloor', type="number", required=True),
                input("学生学号：", name='stuNum', type="text", required=True)
            ], validate=check_form)
            
            # 调用存储过程来删除报修记录
            cursor = db_connection.cursor()
            result = cursor.callproc('deleteRepair', (data['repairID'], data['apNum'], data['floor_'], data['numberOnFloor'], data['stuNum'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '维修情况登记':
            def check_form(data):
                if data['repairID'] <= 0:
                    return ('repairID', '报修编号为正数')
                if len(data['apNum']) != 4:
                    return ('apNum', '公寓楼编号格式不正确')
                if data['floor_'] <= 0:
                    return ('floor_', '楼层数必须是正数')
                if data['numberOnFloor'] <= 0:
                    return ('numberOnFloor', '房间编号必须是正数')
                if len(data['stuNum']) != 10:
                    return ('stuNum', '学号格式不正确')
                
            data = input_group("维修情况登记",[
                input("报修编号：", name='repairID', type="number", required=True),
                input("公寓楼编号：", name='apNum', type="text", required=True),
                input("房间楼层：", name='floor_', type="number", required=True),
                input("房间编号：", name='numberOnFloor', type="number", required=True),
                input("学生学号：", name='stuNum', type="text", required=True),
                input("报修细节：", name='details_', type="text", required=True),
                select("是否完成维修：", name='finish', options=[["是",1],["否",0]], index=1)
            ], validate=check_form)
            
            # 调用存储过程来维修完成登记
            cursor = db_connection.cursor()
            result = cursor.callproc('updateRepair', (data['repairID'], data['apNum'], data['floor_'], data['numberOnFloor'], data['stuNum'], data['details_'], data['finish'], ''))
            db_connection.commit()
            cursor.close()
            if result[-1] == '成功':
                toast(result[-1], color="success")
            else:
                toast(result[-1], color="error")

        elif action == '查询报修信息':
            # 查询所有报修信息
            cursor = db_connection.cursor()
            cursor.execute("SELECT Repair_id, Ap_number, Floor_, Number_onFloor, Stu_number, details, CASE WHEN Repair_status = 0 THEN '待处理' ELSE '已处理' END AS Repair_status FROM As_repair")
            repair_data = cursor.fetchall()
            cursor.close()
            put_text('所有报修信息')
            put_table(repair_data, header=['报修编号', '公寓楼编号', '房间楼层', '房间编号', '学号', '维修详情', '维修状态'])

            # 获取所有报修的信息以填充下拉框
            cursor = db_connection.cursor()
            cursor.execute("SELECT Repair_id, Ap_number, Floor_, Number_onFloor, Stu_number FROM As_repair")
            repairs = cursor.fetchall()
            cursor.close()
            
            repair_options = ["{}-{}-{}-{}-{}".format(repair[0], repair[1], repair[2], repair[3], repair[4]) for repair in repairs]
            selected_repair = select('选择要查询的报修编号（报修编号-公寓楼编号-房间楼层-房间编号-学号）', repair_options, required=True)
            
            repairID, apNum, floor_, numberOnFloor, stuNum = selected_repair.split('-')
            
            # 调用存储过程来查询指定报修信息
            cursor = db_connection.cursor()
            cursor.callproc('getRepairDetails', (repairID, apNum, floor_, numberOnFloor, stuNum))
            for result in cursor.stored_results():
                repair_details = result.fetchall()
            cursor.close()
            
            put_text('学号为{}学生报修的{}公寓{}层{}号房间，报修编号为{}的报修信息'.format(stuNum, apNum, floor_, numberOnFloor, repairID))
            put_table(repair_details, header=['维修详情', '维修状态'])

    students_manage()


# 工作人员增删改查
def workers_manage():
    """ 工作人员管理系统

    管理工作人员信息
    """
    actions = select('工作人员管理系统', ['增加工作人员', '删除工作人员', '修改工作人员信息', '分配管理公寓楼', '查询工作人员信息'], required=True)
    if actions == '增加工作人员':
        def check_form(data):
            if len(data['workerNum']) != 10:
                return ('workerNum', '工号格式不正确')
            if len(data['apNum']) != 0 and len(data['apNum']) != 4:
                return ('apNum', '公寓楼编号格式不正确')
            if len(data['workerContact']) != 0 and len(data['workerContact']) != 11:
                return ('workerContact', '联系方式格式不正确')
        data = input_group("增加工作人员",[
            input("工作人员工号：", name='workerNum', type="text", required=True),
            input("管理公寓楼编号：", name='apNum', type="text"),
            input("工作人员姓名：", name='workerName', type="text", required=True),
            input("工作人员联系方式：", name='workerContact', type="text")
        ], validate=check_form)
        if len(data['apNum']) == 0:
            data['apNum'] = None
        if len(data['workerContact']) == 0:
            data['workerContact'] = None
        
        # 调用存储过程来增加工作人员
        cursor = db_connection.cursor()
        result = cursor.callproc('addWorker', (data['workerNum'], data['apNum'], data['workerName'], data['workerContact'], ''))
        db_connection.commit()
        cursor.close()
        if result[-1] == '成功':
            toast(result[-1], color="success")
        else:
            toast(result[-1], color="error")

    elif actions == '删除工作人员':
        def check_form(data):
            if len(data['workerNum']) != 10:
                return ('workerNum', '工号格式不正确')
        data = input_group("增加工作人员",[
            input("工作人员工号：", name='workerNum', type="text", required=True)
        ], validate=check_form)
        
        # 调用存储过程来删除工作人员
        cursor = db_connection.cursor()
        result = cursor.callproc('deleteWorker', (data['workerNum'], ''))
        db_connection.commit()
        cursor.close()
        if result[-1] == '成功':
            toast(result[-1], color="success")
        else:
            toast(result[-1], color="error")

    elif actions == '修改工作人员信息':
        def check_form(data):
            if len(data['workerNum']) != 10:
                return ('workerNum', '工号格式不正确')
            if len(data['apNum']) != 0 and len(data['apNum']) != 4:
                return ('apNum', '公寓楼编号格式不正确')
            if len(data['workerContact']) != 0 and len(data['workerContact']) != 11:
                return ('workerContact', '联系方式格式不正确')
        data = input_group("增加工作人员",[
            input("工作人员工号：", name='workerNum', type="text", required=True),
            input("新管理公寓楼编号：", name='apNum', type="text"),
            input("工作人员新姓名：", name='workerName', type="text"),
            input("工作人员新联系方式：", name='workerContact', type="text")
        ], validate=check_form)
        if len(data['apNum']) == 0:
            data['apNum'] = None
        if len(data['workerName']) == 0:
            data['workerName'] = None
        if len(data['workerContact']) == 0:
            data['workerContact'] = None
        
        # 调用存储过程来修改工作人员信息
        cursor = db_connection.cursor()
        result = cursor.callproc('updateWorker', (data['workerNum'], data['apNum'], data['workerName'], data['workerContact'], ''))
        db_connection.commit()
        cursor.close()
        if result[-1] == '成功':
            toast(result[-1], color="success")
        else:
            toast(result[-1], color="error")

    elif actions == '分配管理公寓楼':
        def check_form(data):
            if len(data['workerNum']) != 10:
                return ('workerNum', '工号格式不正确')
            if len(data['apNum']) != 0 and len(data['apNum']) != 4:
                return ('apNum', '公寓楼编号格式不正确')
        data = input_group("增加工作人员",[
            input("工作人员工号：", name='workerNum', type="text", required=True),
            input("新管理公寓楼编号：", name='apNum', type="text", required=True)
        ], validate=check_form)
        
        # 调用存储过程来分配管理公寓楼
        cursor = db_connection.cursor()
        result = cursor.callproc('assignWorker', (data['workerNum'], data['apNum'], ''))
        db_connection.commit()
        cursor.close()
        if result[-1] == '成功':
            toast(result[-1], color="success")
        else:
            toast(result[-1], color="error")

    elif actions == '查询工作人员信息':
        # 查询所有工作人员信息
        cursor = db_connection.cursor()
        cursor.execute("SELECT * FROM Workers")
        workers_data = cursor.fetchall()
        cursor.close()
        put_text('所有工作人员信息')
        put_table(workers_data, header=['工号', '管理公寓楼编号', '姓名', '联系方式'])

        # 获取所有工作人员的信息以填充下拉框
        cursor = db_connection.cursor()
        cursor.execute("SELECT Worker_number FROM Workers")
        workers = cursor.fetchall()
        cursor.close()
            
        workerNum = select('选择要查询的工号', [item[0] for item in workers], required=True)
            
        # 调用存储过程来查询指定工作人员信息
        cursor = db_connection.cursor()
        cursor.callproc('getWorkerDetails', (workerNum,))
        for result in cursor.stored_results():
            worker_details = result.fetchall()
        cursor.close()
            
        put_text('工号为{}的工作人员信息'.format(workerNum))
        put_table(worker_details, header=['管理公寓楼编号', '姓名', '联系方式'])

    workers_manage()


# 访客增删改查
def visitors_manage():
    """ 访客登记系统

    管理访问登记信息
    """
    actions = select('访客登记系统', ['来访登记', '删除访问记录', '离开登记', '查询访问记录'], required=True)
    if actions == '来访登记':
        def check_form(data):
            if len(data['visitorIdentity']) != 18:
                return ('visitorIdentity', '身份证号格式不正确')
            if len(data['visitorContact']) != 0 and len(data['visitorContact']) != 11:
                return ('visitorContact', '联系方式格式不正确')
            if len(data['apNum']) != 4:
                return ('apNum', '公寓楼编号格式不正确')
        def set_now_ts(set_value):
            set_value(time.strftime('%Y-%m-%d %H:%M:%S', time.localtime()))
        data = input_group("来访登记",[
            input("访客身份证号：", name='visitorIdentity', type="text", required=True),
            input("访客姓名：", name='visitorName', type="text", required=True),
            input("访客联系方式：", name='visitorContact', type="text"),
            input("公寓楼编号：", name='apNum', type="text", required=True),
            input('来访时间', name='visitTime', type="text", action=('Now', set_now_ts), readonly=True, required=True)
        ], validate=check_form)
        if len(data['visitorContact']) == 0:
            data['visitorContact'] = None
        
        # 调用存储过程来登记访客
        cursor = db_connection.cursor()
        result = cursor.callproc('comeVisitor', (data['visitorIdentity'], data['visitorName'], data['visitorContact'], data['apNum'], data['visitTime'], ''))
        db_connection.commit()
        cursor.close()
        if result[-1] == '成功':
            toast(result[-1], color="success")
        else:
            toast(result[-1], color="error")

    elif actions == '删除访问记录':
        def check_form(data):
            if len(data['visitorIdentity']) != 18:
                return ('visitorIdentity', '身份证号格式不正确')
            if len(data['apNum']) != 4:
                return ('apNum', '公寓楼编号格式不正确')
        data = input_group("来访登记",[
            input("访客身份证号：", name='visitorIdentity', type="text", required=True),
            input("公寓楼编号：", name='apNum', type="text", required=True),
            select("是否删除该访客在该公寓楼所有访问记录：", name='delete_all', options=[["是",1],["否",0]], index=0)
        ], validate=check_form)
        
        if data['delete_all'] == 0:
            def check_data(data):
                if data <= 0:
                    return '访问记录编号必须是正数'
            visitNum = input("删除访问记录编号：", type="number", required=True, validate=check_data)
        else:
            visitNum = 0
        
        # 调用存储过程来删除访问记录
        cursor = db_connection.cursor()
        result = cursor.callproc('deleteVisitor', (data['visitorIdentity'], visitNum, data['apNum'], data['delete_all'], ''))
        db_connection.commit()
        cursor.close()
        if result[-1] == '成功':
            toast(result[-1], color="success")
        else:
            toast(result[-1], color="error")

    elif actions == '离开登记':
        def check_form(data):
            if len(data['visitorIdentity']) != 18:
                return ('visitorIdentity', '身份证号格式不正确')
            if data['visitNum'] <= 0:
                return ('visitNum', '访问记录编号必须是正数')
            if len(data['apNum']) != 4:
                return ('apNum', '公寓楼编号格式不正确')
        def set_now_ts(set_value):
            set_value(time.strftime('%Y-%m-%d %H:%M:%S', time.localtime()))
        data = input_group("来访登记",[
            input("访客身份证号：", name='visitorIdentity', type="text", required=True),
            input("访问记录编号：", name='visitNum', type="number", required=True),
            input("公寓楼编号：", name='apNum', type="text", required=True),
            input('离开时间', name='leaveTime', type="text", action=('Now', set_now_ts), readonly=True, required=True)
        ], validate=check_form)
        
        # 调用存储过程来登记离开
        cursor = db_connection.cursor()
        result = cursor.callproc('updateVisitor', (data['visitorIdentity'], data['visitNum'], data['apNum'], data['leaveTime'], ''))
        db_connection.commit()
        cursor.close()
        if result[-1] == '成功':
            toast(result[-1], color="success")
        else:
            toast(result[-1], color="error")
   
    elif actions == '查询访问记录':
        # 查询所有访问记录
        cursor = db_connection.cursor()
        cursor.execute("SELECT * FROM As_visit")
        visitors_data = cursor.fetchall()
        cursor.close()
        put_text('所有访问记录')
        put_table(visitors_data, header=['访客身份证', '访问编号', '访问公寓楼编号', '访问时间', '访问状态', '离开时间'])

        # 获取所有工作人员的信息以填充下拉框
        cursor = db_connection.cursor()
        cursor.execute("SELECT Visitor_identity, Visit_num, Ap_number FROM As_visit")
        visitors = cursor.fetchall()
        cursor.close()
        
        visitor_options = ["{}-{}-{}".format(visitor[0], visitor[1], visitor[2]) for visitor in visitors]
        selected_visitor = select('选择要查询的访问编号（访客身份证-访问编号-访问公寓楼编号）', visitor_options, required=True)
        
        visitorIdentity, visitNum, apNum = selected_visitor.split('-')

        # 调用存储过程来查询指定访问记录
        cursor = db_connection.cursor()
        cursor.callproc('getVisitorDetails', (visitorIdentity, visitNum, apNum))
        for result in cursor.stored_results():
            visit_details = result.fetchall()
        cursor.close()
            
        put_text('身份证号为{}、访问编号为{}、访问公寓楼编号为{}的访问记录'.format(visitorIdentity, visitNum, apNum))
        put_table(visit_details, header=['访问时间', '离开时间', '访问状态'])

    visitors_manage()


def search_info():
    """ 统计公寓信息

    支持导出PDF
    """
    # 获取所有公寓的信息以填充下拉框
    cursor = db_connection.cursor()
    cursor.execute("SELECT Ap_number FROM Apartments")
    apartments = cursor.fetchall()
    cursor.close()
            
    selected_ap = select('选择要统计的公寓楼编号', [item[0] for item in apartments], required=True)

    # 调用存储过程来查询指定公寓楼的信息
    cursor = db_connection.cursor()
    cursor.callproc('getApartmentDetails', (selected_ap,))
    for result in cursor.stored_results():
        apartment_details = result.fetchall()
    cursor.close()

    apName, apFloors = apartment_details[0]
    
    # 打印公寓名称apName, 公寓楼层数apFloors
    put_markdown(f"# 公寓{selected_ap}信息统计")
    put_text(f"公寓名称: {apName}        公寓楼层数: {apFloors}")

    # 调用存储过程来查询指定公寓楼的所有房间信息
    cursor = db_connection.cursor()
    cursor.callproc('getRoomsByApartment', (selected_ap,))
    for result in cursor.stored_results():
        rooms_data = result.fetchall()
    cursor.close()

    put_markdown(f"## 公寓房间统计")
    if rooms_data:
        for rooms in rooms_data:
            floor_, numberOnFloor, capacity, numOfStu, roomImg = rooms

            # 打印房间总可容纳人数capacity, 已住人数numOfStu
            put_markdown(f"### 房间 {selected_ap}-{floor_}-{numberOnFloor}")
            put_text(f"总可容纳人数: {capacity}        已住人数: {numOfStu}")

            # 调用存储过程来查询指定房间的学生信息和房间容量信息
            cursor = db_connection.cursor()
            cursor.callproc('getRoomDetails', (selected_ap, floor_, numberOnFloor))
            for result in cursor.stored_results():
                room_details = result.fetchall()
            cursor.close()

            # 打印房间所住学生信息：学号stuNum, 姓名stuName, 性别stuGender
            put_markdown(f"#### 居住学生信息")
            if room_details:
                for student in room_details:
                    stuNum, stuName, stuGender = student
                    put_text(f"学号：{stuNum}        姓名：{stuName}        性别：{stuGender}")
            else:
                put_text("暂无居住学生信息")
            
            
            cursor = db_connection.cursor()
            cursor.callproc('getRepairInfo', (selected_ap, floor_, numberOnFloor))
            for result in cursor.stored_results():
                repair_details = result.fetchall()
            cursor.close()

            # 打印房间报修信息：学号stuNum, 报修编号repairID, 详情details_, 是否处理完repairStatus
            put_markdown(f"#### 报修信息")
            if repair_details:
                for repair in repair_details:
                    stuNum, repairID, details_, repairStatus = repair
                    put_text(f"学号：{stuNum}        报修编号：{repairID}        详情：{details_}        维修情况：{repairStatus}")
            else:
                put_text("暂无房间报修信息")
    else:
        put_text("暂无房间信息")

    # 调用存储过程来查询指定公寓楼的管理工作人员信息
    cursor = db_connection.cursor()
    cursor.callproc('getWorkersByApartment', (selected_ap,))
    for result in cursor.stored_results():
        workers_data = result.fetchall()
    cursor.close()

    # 打印工号workerNum, 工作人员姓名workerName, 联系方式workerContact
    put_markdown(f"## 公寓工作人员统计")
    if workers_data:
        for worker in workers_data:
            workerNum, workerName, workerContact = worker
            put_text(f"工号：{workerNum}        工作人员姓名：{workerName}        联系方式：{workerContact}")
    else:
        put_text("暂无工作人员信息")

    # 调用存储过程来查询指定公寓楼的访问信息
    cursor = db_connection.cursor()
    cursor.callproc('getVisitorsByApartment', (selected_ap,))
    for result in cursor.stored_results():
        visitors_data = result.fetchall()
    cursor.close()

    # 打印访客身份证号visitorIdentity, 访问时间visitTime, 离开时间leaveTime, 访问状态visitStatus
    put_markdown(f"## 公寓访客统计")
    if visitors_data:
        for visitor in visitors_data:
            visitorIdentity, visitTime, leaveTime, visitStatus = visitor
            put_text(f"访客身份证号：{visitorIdentity}        访问时间：{visitTime}        离开时间：{leaveTime}        访问状态：{visitStatus}")
    else:
        put_text("暂无访客信息")
        
    def export_pdf():
        pdf_filename = "apartment_info.pdf"
        pdfmetrics.registerFont(UnicodeCIDFont('STSong-Light'))  # 注册中文字体
        c = canvas.Canvas(pdf_filename, pagesize=letter)
        width, height = letter

        # 标题
        c.setFont('STSong-Light', 18)
        c.drawString(250, height - 60, f"公寓 {selected_ap} 信息统计")

        y = height - 90
        c.setFont('STSong-Light', 12)
        c.drawString(200, y, f"公寓名称: {apName}        公寓楼层数: {apFloors}")

        y -= 30
        c.setFont('STSong-Light', 16)
        c.drawString(75, y, "公寓房间统计")

        if rooms_data:
            for rooms in rooms_data:
                floor_, numberOnFloor, capacity, numOfStu, room_img = rooms
                y -= 20
                c.setFont('STSong-Light', 14)
                c.drawString(75, y, f"* 房间 {selected_ap}-{floor_}-{numberOnFloor}")
                c.setFont('STSong-Light', 12)
                y -= 20
                c.drawString(95, y, f"总可容纳人数: {capacity}        已住人数: {numOfStu}")
                
                y -= 20
                c.drawString(95, y, "居住学生信息")
                cursor = db_connection.cursor()
                cursor.callproc('getRoomDetails', (selected_ap, floor_, numberOnFloor))
                for result in cursor.stored_results():
                    room_details = result.fetchall()
                cursor.close()

                if room_details:
                    for student in room_details:
                        y -= 20
                        stuNum, stuName, stuGender = student
                        c.drawString(115, y, f"学号：{stuNum}        姓名：{stuName}        性别：{stuGender}")
                else:
                    y -= 20
                    c.drawString(115, y, "暂无居住学生信息")
                
                y -= 20
                c.drawString(95, y, "报修信息")
                cursor = db_connection.cursor()
                cursor.callproc('getRepairInfo', (selected_ap, floor_, numberOnFloor))
                for result in cursor.stored_results():
                    repair_details = result.fetchall()
                cursor.close()

                if repair_details:
                    for repair in repair_details:
                        y -= 20
                        stuNum, repairID, details_, repairStatus = repair
                        c.drawString(115, y, f"学号：{stuNum}        报修编号：{repairID}        详情：{details_}        维修情况：{repairStatus}")
                else:
                    y -= 20
                    c.drawString(115, y, "暂无房间报修信息")
                
                y -= 10
        else:
            y -= 20
            c.drawString(75, y, "暂无房间信息")

        y -= 30
        c.setFont('STSong-Light', 16)
        c.drawString(75, y, "公寓工作人员统计")
        c.setFont('STSong-Light', 12)
        if workers_data:
            for worker in workers_data:
                y -= 20
                workerNum, workerName, workerContact = worker
                c.drawString(75, y, f"* 工号：{workerNum}        工作人员姓名：{workerName}        联系方式：{workerContact}")
        else:
            y -= 20
            c.drawString(75, y, "暂无工作人员信息")

        y -= 30
        c.setFont('STSong-Light', 16)
        c.drawString(75, y, "公寓访客统计")
        c.setFont('STSong-Light', 12)
        if visitors_data:
            for visitor in visitors_data:
                y -= 20
                visitorIdentity, visitTime, leaveTime, visitStatus = visitor
                c.drawString(75, y, f"* 访客身份证号：{visitorIdentity}        访问状态：{visitStatus}")
                y -= 20
                c.drawString(95, y, f"访问时间：{visitTime}        离开时间：{leaveTime}")
        else:
            y -= 20
            c.drawString(75, y, "暂无访客信息")

        c.save()
        toast("导出PDF成功！", color="success")
        
    # 添加导出为PDF按钮
    put_button("导出为PDF", onclick=export_pdf)


if __name__ == '__main__':

    # 启动 PyWebIO 服务器
    start_server({
        "公寓管理系统": apartments_manage, # 公寓楼/房间管理
        "学生管理系统": students_manage, # 学生增删改查，入住退宿，报修入口
        "工作人员管理系统": workers_manage, # 工作人员增删改查
        "访客登记系统": visitors_manage, # 访客增删改查
    }, port=8000, cdn=False)
