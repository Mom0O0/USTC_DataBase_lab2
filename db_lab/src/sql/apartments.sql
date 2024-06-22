use lab3;

# 增加公寓
DROP PROCEDURE if EXISTS addApartment;
DELIMITER //
CREATE PROCEDURE addApartment(
    IN apNum char(4),
    IN apName varchar(50),
    IN apFloors int,
    OUT result varchar(100)
)
addApartment: BEGIN
    DECLARE is_assigned int;

    SELECT COUNT(*) INTO is_assigned FROM Apartments
    WHERE Ap_number = apNum;
    if is_assigned > 0 THEN
        SET result = '该公寓已存在';
        LEAVE addApartment;
    END if;

    INSERT INTO Apartments(Ap_number, Ap_name, Ap_floors) VALUES(apNum, apName, apFloors);
    SET result = '成功';
END //
DELIMITER ;


# 删除公寓
# 同时删除报修、访问信息、相关房间并让对应的学生居住的房间信息清除为NULL
DROP PROCEDURE if EXISTS deleteApartment;
DELIMITER //
CREATE PROCEDURE deleteApartment(
    IN apNum char(4),
    OUT result varchar(100)
)
deleteApartment: BEGIN
    DECLARE allow_delete int;

    SELECT COUNT(*) INTO allow_delete FROM Apartments
    WHERE Ap_number = apNum;
    if allow_delete = 0 THEN
        SET result = '不能删除不存在的记录';
        LEAVE deleteApartment;
    END if;

    # 清除报修信息中的相关房间信息
    DELETE FROM As_repair WHERE Ap_number = apNum;

    # 清除访问信息中的相关公寓信息
    DELETE FROM As_visit WHERE Ap_number = apNum;

    # 清除学生居住的房间信息
    UPDATE Students
    SET Ap_number = NULL, Floor_ = NULL, Number_onFloor = NULL
    WHERE Ap_number = apNum;

    # 清除工作人员的管理信息
    UPDATE Workers
    SET Ap_number = NULL
    WHERE Ap_number = apNum;

    # 删除相关房间
    DELETE FROM Rooms WHERE Ap_number = apNum;

    # 删除公寓
    DELETE FROM Apartments WHERE Ap_number = apNum;
    
    SET result = '成功';
END //
DELIMITER ;


# 修改公寓信息（名称、楼层数）
DROP PROCEDURE if EXISTS updateApartment;
DELIMITER //
CREATE PROCEDURE updateApartment(
    IN apNum char(4),
    IN apName varchar(50),
    IN apFloors int,
    OUT result varchar(100)
)
updateApartment: BEGIN
    DECLARE is_assigned int;
    DECLARE max_floor int;

    SELECT COUNT(*) INTO is_assigned FROM Apartments
    WHERE Ap_number = apNum;
    if is_assigned = 0 THEN
        SET result = '该公寓不存在';
        LEAVE updateApartment;
    END if;

    if apName IS NOT NULL THEN
        UPDATE Apartments
        SET Ap_name = apName
        WHERE Ap_number = apNum;
    END if;

    if apFloors IS NOT NULL THEN
        SELECT IFNULL(MAX(Floor_), 1) INTO max_floor FROM Rooms
        WHERE Ap_number = apNum;

        if max_floor > apFloors THEN
            SET result = '新楼层数不能比已有房间的最高楼层小';
            LEAVE updateApartment;
        END if;

        UPDATE Apartments
        SET Ap_floors = apFloors
        WHERE Ap_number = apNum;
    END if;

    SET result = '成功';
END //
DELIMITER ;