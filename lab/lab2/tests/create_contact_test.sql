set @c_id = '1';
set @c_name = 'aaa';
set @c_tel = '123456';
set @rel = '1';
call create_contact(
        @c_id,
        @c_name,
        @c_tel,
        @rel,
        @state,
        @msg
    );
select @state,
       @msg;