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
