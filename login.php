<?php
$user        = apache_getenv("REMOTE_USER");
$error       = apache_getenv("EXTERNAL_AUTH_ERROR");
$csrf_cookie = $_COOKIE["csrf"]  ?: "";
$csrf_form   = $_POST["csrf"]    ?: "";
$then        = $_REQUEST["then"] ?: "/";
if (!empty($user) && $csrf_cookie == $csrf_form) {
        header("HTTPDSession: httpd_user=" . urlencode($user), true);
        header("Location: " . $then, true, 302);
        exit;
}
?><!DOCTYPE html>
<html>
  <head>
    <title>Log In</title>
    <style>
        body   { margin-top: 5em; font-family: sans-serif;}
        form   { display: inline-block; margin: 0 auto; }
        label  { display: inline-block; width: 100px; text-align: right; }
        input  { display: inline-block; width: 200px; }
        button { width: 200px; }
        .row   { margin-top: 10px;}
        .error { color: red; }
    </style>
  </head>
  <body>
    <form action="" method="POST">
      <div class="error"><?php echo htmlspecialchars($error) ?></div>
      <input name="then" type="hidden" value="<?php echo htmlspecialchars($then) ?>">
      <input name="csrf" type="hidden" value="<?php echo htmlspecialchars($csrf_cookie) ?>">
      <div class="row">
        <label for="inputUsername">Username:</label>
        <input id="inputUsername" autofocus="autofocus" name="httpd_username" type="text" value="<?php echo htmlspecialchars($_POST["httpd_username"]) ?>">
      </div>
      <div class="row">
        <label for="inputPassword">Password:</label>
          <input id="inputPassword" name="httpd_password" value="" type="password">
      </div>
      <div class="row">
        <button type="submit" name="login" value="Log In">Log In</button>
      </div>
    </form>
  </body>
</html>
