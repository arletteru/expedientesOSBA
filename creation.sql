
CREATE TABLE ciudad(
    id VARCHAR(5) PRIMARY KEY,
    entidad VARCHAR(1000) NOT NULL,
    pais VARCHAR(1000) NOT NULL,
    nombre VARCHAR(1000) NOT NULL
);

CREATE TABLE sujeto(
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono BIGINT NOT NULL UNIQUE,
    correo VARCHAR(256) check (correo LIKE '%_@%.%')NOT NULL UNIQUE,
    codigo_postal INT NOT NULL,
    id_ciudad VARCHAR CONSTRAINT sujeto_id_ciudad_fk REFERENCES ciudad(id) NOT NULL,
    calle VARCHAR(100) NOT NULL,
    numero_interno INT,
    numero_externo INT
);

CREATE TYPE tipo_regimen AS ENUM ('601', '602', '603', '604', '605', '606', '607', '608', '609', '610', '611', '612', '613', '614', '615', '616', '617', '618', '619', '620', '621', '622', '623', '624', '625', '626');

CREATE TYPE tipo_cliente AS ENUM ('Cliente','Provedor');

CREATE TABLE externo(
    id SERIAL PRIMARY KEY,
    rfc VARCHAR(13) UNIQUE,
    regimen_fiscal TIPO_REGIMEN NOT NULL,
    tipo TIPO_CLIENTE NOT NULL
) inherits (sujeto);




CREATE TYPE tipo_lugar AS ENUM('sucursal','almacen','oficina');

CREATE TABLE lugar(
    id SERIAL PRIMARY KEY,
    tipo tipo_lugar NOT NULL,
    id_responsable INTEGER NOT NULL,
    cap_almacenamiento_max NUMERIC(10,2) NOT NULL
) INHERITS (sujeto);

CREATE TYPE tipo_puesto AS ENUM('Mostrador','Recursos_Humanos','Finanzas','Almacen','Admin');

CREATE TABLE registro_contratos(
    id SERIAL PRIMARY KEY,
    id_empleado INTEGER NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    puesto tipo_puesto NOT NULL,
    salario NUMERIC (10,2) check ( salario >= 0) NOT NULL,
    dias_vacaciones INT check (dias_vacaciones >= 0) not null
);

CREATE TABLE modificacion_contrato(
    id_contrato INT CONSTRAINT id_contrato_fk REFERENCES registro_contratos(id) NOT NULL,
    changed_on TIMESTAMP(6) NOT NULL,
    modificaciones JSON NOT NULL,
    PRIMARY KEY (id_contrato, changed_on)
);

CREATE TABLE empleado(
    id SERIAL PRIMARY KEY,
    nss INT NOT NULL UNIQUE,
    password VARCHAR(256) NOT NULL UNIQUE,
    rfc VARCHAR(13) NOT NULL UNIQUE,
    fecha_de_nacimiento DATE NOT NULL,
    fecha_de_ingreso DATE NOT NULL,
    contrato INTEGER CONSTRAINT contrato_fk REFERENCES registro_contratos(id),
    indice_productividad NUMERIC(10,2) check (indice_productividad BETWEEN 0 AND 1) default 1 not null ,

    telefono BIGINT NOT NULL UNIQUE,
    correo VARCHAR(256) check (correo LIKE '%_@%.%')NOT NULL UNIQUE,
    id_ciudad VARCHAR CONSTRAINT empleado_id_ciudad_fk REFERENCES ciudad(id) NOT NULL
 ) INHERITS (sujeto);

alter table lugar add constraint lugar_responsable_fk foreign key (id_responsable) REFERENCES empleado(id);
alter table registro_contratos add constraint registro_contrato_id_empleado_fk foreign key (id_empleado) REFERENCES empleado(id);


CREATE TYPE tipo_gasto_empleado AS ENUM('Nomina','Seguro','Afore','Prima_Vacacional');

CREATE TABLE prestaciones(
    id_empleado INTEGER CONSTRAINT lugar_ REFERENCES empleado(id) NOT NULL,
    concepto tipo_gasto_empleado NOT NULL,
    descripcion VARCHAR(1000),
    total NUMERIC (10,2) CHECK (total >= 0 )NOT NULL,
    fecha DATE NOT NULL,
    PRIMARY KEY(id_empleado, fecha)
);

CREATE TABLE registro_vacaciones(
    id_empleado INTEGER CONSTRAINT registro_vacaciones_id_empleado_fk REFERENCES empleado(id) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    PRIMARY KEY(id_empleado, fecha_inicio)
);

CREATE TYPE tipo_gasto_lugar AS ENUM('fijo','variable');

CREATE TABLE gastos_lugar(
    id_lugar INTEGER CONSTRAINT gastos_lugar_id_fk REFERENCES lugar(id) NOT NULL,
    descripcion VARCHAR(1000) NOT NULL,
    monto NUMERIC(10,2) check(monto >= 0)NOT NULL,
    tipo tipo_gasto_lugar NOT NULL,
    fecha DATE NOT NULL,
    PRIMARY KEY (tipo, fecha)
);

CREATE TYPE tipo_falta AS ENUM('falta','retardo');

CREATE TABLE falta(
    id_empleado INTEGER CONSTRAINT falta_id_empleado_fk REFERENCES empleado(id) NOT NULL,
    tipo tipo_falta NOT NULL,
    fecha DATE NOT NULL,
    descripcion VARCHAR(1000) NOT NULL,
    impacto_prodcuitividad NUMERIC(10,2) check(impacto_prodcuitividad >= 0) NOT NULL,
    PRIMARY KEY (id_empleado, tipo, fecha)
);


CREATE TABLE objetivo(
    id SERIAL PRIMARY KEY,
    id_empleado INTEGER CONSTRAINT objetivo_id_empleado_fk REFERENCES empleado(id) NOT NULL,
    descripcion VARCHAR(1000) NOT NULL,
    porcentaje_avance NUMERIC(10,2) CHECK (porcentaje_avance >= 0) NOT NULL,
    impacto_productividad NUMERIC(10,2) CHECK (porcentaje_avance >= 0) NOT NULL
);

CREATE TYPE tipo_asistencia AS ENUM('entrada','salida');

CREATE TABLE control_asistencia(
    id_empleado INTEGER CONSTRAINT objetivo_id_empleado_fk REFERENCES empleado(id) NOT NULL,
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    tipo TIPO_ASISTENCIA NOT NULL);


CREATE TABLE cat_prod_ser(
    clave INT PRIMARY KEY,
    descripción VARCHAR(1000) NOT NULL
);

CREATE TYPE impuesto AS ENUM('00','01','02','03','04');
CREATE TYPE tipo_unidad AS ENUM('kilogramos','kilos','litros','mililitros','metros','centimetros');
CREATE TABLE articulo(
    id INT,
    nombre VARCHAR(50) NOT NULL,
    descripcion INT CONSTRAINT articulo_descripcion_prod_ser_fk REFERENCES cat_prod_ser(clave) NOT NULL,
    unidad TIPO_UNIDAD NOT NULL,
    volumen NUMERIC(10,2),
    obj_imp impuesto NOT NULL,
    caracteristicas JSON NOT NULL,
    precio_base NUMERIC(10,2) NOT NULL,
    porcentaje_iva NUMERIC(10,2) check(porcentaje_iva >= 0) NOT NULL,
    porcentaje_ieps NUMERIC(10,2) check(porcentaje_ieps >= 0) NOT NULL,
    porcentaje_ganancia NUMERIC(10,2) check(porcentaje_ganancia BETWEEN 0 AND 1) NOT NULL,
    CONSTRAINT pk_articulo PRIMARY KEY (id, precio_base)
) PARTITION BY RANGE (precio_base);


CREATE TABLE inventario(
    cantidad INT NOT NULL,
    descuento NUMERIC(10,2),
    id_lugar INTEGER CONSTRAINT inventario_lugar_id_fk REFERENCES lugar(id) NOT NULL,
    id_articulo INTEGER CONSTRAINT inventario_id_articulo_fk REFERENCES articulo(id) NOT NULL,
    caducidad DATE,
    PRIMARY KEY(id_lugar, id_articulo, caducidad)
);


CREATE TABLE movimiento(
    id SERIAL PRIMARY KEY,
    cantidad_conceptos INT CHECK (cantidad_conceptos >= 0) NOT NULL,
    id_lugar INTEGER CONSTRAINT movimiento_id_lugar_fk REFERENCES lugar(id) NOT NULL,
    fecha DATE NOT NULL,
    hora TIME NOT NULL
);

CREATE TABLE traslado(
    id INTEGER PRIMARY KEY,
    id_lugar INTEGER CONSTRAINT movimiento_id_lugar_fk REFERENCES lugar(id) NOT NULL,
    id_empleado INTEGER CONSTRAINT traslado_id_empleado_fk REFERENCES empleado(id) NOT NULL,
    destino INTEGER CONSTRAINT destino_destino_fk REFERENCES lugar(id) NOT NULL
) INHERITS (movimiento);


CREATE TYPE tipo_perdida AS ENUM('robo','caducado');

CREATE TABLE perdida(
    id INTEGER PRIMARY KEY,
    id_lugar INTEGER CONSTRAINT movimiento_id_lugar_fk REFERENCES lugar(id) NOT NULL,
    movimiento_perdida tipo_perdida NOT NULL,
    total_perdida NUMERIC(10,2) CHECK (total_perdida >= 0) NOT NULL
) INHERITS (movimiento);


CREATE TABLE reabastecimiento(
    id INTEGER PRIMARY KEY,
    id_lugar INTEGER CONSTRAINT movimiento_id_lugar_fk REFERENCES lugar(id) NOT NULL,
    id_provedor INTEGER CONSTRAINT reabastecimiento_id_provedor_fk REFERENCES externo(id) NOT NULL,
    total_compra NUMERIC(10,2) CHECK (total_compra >= 0) NOT NULL,
    fecha DATE NOT NULL
) INHERITS (movimiento);


CREATE TYPE tipo_pago AS ENUM('efectivo','tarjeta','transferencia');

CREATE TABLE venta(
    id INTEGER PRIMARY KEY,
    id_lugar INTEGER CONSTRAINT movimiento_id_lugar_fk REFERENCES lugar(id) NOT NULL,
    id_empleado INTEGER CONSTRAINT venta_id_empleador_fk REFERENCES empleado(id) NOT NULL,
    id_cliente INTEGER CONSTRAINT venta_id_cliente_fk REFERENCES externo(id) NOT NULL,
    subtotal NUMERIC(10,2) CHECK (subtotal >= 0) NOT NULL,
    iva NUMERIC(10,2) CHECK (iva >= 0) NOT NULL,
    total NUMERIC(10,2) CHECK (total >= 0) NOT NULL,
    metodo_pago tipo_pago NOT NULL
) INHERITS (movimiento);


CREATE TYPE tipo_movimiento AS ENUM('Venta','Translado','Reabastecimiento','Perdida');

CREATE TABLE concepto(
    cantidad INT NOT NULL,
    id_articulo INT CONSTRAINT concepto_id_articulo_fk REFERENCES articulo(id),
    id_movimiento INT NOT NULL ,
    caducidad DATE,
    precio_unitario NUMERIC(8,2) NOT NULL,
    tipo tipo_movimiento NOT NULL,
    monto NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (id_articulo, id_movimiento),
    CONSTRAINT concepto_movimiento_fk FOREIGN KEY (id_movimiento) references movimiento(id)
);
