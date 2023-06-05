CREATE PROCEDURE create_contact(IN c_id varchar(18),IN c_name varchar(10),IN c_tel varchar(11), IN rel varchar(8)
                        , OUT state INT, OUT msg varchar(20))
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    INSERT INTO contact(connect_id, name, telephone, relationship) VALUE (c_id, c_name, c_tel, rel);
    set state = s;
    IF s = 0 THEN
        BEGIN
            set msg = 'success';
            commit ;
        end;
    ELSE
        BEGIN
            set msg = 'client no exists or same key';
            rollback ;
        end;
    end if;
end;