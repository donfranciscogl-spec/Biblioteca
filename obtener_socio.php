<?php
// obtener_socio.php
$conn = mysqli_connect("localhost", "root", "", "biblioteca");
mysqli_set_charset($conn, "utf8");

$dni = mysqli_real_escape_string($conn, $_GET['dni'] ?? '');

if (!$dni) {
    echo json_encode(['error' => 'DNI no proporcionado']);
    exit;
}

// 1. Buscamos los datos básicos del socio
$sql_socio = "SELECT id_socio, nombre, Email, telefono, año_nacimiento FROM t_socio WHERE dni = '$dni' LIMIT 1";
$res_socio = mysqli_query($conn, $sql_socio);

if (mysqli_num_rows($res_socio) == 0) {
    echo json_encode(['error' => 'Socio no encontrado']);
    exit;
}

$socio = mysqli_fetch_assoc($res_socio);
$id_s = $socio['id_socio'];

// 2. Calculamos estadísticas
// Libros que tiene actualmente (no devueltos)
$sql_actuales = "SELECT COUNT(*) as total FROM t_prestamo WHERE id_socio = $id_s AND fecha_devolucion IS NULL";
$res_actuales = mysqli_query($conn, $sql_actuales);
$total_actuales = mysqli_fetch_assoc($res_actuales)['total'];

// Total histórico de libros prestados
$sql_historico = "SELECT COUNT(*) as total FROM t_prestamo WHERE id_socio = $id_s";
$res_historico = mysqli_query($conn, $sql_historico);
$total_historico = mysqli_fetch_assoc($res_historico)['total'];

// Listado de títulos pendientes
$sql_lista = "SELECT l.Titulo FROM t_prestamo p JOIN t_libro l ON p.id_libro = l.Id_libro 
              WHERE p.id_socio = $id_s AND p.fecha_devolucion IS NULL";
$res_lista = mysqli_query($conn, $sql_lista);
$libros_pendientes = [];
while($row = mysqli_fetch_assoc($res_lista)) {
    $libros_pendientes[] = $row['Titulo'];
}

// 3. Empaquetamos todo
$respuesta = [
    'nombre' => $socio['nombre'],
    'email' => $socio['Email'],
    'telefono' => $socio['telefono'],
    'nacimiento' => $socio['año_nacimiento'],
    'actuales' => $total_actuales,
    'historico' => $total_historico,
    'lista_pendientes' => $libros_pendientes
];

header('Content-Type: application/json');
echo json_encode($respuesta);
?>