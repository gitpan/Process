
=head1 NAME

Process --   launch and control background processes

=head1 SYNOPSIS

   use Process;

   $myproc = Process->new();             # Create a new process object

   $myproc->start("shell-command-line"); # Launch a shell process
   $myproc->start(sub { ... });          # Launch a perl subroutine
   $myproc->start(\&subroutine);         # Launch a perl subroutine

   $running = $myproc->poll();           # Poll Running Process

   $myproc->kill();                      # Kill Process (SIGTERM)


   $myproc->kill("SIGUSR1");             # Send specified signal

=head1 DESCRIPTION

The Process package provides objects that model real-life
processes from a user's point of view. 
A new process object is created by 

   $myproc = Process->new();

Either shell-like command lines or references to perl
subroutines can be specified for launching a process in background.
A 10-second sleep process, for example, can be started via the
shell as

   $myproc->start("sleep 10");

or, as a perl subroutine, 

   $myproc->start(sub { sleep(10); });

The I<start> Method returns immediately after starting the
specified process in background, i.e. non-blocking mode.
The I<start> method returns 1 if the process has been launched
sucessfully, 0 if not.

The I<poll> method checks if the process is still running

   $running = $myproc->poll();

and returns 1 if it is, 0 if it's not. Finally, 

   $myproc->kill();

terminates the process by sending it the SIGTERM signal. As an
option, another signal can be specified.

   $myproc->kill("SIGUSR1");

sends the SIGUSR1 to the running process. I<kill> returns I<1> if
it succeeds in sending the signal, I<0> if it doesn't.

=head1 AUTHOR

Michael Schilli <schilli@tep.e-technik.tu-muenchen.de>

=cut


use strict;

package Process;

###
### $proc_obj=Process->new();
###
sub new { 
  bless {};
}

###
### $ret = $proc_obj->start("prg"); - Launch process
###                                   
sub start {
  my $self  = shift;
  my $func  = shift;

  # Avoid Zombies
  $SIG{'CHLD'} = sub { wait };

  # Fork a child process
  if(($self->{'pid'}=fork()) == 0) { # Child
      if(ref($func) eq "CODE") {
	  &$func; exit 0;            # Start perl subroutine
      } else {
          exec "$func";              # Start Shell-Process
      }
  } elsif($self->{'pid'} > 0) {      # Parent:
      return 1;                      #   return OK
  } else {                           # Fork Error:
      return 0;                      #   return Error
  }
}

###
### $ret = $proc_obj->poll(); - Check process status
###                             1="running" 0="not running"
###
sub poll {
  my $self = shift;

  defined $self->{'pid'} &&      # pid initialized && 
    kill(0, $self->{'pid'});     # Process alive
}

### 
### $ret = $proc_obj->kill([SIGXXX]); - Send signal to process
###                                     Default-Signal: SIGTERM
sub kill
{ 
  my $self = shift;
  my $sig  = shift;

  # If no signal specified => SIGTERM-Signal
  $sig = "SIGTERM" unless defined $sig;

  # Process initialized at all?
  return 0 if !defined $self->{'pid'};

  # Send signal
  kill($sig, $self->{'pid'}) || return 0;

  # Reap Zombies
  waitpid($self->{'pid'}, 0) == $self->{'pid'} || return 0;

  # Mark Process as non-existing
  undef $self->{'pid'};  

  1;
}

sub version {
    "Process.pm Version 1.1";
}

1;

__END__
