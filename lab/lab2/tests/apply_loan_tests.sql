set @b_name = 'bank1';
set @l_id = 'test5';
set @l_amount = 5;
set @c_id = '1';
select check_loan_valid(@c_id,@l_amount);
call apply_loan(
        @b_name,
        @l_id,
        @l_amount,
        @c_id,
        @state,
        @msg
    );
select @state,
       @msg;