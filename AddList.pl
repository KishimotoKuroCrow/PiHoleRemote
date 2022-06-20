#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw/strftime/;
use Getopt::Long;
use Env '@PATH';

$SIG{"INT"} = \&CleanExit;
my $ScriptName = $0;
my $__DEBUG__  = 0;
my $execfile   = 'sqlite3';
my $piexecfile = 'pihole';

# =========================
#  Function Prototypes
sub SysCmdToPush( $ );
sub RunSysCmd( $ );
sub PathDirectory( $ );
sub GetDateTime();
sub CleanExit();
sub main();


# =========================================
#  Get Date and Time formatted as _YYYYMMDD_HHMM
sub GetDateTime()
{
   my $DateString = "";
   $DateString = strftime "_%Y%m%d_%H%M", localtime;
   
   return $DateString;
}


# =========================================
#  Check and return the directory name
sub PathDirectory( $ )
{
   my( $Path ) = @_;
   my @DirSegment = split( '/', $Path );
   my $DirPath = "./";
   my $NumElements = scalar @DirSegment;
   if( $NumElements gt 1 )
   {
      # Remove the last element and recombine
      if( $__DEBUG__ eq 1 )
      {
         print STDOUT "@DirSegment\n";
      }
      @DirSegment = splice( @DirSegment, 0, $NumElements - 1);
      $DirPath = join( '/', @DirSegment );
   }
   if( $__DEBUG__ eq 1 )
   {
      print STDOUT "$ScriptName :- PathDirectory = \"$DirPath\" for \"$Path\"\n";
   }

   # Return the directory path
   return $DirPath;
}


# =========================================
#  Clean Exit
sub CleanExit()
{
   print STDOUT "\n-- $ScriptName: Exiting Program --\n";
   exit 0;
}


# =========================================
#  Returns the array of system commands to execute
sub SysCmdToPush( $ )
{
   my( $File ) = @_;
   my @SysCmd  = ();

   # Get the file and get the full list
   my $fileline   = "";
   my $cmdline    = "";
   my $CmdIteration = 0;

   # Make sure the file exists and is not empty
   if( !(-s $File ) )
   {
      print STDOUT "$ScriptName: \"$File\" does not exist or is empty.\n";
      return @SysCmd;
   }

   # Open the file and start processing.
   open( INPUTF, "<$File" );
   while( $fileline = <INPUTF> )
   {
      chomp( $fileline );
      if( $__DEBUG__ eq 1 )
      {
         print STDOUT "$ScriptName: - $File, line: \"$fileline\".\n";
      }

      # Go through the list of sites for sql.
      if(not (($fileline =~ /^#/) or ($fileline =~ /^ *$/)) )
      {
         $cmdline = "$execfile /etc/pihole/gravity.db \"INSERT or IGNORE into adlist (address, enabled, comment) VALUES ('$fileline', 1, 'comment');\"";
         push @SysCmd, $cmdline;
      }
   }
   $CmdIteration = scalar @SysCmd;
   if( $__DEBUG__ eq 1 )
   {
      print STDOUT "$ScriptName: $File has $CmdIteration remote hosts files.\n";
   }

   # Not necessary, just a precaution.
   $CmdIteration = 0;
   close( INPUTF );

   return @SysCmd;
}


# =========================================
#  Function to run the system commands
sub RunSysCmd( $ )
{
   my( $InCmdArray ) = @_;
   my @AllCmd = @{$InCmdArray};

   # "One condition -> loop" rather than extra
   # conditional verification at every iteration:
   if( $__DEBUG__ eq 1 )
   {
      # Uncomment below to see the command that will be
      # executed when not in debug mode
      # -----------------------------------------
      foreach my $ThisCmd( @AllCmd )
      {
         print STDOUT "system( \"$ThisCmd\" )\n";
      }
   }
   else
   {
      foreach my $ThisCmd( @AllCmd )
      {
         system( "$ThisCmd" );
      }
   }
}


# =========================================
#  Main Function
sub main()
{
   # Verify that the executables exist
   my $execfile_exists = grep -x "$_/$execfile", @PATH;
   if( not $execfile_exists )
   {
      print STDOUT "** \"$execfile\" cannot be found. Please install it first. **\n";
      CleanExit();
   }
   $execfile_exists = grep -x "$_/$piexecfile", @PATH;
   if( not $execfile_exists )
   {
      print STDOUT "** \"$piexecfile\" cannot be found. Please install it first. **\n";
      CleanExit();
   }

   # Parse through the files
   my @AllCmdToExec = ();
   my @CmdArray = ();
   foreach my $TmpFile( @ARGV )
   {
      @CmdArray = ();
      @CmdArray = SysCmdToPush( $TmpFile );
      push @AllCmdToExec, @CmdArray;
   }

   # Refresh PiHole with the updated lists
   push @AllCmdToExec, "$piexecfile -g";

   # Execute all the commands
   RunSysCmd( \@AllCmdToExec );

   CleanExit();
}

main();
