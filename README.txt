=head1 NAME

README.txt - build and installation instructions

=head1 DESCRIPTION

Alien::wxWidgets allows wxPerl to easily find information about
your wxWidgets installation. It can store this information for multiple
wxWidgets versions or configurations (debug, Unicode, etc.). It can also
build and install a private copy of wxWidgets as part of the build process.

=head1 Installing wxWidgets

If yo do not know how to do it, please answer 'yes' to the question 'Do you
want to build wxWidgets?'; Alien::wxWidgets will build and install a
copy of wxWidgets for you.

=head1 Installing Alien::wxWidgets

Please note that the steps below can be repeated multiple times in order
install multiple configurations (differing for the wxWidgets version,
compiler, compiler version, debug/unicode settings).

=head2 Unices and Mac OS X

Important: either wx-config must be in the PATH or the WX_CONFIG
environment variable must be set to the full path to wx-config. The
environment WX_CONFIG variable can also be used to specify a different
wx-config.

    perl Build.PL
    perl Build
    perl Build test
    perl Build install

=head2 Windows

    <add your compiler to the path>
    <build wxWidgets>
    set WXDIR=C:\Path\to\wxWidgets
    perl Build.PL [--debug] [--unicode] [--mslu]
    perl Build
    perl Build test
    perl Build install

Important: the command line options to Build.PL must match the build
settings used to build wxWidgets.

=cut
