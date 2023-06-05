create procedure create_client(IN c_id varchar(18), IN c_name varchar(5), IN c_tel varchar(11), IN c_addr varchar(20), IN c_photo varchar(30)
                                ,OUT state INT, OUT msg varchar(20))
BEGIN
    DECLARE s INT DEFAULT  0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION set s = 1;
    START TRANSACTION ;
    INSERT INTO client(client_id, client_name, telephone, address, photo) VALUE (c_id, c_name, c_tel, c_addr, c_photo);
    set state = s;
    IF s = 0 THEN
        set msg = 'success';
        commit ;
    ELSE
        set msg = 'repeat client id';
        rollback ;
    end if;
end;