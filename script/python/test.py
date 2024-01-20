import click
from ape.cli import network_option, NetworkBoundCommand, choices, options


def _account_callback(ctx, param, value):
    return param.type.get_user_selected_account()

@click.command(cls=NetworkBoundCommand)
@click.option(
	"--account",
	type=choices.AccountAliasPromptChoice(),
	callback=_account_callback,
)
@network_option(required=True)
def cli(account, network):
	click.echo(f"type of account: {type(account)}, {account}, type of network: {type(network)}, {network}")