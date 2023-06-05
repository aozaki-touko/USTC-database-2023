 drop procedure create_account;
create procedure create_account(IN a_id varchar(18),IN T INT,IN c_date DATE,IN c_id varchar(18)
                                ,OUT state INT,OUT msg varchar(30))
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