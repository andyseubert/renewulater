#! /usr/bin/perl


my $usage = "Please call this script with 3 arguments: renulater <CARD#> <PIN> <EMAIL>\n";
if ($#ARGV != 2) {
	die("$usage");
}

use WWW::Mechanize;

my $resultfile;
my $patroninfo;
my $email_body;
my $reply_to = "Reply-to: andys\@florapdx.com\n";
my $from = "From: renewer\@florapdx.com\n";
my $smtpfrom = "andys\@florapdx.com";
my $subject = "Subject: Renewulater Action. \n";
my @title;
my $due;
####### pull these in from the arguments given:
my $card;
my $pin;
my $email;

$card = $ARGV[0];
$pin = $ARGV[1];
$email=$ARGV[2];
#$email =~ s/\@/\\\@/;
my $mech=WWW::Mechanize->new(autocheck =>1);
$mech->get("https://catalog.multcolib.org/patroninfo~S1");
die "Can't even get the home page: ", $mech->response->status_line
        unless $mech->success;
#print $mech->content;
$mech->submit_form(
	form_name => "patform",
	fields =>{
		code =>$card,
		pin =>$pin
		}
	);
die unless ($mech->success);
my $result=$mech->content();
#######
# we need to grep out the patroninfo number
#######

#print "\n\n\n";
if ( $result =~ m/<a href="\/patroninfo\~S1\/(\d{7})/ ){ #"
	$patroninfo = $1;
#	print "$patroninfo\n";
   }else{
    	die (print "could not login.\n$card\n$pin\n$email\n $result");
    } 
$email_body = "<HTML><BODY>Renew-You-later Running for $email.<br /><br />\n\n";

#######
# print any overdue fines
#######

if ($result =~ m/<a href="\/patroninfo\/${patroninfo}\/overdues" onClick="return replace_or_redraw\( '\/patroninfo\/${patroninfo}\/overdues' \)">(.*?)<\/a>/){
	$email_body =  "$email_body"."You have $1<br /><br />\n\n";
	}

$email_body =  "$email_body"."\n\n<br /><br />Renewing...<br />\n";
$email_body = "$email_body"."<table border = 1>\n";
$email_body = "$email_body"."<tr><th> TITLE </th><th> STATUS </th></tr>\n";
$req = "https://catalog.multcolib.org/patroninfo/$patroninfo/items?renewall";
$mech->get("$req");
die unless ($mech->success);
$result=$mech->content();
#print $result;
#######
# OK , here we will need to parse out the patFunc tags 
#######
while ($result =~ m/.*?<td align="left" class="patFuncTitle">.*?<a href=.*?>(.*?)<\/a>/) {
	#	print $result;
        @title = split (/:/, $1); ### just get the title, not the extended title.
  #      print $title[0];
        $email_body =  "$email_body"."<tr><td>$title[0]\n</td>";

        #remove the found text from the result so we don't find it again.
        $result =~ s/.*?<td align="left" class="patFuncTitle">.*?<a href=.*?>.*?<\/a>//;
        if ($result =~ m/<td align="left" class="patFuncStatus"> (DUE \d\d-\d\d-\d\d) <em>(.*?)<\/em>/){
		 				$due = "$1";
#                $email_body =  "$email_body"."<tr><td>$1</td>";
						if ($2 =~ m/<font color="red">(.*?)<\/font>/) { ### if overdue, special action
							$email_body =  "$email_body"."<td><font color=red> *** ALERT *** NOT RENEWED*** $1 $due<\/font></td></tr>\n";
						}else{
							$email_body =  "$email_body"."<td>$2</td></tr>\n";
						}
				    $result =~ s/<td align="left" class="patFuncStatus"> .*?<\/em>//;
			  }
#	$email_body =  "$email_body"."<br />\n";
}
        $email_body =  "$email_body"."</table></body></html>\n";
unless(open (MAIL, "|/usr/sbin/sendmail $email"))
{
print "error.\n";
warn "Error starting sendmail: $!";
}
else{
print MAIL $from;
print MAIL "To: $email\n";
print MAIL $reply_to;
print MAIL $subject;
print MAIL "Content-type: text/html\n\n";
print MAIL $email_body;
close(MAIL) || warn "Error closing mail: $!";
print "Mail sent\n";
}

print "Success for $email.\n";



