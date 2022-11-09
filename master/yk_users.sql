create table users
(
    id         int auto_increment
        primary key,
    name       varchar(255) not null,
    birth_date date         not null,
    created_at datetime     null,
    constraint users_id_uindex
        unique (id)
);

INSERT INTO yk.users (id, name, birth_date, created_at) VALUES (1, 'Mike', '2001-10-18', '2022-10-31 23:53:15');
