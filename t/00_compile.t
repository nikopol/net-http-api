use strict;
use Test::More;

# XXX pourquoi il meurt ?
BEGIN { plan skip_all => "moooose"; use_ok 'MooseX::Net::API'; use_ok 'MooseX::Net::API::Test' }
