package My::Build::Base;

use strict;
use base qw(Module::Build);
use My::Build::Utility qw(awx_arch_file awx_touch);
use Alien::wxWidgets::Utility qw(awx_sort_config awx_grep_config);
use File::Path ();
use File::Basename ();
use Fatal qw(open close unlink);
use Data::Dumper;

sub ACTION_build {
    my $self = shift;
    # try to make "perl Makefile.PL && make test" work
    # but avoid doubly building wxWidgets when doing
    # "perl Makefile.PL && make && make test"
    unlink 'configured' if -f 'configured';
    $self->SUPER::ACTION_build;
}

sub ACTION_code {
    my $self = shift;

    $self->SUPER::ACTION_code;
    # see comment in ACTION_build for why 'configured' is used
    return if -f 'configured';
    $self->depends_on( 'build_wx' );
    $self->create_config_file( awx_arch_file( 'Config/Config.pm' ) );
    $self->install_wxwidgets;
    # see comment in ACTION_build for why 'configured' is used
    awx_touch( 'configured' );
    $self->add_to_cleanup( 'configured' );
}

sub ACTION_build_wx {
    my $self = shift;

    if( $self->notes( 'build_wx' ) ) {
        $self->fetch_wxwidgets;
        $self->extract_wxwidgets;
        $self->massage_environment;
        $self->build_wxwidgets;
        $self->massage_environment; # twice on purpose
    }
}

sub ACTION_build_perl {
    my $self = shift;

    $self->SUPER::ACTION_build;
    $self->massage_environment;
    $self->create_config_file( awx_arch_file( 'Config/Config.pm' ) );
}

sub ACTION_install_wx {
    my $self = shift;

    $self->depends_on( 'build_perl' );
    $self->install_wxwidgets;
}

sub ACTION_install {
    my $self = shift;

    $self->SUPER::ACTION_install;
    $self->install_system_wxwidgets;
}

sub ACTION_distcheck {
    my $self = shift;
    my $data = $self->notes( 'build_data' );

    foreach my $p ( qw(msw mac unix) ) {
        next unless exists $data->{$p};

        foreach my $c ( qw(unicode ansi) ) {
            next unless exists $data->{$p}{$c};

            foreach my $f ( @{$data->{$p}{$c}} ) {
                my $file = File::Spec->catfile( 'patches', $f );

                warn 'Missing patch file: ', $file, "\n" unless -f $file;
            }
        }
    }

    $self->SUPER::ACTION_distcheck;
}

sub awx_key {
    my( $self ) = @_;

    die unless $self->{awx_key};

    return $self->{awx_key};
}

sub _version_2_dec {
    my( $class, $ver ) = @_;
    my $dec;

    $ver =~ m/^(\d)(\d)$/ and
      $dec = $1 + $2 / 1000;
    $ver =~ m/^(\d)(\d)(\d+)$/ and
      $dec = $1 + $2 / 1000 + $3 / 1000000;
    $ver =~ m/^(\d)(\d+)_(\d+)$/ and
      $dec = $1 + $2 / 1000 + $3 / 1000000;
    $ver =~ m/^(\d+)\.(\d+)\.(\d+)$/ and
      $dec = $1 + $2 / 1000 + $3 / 1000000;

    return $dec;
}

sub _init_config {
    my( $self ) = @_;
    my %config = $self->awx_configure;
    my $ver = $self->awx_wx_config_data->{version};

    $self->{awx_config} = \%config;

    $config{version} = $self->_version_2_dec( $ver );

    $config{compiler} = $ENV{CXX} || $self->awx_wx_config_data->{cxx};
    $config{linker} = $self->awx_wx_config_data->{ld};
    $config{config}{compiler_kind} = $self->notes( 'compiler_kind' ) ||
        $self->awx_compiler_kind( $config{compiler} );
    $config{config}{compiler_version} = $self->notes( 'compiler_version' ) ||
      $self->awx_compiler_version( $config{compiler} );
    $self->notes( 'compiler_kind' => $config{config}{compiler_kind} );
    $self->notes( 'compiler_version' => $config{config}{compiler_version} );

    my $base = $self->awx_get_name
      ( toolkit          => $config{config}{toolkit},
        version          => $config{version},
        debug            => $self->awx_is_debug,
        unicode          => $self->awx_is_unicode,
        mslu             => $self->awx_is_mslu,
        compiler         => $config{config}{compiler_kind},
        compiler_version => $config{config}{compiler_version},
      );

    $self->{awx_key} = $base;

    $config{wx_base_directory} = $self->awx_wx_config_data->{wxdir}
      if $self->awx_wx_config_data->{wxdir};
    $config{alien_base} = $self->{awx_base} = $base;
    $config{alien_package} = "Alien::wxWidgets::Config::${base}";

    return %config;
}

sub create_config_file {
    my( $self, $file ) = @_;

    my $directory = File::Basename::dirname( $file );
    my %config = $self->_init_config;
    my $base = $self->awx_key;

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

sub fetch_wxwidgets {
    my $self = shift;

    return if -f $self->notes( 'build_data' )->{data}{archive};
    require File::Fetch;

    print "Fetching wxWidgets...\n";
    print "fetching from: ", $self->notes( 'build_data' )->{data}{url}, "\n";

    my $path = File::Fetch->new
      ( uri => $self->notes( 'build_data' )->{data}{url} )->fetch;
    die 'Unable to fetch archive' unless $path;
}

sub extract_wxwidgets {
    my $self = shift;

    return if -d $self->notes( 'build_data' )->{data}{directory};
    my $archive = $self->notes( 'build_data' )->{data}{archive};

    print "Extracting wxWidgets...\n";

    if( $^O ne 'MSWin32' || $archive !~ /\.bz2$/i ) {
        require Archive::Extract;
        my $ae = Archive::Extract->new( archive => $archive );

        die 'Error: ', $ae->error unless $ae->extract;
    } else {
        system "bunzip2 -c $archive | tar xf -";
    }

    $self->patch_wxwidgets;
}

sub patch_wxwidgets {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    my @patches = $self->awx_wx_patches;

    print "Patching wxWidgets...\n";

    chdir File::Spec->rel2abs
              ( $self->notes( 'build_data' )->{data}{directory} );

    foreach my $i ( @patches ) {
        print "Applying patch: ", $i, "\n";
        my $cmd = $self->_patch_command( $old_dir, $i );
        print $cmd, "\n";
        system $cmd and die 'Error: ', $?;
    }

    chdir $old_dir;
}

sub _patch_command {
    my( $self, $base_dir, $patch_file ) = @_;

    my $cmd = $^X . ' ' . File::Spec->catfile( $base_dir,
                                               qw(inc bin patch) )
      . " -N -p0 -u -b .bak < $patch_file";

    return $cmd;
}

sub build_wxwidgets {
    die "Don't know how to build wxWidgets";
}

sub install_wxwidgets {
    return unless $_[0]->notes( 'build_wx' );
    die "Don't know how to build wxWidgets";
}

sub install_system_wxwidgets { }

sub awx_configure {
    my $self = shift;
    return %{$self->{awx_config}} if $self->{awx_config};

    my %config;

    $config{config}{debug} = $self->awx_is_debug;
    $config{config}{unicode} = $self->awx_is_unicode;
    $config{config}{mslu} = $self->awx_is_mslu;
    $config{config}{build} = 'multi';
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

sub awx_monolithic { $_[0]->args( 'monolithic' ) ? 1 : 0 }
sub awx_is_monolithic { $_[0]->awx_monolithic }
sub awx_debug { $_[0]->args( 'debug' ) ? 1 : 0 }
sub awx_is_debug { $_[0]->awx_debug }
sub awx_unicode { $_[0]->args( 'unicode' ) ? 1 : 0 }
sub awx_is_unicode { $_[0]->awx_unicode }
sub awx_mslu { 0 }
sub awx_is_mslu { $_[0]->awx_mslu }
sub awx_static { $_[0]->args( 'static' ) ? 1 : 0 }
sub awx_is_static { $_[0]->awx_static }
sub awx_universal { $_[0]->args( 'universal' ) ? 1 : 0 }
sub awx_is_universal { $_[0]->awx_universal }
sub awx_get_package { local $_ = $_[0]; s/^My::Build:://; return $_ }

sub awx_wx_patches {
    my $self = shift;
    my $data = $self->notes( 'build_data' );
    my $toolkit = $^O eq 'MSWin32' ? 'msw' :
                  $^O eq 'darwin'  ? 'mac' :
                                     'unix';
    my $unicode = $self->awx_unicode ? 'unicode' : 'ansi';

    return unless exists $data->{$toolkit} and $data->{$toolkit}{$unicode};

    return map { File::Spec->rel2abs( File::Spec->catfile( 'patches', $_ ) ) }
               @{$data->{$toolkit}{$unicode}};
}

sub awx_get_name {
    my( $self, %args ) = @_;
    my $e = sub { defined $_[0] ? ( $_[0] ) : () };
    my $pv = sub { join '.', map { 0 + ( $_ || 0 ) }
                                 ( $_[0] =~ /(\d+)\.(\d{1,3})(\d{0,3})/ ) } ;
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
    return Alien::wxWidgets::Utility::awx_cc_abi_version( $_[1] );
}

sub awx_path_search {
    my( $self, $file ) = @_;

    foreach my $d ( File::Spec->path ) {
        my $full = File::Spec->catfile( $d, $file );
        return $full if -f $full;
    }

    return;
}

sub awx_uses_bakefile { 1 }

sub ACTION_ppmdist {
    my( $self ) = @_;

    $self->awx_strip_dlls;
    $self->_system( 'perl script/make_ppm.pl' );
}

sub _system {
    shift;
    my $ret;

    $ret = @_ > 1 ? system @_ : system $_[0];
    $ret and croak "system: @_: $?";
}

1;
