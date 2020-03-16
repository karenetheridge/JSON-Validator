use Mojo::Base -strict;
use JSON::Validator;
use Test::More;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};
plan skip_all => 'unset NO_NETWORK_TESTING' if $ENV{NO_NETWORK_TESTING};

my $jv = JSON::Validator->new;

$jv->schema('http://swagger.io/v2/schema.json');

isa_ok($jv->schema, 'Mojo::JSON::Pointer');
like $jv->schema->get('/title'), qr{swagger}i, 'got swagger spec';
ok $jv->schema->get('/patternProperties/^x-/description'),
  'resolved vendorExtension $ref';

done_testing;
