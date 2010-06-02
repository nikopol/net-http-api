package MooseX::Net::API::Meta::Class;

use Moose::Role;

with qw/
    MooseX::Net::API::Meta::Method::APIMethod
    MooseX::Net::API::Meta::Method::APIDeclare
    /;

1;
