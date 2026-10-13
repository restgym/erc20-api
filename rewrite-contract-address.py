"""
ERC20 API - Path rewriting script
Replaces the valid contract addresses that do not belong to a known contract with that of the deployed test contract
"""
import re
from mitmproxy import ctx

# Operations on a contract: /{contractAddress}/{operation}, with anything after the operation (e.g., /balanceOf/{ownerAddress})
OPERATION_PATH = re.compile(r'^/([^/]+)/(decimals|name|symbol|totalSupply|balanceOf|allowance|approve|transfer|transferFrom|approveAndCall|version)(/.*)?$')
# A valid address: 0x followed by 40 hexadecimal digits
VALID_ADDRESS = re.compile(r'^0x[0-9a-fA-F]{40}$')


class ERC20PathRewriter:
    def __init__(self):
        self.contract_address = None
        self.loaded_address = False
        self.known_addresses = set()      # lowercase addresses of the test contract and of the contracts deployed by the tools

    def load_contract_address(self):
        """Load the deployed contract address from file"""
        if self.loaded_address:
            return

        try:
            with open("/tmp/erc20_contract_address.txt", "r") as f:
                self.contract_address = f.read().strip()
                self.known_addresses.add(self.contract_address.lower())
                ctx.log.info(f"[ERC20] Loaded contract address: {self.contract_address}")
                self.loaded_address = True
        except Exception as e:
            ctx.log.warn(f"[ERC20] Could not load contract address: {e}")
            self.loaded_address = True  # Don't try again

    def request(self, flow):
        """Rewrite the paths with a valid address of an unknown contract to use the deployed contract"""
        self.load_contract_address()

        if not self.contract_address:
            return

        # The query string (e.g., of /allowance?ownerAddress=...&spenderAddress=...) is kept as is
        path, separator, query = flow.request.path.partition("?")
        match = OPERATION_PATH.match(path)
        if not match:
            return      # e.g., /config and /deploy, which do not need contract addresses

        current_address = match.group(1)
        # Invalid addresses (e.g., 0xdeadbeef, string) reach the API unchanged, as do the addresses of known contracts
        if not VALID_ADDRESS.match(current_address) or current_address.lower() in self.known_addresses:
            return

        new_path = f"/{self.contract_address}/{match.group(2)}{match.group(3) or ''}{separator}{query}"
        ctx.log.info(f"[ERC20] Rewriting path: {flow.request.path} -> {new_path}")
        flow.request.path = new_path

    def response(self, flow):
        """Remember the addresses of the contracts deployed by the tools (POST /deploy answers the address)"""
        if flow.request.method != "POST" or flow.request.path.partition("?")[0] != "/deploy" or flow.response is None:
            return
        if flow.response.status_code != 200:
            return

        address = (flow.response.get_text(strict=False) or "").strip().strip('"')
        if VALID_ADDRESS.match(address):
            self.known_addresses.add(address.lower())
            ctx.log.info(f"[ERC20] Contract deployed by the tool: {address}")


addons = [ERC20PathRewriter()]
