package PERLANCAR::DataDist::ComparisonTable::Getopts;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;
use File::Temp qw(tempfile);
use IPC::System::Options qw(system);

our $table;

sub _mark {
    $_[0] ? "y" : "";
}

sub add_participant {
    my ($name, $script_content, $interp) = @_;

    my ($tempfh, $tempfpath) = tempfile();
    print $tempfh $script_content;
    close $tempfh;
    #chmod 0755, $tempfpath;
    $interp //= $^X;

    if ($interp =~ m!/perl!) {
        system({die=>1}, $interp, "-c", $tempfpath);
    } else {
        say "$tempfpath ($interp) not checked for syntax";
    }

    my $rownum = 0;
    my $colnum;
    my $stdout;

    $table->[$rownum][0] //= "Feature \\ Participant";
    $colnum = @{ $table->[$rownum] };
    $table->[$rownum][$colnum] = $name;
    $rownum++;

    $table->[$rownum][0] //= "Setting long option value via '--name value'";
    system({shell=>0, capture_stdout=>\$stdout}, $interp, $tempfpath, "--foo", "123");
    $table->[$rownum][$colnum] = _mark(!$? && $stdout =~ /^foo=123$/m);
    $rownum++;

    $table->[$rownum][0] //= "Setting long option value via '--name=value'";
    system({shell=>0, capture_stdout=>\$stdout}, $interp, $tempfpath, "--foo=123");
    $table->[$rownum][$colnum] = _mark(!$? && $stdout =~ /^foo=123$/m);
    $rownum++;

    $table->[$rownum][0] //= "Setting empty long option value via '--name='";
    system({shell=>0, capture_stdout=>\$stdout}, $interp, $tempfpath, "--bar=");
    $table->[$rownum][$colnum] = _mark(!$? && $stdout =~ /^bar=$/m);
    $rownum++;

    $table->[$rownum][0] //= "Auto-abbreviation ('--na value')";
    system({shell=>0, capture_stdout=>\$stdout}, $interp, $tempfpath, "--fo=123");
    $table->[$rownum][$colnum] = _mark(!$? && $stdout =~ /^foo=123$/m);
    $rownum++;
}

$table = [];
{
    require Getopt::Long;
    add_participant("Getopt::Long $Getopt::Long::VERSION", <<'_');
use strict;
use Getopt::Long;
my %opts;
$opts{bar} = "default-bar";
Getopt::Long::Configure("bundling", "no_ignore_case", "permute", "no_getopt_compat", "gnu_compat");
GetOptions(
    "foo=s" => \$opts{foo},
    "bar=s" => \$opts{bar},
);
print <<EOF;
foo=$opts{foo}
bar=$opts{bar}
EOF
_

}

{
    require Getopt::Long::EvenLess;
    add_participant("Getopt::Long::EvenLess $Getopt::Long::EvenLess::VERSION", <<'_');
use strict;
use Getopt::Long::EvenLess;
my %opts;
$opts{bar} = "default-bar";
GetOptions(
    "foo=s" => sub { $opts{foo} = $_[1] },
    "bar=s" => sub { $opts{bar} = $_[1] },
);
print <<EOF;
foo=$opts{foo}
bar=$opts{bar}
EOF
_

}

{
    require Getopt::Long::Complete;
    add_participant("Getopt::Long::Complete $Getopt::Long::Complete::VERSION", <<'_');
use strict;
use Getopt::Long::Complete;
my %opts;
$opts{bar} = "default-bar";
GetOptions(
    "foo=s" => \$opts{foo},
    "bar=s" => \$opts{bar},
);
print <<EOF;
foo=$opts{foo}
bar=$opts{bar}
EOF
_

}

{
    require Smart::Options;
    add_participant("Smart::Options $Smart::Options::VERSION", <<'_');
use strict;
use Smart::Options;
my $opts = Smart::Options->new
    ->type(foo => "Str")
    ->type(bar => "Str")->default(bar => "default-bar")
    ->parse;
print <<EOF;
foo=$opts->{foo}
bar=$opts->{bar}
EOF
_

}

{
    require Getopt::Lucid;
    add_participant("Getopt::Lucid $Getopt::Lucid::VERSION", <<'_');
use Getopt::Lucid qw(:all);
my $opt = Getopt::Lucid->getopt([
    Param('foo'),
    Param('bar')->default('default-bar'),
]);
print "foo=", $opt->get_foo, "\n";
print "bar=", $opt->get_bar, "\n";
_

}

{
    add_participant("argparse (python)", <<'_', 'python3');
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--foo', type=str)
    parser.add_argument('--bar', type=str, default='default-bar')
    args = parser.parse_args()
    print("foo={}".format(args.foo))
    print("bar={}".format(args.bar))
_

}

1;
# ABSTRACT: Table comparing features of various option parsing modules

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut
