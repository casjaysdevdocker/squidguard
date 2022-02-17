#!/usr/bin/env perl

$allow_html_code = 0;
&ReadEnvs;

$deniedurl = $in{'DENIEDURL'};
$reason = $in{'REASON'};
$user = $in{'USER'};
$ip = $in{'IP'};
$cats = $in{'CATEGORIES'};

$host = $in{'HOST'};

$fbypasshash = $in{'GBYPASS'};  #
$ibypasshash = $in{'GIBYPASS'}; #
$hashflag = $in{'HASH'};        #

print "Content-type: text/html\n\n";
print '<HTML><link rel="stylesheet" href="/css/proxy.css" />';
print '<HEAD><TITLE>Access Denied</TITLE></HEAD>';
print '<BODY><CENTER><H2>ACCESS HAS BEEN DENIED</H2>';
print '<img src="/images/blocked.png" alt="Access Denied" />';
if (length($user) > 0) {
  print "<br><em>$user</em>, access to the page:<p>";
}
else {
  print '<br>Access to the page:<p>';
}
print "<strong><a href=\"$deniedurl\">$deniedurl</a></strong>";
print '<p>... has been denied for the following reason:<p>';
print "<strong>$reason</font></strong>";
if (length($cats) > 0) {
  print '<p>Categories:<p>';
  print "<strong>$cats</font></strong>";
}
print '<p>Your username, IP address, date, time and URL have been logged.';
print '<p><table border=1><tr><td>You are seeing this error because the page you attempted<br>';
print 'to access contains, or is labelled as containing, material that';
print '<br>has been deemed inappropriate.</td></tr></table>';
print '<p><table border=1><tr><td>';
print 'If you have any queries contact your <a href="mailto:admin@proxy.casjay.net?subject=Banned -IP-">Proxy Administrator</td></tr></table>';
print '<p><font size=-3>Powered by <a href="http://proxy.casjay.net" target="_blank">Casjays Developments Proxy Server</a></font>';
print '</center></BODY></HTML>';

exit;


sub ReadEnvs {
  local($cl, @clp, $pair, $name, $value);
  if ( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
    read(STDIN, $cl, $ENV{'CONTENT_LENGTH'} );
  }
  else {
    $cl = $ENV{'QUERY_STRING'};
  }
  @clp = split(/::/, $cl);
  foreach $pair (@clp) {
    ($name, $value) = split(/==/, $pair);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $value =~ s/<!--(.|\n)*-->//g;
    if ($allow_html_code != 1) {
      $value =~ s/<([^>]|\n)*>//g;
    }
    $in{$name} = $value;
  }
}
