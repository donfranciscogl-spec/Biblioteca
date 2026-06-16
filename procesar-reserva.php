<?php
// Configuración de la base de datos
$host = '127.0.0.1';
$db   = 'biblioteca';
$user = 'root';
$pass = '';

// 1. Preparamos el "esqueleto" visual VINTAGE
echo '<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resultado de la Reserva</title>
    <style>
        /* Fondo estilo pergamino como en biblioteca.css */
        body {
            background: radial-gradient(circle, #f5f5dc 0%, #d2b48c 100%);
            font-family: "Georgia", "Times New Roman", serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            color: #3e2723;
        }

        /* Tarjeta estilo documento antiguo */
        .tarjeta-resultado {
            background: #fffdf7;
            padding: 40px;
            border: 2px solid #8b5a2b;
            border-radius: 3px;
            box-shadow: 10px 10px 0px rgba(92, 64, 51, 0.15);
            width: 100%;
            max-width: 400px;
            text-align: center;
            box-sizing: border-box;
            position: relative;
        }
        
        /* Detalle de la chincheta vintage */
        .tarjeta-resultado::before {
            content: "";
            position: absolute;
            top: -10px;
            left: 50%;
            transform: translateX(-50%);
            width: 18px;
            height: 18px;
            background: #5c4033;
            border-radius: 50%;
            box-shadow: inset -2px -2px 4px rgba(0,0,0,0.6), 2px 2px 3px rgba(0,0,0,0.4);
        }

        .icono { 
            font-size: 60px; 
            margin-bottom: 15px; 
            display: block;
        }
        
        /* Títulos con estilo retro */
        .titulo-exito { color: #4a5d23; font-size: 24px; margin-bottom: 15px; text-transform: uppercase; border-bottom: 1px dashed #8b5a2b; padding-bottom: 10px; }
        .titulo-error { color: #8b2500; font-size: 24px; margin-bottom: 15px; text-transform: uppercase; border-bottom: 1px dashed #8b2500; padding-bottom: 10px; }
        .titulo-aviso { color: #8b5a2b; font-size: 24px; margin-bottom: 15px; text-transform: uppercase; border-bottom: 1px dashed #8b5a2b; padding-bottom: 10px; }
        
        .texto-mensaje { font-size: 16px; color: #3e2723; line-height: 1.6; margin-bottom: 30px; font-style: italic; }
        
        /* Botones estilo sellos vintage */
        .btn-contenedor {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        
        .btn {
            display: block;
            width: 100%;
            padding: 12px;
            border-radius: 3px;
            text-decoration: none;
            color: #fdfaf3;
            font-weight: bold;
            font-size: 14px;
            text-transform: uppercase;
            letter-spacing: 1px;
            border: 1px solid #3e2723;
            transition: all 0.2s;
        }
        
        .btn-verde { background-color: #4a5d23; }
        .btn-verde:hover { background-color: #2e3b16; color: #d4af37; }
        
        .btn-marron { background-color: #5c4033; }
        .btn-marron:hover { background-color: #3e2723; color: #d4af37; }
    </style>
</head>
<body>
    <div class="tarjeta-resultado">';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $dni_socio = $_POST['dni'] ?? null;
    $titulo_libro = $_POST['titulo_libro'] ?? null;

    if ($dni_socio && $titulo_libro) {
        $stmtSocio = $pdo->prepare("SELECT id_socio, nombre FROM t_socio WHERE dni = :dni LIMIT 1");
        $stmtSocio->execute([':dni' => $dni_socio]);
        $socio = $stmtSocio->fetch(PDO::FETCH_ASSOC);

        $stmtLibro = $pdo->prepare("SELECT Buscar_Id_libro(:titulo) AS id_libro");
        $stmtLibro->execute([':titulo' => $titulo_libro]);
        $libro = $stmtLibro->fetch(PDO::FETCH_ASSOC);

        if (!$socio) {
            echo '<span class="icono">📜❓</span>';
            echo '<h2 class="titulo-error">Socio no hallado</h2>';
            echo '<p class="texto-mensaje">No constan registros del DNI <strong>' . htmlspecialchars($dni_socio) . '</strong> en nuestros archivos. Verifique la numeración.</p>';
        } 
        elseif (!$libro['id_libro']) {
            echo '<span class="icono">📖❓</span>';
            echo '<h2 class="titulo-error">Libro ausente</h2>';
            echo '<p class="texto-mensaje">La obra <strong>' . htmlspecialchars($titulo_libro) . '</strong> no se encuentra en el índice de esta biblioteca.</p>';
        } 
        else {
            $id_socio = $socio['id_socio'];
            $nombre_real = $socio['nombre']; 
            $id_libro = $libro['id_libro'];

            $stmtEjemplar = $pdo->prepare("SELECT id_ejemplar FROM t_ejemplar WHERE id_libro = :id_libro AND disponible = 1 LIMIT 1");
            $stmtEjemplar->execute([':id_libro' => $id_libro]);
            $ejemplar = $stmtEjemplar->fetch(PDO::FETCH_ASSOC);

            if (!$ejemplar) {
                echo '<span class="icono">⏳</span>';
                echo '<h2 class="titulo-aviso">Sin ejemplares</h2>';
                echo '<p class="texto-mensaje">Estimado/a <strong>' . htmlspecialchars($nombre_real) . '</strong>, lamentamos informar que no restan copias disponibles de esta obra.</p>';
            } 
            else {
                $id_ejemplar = $ejemplar['id_ejemplar'];
                $stmtFinal = $pdo->prepare("SELECT f_registrar_prestamo(:id_libro, :id_ejemplar, :id_socio) AS mensaje");
                $stmtFinal->execute([':id_libro' => $id_libro, ':id_ejemplar' => $id_ejemplar, ':id_socio' => $id_socio]);
                
                echo '<span class="icono">✒️📜</span>';
                echo '<h2 class="titulo-exito">Reserva Sellada</h2>';
                echo '<p class="texto-mensaje">Distinguido/a <strong>' . htmlspecialchars($nombre_real) . '</strong>, su préstamo ha sido debidamente registrado. Puede retirar la obra en el mostrador principal.</p>';
            }
        }
    } else {
        echo '<span class="icono">⚠️</span>';
        echo '<h2 class="titulo-error">Datos Incompletos</h2>';
        echo '<p class="texto-mensaje">El formulario carece de información necesaria para procesar el trámite.</p>';
    }

} catch (PDOException $e) {
    echo '<span class="icono">🛠️</span>';
    echo '<h2 class="titulo-error">Error Técnico</h2>';
    echo '<p class="texto-mensaje">Ha ocurrido una incidencia en el sistema: ' . $e->getMessage() . '</p>';
}

echo '      <div class="btn-contenedor">
                <a href="Biblioteca.Html" class="btn btn-verde">Volver al Inicio</a>
                <a href="formulario-reserva.html" class="btn btn-marron">Nueva Reserva</a>
            </div>
    </div>
</body>
</html>';
?>