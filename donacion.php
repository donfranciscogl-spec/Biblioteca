<?php
// Configuración de la base de datos
$conn = mysqli_connect("localhost", "root", "", "biblioteca");
mysqli_set_charset($conn, "utf8");

// 1. Preparamos el esqueleto visual VINTAGE
echo '<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resultado de la Donación</title>
    <style>
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
        .icono { font-size: 60px; margin-bottom: 15px; display: block; }
        .titulo-exito { color: #4a5d23; font-size: 24px; margin-bottom: 15px; text-transform: uppercase; border-bottom: 1px dashed #8b5a2b; padding-bottom: 10px; }
        .titulo-error { color: #8b2500; font-size: 24px; margin-bottom: 15px; text-transform: uppercase; border-bottom: 1px dashed #8b2500; padding-bottom: 10px; }
        .texto-mensaje { font-size: 16px; color: #3e2723; line-height: 1.6; margin-bottom: 30px; font-style: italic; }
        .btn-contenedor { display: flex; flex-direction: column; gap: 12px; }
        .btn {
            display: block; width: 100%; padding: 12px; border-radius: 3px; text-decoration: none;
            color: #fdfaf3; font-weight: bold; font-size: 14px; text-transform: uppercase; letter-spacing: 1px;
            border: 1px solid #3e2723; transition: all 0.2s; box-sizing: border-box;
        }
        .btn-verde { background-color: #4a5d23; }
        .btn-verde:hover { background-color: #2e3b16; color: #d4af37; }
        .btn-marron { background-color: #5c4033; }
        .btn-marron:hover { background-color: #3e2723; color: #d4af37; }
    </style>
</head>
<body>
    <div class="tarjeta-resultado">';

if (isset($_POST['btn_donar'])) {
    $dni = mysqli_real_escape_string($conn, $_POST['DNI']);
    $titulo = mysqli_real_escape_string($conn, $_POST['titulo']);
    $isbn = mysqli_real_escape_string($conn, $_POST['isbn']);
    $ano = mysqli_real_escape_string($conn, $_POST['año_de_publicacion']);
    $metodo = mysqli_real_escape_string($conn, $_POST['metodo_donacion']);

    // --- LÓGICA DE EDITORIAL ---
    $id_edit_post = mysqli_real_escape_string($conn, $_POST['id_editorial']);
    $id_final_editorial = 0;

    if ($id_edit_post === "otra") {
        $nombre_n = mysqli_real_escape_string($conn, $_POST['nombre_nueva_editorial']);
        $sql = "INSERT INTO t_editorial (Nombre, id_nacionalidad) VALUES ('$nombre_n', 0)";
        mysqli_query($conn, $sql);
        $id_final_editorial = mysqli_insert_id($conn);
    } else {
        $id_final_editorial = $id_edit_post;
    }

    // --- LÓGICA DE AUTOR ---
    $id_autor_post = mysqli_real_escape_string($conn, $_POST['id_autor']);
    $id_final_autor = 0;

    if ($id_autor_post === "otra") {
        $nombre_a = mysqli_real_escape_string($conn, $_POST['nombre_nuevo_autor']);
        $cod = strtoupper(substr($nombre_a, 0, 3));
        $sql = "INSERT INTO t_autores (Nombre, codigo_autor, id_Nacionalidad) VALUES ('$nombre_a', '$cod', 0)";
        mysqli_query($conn, $sql);
        $id_final_autor = mysqli_insert_id($conn);
    } else {
        $id_final_autor = $id_autor_post;
    }

    // --- 1. GUARDAR / RECUPERAR EL LIBRO ---
    $check_libro = "SELECT Id_libro FROM t_libro WHERE isbn = '$isbn' OR Titulo = '$titulo' LIMIT 1";
    $res_libro = mysqli_query($conn, $check_libro);
    $id_final_libro = 0;

    if (mysqli_num_rows($res_libro) > 0) {
        // El libro ya existe en el catálogo. Sacamos su ID.
        $fila_libro = mysqli_fetch_assoc($res_libro);
        $id_final_libro = $fila_libro['Id_libro'];
    } else {
        // Es un libro totalmente nuevo. Lo registramos.
        $sql_libro = "INSERT INTO t_libro (Titulo, id_autor, isbn, año_de_publicacion, dni_donante, metodo_entrega, id_editorial) 
                      VALUES ('$titulo', '$id_final_autor', '$isbn', '$ano', '$dni', '$metodo', '$id_final_editorial')";
        mysqli_query($conn, $sql_libro);
        $id_final_libro = mysqli_insert_id($conn);
    }

    // --- 2. GENERAR EL EJEMPLAR FÍSICO DISPONIBLE ---
    // Buscamos cuál fue el último número de ejemplar para este libro y le sumamos 1
    $check_ejemplar = "SELECT IFNULL(MAX(id_ejemplar), 0) + 1 AS nuevo_id FROM t_ejemplar WHERE id_libro = '$id_final_libro'";
    $res_ejemplar = mysqli_query($conn, $check_ejemplar);
    $fila_ejemplar = mysqli_fetch_assoc($res_ejemplar);
    $nuevo_id_ejemplar = $fila_ejemplar['nuevo_id'];

    // Insertamos la copia en la estantería (disponible = 1)
    $sql_ejemplar = "INSERT INTO t_ejemplar (id_libro, id_ejemplar, disponible) VALUES ('$id_final_libro', '$nuevo_id_ejemplar', 1)";
    
    if (mysqli_query($conn, $sql_ejemplar)) {
        echo '<span class="icono">📚🖋️</span>';
        echo '<h2 class="titulo-exito">Donación Registrada</h2>';
        echo '<p class="texto-mensaje">Agradecemos profundamente su contribución. La obra <strong>' . htmlspecialchars($titulo) . '</strong> ha sido añadida y ahora consta con <strong>' . $nuevo_id_ejemplar . ' ejemplar(es)</strong> disponibles en nuestros estantes.</p>';
    } else {
        echo '<span class="icono">⚠️</span>';
        echo '<h2 class="titulo-error">Error Técnico</h2>';
        echo '<p class="texto-mensaje">No se pudo procesar el ejemplar: ' . mysqli_error($conn) . '</p>';
    }
} else {
    echo '<span class="icono">📜❓</span>';
    echo '<h2 class="titulo-error">Acceso Inválido</h2>';
    echo '<p class="texto-mensaje">El formulario no fue enviado correctamente.</p>';
}

// Botones de salida
echo '      <div class="btn-contenedor">
                <a href="index.html" class="btn btn-verde">Volver al Inicio</a>
                <a href="Formulario-Donativolibro.html" class="btn btn-marron">Donar otro Libro</a>
            </div>
    </div>
</body>
</html>';
?>