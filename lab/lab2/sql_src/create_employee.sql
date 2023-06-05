drop procedure create_employee;
create procedure create_employee(IN e_id varchar(18),IN b_name varchar(20), IN d_id int, IN e_name varchar(10),
                        IN e_tele varchar(11), IN e_addr varchar(20), IN e_photo varchar(20), IN e_date DATE,
                        OUT state INT, OUT msg varchar(24))
begin
    DECLARE s INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1; -- 处理外键约束或者重复主键
    START TRANSACTION ;
    INSERT INTO employee(employee_id, bank_name, department, name, telephone, address, photo, employ_date)
        VALUE (e_id, b_name, d_id, e_name, e_tele, e_addr, e_photo, e_date);
    set state = s;
    IF s = 0 THEN
    BEGIN
        set msg = 'success';
        commit ;
    end;
    ELSE
        BEGIN
            set msg = 'same id or no department';
            rollback ;
        end;
    end if;
end;