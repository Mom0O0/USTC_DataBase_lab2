use lab3;

set global log_bin_trust_function_creators=1;

DROP FUNCTION if EXISTS checkExistance;
DELIMITER //
CREATE FUNCTION checkExistance(
    apNum char(4),
    floor_ int,
    numberOnFloor int,
    stuNum char(10)
)
RETURNS VARCHAR(100)
BEGIN
    DECLARE room_exist int;
    DECLARE stu_exist int;

    SELECT COUNT(*) INTO room_exist FROM Rooms
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
    if room_exist = 0 THEN
        RETURN '该房间不存在';
    END if;
    
    SELECT COUNT(*) INTO stu_exist FROM Students
    WHERE Stu_number = stuNum;
    if stu_exist = 0 THEN
        RETURN '该学生不存在';
    END if;
    
    RETURN NULL;
END //
DELIMITER ;


# 新增报修
DROP PROCEDURE if EXISTS addRepair;
DELIMITER //
CREATE PROCEDURE addRepair(
    IN apNum char(4),
    IN floor_ int,
    IN numberOnFloor int,
    IN stuNum char(10),
    IN details_ varchar(100),
    OUT result varchar(100)
)
addRepair: BEGIN
    DECLARE repairNum int;

    SET result = checkExistance(apNum, floor_, numberOnFloor, stuNum);        
    if result IS NOT NULL THEN
        LEAVE addRepair;
    END if;
    
    SELECT IFNULL(MAX(Repair_id), 0) INTO repairNum FROM As_repair
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor AND Stu_number = stuNum;

    INSERT INTO As_repair(Repair_id, Ap_number, Floor_, Number_onFloor, Stu_number, details, Repair_status)
    VALUES(repairNum + 1, apNum, floor_, numberOnFloor, stuNum, details_, 0);

    SET result = '成功';
END //
DELIMITER ;


# 删除报修记录
DROP PROCEDURE if EXISTS deleteRepair;
DELIMITER //
CREATE PROCEDURE deleteRepair(
    IN repairID int,
    IN apNum char(4),
    IN floor_ int,
    IN numberOnFloor int,
    IN stuNum char(10),
    OUT result varchar(100)
)
deleteRepair: BEGIN
    DECLARE is_assigned int;

    SET result = checkExistance(apNum, floor_, numberOnFloor, stuNum);        
    if result IS NOT NULL THEN
        LEAVE deleteRepair;
    END if;

    SELECT COUNT(*) INTO is_assigned FROM As_repair
    WHERE Repair_id = repairID AND Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor AND Stu_number = stuNum;
    if is_assigned = 0 THEN
        SET result = '该报修记录不存在';
        LEAVE deleteRepair;
    END if;

    DELETE FROM As_repair
    WHERE Repair_id = repairID AND Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor AND Stu_number = stuNum;
    
    SET result = '成功';
END //
DELIMITER ;


# 维修结束修改报修信息（报修状态，详情）
# finish: 0-未维修完成只修改详情，1-维修完成
DROP PROCEDURE if EXISTS updateRepair;
DELIMITER //
CREATE PROCEDURE updateRepair(
    IN repairID int,
    IN apNum char(4),
    IN floor_ int,
    IN numberOnFloor int,
    IN stuNum char(10),
    IN details_ varchar(100),
    IN finish int,
    OUT result varchar(100)
)
updateRepair: BEGIN
    DECLARE is_assigned int;

    SET result = checkExistance(apNum, floor_, numberOnFloor, stuNum);        
    if result IS NOT NULL THEN
        LEAVE updateRepair;
    END if;

    SELECT COUNT(*) INTO is_assigned FROM As_repair
    WHERE Repair_id = repairID AND Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor AND Stu_number = stuNum;
    if is_assigned = 0 THEN
        SET result = '该报修记录不存在';
        LEAVE updateRepair;
    END if;

    UPDATE As_repair
    SET details = details_, Repair_status = finish
    WHERE Repair_id = repairID AND Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor AND Stu_number = stuNum;

    SET result = '成功';
END //
DELIMITER ;