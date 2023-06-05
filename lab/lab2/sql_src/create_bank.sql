drop procedure create_bank;
-- 如果要修改余额,可以直接在前端中修改
create procedure create_bank(IN b_name varchar(20),IN b_city varchar(10), IN base_asset INT,
                    OUT state INT ,OUT msg varchar(20))
begin
    declare s INT default 0;
    declare CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    start transaction ;
    if base_asset <= 0 then
        set s = 2;
    end if;
    insert into bank.bank(bank_name, city, assets) VALUE (b_name,b_city,base_asset);
    if s = 0 THEN
        set state = 0;
        set msg = 'success';
        commit ;
    ELSE
        set state  = s;
        case s
            when 1 THEN set msg = '重复名字';
            when 2 THEN set msg = '资产为负';
        end case ;
        rollback ;
    end if;
end;