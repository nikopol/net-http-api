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
