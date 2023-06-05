set @from_a_id = '2';
set @to_a_id = 'test1';
set @t_amount = 100;
call transfer(
        @from_a_id,
        @to_a_id,
        @t_amount,
        @state,
        @msg
    );
select @state,
       @msg;