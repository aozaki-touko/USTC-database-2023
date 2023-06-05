create function check_loan_valid(c_id varchar(18),money_apply float)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    -- 检查贷款是否合理
    -- 遍历数据库中该用户的所有未偿还完毕的贷款，如果小于贷款限额，则允许贷款
    DECLARE s INT default 0;
    DECLARE maxMoney,curMoney,curLoanAmount,curLoanPaid FLOAT default 0;
    DECLARE cnt INT DEFAULT 0;
    DECLARE ct CURSOR FOR (SELECT loan.amount AS total,loan.paid_amount AS paid FROM loan,own_loan WHERE own_loan.client_id = c_id AND own_loan.loan_id = loan.loan_id);
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
    REPEAT
        FETCH ct INTO curLoanAmount,curLoanPaid;
        SET curMoney = curMoney + curLoanAmount - curLoanPaid;
    until s = 1
    end repeat;
    SET curMoney = curMoney + money_apply;
    IF curMoney > maxMoney THEN
        return false;
    end if;
    RETURN true;
end;