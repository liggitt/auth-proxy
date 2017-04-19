<?php

$then = $_REQUEST["then"] ?: "/";
header("HTTPDSession: httpd_user=", true);
header("Location: " . $then, true, 302);

?>