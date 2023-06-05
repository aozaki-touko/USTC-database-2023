CREATE TRIGGER autoSetLoan AFTER INSERT ON pay_loan FOR EACH ROW
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