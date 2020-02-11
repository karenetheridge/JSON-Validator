use lib '.';
use t::Helper;

sub j { Mojo::JSON::decode_json(Mojo::JSON::encode_json($_[0])); }

validate_ok j($_), {type => 'any'} for undef, [], {}, 123, 'foo';
validate_ok j(undef), {type => 'null'};
validate_ok j(1), {type => 'null'}, E('/', 'Not null.');

validate_ok($_, {})
  foreach (JSON::PP::true, JSON::PP::false, 1, 1.2, 'a string', {a => 'b'},
  [1, 2, 3],);

validate_ok($_, JSON::PP::true)
  foreach (JSON::PP::true, JSON::PP::false, 1, 1.2, 'a string', {a => 'b'},
  [1, 2, 3],);

validate_ok($_, JSON::PP::false, E('/', 'Should not match.'))
  foreach (JSON::PP::true, JSON::PP::false, 1, 1.2, 'a string', {a => 'b'},
  [1, 2, 3],);

done_testing;
