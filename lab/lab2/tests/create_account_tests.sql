set @a_id = 'test2';
set @T = 0;
set @c_date = (CURDATE());
set @c_id = '2';
call create_account(
        @a_id,
        @T,
        @c_date,
        @c_id,
        @state,
        @msg
    );
select @state,
       @msg;