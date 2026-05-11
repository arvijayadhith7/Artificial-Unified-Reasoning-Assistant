const { search } = require('duck-duck-scrape');
search('latest news', { safeSearch: 0 }).then(results => {
  console.log('Results:', results.results.length);
  process.exit(0);
}).catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
