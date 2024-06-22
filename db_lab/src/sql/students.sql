use lab3;


# 函数：判断输入项是否合法
DROP FUNCTION if EXISTS checkRoomOccupancy;
DELIMITER //
CREATE FUNCTION checkRoomOccupancy(
    # 以房间的主码为输入
    apNum char(4),
    floor_ int,
    numberOnFloor int
)
RETURNS VARCHAR(100) 
BEGIN
    DECLARE roomCapacity int;
    DECLARE num_StuNow int;
    DECLARE room_exist int;
    # 检查房间是否存在
    SELECT COUNT(*) INTO room_exist FROM Rooms
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
    if room_exist = 0 THEN
        RETURN '该房间不存在';
    END if;

    SELECT Capacity, NumOfStuNow INTO roomCapacity, num_StuNow FROM Rooms
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
    

    # 检查房间是否有空余
    if num_StuNow >= roomCapacity THEN
        RETURN '房间容量不足';
    END if;

    RETURN NULL;
END //
DELIMITER ;


# 创建触发器: 在Students表插入记录时更新房间入住人数
DROP TRIGGER if EXISTS after_insert_student;
DELIMITER //
CREATE TRIGGER after_insert_student
AFTER INSERT ON Students FOR EACH ROW # 在对学生表每一行的插入之后进行
BEGIN
    # 检查是否有入住信息，有则更新房间入住人数
    IF NEW.Ap_number IS NOT NULL AND NEW.Floor_ IS NOT NULL AND NEW.Number_onFloor IS NOT NULL THEN
        UPDATE Rooms
        SET NumOfStuNow = NumOfStuNow + 1
        WHERE Ap_number = NEW.Ap_number AND Floor_ = NEW.Floor_ AND Number_onFloor = NEW.Number_onFloor;
    END IF;
END //
DELIMITER ;


# 创建触发器: 在Students表删除记录时更新房间入住人数
DROP TRIGGER if EXISTS after_delete_student;
DELIMITER //
CREATE TRIGGER after_delete_student
AFTER DELETE ON Students FOR EACH ROW # 在对学生表每一行的删除之后进行
BEGIN
    # 如果学生有房间信息，则减少房间的入住人数
    IF OLD.Ap_number IS NOT NULL AND OLD.Floor_ IS NOT NULL AND OLD.Number_onFloor IS NOT NULL THEN
        UPDATE Rooms
        SET NumOfStuNow = NumOfStuNow - 1
        WHERE Ap_number = OLD.Ap_number AND Floor_ = OLD.Floor_ AND Number_onFloor = OLD.Number_onFloor;
    END IF;
END //
DELIMITER ;


# 创建触发器: 在Students表更新记录时更新房间入住人数
DROP TRIGGER if EXISTS after_update_student;
DELIMITER //
CREATE TRIGGER after_update_student
AFTER UPDATE ON Students FOR EACH ROW # 在对学生表每一行的更新之后进行
BEGIN
    # 如果学生更新了入住信息，需要处理旧房间和新房间的入住人数
    # 减少旧房间入住人数
    IF OLD.Ap_number IS NOT NULL AND OLD.Floor_ IS NOT NULL AND OLD.Number_onFloor IS NOT NULL THEN
        UPDATE Rooms
        SET NumOfStuNow = NumOfStuNow - 1
        WHERE Ap_number = OLD.Ap_number AND Floor_ = OLD.Floor_ AND Number_onFloor = OLD.Number_onFloor;
    END IF;
    # 增加新房间入住人数
    IF NEW.Ap_number IS NOT NULL AND NEW.Floor_ IS NOT NULL AND NEW.Number_onFloor IS NOT NULL THEN
        UPDATE Rooms
        SET NumOfStuNow = NumOfStuNow + 1
        WHERE Ap_number = NEW.Ap_number AND Floor_ = NEW.Floor_ AND Number_onFloor = NEW.Number_onFloor;
    END IF;
END //
DELIMITER ;


# 增加学生
# 若增加学生的房间信息不为空，则：
# 若房间有空余，增加房间入住人数；若房间无空余，提示增加学生失败信息
DROP PROCEDURE if EXISTS addStudent;
DELIMITER //
CREATE PROCEDURE addStudent(
    IN stuNum char(10),
    IN apNum char(4),
    IN floor_ int,
    IN numberOnFloor int,
    IN stuName VARCHAR(50),
    IN stuGender int,
    OUT result varchar(100) # 返回执行状态信息
)
addStudent: BEGIN
    DECLARE is_assigned int;

    # 检查主码（学号）是否已经存在
    SELECT COUNT(*) INTO is_assigned FROM Students
    WHERE Stu_number = stuNum;
    if is_assigned > 0 THEN
        SET result = '该学生已存在';
        LEAVE addStudent;
    END if;

    # 入住登记房间信息
    if apNum IS NOT NULL AND floor_ IS NOT NULL AND numberOnFloor IS NOT NULL THEN
        SET result = checkRoomOccupancy(apNum, floor_, numberOnFloor); # 调用函数检查房间是否合法
        if result IS NOT NULL THEN
            LEAVE addStudent;
        END if;
        # 插入元组
        INSERT INTO Students(Stu_number, Ap_number, Floor_, Number_onFloor, Stu_name, Stu_gender)
        VALUES(stuNum, apNum, floor_, numberOnFloor, stuName, stuGender);
        
    # 增加没有房间信息的学生
    ELSE
        INSERT INTO Students(Stu_number, Ap_number, Floor_, Number_onFloor, Stu_name, Stu_gender)
        VALUES(stuNum, NULL, NULL, NULL, stuName, stuGender);
    END if;

    SET result = '成功';
END //
DELIMITER ;


# 删除学生
# 同时删除该学生的报修信息，同时若删除学生的房间信息不为空，则通过触发器减少房间入住人数
DROP PROCEDURE if EXISTS deleteStudent;
DELIMITER //
CREATE PROCEDURE deleteStudent(
    IN stuNum char(10),
    OUT result varchar(100)
)
deleteStudent: BEGIN
    DECLARE allow_delete int;
    DECLARE apNum char(4);
    DECLARE floor_ int;
    DECLARE numberOnFloor int;
    # 检查主码（学号）是否存在
    SELECT COUNT(*) INTO allow_delete FROM Students
    WHERE Stu_number = stuNum;
    if allow_delete = 0 THEN
        SET result = '该学生不存在';
        LEAVE deleteStudent;
    END if;

    # 清除报修信息中的相关学生信息
    DELETE FROM As_repair
    WHERE Stu_number = stuNum;

    # 获取学生的房间信息
    SELECT Ap_number, Floor_, Number_onFloor INTO apNum, floor_, numberOnFloor FROM Students
    WHERE Stu_number = stuNum;

    # 删除学生
    DELETE FROM Students
    WHERE Stu_number = stuNum;
    
    SET result = '成功';
END //
DELIMITER ;


# 修改学生信息（姓名，性别，入住信息）
# 仅当输入的信息不为空时修改。
DROP PROCEDURE if EXISTS updateStudent;
DELIMITER //
CREATE PROCEDURE updateStudent(
    IN stuNum char(10),
    IN apNum char(4),
    IN floor_ int,
    IN numberOnFloor int,
    IN stuName VARCHAR(50),
    IN stuGender int,
    OUT result varchar(100)
)
updateStudent: BEGIN
    DECLARE is_assigned int;
    # 检查主码是否存在
    SELECT COUNT(*) INTO is_assigned FROM Students
    WHERE Stu_number = stuNum;
    if is_assigned = 0 THEN
        SET result = '该学生不存在';
        LEAVE updateStudent;
    END if;

    # 修改房间信息
    if apNum IS NOT NULL AND floor_ IS NOT NULL AND numberOnFloor IS NOT NULL THEN
        SET result = checkRoomOccupancy(apNum, floor_, numberOnFloor);
        if result IS NOT NULL THEN
            LEAVE updateStudent;
        END if;

        # 修改入住信息
        UPDATE Students
        SET Ap_number = apNum, Floor_ = floor_, Number_onFloor = numberOnFloor
        WHERE Stu_number = stuNum;
    END if;

    # 修改姓名
    if stuName IS NOT NULL THEN
        UPDATE Students
        SET Stu_name = stuName
        WHERE Stu_number = stuNum;
    END if;
    
    # 修改性别
    if stuGender IS NOT NULL THEN
        UPDATE Students
        SET Stu_gender = stuGender
        WHERE Stu_number = stuNum;
    END if;

    SET result = '成功';
END //
DELIMITER ;


# 学生入住
DROP PROCEDURE if EXISTS checkinStudent;
DELIMITER //
CREATE PROCEDURE checkinStudent(
    IN stuNum char(10),
    IN apNum char(4),
    IN floor_ int,
    IN numberOnFloor int,
    OUT result varchar(100)
)
checkinStudent: BEGIN
    DECLARE is_assigned int;
    DECLARE apNum_ori char(4);
    DECLARE floor_ori int;
    DECLARE numberOnFloor_ori int;
    # 检查主码是否存在
    SELECT COUNT(*) INTO is_assigned FROM Students
    WHERE Stu_number = stuNum;
    if is_assigned = 0 THEN
        SET result = '该学生不存在';
        LEAVE checkinStudent;
    END if;

    # 查询原本入住的房间
    SELECT Ap_number, Floor_, Number_onFloor INTO apNum_ori, floor_ori, numberOnFloor_ori FROM Students
    WHERE Stu_number = stuNum;

    # 若原本有入住房间，则不允许入住新房间
    if apNum_ori IS NOT NULL AND floor_ori IS NOT NULL AND numberOnFloor_ori IS NOT NULL THEN
        SET result = '该学生已经入住其他房间';
        LEAVE checkinStudent;
    END if;

    SET result = checkRoomOccupancy(apNum, floor_, numberOnFloor);
    if result IS NOT NULL THEN
        LEAVE checkinStudent;
    END if;
        
    # 修改入住信息
    UPDATE Students
    SET Ap_number = apNum, Floor_ = floor_, Number_onFloor = numberOnFloor
    WHERE Stu_number = stuNum;

    SET result = '成功';
END //
DELIMITER ;


# 学生退宿
DROP PROCEDURE if EXISTS checkoutStudent;
DELIMITER //
CREATE PROCEDURE checkoutStudent(
    IN stuNum char(10),
    OUT result varchar(100)
)
checkoutStudent: BEGIN
    DECLARE is_assigned int;
    DECLARE apNum_ori char(4);
    DECLARE floor_ori int;
    DECLARE numberOnFloor_ori int;
    # 检查主码是否存在
    SELECT COUNT(*) INTO is_assigned FROM Students
    WHERE Stu_number = stuNum;
    if is_assigned = 0 THEN
        SET result = '该学生不存在';
        LEAVE checkoutStudent;
    END if;

    # 查询原本入住的房间
    SELECT Ap_number, Floor_, Number_onFloor INTO apNum_ori, floor_ori, numberOnFloor_ori FROM Students
    WHERE Stu_number = stuNum;

    # 若原本有入住房间，则减少旧房间入住人数
    if apNum_ori IS NULL AND floor_ori IS NULL AND numberOnFloor_ori IS NULL THEN
        SET result = '该学生并未入住';
        LEAVE checkoutStudent;
    END if;

    # 修改入住信息
    UPDATE Students
    SET Ap_number = NULL, Floor_ = NULL, Number_onFloor = NULL
    WHERE Stu_number = stuNum;

    SET result = '成功';
END //
DELIMITER ;