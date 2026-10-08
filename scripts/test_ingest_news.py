import unittest
from ingest_news import draft_record, validate_source

class IngestTests(unittest.TestCase):
    def test_only_official_sources(self):
        for url in ['http://www.crunchyroll.com/news', 'https://www.crunchyroll.com.evil.test/news', 'https://user@www.crunchyroll.com/news', 'https://www.crunchyroll.com:8443/news']:
            with self.assertRaises(ValueError): validate_source(url)
    def test_news_stays_unpublished_and_unknown_date_stays_unknown(self):
        value = draft_record('https://www.crunchyroll.com/news/example', {'headline': 'Neue Staffel', 'summary': 'Eine neue Staffel wurde angekündigt.', 'category': 'season', 'published_at': None}, now='2026-10-08T00:00:00Z')
        self.assertFalse(value['published'])
        self.assertIsNone(value['published_at'])
    def test_rejects_long_copied_content(self):
        with self.assertRaises(ValueError):
            draft_record('https://www.crunchyroll.com/news/example', {'headline': 'Test', 'summary': 'word ' * 81, 'category': 'dub'})

if __name__ == '__main__': unittest.main()
