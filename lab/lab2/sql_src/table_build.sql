create table account
(
    account_id  varchar(18)               not null
        primary key,
    type        int   default 0           not null comment '0是储蓄账户,1是支票账户',
    balance     float default 0           not null,
    create_date date  default (curdate()) not null,
    constraint check_balance_valid
        check (`balance` >= 0)
);

create table bank
(
    bank_name varchar(20) not null comment '银行名'
        primary key,
    city      varchar(10) null
);

create table check_account
(
    account_id varchar(18)     not null
        primary key,
    overdraft  float default 0 null,
    constraint check_account_account_account_id_fk
        foreign key (account_id) references account (account_id)
            on update cascade on delete cascade
);

create table client
(
    client_id   varchar(18) not null
        primary key,
    client_name varchar(5)  null,
    telephone   varchar(11) null,
    address     varchar(20) null,
    photo       varchar(30) null
);

create table contact
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

create table department
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

create table employee
(
    employee_id varchar(18) not null
        primary key,
    bank_name   varchar(20) null,
    department  int         null,
    name        varchar(15) null,
    telephone   varchar(11) null,
    address     varchar(20) null,
    photo       varchar(20) null,
    employ_date date        null,
    constraint employee_bank__fk
        foreign key (bank_name) references bank (bank_name)
            on update cascade on delete cascade,
    constraint employee_department__fk
        foreign key (department) references department (department_id)
            on update cascade on delete cascade
);

create table connection
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

create table loan
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

create table manager_table
(
    bank_name     varchar(20) not null,
    department_id int         not null,
    manager_id    varchar(18) not null,
    primary key (department_id, bank_name, manager_id),
    constraint manager_table_department__fk
        foreign key (bank_name) references department (bank_name)
            on update cascade on delete cascade,
    constraint manager_table_department__fk2
        foreign key (department_id) references department (department_id)
            on update cascade on delete cascade,
    constraint manager_table_employee__fk
        foreign key (manager_id) references employee (employee_id)
            on update cascade on delete cascade
);

create table own_account
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

create table own_loan
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

create table pay_loan
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

create definer = root@localhost trigger autoSetLoan
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

create table saving_account
(
    account_id    varchar(18) not null
        primary key,
    interest_rate float       null,
    constraint saving_account_account__fk
        foreign key (account_id) references account (account_id)
            on update cascade on delete cascade
);

create table usertable
(
    username varchar(8)  not null
        primary key,
    password varchar(10) null
);

