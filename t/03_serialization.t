use strict;
use warnings;
use Test::More;

use MooseX::Net::API::Parser::XML;
use MooseX::Net::API::Parser::JSON;
use MooseX::Net::API::Parser::YAML;

ok my $xml_parser = MooseX::Net::API::Parser::XML->new();
ok my $yaml_parser = MooseX::Net::API::Parser::YAML->new();
ok my $json_parser = MooseX::Net::API::Parser::JSON->new();

done_testing;
