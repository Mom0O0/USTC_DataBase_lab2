use lab3;

# 增加房间
DROP PROCEDURE if EXISTS addRoom;
DELIMITER //
CREATE PROCEDURE addRoom(
    IN apNum CHAR(4),
    IN floor_ INT,
    IN numberOnFloor INT,
    IN capacity INT,
    IN roomImg varchar(50),
    OUT result varchar(100)
)
addRoom: BEGIN
    DECLARE is_assigned int;
    DECLARE ap_exist int;
    DECLARE max_floor int;

    SELECT COUNT(*) INTO is_assigned FROM Rooms
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
    if is_assigned > 0 THEN
        SET result = '该房间已存在';
        LEAVE addRoom;
    END if;

    SELECT COUNT(*) INTO ap_exist FROM Apartments
    WHERE Ap_number = apNum;
    if ap_exist = 0 THEN
        SET result = '该公寓不存在';
        LEAVE addRoom;
    END if;

    SELECT Ap_floors INTO max_floor FROM Apartments
    WHERE Ap_number = apNum;
    if max_floor < floor_ THEN
        SET result = '房间楼层不能比公寓最高层数大';
        LEAVE addRoom;
    END if;

    INSERT INTO Rooms(Ap_number, Floor_, Number_onFloor, Capacity, NumOfStuNow, room_img)
    VALUES(apNum, floor_, numberOnFloor, capacity, 0, roomImg);
    SET result = '成功';
END //
DELIMITER ;


# 删除房间
# 同时删除报修信息并让对应的学生居住的房间信息清除为NULL
DROP PROCEDURE if EXISTS deleteRoom;
DELIMITER //
CREATE PROCEDURE deleteRoom(
    IN apNum char(4),
    IN floor_ INT,
    IN numberOnFloor INT,
    OUT result varchar(100)
)
deleteRoom: BEGIN
    DECLARE allow_delete int;

    SELECT COUNT(*) INTO allow_delete FROM Rooms
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
    if allow_delete = 0 THEN
        SET result = '该房间不存在';
        LEAVE deleteRoom;
    END if;

    # 清除报修信息中的相关房间信息
    DELETE FROM As_repair
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;

    # 清除学生居住的房间信息
    UPDATE Students
    SET Ap_number = NULL, Floor_ = NULL, Number_onFloor = NULL
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;

    # 删除相关房间
    DELETE FROM Rooms
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
    
    SET result = '成功';
END //
DELIMITER ;


# 修改房间信息（容量，图片，其他信息为主码不可修改或由学生入住退宿过程维护）
DROP PROCEDURE if EXISTS updateRoom;
DELIMITER //
CREATE PROCEDURE updateRoom(
    IN apNum char(4),
    IN floor_ INT,
    IN numberOnFloor INT,
    IN capacity INT,
    IN roomImg varchar(50),
    OUT result varchar(100)
)
updateRoom: BEGIN
    DECLARE is_assigned int;
    DECLARE numOfStu int;

    SELECT COUNT(*) INTO is_assigned FROM Rooms
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
    if is_assigned = 0 THEN
        SET result = '该房间不存在';
        LEAVE updateRoom;
    END if;

    SELECT NumOfStuNow INTO numOfStu FROM Rooms
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
    if capacity < numOfStu THEN
        SET result = '房间容量不能比已住人数小';
        LEAVE updateRoom;
    END if;

    if capacity IS NOT NULL THEN
        UPDATE Rooms
        SET Capacity = capacity
        WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
    END if;

    if roomImg IS NOT NULL THEN
        UPDATE Rooms
        SET room_img = roomImg
        WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
    END if;

    SET result = '成功';
END //
DELIMITER ;