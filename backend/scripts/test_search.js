const googleIt = require('google-it');
googleIt({ query: 'latest news' }).then(results => {
  console.log('Results:', results.length);
  process.exit(0);
}).catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
