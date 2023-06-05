select COUNT(*) FROM own_account,account WHERE  own_account.client_id ='2' AND own_account.account_id = account.account_id AND account.type = 1 ;
SELECT loan.amount AS total,loan.paid_amount AS paid FROM loan,own_loan WHERE own_loan.client_id = '2' AND own_loan.loan_id = loan.loan_id;
select check_account.overdraft FROM own_account,check_account WHERE own_account.client_id ='2' AND own_account.account_id = check_account.account_id;
SELECT loan.amount AS total,loan.paid_amount AS paid FROM loan,own_loan WHERE own_loan.client_id = '2' AND own_loan.loan_id = loan.loan_id