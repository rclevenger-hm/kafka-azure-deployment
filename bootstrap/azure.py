"""Bounded Azure public-cloud REST access using the VM's selected managed identity."""
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request

IMDS = 'http://169.254.169.254/metadata/'
UUID = r'[a-fA-F0-9]{8}(?:-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}'
DISK_ID = r'/subscriptions/' + UUID + r'/resourceGroups/[A-Za-z0-9_.()-]+/providers/Microsoft.Compute/disks/[A-Za-z0-9_.-]+'


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ValueError('Authenticated redirects are forbidden')


def request(url, headers=None, maximum=4 * 1024 * 1024, attempts=5):
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    for attempt in range(attempts):
        try:
            req = urllib.request.Request(url, headers=headers or {})
            with opener.open(req, timeout=20) as response:
                data = response.read(maximum + 1)
                if len(data) > maximum:
                    raise ValueError('Azure response exceeds its size limit')
                return data, dict(response.headers)
        except OSError as error:
            retryable = not isinstance(error, urllib.error.HTTPError) or error.code in {404, 408, 409, 429, 500, 502, 503, 504}
            if not retryable or attempt == attempts - 1:
                raise
            time.sleep(2 ** attempt)


def token(client_id, resource):
    if not re.fullmatch(UUID, client_id) or resource not in {'https://vault.azure.net', 'https://storage.azure.com/'}:
        raise ValueError('Invalid managed identity or token audience')
    query = urllib.parse.urlencode({'api-version': '2018-02-01', 'client_id': client_id, 'resource': resource})
    raw, _ = request(IMDS + 'identity/oauth2/token?' + query, {'Metadata': 'true'}, maximum=65536)
    result = json.loads(raw)
    if not isinstance(result.get('access_token'), str) or not result['access_token']:
        raise ValueError('Managed identity token missing')
    return result['access_token']


def secret_payload(version_url, client_id):
    if not re.fullmatch(r'https://[a-z][a-z0-9-]{1,22}[a-z0-9]\.vault\.azure\.net/secrets/[A-Za-z0-9-]{1,127}/[a-f0-9]{32}', version_url):
        raise ValueError('Use a public-cloud Key Vault secret URL with an immutable 32-hex version')
    bearer = token(client_id, 'https://vault.azure.net')
    raw, _ = request(version_url + '?api-version=7.4', {'Authorization': 'Bearer ' + bearer}, maximum=131072)
    result = json.loads(raw)
    if result.get('id', '').lower() != version_url.lower():
        raise ValueError('Secret response differs from pinned identity')
    value = json.loads(result['value'])
    if not isinstance(value, dict):
        raise ValueError('TLS bundle must be a JSON object')
    return value
