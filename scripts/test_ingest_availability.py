import unittest
from ingest_availability import normalize

class AvailabilityTests(unittest.TestCase):
    def test_audio_and_subtitles_are_independent(self):
        show = {'streamingOptions': {'de': [{'service': {'name': 'Example'}, 'link': 'https://example.com/show', 'audios': [{'language': 'jpn'}], 'subtitles': [{'locale': {'language': 'deu'}, 'closedCaptions': False}]}]}}
        row = normalize(show, 1, 'DE')[0]
        self.assertEqual(row['audio_languages'], ['ja'])
        self.assertEqual(row['subtitle_languages'], ['de'])
        self.assertEqual(row['scope'], 'series')
        self.assertIsNone(row['episode'])
        self.assertFalse(row['published'])
    def test_missing_audio_stays_unknown(self):
        show = {'streamingOptions': {'de': [{'service': {'name': 'Example'}, 'link': 'https://example.com/show'}]}}
        self.assertIsNone(normalize(show, 1, 'DE')[0]['audio_languages'])
    def test_other_country_is_not_inferred(self):
        self.assertEqual(normalize({'streamingOptions': {'us': []}}, 1, 'DE'), [])

if __name__ == '__main__': unittest.main()
