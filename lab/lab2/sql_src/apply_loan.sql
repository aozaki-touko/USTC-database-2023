create procedure apply_loan(IN b_name varchar(30), IN l_id varchar(18), IN l_amount float, IN c_id varchar(18)
,OUT state INT, OUT msg varchar(20))
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
    end if;
    INSERT INTO loan(bank_name, loan_id, amount, paid_amount, status) VALUE (b_name,l_id,l_amount,0,0);
    INSERT INTO own_loan(client_id, loan_id) VALUE (c_id,l_id);
    set state = s;
    IF s = 0 THEN
        set msg = 'success';
        commit ;
    ELSE
        BEGIN
            case s
                WHEN 1 THEN SET msg = 'invalid amount';
                WHEN 2 THEN SET msg = 'bank name invalid';
                WHEN 4 THEN SET msg = 'invalid key';
            end case ;
        end;
        rollback ;
    end if;
end;