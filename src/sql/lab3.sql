drop database if exists lab3;
create database if not exists lab3;

use lab3;

drop table if exists Apartments;
drop table if exists As_repair;
drop table if exists As_visit;
drop table if exists Rooms;
drop table if exists Students;
drop table if exists Visitor;
drop table if exists Workers;


# 公寓
create table Apartments
(
    Ap_number           char(4) not null,
    Ap_name             varchar(50) not null,
    Ap_floors           int not null check(Ap_floors > 0),
    constraint primary key(Ap_number)
);

# 房间
# Capacity: 总可容纳人数，固定数值
# NumOfStuNow: 已住人数
create table Rooms
(
    Ap_number            char(4) not null,
    Floor_               int not null check(Floor_ > 0),
    Number_onFloor       int not null check(Number_onFloor > 0),
    Capacity             int not null check(Capacity > 0),
    NumOfStuNow          int not null check(NumOfStuNow >= 0),
    room_img             varchar(50),
    constraint primary key(Ap_number, Floor_, Number_onFloor),
    constraint foreign key(Ap_number) references Apartments(Ap_number)
);

# 学生
# Stu_gender: 0-男，1-女
create table Students
(
    Stu_number           char(10) not null,
    Ap_number            char(4),
    Floor_               int,
    Number_onFloor       int,
    Stu_name             varchar(50) not null,
    Stu_gender           int not null check(Stu_gender in(0, 1)),
    constraint primary key(Stu_number),
    constraint foreign key(Ap_number, Floor_, Number_onFloor) references Rooms(Ap_number, Floor_, Number_onFloor)
);

# 访客
create table Visitor
(
    Visitor_identity     char(18) not null,
    Visitor_name         varchar(50) not null,
    Visitor_contact      char(11),
    constraint primary key(Visitor_identity)
);

# 工作人员
create table Workers
(
    Worker_number        char(10) not null,
    Ap_number            char(4),
    Worker_name          varchar(50) not null,
    Worker_contact       char(11),
    constraint primary key(Worker_number),
    constraint foreign key(Ap_number) references Apartments(Ap_number)
);

# 公寓报修
# 一个人可以多次报修同一间房间
# Repair_id初始化为1，报修一次加一
# Repair_status: 0-待处理，1-已处理
create table As_repair
(
    Repair_id           int not null,
    Ap_number           char(4) not null,
    Floor_              int not null check(Floor_ > 0),
    Number_onFloor      int not null check(Number_onFloor > 0),
    Stu_number          char(10) not null,
    details             varchar(100),
    Repair_status       int not null check(Repair_status in(0, 1)),
    constraint primary key(Repair_id, Ap_number, Floor_, Number_onFloor, Stu_number),
    constraint foreign key(Ap_number, Floor_, Number_onFloor) references Rooms(Ap_number, Floor_, Number_onFloor),
    constraint foreign key(Stu_number) references Students(Stu_number)
);

# 访问
# 一个人可以多次访问公寓
# Visit_num初始化为1，访问一次加一
# Visit_status: 0-访问中，1-访问结束已离开
# 新一次访问前需要维护leave_time（？）
create table As_visit
(
    Visitor_identity     char(18) not null,
    Visit_num            int not null,
    Ap_number            char(4) not null,
    Visit_time           datetime not null,
    Visit_status         int not null check(Visit_status in(0, 1)),
    Leave_time           datetime,
    constraint primary key(Visitor_identity, Visit_num, Ap_number),
    constraint foreign key(Visitor_identity) references Visitor(Visitor_identity),
    constraint foreign key(Ap_number) references Apartments(Ap_number)
);