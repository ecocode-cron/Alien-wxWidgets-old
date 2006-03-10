package My::Build::Win32_MSVC_Bakefile;

use strict;
use base qw(My::Build::Win32_MSVC My::Build::Win32_Bakefile);
use My::Build::Utility qw(awx_install_arch_file awx_install_arch_auto_file);
use Alien::wxWidgets::Utility qw(awx_capture);
use Config;
use Fatal qw(chdir);
use Cwd ();

sub _check_nmake {
    my $out = awx_capture( 'nmake /?' );
    unless( $out =~ m{/U\s}i ) {
        die "Please use an NMAKE version supporting '-u', not the" .
            " freely-available one\n";
    }
}

sub awx_wx_config_data {
    my $self = shift;

    My::Build::Win32::_init();
    $self->_check_nmake();

    return $self->{awx_data} if $self->{awx_data};

    my %data = ( %{$self->SUPER::awx_wx_config_data},
                 'cxx'     => 'cl',
                 'ld'      => 'link',
               );

    die "PANIC: you are not using nmake!" unless $Config{make} eq 'nmake';

    my $orig_libdir;
    my $final = $self->awx_debug ? 'BUILD=debug   DEBUG_RUNTIME_LIBS=0'
                                 : 'BUILD=release DEBUG_RUNTIME_LIBS=0';
    my $unicode = $self->awx_unicode ? 'UNICODE=1' : 'UNICODE=0';
    $unicode .= ' MSLU=1' if $self->awx_mslu;

    my $dir = Cwd::cwd;
    chdir File::Spec->catdir( $ENV{WXDIR}, 'samples', 'minimal' );
    my @t = qx(nmake /nologo /n /u /f makefile.vc $final $unicode SHARED=1);

    my( $accu, $libdir, $digits );
    foreach ( @t ) {
        chomp;
        m/^\s*echo\s+(.*)>\s*\S+\s*$/ and $accu .= ' ' . $1 and next;
        s/\@\S+\s*$/$accu/ and undef $accu;

        if( s/^\s*link\s+// ) {
            m/\swxmsw(\d+)\S+\.lib/ and $digits = $1;
            s/\s+\S+\.(exe|res|obj)/ /g;
            s{[-/]LIBPATH:(\S+)}
             {$orig_libdir = File::Spec->canonpath
                                 ( File::Spec->rel2abs( $1 ) );
              '-L' . ( $libdir = awx_install_arch_file( 'rEpLaCe/lib' ) )}egi;
            $data{libs} = $_;
        } elsif( s/^\s*cl\s+// ) {
            s/\s+\S+\.(cpp|pdb|obj)/ /g;
            s{[-/]I(\S+)}{'-I' . File::Spec->canonpath
                                     ( File::Spec->rel2abs( $1 ) )}egi;
            s{[-/]I(\S+)[\\/]samples[\\/]minimal(\s|$)}{-I$1\\contrib\\include }i;
            s{[-/]I(\S+)[\\/]samples(\s|$)}{ }i;
            s{[-/]D(\S+)}{-D$1}g;
            $data{cxxflags} = $_;
        }
    }

    chdir $dir;
    die 'Could not find wxWidgets lib directory' unless $libdir;

    $data{dlls} = $self->awx_grep_dlls( $orig_libdir, $digits );
    $data{version} = $digits;

    $self->{awx_data} = \%data;
}

sub _make_command { "nmake -f makefile.vc all " }

sub build_wxwidgets {
    my( $self ) = shift;

    $self->My::Build::Win32_Bakefile::build_wxwidgets( @_ );
}

1;
