use v5.20;
use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::More;

use Floday::Helper::Container;

my $expected_result_1 = {
	'setups'     => {
		'network' => {
			'avoidable' => 'false',
			'priority' => '10',
			'exec'     => 'riuk/children/core/setups/network.pl'
		},
		'data'    => {
			'avoidable' => 'true',
			'priority' => '30',
			'exec'     => 'riuk/children/core/setups/data.pl'
		}
	},
	'hooks'      => {
		'lxc_deploy_before' => {
			'open_firewall' => {
				'exec'     => 'riuk/children/core/hooks/lxc_deploy_before/open_firewall.pl',
				'priority' => 10
			}
		},
		'lxc_deploy_after'  => {
			'close_firewall' => {
				'exec'     => 'riuk/children/core/hooks/lxc_deploy_after/close_firewall.pl',
				'priority' => 10
			},
		},
		'lxc_destroy_before' => {
			'clear_filesystem' => {
				'exec'     => 'riuk/children/core/hooks/lxc_destroy_before/clear_filesystem.pl',
				'priority' => 10
			}
		},
		'lxc_destroy_after'  => {
			'update_fstab' => {
				'exec'     => 'riuk/children/core/hooks/lxc_destroy_after/update_fstab.pl',
				'priority' => 10
			}
		}
	},
	'inherit'    => [
		'riuk-core'
	],
	'parameters' => {
		'data_out'               => {
			'mandatory' => 'false'
		},
		'second_arbitrary_param' => {
			'mandatory' => 'false'
		},
		'data_in'                => {
			'mandatory' => 'false'
		},
		'iface'                  => {
			'mandatory' => 'true',
			'value'     => 'eth0'
		},
		'ipv4'                   => {
			'mandatory' => 'true'
		},
		'template'               => {
			'mandatory' => 'true',
			'value'     => 'flodayalpine -- version 3.4'
		},
		'netmask'                => {
			'value'     => '255.255.255.0',
			'mandatory' => 'true'
		},
		'arbitrary_param'        => {
			'mandatory' => 'false'
		},
		'bridge'                 => {
			'mandatory' => 'true',
			'value'     => 'lxcbr0'
		},
		'gateway'                => {
			'mandatory' => 'true'
		}
	},
	'avoidance' => {
		'importer' => {
			'exec' => 'riuk/children/core/avoidance/importer.pl',
			'priority' => '1-20'
		},
		'parameters' => {
			'priority' => '1-10',
			'exec' => 'riuk/children/core/avoidance/parameters.pl'
		}
	}
};

cmp_ok (Floday::Helper::Container->new('container_path' => 'riuk-web-php')->get_container_definition_file_path(),
  'eq',
  '/etc/floday/containers/riuk/children/web/children/php/config.yml',
  'Definition file path corectly fetched.'
);

cmp_deeply (Floday::Helper::Container->new('container_path' => 'riuk-sftp')->get_container_definition(),
  $expected_result_1,
  'Definition of container correctly fetched.'
);

throws_ok {Floday::Helper::Container->new('container_path' => 'riuk-broken')->get_container_definition()}
  qr#Errors in riuk-broken definition:
/inherit: Expected array - got string.
/parameters/fake/mandatory: Not in enum list: true, false.
/setups/fake/exec: Expected string - got null.
/setups/fake/priority: Missing property.#,
  'Check container YAML schema validation.';

my @parents;
for (Floday::Helper::Container->new('container_path' => 'riuk-inheritance_test')->get_container_parents()) {
	push @parents, $_->get_container_path();
}
@parents = sort @parents;
cmp_deeply (\@parents, ['riuk-core', 'riuk-mumble', 'riuk-sftp'], 'Test get_container_parents.');

done_testing;
