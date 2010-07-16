package Net::HTTP::API::Parser::JSON;

# ABSTRACT: Parse JSON

use JSON;
use Moose;
extends 'Net::HTTP::API::Parser';

sub encode {
    my ($self, $content) = @_;
    return JSON::encode_json($content);
}

sub decode {
    my ($self, $content) = @_;
    return JSON::decode_json($content);
}

1;

=head1 SYNOPSIS

=head1 DESCRIPTION
