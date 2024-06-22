use lab3;


DROP PROCEDURE if EXISTS getApartmentDetails;
DELIMITER //
CREATE PROCEDURE getApartmentDetails(
    IN apNum CHAR(4)
)
BEGIN
    SELECT Ap_name, Ap_floors
    FROM Apartments
    WHERE Ap_number = apNum;
END //
DELIMITER ;


DROP PROCEDURE if EXISTS getRoomsByApartment;
DELIMITER //
CREATE PROCEDURE getRoomsByApartment(
    IN apNum CHAR(4)
)
BEGIN
    SELECT Floor_, Number_onFloor, Capacity, NumOfStuNow, room_img
    FROM Rooms
    WHERE Ap_number = apNum;
END //
DELIMITER ;


DROP PROCEDURE if EXISTS getRoomDetails;
DELIMITER //
CREATE PROCEDURE getRoomDetails(
    IN apNum CHAR(4),
    IN floor_ INT,
    IN numberOnFloor INT
)
BEGIN
    SELECT Stu_number, Stu_name, CASE WHEN Stu_gender = 0 THEN '男' ELSE '女' END AS Stu_gender
    FROM Students
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
END //
DELIMITER ;


DROP PROCEDURE if EXISTS getRoomCapacity;
DELIMITER //
CREATE PROCEDURE getRoomCapacity(
    IN apNum CHAR(4),
    IN floor_ INT,
    IN numberOnFloor INT
)
BEGIN
    SELECT Capacity, NumOfStuNow, room_img
    FROM Rooms
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
END //
DELIMITER ;

# 查询学生详细信息
DROP PROCEDURE if EXISTS getStudentDetails;
DELIMITER //
CREATE PROCEDURE getStudentDetails(
    IN stuNum CHAR(10)
)
BEGIN
    SELECT Ap_number, Floor_, Number_onFloor, Stu_name, CASE WHEN Stu_gender = 0 THEN '男' ELSE '女' END AS Stu_gender
    FROM Students
    WHERE Stu_number = stuNum;
END //
DELIMITER ;


DROP PROCEDURE if EXISTS getRepairInfo;
DELIMITER //
CREATE PROCEDURE getRepairInfo(
    IN apNum CHAR(4),
    IN floor_ INT,
    IN numberOnFloor INT
)
BEGIN
    SELECT Stu_number, Repair_id, details, CASE WHEN Repair_status = 0 THEN '待处理' ELSE '已处理' END AS Repair_status
    FROM As_repair
    WHERE Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor;
END //
DELIMITER ;


DROP PROCEDURE if EXISTS getRepairDetails;
DELIMITER //
CREATE PROCEDURE getRepairDetails(
    IN repairID INT,
    IN apNum CHAR(4),
    IN floor_ INT,
    IN numberOnFloor INT,
    IN stuNum CHAR(10)
)
BEGIN
    SELECT details, CASE WHEN Repair_status = 0 THEN '待处理' ELSE '已处理' END AS Repair_status
    FROM As_repair
    WHERE Repair_id = repairID AND Ap_number = apNum AND Floor_ = floor_ AND Number_onFloor = numberOnFloor AND Stu_number = stuNum;
END //
DELIMITER ;


DROP PROCEDURE if EXISTS getWorkersByApartment;
DELIMITER //
CREATE PROCEDURE getWorkersByApartment(
    IN apNum CHAR(4)
)
BEGIN
    SELECT Worker_number, Worker_name, Worker_contact
    FROM Workers
    WHERE Ap_number = apNum;
END //
DELIMITER ;


DROP PROCEDURE if EXISTS getWorkerDetails;
DELIMITER //
CREATE PROCEDURE getWorkerDetails(
    IN workerNum CHAR(10)
)
BEGIN
    SELECT Ap_number, Worker_name, Worker_contact
    FROM Workers
    WHERE Worker_number = workerNum;
END //
DELIMITER ;


DROP PROCEDURE if EXISTS getVisitorsByApartment;
DELIMITER //
CREATE PROCEDURE getVisitorsByApartment(
    IN apNum CHAR(4)
)
BEGIN
    SELECT Visitor_identity, Visit_time, Leave_time, CASE WHEN Visit_status = 0 THEN '访问中' ELSE '已离开' END AS Visit_status
    FROM As_visit
    WHERE Ap_number = apNum;
END //
DELIMITER ;


DROP PROCEDURE if EXISTS getVisitorDetails;
DELIMITER //
CREATE PROCEDURE getVisitorDetails(
    IN visitorIdentity CHAR(18),
    IN visitNum INT,
    IN apNum CHAR(4)
)
BEGIN
    SELECT Visit_time, Leave_time, CASE WHEN Visit_status = 0 THEN '访问中' ELSE '已离开' END AS Visit_status
    FROM As_visit
    WHERE Visitor_identity = visitorIdentity AND Visit_num = visitNum AND Ap_number = apNum;
END //
DELIMITER ;