package My::Build::Base;

use strict;
use base qw(Module::Build);
use My::Build::Utility qw(awx_arch_file);
use File::Path ();
use File::Basename ();
use Fatal qw(open close);
use Data::Dumper;

sub ACTION_build {
    my $self = shift;

    $self->SUPER::ACTION_build;
    $self->create_config_file( awx_arch_file( 'Config.pm' ) );
    $self->build_wxwidgets;
}

sub create_config_file {
    my( $self, $file ) = @_;
    my %config = $self->awx_configure;
    my $directory = File::Basename::dirname( $file );
    my $ver = $self->awx_wx_config_data->{version};

    $ver =~ m/(\d)(\d)/ and
      $config{version} = $1 + $2 / 1000;
    $ver =~ m/(\d)(\d)(\d+)/ and
      $config{version} = $1 + $2 / 1000 + $3 / 1000000;
    $ver =~ m/(\d)(\d+)_(\d+)/ and
      $config{version} = $1 + $2 / 1000 + $3 / 1000000;
    $ver =~ m/(\d+)\.(\d+)\.(\d+)/ and
      $config{version} = $1 + $2 / 1000 + $3 / 1000000;

    $self->{awx_config} = \%config;

    $config{wx_base_directory} = $self->awx_wx_config_data->{wxdir}
      if $self->awx_wx_config_data->{wxdir};
    $config{compiler} = $self->awx_wx_config_data->{cxx};
    $config{linker} = $self->awx_wx_config_data->{ld};

    File::Path::mkpath( $directory ) or die "mkpath '$directory': $!"
        unless -d $directory;
    open my $fh, "> $file";

    print $fh <<'EOT';
package Alien::wxWidgets::Config;

use strict;
use base qw(Exporter);

our @EXPORT = qw(%VALUES);
our %VALUES;

{
    no strict 'vars';
    %VALUES = %{
EOT

    print {$fh} Data::Dumper->Dump( [ \%config ] );

    print $fh <<'EOT';
    };
}

1;
EOT

    close $fh;
}

sub build_wxwidgets {
    # by default do nothing
}

sub awx_configure {
    my $self = shift;
    return %{$self->{awx_config}} if $self->{awx_config};

    my %config;

    $config{config}{debug} = $self->awx_debug;
    $config{config}{unicode} = $self->awx_unicode;
    $config{config}{mslu} = $self->awx_mslu;
    $config{link_flags} = '';
    $config{c_flags} = '';

    return %config;
}

sub wx_config {
    my $self = shift;
    my $data = $self->awx_wx_config_data;

    foreach ( @_ ) {
        warn "Undefined key '", $_, "' in wx_config"
          unless defined $data->{$_};
    }

    return @{$data}{@_};
}

sub awx_debug { $_[0]->args( 'debug' ) ? 1 : 0 }
sub awx_unicode { $_[0]->args( 'unicode' ) ? 1 : 0 }
sub awx_static { $_[0]->args( 'static' ) ? 1 : 0 }
sub awx_get_package { local $_ = $_[0]; s/^My::Build:://; return $_ }

# MSLU is default when using Unicode *and* it has not
# been explicitly disabled
sub awx_mslu {
    return 0 unless $^O =~ /MSWin32/;
    return $_[0]->args( 'mslu' ) if defined $_[0]->args( 'mslu' );
    return $_[0]->args( 'unicode' );
}

1;
