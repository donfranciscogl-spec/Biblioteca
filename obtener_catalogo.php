<?php
// obtener_catalogo.php
$conn = mysqli_connect("localhost", "root", "", "biblioteca");
mysqli_set_charset($conn, "utf8");

// Consulta que une libros, autores y ejemplares disponibles (disponible = 1)
$query = "
    SELECT l.Titulo, a.Nombre AS Autor, COUNT(e.id_ejemplar) AS Cantidad
    FROM t_libro l
    JOIN t_autores a ON l.id_autor = a.Id_autor
    LEFT JOIN t_ejemplar e ON l.Id_libro = e.id_libro AND e.disponible = 1
    GROUP BY l.Id_libro
    ORDER BY Cantidad DESC, l.Titulo ASC
    LIMIT 10
";

$result = mysqli_query($conn, $query);

$libros = [];
while ($row = mysqli_fetch_assoc($result)) {
    $libros[] = $row;
}

// Devolvemos el resultado en formato JSON para que JavaScript lo procese
header('Content-Type: application/json');
echo json_encode($libros);
?>