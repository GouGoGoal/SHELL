
<?php

define('SYSTEM_ROOT', dirname(preg_replace('@\\(.*\\(.*$@', '', preg_replace('@\\(.*\\(.*$@', '', __FILE__))) . '/');
session_start();
date_default_timezone_set('Asia/Shanghai');
header('Content-Type: text/html; charset=UTF-8');

if(!@$_SESSION['rand_session']){
		$rand_session=md5(uniqid().rand(1,1000));
		$_SESSION['rand_session']=$rand_session;
		exit("<!DOCTYPE HTML>
		<html>
		<head>
		<meta charset=\"UTF-8\"/>
		<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, maximum-scale=1\" />

		<title>安全检查中...</title>
	 <script> var i = 3; 
  var intervalid; 
  intervalid = setInterval(\"fun()\", 1000); 
function fun() { 
if (i == 0) { 
window.location.reload();
clearInterval(intervalid); 
} 
document.getElementById(\"mes\").innerHTML = i; 
i--; 
} 
</script> 
<style>
	html, body {width: 100%; height: 100%; margin: 0; padding: 0;}
    body {background-color: #ffffff; font-family: Helvetica, Arial, sans-serif; font-size: 100%;}
    h1 {font-size: 1.5em; color: #404040; text-align: center;}
    p {font-size: 1em; color: #404040; text-align: center; margin: 10px 0 0 0;}
    #spinner {margin: 0 auto 30px auto; display: block;}
    .attribution {margin-top: 20px;}
  </style>
  </head>
<body>
  <table width=\"100%\" height=\"100%\" cellpadding=\"20\">
    <tr>
      <td align=\"center\" valign=\"middle\">
    <noscript><h2>请打开浏览器的javascript，然后刷新浏览器</h2></noscript>
  <h1><span data-translate=\"checking_browser\">浏览器安全检查中...</span></h1>
    <p data-translate=\"process_is_automatic\"></p>
    <p data-translate=\"allow_3_secs\">还剩 <span id=\"mes\">3</span> 秒</p>
  </div>
</div>
  </td>
    </tr>
</table></body></html>");}
