package vendorlib;

use strict;
use warnings;
use Config;

=head1 NAME

vendorlib - Use Only Core and Vendor Libraries in @INC

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    #!/usr/bin/perl

    use vendorlib;
    use strict;
    use warnings;
    use SomeModule; # will only search in core and vendor paths
    ...

=head1 DESCRIPTION

In a system distribution such as Debian, it may be advisable for Perl programs
to ignore the user's CPAN-installed modules and only use the
distribution-provided modules to avoid possible breakage with newer and
unpackaged versions of modules.

To that end, this pragma will replace your C<@INC> with only the core and vendor
C<@INC> paths, ignoring site_perl and C<$ENV{PERL5LIB}> entirely.

It is recommended that you put C<use vendorlib;> as the first statement in your
program, before even C<use strict;> and C<use warnings;>.

=cut

sub import {
    my @paths = (($^O ne 'MSWin32' ? ('/etc/perl') : ()), @Config{qw/
        vendorarch
        vendorlib
        archlib
        privlib
    /});

    # This grep MUST BE on copies of the paths to not trigger Config overload
    # magic.
    @paths = grep $_, @paths;

    # remove duplicates
    my @result;
    while (my $path = shift @paths) {
        if (@paths && $path eq $paths[0]) {
            # ignore
        }
        else {
            push @result, $path;
        }
    }
    @paths = @result;

    # fixup slashes for @INC on Win32
    if ($^O eq 'MSWin32') {
        s{\\}{/}g for @paths;
    }

    # expand tildes
    if ($^O ne 'MSWin32') {
        for my $path (@paths) {
            if ($path =~ m{^~/+}) {
                my $home = (getpwuid($<))[7];
                $path =~ s|^~/+|${home}/|;
            }
            elsif (my ($user) = $path =~ /^~(\w+)/) {
                my $home = (getpwnam($user))[7];
                $path =~ s|^~${user}/+|${home}/|;
            }
        }
    }

    # remove any directories that don't actually exist
    # this will also remove /etc/perl on non-Debian systems
    @paths = grep -d, @paths;

    @INC = @paths;
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-vendorlib at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=vendorlib>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc vendorlib

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=vendorlib>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/vendorlib>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/vendorlib>

=item * Search CPAN

L<http://search.cpan.org/dist/vendorlib/>

=back

=head1 ACKNOWLEDGEMENTS

mxey and jawnsy on oftc #debian-perl helped to hash out the design for this.

ribasushi reviewed the initial version and pointed out that @INC order matters.

=head1 AUTHOR

Rafael Kitover, C<< <rkitover at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Rafael Kitover.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of vendorlib
