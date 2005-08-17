package Alien::wxWidgets::Utility;

=head1 NAME

Alien::wxWidgets::Utility - INTERNAL: do not use

=cut

use strict;
use base qw(Exporter);
use Config;

our @EXPORT_OK = qw(awx_capture awx_cc_is_gcc awx_cc_version
                    awx_sort_config awx_grep_config awx_smart_config);

my $quotes = $^O =~ /MSWin32/ ? '"' : "'";

sub awx_capture {
    qx!$^X -e ${quotes}open STDERR, q[>&STDOUT]; exec \@ARGV${quotes} -- $_[0]!;
}

sub awx_cc_is_gcc {
    my( $cc ) = @_;

    return    scalar( awx_capture( "$cc --version" ) =~ m/gcc/i ) # 3.x
           || scalar( awx_capture( "$cc" ) =~ m/gcc/i );          # 2.95
}

sub awx_cc_version {
    my( $cc ) = @_;
    return 0 unless awx_cc_is_gcc( $cc );

    my $ver = awx_capture( "$cc --version" );

    $ver =~ m/(\d+\.\d+)(?:\.\d+)?/ or return 0;

    return $1;
}

sub awx_compiler_kind {
    my( $cc ) = @_;

    return 'gcc' if awx_cc_is_gcc( $cc );
    return 'cl'  if $^O =~ /MSWin32/ and $cc =~ /^cl/i;

    return 'nc'; # as in 'No Clue'
}

sub awx_sort_config {
    my $make_cmpn = sub {
        my $k = shift;
        sub { exists $a->{$k} && exists $b->{$k} ? $a->{$k} <=> $b->{$k} :
              exists $a->{$k}                    ? 1                     :
              exists $b->{$k}                    ? -1                    :
                                                   0 }
    };
    my $make_cmps = sub {
        my $k = shift;
        sub { exists $a->{$k} && exists $b->{$k} ? $a->{$k} cmp $b->{$k} :
              exists $a->{$k}                    ? 1                     :
              exists $b->{$k}                    ? -1                    :
                                                   0 }
    };
    my $rev = sub { my $cmp = shift; sub { -1 * &$cmp } };
    my $crit_sort = sub {
        my @crit = @_;
        sub {
            foreach ( @crit ) {
                my $cmp = &$_;
                return $cmp if $cmp;
            }

            return 0;
        }
    };

    my $cmp = $crit_sort->( $make_cmpn->( 'version' ),
                            $rev->( $make_cmpn->( 'debug' ) ),
                            $make_cmpn->( 'unicode' ),
                            $make_cmpn->( 'mslu' ) );

    return reverse sort $cmp @_;
}

sub awx_grep_config {
    my( $cfgs ) = shift;
    my( %a ) = @_;
    my $make_cmpr = sub {
        my $k = shift;
        sub {
            return 1 unless exists $a{$k};
            ref $a{$k} ? $a{$k}[0] <= $_->{$k} && $_->{$k} < $a{$k}[1] :
                         $a{$k}    <= $_->{$k};
        }
    };
    my $make_cmpn = sub {
        my $k = shift;
        sub { exists $a{$k} ? $a{$k} == $_->{$k} : 1 }
    };
    my $make_cmps = sub {
        my $k = shift;
        sub { exists $a{$k} ? $a{$k} eq $_->{$k} : 1 }
    };

    my $wver = $make_cmpr->( 'version' );
    my $ckind = $make_cmps->( 'compiler_kind' );
    my $cver = $make_cmpn->( 'compiler_version' );
    my $tkit = $make_cmps->( 'toolkit' );
    my $deb = $make_cmpn->( 'debug' );
    my $uni = $make_cmpn->( 'unicode' );
    my $mslu = $make_cmpn->( 'mslu' );
    my $key = $make_cmps->( 'key' );

    grep { &$wver  } grep { &$ckind } grep { &$cver  }
    grep { &$tkit  } grep { &$deb   } grep { &$uni   }
    grep { &$mslu  } grep { &$key   }
         @{$cfgs}
}

sub awx_smart_config {
    my( %args ) = @_;
    my $cc = $Config{cc};
    my $kind = awx_compiler_kind( $cc );
    my $version = awx_cc_version( $cc );

    $args{compiler_kind} ||= $kind;
    $args{compiler_version} ||= $version;

    return %args;
}

1;
