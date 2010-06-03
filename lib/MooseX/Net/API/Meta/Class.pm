package MooseX::Net::API::Meta::Class;

use Moose::Role;

with qw/
    MooseX::Net::API::Meta::Method::APIMethod
    MooseX::Net::API::Meta::Method::APIDeclare
    /;

1;
__END__

=head1 NAME

MooseX::Net::API::Meta::Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright 2009, 2010 by Linkfluence

http://linkfluence.net

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
