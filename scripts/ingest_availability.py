"""Import series-level streaming languages for an explicitly reviewed ID match."""
import argparse
import json
import os
import re
import urllib.request
from datetime import datetime, timezone
from urllib.parse import quote, urlparse
from ingest_news import request_json, supabase_headers

LANGUAGES = {'deu': 'de', 'ger': 'de', 'eng': 'en', 'jpn': 'ja', 'fra': 'fr', 'fre': 'fr', 'spa': 'es', 'ita': 'it'}

def language_codes(values, subtitles=False):
    if values is None:
        return None
    if not isinstance(values, list):
        raise ValueError('Language field must be a list')
    codes = set()
    for value in values:
        locale = value.get('locale', {}) if subtitles else value
        code = locale.get('language')
        if not isinstance(code, str) or not re.fullmatch('[a-z]{2,3}', code):
            raise ValueError('Invalid language code')
        codes.add(LANGUAGES.get(code, code))
    return sorted(codes)

def normalize(show, mal_id, region, checked_at=None):
    if mal_id <= 0 or not re.fullmatch('[A-Z]{2}', region):
        raise ValueError('Invalid identity or region')
    now = datetime.now(timezone.utc)
    rows = []
    for option in show.get('streamingOptions', {}).get(region.lower(), []):
        link = option.get('link', '')
        if urlparse(link).scheme != 'https':
            raise ValueError('Watch link must use HTTPS')
        # availableSince is detection time, not an announced future episode release.
        expires = option.get('expiresOn')
        if expires is not None and expires < now.timestamp():
            continue
        provider = option['service']['name']
        if option.get('addon'):
            provider += ' / ' + option['addon']['name']
        rows.append({'mal_id': mal_id, 'provider': provider, 'region': region,
            'scope': 'series', 'season_number': None, 'episode': None,
            'audio_languages': language_codes(option.get('audios')),
            'subtitle_languages': language_codes(option.get('subtitles'), subtitles=True),
            'status': 'available', 'watch_url': link, 'source_url': link,
            'checked_at': checked_at or now.isoformat(), 'published': False})
    return rows

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mal-id', type=int, required=True)
    parser.add_argument('--show-id', required=True)
    parser.add_argument('--region', default='DE')
    parser.add_argument('--mapping-reviewed', action='store_true', required=True,
                        help='Confirm these IDs describe the same series; do not match by title alone')
    parser.add_argument('--write-draft', action='store_true')
    args = parser.parse_args()
    if not re.fullmatch(r'(tt[0-9]+|[0-9]+|tv/[0-9]+|movie/[0-9]+)', args.show_id):
        raise ValueError('Use a provider, IMDb or TMDB ID')
    key = os.environ['STREAMING_API_KEY']
    if key.startswith('motn-key-'):
        base, header = 'https://api.movieofthenight.com/v4', 'X-API-Key'
    else:
        base, header = 'https://streaming-availability.p.rapidapi.com', 'X-RapidAPI-Key'
    request = urllib.request.Request(base + '/shows/' + quote(args.show_id, safe='') + '?country=' + args.region.lower(), headers={header: key})
    with urllib.request.urlopen(request, timeout=30) as response:
        rows = normalize(json.load(response), args.mal_id, args.region.upper())
    if args.write_draft and rows:
        secret = os.environ['SUPABASE_SECRET_KEY']
        request_json(os.environ['SUPABASE_URL'].rstrip('/') + '/rest/v1/availability?on_conflict=mal_id,provider,region,scope,season_number,episode,source_url', rows,
            supabase_headers(secret))
        print(f'{len(rows)} unpublished series-level drafts stored. Existing reviewed rows were retained.')
    else:
        print(json.dumps(rows, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
