#        Name: $RCSfile$
# Description: Subroutines to provide various parts of HTML about documents
#
#    Revision: $Revision$
#    Modified: $Author$ on $Date$
#
#      Author: Eric Vaandering (ewv@fnal.gov)

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

require "HTMLUtilities.pm";

sub DocumentTable (%) {
  require "DocumentSQL.pm";
  require "RevisionSQL.pm";
  require "Security.pm";
  require "Sorts.pm";
  require "DocDBFields.pm";

  require "AuthorHTML.pm";
  require "RevisionHTML.pm";
  require "ResponseElements.pm";

  my %Params = @_;

  my $SortBy          =   $Params{-sortby};
  my $Reverse         =   $Params{-reverse};
  my $MaxDocs         =   $Params{-maxdocs};
  my $NoneBehavior    =   $Params{-nonebehavior} || "skip";  # skip|
  my $TalkID          =   $Params{-talkid} || 0;
  my $SkipVersions    =   $Params{-skipversions} || $False;
  my @DocumentIDs     = @{$Params{-docids}};
  my @SessionOrderIDs = @{$Params{-sessionorderids}};
  my %FieldList       = %{$Params{-fieldlist}};

  my @IDs  = ();
  my $Mode;

  if (@SessionOrderIDs) {
    @IDs  = @SessionOrderIDs;
    $Mode = "SessionOrder";
  } elsif (@DocumentIDs) {
    @IDs  = @DocumentIDs;
    $Mode = "Document";
  }

  unless (@IDs) {
    if ($NoneBehavior eq "skip") {
      return;
    }
  }

### Write out the beginning and header of table

  %SortFields = %FieldList;
  my @Fields = sort FieldsByColumn keys %FieldList;
  %SortFields = ();

  print qq(<table id="DocumentTable" class="Alternating DocumentList tablesorter">\n);

  print "<thead><tr>\n";
  my $LastRow = 1;
  foreach my $Field (@Fields) {
    if ($Public && $PublicSkipFields{$Field}) {
      next; # Skip headers for fields which public should never see
    }
    my $Column  = $FieldList{$Field}{Column};
    my $Row     = $FieldList{$Field}{Row};
    my $RowSpan = $FieldList{$Field}{RowSpan};
    my $ColSpan = $FieldList{$Field}{ColSpan};

    if ($Row != $LastRow) {
      $LastRow = $Row;
      print "</tr><tr>\n";
    }

    # Construct and print <th></th>

    my $TH = "<th";
    if ($RowSpan > 1) {$TH .= qq( rowspan="$RowSpan");}
    if ($ColSpan > 1) {$TH .= qq( colspan="$ColSpan");}
    $TH .= " class=\"$Field\">";
    print "$TH",$FieldTitles{$Field},"</th>\n";
  }
  print "</tr></thead><tbody>\n";

### Sort document IDs, reverse from convention if needed

  if ($Mode eq "Document") {
    # Fetch all documents so sorts have info
    foreach my $DocumentID (@IDs) {
      my $Version = &LastAccess($DocumentID);
      if ($Version == -1) {next;}
      my $DocRevID = &FetchRevisionByDocumentAndVersion($DocumentID,$Version);
    }

    # Sort and reverse
    if ($SortBy eq "docid") {
      @IDs = sort numerically @IDs;
    } elsif ($SortBy eq "date") {
      @IDs = sort DocumentByRevisionDate @IDs;
    } elsif ($SortBy eq "doctitle") {
      @IDs = sort DocumentByTitle @IDs;
    } elsif ($SortBy eq "requester") {
      @IDs = sort DocumentByRequester @IDs;
    } elsif ($SortBy eq "firstauthor") {
      @IDs = sort DocumentByFirstAuthor @IDs;
    } elsif ($SortBy eq "confdate") {
      @IDs = sort DocumentByConferenceDate @IDs;
    } elsif ($SortBy eq "relevance") {
      @IDs = sort DocumentByRelevance @IDs;
    }

    if ($Reverse) {
      @IDs = reverse @IDs;
    }
  }

### Loop over Document/SessionOrder IDs

  my $NumberOfDocuments = 0;
  my $RowClass;
  foreach my $ID (@IDs) {
    my $DocumentID      = 0;
    my $SessionOrderID  = 0;
    my $SessionTalkID   = 0;
    my $TalkSeparatorID = 0;
    my $Unconfirmed = $FALSE;
    if ($Mode eq "Document") {
      $DocumentID = $ID;
    } elsif ($Mode eq "SessionOrder") {
      $SessionOrderID = $ID;
      if ($SessionOrders{$SessionOrderID}{TalkSeparatorID}) {
        $TalkSeparatorID = $SessionOrders{$SessionOrderID}{TalkSeparatorID};
      }
      if ($SessionOrders{$SessionOrderID}{SessionTalkID}) {
        $SessionTalkID = $SessionOrders{$SessionOrderID}{SessionTalkID};
        $DocumentID    = $SessionTalks{$SessionTalkID}{DocumentID};
        if ($DocumentID && !$SessionTalks{$SessionTalkID}{Confirmed}) {
          $Unconfirmed = $TRUE;
        }
      }
    }

### Which version (if any) can they view (Move into document mode section?)
    my $Version  = LastAccess($DocumentID);
    if ($Version == -1 && $Mode eq "Document") {next;}
    my $DocRevID = FetchRevisionByDocumentAndVersion($DocumentID,$Version);
    ++$NumberOfDocuments;

    if ($MaxDocs && $NumberOfDocuments > $MaxDocs) {
      last;
    }

### Print fields requested
    if ($NumberOfDocuments % 2) {
      $RowClass = "Odd";
    } else {
      $RowClass = "Even";
    }
    if ($Unconfirmed) {
      $RowClass .= " Unconfirmed";
    }
    print "<tr>\n";
    my $LastRow = 1;
    foreach my $Field (@Fields) {
      if ($Public && $PublicSkipFields{$Field}) {
        next; # Skip contents for fields which public should never see
      }
      my $Column  = $FieldList{$Field}{Column};
      my $Row     = $FieldList{$Field}{Row};
      my $RowSpan = $FieldList{$Field}{RowSpan};
      my $ColSpan = $FieldList{$Field}{ColSpan};

      if ($Row != $LastRow) {
        $LastRow = $Row;
        print "</tr><tr>\n";
      }

      my $TD = qq(<td class="$Field");
      if ($RowSpan > 1) {$TD .= qq( rowspan="$RowSpan");}
      if ($ColSpan > 1) {$TD .= qq( colspan="$ColSpan");}
      $TD .= ">";
      print $TD;

      if      ($Field eq "Docid") {    # Document number
        print DocumentLink(-docid => $DocumentID, -version => $Version,
                                -numwithversion => $TRUE);
      } elsif ($Field eq "Title") {    # Document title
        if ($DocumentID) {
          print DocumentLink(-docid => $DocumentID, -version => $Version,
                                  -titlelink => $TRUE);
        } elsif ($TalkSeparatorID) { # TalkSeparator
          print "$TalkSeparators{$TalkSeparatorID}{Title}";
        } elsif ($SessionTalkID) { # TalkSeparator
          print "$SessionTalks{$SessionTalkID}{HintTitle}";
        }
      } elsif ($Field eq "Author") {   # Single author (et al.)
        require "TalkHintSQL.pm";
        if ($DocRevID) {
          print FirstAuthor($DocRevID);
        } elsif ($SessionTalkID) {
          my @AuthorHintIDs = FetchAuthorHintsBySessionTalkID($SessionTalkID);
          my @AuthorIDs = ();
          foreach my $AuthorHintID (@AuthorHintIDs) {
            push @AuthorIDs,$AuthorHints{$AuthorHintID}{AuthorID};
          }
          print AuthorListByID({ -listformat => "br", -authorids => \@AuthorIDs });
        }
      } elsif ($Field eq "AuthorInst") {   # Single author (et al.)
        require "TalkHintSQL.pm";
        if ($DocRevID) {
          print FirstAuthor($DocRevID, {-institution => $TRUE} );
        } elsif ($SessionTalkID) {
          my @AuthorHintIDs = FetchAuthorHintsBySessionTalkID($SessionTalkID);
          my @AuthorIDs = ();
          foreach my $AuthorHintID (@AuthorHintIDs) {
            push @AuthorIDs,$AuthorHints{$AuthorHintID}{AuthorID};
          }
          print AuthorListByID({ -listformat => "br", -authorids => \@AuthorIDs });
        }
      } elsif ($Field eq "Updated") {  # Date of last update
        print EuroDate($DocRevisions{$DocRevID}{DATE});
      } elsif ($Field eq "Created") {  # Date of creation
        print EuroDate($Documents{$DocumentID}{Date});
      } elsif ($Field eq "CanSign") {  # Who can sign document
        require "SignoffUtilities.pm";
        require "SignoffHTML.pm";
        my @EmailUserIDs = ReadySignatories($DocRevID);
        foreach my $EmailUserID (@EmailUserIDs) {
          print SignatureLink($EmailUserID),"<br/>\n";
        }
      } elsif ($Field eq "Conference" || $Field eq "Events") {
        PrintEventInfo(-docrevid => $DocRevID, -format => "short");
      } elsif ($Field eq "LongEvents") {
        PrintEventInfo(-docrevid => $DocRevID, -format => "description");
      } elsif ($Field eq "Topics") {  # Topics for document
        require "TopicHTML.pm";
        require "TopicSQL.pm";
        require "TalkHintSQL.pm";
        my @TopicIDs = ();
        if ($DocRevID) {
          @TopicIDs = GetRevisionTopics( {-docrevid => $DocRevID} );
        } elsif ($SessionTalkID) {
          my @TopicHintIDs  = FetchTopicHintsBySessionTalkID($SessionTalkID);
          foreach my $TopicHintID (@TopicHintIDs) {
            push @TopicIDs,$TopicHints{$TopicHintID}{TopicID};
          }
        }
        print TopicListByID( {-topicids => \@TopicIDs, -listformat => "br"} );
      } elsif ($Field eq "Abstract") { # Abstract
        PrintAbstract($DocRevisions{$DocRevID}{Abstract}, {-format => "bare"} );
      } elsif ($Field eq "DocNotes") { # Notes and Changes
        print SmartHTML({-text=>$DocRevisions{$DocRevID}{Note}, -addLineBreaks=>$TRUE, -makeURLs=>$TRUE});
      } elsif ($Field eq "Files") {    # Files in document
        require "FileHTML.pm";
        ShortFileListByRevID($DocRevID, $SkipVersions);
      } elsif ($Field eq "Confirm") {
        print $query -> start_multipart_form('POST',$ConfirmTalkHint);
        print "<div>\n";
        print $query -> hidden(-name => 'documentid',    -default => $DocumentID);
        print $query -> hidden(-name => 'sessiontalkid', -default => $TalkID);
        print $query -> submit (-value => "Confirm");
        print "</div>\n";
        print $query -> end_multipart_form;
      } elsif ($Field eq "References") {   # Journal refs
        require "RevisionHTML.pm";
        PrintReferenceInfo($DocRevID,"short");
      } elsif ($Field eq "TalkTime") {
        if ($SessionOrderID) {
          print "<strong>",TruncateSeconds($SessionOrders{$SessionOrderID}{StartTime}),"</strong>";
        } else {
          print "";
        }
      } elsif ($Field eq "TalkLength") {
        if ($SessionTalkID) {
          print TruncateSeconds($SessionTalks{$SessionTalkID}{Time});
        } elsif ($TalkSeparatorID) {
          print TruncateSeconds($TalkSeparators{$TalkSeparatorID}{Time});
        } else {
          print "";
        }
      } elsif ($Field eq "TalkNotes") {
        if ($SessionTalkID) {
          print SmartHTML({-text=>$SessionTalks{$SessionTalkID}{Note}, -addLineBreaks=>$TRUE, -makeURLs=>$TRUE});
        } elsif ($TalkSeparatorID) {
          print SmartHTML({-text=>$TalkSeparators{$TalkSeparatorID}{Note}, -addLineBreaks=>$TRUE, -makeURLs=>$TRUE});
        }
      } elsif ($Field eq "Edit") {
        if ($SessionOrderID) {
          print TalkNoteLink($SessionOrderID);
        } elsif ($DocumentID) {
          print DocumentUpdateLink( {-docid => $DocumentID} );
        }
      } elsif ($Field eq "Blank") {        # Blank Cell
        print "";
      } else {
        print "Unknown field: $Field"
      }
      print "</td>\n";
    }
    print "</tr>\n";
  }

### End table, return

  print "</tbody></table>\n";

  return $NumberOfDocuments;
}

sub DocumentLink (%) {
  require "DocumentSQL.pm";
  require "RevisionSQL.pm";
  require "ResponseElements.pm";
  require "Security.pm";

  my %Params = @_;

  my $DocumentID       = $Params{-docid};
#  my $DocRevID         = $Params{-docrevid}; #FIXME
  my $DocIDOnly        = $Params{-docidonly}        || 0;
  my $NumWithVersion   = $Params{-numwithversion}   || 0;
  my $NoVersion        = $Params{-noversion}        || 0;
  my $TitleLink        = $Params{-titlelink}        || 0;
  my $LinkText         = $Params{-linktext}         || "";
  my $NoApprovalStatus = $Params{-noapprovalstatus} || 0;

# Treat Version special since v0 is valid and we don't know the last version # until later

  my $Version = "latest";
  if (defined $Params{-version}) {
    $Version = $Params{-version};
  }

  FetchDocument($DocumentID);
  if ($Version eq "latest") {
    $Version      = $Documents{$DocumentID}{NVersions};
  }

  my $DocRevID  = FetchRevisionByDocumentAndVersion($DocumentID,$Version);
  unless ($DocRevID) {
    return "";
  }
  my $FullDocID = FullDocumentID($DocumentID,$Version);
  my $CanAccess = CanAccess($DocumentID,$Version);

  my $Link;
  my $EndElement = '</a>';
  if ($CanAccess) {
    $Link .= "<a href=\"$ShowDocument\?docid=$DocumentID";
    if ($Version != $Documents{$DocumentID}{NVersions}) { # For other than last one
      $Link .= "&amp;version=$Version";
    }
    $Link .= "\"";
    $Link .= " title=\"$FullDocID\"";
    $Link .= ">";
  } else {
    $Link .= '<span class="PrivateDocument">';
    $EndElement = '</span>';
  }

  if ($LinkText) {            # User specifies text
    $Link .= $LinkText;
    $Link .= $EndElement;
  } elsif ($DocIDOnly) {      # Like 1234
    $Link .= $DocumentID;
    $Link .= $EndElement;
  } elsif ($NumWithVersion) { # Like 1234-v56
    $Link .= $DocumentID."-v".$Version;
    $Link .= $EndElement;
  } elsif ($TitleLink) {      # Use the document Title
    $Link .= SmartHTML({-text => $DocRevisions{$DocRevID}{Title} });
    $Link .= $EndElement;
    if ($UseSignoffs && !$NoApprovalStatus) { # Put document status on next line
      require "SignoffUtilities.pm";
      require "SignoffSQL.pm";
      require "SQLUtilities.pm";
      my ($ApprovalStatus,$LastApproved) = RevisionStatus($DocRevID);
      unless ($ApprovalStatus eq "Unmanaged") {
        $Link .= "<br/>($ApprovalStatus";
        if($ApprovalStatus eq "Approved") {
          my $LastApproved = RevisionSignoffDate($DocRevID);
          my $ApprovalDateTime = ConvertToDateTime({-MySQLTimeStamp => $LastApproved, });
          my $ApprovalTime  = DateTimeString({ -DateTime => $ApprovalDateTime, -ShowTime => $FALSE, });
          $Link .= " - $ApprovalTime";
        } elsif ($ApprovalStatus eq "Unapproved") {
          if (defined $LastApproved) {
            my $DocumentID = $DocRevisions{$LastApproved}{DOCID};
            my $Version    = $DocRevisions{$LastApproved}{Version};
            my $LastLink   = DocumentLink(-docid    => $DocumentID, -version => $Version,
                                               -linktext => "version $Version", -noapprovalstatus => $TRUE,); # Will Recurse
            $Link .= " - Last approved: $LastLink";
          } else {
            $Link .= " - No approved version";
          }
        }
        $Link .= ")";
      }
    }
  } elsif ($NoVersion) {      # Like Project-doc-1234
    $Link .= FullDocumentID($DocumentID);
    $Link .= $EndElement;
  } else {                    # Like Project-doc-1234-v56
    $Link .= FullDocumentID($DocumentID,$Version);
    $Link .= $EndElement;
  }
  return $Link;
}

sub PrintDocNumber { # And type
  my ($DocRevID) = @_;
  # XXX: EGI Add permalink
  print "<dt>Permalink:</dt>";
  print "<dd style=\"word-wrap: break-word;\">";
  print "<a style=\"font-size: xx-small;\" href=\"${web_root}document/",$DocRevisions{$DocRevID}{DOCID},"\">","${web_root}document/",$DocRevisions{$DocRevID}{DOCID},"</a>";
  print "</dd>\n";

  print "<dt>Document #:</dt>";
  print "<dd>";
  print (&FullDocumentID($DocRevisions{$DocRevID}{DOCID}));
  print "-v$DocRevisions{$DocRevID}{Version}";
  print "</dd>\n";

  print "<dt>Document type:</dt>";
  my $type_link = &TypeLink($DocRevisions{$DocRevID}{DocTypeID},"short");
  print "<dd>$type_link</dd>\n";
}

sub FieldListChooser (%) {
  my %Params = @_;

  require "DocDBFields.pm";
  require "FormElements.pm";

  my $Partition = $Params{-partition};

  if ($Partition == 1) {
    print "<tr>\n";
    print "<th>",FormElementTitle(-helplink => "customlist", -helptext => "Field",      -nocolon => $TRUE),"</th>\n";
    print "<th>",FormElementTitle(-helplink => "customlist", -helptext => "Row",        -nocolon => $TRUE),"</th>\n";
    print "<th>",FormElementTitle(-helplink => "customlist", -helptext => "Column",     -nocolon => $TRUE),"</th>\n";
    print "<th>",FormElementTitle(-helplink => "customlist", -helptext => "Row(s)",     -nocolon => $TRUE),"</th>\n";
    print "<th>",FormElementTitle(-helplink => "customlist", -helptext => "Columns(s)", -nocolon => $TRUE),"</th>\n";
    print "</tr>\n";
  }

  my %FormFields = %FieldDescriptions;

  $FormFields{xxxx}  = "-- Select a Field --";      # Add option for nothing

  my @Fields = sort keys %FormFields;

  print "<tr>";
  print "<td>\n";
  print $query -> popup_menu (-name => "field$Partition",   -values => \@Fields, -default => "xxxx", -labels => \%FormFields);
  print "</td>\n";
  print "<td>\n";
  print $query -> popup_menu (-name => "row$Partition",     -values => [1..15],  -default => 1);
  print "</td>\n";
  print "<td>\n";
  print $query -> popup_menu (-name => "col$Partition",     -values => [1..15],  -default => $Partition);
  print "</td>\n";
  print "<td>\n";
  print $query -> popup_menu (-name => "rowspan$Partition", -values => [1..10],   -default => 1);
  print "</td>\n";
  print "<td>\n";
  print $query -> popup_menu (-name => "colspan$Partition", -values => [1..10],   -default => 1);
  print "</td>\n";
  print "</tr>";

  return
}

sub DocumentUpdateLink ($) {
  my ($ArgRef) = @_;

  my $DocID = exists $ArgRef->{-docid} ? $ArgRef->{-docid} : 0;
  # Add option for update/updatedb if needed

  require "Security.pm";

  if (CanModify($DocID)) {
    return qq{<a href="$DocumentAddForm?docid=$DocID&amp;mode=update">Update</a>};
  }
}


1;
