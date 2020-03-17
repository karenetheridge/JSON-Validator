use lib '.';
use t::Helper;

jv->version(7);

my $data = {
  type       => 'object',
  properties => {
    const =>
      {'$ref' => 'http://json-schema.org/draft-07/schema#/properties/const'},
  },
};

# first, ensure that our data has passed through _resolve, turning that
# $ref into a JSON::Validator::Ref object
jv->schema($data);

# now try to validate it and watch for kabooms
validate_ok($data, 'http://json-schema.org/draft-07/schema#');

done_testing;
