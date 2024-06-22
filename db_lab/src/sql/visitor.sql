use lab3;

# 新增访问
# 首次访问新增访问人员，Visit_num设为1；非首次访问Visit_num加1。Visit_status为访问中
# 新访问前必须登记上一次访问离开
# 每次访问可能会同步更新联系方式
DROP PROCEDURE if EXISTS comeVisitor;
DELIMITER //
CREATE PROCEDURE comeVisitor(
    IN visitorIdentity CHAR(18),
    IN visitorName VARCHAR(50),
    IN visitorContact CHAR(11),
    IN apNum char(4),
    IN visitTime datetime,
    OUT result varchar(100)
)
comeVisitor: BEGIN
    DECLARE is_assigned int;
    DECLARE ap_exist int;
    DECLARE visitNum int;
    DECLARE lastvisit int;

    SELECT COUNT(*) INTO ap_exist FROM Apartments
    WHERE Ap_number = apNum;
    if ap_exist = 0 THEN
        SET result = '该公寓不存在';
        LEAVE comeVisitor;
    END if;

    SELECT COUNT(*) INTO is_assigned FROM Visitor
    WHERE Visitor_identity = visitorIdentity;
    if is_assigned = 0 THEN
        # 增加新访客
        INSERT INTO Visitor(Visitor_identity, Visitor_name, Visitor_contact)
        VALUES(visitorIdentity, visitorName, visitorContact);

        INSERT INTO As_visit(Visitor_identity, Visit_num, Ap_number, Visit_time, Visit_status, Leave_time)
        VALUES(visitorIdentity, 1, apNum, visitTime, 0, NULL);
    ELSE
        SELECT IFNULL(MIN(Visit_status), 1) INTO lastvisit FROM As_visit
        WHERE Visitor_identity = visitorIdentity;
        if lastvisit = 0 THEN
            SET result = '上一次访问未登记离开';
            LEAVE comeVisitor;
        END if;

        SELECT IFNULL(MAX(Visit_num), 0) INTO visitNum FROM As_visit
        WHERE Visitor_identity = visitorIdentity AND Ap_number = apNum;

        INSERT INTO As_visit(Visitor_identity, Visit_num, Ap_number, Visit_time, Visit_status, Leave_time)
        VALUES(visitorIdentity, visitNum + 1, apNum, visitTime, 0, NULL);

        if visitorContact IS NOT NULL THEN
            UPDATE Visitor
            SET Visitor_contact = visitorContact
            WHERE Visitor_identity = visitorIdentity;
        END if;

        UPDATE Visitor
        SET Visitor_name = visitorName
        WHERE Visitor_identity = visitorIdentity;
    END if;

    SET result = '成功';
END //
DELIMITER ;


# 删除访问记录
# delete_all为1则删除该访客在该公寓所有访问记录，否则只删除visitNum对应的一条记录
DROP PROCEDURE if EXISTS deleteVisitor;
DELIMITER //
CREATE PROCEDURE deleteVisitor(
    IN visitorIdentity CHAR(18),
    IN visitNum int,
    IN apNum char(4),
    IN delete_all int,
    OUT result varchar(100)
)
deleteVisitor: BEGIN
    DECLARE allow_delete int;
    DECLARE ap_exist int;

    SELECT COUNT(*) INTO allow_delete FROM Visitor
    WHERE visitorIdentity = Visitor_identity;
    if allow_delete = 0 THEN
        SET result = '该访问人员不存在';
        LEAVE deleteVisitor;
    END if;

    SELECT COUNT(*) INTO ap_exist FROM Apartments
    WHERE Ap_number = apNum;
    if ap_exist = 0 THEN
        SET result = '该公寓不存在';
        LEAVE deleteVisitor;
    END if;

    if delete_all = 0 THEN
        SELECT COUNT(*) INTO allow_delete FROM As_visit
        WHERE visitorIdentity = Visitor_identity AND visitNum = Visit_num AND apNum = Ap_number;
        if allow_delete = 0 THEN
            SET result = '该访问记录不存在';
            LEAVE deleteVisitor;
        END if;

        DELETE FROM As_visit
        WHERE visitorIdentity = Visitor_identity AND visitNum = Visit_num AND apNum = Ap_number;

        # 如果删完了所有访客记录，那么访客也删除
        SELECT COUNT(*) INTO allow_delete FROM As_visit
        WHERE visitorIdentity = Visitor_identity;
        if allow_delete = 0 THEN
            DELETE FROM Visitor
            WHERE visitorIdentity = Visitor_identity;
        END if;
    ELSE
        SELECT COUNT(*) INTO allow_delete FROM As_visit
        WHERE visitorIdentity = Visitor_identity AND apNum = Ap_number;
        if allow_delete = 0 THEN
            SET result = '该访问记录不存在';
            LEAVE deleteVisitor;
        END if;

        DELETE FROM As_visit
        WHERE visitorIdentity = Visitor_identity AND apNum = Ap_number;

        # 如果删完了所有访客记录，那么访客也删除
        SELECT COUNT(*) INTO allow_delete FROM As_visit
        WHERE visitorIdentity = Visitor_identity;
        if allow_delete = 0 THEN
            DELETE FROM Visitor
            WHERE visitorIdentity = Visitor_identity;
        END if;
    END if;
    
    SET result = '成功';
END //
DELIMITER ;


# 访客离开修改访问信息
# （访问状态，离开时间。不支持修改姓名和联系方式，这些对软件使用人不可见）
DROP PROCEDURE if EXISTS updateVisitor;
DELIMITER //
CREATE PROCEDURE updateVisitor(
    IN visitorIdentity CHAR(18),
    IN visitNum int,
    IN apNum char(4),
    IN leaveTime datetime,
    OUT result varchar(100)
)
updateVisitor: BEGIN
    DECLARE is_assigned int;
    DECLARE status_ori int;

    SELECT COUNT(*) INTO is_assigned FROM As_visit
    WHERE Visitor_identity = visitorIdentity AND Visit_num = visitNum AND Ap_number = apNum;
    if is_assigned = 0 THEN
        SET result = '该访问记录不存在';
        LEAVE updateVisitor;
    END if;
    
    SELECT Visit_status INTO status_ori FROM As_visit
    WHERE Visitor_identity = visitorIdentity AND Visit_num = visitNum AND Ap_number = apNum;

    if status_ori = 1 THEN
        SET result = '该访问记录已经登记离开';
        LEAVE updateVisitor;
    END if;

    UPDATE As_visit
    SET Visit_status = 1, Leave_time = leaveTime
    WHERE Visitor_identity = visitorIdentity AND Visit_num = visitNum AND Ap_number = apNum;
    
    SET result = '成功';
END //
DELIMITER ;