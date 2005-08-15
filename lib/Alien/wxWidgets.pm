package Alien::wxWidgets;

=head1 NAME

Alien::wxWidgets - building, finding and using wxWidgets binaries

=head1 SYNOPSIS

    use Alien::wxWidgets;

    my $include_path = Alien::wxWidgets->include_path;
    my $defines = Alien::wxWidgets->defines;
    my $cflags = Alien::wxWidgets->c_flags;
    my $compiler = Alien::wxWidgets->compiler;
    my $linker = Alien::wxWidgets->linker;
    my $libraries = Alien::wxWidgets->link_libraries( qw(gl adv core base) );
    my $implib = Alien::wxWidgets->import_libraries( qw(gl adv core base) );
    my $shrlib = Alien::wxWidgets->shared_libraries( qw(gl adv core base) );
    my $linkflags = Alien::wxWidgets->link_flags;
    my $libraries = Alien::wxWidgets->libraries( qw(gl adv core base) );
    my $version = Alien::wxWidgets->version;

    # returns an hash of the form
    # { toolkit   => 'msw',
    #   debug     => 1 | 0,
    #   unicode   => 1 | 0,
    #   mslu      => 1 | 0,
    #  }
    my $config = Alien::wxWidgets->config;

=cut

use strict;
use Carp;
use Alien::wxWidgets::Config qw(%VALUES);

our $AUTOLOAD;
our $VERSION = '0.01';

sub AUTOLOAD {
    my $name = $AUTOLOAD;

    $name =~ s/.*:://;
    croak "Can not use '", $name, "'" unless exists $VALUES{$name};

    return $VALUES{$name};
}

sub _grep_libraries {
    my( $type, @libs ) = @_;
    my $dlls = $VALUES{_libraries};

    @libs = keys %$dlls unless @libs;
    return map { defined( $dlls->{$_}{$type} ) ? $dlls->{$_}{$type} :
                     croak "No such '$type' library: '$_'" }
               @libs;
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
