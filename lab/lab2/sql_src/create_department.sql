create procedure create_department(IN b_name varchar(20), IN d_name varchar(10), IN d_type varchar(4),IN d_id INT
                                ,OUT state INT,OUT msg VARCHAR(20))
begin
    DECLARE s INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    START TRANSACTION ;
    INSERT INTO bank.department(bank_name, name, type, department_id) VALUE (b_name,d_name,d_type,d_id);
    IF s = 0 THEN
        set state = s;
        set msg = 'success';
        commit ;
    ELSE
        begin
            set state = s;
            set msg = '部门重复';
            rollback ;
        end;
    end if;
end;