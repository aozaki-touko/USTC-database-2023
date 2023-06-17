create table if not exists account
(
    account_id  varchar(18)               not null
        primary key,
    type        int   default 0           not null comment '0是储蓄账户,1是支票账户',
    balance     float default 0           not null,
    create_date date  default (curdate()) not null,
    constraint check_balance_valid
        check (`balance` >= 0)
);

create table if not exists bank
(
    bank_name varchar(20) not null comment '银行名'
        primary key,
    city      varchar(10) null
);

create table if not exists check_account
(
    account_id varchar(18)     not null
        primary key,
    overdraft  float default 0 null,
    constraint check_account_account_account_id_fk
        foreign key (account_id) references account (account_id)
            on update cascade on delete cascade
);

create table if not exists client
(
    client_id   varchar(18) not null
        primary key,
    client_name varchar(5)  null,
    telephone   varchar(11) null,
    address     varchar(20) null,
    photo       varchar(30) null
);

create table if not exists contact
(
    connect_id   varchar(18) not null comment '关联的客户id',
    name         varchar(10) not null,
    telephone    varchar(11) not null,
    relationship varchar(8)  null comment '和关联客户的关系',
    primary key (connect_id, name, telephone),
    constraint contact_client__fk
        foreign key (connect_id) references client (client_id)
            on update cascade on delete cascade
);

create table if not exists department
(
    bank_name     varchar(20) not null,
    name          varchar(10) null comment '部门名',
    type          varchar(4)  null comment '部门类型',
    department_id int         not null comment '部门号',
    primary key (bank_name, department_id),
    constraint department_pk
        unique (department_id),
    constraint department_bank__fk
        foreign key (bank_name) references bank (bank_name)
            on update cascade on delete cascade
);

create table if not exists employee
(
    employee_id     varchar(18)              not null
        primary key,
    name            varchar(15)              null,
    bank_name       varchar(20)              null,
    department      int                      null,
    telephone       varchar(11)              null,
    address         varchar(20)              null,
    photo           varchar(20)              null,
    employ_date     date default (curdate()) null,
    department_name varchar(20)              null,
    constraint employee_bank__fk
        foreign key (bank_name) references bank (bank_name)
            on update cascade on delete cascade,
    constraint employee_department__fk
        foreign key (department) references department (department_id)
            on update cascade on delete cascade
);

create table if not exists connection
(
    employee_id varchar(18) not null,
    client_id   varchar(18) not null,
    service     int         null comment '服务类型',
    primary key (employee_id, client_id),
    constraint connection_client_client_id_fk
        foreign key (client_id) references client (client_id)
            on update cascade on delete cascade,
    constraint connection_employee__fk
        foreign key (employee_id) references employee (employee_id)
            on update cascade on delete cascade
)
    comment '员工对客户的负责表';

create table if not exists loan
(
    bank_name   varchar(20)     not null comment '发放贷款的银行',
    loan_id     varchar(18)     not null
        primary key,
    amount      float default 0 null comment '贷款金额',
    paid_amount float default 0 null comment '已经偿还的金额',
    status      int   default 0 null comment '0代表未偿还完毕，1代表已经还完',
    constraint loan_bank__fk
        foreign key (bank_name) references bank (bank_name)
            on update cascade on delete cascade,
    constraint check_amount
        check (`amount` >= 0)
);

create table if not exists manager_table
(
    bank_name     varchar(20) not null,
    department_id int         not null,
    manager_id    varchar(18) not null,
    primary key (department_id, bank_name, manager_id),
    constraint manager_table_department__fk
        foreign key (bank_name) references bank (bank_name)
            on update cascade on delete cascade,
    constraint manager_table_department__fk2
        foreign key (department_id) references department (department_id)
            on update cascade on delete cascade,
    constraint manager_table_employee__fk
        foreign key (manager_id) references employee (employee_id)
            on update cascade on delete cascade
);

create table if not exists own_account
(
    account_id varchar(18) not null,
    client_id  varchar(18) not null,
    primary key (account_id, client_id),
    constraint own_account_account__fk
        foreign key (account_id) references account (account_id)
            on update cascade on delete cascade,
    constraint own_account_client__fk
        foreign key (client_id) references client (client_id)
            on update cascade on delete cascade
);

create table if not exists own_loan
(
    client_id varchar(18) not null,
    loan_id   varchar(18) not null,
    primary key (loan_id, client_id),
    constraint own_loan_client_client_id_fk
        foreign key (client_id) references client (client_id)
            on update cascade on delete cascade,
    constraint own_loan_loan__fk
        foreign key (loan_id) references loan (loan_id)
            on update cascade on delete cascade
);

create table if not exists pay_loan
(
    bank_name varchar(20) not null,
    loan_id   varchar(18) not null,
    pay_id    varchar(18) not null,
    amount    float       null,
    pay_date  date        null,
    pay_c_id  varchar(18) null,
    primary key (loan_id, pay_id),
    constraint pay_loan_pk
        unique (pay_id),
    constraint pay_loan_bank__fk
        foreign key (bank_name) references bank (bank_name)
            on update cascade on delete cascade,
    constraint pay_loan_client__fk
        foreign key (pay_c_id) references client (client_id)
            on update cascade on delete cascade,
    constraint pay_loan_loan__fk
        foreign key (loan_id) references loan (loan_id)
            on update cascade on delete cascade
);

create trigger autoSetLoan
    after insert
    on pay_loan
    for each row
BEGIN
    DECLARE loanAmount,loanPaid Float DEFAULT 0;
    DECLARE amountOverLimit FLOAT DEFAULT 0;
    DECLARE ac_id varchar(18);
    SELECT loan.amount FROM loan WHERE loan.loan_id = NEW.loan_id INTO loanAmount;
    SELECT loan.paid_amount FROM loan WHERE loan.loan_id = NEW.loan_id INTO loanPaid;
    SELECT account.account_id FROM account,own_account,own_loan WHERE NEW.pay_c_id = own_account.client_id AND own_account.account_id = account.account_id AND account.type = 1 LIMIT 1 INTO ac_id;
    --
    SET amountOverLimit = loanPaid + NEW.amount - loanAmount;
    IF amountOverLimit >= 0 THEN
        -- 可以完全支付剩下的钱
        -- 把贷款状态设为1
        UPDATE loan SET loan.status = 1,loan.paid_amount = loanAmount WHERE loan_id = NEW.loan_id;
        UPDATE account SET account.balance = account.balance + amountOverLimit WHERE account_id = ac_id;
    ELSE
        BEGIN
            -- 仅仅修改已经支付的钱
            UPDATE loan SET loan.paid_amount = loan.paid_amount + NEW.amount WHERE loan_id = NEW.loan_id;
        end;
    end if;

end;

create table if not exists saving_account
(
    account_id    varchar(18) not null
        primary key,
    interest_rate float       null,
    constraint saving_account_account__fk
        foreign key (account_id) references account (account_id)
            on update cascade on delete cascade
);

create table if not exists usertable
(
    username varchar(8)  not null
        primary key,
    password varchar(10) null
);

create procedure apply_loan(IN b_name varchar(30), IN l_id varchar(18), IN l_amount float, IN c_id varchar(18),
                            OUT state int)
BEGIN
    DECLARE s INT default 0;
    DECLARE b_num INT DEFAULT 0;
    DECLARE flag BOOLEAN DEFAULT false;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 4;
    START TRANSACTION ;
    SELECT check_loan_valid(c_id,l_amount) INTO flag;
    IF flag = false OR l_amount <= 0 THEN
        -- 超额的申请额,和负数的申请额都不允许
        set s = 1;
    end if;
    SELECT COUNT(*) FROM bank.bank WHERE bank_name = b_name INTO b_num;
    IF b_num = 0 THEN
        set s = 2;
        -- 不存在此支行
    end if;
    INSERT INTO loan(bank_name, loan_id, amount, paid_amount, status) VALUE (b_name,l_id,l_amount,0,0);
    INSERT INTO own_loan(client_id, loan_id) VALUE (c_id,l_id);
    set state = s;
    IF s = 0 THEN
        commit ;
    ELSE
        BEGIN
            ROLLBACK;
        end;
    end if;
end;

create function check_loan_valid(c_id varchar(18), money_apply float) returns tinyint(1)
    reads sql data
BEGIN
    -- 检查贷款是否合理
    -- 遍历数据库中该用户的所有未偿还完毕的贷款，如果小于贷款限额，则允许贷款
    DECLARE s INT default 0;
    DECLARE maxMoney,curMoney,curLoanAmount,curLoanPaid FLOAT default 0;
    DECLARE cnt INT DEFAULT 0;
    DECLARE ct CURSOR FOR (SELECT loan.amount AS total,loan.paid_amount AS paid FROM loan,own_loan WHERE own_loan.client_id = c_id AND own_loan.loan_id = loan.loan_id AND loan.status = 0);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET s = 1;
    -- 不存在这样的账户就返回FALSE
    select COUNT(*) FROM own_account,account WHERE c_id = own_account.client_id AND own_account.account_id = account.account_id AND account.type = 1 INTO cnt;
    IF not cnt = 1 THEN
        RETURN FALSE;
    end if;
    -- 找到用户的支票账户透支额
    select check_account.overdraft FROM own_account,check_account WHERE own_account.client_id = c_id AND own_account.account_id = check_account.account_id INTO maxMoney;
    -- 找到用户所有的未偿还的贷款，计算总的欠款
    open ct;
    CALC :LOOP
        FETCH ct INTO curLoanAmount,curLoanPaid;
        if s = 1 THEN
            LEAVE CALC;
        end if;
        SET curMoney = curMoney + curLoanAmount - curLoanPaid;
    END LOOP CALC;

    SET curMoney = curMoney + money_apply;
    if curMoney<=maxMoney THEN
        return true;
    end if;
    return false;
end;

create procedure create_account(IN a_id varchar(18), IN T int, IN c_date date, IN c_id varchar(18), OUT state int,
                                OUT msg varchar(30))
begin
    declare s INT default 0;
    declare sameCheck INT default 0;
    DECLARE cl_count INT default 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    -- 创建账户
    start transaction ;
    select count(*) FROM bank.client WHERE c_id = client_id INTO cl_count; -- 检测是否存在账户
    -- 先选出client 相同的account号

    select count(*) FROM bank.account,(select account_id AS oa_id FROM own_account WHERE c_id = client_id) AS x WHERE x.oa_id = account.account_id AND bank.account.type = T INTO sameCheck;
    if cl_count = 0 THEN
        set s = 2; -- 客户不存在
    end if;
    if not T = 0 and not T = 1 THEN
        set s = 3; -- 账户类型错误
    end if;
    IF sameCheck > 0 THEN
        set s = 4; -- 账户类型重复
    end if;
    INSERT INTO bank.account(account_id, type, balance, create_date) VALUE (a_id,T,0,c_date);
    INSERT INTO bank.own_account(account_id, client_id) VALUE (a_id,c_id);
    IF T = 0 THEN
        INSERT INTO bank.saving_account(account_id, interest_rate) VALUE (a_id,0.01);
    ELSE
        INSERT INTO bank.check_account(account_id, overdraft) VALUE (a_id,0);
    end if;
    IF s = 0 THEN
        set state = s;
        set msg = 'success';
        commit ;
    ELSE
        set state = s;
        case s
            when 1 then set msg = '账户已存在或客户不存在';
            when 2 then set msg = '客户不存在';
            when 3 then set msg = '不合法的账户类型';
            when 4 then set msg = '相同的账户类型';
        end case ;
        rollback ;
    end if;
end;

create procedure create_bank(IN b_name varchar(20), IN b_city varchar(10), OUT state int)
begin
    declare s INT default 0;
    declare CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    start transaction ;
    insert into bank(bank_name, city) VALUE (b_name,b_city);
    if s = 0 THEN
        set state = 0;
        commit ;
    ELSE
        set state  = s;
        rollback ;
    end if;
end;

create procedure create_client(IN c_id varchar(18), IN c_name varchar(5), IN c_tel varchar(11), IN c_addr varchar(20),
                               IN c_photo varchar(30), OUT state int)
BEGIN
    DECLARE s INT DEFAULT  0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    START TRANSACTION ;
    INSERT INTO client(client_id, client_name, telephone, address, photo) VALUE (c_id, c_name, c_tel, c_addr, c_photo);
    set state = s;
    IF s = 0 THEN
        commit ;
    ELSE
        rollback ;
    end if;
end;

create procedure create_contact(IN c_id varchar(18), IN c_name varchar(10), IN c_tel varchar(11), IN rel varchar(8),
                                OUT state int)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    INSERT INTO contact(connect_id, name, telephone, relationship) VALUE (c_id, c_name, c_tel, rel);
    set state = s;
    IF s = 0 THEN
        BEGIN
            commit ;
        end;
    ELSE
        BEGIN
            rollback ;
        end;
    end if;
end;

create procedure create_department(IN b_name varchar(20), IN d_name varchar(10), IN d_type varchar(4), IN d_id int,
                                   OUT state int)
begin
    DECLARE s INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    START TRANSACTION ;
    INSERT INTO bank.department(bank_name, name, type, department_id) VALUE (b_name,d_name,d_type,d_id);
    IF s = 0 THEN
        set state = s;
        commit ;
    ELSE
        begin
            set state = s;
            rollback ;
        end;
    end if;
end;

create procedure create_employee(IN e_id varchar(18), IN b_name varchar(20), IN d_id int, IN e_name varchar(10),
                                 IN e_tele varchar(11), IN e_addr varchar(20), IN e_photo varchar(20), IN e_date date,
                                 IN d_name varchar(20), OUT state int)
begin
    DECLARE s INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1; -- 处理外键约束或者重复主键
    START TRANSACTION ;
    INSERT INTO employee(employee_id, name, bank_name, department, telephone, address, photo, employ_date, department_name)
        VALUE (e_id,e_name, b_name, d_id,  e_tele, e_addr, e_photo, e_date,d_name);
    set state = s;
    IF s = 0 THEN
    BEGIN
        commit ;
    end;
    ELSE
        BEGIN
            rollback ;
        end;
    end if;
end;

create procedure create_user(IN usrname varchar(8), IN passwd varchar(10), OUT res int)
begin
    DECLARE s INT default 0; -- 状态码，0正常创建
    DECLARE a INT default 0;
    start transaction ;
    select count(*) FROM  bank.usertable where username = usrname into a;
    if a > 0 then
        begin
            set res = 1;
            rollback ;
        end;
    else
        begin
            INSERT into bank.usertable(username, password) VALUE (usrname,passwd);
            set res = 0;
            commit ;
        end;
    end if;
end;

create procedure pay_loan(IN b_name varchar(20), IN l_id varchar(18), IN p_id varchar(18), IN l_amount float,
                          IN p_date date, IN c_id varchar(18), OUT state int)
BEGIN
    DECLARE s,cnt INT DEFAULT 0;
    DECLARE st BOOLEAN DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    START TRANSACTION ;
    IF l_amount <= 0 THEN
        set s = 2; -- invalid pay amount
    end if;
    SELECT COUNT(*) FROM loan WHERE loan_id = l_id AND status = 0 INTO cnt;
    IF cnt != 1 THEN
        set s = 3; -- loan id error
    end if;
    IF s = 0 THEN
    INSERT INTO pay_loan(bank_name, loan_id, pay_id, amount, pay_date, pay_c_id) VALUE
        (b_name,l_id,p_id,l_amount,p_date,c_id);
    end if;
    SET state = s;
    IF s = 0 THEN
        commit ;
    ELSE

        rollback ;
    end if;



end;

create procedure set_manager(IN b_name varchar(20), IN d_id int, IN e_id varchar(18), OUT state int)
begin
    DECLARE s INT DEFAULT 0;
    DECLARE d_count INT DEFAULT 0; -- 检测是否有重复部门
    DECLARE e_count INT DEFAULT 0; -- 检测是否出现重复经理
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    start transaction ;
    SELECT count(*) FROM manager_table WHERE bank_name = b_name and department_id = d_id INTO d_count;
    SELECT count(*) FROM manager_table WHERE manager_id = e_id INTO e_count;
    INSERT INTO manager_table(bank_name, department_id, manager_id) VALUE (b_name, d_id, e_id);
    IF d_count > 0 THEN
        set s = 2;
    end if;
    IF e_count > 0 THEN
        set s = 3;
    end if;
    set state = s;
    IF s = 0 THEN
        commit ;
    ELSE
        begin

        end;
        rollback ;
    end if;
end;

create procedure transfer(IN from_a_id varchar(18), IN to_a_id varchar(18), IN t_amount float, OUT state int)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE from_exist,to_exist INT DEFAULT 0;
    DECLARE from_amount INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set state = 1,s=1;
    START TRANSACTION ;
    IF t_amount <= 0 THEN
        set state = 2,s=2; -- 不合法的转账
    end if;
    SELECT balance FROM account WHERE account_id = from_a_id INTO from_amount;
    SELECT COUNT(*) FROM account WHERE account_id = from_a_id INTO from_exist;
    SELECT COUNT(*) FROM account WHERE account_id = to_a_id INTO to_exist;
    UPDATE account SET balance = balance - t_amount WHERE account_id = from_a_id;
    UPDATE account SET balance = balance + t_amount WHERE account_id = to_a_id;
    IF from_amount < t_amount THEN
        set s = 3; -- 不够钱转
        set state = 3;
    end if;
    IF from_exist = 0 THEN
        set s = 4,state = 4; -- account not exist
    end if;
    IF to_exist = 0 THEN
        set s = 4,state = 4; -- account not exist
    end if;
    IF s = 0 THEN
        BEGIN
            commit ;
        end;
    ELSE
        BEGIN
            ROLLBACK ;
        end;
    end if;
end;

