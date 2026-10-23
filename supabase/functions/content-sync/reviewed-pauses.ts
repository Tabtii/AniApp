// Human-reviewed exception to recurring schedule estimates. Update/remove when
// the publisher confirms a resumption; never derive a date from publication time.
export const reviewedPauses = [{
  mal_id:21,title:'One Piece',from:'2026-10-04T00:00:00Z',
  source_url:'https://news.animationdigitalnetwork.com/de/2026/10/04/warum-gibt-es-diese-woche-keine-neue-folge-one-piece/',
  checked_at:'2026-10-08T17:25:00Z',
  release_note:'Ausstrahlungspause nach Folge 1180 laut ADN. Ein Termin für die Fortsetzung ist noch nicht bestätigt. Stand: 8. Oktober 2026.',
}];
export const pausedIds=(now=new Date())=>new Set(reviewedPauses.filter(p=>Date.parse(p.from)<=now.getTime()).map(p=>p.mal_id));
