drop procedure pay_loan;
CREATE PROCEDURE pay_loan(IN b_name varchar(20),IN l_id varchar(18),IN p_id varchar(18),
                IN l_amount FLOAT, IN p_date DATE, IN c_id varchar(18),
                OUT state INT, OUT msg varchar(20))
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
        set msg = 'success';
        commit ;
    ELSE
        BEGIN
            case s
                WHEN 1 THEN set msg = 'invalid key';
                WHEN 2 THEN set msg = 'invalid amount';
                WHEN 3 THEN set msg = 'loan invalid';
            end case ;
        end;
        commit ;
    end if;



end;