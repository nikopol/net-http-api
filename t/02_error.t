use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    dies_ok {
        {

            package net_api_fail;
            use Moose;
            use MooseX::Net::API;
            net_api_declare foo => ();
        }
    }
    "... format is missing";
    like $@, qr/format is missing in your api declaration/,
        "... format is missing";
    dies_ok {
        {

            package net_api_fail;
            use Moose;
            use MooseX::Net::API;
            net_api_declare foo => ( format => 'foo' );
        }
    }
    "... no valid format";
    like $@, qr/format is not recognised/, "... no valid format";
    dies_ok {
        {

            package net_api_fail;
            use Moose;
            use MooseX::Net::API;
            net_api_declare foo => ( format => 'json' );
        }
    }
    "... format mode is not set";
    like $@, qr/format_mode is not set/, "... format mode is not set";
    dies_ok {
        {

            package net_api_fail;
            use Moose;
            use MooseX::Net::API;
            net_api_declare foo => ( format => 'json', format_mode => 'bar' );
        }
    }
    "... format mode is unvalid";
    like $@, qr/must be append or content-type/, "... format mode is unvalid";
    #dies_ok {
        #{
            #package net_api_fail;
            #use Moose;
            #use MooseX::Net::API;
            #net_api_declare foo => (
                #format      => 'json',
                #format_mode => 'content-type'
            #);
        #}
    #}
    #"... bad useragent";
    #warn $@;
}

done_testing;
