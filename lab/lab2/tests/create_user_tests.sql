set @usrname = 'user3';
set @password = '1';
call create_user(@usrname,@password,@res)
select @res