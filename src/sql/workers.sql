use lab3;

# 增加工作人员
DROP PROCEDURE if EXISTS addWorker;
DELIMITER //
CREATE PROCEDURE addWorker(
    IN workerNum CHAR(10),
    IN apNum CHAR(4),
    IN workerName VARCHAR(50),
    IN workerContact CHAR(11),
    OUT result varchar(100)
)
addWorker: BEGIN
    DECLARE is_assigned int;
    DECLARE ap_exist int;

    START TRANSACTION; # 开始事务
    # 检查workerNum和Apnum是否已经存在
    SELECT COUNT(*) INTO is_assigned FROM Workers
    WHERE Worker_number = workerNum;
    if is_assigned > 0 THEN
        SET result = '该工作人员已存在';
        ROLLBACK; # workerNum已经存在，事务ROLLBACK
        LEAVE addWorker;
    END if;

    if apNum IS NOT NULL THEN
        SELECT COUNT(*) INTO ap_exist FROM Apartments
        WHERE Ap_number = apNum;
        if ap_exist = 0 THEN
            SET result = '该公寓不存在';
            ROLLBACK; # Apnum不存在，事务ROLLBACK
            LEAVE addWorker;
        END if;
    END if;

    INSERT INTO Workers(Worker_number, Ap_number, Worker_name, Worker_contact)
    VALUES(workerNum, apNum, workerName, workerContact);
    COMMIT; # 事务正常，COMMIT
    SET result = '成功';
END //
DELIMITER ;


# 删除工作人员
DROP PROCEDURE if EXISTS deleteWorker;
DELIMITER //
CREATE PROCEDURE deleteWorker(
    IN workerNum CHAR(10),
    OUT result varchar(100)
)
deleteWorker: BEGIN
    DECLARE allow_delete int;

    SELECT COUNT(*) INTO allow_delete FROM Workers
    WHERE Worker_number = workerNum;
    if allow_delete = 0 THEN
        SET result = '该工作人员不存在';
        LEAVE deleteWorker;
    END if;

    # 删除工作人员
    DELETE FROM Workers
    WHERE Worker_number = workerNum;
    
    SET result = '成功';
END //
DELIMITER ;


# 修改工作人员信息（姓名，联系方式，管理公寓）
DROP PROCEDURE if EXISTS updateWorker;
DELIMITER //
CREATE PROCEDURE updateWorker(
    IN workerNum CHAR(10),
    IN newApNum CHAR(4),
    IN newWorkerName VARCHAR(50),
    IN newWorkerContact CHAR(11),
    OUT result varchar(100)
)
updateWorker: BEGIN
    DECLARE is_assigned int;
    DECLARE ap_exist int;

    SELECT COUNT(*) INTO is_assigned FROM Workers
    WHERE Worker_number = workerNum;
    if is_assigned = 0 THEN
        SET result = '该工作人员不存在';
        LEAVE updateWorker;
    END if;

    if newApNum IS NOT NULL THEN
        SELECT COUNT(*) INTO ap_exist FROM Apartments
        WHERE Ap_number = newApNum;
        if ap_exist = 0 THEN
            SET result = '该公寓不存在';
            LEAVE updateWorker;
        END if;
        
        UPDATE Workers
        SET Ap_number = newApNum
        WHERE Worker_number = workerNum;
    END if;

    if newWorkerName IS NOT NULL THEN
        UPDATE Workers
        SET Worker_name = newWorkerName
        WHERE Worker_number = workerNum;
    END if;

    if newWorkerContact IS NOT NULL THEN
        UPDATE Workers
        SET Worker_contact = newWorkerContact
        WHERE Worker_number = workerNum;
    END if;

    SET result = '成功';
END //
DELIMITER ;


# 分配管理公寓楼
DROP PROCEDURE if EXISTS assignWorker;
DELIMITER //
CREATE PROCEDURE assignWorker(
    IN workerNum CHAR(10),
    IN newApNum CHAR(4),
    OUT result varchar(100)
)
assignWorker: BEGIN
    DECLARE is_assigned int;
    DECLARE ap_exist int;

    SELECT COUNT(*) INTO is_assigned FROM Workers
    WHERE Worker_number = workerNum;
    if is_assigned = 0 THEN
        SET result = '该工作人员不存在';
        LEAVE assignWorker;
    END if;

    SELECT COUNT(*) INTO ap_exist FROM Apartments
    WHERE Ap_number = newApNum;
    if ap_exist = 0 THEN
        SET result = '该公寓不存在';
        LEAVE assignWorker;
    END if;

    UPDATE Workers
    SET Ap_number = newApNum
    WHERE Worker_number = workerNum;
    
    SET result = '成功';
END //
DELIMITER ;