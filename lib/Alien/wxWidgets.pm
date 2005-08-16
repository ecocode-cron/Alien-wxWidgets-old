package Alien::wxWidgets;

=head1 NAME

Alien::wxWidgets - building, finding and using wxWidgets binaries

=head1 SYNOPSIS

    use Alien::wxWidgets;

    my $version = Alien::wxWidgets->version;
    my $config = Alien::wxWidgets->config;
    my $compiler = Alien::wxWidgets->compiler;
    my $linker = Alien::wxWidgets->linker;
    my $include_path = Alien::wxWidgets->include_path;
    my $defines = Alien::wxWidgets->defines;
    my $cflags = Alien::wxWidgets->c_flags;
    my $linkflags = Alien::wxWidgets->link_flags;
    my $libraries = Alien::wxWidgets->libraries( qw(gl adv core base) );
    my @libraries = Alien::wxWidgets->link_libraries( qw(gl adv core base) );
    my @implib = Alien::wxWidgets->import_libraries( qw(gl adv core base) );
    my @shrlib = Alien::wxWidgets->shared_libraries( qw(gl adv core base) );
    my $library_path = Alien::wxWidgets->shared_library_path;

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

In short C<Alien::wxWidgets> can be used to detect and get
configuration settings from an installed wxWidgets.

=cut

use strict;
use Carp;
use Alien::wxWidgets::Config qw(%VALUES);

our $AUTOLOAD;
our $VERSION = '0.02';

sub AUTOLOAD {
    my $name = $AUTOLOAD;

    $name =~ s/.*:://;
    croak "Can not use '", $name, "'" unless exists $VALUES{$name};

    return $VALUES{$name};
}

my $lib_filter = $VALUES{version} >= 2.005001 ? qr/(?!a)a/ : # match nothing
                 $^O =~ /MSWin32/ ? qr/^(?:adv|base|html|net|xml|media|gl)$/ :
                                    qr/^(?:adv|base|html|xml|media)$/;

sub _grep_libraries {
    my( $type, @libs ) = @_;
    my $dlls = $VALUES{_libraries};

    @libs = keys %$dlls unless @libs;
    push @libs, 'core', 'base'  unless grep /^core$/, @libs;
    return map  { defined( $dlls->{$_}{$type} ) ? $dlls->{$_}{$type} :
                      croak "No such '$type' library: '$_'" }
           grep !/$lib_filter/, @libs;
}

sub link_libraries { shift; return _grep_libraries( 'link', @_ ) }
sub shared_libraries { shift; return _grep_libraries( 'dll', @_ ) }
sub import_libraries { shift; return _grep_libraries( 'lib', @_ ) }

sub libraries {
    my $class = shift;

    return $VALUES{link_libraries} . ' ' .
           join ' ', $class->link_libraries( @_ );
}

1;

__END__

=head1 METHODS

=head1 version

    my $version = Alien::wxWidgets->version;

Returns the wxWidgets version for this C<Alien::wxWidgets>
installation in the form MAJOR + MINOR / 1_000 + RELEASE / 1_000_000
e.g. 2.006002 for wxWidgets 2.6.2 and 2.004 for wxWidgets 2.4.0.

=head1 config

    my $config = Alien::wxWidgets->config;

Returns some miscellaneous configuration informations for wxWidgets
in the form

    { toolkit   => 'msw' | 'gtk' | 'motif' | 'x11' | 'cocoa' | 'mac',
      debug     => 1 | 0,
      unicode   => 1 | 0,
      mslu      => 1 | 0,
      }

=head1 include_path

    my $include_path = Alien::wxWidgets->include_path;

Returns the include paths to be used in a format suitable for the
compiler (usually something like "-I/usr/local/include -I/opt/wx/include").

=head1 defines

    my $defines = Alien::wxWidgets->defines;

Returns the compiler defines to be used in a format suitable for the
compiler (usually something like "-D__WXDEBUG__ -DFOO=bar").

=head1 c_flags

    my $cflags = Alien::wxWidgets->c_flags;

Returns additional compiler flags to be used.

=head1 compiler

    my $compiler = Alien::wxWidgets->compiler;

Returns the (C++) compiler used for compiling wxWidgets.

=head1 linker

    my $linker = Alien::wxWidgets->linker;

Returns a linker suitable for linking C++ binaries.

=head1 link_flags

    my $linkflags = Alien::wxWidgets->link_flags;

Returns additional link flags.

=head1 libraries

    my $libraries = Alien::wxWidgets->libraries( qw(gl adv core base) );

Returns link flags for linking the libraries passed as arguments. This
usually includes some search path specification in addition to the
libraries themselves. The caller is responsible for the correct order
of the libraries.

=head1 link_libraries

    my @libraries = Alien::wxWidgets->link_libraries( qw(gl adv core base) );

Returns a list of linker flags that can be used to link the libraries
passed as arguments.

=head1 import_libraries

    my @implib = Alien::wxWidgets->import_libraries( qw(gl adv core base) );

Windows specific. Returns a list of import libraries corresponding to
the libraries passed as arguments.

=head1 shared_libraries

    my @shrlib = Alien::wxWidgets->shared_libraries( qw(gl adv core base) );

Returns a list of shared libraries corresponding to the libraries
passed as arguments.

=head1 library_path

    my $library_path = Alien::wxWidgets->shared_library_path;

Windows specific. Returns the path at which the private copy
of wxWidgets libraries has been installed.

=head1 BUGS

=over 4

=item *

Does not support multiple wxWidgets configurations.

=item *

Does not support automated wxWidgets download/installation.

=item *

Error handling (wx-config not in path, compiler/make not found)
is missing.

=back

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2005 Mattia Barbon <mbarbon@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself
