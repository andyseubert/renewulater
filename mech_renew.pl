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
	print "patron code: $patroninfo\n";
   }else{
    	die (print "could not login.\n$card\n$pin\n$email\n $result");
    } 
$email_body = "<HTML><BODY>Renew-You-later Running for $email.<br /><br />\n\n";

#######
# print any overdue fines
#######
if ($result =~ m/<span class="loggedInMessage">You are logged into Multnomah County Library                                         \/All Locations as (SEUBERT, ANDREW JAMES)<\/span>/){
	$email_body = "$email_body"."Logged in as $1\n";
	print "Logged in as $1\n";
}
if ($result =~ m/<a href="\/patroninfo~S1\/${patroninfo}\/overdues" target="_self">(.*?)<\/a>/){
	$email_body =  "$email_body"."You have $1<br /><br />\n\n";
	print "you have $1\n";
	}

$email_body =  "$email_body"."\n\n<br /><br />Renewing...<br />\n";
$email_body = "$email_body"."<table border = 1>\n";
$email_body = "$email_body"."<tr><th> TITLE </th><th> STATUS </th></tr>\n";

## start renewal pae GET here
$req = "https://catalog.multcolib.org/patroninfo~S1/$patroninfo/items?renewall";
$mech->get("$req");
die unless ($mech->success);
$result=$mech->content();
#print $result;
#######
# OK , here we will need to parse out the patFunc tags 
#######
while ($result =~ m/<span class="patFuncTitleMain">(.*?)<\/span>/) {
#		print $result;
        @title = split (/:/, $1); ### just get the title, not the extended title.
        print "$title[0]\n";
        $email_body =  "$email_body"."<tr><td>$title[0]\n</td>";

        #remove the found text from the result so we don't find it again.
        $result =~ s/<span class="patFuncTitleMain">.*?<\/span>//;
        if ($result =~ m/<td  class="patFuncStatus" text-align:left> (DUE \d\d-\d\d-\d\d) <em>(.*?)<\/em>/){
		 				$due = "$1";
#                $email_body =  "$email_body"."<tr><td>$1</td>";
						if ($2 =~ m/<div style="color:red">(.*?)<\/div>/) { ### if overdue, special action
							$email_body =  "$email_body"."<td><font color=red> *** ALERT *** NOT RENEWED*** $1 $due<\/font></td></tr>\n";
						}else{
							$email_body =  "$email_body"."<td>$2</td></tr>\n";
						}
				    $result =~ s/<td  class="patFuncStatus" text-align:left> .*?<\/em>//;
			  }
#	$email_body =  "$email_body"."<br />\n";
}
        $email_body =  "$email_body"."</table></body></html>\n";

print "$email_body\n";
# unless(open (MAIL, "|/usr/sbin/sendmail $email"))
# {
# print "error.\n";
# warn "Error starting sendmail: $!";
# }
# else{
# print MAIL $from;
# print MAIL "To: $email\n";
# print MAIL $reply_to;
# print MAIL $subject;
# print MAIL "Content-type: text/html\n\n";
# print MAIL $email_body;
# close(MAIL) || warn "Error closing mail: $!";
# print "Mail sent\n";
# }

### added when moving to windows 08/30/2016 inside the net
use Net::SMTP;
    # Constructors
$smtp = Net::SMTP->new('mailout.collegenet.com', Timeout => 60);
$smtp->recipient($email,"andys@florapdx.com");
$smtp->mail( 'renewulater@florapdx.com' ); # use the sender's address here
$smtp->to($email); # recipient's address
$smtp->data(); # Start the mail

# Send the header.
$smtp->datasend("To: $email\n");
$smtp->datasend("Cc: andys\@florapdx.com\n");
$smtp->datasend("From: renewulater@florapdx.com\n");
$smtp->datasend("Subject: RenewUlater.\n");
# Send the body.

$smtp->datasend("MIME-Version: 1.0\n");
$smtp->datasend("Content-Type: multipart/mixed; boundary=\"frontier\"\n");
$smtp->datasend("\n--frontier\n");
$smtp->datasend("Content-Type: text/html; charset=\"UTF-8\" \n");
$smtp->datasend("$email_body\n");
$smtp->datasend("--frontier--\n");
$smtp->datasend("\n");
$smtp->dataend(); # Finish sending the mail
$smtp->quit; # Close the SMTP connection

print "Success for $email.\n";



