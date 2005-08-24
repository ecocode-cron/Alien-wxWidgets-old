package My::Build::Base;

use strict;
use base qw(Module::Build);
use My::Build::Utility qw(awx_arch_file);
use Alien::wxWidgets::Utility qw(awx_sort_config awx_grep_config);
use File::Path ();
use File::Basename ();
use Fatal qw(open close);
use Data::Dumper;

sub ACTION_build {
    my $self = shift;

    $self->SUPER::ACTION_build;
    $self->create_config_file( awx_arch_file( 'Config/Config.pm' ) );
    $self->build_wxwidgets;
}

sub create_config_file {
    my( $self, $file ) = @_;
    my %config = $self->awx_configure;
    my $directory = File::Basename::dirname( $file );
    my $ver = $self->awx_wx_config_data->{version};

    $self->{awx_config} = \%config;

    $ver =~ m/^(\d)(\d)$/ and
      $config{version} = $1 + $2 / 1000;
    $ver =~ m/^(\d)(\d)(\d+)$/ and
      $config{version} = $1 + $2 / 1000 + $3 / 1000000;
    $ver =~ m/^(\d)(\d+)_(\d+)$/ and
      $config{version} = $1 + $2 / 1000 + $3 / 1000000;
    $ver =~ m/^(\d+)\.(\d+)\.(\d+)$/ and
      $config{version} = $1 + $2 / 1000 + $3 / 1000000;

    $config{compiler} = $self->awx_wx_config_data->{cxx};
    $config{linker} = $self->awx_wx_config_data->{ld};
    $config{config}{compiler_kind} =
        $self->awx_compiler_kind( $config{compiler} );
    $config{config}{compiler_version} =
      $self->awx_compiler_version( $config{compiler} );

    my $base = $self->awx_get_name
      ( toolkit          => $config{config}{toolkit},
        version          => $config{version},
        debug            => $self->awx_is_debug,
        unicode          => $self->awx_is_unicode,
        mslu             => $self->awx_is_mslu,
        compiler         => $config{config}{compiler_kind},
        compiler_version => $config{config}{compiler_version},
      );

    $config{wx_base_directory} = $self->awx_wx_config_data->{wxdir}
      if $self->awx_wx_config_data->{wxdir};
    $config{alien_base} = $self->{awx_base} = $base;
    $config{alien_package} = "Alien::wxWidgets::Config::${base}";

    my $body = Data::Dumper->Dump( [ \%config ] );
    $body =~ s/rEpLaCe/$base/g;

    File::Path::mkpath( $directory ) or die "mkpath '$directory': $!"
        unless -d $directory;
    open my $fh, '> ' . File::Spec->catfile( $directory, $base . '.pm' );

    print $fh <<"EOT";
package $config{alien_package};

EOT

    print $fh <<'EOT';
use strict;

our %VALUES;

{
    no strict 'vars';
    %VALUES = %{
EOT

    print $fh $body ;

    print $fh <<'EOT';
    };
}

my $key = substr __PACKAGE__, 1 + rindex __PACKAGE__, ':';

sub values { %VALUES, key => $key }

sub config {
   +{ %{$VALUES{config}},
      package       => __PACKAGE__,
      key           => $key,
      version       => $VALUES{version},
      }
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

    $config{config}{debug} = $self->awx_is_debug;
    $config{config}{unicode} = $self->awx_is_unicode;
    $config{config}{mslu} = $self->awx_is_mslu;
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
sub awx_is_debug { $_[0]->awx_debug }
sub awx_unicode { $_[0]->args( 'unicode' ) ? 1 : 0 }
sub awx_is_unicode { $_[0]->awx_unicode }
sub awx_mslu { 0 }
sub awx_is_mslu { $_[0]->awx_mslu }
sub awx_static { $_[0]->args( 'static' ) ? 1 : 0 }
sub awx_is_static { $_[0]->awx_static }
sub awx_get_package { local $_ = $_[0]; s/^My::Build:://; return $_ }

sub awx_get_name {
    my( $self, %args ) = @_;
    my $e = sub { defined $_[0] ? ( $_[0] ) : () };
    my $pv = sub { join '.', map { 0 + ( $_ || 0 ) }
                                 ( $_[0] =~ /(\d+)\.(\d{3,3})(\d{0,3})/ ) } ;
    my $base = join '-', $args{toolkit}, $pv->( $args{version} ),
                   $e->( $args{debug} ? 'dbg' : undef ),
                   $e->( $args{unicode} ? 'uni' : undef ),
                   $e->( $args{mslu} ? 'mslu' : undef ),
                   $e->( $args{compiler} ),
                   $e->( $args{compiler_version} ),
                   ;

    $base =~ s/\./_/g; $base =~ s/-/_/g;

    return $base;
}

sub awx_compiler_kind { 'nc' } # as in 'No Clue'

sub awx_compiler_version {
    return Alien::wxWidgets::Utility::awx_cc_version( $_[1] );
}

sub awx_path_search {
    my( $self, $file ) = @_;

    foreach my $d ( File::Spec->path ) {
        my $full = File::Spec->catfile( $d, $file );
        return $full if -f $full;
    }

    return;
}

1;
