# Description: Routines to determine various levels of access to meetings  
#              and sessions based on group names, MeetingIDs, etc.
#
#      Author: Eric Vaandering (ewv@fnal.gov)
#    Modified: 

# Copyright 2001-2004 Eric Vaandering, Lynn Garren, Adam Bryant

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
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

sub CanAccessMeeting ($) {
  require "SecuritySQL.pm";
  require "MeetingSecuritySQL.pm";
  
  my ($ConferenceID) = @_;
  
  my $CanAccessMeeting = 0;

  # Find out group IDs of those who can access this meeting and of the
  # current user
  
  my @MeetingSecurityIDs = &GetMeetingSecurityGroups($ConferenceID);
  my @MeetingGroupIDs  = ();
  
  unless (@MeetingSecurityIDs) { # There are no entries, so meeting is public
    $CanAccessMeeting = 1;
    return $CanAccessMeeting;
  }
    
  my $SecurityGroupID = &FetchSecurityGroupByName($remote_user);

  foreach my $MeetingSecurityID (@MeetingSecurityIDs) {
    my $MeetingGroupID = $MeetingModify{$MeetingSecurityID}{GroupID};
    push @MeetingGroupIDs,$MeetingGroupID; # Needed later by subordinates
    if ($SecurityGroupID == $MeetingGroupID) { 
      $CanAccessMeeting = 1;
    }  
  }

  if ($CanAccessMeeting) {
    return $CanAccessMeeting; # User can access directly, so let them
  }  

  # If not approved yet, see if they are the parent to a group that is

  &GetSecurityGroups(); # Pull out the big guns
  
  my @HierarchyIDs = keys %GroupsHierarchy;
  foreach my $HierarchyID (@HierarchyIDs) {
    $ParentID = $GroupsHierarchy{$HierarchyID}{Parent}; 
    $ChildID  = $GroupsHierarchy{$HierarchyID}{Child}; 
    if ($ParentID == $SecurityGroupID) { # I am the parent
      foreach my $MeetingGroupID (@MeetingGroupIDs) { 
        if ($MeetingGroupID == $ChildID) {
          $CanAccessMeeting = 1;                           
        }  
      }
    }  
  }

  return $CanAccessMeeting;
}

sub CanModifyMeeting ($) {
  require "SecuritySQL.pm";
  require "MeetingSecuritySQL.pm";

  my ($ConferenceID) = @_;
  
  if ($Public || !(&CanCreateMeeting())) {
    return 0; # The public and those who can't create meetings can't modify meetings
  }  
  
  my $CanModifyMeeting = 0;

  # Find out group IDs of those who can modify this meeting and of the
  # current user
  
  my @MeetingModifyIDs = &GetMeetingModifyGroups($ConferenceID);
  my @MeetingGroupIDs  = ();
  
  unless (@MeetingModifyIDs) { # There are no entries, so meeting 
    $CanModifyMeeting = 1;     # modifiable by all
    return $CanModifyMeeting;
  }
    
  my $SecurityGroupID = &FetchSecurityGroupByName($remote_user);

  foreach my $MeetingModifyID (@MeetingModifyIDs) {
    my $MeetingGroupID = $MeetingModify{$MeetingModifyID}{GroupID};
    push @MeetingGroupIDs,$MeetingGroupID; # Needed later by subordinates
    if ($SecurityGroupID == $MeetingGroupID) {
      $CanModifyMeeting = 1;
    }  
  }

  if ($CanModifyMeeting || !($SuperiorsCanModify)) {
    return $CanModifyMeeting; # Either approved or can't be anymore
  }  

  # If not approved yet, see if they are the parent to a group that is

  &GetSecurityGroups(); # Pull out the big guns
  
  my @HierarchyIDs = keys %GroupsHierarchy;
  foreach my $HierarchyID (@HierarchyIDs) {
    $ParentID = $GroupsHierarchy{$HierarchyID}{Parent}; 
    $ChildID  = $GroupsHierarchy{$HierarchyID}{Child}; 
    if ($ParentID == $SecurityGroupID) { # I am the parent
      foreach my $MeetingGroupID (@MeetingGroupIDs) { 
        if ($MeetingGroupID == $ChildID) {
          $CanModifyMeeting = 1;                           
        }  
      }
    }  
  }

  return $CanModifyMeeting;
}

sub CanCreateMeeting { # Is the user allowed to create a new meeting?
  require "Security.pm";
  
  if ($Public) {
    return 0; 
  }
    
  my $CanCreateMeeting = &CanCreate();   # If they can create documents
                                         # they can create meetings
  return $CanCreateMeeting;              
}
  
1;