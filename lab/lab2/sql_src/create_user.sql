drop procedure create_user;
create procedure create_user(IN usrname varchar(8), IN passwd varchar(10),
                                OUT res INT)
begin
    DECLARE s INT default 0; -- 状态码，0正常创建
    DECLARE a INT default 0;
    start transaction ;
    select count(*) FROM  bank.usertable where username = usrname into a;
    if a > 0 then
        begin
            set res = 1;
            rollback ;
        end;
    else
        begin
            INSERT into bank.usertable(username, password) VALUE (usrname,passwd);
            set res = 0;
            commit ;
        end;
    end if;
end;