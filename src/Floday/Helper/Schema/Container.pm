package Floday::Helper::Schema::Container;

use strict;
use warnings;

use JSON::Validator;
use Moo;

my $validator = JSON::Validator->new();

$validator->schema({
    'type' => 'object',
    'additionalProperties' => 0,
    'properties' => {
        'inherit' => {
            'type' => 'array'
        },
        'setups' => {
            '$ref' => '#/definitions/script_avoidable'
        },
        'end_setups' => {
            '$ref' => '#/definitions/script_avoidable'
        },
        'parameters' => {
            '$ref' => '#/definitions/parameters'
        },
        'avoidance' => {
            '$ref' => '#/definitions/script_no_avoidable'
        },
        'hooks' => {
            'properties' => {
                'lxc_deploy_before' => {
                    '$ref' => '#/definitions/script_no_avoidable'
                },
                'lxc_deploy_after' => {
                    '$ref' => '#/definitions/script_no_avoidable'
                },
                'lxc_destroy_before' => {
                    '$ref' => '#/definitions/script_no_avoidable'
                },
                'lxc_destroy_after' => {
                    '$ref' => '#/definitions/script_no_avoidable'
                }
            },
        },
    },
    'definitions' => {
        'parameters' => {
            'patternProperties' => {
                '^.*$' => {
                    'additionalProperties' => 0,
                    'type' => 'object',
                    'properties' => {
                        'mandatory' => {'enum' => ['true', 'false']},
                        'value'     => {'type' => 'string'},
                        'pattern'   => {'type' => 'string'}
                    }
                }
            }
        },
        'script_avoidable' => {
            'patternProperties' => {
                '^.*$' => {
                    'additionalProperties' => 0,
                    'properties' => {
                        'exec'     => {'type' => 'string'},
                        'priority' => {'type' => 'string'},
                        'avoidable' => {'enum' => ['true', 'false']}
                    },
                    'required' => ['exec', 'priority'],
                    'type' => 'object'
                }
            }
        },
        'script_no_avoidable' => {
            'patterProperties' => {
                '.*$' => {
                    'additionalProperties' => 0,
                    'type' => 'object',
                    'properties' => {
                        'exec'     => { 'type' => 'string'},
                        'priority' => { 'type' => 'string'}
                    }
                }
            }
        },
    }
});

sub validate {
    my ($self, $schema) = @_;
    $validator->validate($schema);
}

1;

=head1 NAME

Floday::Helper::Schema::Container - Define the YAML schema for container configuration.

=head1 VERSION

1.1.2

=head1 DESCRIPTION

This is an internal module used by Floday for checking container definition validity.
You should not work directly with this module if you are not currently developing on Floday core.

=head1 AUTHORS

Floday team - http://dev.spyzone.fr/floday

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Floday team.

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
