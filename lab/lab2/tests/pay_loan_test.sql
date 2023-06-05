set @b_name = 'bank1';
set @l_id = 'test5';
set @p_id = '7';
set @l_amount =100;
set @p_date = (CURDATE());
set @c_id = '1';
call pay_loan(
        @b_name,
        @l_id,
        @p_id,
        @l_amount,
        @p_date,
        @c_id,
        @state,
        @msg
    );
select @state,
       @msg;