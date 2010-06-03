package MooseX::Net::API::Meta::Class;

# ABSTRACT: metaclass for all API client

use Moose::Role;

with qw/
    MooseX::Net::API::Meta::Method::APIMethod
    MooseX::Net::API::Meta::Method::APIDeclare
    /;

1;

=head1 SYNOPSIS

=head1 DESCRIPTION
