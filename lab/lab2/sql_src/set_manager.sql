create procedure set_manager(IN b_name varchar(20), IN d_id INT, IN e_id VARCHAR(18), OUT state INT, OUT msg VARCHAR(20))
begin
    DECLARE s INT DEFAULT 0;
    DECLARE d_count INT DEFAULT 0; -- 检测是否有重复部门
    DECLARE e_count INT DEFAULT 0; -- 检测是否出现重复经理
    DECLARE e_valid INT DEFAULT 0; -- 检测雇员是不是在该部门
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    start transaction ;
    SELECT count(*) FROM manager_table WHERE bank_name = b_name and department_id = d_id INTO d_count;
    SELECT count(*) FROM manager_table WHERE manager_id = e_id INTO e_count;
    SELECT count(*) FROM employee WHERE employee_id = e_id and d_id = employee.department and bank_name = b_name INTO  e_valid;
    INSERT INTO manager_table(bank_name, department_id, manager_id) VALUE (b_name, d_id, e_id);
    IF d_count > 0 THEN
        set s = 2;
    end if;
    IF e_count > 0 THEN
        set s = 3;
    end if;
    IF not e_valid = 1 THEN
        set s = 4;
    end if;
    set state = s;
    IF s = 0 THEN
        set msg = 'success';
        commit ;
    ELSE
        begin
            case s
                when 1 THEN set msg = 'repeat key';
                when 2 THEN set msg = 'repeat department';
                when 3 THEN set msg = 'repeat employee';
                when 4 THEN set msg = 'invalid employee';
            end CASE ;
        end;
        rollback ;
    end if;
end;