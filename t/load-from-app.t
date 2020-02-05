use Mojo::Base -strict;
use Test::More;
use JSON::Validator;
use Mojolicious::Lite;

$ENV{MOJO_LOG_LEVEL} = 'fatal';

get '/spec' => sub { shift->reply->static('spec.json') };

my $schema = eval {
  JSON::Validator->new->load_and_validate_schema('data:///spec.json')
    ->schema->{data};
};
is $@, '', 'no errors when loading from file directly';

is_deeply(
  $schema,
  {schema => {type => 'array', items => {type => 'number'}}},
  'loaded schema from file',
);

$schema = eval {
  JSON::Validator->new->load_and_validate_schema('/spec')->schema->{data};
};
is $@, '', 'no errors when loading from app';

is_deeply(
  $schema,
  {schema => {type => 'array', items => {type => 'number'}}},
  'loaded schema and resolved refs',
);

done_testing;

__DATA__
@@ spec.json
{
  "schema": {
    "type": "array",
    "items": { "type": "number" }
  }
}
