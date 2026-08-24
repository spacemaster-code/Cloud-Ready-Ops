create database empresa_db;
use empresa_db;

create table empleados (
    id int auto_increment primary key,
    nombre varchar(50)
);

insert into empleados (nombre) values ('Matias');

select * from empleados;