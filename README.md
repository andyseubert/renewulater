Introduction
--
It does not have to, but was running this on a raspberry pi. now it's running on a virtual private server.

Install
--
Dependencies
---
Perl
Perl libs
www-mechanize
apt-get install libwww-mechanize-perl
local MAIL command
ssmtp is a good choice if you like to send through the googles
http://wiki.debian.org/sSMTP

Configure
--
set up SSMTP per instructions http://wiki.debian.org/sSMTP
edit the file mech_renew.pl
$reply_to = "Reply-to: yourname\@yourdomain.com\n";
$from = "From: yourname\@yourdomain.com\n";
$smtpfrom = "yourname\@yourdomain.com";
$subject = "Subject: RenewuLater Report\n";

Usage
--
the script is called "mech_renew.pl"
Please call this script with 3 arguments:
mech_renew.pl <CARD#> <PIN> <EMAIL>

Scheduling with cron
--
create a bash script like 'renew.sh' containing the command shown above then call that shell script from crontab:
30 15 * * 3 /home/username/renewulater/renew.sh
