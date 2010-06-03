package MooseX::Net::API::Parser::JSON;

use JSON;
use Moose;
extends 'MooseX::Net::API::Parser';

sub encode {
    my ($self, $content) = @_;
    return JSON::encode_json($content);
}

sub decode {
    my ($self, $content) = @_;
    return JSON::decode_json($content);
}

1;
__END__

=head1 NAME

MooseX::Net::API::Parser::JSON

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright 2010 by Linkfluence

http://linkfluence.net

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
