create procedure transfer(IN from_a_id varchar(18), IN to_a_id varchar(18), IN t_amount float
                            ,OUT state INT, OUT msg varchar(20))
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE from_exist,to_exist BOOLEAN DEFAULT FALSE;
    DECLARE from_amount INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    START TRANSACTION ;
    IF t_amount <= 0 THEN
        set s = 2; -- 不合法的转账
    end if;
    SELECT balance FROM account WHERE account_id = from_a_id INTO from_amount;
    SELECT COUNT(*) FROM account WHERE account_id = from_a_id INTO from_exist;
    SELECT COUNT(*) FROM account WHERE account_id = to_a_id INTO to_exist;
    UPDATE account SET balance = balance - t_amount WHERE account_id = from_a_id;
    UPDATE account SET balance = balance + t_amount WHERE account_id = to_a_id;
    IF from_amount < t_amount THEN
        set s = 3; -- 不够钱转
    end if;
    IF not from_exist OR not to_exist THEN
        set s = 4; -- account not exist
    end if;
    set state = s;
    IF s = 0 THEN
        BEGIN
            set msg = 'success';
            commit ;
        end;
    ELSE
        BEGIN
            case s
                WHEN 1 THEN SET msg = 'error';
                WHEN 2 THEN SET msg = 'amount <= 0';
                WHEN 3 THEN SET msg = 'Not enough balance';
                WHEN 4 THEN SET msg = 'account not exist';
            end case ;
            ROLLBACK ;
        end;
    end if;
end;