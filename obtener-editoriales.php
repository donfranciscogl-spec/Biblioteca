<?php
// obtener_editoriales.php
$conn = mysqli_connect("localhost", "root", "", "biblioteca"); //
mysqli_set_charset($conn, "utf8");

$query = "SELECT Id_editorial, Nombre FROM t_editorial ORDER BY Nombre ASC"; //
$result = mysqli_query($conn, $query);

$editoriales = [];
while ($row = mysqli_fetch_assoc($result)) {
    $editoriales[] = $row;
}

// Devolvemos los datos en formato JSON para que JavaScript los entienda
header('Content-Type: application/json');
echo json_encode($editoriales);
?> 