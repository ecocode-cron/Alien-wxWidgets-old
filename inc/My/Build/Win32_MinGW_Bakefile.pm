package My::Build::Win32_MinGW_Bakefile;

use strict;
use base qw(My::Build::Win32_MinGW);
use My::Build::Utility qw(awx_install_arch_file awx_install_arch_auto_file);
use Config;
use Fatal qw(chdir);

my $min_dir = File::Spec->catdir( $ENV{WXDIR}, 'samples', 'minimal' );

sub awx_wx_config_data {
    my $self = shift;
    return $self->{awx_data} if $self->{awx_data};

    my %data = ( %{$self->SUPER::awx_wx_config_data},
                 'cxx'     => 'g++',
                 'ld'      => 'g++',
                 'wxdir'   => $ENV{WXDIR},
               );

    my $final = $self->awx_debug ? 'BUILD=debug'
                                 : 'BUILD=release';
    my $unicode = $self->awx_unicode ? 'UNICODE=1' : 'UNICODE=0';
    $unicode .= ' MSLU=1' if $self->awx_mslu;

    my $dir = Cwd::cwd;
    chdir $min_dir;
    my @t = qx(make -n -f makefile.gcc $final $unicode SHARED=1);

    my( $orig_libdir, $libdir, $digits );
    foreach ( @t ) {
        chomp;

        if( m/\s-l\w+/ ) {
            m/-lwxbase(\d+)/ and $digits = $1;
            s/^[cg]\+\+//;
            s/(?:\s|^)-[co]//g;
            s/\s+\S+\.(exe|o)/ /gi;
            s{-L(\S+)}
             {$orig_libdir = File::Spec->canonpath
                                 ( File::Spec->rel2abs( $1 ) );
              '-L' . ( $libdir = awx_install_arch_file( 'rEpLaCe/lib' ) )}eg;
            $data{libs} = $_;
        } elsif( s/^\s*g\+\+\s+// ) {
            s/\s+\S+\.(cpp|o)/ /g;
            s/(?:\s|^)-[co]//g;
            s{[-/]I(\S+)}{'-I' . File::Spec->canonpath
                                     ( File::Spec->rel2abs( $1 ) )}egi;
            s{[-/]I(\S+)[\\/]samples[\\/]minimal(\s|$)}{-I$1\\contrib\\include }i;
            s{[-/]I(\S+)[\\/]samples(\s|$)}{ }i;
            $data{cxxflags} = $_;
        }
    }

    chdir $dir;
    die 'Could not find wxWidgets lib directory' unless $libdir;

    $data{dlls} = $self->awx_grep_dlls( $orig_libdir, $digits );
    $data{version} = $digits;

    $self->{awx_data} = \%data;
}

1;
