use lab3;

-- 插入数据到 Apartments 表
INSERT INTO Apartments (Ap_number, Ap_name, Ap_floors) VALUES
('A001', 'Sunshine Apartment', 5),
('A002', 'Moonlight Apartment', 2),
('A003', 'Starlight Apartment', 3);

-- 插入数据到 Rooms 表
INSERT INTO Rooms (Ap_number, Floor_, Number_onFloor, Capacity, NumOfStuNow, room_img) VALUES
('A001', 1, 101, 4, 3, NULL),
('A001', 1, 102, 4, 2, NULL),
('A001', 2, 201, 2, 2, NULL),
('A002', 1, 101, 3, 1, NULL),
('A002', 1, 102, 2, 2, NULL),
('A003', 2, 201, 3, 1, NULL),
('A003', 3, 301, 3, 1, NULL);

-- 插入数据到 Students 表
INSERT INTO Students (Stu_number, Ap_number, Floor_, Number_onFloor, Stu_name, Stu_gender) VALUES
('S000000001', 'A001', 1, 101, 'David', 0),
('S000000002', 'A001', 1, 101, 'Bob', 0),
('S000000003', 'A001', 1, 101, 'Charlie', 0),
('S000000004', 'A001', 1, 102, 'Alice', 1),
('S000000005', 'A001', 1, 102, 'Eve', 1),
('S000000006', 'A001', 2, 201, 'Faythe', 1),
('S000000007', 'A001', 2, 201, 'Grace', 1),
('S000000008', 'A002', 1, 101, 'Heidi', 1),
('S000000009', 'A002', 1, 102, 'Ivan', 0),
('S000000010', 'A002', 1, 102, 'Mallory', 0),
('S000000011', 'A003', 2, 201, 'Judy', 1),
('S000000012', 'A003', 3, 301, 'Oscar', 0),
('S000000013', NULL, NULL, NULL, 'Nina', 1),
('S000000014', NULL, NULL, NULL, 'Oliver', 0),
('S000000015', NULL, NULL, NULL, 'Peter', 0),
('S000000016', NULL, NULL, NULL, 'Quinn', 1),
('S000000017', NULL, NULL, NULL, 'Rachel', 1),
('S000000018', NULL, NULL, NULL, 'Steve', 0),
('S000000019', NULL, NULL, NULL, 'Tina', 1),
('S000000020', NULL, NULL, NULL, 'Uma', 1);

-- 插入数据到 Visitor 表
#INSERT INTO Visitor (Visitor_identity, Visitor_name, Visitor_contact) VALUES
#('111', 'Victor', '11111111111'),
#('222', 'Wendy', '22222222222'),
#('333', 'Xander', '33333333333');

-- 插入数据到 Workers 表
INSERT INTO Workers (Worker_number, Ap_number, Worker_name, Worker_contact) VALUES
('W000000001', 'A001', 'Tom', '11111111111'),
('W000000002', 'A001', 'Jerry', '22222222222'),
('W000000003', 'A002', 'Spike', '33333333333'),
('W000000004', 'A002', 'Tyke', '44444444444'),
('W000000005', 'A003', 'Butch', '55555555555');
