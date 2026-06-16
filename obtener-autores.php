<?php
// obtener_autores.php
$conn = mysqli_connect("localhost", "root", "", "biblioteca");
mysqli_set_charset($conn, "utf8");

$query = "SELECT Id_autor, Nombre FROM t_autores ORDER BY Nombre ASC"; 
$result = mysqli_query($conn, $query);

$autores = [];
while ($row = mysqli_fetch_assoc($result)) {
    $autores[] = $row;
}

header('Content-Type: application/json');
echo json_encode($autores);
?>