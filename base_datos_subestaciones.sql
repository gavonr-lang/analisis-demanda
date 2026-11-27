-- Base de Datos Relacional de Subestaciones y Alimentadores Eléctricos
-- Compatible con SQLite / PostgreSQL / MySQL

DROP TABLE IF EXISTS medicion_historica_resumen;
DROP TABLE IF EXISTS alimentadores;
DROP TABLE IF EXISTS subestaciones;

CREATE TABLE subestaciones (
    id_subestacion VARCHAR(10) PRIMARY KEY,
    nombre_subestacion VARCHAR(100) NOT NULL,
    nivel_tension_kv REAL NOT NULL,
    zona_operativa VARCHAR(50) NOT NULL
);

CREATE TABLE alimentadores (
    codigo_alimentador VARCHAR(10) PRIMARY KEY,
    id_subestacion VARCHAR(10) NOT NULL,
    nombre_circuito VARCHAR(100) NOT NULL,
    tipo_carga VARCHAR(40) NOT NULL,
    capacidad_nominal_kw REAL NOT NULL,
    FOREIGN KEY (id_subestacion) REFERENCES subestaciones(id_subestacion)
);

INSERT INTO subestaciones (id_subestacion, nombre_subestacion, nivel_tension_kv, zona_operativa) VALUES
('SE-01', 'Subestación Parque Industrial', 10.0, 'Zona Norte'),
('SE-02', 'Subestación Centro Histórico', 10.0, 'Zona Centro'),
('SE-03', 'Subestación Viñani - Cono Sur', 22.9, 'Zona Sur');

INSERT INTO alimentadores (codigo_alimentador, id_subestacion, nombre_circuito, tipo_carga, capacidad_nominal_kw) VALUES
('O-141', 'SE-01', 'Alimentador Industrial Norte 1', 'Industrial', 5000.0),
('O-142', 'SE-01', 'Alimentador Parque Manufactura', 'Industrial', 3000.0),
('O-143', 'SE-01', 'Alimentador Agroindustrial', 'Mixto', 3000.0),
('O-144', 'SE-01', 'Alimentador Residencial Alto', 'Residencial', 3500.0),
('O-145', 'SE-01', 'Alimentador Comercial Norte', 'Comercial', 4200.0),
('O-146', 'SE-01', 'Alimentador Servicios Auxiliares', 'Institucional', 1500.0),
('O-242', 'SE-02', 'Alimentador Cercado Centro', 'Comercial', 3200.0),
('O-244', 'SE-02', 'Alimentador Hospitalario - Cívico', 'Institucional', 3500.0),
('O-281', 'SE-03', 'Alimentador Troncal Sur 1', 'Mixto', 6500.0),
('O-282', 'SE-03', 'Alimentador Residencial Sur 2', 'Residencial', 4800.0),
('O-283', 'SE-03', 'Alimentador Expansión Urbana', 'Residencial', 4500.0),
('O-284', 'SE-03', 'Alimentador Zona Franca - Aduana', 'Industrial', 5200.0);
