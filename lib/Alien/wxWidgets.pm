package Alien::wxWidgets;

=head1 NAME

Alien::wxWidgets - building, finding and using wxWidgets binaries

=head1 SYNOPSIS

    use Alien::wxWidgets <options>;

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
    my @keys = Alien::wxWidgets->library_keys; # 'gl', 'adv', ...
    my $library_path = Alien::wxWidgets->shared_library_path;
    my $key = Alien::wxWidgets->key;
    my $prefix = Alien::wxWidgets->prefix;

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

In short C<Alien::wxWidgets> can be used to detect and get
configuration settings from an installed wxWidgets.

=cut

use strict;
use Carp;
use Alien::wxWidgets::Utility qw(awx_sort_config awx_grep_config
                                 awx_smart_config);
use Module::Pluggable sub_name      => '_list',
                      search_path   => 'Alien::wxWidgets::Config',
                      instantiate   => 'config';

our $AUTOLOAD;
our $VERSION = '0.16';
our %VALUES;
our $dont_remap;

*_remap = \&Alien::wxWidgets::Utility::_awx_remap;

sub AUTOLOAD {
    my $name = $AUTOLOAD;

    $name =~ s/.*:://;
    croak "Can not use '", $name, "'" unless exists $VALUES{$name};

    return _remap( $VALUES{$name} );
}

sub import {
    my $class = shift;
    if( @_ == 1 ) {
        $class->show_configurations if $_[0] eq ':dump';
        return;
    }

    $class->load( @_ );
}

sub load {
    my $class = shift;
    my %crit = awx_smart_config @_;

    my @configs = awx_sort_config awx_grep_config [ $class->_list ], %crit ;

    unless( @configs ) {
        require Data::Dumper;
        die "No matching config:\n",
          Data::Dumper->Dump( [ { %crit } ] );
    }

    %VALUES = $configs[0]->{package}->values;
}

sub show_configurations {
    my $class = shift;
    my @configs = awx_sort_config awx_grep_config [ $class->_list ], @_;

    require Data::Dumper;
    print Data::Dumper->Dump( \@configs );
}

sub get_configurations {
    my $class = shift;

    return awx_sort_config awx_grep_config [ shift->_list ], @_;
 }

my $lib_nok  = 'adv|base|html|net|xml|media';
my $lib_mono = 'adv|base|html|net|xml|xrc|media';

sub _grep_libraries {
    my $lib_filter = $VALUES{version} >= 2.005001 ? qr/(?!a)a/ : # no match
                     $^O =~ /MSWin32/             ? qr/^(?:$lib_nok|gl)$/ :
                                                    qr/^(?:$lib_nok)$/;

    my( $type, @libs ) = @_;

    my $dlls = $VALUES{_libraries};

    @libs = keys %$dlls unless @libs;
    push @libs, 'core', 'base'  unless grep /^core|mono$/, @libs;

    if( ( $VALUES{config}{build} || '' ) eq 'mono' ) {
        @libs = map { $_ eq 'core'            ? ( 'mono' ) :
                      $_ =~ /^(?:$lib_mono)$/ ? () :
                      $_ } @libs;
        @libs = qw(mono) unless @libs;
    }

    return map  { _remap( $_ ) }
           map  { defined( $dlls->{$_}{$type} ) ? $dlls->{$_}{$type} :
                      croak "No such '$type' library: '$_'" }
           grep !/$lib_filter/, @libs;
}

sub link_libraries { shift; return _grep_libraries( 'link', @_ ) }
sub shared_libraries { shift; return _grep_libraries( 'dll', @_ ) }
sub import_libraries { shift; return _grep_libraries( 'lib', @_ ) }
sub library_keys { shift; return keys %{$VALUES{_libraries}} }

sub libraries {
    my $class = shift;

    return ( _remap( $VALUES{link_libraries} ) || '' ) . ' ' .
           join ' ', map { _remap( $_ ) }
                         $class->link_libraries( @_ );
}

1;

__END__

=head1 METHODS

=head1 load/import

    use Alien::wxWidgets version          => 2.004 | [ 2.004, 2.005 ],
                         compiler_kind    => 'gcc' | 'cl', # Windows only
                         compiler_version => '3.3', # only GCC for now
                         toolkit          => 'gtk2',
                         debug            => 0 | 1,
                         unicode          => 0 | 1,
                         mslu             => 0 | 1,
                         key              => $key,
                         ;

    Alien::wxWidgets->load( <same as the above> );

Using C<Alien::wxWidgets> without parameters will load a default
configuration (for most people this will be the only installed
confiuration). Additional parameters allow to be more selective.

If there is no matching configuration the method will C<die()>.

In case no arguments are passed in the C<use>, C<Alien::wxWidgets>
will try to find a reasonable default configuration.

Please note that when the version is pecified as C<version => 2.004>
it means "any version >= 2.004" while when specified as
C<version => [ 2.004, 2.005 ]> it means "any version => 2.004 and < 2.005".

=head1 key

    my $key = Alien::wxWidgets key;

Returns an unique key that can be used to reload the
currently-loaded configuration.

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

Copyright (c) 2005, 2006 Mattia Barbon <mbarbon@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself

=cut
