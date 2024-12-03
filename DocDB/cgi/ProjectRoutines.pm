#
# Description: These are routines that are specific to your installation and 
#              should be customized for your needs. This file is a template
#              only. Make a copy of this file as ProjectRoutines.pm (no
# "template") and make your changes there. Basically you can use ProjectHeader,
# ProjectBodyStart, ProjectFooter, and DocDBFooter to make DocDB  web pages
# just like the web pages for the rest of your project. If you don't want to do
# any customization or just want to test DocDB, these routines work as-is.
# A global variable $Public is used (when set) to remove elements from the
# nav-bars that the public has no interest in. The variable is global
# and can control the style of your headers and footers too. 
#
#      Author: Eric Vaandering (ewv@fnal.gov)
#    Modified: 

# Copyright 2001-2013 Eric Vaandering, Lynn Garren, Adam Bryant

#    This file is part of DocDB.

#    DocDB is free software; you can redistribute it and/or modify
#    it under the terms of version 2 of the GNU General Public License 
#    as published by the Free Software Foundation.

#    DocDB is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with DocDB; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

sub ProjectHeader { 
  my ($Title,$PageTitle) = @_;
  
# This routine is reponsible for whatever HTML you want to write in the <HEAD>  
# section of the page. You can embed style sheets, etc. 
#
# $Title is what is in the <title> element while $PageTitle is the title  of
# the page you may put in the text of the page. They are provided here for
# your  convenience, but you should not print the <title> here since DocDB
# already takes  care of that.

# Here is a link to a style sheet.

#   print "<link rel=\"stylesheet\" href=\"/includes/style.css\" type=\"text/css\">\n";
 print '<link rel="stylesheet" type="text/css" href="https://documents.egi.eu/export/system/modules/eu.egi.www/resources/d2/css/screen.css"  media="screen" />';
}

sub ProjectBodyStart {

# This routine is called after the <body> tag is written. Here you can put your
# project specific HTML. You might want to put the document title too, as a
# header. ($Title is what is in the <title> element while $PageTitle is the 
# title  of the page you may put in the text of the page.)

print '
<div id="container">
    <div id="head">

       <div id="site-title">
          <a class="over-image" href="/">EGI<span></span></a>
       </div>
  
       <div class="phrase over-image">
       </div>
    </div>
';

print '
    <div class="right-content">
        <div id="page-header">
';
     

  my ($Title,$PageTitle) = @_;
  my @TitleParts = split /\s+/, $PageTitle;
  $PageTitle = join '&nbsp;',@TitleParts;

  require "Images.pm";

  my ($path,$query) = @ENV{qw/SCRIPT_NAME QUERY_STRING/};
  $path =~ s/^$cgi_path//;
  $path =~ s/^\/+//;
  if ($Public) {
	$txt = qq{<b>Public area</b><br/><a href="$secure_root$path?$query">Login</a>};
	$icon = 'Unlock';
	$id = '';
  }
  else {
	if (stat("/opt/DocDB/public/$path")) {
	  $txt = qq{<b>Restricted area</b> <br/><a href="$public_root$path?$query">Logout</a>};
	} else {
	  $txt = qq{<b>Restricted area</b> <br/><a href="$public_root">Logout</a>};
	}
	$icon = 'Lock';
	$id = "Logged in as $ENV{SSL_CLIENT_S_DN_CN}";
 }

#<table style="text-align: left; width: 200px; margin-left: auto; margin-right: 0px;">
  print qq{
<table style="width: 200px; float: right;">
<tr>
<td>$txt</td>
<td>
<img src="$ImgURLPath/$ImageNames{$icon}"/>
</td>
</tr>
<tr>
<td colspan="2">$id</td>
</tr>
</table>
};

print '
          <h1>Document Server</h1>
          <div class="navigation">
              <a href="http://www.egi.eu/">Home</a> &gt; <a href="http://www.egi.eu/about/">About EGI.eu</a> &gt; <a href="http://www.egi.eu/about/intranet/">Intranet</a> &gt; <strong>DocDB</strong>
          </div><!-- end navigation -->
        </div><!-- end page-header -->
        <div class="page-content ">
';



  print "<h1>$PageTitle</h1>\n";
  # show the navbar at the top of the page as well as at the bottom
  if ($dbh) {
     &DocDBNavBar();
  }
}

sub ProjectFooter {
  require "DocDBVersion.pm";

  my ($WebMasterEmail,$WebMasterName) = @_;

# This routine is reponsible for whatever you want to put as a footer on the
# page. 
#
# Parameters are supplied for the name and e-mail address of the person
# responsible for the pages. We would appreciate it if you keep the link to 
# the DocDB home page present.

# You probably want to include some version of this:

  print "<p><small>\n";
  print "<a href=\"$DocDBHome\">DocDB</a>, ";
# print "Version $DocDBVersion, contact \n";
  print "Contact: \n";
  print "<i>\n";
  print "<a href=\"mailto:$WebMasterEmail\">$WebMasterName</a>\n";
  print "</i>\n";
  print "</small><br/>\n";
  
# This prints benchmark info for pages that have it  
  
  if ($EndTime && $StartTime) {
    my $TimeDiff = timediff($EndTime,$StartTime);
    print "<small><b>Execution time: </b>",timestr($TimeDiff),"</small>\n";
  }
  print "</p>\n";
  
# Do not print the </body> and </html> tags, DocDB does that now.

use Time::Piece;
my $t = Time::Piece->new();

print '
         </div>
        </div>
    <div class="clear"></div>
</div>
<div id="footer">
<div class="float-left">
        &copy; '.$t->year.' <strong>EGI Foundation</strong><br />
        Website hosted by CESNET, Brno on behalf of EGI.eu, <a href="mailto:contact@egi.eu">contact@egi.eu</a>

      </div>
      <div class="float-right align-right">
        <a href="http://www.egi.eu/">Disclaimers</a> &nbsp;|&nbsp;
        <a href="http://www.egi.eu/site-map/">Site map</a> &nbsp;|&nbsp;
        <a href="http://www.egi.eu/about/contact/">Contact</a> &nbsp;|&nbsp;

        <a href="http://www.egi.eu/about/">About</a><br />
      <div class="clear"></div>
</div>
';
}

sub DocDBNavBar {
  
# This routine prints the navigation bar just above the footer on the
# page. 
# This provides a good default, but you can customize for your installation 
# and include an optional extra description and URL (e.g. for a related page).


  my ($ExtraDesc,$ExtraURL) = @_;

  require "Security.pm";

  print "<div class=\"DocDBNavBar\">\n";
  if ($ExtraDesc && $ExtraURL) {
    print "[&nbsp;<a href=\"$ExtraURL\">$ExtraDesc</a>&nbsp;]&nbsp;\n";
  } 
  print "[&nbsp;<a href=\"$MainPage\">DocDB&nbsp;Home</a>&nbsp;]&nbsp;\n";
  if (&CanAdminister()) {
    print "[&nbsp;<a href=\"$AdministerHome\">Administer</a>&nbsp;]&nbsp;\n";
  }
  if (&CanCreate()) {
    print "[&nbsp;<a href=\"$DocumentAddForm?mode=add\">New</a>&nbsp;]&nbsp;\n";
  }
  print "[&nbsp;<a href=\"$SearchForm\">Search</a>&nbsp;]\n";
  print "[&nbsp;<a href=\"$ListBy?days=$LastDays\">Last&nbsp;$LastDays&nbsp;Days</a>&nbsp;]\n";
  print "[&nbsp;<a href=\"$ListAuthors\">List&nbsp;Authors</a>&nbsp;]\n";
  print "[&nbsp;<a href=\"$ListTopics\">List&nbsp;Topics</a>&nbsp;]\n";
  print "[&nbsp;<a href=\"$ListAllMeetings\">List&nbsp;Events</a>&nbsp;]\n";
  unless ($Public) {
    print "[&nbsp;<a href=\"$DocDBInstructions\">Help</a>&nbsp;]\n";
  } 
  print "</div>\n";
}

sub ProjectReferenceLink (;$$$$) {
  my ($Acronym,$Volume,$Page,$ReferenceID) = @_;

# This routine is used to add links to and optionally replace the text of 
# references specific to the project.
# See ReferenceLink in ReferenceLinks.pm for examples.

  my $ReferenceLink = "";
  my $ReferenceText = "";

  return ($ReferenceLink,$ReferenceText);
}

# Often times groups may have CSS or other files that are used in Server
# Side Includes. This function replicates that functionality
  
#sub SSInclude {
#  my ($file) = @_;
#  open SSI,"$SSIDirectory$file";
#  my @SSI_lines = <SSI>;
#  close SSI;
#  print @SSI_lines;
#}

1;
