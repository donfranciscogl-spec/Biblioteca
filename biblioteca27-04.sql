-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 27-04-2026 a las 14:13:57
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `biblioteca`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `Buscar_libro_autor_titulo` (IN `p_titulo` VARCHAR(100), IN `p_autor` VARCHAR(100), OUT `p_mensaje` VARCHAR(100))   BEGIN
DECLARE v_titulo varchar (100);
DECLARE v_autor varchar (100);
DECLARE v_id  INT;
DECLARE v_id2 INT;
IF p_titulo = '' OR p_titulo IS NULL OR p_autor = '' OR p_autor IS NULL THEN
    SET p_mensaje = 'Por favor, rellena tanto el título como el autor.';
ELSE
SELECT Titulo INTO v_titulo FROM t_libro
	WHERE Titulo LIKE concat('%', p_titulo,'%')
    LIMIT 1;
SELECT Nombre INTO v_autor FROM t_autores
	WHERE	Nombre LIKE concat('%',p_autor,'%')
    LIMIT 1; 

SELECT id_autor INTO v_id FROM t_autores 
	WHERE Nombre LIKE concat('%',p_autor,'%');

SELECT id_autor INTO v_id2 FROM t_libro 
	WHERE titulo LIKE concat('%',p_titulo,'%');
    
    
IF v_id = v_id2 then SET p_mensaje =concat('Tenemos ',v_titulo, ' de ',v_autor) ;
ELSE 
SET p_mensaje = 'Comprueba los datos' ;
END IF;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `libro_mas_prestado` ()   BEGIN

SELECT titulo
FROM t_libro
JOIN t_prestamo USING(id_libro)
GROUP BY id_libro
ORDER BY count(*) DESC
LIMIT 1;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Prestar_libros` (IN `p_DNI` VARCHAR(9), IN `p_Titulo` VARCHAR(100), OUT `p_mensaje` VARCHAR(100))   BEGIN 
   
    DECLARE v_socio INT;
    DECLARE v_libro INT;
    DECLARE v_ejemplar INT;
    DECLARE v_disponible TINYINT DEFAULT 0;
    
    
    IF p_DNI is null or p_DNI = '' THEN SET p_mensaje = 'revise el campo';
    ELSE 
    SELECT id_socio INTO v_socio FROM t_socio WHERE dni = p_DNI 
    limit 1;
    END IF;
    
    SELECT id_libro, id_ejemplar, disponible into v_libro, v_ejemplar, v_disponible 
    FROM t_ejemplar 
    	JOIN t_libro USING(id_libro) 
        WHERE titulo like concat('%',p_Titulo,'%') AND disponible = 1 
        limit 1;
        
        IF v_disponible = 0 THEN SET p_mensaje = 'No existe ejemplar disponible actualmente';
        ELSE  INSERT INTO t_prestamo (id_libro, id_ejemplar, id_socio)
       				 VALUES (v_libro, v_ejemplar, v_socio);
        UPDATE t_ejemplar
        SET disponible = 0
        WHERE id_libro = v_libro AND id_ejemplar = v_ejemplar;
        SET p_mensaje = 'Prestamo realizado con exito';
        END IF;
    
        SELECT p_mensaje;
        END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `buscar_id_autor` (`Nombre_completo` VARCHAR(100)) RETURNS INT(11)  BEGIN
declare id_de_autor int;
set id_de_autor=(select Id_autor from t_autores
              where Nombre=Nombre_completo);
if id_de_autor<>0 THEN
return id_de_autor;
ELSE
return 0;
end if;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `buscar_id_editorial` (`Editorial` VARCHAR(100)) RETURNS INT(11)  BEGIN
RETURN (
    SELECT ifnull(Id_editorial,0)
    FROM t_editorial
    WHERE Nombre=Editorial
    LIMIT 1
);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Buscar_Id_libro` (`p_titulo` VARCHAR(255)) RETURNS INT(11) READS SQL DATA BEGIN DECLARE v_Id_libro INT(11);

SELECT Id_libro INTO v_Id_libro
    FROM t_libro 
    WHERE Titulo = p_titulo 
    LIMIT 1;
RETURN v_id_libro;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `calcular_vencimiento` (`p_fecha_inicio` DATE, `p_dias` INT) RETURNS DATE DETERMINISTIC BEGIN
DECLARE v_fecha_final DATE;
 -- prevencion de error
IF p_dias <= 0 THEN RETURN NULL;
END IF;
 -- fin prevencion de error
SET v_fecha_final = DATE_ADD(p_fecha_inicio, INTERVAL p_dias DAY);

IF DAYOFWEEK(v_fecha_final) = 1 THEN 
    -- Si es domingo (1), le sumamos un día más para que sea lunes
    SET v_fecha_final = DATE_ADD(v_fecha_final, INTERVAL 1 DAY);
END IF;
IF DAYOFWEEK(v_fecha_final) = 7 THEN 
    -- Si es sabado (7), le sumamos dos diías más para que sea lunes
    SET v_fecha_final = DATE_ADD(v_fecha_final, INTERVAL 2 DAY);
END IF;
RETURN v_fecha_final;
    RETURN DATE_ADD(p_fecha_inicio, INTERVAL p_dias DAY);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `COMPROBAR_DISPONIBILIDAD` (`p_titulo` VARCHAR(100)) RETURNS VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_general_ci READS SQL DATA BEGIN
DECLARE v_disponible TINYINT;
SELECT disponible INTO v_disponible FROM t_ejemplar
JOIN t_libro USING(Id_libro)
WHERE Titulo like concat('%',titulo,'%')  and disponible = 1
LIMIT 1;

IF v_disponible = 1 THEN RETURN 'El libro esta disponible';
ELSE RETURN 'El libro no esta disponible';
END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `contadoranyo` (`Anyo` YEAR) RETURNS INT(11)  BEGIN
DECLARE totallibrosporaño int;
SELECT COUNT(*) INTO totallibrosporaño from t_libro
   WHERE año_de_publicacion = Anyo;
IF totallibrosporaño <> 0 THEN
   RETURN totallibrosporaño;
ELSE
   RETURN 0;
end IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `contar_disponibilidad` (`p_titulo` VARCHAR(100)) RETURNS VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_general_ci  BEGIN 
	DECLARE v_total INT DEFAULT 0;
	DECLARE v_nombre_titulo varchar(100) DEFAULT 'libro no encontrado';
		SELECT Titulo INTO v_nombre_titulo
        	FROM t_libro 
            	where Titulo like concat('%',p_titulo,'%')
                limit 1;
	
    SELECT count(*) into v_total
			FROM t_ejemplar
            	join t_libro using(id_libro)
    			WHERE Titulo = v_nombre_titulo and disponible = 1;
    
    RETURN concat('El total de ejemplares disponibles de ' ,v_nombre_titulo, ' es ' ,v_total, '.');

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `estado_socio` (`v_id_socio` INT) RETURNS VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_general_ci  begin

declare v_libros_pendientes int; 
DECLARE v_nombre_socio varchar(50);

select nombre into v_nombre_socio from t_socio 
	where id_socio = v_id_socio;
select count(*) into v_libros_pendientes from t_prestamo 
	where id_socio = v_id_socio and fecha_devolucion is null;

if v_libros_pendientes > 0 then RETURN CONCAT('El socio ', v_nombre_socio , ' no puede pedir mas libros');
else RETURN CONCAT('El socio ', v_nombre_socio , ' puede solicitar nuevos prestamos');
end if;
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `f_registrar_prestamo` (`p_id_libro` INT UNSIGNED, `p_id_ejemplar` INT UNSIGNED, `p_id_socio` INT) RETURNS VARCHAR(255) CHARSET utf8mb4 COLLATE utf8mb4_general_ci MODIFIES SQL DATA BEGIN
    -- Variables
    DECLARE v_disponible TINYINT;
    
    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN '❌ Error: No se pudo registrar el préstamo. Verifica los IDs.';
    END;

    -- 1. Buscamos el estado EXACTO de ese libro y ese ejemplar
    SELECT disponible INTO v_disponible
    FROM t_ejemplar
    WHERE id_libro = p_id_libro AND id_ejemplar = p_id_ejemplar LIMIT 1;

    -- Lógica principal
    IF v_disponible = 1 THEN
        
        -- 2. Creamos el préstamo guardando los tres datos
        INSERT INTO t_prestamo (id_libro, id_ejemplar, id_socio)
        VALUES (p_id_libro, p_id_ejemplar, p_id_socio);

        -- 3. Actualizamos solo ese ejemplar específico
        UPDATE t_ejemplar
        SET disponible = 0
        WHERE id_libro = p_id_libro AND id_ejemplar = p_id_ejemplar;

        -- Mensaje de éxito
        RETURN '✅ Préstamo registrado con éxito y ejemplar actualizado.';
        
    ELSE
        -- Si no estaba disponible (0) o no existe
        RETURN '⚠️ Error: El ejemplar de este libro no está disponible actualmente.';
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Socio_libro` (`p_titulo` VARCHAR(100)) RETURNS VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_general_ci  BEGIN
DECLARE v_socio_libro varchar(100);
DECLARE v_titulo_a_ver varchar(100);

SELECT Titulo INTO v_titulo_a_ver from t_libro WHERE Titulo like concat('%',p_titulo,'%') LIMIT 1;

SELECT GROUP_CONCAT(DISTINCT nombre SEPARATOR ' - ') INTO v_socio_libro 
FROM t_socio
JOIN t_prestamo USING (id_socio) 
JOIN t_libro USING (id_libro)
WHERE titulo = v_titulo_a_ver;

RETURN concat('Estos socios han pedido prestado alguna vez este libro: ' ,v_titulo_a_ver,':',' ', v_socio_libro);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `total_libros` (`total_libros` INT) RETURNS INT(11)  BEGIN
DECLARE total_libros int;
SELECT COUNT(*) INTO total_libros from t_libro;
RETURN total_libros;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Total_libros_prestados` (`p_socio` VARCHAR(100)) RETURNS VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_general_ci  BEGIN
DECLARE v_total INT;

SELECT COUNT(id_socio)
INTO v_total FROM t_prestamo
JOIN t_socio USING(id_socio) 
WHERE nombre = p_socio;

RETURN concat ('el socio tiene prestados ',v_total,' libros');

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `t_autores`
--

CREATE TABLE `t_autores` (
  `Id_autor` int(11) NOT NULL,
  `Nombre` varchar(100) NOT NULL,
  `codigo_autor` varchar(11) NOT NULL,
  `id_Nacionalidad` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `t_autores`
--

INSERT INTO `t_autores` (`Id_autor`, `Nombre`, `codigo_autor`, `id_Nacionalidad`) VALUES
(1, 'Martin Joel Velazquez', 'VEL', 0),
(3, 'David Baker', 'BAK', 4),
(4, 'Sigmund froid', 'FRO', 5),
(5, 'Matthew Ellul', 'ELL', 6),
(6, 'Charles Darwin', 'DAR', 4),
(7, 'Richard Wolfson', 'WOL', 7),
(8, 'John Bowker', 'BOW', 4),
(9, 'Gabriel Garcia Marquez', 'GAR', 0),
(10, 'William Shakespeare', 'SHA', 4),
(11, 'John Pinel', 'PIN', 7),
(12, 'Walter Isaacson', 'ISA', 7),
(13, 'Ralph H. Petrucci et al.', 'PET', 7),
(14, 'John J.Macionis', 'MAC', 7),
(15, 'Gregory Mankiv', 'MAN', 7),
(16, 'Dante Alighieri', 'ALI', 8),
(100, 'Cervantes', 'CER', 0),
(102, 'Olga Lujan', 'OLG', 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `t_editorial`
--

CREATE TABLE `t_editorial` (
  `Id_editorial` int(11) NOT NULL,
  `Nombre` varchar(100) NOT NULL,
  `id_nacionalidad` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `t_editorial`
--

INSERT INTO `t_editorial` (`Id_editorial`, `Nombre`, `id_nacionalidad`) VALUES
(1, 'Santillana', 0),
(2, 'publicacion independiente mexico', 2),
(3, 'Antoni Bosh Editor, S.A.', 7),
(4, 'Alianza editorial', 0),
(5, 'Ed, School of composition', 7),
(7, 'Pearson Education', 4),
(8, 'DK.', 7),
(9, 'Debolsillo', 4),
(10, 'Create Space', 7),
(11, 'Ed. Paraninfo', 0),
(12, 'Poseidonia', 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `t_ejemplar`
--

CREATE TABLE `t_ejemplar` (
  `id_libro` int(11) UNSIGNED NOT NULL,
  `id_ejemplar` int(11) UNSIGNED NOT NULL,
  `disponible` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `t_ejemplar`
--

INSERT INTO `t_ejemplar` (`id_libro`, `id_ejemplar`, `disponible`) VALUES
(1, 1, 0),
(1, 3, 0),
(2, 1, 0),
(2, 2, 0),
(3, 2, 0),
(4, 2, 0),
(5, 2, 0),
(7, 2, 0),
(8, 2, 0),
(9, 2, 0),
(10, 1, 0),
(10, 2, 0),
(11, 1, 0),
(11, 2, 0),
(12, 1, 0),
(12, 2, 0),
(13, 1, 0),
(13, 2, 0),
(14, 2, 0),
(15, 2, 0),
(16, 2, 0),
(17, 2, 0),
(1, 2, 1),
(1, 4, 1),
(1, 5, 1),
(1, 6, 1),
(3, 1, 1),
(4, 1, 1),
(5, 1, 1),
(5, 3, 1),
(5, 4, 1),
(7, 1, 1),
(8, 1, 1),
(9, 1, 1),
(11, 3, 1),
(14, 1, 1),
(15, 1, 1),
(16, 1, 1),
(17, 1, 1),
(17, 3, 1),
(18, 1, 1),
(18, 2, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `t_libro`
--

CREATE TABLE `t_libro` (
  `Id_libro` int(11) UNSIGNED NOT NULL,
  `isbn` varchar(20) NOT NULL,
  `Titulo` varchar(50) NOT NULL,
  `id_editorial` int(11) NOT NULL,
  `año_de_publicacion` year(4) NOT NULL,
  `id_autor` int(11) NOT NULL,
  `dni_donante` varchar(20) DEFAULT NULL,
  `metodo_entrega` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `t_libro`
--

INSERT INTO `t_libro` (`Id_libro`, `isbn`, `Titulo`, `id_editorial`, `año_de_publicacion`, `id_autor`, `dni_donante`, `metodo_entrega`) VALUES
(1, '8429445595', 'Don quijote de la mancha', 1, '1996', 100, NULL, NULL),
(2, '979-8687336024', 'matematicas basicas: aritmetica y algebra', 2, '2022', 1, NULL, NULL),
(3, '9788412473650', 'Breve historia del mundo', 3, '2023', 3, NULL, NULL),
(4, '9788420650906', 'Introduccion al psicoanalisis', 4, '2011', 4, NULL, NULL),
(5, '9789918954858', 'Aprende a leer música en 30 días', 5, '2022', 5, NULL, NULL),
(7, '9788411484565', 'El Origen de las Especies', 4, '2023', 6, NULL, NULL),
(8, '9788478291250', 'Fundamentos de Fisica', 7, '2011', 7, NULL, NULL),
(9, '9780241582930', 'Religiones del Mundo', 8, '2022', 8, NULL, NULL),
(10, '9788497592208', 'Cien años de soledad', 9, '2003', 9, NULL, NULL),
(11, '9781985248113', 'Romeo y Julieta', 10, '2018', 10, NULL, NULL),
(12, '9988478290819', 'Biopsicologia', 7, '2006', 11, NULL, NULL),
(13, '9788499897318', 'Steve Jobs. La biografía', 9, '2013', 12, NULL, NULL),
(14, '9788490355336', 'Química General', 7, '2017', 13, NULL, NULL),
(15, '9788483227428', 'Sociología', 7, '2012', 14, NULL, NULL),
(16, '9788428333672', 'Economia', 11, '2017', 15, NULL, NULL),
(17, '997842060996', 'La Divina Comedia', 4, '2012', 16, NULL, NULL),
(18, '9788175654439', 'La Teniente de Ayas ', 12, '2025', 102, '15489468P', 'Presencial');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `t_matica`
--

CREATE TABLE `t_matica` (
  `cdu` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `t_matica`
--

INSERT INTO `t_matica` (`cdu`, `nombre`) VALUES
(4, ''),
(7, 'Artes, musi'),
(6, 'ciencia aplicadas'),
(5, 'ciencias exactas y naturales'),
(2, 'ciencias sociales'),
(1, 'filosofía y psicología'),
(9, 'geografia, biografia e historia'),
(8, 'lingüistica y literatura'),
(0, 'obras generales'),
(3, 'religion');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `t_nacionalidad`
--

CREATE TABLE `t_nacionalidad` (
  `id_nacionalidad` int(50) NOT NULL,
  `pais` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `t_nacionalidad`
--

INSERT INTO `t_nacionalidad` (`id_nacionalidad`, `pais`) VALUES
(0, 'España'),
(1, 'Portugal'),
(2, 'mexico'),
(3, 'Fracia'),
(4, 'Inglaterra'),
(5, 'Austria'),
(6, 'Malta'),
(7, 'EEUU'),
(8, 'Italia');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `t_prestamo`
--

CREATE TABLE `t_prestamo` (
  `id_prestamo` int(11) UNSIGNED NOT NULL,
  `id_libro` int(11) UNSIGNED DEFAULT NULL,
  `id_ejemplar` int(11) UNSIGNED NOT NULL,
  `id_socio` int(11) NOT NULL,
  `fecha_alta` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_devolucion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `t_prestamo`
--

INSERT INTO `t_prestamo` (`id_prestamo`, `id_libro`, `id_ejemplar`, `id_socio`, `fecha_alta`, `fecha_devolucion`) VALUES
(1, 1, 3, 7, '2026-03-23 13:31:41', NULL),
(2, 2, 2, 8, '2026-03-23 13:31:48', NULL),
(3, 13, 2, 1, '2026-03-23 14:10:03', NULL),
(4, 12, 2, 1, '2026-03-23 14:09:21', NULL),
(5, 11, 2, 16, '2026-03-23 14:07:21', NULL),
(6, 3, 2, 9, '2026-03-23 14:05:21', NULL),
(7, 4, 2, 10, '2026-03-23 14:05:42', NULL),
(8, 5, 2, 11, '2026-03-23 14:05:56', NULL),
(9, 7, 2, 12, '2026-03-23 14:06:07', NULL),
(10, 8, 2, 13, '2026-03-23 14:06:20', NULL),
(11, 9, 2, 14, '2026-03-23 14:06:59', NULL),
(12, 10, 2, 15, '2026-03-23 14:07:11', NULL),
(13, 11, 1, 7, '2026-04-13 14:15:08', NULL),
(15, 12, 1, 16, '2026-04-14 10:53:18', NULL),
(16, 1, 1, 8, '2026-04-23 09:59:10', NULL),
(17, 10, 1, 7, '2026-04-23 13:34:28', NULL),
(19, 2, 1, 4, '2026-04-27 13:23:45', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `t_signatura`
--

CREATE TABLE `t_signatura` (
  `codigo_autor` varchar(11) NOT NULL,
  `id_libro` int(11) UNSIGNED NOT NULL,
  `cdu` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `t_signatura`
--

INSERT INTO `t_signatura` (`codigo_autor`, `id_libro`, `cdu`) VALUES
('CER', 1, 8),
('DAR', 7, 5),
('WOL', 8, 6),
('GAR', 10, 8),
('SHA', 11, 8),
('PIN', 12, 1),
('ISA', 13, 9),
('PET', 14, 6),
('MAC', 15, 2),
('MAN', 16, 6),
('ALI', 17, 8);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `t_socio`
--

CREATE TABLE `t_socio` (
  `id_socio` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `dni` varchar(9) NOT NULL,
  `telefono` int(9) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `año_nacimiento` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `t_socio`
--

INSERT INTO `t_socio` (`id_socio`, `nombre`, `dni`, `telefono`, `Email`, `año_nacimiento`) VALUES
(1, 'Fran Gonzalez', '99555999p', 957957874, 'fran.gonz@email.com', '1998-11-07'),
(4, 'Javier lujan', '66677755O', 987566322, 'jav.luj2@gmail.com', '1997-11-03'),
(7, 'Ana García López', '12345678A', 600111222, 'ana.garcia@email.com', '1990-05-15'),
(8, 'Carlos Martínez Ruiz', '23456789B', 611222333, 'carlos.mtz@email.com', '1985-10-20'),
(9, 'Elena Rodríguez Sanz', '34567890C', 622333444, 'elena.rs@email.com', '1992-03-08'),
(10, 'Javier Fernández Gómez', '45678901D', 633444555, 'javi.fdez@email.com', '1988-12-12'),
(11, 'Lucía Sánchez Pérez', '56789012E', 644555666, 'lucia.sp@email.com', '1995-07-25'),
(12, 'Pablo Jiménez Díaz', '67890123F', 655666777, 'pablo.jim@email.com', '1982-01-30'),
(13, 'Marta Vázquez Ramos', '78901234G', 666777888, 'marta.vaz@email.com', '2000-11-02'),
(14, 'Ricardo Castro Mola', '89012345H', 677888999, 'ricardo.c@email.com', '1979-06-14'),
(15, 'Sara Navarro Torres', '90123456I', 688999000, 'sara.nt@email.com', '1998-09-19'),
(16, 'Hugo Pascual Herrero', '01234567J', 699000111, 'hugo.pas@email.com', '1993-04-22');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_detalle_libros`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_detalle_libros` (
`Titulo` varchar(50)
,`Autor` varchar(100)
,`Editorial` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_detalle_libros`
--
DROP TABLE IF EXISTS `vw_detalle_libros`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_detalle_libros`  AS SELECT `t_libro`.`Titulo` AS `Titulo`, `t_autores`.`Nombre` AS `Autor`, `t_editorial`.`Nombre` AS `Editorial` FROM ((`t_libro` join `t_autores` on(`t_libro`.`id_autor` = `t_autores`.`Id_autor`)) join `t_editorial` on(`t_libro`.`id_editorial` = `t_editorial`.`Id_editorial`)) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `t_autores`
--
ALTER TABLE `t_autores`
  ADD PRIMARY KEY (`Id_autor`),
  ADD KEY `exp` (`codigo_autor`),
  ADD KEY `codigo_autor` (`codigo_autor`),
  ADD KEY `nacionalidad` (`id_Nacionalidad`);

--
-- Indices de la tabla `t_editorial`
--
ALTER TABLE `t_editorial`
  ADD PRIMARY KEY (`Id_editorial`),
  ADD KEY `id_nacionalidad` (`id_nacionalidad`);

--
-- Indices de la tabla `t_ejemplar`
--
ALTER TABLE `t_ejemplar`
  ADD PRIMARY KEY (`id_libro`,`id_ejemplar`),
  ADD KEY `disponible` (`disponible`);

--
-- Indices de la tabla `t_libro`
--
ALTER TABLE `t_libro`
  ADD PRIMARY KEY (`Id_libro`),
  ADD UNIQUE KEY `isbn` (`isbn`),
  ADD KEY `id_autor` (`id_autor`),
  ADD KEY `t_libro_ibfk_3` (`id_editorial`);

--
-- Indices de la tabla `t_matica`
--
ALTER TABLE `t_matica`
  ADD PRIMARY KEY (`cdu`),
  ADD KEY `nombre` (`nombre`);

--
-- Indices de la tabla `t_nacionalidad`
--
ALTER TABLE `t_nacionalidad`
  ADD PRIMARY KEY (`id_nacionalidad`);

--
-- Indices de la tabla `t_prestamo`
--
ALTER TABLE `t_prestamo`
  ADD PRIMARY KEY (`id_prestamo`),
  ADD KEY `id_libro` (`id_ejemplar`),
  ADD KEY `id_socio` (`id_socio`),
  ADD KEY `id_libro_2` (`id_libro`);

--
-- Indices de la tabla `t_signatura`
--
ALTER TABLE `t_signatura`
  ADD PRIMARY KEY (`id_libro`),
  ADD KEY `cdu` (`cdu`),
  ADD KEY `codigo_autor` (`codigo_autor`);

--
-- Indices de la tabla `t_socio`
--
ALTER TABLE `t_socio`
  ADD PRIMARY KEY (`id_socio`),
  ADD UNIQUE KEY `dni` (`dni`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `t_autores`
--
ALTER TABLE `t_autores`
  MODIFY `Id_autor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=103;

--
-- AUTO_INCREMENT de la tabla `t_editorial`
--
ALTER TABLE `t_editorial`
  MODIFY `Id_editorial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `t_libro`
--
ALTER TABLE `t_libro`
  MODIFY `Id_libro` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla `t_prestamo`
--
ALTER TABLE `t_prestamo`
  MODIFY `id_prestamo` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT de la tabla `t_socio`
--
ALTER TABLE `t_socio`
  MODIFY `id_socio` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `t_autores`
--
ALTER TABLE `t_autores`
  ADD CONSTRAINT `t_autores_ibfk_1` FOREIGN KEY (`id_Nacionalidad`) REFERENCES `t_nacionalidad` (`id_nacionalidad`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `t_editorial`
--
ALTER TABLE `t_editorial`
  ADD CONSTRAINT `t_editorial_ibfk_1` FOREIGN KEY (`id_nacionalidad`) REFERENCES `t_nacionalidad` (`id_nacionalidad`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `t_ejemplar`
--
ALTER TABLE `t_ejemplar`
  ADD CONSTRAINT `t_ejemplar_ibfk_1` FOREIGN KEY (`id_libro`) REFERENCES `t_libro` (`Id_libro`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `t_libro`
--
ALTER TABLE `t_libro`
  ADD CONSTRAINT `t_libro_ibfk_1` FOREIGN KEY (`id_autor`) REFERENCES `t_autores` (`Id_autor`) ON UPDATE CASCADE,
  ADD CONSTRAINT `t_libro_ibfk_3` FOREIGN KEY (`id_editorial`) REFERENCES `t_editorial` (`Id_editorial`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `t_prestamo`
--
ALTER TABLE `t_prestamo`
  ADD CONSTRAINT `t_prestamo_ibfk_1` FOREIGN KEY (`id_socio`) REFERENCES `t_socio` (`id_socio`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `t_prestamo_ibfk_2` FOREIGN KEY (`id_libro`) REFERENCES `t_libro` (`Id_libro`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `t_signatura`
--
ALTER TABLE `t_signatura`
  ADD CONSTRAINT `t_signatura_ibfk_1` FOREIGN KEY (`id_libro`) REFERENCES `t_libro` (`Id_libro`) ON UPDATE CASCADE,
  ADD CONSTRAINT `t_signatura_ibfk_2` FOREIGN KEY (`cdu`) REFERENCES `t_matica` (`cdu`) ON UPDATE CASCADE,
  ADD CONSTRAINT `t_signatura_ibfk_3` FOREIGN KEY (`codigo_autor`) REFERENCES `t_autores` (`codigo_autor`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
